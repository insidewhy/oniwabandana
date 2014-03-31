module Oniwabandana
  CriterionMatch = Struct.new :score, :idx

  class Match
    attr_reader :filename, :score

    def initialize filename
      @filename = filename
      @score = 0
      # match info one per criterion
      @matches = []
    end

    # Update @score after criteria has been extended.
    # Params:
    # +criteria+:: Array of strings to apply as criteria.
    def increase_score! criteria
      if criteria.last.size == 1
        # the last criterion is new
        offset = @matches.empty? ? 0 : @matches.last.idx
        idx = @filename.index criteria.first, offset
        if idx.nil?
          @score = -1
        else
          @score += 10
          @matches << CriterionMatch.new(10, idx)
        end
      else
        # the last criterion was updated
        offset = @matches.size > 1 ? @matches[-2].idx : 0

        idx = @filename.index criteria.last, offset
        if idx.nil?
          @score = -1
        else
          @score += 10
          @matches[-1].idx = idx
          @matches[-1].score += 10
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
