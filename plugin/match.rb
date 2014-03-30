module Oniwabandana
  class Match
    attr_reader :filename, :score, :matches

    def initialize filename
      @filename = filename
      @score = 0
      @matches = []
    end

    def calculate_score! criteria
      if criteria.last.size == 1
        offset = @matches.empty? ? 0 : @matches.last
        idx = @filename.index criteria.first, offset
        if idx.nil?
          @score = -1
        else
          @score += 10
          @matches << idx
        end
      else
        return if @score < 0
        offset = @matches.size > 1 ? @matches[-2] : 0

        idx = @filename.index criteria.last, offset
        if idx.nil?
          @score = -1
        else
          @score += 10
          @matches[-1] = idx
        end
      end
    end

    def <=> rhs
      @score <=> rhs.score
    end

    def matching?
      @score >= 0
    end
  end
end
