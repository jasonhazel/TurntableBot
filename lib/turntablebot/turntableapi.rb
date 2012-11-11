require "rubygems"
require "turntablebot/websocket"
require "uri"
require "net/http"
require "json"


class TurntableApi
  # this is the DSL magic



  def initialize
    @listeners  = {}
    @_msgId     = 0
    @_clientId  = "#{Time.now.to_i}-0.59633534294921572"
    @status     = "available"
  end

  def incoming data
    # this logic is pretty much identical to the ttapi version
    heartbeat_match = /~m~[0-9]+~m~(~h~[0-9]+)/
    if data =~ heartbeat_match
      heartbeat heartbeat_match.match(data)[1]
      # puts heartbeat_match.match(data).inspect
      @heartbeat = Time.now
      presence
      roominfo
      return
    end

    if data == "~m~10~m~no_session"
      authenticate
      presence
      return
    end
    Thread.new do
      delegate data
    end
  end

  def update_room_info response
    # puts response.inspect
    # puts @song.inspect

    @roominfo = response[:room]

    metadata = response['room']['metadata']
    # puts metadata['current_song']
    unless metadata['current_song'].nil?
      @song = Song.new  :id => metadata['current_song']['_id'],
                        :artist => metadata['current_song']['metadata']['artist'],
                        :title  => metadata['current_song']['metadata']['song'],
                        :username => metadata['current_song']['djname'],
                        :userid => metadata['current_song']['djid'],
                        :listeners => metadata['listeners'],
                        :up => metadata['upvotes'],
                        :down => metadata['downvotes']
      # @song.update
    end

    unless metadata['djs'].nil?
      @djs = metadata['djs']
    end
  end

  def djs
    @djs || []
  end

  def delegate data
    # puts data
    response = JSON.parse(data[data.index("{"), data.length])
    command = response['command'].to_sym if response['command']

    # @waiting_response[message].call (response) unless @waiting_response[message].nil?

    notify :data, response
    # handle special data
    case command
    when :newsong
      @previous_song = @song
      # update_room_info response
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
      @chat_message = data
    when :rem_dj
      # update_room_info response
    when :add_dj
      # update_room_info response
    when :update_votes
      # data = response['room']['metadata']
      # @song.update_votes :up        => data['upvotes'],
      #                    :down      => data['downvotes'],
      #                    :listeners => data['listeners']
      data = response['room']['metadata']['votelog']
    when :registered
      data = User.new :name => response['user'][0]['name'], 
                      :id => response['user'][0]['userid'] 
    else
      update_room_info response unless response['room'].nil?
      roominfo if @song.nil?
      data = response
    end

    # @listeners[command].call data if @listeners[command]
    notify command, data
    unless response['room'].nil?
      update_room_info response
      notify :roominfo, response
    end

  end

  def notify action, data = nil
    unless @listeners[action].nil?
      @listeners[action].each do |method|
        # puts method.inspect
        method.call(data) unless method.nil?
      end
    end
    # @listeners[action].call data if @listeners[action]
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
    send request
  end

  def send request={}
    request[:msgid]     = @_msgId
    request[:clientid]  = @_clientId
    request[:userid]    = @user unless request[:userid]
    request[:userauth]  = @auth


    message = JSON.generate request

    notify :data, message
    heartbeat message
  end

  def heartbeat message
    @socket.send "~m~#{message.length}~m~#{message}"
    @_msgId += 1
  end

  def on action, &block
    @listeners[action] = [] if @listeners[action].nil?

    @listeners[action].push block
  end

  def speak message
    send :api => 'room.speak', :roomid => @room, :text => message.to_s
  end

  def pm user, message
      send :api => 'pm.send', :receiverid => user, :text => message 
  end

  def add_dj
    send :api => "room.add_dj", :roomid => @room 
  end

  def rem_dj 
    send :api => "room.rem_dj", :roomid => @room 
  end

  def previous_song
    @previous_song || Song.new
  end

  def playlist_add index=0, playlist='default'
    send  :api => 'playlist.add',
          :playlist_name => playlist,
          :song_dict =>  { fileid: @song.id },
          :index => index ;
  end


  def snag
      sh = Digest::SHA1.hexdigest(Random.rand.to_s)
      fh = Digest::SHA1.hexdigest(Random.rand.to_s)
      i = [@user, @song.user.id, @song.id, @room, 'queue', 'board', 'false', 'false', sh]
      vh = Digest::SHA1.hexdigest(i.join('/'))


      send  :api      => 'snag.add',
            :djid     => @song.user.id,
            :songid   => @song.id,
            :roomid   => @room,
            :site     => 'queue',
            :location => 'board',
            :in_queue => 'false',
            :blocked  => 'false',
            :vh       => vh,
            :sh       => sh,
            :fh       => fh
  end

  def song
    @song || Song.new
  end

  def vote direction=:up
    unless @song.nil?
      direction = direction.to_s
      vh  = Digest::SHA1.hexdigest(@room + direction + @song.id)
      th  = Digest::SHA1.hexdigest(Random.rand.to_s)
      ph  = Digest::SHA1.hexdigest(Random.rand.to_s)
      send :api => 'room.vote', :roomid => @room, :val => direction, :vh => vh, :th => th, :ph => ph
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
      @listeners = data[:listeners]
      @up     = data[:up]
      @down   = data[:down]
      # update_votes data
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
      # puts data
      @name = data[:name] || nil
      @id   = data[:id] || nil
    end
  end


end