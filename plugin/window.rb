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
      @n_matches_shown = @opts.height - 1
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
      return if new_offset < 0 or new_offset > (@matched.length - @n_matches_shown)
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
      @n_matches_shown = [ @matched.size, @n_matches_shown ].min

      if @has_buffer
        VIM::command("silent! #{@n_matches_shown + 1} split SearchFiles")
        true
      else
        VIM::command("silent! #{@n_matches_shown + 1} new SearchFiles")
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
        @n_matches_shown.times do
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

    def accept_in_new_tab
      VIM::command('call OniwaClose()')
      VIM::command("tabe #{get_shown_match.filename}")
    end

    def accept_smart
      VIM::command('call OniwaClose()')
      if $curbuf.name.nil? and VIM::evaluate('&modified') == 0
        VIM::command("edit #{get_shown_match.filename}")
      else
        VIM::command("tabe #{get_shown_match.filename}")
      end
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
        @opts.open => 'Accept',
        @opts.open_smart => 'AcceptSmart',
        @opts.tabopen => 'AcceptInNewTab',
        '<Left>' => 'Ignore',
        '<Right>' => 'Ignore',
        '<Up>' => 'SelectPrev',
        '<Down>' => 'SelectNext',
        @opts.close => 'Close',
        @opts.backspace => 'Backspace',
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
      matched.drop(@offset).take(@n_matches_shown).each_with_index do |match, idx|
        show_match idx, match
      end
    end

    private
    def recalculate_window_height
      @n_matches_shown = [ @matched.size, @opts.height - 1 ].min
      if @n_matches_shown != $curbuf.count
        VIM::command("silent! resize #{@n_matches_shown + 1}")
      end
    end

    def map key, function, param = ''
      VIM::command "noremap <silent> <buffer> #{key} " \
        ":call Oniwa#{function}(#{param})<CR>"
    end

    # called after changes to @criteria to update matched
    def restrict_match_criteria
      # p @criteria
      @matched.each { |match| match.increase_score! @criteria }
      @matched.select! do |match|
        if match.matching?
          true
        else
          @rejected << match
          false
        end
      end
      @matched.sort!
      show_matches
      recalculate_window_height
    end

    def relax_match_criteria
      # p @criteria
      if @criteria.size == 0
        @rejected = []
        @matched = @files.map { |file| Match.new file, @opts }
      else
        @matched.each { |match| match.decrease_score! @criteria }
        @rejected.reject! do |match|
          match.calculate_score! @criteria
          if match.score != -1
            @matched << match
            true
          end
        end
        @matched.sort!
      end
      show_matches
      recalculate_window_height
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
