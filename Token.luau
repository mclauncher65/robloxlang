local Token = {}

function Token.new(line, col, TokenType, value, literal) 
	local self = {}
	self.line = line
	self.col = col
	self.TokenType = TokenType
	self.value = value
	self.literal = literal
	
	self = setmetatable(self, {
		__tostring = function(tab) 
			return `Type {self.TokenType} with value {self.value} at {self.line}:{self.col}`
		end
	})
	
	return self
end

return Token