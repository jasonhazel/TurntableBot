class TurntableBot
  def message user, with
    pm user.id, with
  end


  def someone_messaged phrase, &block
    on :pmmed do |message|
      phrase = [phrase] if [String, Regexp].include? phrase.class

      phrase.each do |listen_for|
        if listen_for.match message.text
          message.parts = message.text.match listen_for
          block.call message
          break
        end
      end
    end
  end
end