class TurntableBot
  # attr_reader :admins

  def admins users=nil
    @admins = {}
    users.each do |admin|
      @admins[admin] = User.new(:id => admin)
    end
  end

  def is_admin? user
    @admins.include? user.id
  end

  def tell_admins message
    @admins.each do |id, admin|
      message admin, message
    end
  end

  def admin_said phrase, &block
    on :speak do |message|
      if is_admin? message.user
        phrase = [phrase] if [String, Regexp].include? phrase.class

        phrase.each do |listen_for|
          if message.text.match listen_for
            message.parts = message.text.match listen_for
            block.call message
            return
          end
        end
      end
    end
  end

  def admin_messaged phrase, &block
    on :pmmed do |message|
      if is_admin? message.user
        phrase = [phrase] if [String, Regexp].include? phrase.class

        phrase.each do |listen_for|
          if message.text.match listen_for
            message.parts = message.text.match listen_for
            block.call message
            break
          end
        end
      end
    end
  end
end