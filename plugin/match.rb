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
      if idx == 0 || '._/ '.index(@matchname[idx - 1]) ||
      (is_upper?(@filename[idx]) && is_lower?(@filename[idx - 1]))
        multiplier *= 2
      end
      multiplier *= 2 if idx >= @file_idx
      multiplier
    end

    # Update @score after criteria has been extended.
    # Pre: @score != -1
    # Params:
    # +criteria+:: Array of strings to apply as criteria.
    def increase_score! criteria
      crit_size = criteria.last.size
      if crit_size == 1
        rescore_criterion(criteria, criteria.size - 1)
        @score = -1 if @matches.last.score == 0
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
    # Pre: @score != -1
    # Params:
    # +criteria+:: Array of strings to apply as criteria.
    def decrease_score! criteria
      if @matches.size > criteria.size
        # lost criterion from the end
        @score -= @matches.pop.score
      else
        # final criterion was modified so recalculate it
        rescore_criterion(criteria, criteria.size - 1)
      end
    end

    # Recalculate @score from criteria.
    # Params:
    # +criteria+:: Array of strings to apply as criteria.
    def calculate_score! criteria
      @score = 0
      @matches = []
      failure = (0 ... criteria.length).detect do |idx|
        rescore_criterion criteria, idx
        @matches[idx].score == 0
      end
      @score = -1 unless failure.nil?
    end

    # reverse order as higher score should be ranked first
    def <=> rhs
      ret = rhs.score <=> @score
      ret == 0 ? (@filename <=> rhs.filename) : ret
    end

    def matching?
      @score >= 0
    end

    private
    # Rescore an existing criteria's match (or score it if it is a new match).
    def rescore_criterion criteria, crit_idx
      criterion = criteria[crit_idx]
      match = @matches[crit_idx]
      if match.nil?
        match = @matches[crit_idx] = CriterionMatch.new 0, []
      else
        match.indexes = []
        @score -= match.score unless match.score == -1
        match.score = 0
      end

      # by searching for the criterion again
      idx = crit_idx > 0 ? @matches[crit_idx - 1].indexes.first.index + 1 : -1
      while true
        idx = @matchname.index criterion, idx + 1
        break if idx.nil?
        multiplier = calculate_multiplier idx
        match.indexes << CriterionIndex.new(idx, multiplier)
        match.score += multiplier * criterion.size
      end
      @score += match.score
    end

    def is_lower? chr
      @@lower_test ||= /[[:lower:]]/
      chr.match @@lower_test
    end

    def is_upper? chr
      @@upper_test ||= /[[:upper:]]/
      chr.match @@upper_test
    end
  end
end
