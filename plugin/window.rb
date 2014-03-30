require 'match'

module Oniwabandana
  class Window
    GLOBAL_ONLY_OPTS = { 'hlsearch' => true, 'scrolloff' => true, 'omnifunc' => true  }
    SELECTED_PREFIX = '> '

    def initialize opts
      @opts = opts
      @max_options = @opts.height - 1
      @selected_idx = 0 # of window entry from top
      @files = nil # all potential files
      @matches = nil # files matching current search paramters
      @offset = 0 # current offset from first match
      @cursor_pos = 0 # cursor offset from left hand side
      @criteria = []
      # true at beginning or if space was previous key pressed
      @finished_criteria = true
    end

    def show_matches
      if @matches.size < $curbuf.count
        VIM::command("silent! resize #{@matches.size + 1}")
      end
      # todo: handle window size increase on relaxed match (after backspace)

      # avoid copying the matches array in ruby 2.0+
      matches = @matches.respond_to?(:lazy) ? @matches.lazy : @matches
      matches.drop(@offset).take(@max_options).each_with_index do |match, idx|
        prefix = idx == @selected_idx ? '> ' : '  '
        $curbuf[idx + 2] = prefix + match.filename
      end
    end

    def select offset
      new_sel_idx = @selected_idx + offset
      if new_sel_idx < 0
        scroll new_sel_idx
        @selected_idx = 0
      elsif new_sel_idx >= @max_options
        scroll(new_sel_idx - @max_options + 1)
        @selected_idx = @max_options - 1
      else
        $curbuf[@selected_idx + 2] = '  ' + $curbuf[@selected_idx + 2][2..-1]
        $curbuf[new_sel_idx + 2] = '> ' + $curbuf[new_sel_idx + 2][2..-1]
        @selected_idx = new_sel_idx
      end
    end

    def scroll offset
      new_offset = @offset + offset
      return if new_offset < 0 or new_offset > (@matches.length - @max_options)
      @offset = new_offset
      show_matches
    end

    def set cmd
      name = cmd.gsub /^no|=.*$|<$/, ''
      if GLOBAL_ONLY_OPTS[name]
        VIM::command("silent! SetBufferLocal #{cmd}")
      else
        VIM::command("setlocal #{cmd}")
      end
    end

    def show files
      @files = files
      @matches = @files.map { |file| Match.new file }

      if @has_buffer
        VIM::command("silent! #{@opts.height} split SearchFiles")
        true
      else
        VIM::command("silent! #{@opts.height} new SearchFiles")
        set 'nohlsearch'
        set 'noinsertmode'
        set 'buftype=nofile'
        # set 'nomodifiable'
        set 'noswapfile'
        set 'nocursorline'
        set 'nospell'
        set 'nobuflisted'
        set 'textwidth=0'
        set 'scrolloff=0'
        @has_buffer = true

        @max_options.times do
          # create empty lines in the buffer for manipulation later
          $curbuf.append(0, '')
        end
        # the cmd line always has a space at the end so the cursor can be there
        $curbuf.line = ' '
        false
      end
    end

    def register_for_keys
      numbers     = ('0'..'9').to_a.join
      lowercase   = ('a'..'z').to_a.join
      uppercase   = lowercase.upcase
      punctuation = '<>`@#~!"$%&/()=+*-_.,;:?\\\'{}[] ' # and space
      (numbers + lowercase + uppercase + punctuation).each_byte do |b|
        map "<Char-#{b}>", 'HandleKey', b
      end
      special = {
        '<CR>' => 'Accept',
        '<Left>' => 'Ignore',
        '<Right>' => 'Ignore',
        '<Up>' => 'SelectPrev',
        '<Down>' => 'SelectNext',
        '<C-c>' => 'Hide',
        '<C-h>' => 'Backspace',
        '<BS>' => 'Backspace',
        # '<Esc>' => 'Hide' # messes with arrow keys
      }
      special.each do |key, val|
        map key, val
      end
    end

    def map key, function, param = ''
      ::VIM::command "noremap <silent> <buffer> #{key} " \
        ":call Oniwa#{function}(#{param})<CR>"
    end

    def key_press key
      char = key.to_i.chr
      if char == ' '
        unless @finished_criteria
          $curbuf.line += ' '
          move_cursor 1
          @finished_criteria = true
        end
        return
      end

      if @finished_criteria
        @criteria << char
        @finished_criteria = false
      else
        @criteria[-1] += char
      end

      # replace old space at end with char and add a new one after it
      $curbuf.line = $curbuf.line[0..-2] + char + ' '
      move_cursor 1
      update_matches
    end

    # called after changes to @criteria to update matches
    def update_matches
      p @criteria
      @matches.each { |match| match.calculate_score! @criteria }
      @matches.select! &:matching?
      @matches.sort!
      show_matches
    end

    def move_cursor offset
      @cursor_pos += offset
      $curwin.cursor = [ 0, @cursor_pos ]
    end

    def backspace
      return if @cursor_pos == 0
      $curbuf.line = $curbuf.line[0..-3] + ' '
      move_cursor -1
      if @finished_criteria
        @finished_criteria = false
      else
        @criteria[-1] = @criteria.last[0..-2]
        if @criteria.last.empty?
          @criteria.pop
          @finished_criteria = true
        end
        # todo: update matches based on new criteria
        update_matches
      end
    end

    def accept
      p "accept"
    end

    def hide
      VIM::command("silent! hide") if @has_buffer
    end
  end
end
