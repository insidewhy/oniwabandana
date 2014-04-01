module Oniwabandana
  CriterionIndex = Struct.new :index, :multiplier
  CriterionMatch = Struct.new :score, :indexes

  class Match
    attr_reader :filename, :score, :matches

    def initialize filename, opts
      @filename = filename
      @matchname = opts.case_sensitive ? filename : filename.downcase
      @file_idx = filename.rindex('/') || 0
      @score = 0
      # match info one per criterion
      @matches = []
    end

    def calculate_multiplier idx
      multiplier = 1
      multiplier *= 2 if idx == 0 || '._/ '.index(@matchname[idx - 1])
      multiplier *= 2 if idx >= @file_idx
      multiplier
    end

    # Update @score after criteria has been extended.
    # Params:
    # +criteria+:: Array of strings to apply as criteria.
    def increase_score! criteria
      crit_size = criteria.last.size
      if crit_size == 1
        # the last criterion is new
        offset = @matches.empty? ? 0 : @matches.last.indexes.first.index + 1
        idx = @matchname.index criteria.last, offset
        if idx.nil?
          @score = -1
        else
          multiplier = calculate_multiplier idx
          match = CriterionMatch.new(multiplier, [CriterionIndex.new(idx, multiplier)])
          @matches << match
          # search for the criterion multiple times
          while true
            idx = @matchname.index criteria.last, idx + 1
            break if idx.nil?
            multiplier = calculate_multiplier idx
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
            index = @matchname.index criteria.last, idx.index
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

    # Update @score after criteria has been reduced.
    # Params:
    # +criteria+:: Array of strings to apply as criteria.
    def decrease_score! criteria
      if @matches.size > criteria.size
        # lost criterion from the end
        @score -= @matches.pop.score
      else
        criterion = criteria.last

        # recalculate final criterion's score
        match = @matches.last
        match.indexes = []
        @score -= match.score
        match.score = 0

        # by searching for the criterion again
        idx = @matches.size > 1 ? @matches[-2].indexes.first.index + 1 : -1
        while true
          idx = @matchname.index criterion, idx + 1
          break if idx.nil?
          multiplier = calculate_multiplier idx
          match.indexes << CriterionIndex.new(idx, multiplier)
          match.score += multiplier * criterion.size
        end
        @score += match.score
      end
    end

    # Recalculate @score from criteria.
    # Params:
    # +criteria+:: Array of strings to apply as criteria.
    def calculate_score! criteria
      # todo:
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
