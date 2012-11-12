class TurntableBot
  def message user, with
    pm user.id, with
  end

  def message_recieved_saying phrase, &block
    on :pmmed do |message|
      block.call(message) if message.text == phrase
    end
  end
  def message_recieved_mentioning phrase, &block
    on :pmmed do |message|
      block.call(message) if message.text.include? phrase
    end
  end
end