module Oniwabandana
  class CriteriaInput
    attr_accessor :criteria

    def initialize
      @criteria = []
      # true at beginning or if space was previous key pressed
      @finished_criteria = true
    end

    def backspace
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
      return false if @finished_criteria
      @finished_criteria = true
    end

    def add_to_criterion char
      if @finished_criteria
        @criteria << char
        @finished_criteria = false
      else
        @criteria[-1] += char
      end
    end
  end
end
