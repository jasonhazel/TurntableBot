require_relative "./turntablebot/turntableapi.rb"

class TurntableBot < TurntableApi
  
  def self.create &block
    bot = TurntableBot.new
    # begin
      bot.instance_eval(&block)
      bot.connect  
    # rescue Exception => e
    #   puts e.inspect
    #   bot.tell_admins "Crashing... #{e.inspect}"
    #   bot.deregister
    # end
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

  def when_ready &block
    on :incoming do |data|
      process_incoming(data)
    end

    on :ready do
      roominfo
      block.call
    end
  end

  def process_incoming response=nil
    return if response.nil?

    command = response['command'].to_sym if response['command']
    notify response['msgid'], response if response['msgid']
    notify :data, response

    if response['users']
      @users = {}
      response['users'].each do |user|
        @users[user['userid']] = User.new :id => user['userid'],
                                          :name   => user['name'],
                                          :points => user['points']
      end
    end

    if response['room']
      metadata = response['room']['metadata']

      if metadata['djs']
        @djs = {}
        metadata['djs'].each do |id|
          @djs[id] = User.new :id => id
        end
      end
      
      @previous_song = @song if command == :newsong

      if metadata['current_song']
        @song = Song.new :id     => metadata['current_song']['_id'], 
                         :title  => metadata['current_song']['metadata']['song'],
                         :artist => metadata['current_song']['metadata']['artist'],
                         :album  => metadata['current_song']['metadata']['album'],
                         :dj     => @users[metadata['current_dj']]
                       
      end

      unless @song.nil?
        @song.up        = metadata['upvotes']
        @song.down      = metadata['downvotes']
        @song.listeners = metadata['listeners']
      end

      notify :roominfo, response
    end

    if command
      case command
      when :speak
        notify :speak, Message.new(:user => @users[response['userid']] ,
                                   :text   => response['text'],
                                   :type   => :chat)
      when :newsong
        notify :previous_song, @previous_song unless @previous_song.nil?
        notify :new_song, @song
        notify :newsong, @song
      when :pmmed
        notify :pmmed, Message.new(:user => User.new(:id => response['senderid']),
                                   :text   => response['text'],
                                   :type   => :pm)
      when :registered
        new_users = {}
        response['user'].each do |user|
          new_users[user['userid']] = User.new(:name => user['name'],
                                               :id   => user['userid'])
        end

        notify :registered, new_users
        # roominfo
      when :deregistered
        old_users = {}
        response['user'].each do |user|
          old_users[user['userid']] = User.new(:name => user['name'],
                                               :id   => user['userid'])
        end
        notify :deregistered, old_users
        # roominfo
      when :add_dj
        notify :add_dj, response
        roominfo
      when :rem_dj
        notify :rem_dj, response
        roominfo
      when :snagged
        @song.hearts = @song.hearts+1
        puts
        notify :snagged, response
      else
        notify command, response
      end
    end
  end

  def log &block
    on :data do |data|
      block.call data
    end
  end

  class User
    attr_accessor :id, :name, :points

    def initialize args={}
      @id     = args[:id]
      @name   = args[:name]
      @points = args[:points]
    end
  end

  class Message
    attr_accessor :user, :text, :type, :parts
    def initialize args={}
      @user = args[:user]
      @text = args[:text]
      @type = args[:type] 
    end
  end

  class Song
    attr_accessor :id, :title, :artist, :dj, :up, :down, :listeners, :hearts
    def initialize args={}
      @id         = args[:id]
      @title      = args[:title]
      @artist     = args[:artist]
      @dj         = args[:dj]
      @up         = args[:up]
      @down       = args[:down]
      @listeners  = args[:listeners]
      @hearts     = args[:hearts] || 0
    end
  end

  class Room
    attr_accessor :id, :djs, :users, :song
  end

end