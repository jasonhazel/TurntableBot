require_relative './lib/turntablebot.rb'
require "yaml"
config = YAML::load(File.open('config.yml'))

TurntableBot.create do
  as_user         config[:user]
  authorized_by   config[:auth]
  in_room         config[:room]
  admins          config[:admin]

  # log all api responses
  log do |data|
    File.open(config[:log], 'a') do |file|
      file.puts "[#{Time.now}] #{data}"
    end
  end

  when_ready do
    i_entered do
      tell_admins "Ready to work."
    end

    someone_entered do |user|
      message user, 'Welcome to the party?'
    end

    someone_mentioned ['dance','bop'] do |message|
      say "Look at me, #{message.user.name}, I'm dancing! "
      vote 
    end

    someone_said '/roll' do |message|
      say 'var randNumber = 4;'
    end

    admin_messaged_mentioning ['boo','barf','lame'] do |message|
      message message.user, 'Song lamed.'
      lame
    end

    admin_messaged_saying 'quit' do |message|
      message message.user, 'Shutting down.'

    end

    message_recieved_saying 'current' do |message|
      message message.user, "#{song.title} - :arrow_up: #{song.up} :arrow_down: #{song.down} :speaker: #{song.listeners}"
    end

    admin_messaged_saying 'start djing' do |message|
      start_djing
      message message.user, 'Party mode: Activated.'
    end

    admin_messaged_saying 'snag' do |message|
      heart
      message message.user, "#{song.title} snagged."
      message song.user, 'Good play.'
    end

    admin_messaged_saying 'stop djing' do |message|
      stop_djing
      message message.user, 'Stepping down.'
    end

    song_ended do |song|
      message song.user, "#{song.title} - :arrow_up: #{song.up} :arrow_down: #{song.down} :speaker: #{song.listeners}"
    end

    song_started do |song|
      # if you bot is djing, show love to the others
      if djs.include? config[:user]
        # wait for a bit before voting
        Thread.new do
          sleep 20
          vote
        end
      end
    end

    when_solo_dj do
      start_djing
      say "I guess I'll play for a bit."
    end

    when_enough_djs do
      stop_djing
      say "That was fun."
    end
  end
end