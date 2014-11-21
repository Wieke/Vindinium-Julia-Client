module RandomBot
	using Vindinium

	function step(session :: Vindinium.Data)
		r = rand(1:5)
		if r == 1
			return North()
		elseif r == 2
			return South()
		elseif r == 3
			return East()
		elseif r == 4
			return West()
		else
			return Stay()
		end			
	end
end