require "rubygems"
require_relative "./websocket"
# require "set"
require "uri"
require "net/http"
require "json"


class TurntableBot
  # this is the DSL magic

  def self.create &block
    bot = TurntableBot.new
    bot.instance_eval(&block)
    bot.activate
  end

  def initialize
    @listeners  = {}
    @_msgId     = 0
    @_clientId  = "#{Time.now.to_i}-0.59633534294921572"
    @status     = "available"
  end

  def as_user user
    @user = user
  end

  def authorized_by auth
    @auth = auth
  end

  def in_room room 
    @room = room
  end

  def activate
    connect
    notify :ready
    while data = @socket.receive
      incoming data
    end
  end

  def incoming data
    # this logic is pretty much identical to the ttapi version
    heartbeat_match = /~m~[0-9]+~m~(~h~[0-9]+)/
    if data =~ heartbeat_match
      heartbeat heartbeat_match.match(data)[1]
      @heartbeat = Time.now
      presence
      return
    end

    if data == "~m~10~m~no_session"
      authenticate
      presence
      return
    end

    delegate data
  end

  def delegate data
    # puts data
    response = JSON.parse(data[data.index("{"), data.length])
    command = response['command'].to_sym if response['command']

    # fire our data listener, useful to write a logger
    @listeners[:data].call data if @listeners[:data]

    # handle special data
    case command
    when :newsong
      data = response['room']['metadata']['current_song']
      @previous_song = @song || nil
      @song = Song.new  :id         => data['_id'],
                        :artist     => data['metadata']['artist'],
                        :title      => data['metadata']['song'],
                        :username   => data['djname'],
                        :userid     => data['djid'] 
      @song.update
      data = @song
    when :pmmed
      data = Message.new :id   => response['senderid'],
                         :type => 'pm',
                         :text => response['text']
    when :speak
      response["type"] = "chat"
      data = Message.new  :name => response['name'],
                          :id   => response['userid'],
                          :type => 'chat',
                          :text => response['text']
    when :update_votes
      data = response['room']['metadata']
      @song.update :up        => data['upvotes'],
                   :down      => data['downvotes'],
                   :listeners => data['listeners']

      data = response['room']['metadata']['votelog']
    when :registered
      data = User.new :name => response['user'][0]['name'], 
                      :id => response['user'][0]['userid'] 
    else
      data = response
    end

    @listeners[command].call data if @listeners[command]
  end

  def notify action, data = nil
    @listeners[action].call data if @listeners[action]
  end

  def presence type=nil
    type = @status if type.nil?
    request = {:api => "presence.update", :status => type }
    send request
  end

  def authenticate
    request = {:api => "user.authenticate"}
    send request
  end


  def roominfo
    request = { "api" => "room.info", "roomid" => @room }
    send request
  end


  def connect
    # another method that is pretty much identical to the ttapi
    uri = URI.parse "http://turntable.fm:80/api/room.which_chatserver?roomid=#{@room}"
    response = Net::HTTP.get_response uri
    response = JSON.parse response.body
    host, port = response[1]["chatserver"][0], response[1]["chatserver"][1]
    url = "ws://#{host}:#{port}/socket.io/websocket"
    @socket = WebSocket.new url
    register
  end

  def register
    request = {:api => 'room.register', :roomid => @room}
    send request, nil
  end

  def send request, callback = nil
    request[:msgid]     = @_msgId
    request[:clientid]  = @_clientId
    request[:userid]    = @user unless request[:userid]
    request[:userauth]  = @auth

    message = JSON.generate request
    heartbeat message
  end

  def heartbeat message
    @socket.send "~m~#{message.length}~m~#{message}"
    @_msgId += 1
  end

  def on action, &block
    @listeners[action] = block
  end

  def speak message
    request = {:api => 'room.speak', :roomid => @room, :text => message.to_s}
    send request
  end

  def pm user, message
      request = {:api => 'pm.send', 'receiverid' => user, 'text' => message }
      send request
  end

  def start_dj
    request = {"api" => "room.add_dj", "roomid" => @room }
    send request
  end

  def previous_song
    @previous_song || nil
  end

  def current_song
    # TODO: if no current song, query TT to get it.
    # currently this will only be set on newsong
    @song || nil
  end

  def vote direction=:up
    if @song
      direction = direction.to_s
      vh  = Digest::SHA1.hexdigest(@room + direction + @song.id)
      th  = Digest::SHA1.hexdigest(Random.rand.to_s)
      ph  = Digest::SHA1.hexdigest(Random.rand.to_s)
      request = { :api => 'room.vote', :roomid => @room, :val => direction, :vh => vh, :th => th, :ph => ph}
      send request
    end
  end

  class Song
    attr_reader :title, :artist, :id, :user, :up, :down, :listeners
    
    def initialize data={}
      @id     = data[:id] || nil
      @artist = data[:artist] || nil
      @title  = data[:title]  || nil
      @user   = User.new :name => data[:username],
                         :id   => data[:userid] 
    end

    def update data={}
      @up         = data[:up] || 0
      @down       = data[:down] || 0
      @listeners  = data[:listeners] || 0
    end
  end

  class Message
    attr_reader :user, :text, :type

    def initialize data={}
      @user       = User.new data
      @text       = data[:text] || nil
      @type       = data[:type] || nil
    end
  end

  class User
    attr_reader :name, :id

    def initialize data={}
      puts data
      @name = data[:name] || nil
      @id   = data[:id] || nil
    end
  end
end