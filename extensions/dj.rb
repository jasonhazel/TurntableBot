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
      if not djs.nil? and  djs.length <= 1 and not djs.include? @user and not @waiting_on_room
        @waiting_on_room = true
        block.call
        @waiting_on_room = false
      end
    end
  end

  def am_i? user
    @user == user.id unless user.nil?
  end

  def is_dj? user
    @djs.include? user
  end

  def when_enough_djs &block
    on :roominfo do
      @djs = {} if @djs.nil?


      count = @djs.length || 5 # if error with number of djs, assume full.
      if not djs.nil? and djs.length > 2 and is_dj? @user and not @waiting_on_room and not am_i? song.dj
        @waiting_on_room = true
        block.call
        @waiting_on_room = false
      end
    end
  end

  def djs
    @djs
  end
end