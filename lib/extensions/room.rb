class TurntableBot

  def someone_entered &block
    on :registered do |user|
      block.call(user) unless user.id == @user
    end
  end

  def i_entered &block
    on :registered do |user|
      block.call(user) if user.id == @user
    end
    # roominfo
  end

  def someone_said phrase, &block
    on :speak do |message|
      unless message.user.id == @user
        block.call(message) if message.text == phrase
      end
    end
  end

  def someone_mentioned phrases, &block
    on :speak do |message|
      unless message.user.id == @user
        block.call(message) if phrases.include? message.text
      end
    end
  end
  def song_ended &block
    on :newsong do |song|
      block.call(previous_song)
    end
  end

  def song_started &block
    on :newsong do |song|
      block.call(song)
    end
  end

  def heart song_to_snag=nil
    playlist_add song_to_snag
  end

  def say message
    speak message
  end

  def upvote
    vote :up
  end

  def downvote
    vote :down
  end

  def lame
    vote :down
  end

  def awesome
    vote :up
  end
end