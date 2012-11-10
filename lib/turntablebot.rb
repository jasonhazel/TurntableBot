require_relative "./turntablebot/turntableapi.rb"

class TurntableBot < TurntableApi
  
  def self.create &block
    bot = TurntableBot.new
    bot.instance_eval(&block)
    bot.activate
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


  def admins users
    @admins = users
  end

  def is_admin? user
    @admins.include? user.id unless @admins.nil?
  end

  def someone_said phrase, &block
    on :speak do |message|
      unless message.user.id == @user
        block.call(message) if message.text == phrase
      end
    end
  end

  def admin_said phrase, &block
    on :speak do |message|
      if is_admin? message.user
        block.call(message) if message.text == phrase
      end
    end
  end

  def someone_mentioned phrase, &block
    on :speak do |message|
      unless message.user.id == @user
        block.call(message) if message.text.include? phrase
      end
    end
  end

  def admin_mentioned phrase, &block
    on :soeak do |message|
      if is_admin? message.user
        block.call(message) if message.text.include? phrase
      end
    end
  end

  def respond_to message, with
    pm message.user.id, with
  end

  def message_recieved_saying phrase, &block
    on :pmmed do |message|
      block.call(message) if message.text == phrase
    end
  end

  def admin_messaged_saying phrase, &block
    on :pmmed do |message|
      block.call(message) if is_admin? message.user and message.text == phrase
    end
  end

  def message_recieved_mentioning phrase, &block
    on :pmmed do |message|
      block.call(message) if message.text.include? phrase
    end
  end

  def start_djing
    add_dj
  end

  def stop_djing
    rem_dj
  end

  def say message
    speak message
  end

  def log &block
    on :data do |data|
      block.call data
    end
  end
end