local Errors = {}

local function ErrorTypeGenerator(Name) 
	local build = {}
	
	function build.new(description, ln, col)
		local self = {}
		
		self.name = Name or "Error"
		self.description = description
		self.ln = ln
		self.col = col
		
		return setmetatable(self, {
			__tostring = function(t)
				return (
"%s: %s at Item:%s:%s"):format(t.name, t.description, tostring(t.ln), tostring(t.col))
			end
		})
	end
	
	return build
end

Errors.IncorrectCharacterError = ErrorTypeGenerator("IncorrectCharacterError")
Errors.ParserError = ErrorTypeGenerator("ParserError")
Errors.RuntimeError = ErrorTypeGenerator("RuntimeError")
Errors.RuntimeError = ErrorTypeGenerator("RuntimeError")

return Errors