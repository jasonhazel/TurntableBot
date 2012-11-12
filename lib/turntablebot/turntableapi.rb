require "rubygems"
require "turntablebot/websocket"
require "uri"
require "net/http"
require "json"


class TurntableApi
  # this is the DSL magic

  attr_reader :djs, :users

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
    metadata = response['room']['metadata']

    unless response['users'].nil?
      users = response['users']
      @users = {}
      users.each do |user_info|
        user = User.new :id => user_info['_id'], :name => user_info['name']
        @users[user.id] = user
      end
    end

    unless metadata['current_song'].nil?
      @song = Song.new  :id => metadata['current_song']['_id'],
                        :artist => metadata['current_song']['metadata']['artist'],
                        :title  => metadata['current_song']['metadata']['song'],
                        :username => metadata['current_song']['djname'],
                        :userid => metadata['current_song']['djid'],
                        :listeners => metadata['listeners'],
                        :up => metadata['upvotes'],
                        :down => metadata['downvotes']
    end

    unless metadata['djs'].nil?
      @djs = {}
      metadata['djs'].each do |userid|
        @djs[userid] = @users[userid]
      end
    end

    notify :roominfo, response
  end

  def delegate data
    response = JSON.parse(data[data.index("{"), data.length])
    command = response['command'].to_sym if response['command']

    notify response['msgid'], response

    notify :data, response

    case command
    when :newsong
      @previous_song = @song
      # update_room_info response
      data = @song
    when :add_dj
      roominfo
    when :rem_dj
      roominfo
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
    when :update_votes
      data = response['room']['metadata']['votelog']
    when :registered
      data = User.new :name => response['user'][0]['name'], 
                      :id => response['user'][0]['userid'] 
    else
      data = response
    end

    unless response['room'].nil?
      update_room_info response
    end

    notify command, data
  end

  def notify action, data = nil
    unless @listeners[action].nil?
      @listeners[action].each do |method|
        method.call(data) unless method.nil?
      end
    end
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
    send :api => "room.info", :roomid => @room
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
    send :api => 'room.register', 
         :roomid => @room
  end

  def send request={}
    request[:msgid]     = @_msgId
    request[:clientid]  = @_clientId
    request[:userid]    = @user unless request[:userid]
    request[:userauth]  = @auth


    message = JSON.generate request

    notify :data, message
    message_id = @_msgId
    heartbeat message
    message_id
  end

  def get_user_id name
    send :api => 'user.get_id', :name => name
  end

  def heartbeat message
    @socket.send "~m~#{message.length}~m~#{message}"
    @_msgId += 1
  end

  def waiting_on message_id, &block
    @listeners[message_id] = block
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

  def stop_song
    send :api => "room.stop_song", :roomid => @room
  end

  def previous_song
    @previous_song || Song.new
  end

  def playlist_add song=nil, index=0, playlist='default'
    song = @song if song.nil?

    send  :api => 'playlist.add',
          :playlist_name => playlist,
          :song_dict =>  { :fileid => song.id },
          :index => index
  end


  def snag song_to_snag=nil
      song_to_snag = @song if song_to_snag.nil?

      sh = Digest::SHA1.hexdigest(Random.rand.to_s)
      fh = Digest::SHA1.hexdigest(Random.rand.to_s)
      i = [@user, song_to_snag.user.id, song_to_snag.id, @room, 'queue', 'board', 'false', 'false', sh]
      vh = Digest::SHA1.hexdigest(i.join('/'))


      send  :api      => 'snag.add',
            :djid     => song_to_snag.user.id,
            :songid   => song_to_snag.id,
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
    attr_reader :user, :text, :type, :parts
    attr_accessor :parts

    def initialize data={}
      @user       = User.new data
      @text       = data[:text] || nil
      @type       = data[:type] || nil
      @parts      = []
    end
  end

  class User
    attr_reader :name, :id

    def initialize data={}
      @name = data[:name] || nil
      @id   = data[:id] || nil
    end
  end

end
