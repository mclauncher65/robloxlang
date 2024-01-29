--!nocheck
local Environment = require(game.ReplicatedStorage.lang.Environment)
local NIL = require(game.ReplicatedStorage.lang.NIL)

export type Expression = { accept: <R>(Visitor) -> R, new: (...any) -> {}, __name: string  }
export type Statement = { accept: <R>(StatementVisitor) -> R, new: (...any) -> {}, __name: string  }

export type BinaryReturnType = Expression&{ left: any, operator: any, right: any }
export type GroupingReturnType = Expression&{expression: any}
export type LiteralReturnType = Expression&{value: any}
export type UnaryReturnType = Expression&{operator: any, right: any}
export type ExpressionReturnType = Expression&{expression: Expression}
export type VarReturnType = Statement&{name: any, initializer: any}
export type ConstVarReturnType = VarReturnType
export type VariableReturnType = Expression&{name: any}
export type CallReturnType = Expression&{callee: any, paren: any, arguments: any}
export type WhileReturnType = Statement&{condition: any, body: any}
export type AssignReturnType = Expression&{name: any, value: any}
export type BlockReturnType = Statement&{statements: {any}}
export type FunctionReturnType = Statement&{name: any, params: any, body: any}
export type Callable = {__name: string, call: (interpreter: any, arguments: {any}) -> any, arity: () -> number}
export type LogicalReturnType = Expression&{left: any, operator: any, right: any}
export type IfReturnType = Statement&{condition: any, thenBranch: any, elifBranch: any, elseBranch: any}
export type ReturnReturnType = Expression&{keyword: any, value: any}
export type Func = Callable&{declaration: any}
export type SetReturnType = Expression&{data: {any}}
export type SetCallReturnType = Expression&{callee: any, paren: any, index: any}
export type ItemReturnType = Statement&{body: any}
export type LambdaReturnType = Expression&{params: any, body: any}
export type SwitchReturnType = Statement&{suspect: any, cases: any}
export type PairsReturnType = Statement&{keyword: any, applier: any, block : any}

export type Visitor<R> = {
	visitAssignExpr: (AssignReturnType) -> R;
	visitBinaryExpr: (BinaryReturnType) -> R;
	visitGroupingExpr: (GroupingReturnType) -> R;
	visitLiteralExpr: (LiteralReturnType) -> R;
	visitUnaryExpr: (UnaryReturnType) -> R;
	visitVariableExpr: (VariableReturnType) -> R;
	visitLogicalExpr: (LogicalReturnType) -> R;
	visitCallExpr: (CallReturnType) -> R;
	visitSetExpr: (SetReturnType) -> R;
	visitSetCallExpr: (SetCallReturnType) -> R;
	visitLambdaExpr: (LambdaReturnType) -> R;
	visitSwitchExpr: (SwitchReturnType) -> R;
}

export type StatementVisitor<R> = {
	visitBlockStmt: (BlockReturnType) -> R;
	visitExpressionStmt: (ExpressionReturnType) -> R;
	visitVarStmt: (VarReturnType) -> R;
	visitIfStmt: (IfReturnType) -> R;
	visitWhileStmt: (WhileReturnType) -> R;
	visitFuncStmt: (FunctionReturnType) -> R;
	visitReturnStmt: (ReturnReturnType) -> R;
	visitItemStmt: (ItemReturnType) -> R;
	visitConstStmt: (ConstVarReturnType) -> R;
	visitSwitchStmt: (SwitchReturnType) -> R;
	visitPairsStmt: (PairsReturnType) -> R;
	visitBreakStmt: (Statement) -> R;
}

return {
	
	
	newFunc = function(declaration, closure)
		local self: Func = {declaration = declaration, closure = closure, __name = "Callable"}
		self.call = function(interpreter, args) 
			local environment = Environment.new(closure)
			
			for i = 1, #declaration.params, 1 do
				environment.define(declaration.params[i].value, args[i])
			end
			
			local returning = NIL
			
			interpreter.returnHandler = function(returningValue)
				returning = returningValue
			end
			
			interpreter.executeBlock(declaration.body, environment)
			
			
			return returning
		end
		
		self.arity = function() 
			return #declaration.params
		end
		
		setmetatable(self, {
			__tostring = function (t) 
				return `\{ user defined function {declaration.name.value} }`
			end,
		})
		return self
	end
	
}
