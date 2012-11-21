class TurntableBot

  def someone_entered &block
    on :registered do |user|
      block.call(user) unless user.include? @user
    end
  end

  def i_entered &block
    on :registered do |user|
      block.call(user) if user.include? @user
    end
    # roominfo
  end

  def someone_said phrase, &block
    on :speak do |message|
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

  def song_ended &block
    on :previous_song do |song|
      block.call(song) unless song.nil?
    end
  end

  def song_started &block
    on :new_song do |song|
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