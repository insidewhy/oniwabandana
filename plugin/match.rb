module Oniwabandana
  CriterionIndex = Struct.new :index, :multiplier
  CriterionMatch = Struct.new :score, :indexes

  class Match
    attr_reader :filename, :score, :matches

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
      crit_size = criteria.last.size
      if crit_size == 1
        # the last criterion is new
        offset = @matches.empty? ? 0 : @matches.last.indexes.first.index + 1
        idx = @filename.index criteria.last, offset
        if idx.nil?
          @score = -1
        else
          multiplier = 1
          calc_multiplier = proc do
            multiplier = 1
            multiplier *= 2 if idx == 0 || '._/ '.index(@filename[idx - 1])
            multiplier *= 2 if idx >= @file_idx
          end
          calc_multiplier.call

          match = CriterionMatch.new(multiplier, [CriterionIndex.new(idx, multiplier)])
          @matches << match
          # search for the criterion multiple times
          while true
            idx = @filename.index criteria.last, idx + 1
            # todo: recalculate multiplier
            break if idx.nil?
            calc_multiplier.call
            match.indexes << CriterionIndex.new(idx, multiplier)
            match.score += multiplier
          end

          @score += match.score
        end
      else
        # the last criterion was updated
        match = @matches.last
        @score -= match.score
        match.score = 0

        prev_idx = index_idx = -1
        # use previous set of indexes as a guide to find next indexes
        fail_idx = match.indexes.index do |idx|
          if idx.index < prev_idx
            false
          elsif idx.index == prev_idx
            # catchup from previous iteration
            match.indexes[index_idx += 1].multiplier = idx.multiplier
            match.indexes[index_idx].index = prev_idx
            match.score += idx.multiplier * crit_size
            false
          else
            index = @filename.index criteria.last, idx.index
            if index.nil?
              true
            else
              # make sure the correct multiplier is used
              if index == idx.index
                match.indexes[index_idx += 1].index = index
                match.score += idx.multiplier * crit_size
              end
              prev_idx = index
              false
            end
          end
        end

        if match.indexes.size >= index_idx + 1
          match.indexes = match.indexes[0..index_idx]
        end

        if fail_idx == 0
          @score = -1
        else
          @score += match.score
        end
      end
    end

    # reverse order as higher score should be ranked first
    def <=> rhs
      rhs.score <=> @score
    end

    def matching?
      @score >= 0
    end
  end
end
