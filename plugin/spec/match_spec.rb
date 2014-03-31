require_relative '../match'

module Oniwabandana
  describe 'match' do
    it 'can match and update single criterion' do
      m = Match.new "the file"
      m.calculate_score! ['f'], false
      expect(m.score).to eq(10)
      m.calculate_score! ['fi'], false
      expect(m.score).to eq(20)
    end

    it 'can fail single criterion' do
      m = Match.new "the file"
      m.calculate_score! ['o'], false
      expect(m.score).to eq(-1)
    end
  end
end
