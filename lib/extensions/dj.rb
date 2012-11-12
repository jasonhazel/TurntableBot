class TurntableBot
  def start_djing
    add_dj
  end

  def stop_djing
    rem_dj
  end

  def skip_song
    stop_song
  end

  def when_solo_dj &block
    on :roominfo do
      if djs.length <= 1 and not djs.include? @user and not @waiting_on_room
        @waiting_on_room = true
        block.call
        @waiting_on_room = false
      end
    end
  end

  def when_enough_djs &block
    on :roominfo do
      if djs.length > 2 and djs.include? @user and not @waiting_on_room and not song.user.id @user
        @waiting_on_room = true
        block.call
        @waiting_on_room = false
      end
    end
  end


  def tell_djs message
    @djs.each do |id, dj|
      message dj, message
    end
  end  

end