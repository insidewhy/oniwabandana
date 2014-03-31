require_relative '../match'

module Oniwabandana
  describe 'match' do
    it 'and update single criterion in middle' do
      m = Match.new 'thefile'
      m.increase_score! ['f']
      expect(m.score).to eq(10)
      m.increase_score! ['fi']
      expect(m.score).to eq(20)
    end

    it 'fails single criterion' do
      m = Match.new 'the file'
      m.increase_score! ['o']
      expect(m.score).to eq(-1)
    end

    it 'and update single criterion at beginning with multiplier' do
      m = Match.new 'thefile'
      m.increase_score! ['t']
      expect(m.score).to eq(20)
      m.increase_score! ['th']
      expect(m.score).to eq(40)
    end

    it 'after undescore in middle with multiplier' do
      m = Match.new 'the_file'
      m.increase_score! ['f']
      expect(m.score).to eq(20)
      m.increase_score! ['fi']
      expect(m.score).to eq(40)
    end
  end
end
