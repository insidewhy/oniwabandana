module Oniwabandana
  GREP_SUFFIX = 'grep: '

  class CriteriaInput
    attr_reader :criteria

    def initialize opts
      @opts = opts
      @criteria = []
      # true at beginning or if space was previous key pressed
      @finished_criteria = true
      @cursor_pos = 0 # cursor offset from left hand side
      @grep_pos = 0 # where the grep: cursor ends
    end

    def grep_mode? ; @grep_pos > 0 ; end

    def backspace
      if grep_mode?
        if @cursor_pos > @grep_pos
          $curbuf.line = $curbuf.line[0..-3] + ' '
          move_cursor -1
        else
          leave_grep_mode
        end
        return false
      end

      return false if @cursor_pos == 0

      $curbuf.line = $curbuf.line[0..-3] + ' '
      move_cursor -1

      if @finished_criteria
        @finished_criteria = false
        return false
      else
        @criteria[-1] = @criteria.last[0..-2]
        if @criteria.last.empty?
          @criteria.pop
          @finished_criteria = true
        end
        return true
      end
    end

    def finish_criterion
      return if @finished_criteria
      @finished_criteria = true
      $curbuf.line += ' '
      move_cursor 1
    end

    def add_to_criterion char
      if @finished_criteria
        @criteria << char
        @finished_criteria = false
      else
        @criteria[-1] += char
      end

      # replace old space at end with char and add a new one after it
      entry_append char
    end

    def enter_grep_mode
      return if grep_mode?
      suffix = @criteria.empty? ? '' : ' '
      suffix += GREP_SUFFIX
      @grep_pos = $curbuf.line.length + suffix.length - 1
      entry_append suffix

      # keys for grep mode
      special = {
        @opts.accept => 'Accept',
        '<Left>' => 'Ignore',
        '<Right>' => 'Ignore',
        @opts.close => 'Close',
        @opts.backspace => 'Backspace',
        '<BS>' => 'Backspace',
      }
      special.each { |key, val| map key, val }
    end

    def leave_grep_mode
      return unless grep_mode?
      if @criteria.empty?
        $curbuf.line = ' '
        set_cursor 0
      else
        idx = @grep_pos - GREP_SUFFIX.length - 1
        $curbuf.line = $curbuf.line[0...idx] + ' '
        set_cursor idx
      end
      enter_search_mode
    end

    def enter_search_mode
      @grep_pos = 0
      register_search_keys
    end

    def entry_append str
      $curbuf.line = $curbuf.line[0..-2] + str + ' '
      move_cursor str.length
    end

    private
    def register_search_keys
      numbers     = ('0'..'9').to_a.join
      lowercase   = ('a'..'z').to_a.join
      uppercase   = lowercase.upcase
      punctuation = '<>`@#~!"$%&/()=+*-_.,;:?\\\'{}[] ' # and space
      (numbers + lowercase + uppercase + punctuation).each_byte do |b|
        map "<Char-#{b}>", 'HandleKey', b
      end
      special = {
        @opts.open => 'Open',
        @opts.tabopen => 'OpenInNewTab',
        @opts.tabopen_all => 'OpenAllInNewTab',
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

    def map key, function, param = ''
      VIM::command "noremap <silent> <buffer> #{key} " \
        ":call Oniwa#{function}(#{param})<CR>"
    end

    def move_cursor offset
      set_cursor @cursor_pos + offset
    end

    def set_cursor col
      @cursor_pos = col
      $curwin.cursor = [ 0, @cursor_pos ]
    end
  end
end
