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
    File.open(config['log_file'], 'a') do |file|
      file.puts data 
    end
  end

  someone_said 'bop' do |message|
    say "Just for you, #{message.user.name}!"
    vote 
  end

  someone_said 'roll' do |message|
    say 'var randNumber = 4;'
  end

  admin_messaged_saying 'boo' do
    vote
  end

  admin_messaged_saying 'start djing' do
    start_djing
  end

  admin_messaged_saying 'stop djing' do
    stop_djing
  end
end