# -*- encoding : utf-8 -*-

require 'open-uri'
require 'hpricot'
require 'htmlentities'
require 'net/http'

#A module to generate names
linael :name do

  help [
    "Module: Name",
    "A module to generate names.", 
    "Thx to http://www.behindthename.com",
    " ",
    "=====Fonctions=====",
    "!name        => display a random name from a database",
    "!name -types => display the different types of names available",
    "!name -info  => display information on name",
    " ",
    "=====Options=====",
    "!name -g{m|f} -s[1-4] -[0-9] -a -tType1,Type2,...",
    "    -g    : Gender male or female",
    "    -s    : Size of the name",
    "    -     : Number of result",
    "    -a    : All ignore all the other options",
    "    -t    : Types of names",
    "!name types regex",
    "    regex : regex like b* for every type begining with b"
  ]


  #generate a name
  on :cmd, :get_names, /^!name\s/ do |msg,options|
    before(options) do |options|
      !options.types? and !options.info?
    end

    coder = HTMLEntities.new

    time(options).times do |i|
      url="http://www.behindthename.com/random/random.php?"
      url+="number=#{options.size}"
      url+="&"
      url+="gender=#{options.gender}"
      url+="&all=yes" if options.all?
      url+="&all=no" if !options.all?
      types(options).each do |type|
        url+="&usage_#{type}=1"
      end
      page = Hpricot(open(url))
      name = (page/"div.body span.heavybig a").inject("") {|str, nam| str += " #{coder.decode(nam.inner_html)}"}
      name = (page/"div.body span").inject("") {|str, nam| str += " #{coder.decode(nam.inner_html.gsub(/\s/,""))}"} if name.empty?
      answer(msg,"#{i+1} - #{name}")

    end
  end

  #info on a name... this fonction is SO UGLY
  on :cmd, :info_name, /!name\s.*\s*-info\s/ do |msg,options|
    coder = HTMLEntities.new

    uri = URI('http://www.behindthename.com/names/search.php')
    redirect = Net::HTTP.post_form(uri, 'terms' => options.who)
    redirect.each_header {|h,v| p h; p v}
    url = "http://www.behindthename.com"+redirect.get_fields('location')[0]
    page = Hpricot(open(url))
    page = coder.decode(page)
    page =~ /GENDER[^>]*>[^>]*info[^>]*><[^<]*>([A-z]*)<[^<]*<\/span/m
    gender = $1
    answer(msg,"Gender: #{gender}")
    usages = page.scan /<a[^>]*usg[^>]*>([A-z\s]*)</
    answer(msg,"Usages: #{usages.join(", ")}")
    page =~ /padding:3px;padding-left:10px;[^>]*>.(.*)<.div.*nameheading.*triangle.gif[^>]*>[^>]*related/m
    description = $1
    description.gsub!(/<[^>]*>/,"")
    answer(msg,"Description:")
    description.split("\n").each do |to_print|
      to_print.gsub!("\r","")
      to_print += " "
      to_print.scan(/.{0,400}\s/).each do |line|
        answer(msg,line)
      end
    end
  end

  #show the differents types of names
  on :cmd, :what_types, /^!name\s.*\s*-types\s/ do |msg,options|
    coder = HTMLEntities.new

    if (msg.message =~ /^!name\s.*\s*-types\s+([A-z\*]*)/)
      search=$1
      search.gsub!("*",".*")
    end
    url ="http://www.behindthename.com/random/"
    page = Hpricot(open(url))
    typesNames = (page/"div.body td.emcell table.emtable td")
    typesToParse = (page/"div.body td.emcell table.emtable input").map! do |input| 
      if input.to_html.match(/usage/)
        type=input.to_html.match(/usage_([A-z]*)/)[0].gsub(/usage_/,"")
        index=typesNames.find_index {|item| item.to_html.match(/usage_#{type}"/)}
        tdToParse=typesNames[index]
        tdToParse.to_html.match "usage_#{type}[^>]*>[^A-z]*([A-z]+\s*[A-z]*)"
        name=$1
        "#{type} : #{coder.decode(name)}" if search.nil? || search.empty? || type.match("^#{search}$")
      end
    end
    typesToParse.compact!
    typesToParse.cycle do |type|
      talk(msg.who,typesToParse.shift(5).join("   "))
    end
  end


  value_with_default :time_string => {regexp: /\s-([0-1]?[0-9])\s/, default: "1"},
                     :size => {regexp: /\s-s([1-4])\s/, default: "1"}

  value :gender        => /\s-g([mfa])\s/,
        :types_string  => /\s-t([A-z0-9]*)\s/

  match :all   => /\s-a\s/,
        :types => /\s-types\s/,
        :info  => /\s-info\s/

  define_method "types" do |options|
    options.types_string.split(',')
  end

  define_method "time" do |options|
    options.time_string.to_i
  end

end
