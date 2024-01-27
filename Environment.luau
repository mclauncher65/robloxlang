local Environment = {}
local Errors = require(game.ReplicatedStorage.lang.Errors)

function Environment.new(enclosing: any?)
	local self = {}
	
	if (enclosing ~= nil) then
		self.enclosing = enclosing
	end
	
	self.values = {}
	
	function self.define(name, value, protected: boolean?)
		protected = protected or false
		self.values[name] = {value = value, protected = protected}
	end
	
	function self.get(name)
		if self.values[name.value] ~= nil then
			return self.values[name.value]["value"], true
		end
		
		if (self.enclosing ~= nil) then return enclosing.get(name) end
		
		return Errors.RuntimeError.new(`Undefined variable {name.value}`, name.line, name.col), false
	end
	
	function self.assign(name, value)
		if (self.values[name.value] ~= nil and not self.values[name.value]["protected"]) then
			self.values[name.value]["value"] = value
			return nil, true
		elseif (self.values[name.value] ~= nil and self.values[name.value]["protected"]) then
			return Errors.RuntimeError.new("Attempt to change protected variable", name.line, name.col)
		end
		
		if (enclosing ~= nil) then
			enclosing.assign(name, value)
			return nil, true
		end
		
		return Errors.RuntimeError.new(`Undefined variable {name.value}`), false
	end
	
	return self
end

return Environment