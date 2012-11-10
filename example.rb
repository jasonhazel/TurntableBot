require_relative './lib/turntablebot.rb'
require "yaml"
config = YAML::load(File.open('config.yml'))


TurntableBot.create do
  as_user         config['user']
  authorized_by   config['auth']
  in_room         config['room']
  admins          config['admin']

  # log all api responses
  log do |data|
    File.open(config['log'], 'a') do |file|
      file.puts data 
    end
  end

  i_entered do
    tell_admins "Ready to work."
  end

  someone_entered do |user|
    message user 'Welcome to the party?'
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

  admin_messaged_saying 'start djing' do |message|
    start_djing
    message message.user, 'Party mode: Activated.'
  end

  admin_messaged_saying 'stop djing' do |message|
    stop_djing
    message message.user, 'Stepping down.'
  end
end