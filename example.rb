#!/usr/bin/env ruby
#
require_relative './lib/turntablebot.rb'
require_relative './lib/extensions/admin.rb'
require_relative './lib/extensions/dj.rb'
require_relative './lib/extensions/pm.rb'
require_relative './lib/extensions/room.rb'


require "yaml"
config = YAML::load(File.open('config.yml'))

TurntableBot.create do
  as_user         config[:user]
  authorized_by   config[:auth]
  in_room         config[:room]
  admins          config[:admin]

  log do |data|
    
    if data['room'].nil?
      now = Time.new
      timestamp = now.strftime('%Y-%m-%d')
      log_file = "#{File.dirname(__FILE__)}/#{config[:logs]}/#{timestamp}.log"
        
      File.open(log_file, 'a') do |file|
        file.puts "[#{now}] #{data}"
      end
    end
  end

  when_ready do
    i_entered do
      tell_admins "Ready to work."
    end

    someone_entered do |user|
      # puts user.inspect
      user.each do |id, info|
        message info, 'Welcome to the party?'
      end
      
    end

    someone_said ['dance','bop'] do |message|
      say "Look at me, #{message.user.name}, I'm dancing! "
      vote 
    end

    admin_messaged ['boo','barf','lame'] do |message|
      message message.user, 'Song lamed.'
      lame
    end

    admin_messaged /say (.+$)/i do |message|
      say message.parts[1]
    end

    admin_messaged /tell djs (.+$)/i do |message|
      tell_djs message.parts[1]
    end

    admin_messaged 'quit' do |message|
      message message.user, 'Shutting down.'
    end

    someone_messaged 'current' do |message|
      message message.user, "#{song.title} - :arrow_up: #{song.up} :arrow_down: #{song.down} :speaker: #{song.listeners}"
    end

    admin_messaged 'start djing' do |message|
      start_djing
      message message.user, 'Party mode: Activated.'
    end

    admin_messaged 'snag' do |message|
      heart
      message message.user, "#{song.title} snagged."
    end

    admin_messaged 'stop djing' do |message|
      stop_djing
      message message.user, 'Stepping down.'
    end

    admin_messaged ['skip song','skip'] do |message|
      skip_song
      message message.user, 'Skipping song'
    end

    song_ended do |song|
      # puts song.inspect
      message song.dj, song.title
      message song.dj, ":arrow_up: #{song.up} :arrow_down: #{song.down} :heart_decoration: #{song.hearts} :speaker: #{song.listeners}"
    end

    song_started do |song|
      # if you bot is djing, show love to the others
      if is_dj? config[:user] and not am_i? song.dj
        # wait for a bit before voting
        Thread.new do
          sleep rand(60 - 20) + 20
          vote
        end
      end
    end

    when_solo_dj do
      start_djing
      say "I guess I'll spin for a bit."
    end

    when_enough_djs do
      stop_djing
      say "That was fun."
    end
  end
end