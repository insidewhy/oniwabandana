module Oniwabandana
  CriterionMatch = Struct.new :score, :idx, :multiplier

  class Match
    attr_reader :filename, :score

    def initialize filename
      @filename = filename
      @file_idx = filename.rindex('/') || 0
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
        offset = @matches.empty? ? 0 : @matches.last.idx + 1
        idx = @filename.index criteria.last, offset
        if idx.nil?
          @score = -1
        else
          multiplier = 1
          multiplier *= 2 if idx == 0 || '._/ '.index(@filename[idx - 1])
          multiplier *= 2 if idx >= @file_idx
          @matches << CriterionMatch.new(multiplier * 10, idx, multiplier)
          @score += @matches.last.score
        end
      else
        # the last criterion was updated
        offset = @matches.size > 1 ? @matches[-2].idx + 1 : 0
        idx = @filename.index criteria.last, offset
        if idx.nil?
          @score = -1
        else
          last_match = @matches.last
          @score += 10 * last_match.multiplier
          last_match.idx = idx
          last_match.score += 10 * last_match.multiplier
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
