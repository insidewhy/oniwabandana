require 'match'

module Oniwabandana
  class Window
    GLOBAL_ONLY_OPTS = {
      'hlsearch' => true, 'scrolloff' => true, 'omnifunc' => true
    }
    SELECTED_PREFIX = '> '
    REJECTED_PREFIX = ' ' * SELECTED_PREFIX.size

    def initialize opts
      @opts = opts
      @max_options = @opts.height - 1
      @selected_idx = 0 # of window entry from top
      @files = nil # all potential files
      @matched = nil # files matching current search parameters
      @rejected = nil # files not matching current search parameters
      @offset = 0 # current offset from first match
      @cursor_pos = 0 # cursor offset from left hand side
      @window = nil #
      @criteria = []
      # true at beginning or if space was previous key pressed
      @finished_criteria = true
    end

    def select offset
      new_sel_idx = @selected_idx + offset
      if new_sel_idx < 0
        @selected_idx = 0
        scroll new_sel_idx
      elsif new_sel_idx >= scroll_height
        @selected_idx = scroll_height - 1
        scroll(new_sel_idx - scroll_height + 1)
      else
        old_sel_idx = @selected_idx
        @selected_idx = new_sel_idx
        show_match @selected_idx
        show_match old_sel_idx
      end
    end

    def scroll_height
      @window.height - 1
    end

    def scroll offset
      new_offset = @offset + offset
      return if new_offset < 0 or new_offset > (@matched.length - @max_options)
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
      @matched = @files.map { |file| Match.new file, @opts }
      @rejected = []
      @max_options = [ @matched.size, @max_options ].min

      if @has_buffer
        VIM::command("silent! #{@max_options + 1} split SearchFiles")
        true
      else
        VIM::command("silent! #{@max_options + 1} new SearchFiles")
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
        set 'nowrap'
        @window = $curwin

        VIM::command "syntax match OniwaSelection \"^>.\\+$\""
        VIM::command "highlight link OniwaSelection PmenuSel"

        # create empty buffer space
        @max_options.times do
          # create empty lines in the buffer for manipulation later
          $curbuf.append(0, '')
        end
        # the cmd line always has a space at the end so the cursor can be there
        $curbuf.line = ' '

        @has_buffer = true
        false
      end
    end

    def accept
      # p "accept " + get_shown_match.filename
      VIM::command('call OniwaClose()')
      VIM::command("edit #{get_shown_match.filename}")
    end

    def close
      if @has_buffer
        VIM::command("silent! q!")
        @has_buffer = false
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
        '<C-c>' => 'Close',
        '<C-h>' => 'Backspace',
        '<BS>' => 'Backspace',
        # '<Esc>' => 'Hide' # messes with arrow keys
      }
      special.each { |key, val| map key, val }
    end

    def key_press key
      @selected_idx = @offset = 0
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
      restrict_match_criteria
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
        relax_match_criteria
      end
    end

    def show_matches
      # avoid copying the matched array in ruby 2.0+
      matched = @matched.respond_to?(:lazy) ? @matched.lazy : @matched
      matched.drop(@offset).take(@max_options).each_with_index do |match, idx|
        show_match idx, match
      end
    end

    private
    def map key, function, param = ''
      VIM::command "noremap <silent> <buffer> #{key} " \
        ":call Oniwa#{function}(#{param})<CR>"
    end

    # called after changes to @criteria to update matched
    def restrict_match_criteria
      # p @criteria
      @matched.each { |match| match.increase_score! @criteria }
      @matched.select! &:matching?
      @matched.sort!
      if @matched.size < $curbuf.count
        VIM::command("silent! resize #{@matched.size + 1}")
      end
      show_matches
    end

    def relax_match_criteria
      # p @criteria
      # todo: apply relaxation to @matched
      # todo: handle window size increase on relaxed match (after backspace)
    end

    def get_shown_match(idx_from_top = @selected_idx)
      @matched[@offset + idx_from_top]
    end

    def show_match idx, match = nil
      match ||= get_shown_match idx
      if idx == @selected_idx
        $curbuf[idx + 2] = SELECTED_PREFIX + match.filename + ' ' * @window.width
      else
        $curbuf[idx + 2] = REJECTED_PREFIX + match.filename
      end
    end

    def move_cursor offset
      @cursor_pos += offset
      $curwin.cursor = [ 0, @cursor_pos ]
    end
  end
end
