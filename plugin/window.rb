require 'match'
require 'criteria_input'

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
      @window = nil #
      @criteria_input = CriteriaInput.new
      @grep_mode = false
    end

    def criteria ; @criteria_input.criteria ; end

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
      if @grep_mode
        # TODO: apply grep pattern then leave grep mode
      else
        VIM::command('call OniwaClose()')
        VIM::command("edit #{get_shown_match.filename}")
      end
    end

    def accept_in_new_tab
      VIM::command('call OniwaClose()')
      if @opts.smart_tabopen and $curbuf.name.nil? and VIM::evaluate('&modified') == 0
        VIM::command("edit #{get_shown_match.filename}")
      else
        VIM::command("#{@opts.tabopen_cmd} #{get_shown_match.filename}")
      end
    end

    def accept_all_in_new_tab
      VIM::command('call OniwaClose()')
      @matched.each do |match|
        VIM::command("#{@opts.tabopen_cmd} #{match.filename}")
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
        @opts.tabopen => 'AcceptInNewTab',
        @opts.tabopen_all => 'AcceptAllInNewTab',
        '<Left>' => 'Ignore',
        '<Right>' => 'Ignore',
        @opts.select_prev => 'SelectPrev',
        @opts.select_next  => 'SelectNext',
        @opts.close => 'Close',
        @opts.backspace => 'Backspace',
        '<BS>' => 'Backspace',
        @opts.grep => 'Grep',
        # '<Esc>' => 'Hide' # messes with arrow keys
      }
      special.each { |key, val| map key, val }
    end

    def key_press key
      if @grep_mode
        grep_key_press key
      else
        search_key_press key
      end
    end

    def backspace
      if @grep_mode
        # TODO: backspace or leave grep mode if at beginning
      else
        relax_match_criteria if @criteria_input.backspace
      end
    end

    def show_matches
      # avoid copying the matched array in ruby 2.0+
      matched = @matched.respond_to?(:lazy) ? @matched.lazy : @matched
      matched.drop(@offset).take(@n_matches_shown).each_with_index do |match, idx|
        show_match idx, match
      end
    end

    def enter_grep_mode
      return if @grep_mode
      @grep_mode = true
      suffix = criteria.empty? ? '' : ' '
      suffix += 'grep: '
      @criteria_input.entry_append suffix
      @criteria_input.move_cursor suffix.length
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
      @matched.each { |match| match.increase_score! criteria }
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
      if criteria.size == 0
        @rejected = []
        @matched = @files.map { |file| Match.new file, @opts }
      else
        @matched.each { |match| match.decrease_score! criteria }
        @rejected.reject! do |match|
          match.calculate_score! criteria
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

    def search_key_press key
      @selected_idx = @offset = 0
      char = key.to_i.chr
      if char == ' '
        @criteria_input.finish_criterion
      else
        @criteria_input.add_to_criterion char
        restrict_match_criteria
      end
    end

    def grep_key_press key
      char = key.to_i.chr
      @criteria_input.entry_append char
      @criteria_input.move_cursor 1
    end
  end
end
