--!nocheck
local Types = require(game.ReplicatedStorage.lang.Types)

local Statement = {}

local function build(name: string, Properties: {string}, accept: <R>(self: any, visitor: Types.StatementVisitor<R>) -> R ) 

	local state = {}


	function state.new(...: any)
		local self = {}
		self.__name = name
		self.accept = function<R>(visitor: Types.StatementVisitor<R>): R
			return accept(self, visitor)
		end

		local packed = table.pack(...)
		packed["n"] = nil
		
		assert(#packed == #Properties)
		for i, PropertyName in pairs(Properties) do 
			assert(packed[i] ~= nil)
			self[PropertyName] = packed[i]
		end

		return self
	end


	return state

end

Statement.Block = build("Block", {"statements"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitBlockStmt(self)
end)

Statement.Expression = build("Expression", {"expression"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitExpressionStmt(self)
end)

Statement.Var = build("Var", {"name", "initializer"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitVarStmt(self)
end)

Statement.If = build("If", {"condition", "thenBranch", "elifBranch", "elseBranch"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitIfStmt(self)
end)

Statement.While = build("While", {"condition", "body"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitWhileStmt(self)
end)

Statement.Function = build("Function", {"name", "params", "body"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitFuncStmt(self)
end)

Statement.Return = build("Return", {"keyword", "value"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitReturnStmt(self)
end)

Statement.Item = build("Item", {"body"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitItemStmt(self)
end)

Statement.ConstVar = build("ConstVar", {"name", "initializer"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitConstStmt(self)
end)

Statement.Switch = build("Switch", {"suspect", "cases"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitSwitchStmt(self)
end)
Statement.Pairs = build("Pairs", {"keyword", "applier", "block"}, function<R>(self, visitor: Types.StatementVisitor<R>): R
	return visitor.visitPairsStmt(self)
end)


return Statement