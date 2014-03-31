require_relative '../match'

module Oniwabandana
  describe 'match' do
    it 'with update to single criterion in middle' do
      m = Match.new 'thefile'
      m.increase_score! ['f']
      expect(m.score).to eq(20)
      m.increase_score! ['fi']
      expect(m.score).to eq(40)
    end

    it 'fails single criterion' do
      m = Match.new 'the file'
      m.increase_score! ['o']
      expect(m.score).to eq(-1)
    end

    it 'and update single criterion at beginning with multiplier' do
      m = Match.new 'thefile'
      m.increase_score! ['t']
      expect(m.score).to eq(40)
      m.increase_score! ['th']
      expect(m.score).to eq(80)
    end

    it 'after undescore in middle with multiplier' do
      m = Match.new 'the_file'
      m.increase_score! ['f']
      expect(m.score).to eq(40)
      m.increase_score! ['fi']
      expect(m.score).to eq(80)
    end

    it 'failing second criterion' do
      m = Match.new 'thefile'
      m.increase_score! ['t']
      m.increase_score! ['th']
      expect(m.score).to eq(80)
      m.increase_score! ['th', 'b']
      expect(m.score).to eq(-1)
    end

    it 'weighted criterion followed by unweighted criterion' do
      m = Match.new 'thefile'
      m.increase_score! ['t']
      expect(m.score).to eq(40)
      m.increase_score! ['th']
      expect(m.score).to eq(80)
      m.increase_score! ['th', 'f']
      expect(m.score).to eq(100)
      m.increase_score! ['th', 'fi']
      expect(m.score).to eq(120)
      m.increase_score! ['th', 'fio']
      expect(m.score).to eq(-1)
    end

    it 'with lower multiplier against directory' do
      m = Match.new 'dir/file'
      m.increase_score! ['d']
      expect(m.score).to eq(20)
      m.increase_score! ['di']
      expect(m.score).to eq(40)
      m.increase_score! ['di', 'f']
      expect(m.score).to eq(80)
      m.increase_score! ['di', 'fi']
      expect(m.score).to eq(120)
    end
  end
end
