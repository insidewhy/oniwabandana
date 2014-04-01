require_relative '../match'

module Oniwabandana
  describe 'Match' do
    before :each do
      @opts = double('Opts', :case_sensitive => false)
    end

    it 'with update to single criterion in middle' do
      m = Match.new 'thefile', @opts
      m.increase_score! ['f']
      expect(m.score).to eq(2)
      m.increase_score! ['fi']
      expect(m.score).to eq(4)
    end

    it 'fails single criterion' do
      m = Match.new 'the file', @opts
      m.increase_score! ['o']
      expect(m.score).to eq(-1)
    end

    it 'and update single criterion at beginning with multiplier' do
      m = Match.new 'thefile', @opts
      m.increase_score! ['t']
      expect(m.score).to eq(4)
      m.increase_score! ['th']
      expect(m.score).to eq(8)
    end

    it 'after undescore in middle with multiplier' do
      m = Match.new 'the_file', @opts
      m.increase_score! ['f']
      expect(m.score).to eq(4)
      m.increase_score! ['fi']
      expect(m.score).to eq(8)
    end

    it 'failing second criterion' do
      m = Match.new 'thefile', @opts
      m.increase_score! ['t']
      m.increase_score! ['th']
      expect(m.score).to eq(8)
      m.increase_score! ['th', 'b']
      expect(m.score).to eq(-1)
    end

    it 'weighted criterion followed by unweighted criterion' do
      m = Match.new 'thefile', @opts
      m.increase_score! ['t']
      expect(m.score).to eq(4)
      m.increase_score! ['th']
      expect(m.score).to eq(8)
      m.increase_score! ['th', 'f']
      expect(m.score).to eq(10)
      m.increase_score! ['th', 'fi']
      expect(m.score).to eq(12)
      m.increase_score! ['th', 'fio']
      expect(m.score).to eq(-1)
    end

    it 'with lower multiplier against directory' do
      m = Match.new 'dir/file', @opts
      m.increase_score! ['d']
      expect(m.score).to eq(2)
      m.increase_score! ['di']
      expect(m.score).to eq(4)
      m.increase_score! ['di', 'f']
      expect(m.score).to eq(8)
      m.increase_score! ['di', 'fi']
      expect(m.score).to eq(12)
    end

    it 'ensures second criterion must be after first' do
      m = Match.new 'abc_def_ghi', @opts
      m.increase_score! ['d']
      m.increase_score! ['de']
      expect(m.score).to eq(8)
      m.increase_score! ['de', 'a']
      expect(m.score).to eq(-1)
    end

    it 'when second criterion is subset of firsta match must be after the first criterion match' do
      m = Match.new 'den_bon', @opts
      m.increase_score! ['d']
      m.increase_score! ['de']
      expect(m.score).to eq(8)
      m.increase_score! ['de', 'd']
      expect(m.score).to eq(-1)
    end

    it 'a single criterion multiple times' do
      m = Match.new 'ban ban', @opts
      m.increase_score! ['b']
      expect(m.score).to eq(8) # 4 from each match
    end

    it 'a single criterion multiple times with an update' do
      m = Match.new 'ban ban', @opts
      m.increase_score! ['b'] # score == 8
      m.increase_score! ['ba']
      expect(m.score).to eq(16) # 8 from each match
    end

    it 'matches a criterion multiple times with updates' do
      m = Match.new 'ban don sban sdon', @opts
      m.increase_score! ['b']
      expect(m.score).to eq(6) # 4 + 2
    end

    it 'removes the score of a criterion that matches twice then once' do
      m = Match.new 'baan0baon', @opts
      m.increase_score! ['b'] # 4 + 2
      m.increase_score! ['ba'] # (4 * 2) + (2 * 2)
      expect(m.score).to eq(12)
      m.increase_score! ['baa'] # (4 * 3)
      expect(m.score).to eq(12)
    end

    it 'reduces a score by removing character from criterion' do
      m = Match.new 'koreless', @opts
      m.increase_score! ['k']
      m.increase_score! ['ko']
      expect(m.score).to eq(8)
      m.decrease_score! ['k']
      expect(m.score).to eq(4)
      m.increase_score! ['ko']
      expect(m.score).to eq(8)
    end

    it 'reduces a score by removing two characters from a criterion followed by an increase' do
      m = Match.new 'tomoda', @opts
      m.increase_score! ['t']
      m.increase_score! ['to']
      m.increase_score! ['tom']
      expect(m.score).to eq(12)
      m.decrease_score! ['to']
      expect(m.score).to eq(8)
      m.decrease_score! ['t']
      expect(m.score).to eq(4)
      m.increase_score! ['to']
      expect(m.score).to eq(8)
    end

    it 'reduces a score by removing a criterion then increases the score again' do
      m = Match.new 'kodama', @opts
      m.increase_score! ['o']
      m.increase_score! ['od']
      expect(m.score).to eq(4)
      m.increase_score! ['od', 'm']
      expect(m.score).to eq(6)
      m.decrease_score! ['od']
      expect(m.score).to eq(4)
      m.decrease_score! ['o']
      expect(m.score).to eq(2)
      m.increase_score! ['od']
      expect(m.score).to eq(4)
    end

    it 'reduces a score of a subsequent criterion ignoring earlier match prior to first criterion' do
      m = Match.new 'abc def abc', @opts
      m.increase_score! ['d']
      m.increase_score! ['de']
      expect(m.score).to eq(8)
      m.increase_score! ['de', 'a']
      m.increase_score! ['de', 'ab']
      expect(m.score).to eq(16) # previous two only matched at end
      m.decrease_score! ['de', 'a']
      expect(m.score).to eq(12)
      m.decrease_score! ['de']
      expect(m.score).to eq(8)
      m.increase_score! ['def']
      expect(m.score).to eq(12)
    end

    it 'passes a real-world example' do
      m = Match.new 'app/controller/application_controller.rb', @opts
      m.increase_score! ['a'] # 2 + 4 + 2
      expect(m.score).to eq(8)
      m.increase_score! ['ap'] # (2 * 2)  + (2 * 4)
      expect(m.score).to eq(12)
      m.increase_score! ['app'] # (3 * 2)  + (3 * 4)
      expect(m.score).to eq(18)
      m.increase_score! ['app', 'c'] # 18 + 2 + 2 + 4
      expect(m.score).to eq(26)
      m.increase_score! ['app', 'co'] # 18 + (2 * 2) + (2 * 4)
      expect(m.score).to eq(30)
      m.increase_score! ['app', 'con'] # 18 + (3 * 2) + (3 * 4)
      expect(m.score).to eq(36)
    end
  end
end
