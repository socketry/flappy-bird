class Highscore < ApplicationRecord
	def self.top10
		order(score: :desc).limit(10)
	end
end
