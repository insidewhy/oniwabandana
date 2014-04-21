module Oniwabandana
  class CriteriaInput
    attr_accessor :criteria

    def initialize
      @criteria = []
      # true at beginning or if space was previous key pressed
      @finished_criteria = true
      @cursor_pos = 0 # cursor offset from left hand side
    end

    def backspace
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
      move_cursor 1
    end

    def entry_append str
      $curbuf.line = $curbuf.line[0..-2] + str + ' '
    end

    def move_cursor offset
      @cursor_pos += offset
      $curwin.cursor = [ 0, @cursor_pos ]
    end
  end
end
