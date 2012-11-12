class TurntableBot
  attr_reader :admins

  def admins users=nil
    @admins ||= users
  end

  def is_admin? user
    @admins.include? user.id
  end

  def tell_admins message
    @admins.each do |admin|
      message User.new(:id => admin), message
    end
  end

  def admin_said phrase, &block
    on :speak do |message|
      if is_admin? message.user
        block.call(message) if message.text == phrase
      end
    end
  end

  def admin_mentioned phrases, &block
    on :soeak do |message|
      if is_admin? message.user
        block.call(message) if phrases.include? message.text
      end
    end
  end

  def admin_messaged_saying phrase, &block
    on :pmmed do |message|
      block.call(message) if is_admin? message.user and message.text == phrase
    end
  end

  def admin_messaged_mentioning phrases, &block
    on :pmmed do |message|
      block.call(message) if is_admin? message.user and phrases.include? message.text
    end
  end

  def admin_messaged_matching pattern, &block
    on :pmmed do |message|
      if is_admin? message.user
        message.parts = message.text.match pattern
        block.call(message) unless message.parts.nil?
      end
    end
  end
end