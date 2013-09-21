# -*- encoding : utf-8 -*-

#A module for adminsitration
linael :admin, require_auth: true do

  help [
    t.admin.help.description,
    t.help.helper.line.white,
    t.help.helper.line.admin,
    t.admin.help.function.join,
    t.admin.help.function.part,
    t.admin.help.function.kick,
    t.admin.help.function.die,
    t.admin.help.function.mode,
    t.admin.help.function.reload
  ]

  on_init do
    @chans =[]
  end

  #List of joined chan
  attr_accessor :chans

  #on load rejoin all the chan
  on_load do
    @chans.each {|chan| join_channel :dest => chan}
  end

  def join_act chan
    chans << chan unless chans.include? chan
    join_channel :dest => chan
  end

  def part_act chan
    talk(chan,t.admin.act.part.message)
    chans.delete chan
    part_channel :dest => chan
  end

  def die_act
    quit_channel :msg => t.admin.act.die.message
    exit 0
  end

  def kick_act who,chan,reason
    talk(chan,t.admin.act.kick.message(who))
    kick_channel :dest => chan,
                 :who  => who, 
                 :msg  => reason
  end

  def mode_act chan,what,args
    mode_channel  :dest => chan,
                  :what => what,
                  :args => args
  end

  #join chan
  on :cmdAuth, :join, /^!admin_join\s|^!join\s|^!j\s/ do |msg,options|
    answer(msg,t.admin.act.join.answer(options.chan))	
    join_act options.chan
  end

  #part chan
  on :cmdAuth, :part, /^!admin_part\s|^!part\s/ do |msg,options|
    answer(msg,t.admin.act.part.answer(options.chan))	
    part_act options.chan
  end

  #exit 0
  on :cmdAuth, :die, /^!admin_die\s/ do |msg,options|
    answer(msg,t.admin.act.die.answer)
    die_act
  end

  #kick
  on :cmdAuth, :kick, /^!admin_kick\s|^!kick\s|^!k\s/ do |msg,options|
    answer(msg,t.admin.act.kick.answer(options.who,options.chan))	
    kick_act options.who,options.chan,options.reason
  end

  #(re)load a file
  on :cmdAuth, :reload, /^!admin_reload\s/ do |msg,options|
    answer(msg,t.admin.act.reload.answer(options.what)) if load options.what
  end

  #change mode on a chan
  on :cmdAuth, :mode, /^!admin_mode\s|^!mode\s/ do |msg,options|
    answer(msg,t.admin.act.mode.answer("#{options.what} #{options.reason+" " unless options.reason.empty?}",options.chan))
    mode_act options.chan,options.what,options.reason
  end

end