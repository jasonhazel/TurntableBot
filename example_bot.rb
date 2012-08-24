require_relative "./lib/turntablebot"
require "yaml"
config = YAML::load(File.open('config.yml'))

TurntableBot.create do
  as_user         config['user']
  authorized_by   config['auth']
  in_room         config['room']

  on :speak do |message|
    if message.text =~ /\/bop/i
      vote :up
    end

  end
end