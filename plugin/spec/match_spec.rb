require_relative '../match'

module Oniwabandana
  describe 'match' do
    it 'can match and update single criterion at beginning' do
      m = Match.new 'the file'
      m.increase_score! ['t']
      expect(m.score).to eq(10)
      m.increase_score! ['th']
      expect(m.score).to eq(20)
    end

    it 'can match and update single criterion in middle' do
      m = Match.new 'the file'
      m.increase_score! ['f']
      expect(m.score).to eq(10)
      m.increase_score! ['fi']
      expect(m.score).to eq(20)
    end

    it 'can fail single criterion' do
      m = Match.new 'the file'
      m.increase_score! ['o']
      expect(m.score).to eq(-1)
    end
  end
end
