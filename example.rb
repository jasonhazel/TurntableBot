require "turntablebot"
require "yaml"
config = YAML::load(File.open('config.yml'))

TurntableBot.create do
  as_user         config['user']
  authorized_by   config['auth']
  in_room         config['room']

  # log all api responses
  on :data do |data|
    File.open(config['log_file'], 'a') do |file|
      file.puts data 
    end
  end

  # when someone talks in the chat
  on :speak do |message|
    if message.text == '/current'
      speak "#{current_song.user.name} is playing #{current_song.title} by #{current_song.artist}" unless current_song.nil?
    end

    if message.text == '/bop'
      speak "Just for you #{message.user.name}"
      vote
    end

    add_dj if message.text == '/start_dj' and message.user.id == config['admin']
    rem_dj if message.text == '/stop_dj' and message.user.id == config['admin']
  end

  # when there is a new song
  on :newsong do |song|
    # here we are sending a PM to the dj that just finished letting them know their stats
    pm previous_song.user.id, "#{previous_song.title} :arrow_up: #{previous_song.up} :arrow_down: #{previous_song.down}  :speaker: #{previous_song.listeners}" unless previous_song.nil?
  end

  # when someone enters the room
  on :registered do |user|
    # we're going to say hello
    speak "Hello, #{user.name}" unless user.id == config['user']
  end

  # when a private message is received
  on :pmmed do |message|
    # when someone messages us.  we'll just say hi for now.
    pm message.user.id, 'hi.'
  end
end