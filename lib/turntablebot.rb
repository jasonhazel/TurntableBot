require_relative "./turntablebot/turntableapi.rb"

class TurntableBot < TurntableApi
  
  attr_reader :djs

  def self.create &block
    bot = TurntableBot.new
    # begin
      bot.instance_eval(&block)
      bot.activate  
    # rescue Exception => e
    #   puts e.inspect
    #   bot.tell_admins "Crashing... #{e.inspect}"
    #   bot.disconnect
    # end
  end

  def disconnect
    send :api => "room.deregister", :roomid => @room
  end

  def activate
    connect
    notify :ready

    while data = @socket.receive
      incoming data
    end
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
    on :ready do
      block.call
      roominfo
    end
  end

  def log &block
    on :data do |data|
      block.call data
    end
  end
end