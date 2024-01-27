--!strict
local Types = require(game.ReplicatedStorage.lang.Types)

local Expr = {}

local function build(name: string, Properties: {string}, accept: <R>(self: any, visitor: Types.Visitor<R>) -> R ) 
	
	local state = {}
	
	
	function state.new(...: any)
		local self = {}
		self.__name = name
		self.accept = function<R>(visitor: Types.Visitor<R>)
			return accept(self, visitor)
		end
		
		local packed = table.pack(...)
		packed["n"] = nil

		assert(#Properties == #packed)
		for i, PropertyName in pairs(Properties) do 
			assert(packed[i] ~= nil)
			self[PropertyName] = packed[i]
		end
			
		return self
	end
	
	
	return state
	
end

Expr.Assign = build("Assign", {"name", "value"}, function<R>(self, visitor: Types.Visitor<R>): R
	return visitor.visitAssignExpr(self)
end)

Expr.Logical = build("Logical", {"left", "operator", "right"}, function<R>(self, visitor: Types.Visitor<R>): R
	return visitor.visitLogicalExpr(self)
end)

Expr.Binary = build("Binary", {"left", "operator", "right"}, function<R>(self, visitor: Types.Visitor<R>): R
	return visitor.visitBinaryExpr(self)
end)

Expr.Grouping = build("Grouping", {"expression"}, function<R>(self, visitor: Types.Visitor<R>): R
	return visitor.visitGroupingExpr(self)
end)

Expr.Literal = build("Literal", {"value"}, function<R>(self, visitor: Types.Visitor<R>): R  
	return visitor.visitLiteralExpr(self)
end)

Expr.Unary = build("Unary", {"operator", "right"}, function<R>(self, visitor: Types.Visitor<R>): R
	return visitor.visitUnaryExpr(self)
end)

Expr.Variable = build("Variable", {"name"}, function<R>(self, visitor: Types.Visitor<R>): R  
	return visitor.visitVariableExpr(self)
end)

Expr.Call = build("Call", {"callee", "paren", "arguments"}, function<R>(self, visitor: Types.Visitor<R>): R  
	return visitor.visitCallExpr(self)
end)

Expr.Set = build("Set", {"data"}, function<R>(self, visitor: Types.Visitor<R>): R  
	return visitor.visitSetExpr(self)
end)

Expr.SetCall = build("SetCall", {"callee", "paren", "index"}, function<R>(self, visitor: Types.Visitor<R>): R  
	return visitor.visitSetCallExpr(self)
end)

Expr.Lambda = build("Lambda", {"params", "body"}, function<R>(self, visitor: Types.Visitor<R>): R  
	return visitor.visitLambdaExpr(self)
end)

Expr.Switch = build("Switch", {"suspect", "cases"}, function<R>(self, visitor: Types.Visitor<R>): R 
	return visitor.visitSwitchExpr(self)
end)


return Expr