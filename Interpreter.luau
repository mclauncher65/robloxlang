--!nocheck

local Types = require(game.ReplicatedStorage.lang.Types)
local TokenType = require(game.ReplicatedStorage.lang.TokenType)
local Utilities = require(game.ReplicatedStorage.lang.Util)
local NIL = require(game.ReplicatedStorage.lang.NIL)
local Errors = require(game.ReplicatedStorage.lang.Errors)
local Statements = require(game.ReplicatedStorage.lang.Statement)
local Environment = require(game.ReplicatedStorage.lang.Environment)

local Interpreter: Types.Visitor<any>&Types.StatementVisitor<never>
local args = nil

local errors = {}
local hadError = false
local OnRun
local funReturn = nil

local function newError(token, message)
	hadError = true
	table.insert(errors, Errors.RuntimeError.new(message, token.line, token.col))
	error()
end

function errorFromError(err)
	hadError = true
	table.insert(errors, err)
	error()
end


stringify = function(object)
	if (object == nil or object == NIL) then return "nil" end
	local s = tostring(object)

	if ((s:split("")[1] == '"' or s:split("")[1] == '\'') and (s:split("")[s:len()] == '"' or s:split("")[s:len()] == '\'')) then
		return s:sub(2, s:len() - 1)
	else
		return s
	end
end;

function GetErrors() 
	return errors
end

function new_globals()
	local globals = Environment.new();
	globals.define("print", setmetatable({
		__name = "Callable";
		
		arity = function() return 1 end;

		call = function(interpreter, args)
			OnRun(stringify(args[1]))
		end;
	}, {
		__tostring = function(t)
			return "Prints out text to the standard output."
		end,
	}), true)

	globals.define("str", setmetatable({
		__name = "Callable";

		arity = function() return 1 end;

		call = function(interpreter, args)
			return `"{tostring(args[1])}"`
		end;
	}, {
		__tostring = function(t)
			return "Returns value -> string"
		end,
	}), true)
	
	globals.define("random", setmetatable({
		__name = "Callable";

		arity = function() return 2 end;

		call = function(interpreter, args)
			return math.random(args[1], args[2])
		end;
	}, {
		__tostring = function(t)
			return "Returns a random number from the first param to the last param"
		end,
	}), true)
	
	globals.define("wait", setmetatable({
		__name = "Callable";

		arity = function() return 1 end;

		call = function(interpreter, args)
			wait(args[1])
		end;
	}, {
		__tostring = function(t)
			return "Waits for x amount of seconds"
		end,
	}), true)

	return globals
end

local Interpreter 

Interpreter = {
	
	interpret = function(statements: {any}, funs, globals, onOut)
		local result
		hadError = false
		funReturn = {}
		errors = {}
		OnRun = onOut
		Interpreter.globals = new_globals();
		if globals then
			for _, global in globals do
				Interpreter.globals.define(global["name"], global["value"], true)
			end
		end
		Interpreter.environment = Interpreter.globals;
		Interpreter.funs = funs
		
		for _, statement in statements do
			local success, r = pcall(function()
				result = Interpreter.execute(statement)
			end)
			
			if not success then
				return errors, false, nil
			end
		end
		
		return nil, true, funReturn
	end;
	
	execute = function(stmt: Types.Statement)
		stmt.accept(Interpreter)
	end;
	
	stringify = function(object)
		if (object == nil or object == NIL) then return "nil" end
		local s = tostring(object)
		
		if ((s:split("")[1] == '"' or s:split("")[1] == '\'') and (s:split("")[s:len()] == '"' or s:split("")[s:len()] == '\'')) then
			return s:sub(2, s:len() - 1)
		else
			return s
		end
	end;
	
	visitItemStmt = function(stmt: Types.ItemReturnType)
		Interpreter.evaluate(stmt.body)
	end;
	
	visitBlockStmt = function(stmt: Types.BlockReturnType)
		Interpreter.executeBlock(stmt.statements, Environment.new(Interpreter.environment))
	end;
	
	visitFuncStmt = function(stmt: Types.Func) 
		local func = Types.newFunc(stmt, Interpreter.environment)
		if Interpreter.funs[stmt.name.value] then
			if func.arity() == Interpreter.funs[stmt.name.value] then
				funReturn[stmt.name.value] = func.call
			else
				newError(stmt.name, "Unexpected number of params, wanted "..Interpreter.funs[stmt.name.value]..", got "..func.arity().." arguments...")
			end
		end
		Interpreter.environment.define(stmt.name.value, func)
		return nil
	end;
	
	visitReturnStmt = function(stmt: Types.ReturnReturnType)
		local value = NIL
		if (stmt.value ~= nil and stmt.value ~= NIL) then value = Interpreter.evaluate(stmt.value) end
		
		if (Interpreter["returnHandler"] ~= nil) then
			Interpreter["returnHandler"](value)
		end
		
	end;
	
	visitSetExpr = function(expr: Types.SetReturnType)
		local index = expr.data["i"]
		local value = expr.data["v"]
		
		local final = {}
		
		for i,v in pairs(index) do
			final[Interpreter.stringify(Interpreter.evaluate(v))] = Interpreter.evaluate(value[i])
		end
		
		return setmetatable({data = final, __name = "Set"}, {
			__tostring = function(t)
				return "<set>"
			end,
		})
	end;
	
	visitPairsStmt = function(stmt: Types.PairsReturnType)
		local set = Interpreter.evaluate(stmt.applier)
		
		if (set.__name ~= "Set") then
			newError(stmt.keyword, "Expected a set, didn't get one.")
		end
		
		local statements = stmt.block.statements
		
		for i,v in pairs(set.data) do
			local env = Environment.new(Interpreter.environment)
			env.define("i", i, false)
			env.define("v", v, false)
			Interpreter.executeBlock(statements, env)
		end
	end;
	
	visitSetCallExpr = function(expr: Types.SetCallReturnType)
		local callee = Interpreter.evaluate(expr.callee)
		
		if callee.__name ~= "Set" then
			newError(expr.paren, "This aint a set bro...")
		end
		
		return callee["data"][Interpreter.stringify(Interpreter.evaluate(expr.index))] or NIL
	end;
	
	visitIfStmt = function(stmt: Types.IfReturnType)
		if (Interpreter.isTruthy(Interpreter.evaluate(stmt.condition))) then
			Interpreter.execute(stmt.thenBranch)
		else
			local foundElseIf = false
			for _, elseIfBranch in pairs(stmt.elifBranch) do 
				if (Interpreter.isTruthy(Interpreter.evaluate(elseIfBranch.condition))) then
					Interpreter.execute(elseIfBranch.thenBranch)
					foundElseIf = true
					break
				end
			end
			
			if (not foundElseIf and stmt.elseBranch ~= NIL) then
				Interpreter.execute(stmt.elseBranch)
			end
			
		end
		return
	end;
	
	visitLambdaExpr = function(expr: Types.LambdaReturnType)
		local func = Types.newFunc(expr, Interpreter.environment)
		return func
	end;
	
	visitLogicalExpr = function(expr: Types.LogicalReturnType)
		local left = Interpreter.evaluate(expr.left)
		
		if (expr.operator.TokenType == TokenType.Type.OR) then
			if (Interpreter.isTruthy(left)) then return left end
		else
			if (not(Interpreter.isTruthy(left))) then return left end
		end
		
		return Interpreter.evaluate(expr.right)
	end;
	
	visitWhileStmt = function(stmt: Types.WhileReturnType)
		while (Interpreter.isTruthy(Interpreter.evaluate(stmt.condition))) do
			Interpreter.execute(stmt.body)
			wait(0.01)
		end
		return nil
	end;
	
	visitConstStmt = function(stmt: Types.ConstVarReturnType)
		local value = nil
		if (stmt.initializer ~= nil) then
			value = Interpreter.evaluate(stmt.initializer)
		end

		Interpreter.environment.define(stmt.name.value, value, true)
		return nil
	end;
	
	visitSwitchStmt = function(stmt: Types.SwitchReturnType)
		local suspect = Interpreter.evaluate(stmt.suspect)
		local foundMark = false
		
		for i,v in pairs(stmt.cases.case) do
			local witness = Interpreter.evaluate(v.witness)
			if (witness == suspect) then
				foundMark = true
				Interpreter.execute(v.ifTrue)
			end
		end
		
		if not foundMark and stmt.cases["default"] ~= nil then
			Interpreter.execute(stmt.cases["default"].ifTrue)
		end
	end;
	
	visitSwitchExpr = function(expr: Types.SwitchReturnType)
		local suspect = Interpreter.evaluate(expr.suspect)
		local foundMark = false

		for i,v in pairs(expr.cases.case) do
			local witness = Interpreter.evaluate(v.witness)
			if (witness == suspect) then
				foundMark = true
				return Interpreter.evaluate(v.ifTrue)
			end
		end

		if not foundMark and expr.cases["default"] ~= nil then
			return Interpreter.evaluate(expr.cases["default"].ifTrue)
		end
	end;
	
	executeBlock = function(statements, env)
		local previous = Interpreter.environment
		

		Interpreter.environment = env
			
		for _, statement in statements do
			Interpreter.execute(statement)
		end
		
		Interpreter.environment = previous
		
	end;
	
	visitExpressionStmt = function(stmt: Types.ExpressionReturnType): never
		Interpreter.evaluate(stmt.expression)
	end;
	
	visitAssignExpr = function(expr: Types.AssignReturnType)
		local value = Interpreter.evaluate(expr.value)
		local result, success = Interpreter.environment.assign(expr.name, value)
		if not success then
			errorFromError(result)
			return
		end
		return value
	end;
	
	visitVarStmt = function(stmt: Types.VarReturnType)
		local value = nil
		if (stmt.initializer ~= NIL) then
			value = Interpreter.evaluate(stmt.initializer)
		end
		
		Interpreter.environment.define(stmt.name.value, value)
		return nil
	end;
	
	visitVariableExpr = function(expr: Types.VariableReturnType)
		local result, success = Interpreter.environment.get(expr.name)
		if not success then
			errorFromError(result)
			return
		end
		return result
	end;
	
	visitBinaryExpr = function(expr: Types.BinaryReturnType): any
		local ltype = expr.left.__name
		
		local left = Interpreter.evaluate(expr.left)
		local right = Interpreter.evaluate(expr.right)
		
		local result
		
		Utilities.switch(expr.operator.TokenType, {
			[TokenType.Type.PLEQ] = function(c)
				if (ltype == "Variable" and tonumber(left) ~= nil and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.left.name, left + right)
				elseif (ltype == "Variable" and typeof(right) == "string") then
					Interpreter.environment.assign(expr.left.name, Interpreter.stringify(left) .. Interpreter.stringify(right))
				else
					result = -1
					newError(expr.operator, "Expected <var> <operator> <number> or <var> <operator> <string>")
				end
			end;
			[TokenType.Type.MINEQ] = function(c)
				if (ltype == "Variable" and tonumber(left) ~= nil and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.left.name, left - right)
				else
					result = -1
					newError(expr.operator, "Expected <var> <operator> <number>")
				end
			end;
			[TokenType.Type.FLOEQ] = function(c)
				if (ltype == "Variable" and tonumber(left) ~= nil and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.left.name, left // right)
				else
					result = -1
					newError(expr.operator, "Expected <var> <operator> <number>")
				end
			end;
			[TokenType.Type.DIVIEQ] = function(c)
				if (ltype == "Variable" and tonumber(left) ~= nil and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.left.name, left / right)
				else
					result = -1
					newError(expr.operator, "Expected <var> <operator> <number>")
				end
			end;
			[TokenType.Type.MULTIPEQ] = function(c)
				if (ltype == "Variable" and tonumber(left) ~= nil and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.left.name, left * right)
				else
					result = -1
					newError(expr.operator, "Expected <var> <operator> <number>")
				end
			end;
			[TokenType.Type.MINUS] = function(c)
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result = -1
				end
				result =  tonumber(left) - tonumber(right)
			end;
			[TokenType.Type.DIVIDE] = function(c)
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result =  -1
				end
				if tonumber(left) == 0 and tonumber(right) == 0 then
					result = "\"NaN\""
				else
					result =  tonumber(left) / tonumber(right)
				end
			end;
			[TokenType.Type.POWEQ] = function(c)
				if (ltype == "Variable" and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.left.name, left ^ right)
				else
					result = -1
					newError(expr.operator, "Expected <var> <operator> <number>")
				end
			end;
			[TokenType.Type.REMAINDEQ] = function(c)
				if (ltype == "Variable" and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.left.name, left % right)
				else
					result = -1
					newError(expr.operator, "Expected <var> <operator> <number>")
				end
			end;
			[TokenType.Type.MULTIPLY] = function(c)
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result =  -1
				end
				result =  tonumber(left) * tonumber(right)
			end;
			[TokenType.Type.FLOOR] = function(c) 
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result =  -1
				end
				result =  tonumber(left) // tonumber(right)
			end;
			[TokenType.Type.PLUS] = function(c) 
				if (tonumber(left) ~= nil and tonumber(right) ~= nil) then
					result =  tonumber(left) + tonumber(right)
					return
				end
				
				if (typeof(left) == "string" and typeof(right) == "string") then
					result =  (Interpreter.stringify(left) .. Interpreter.stringify(right))
					return
				end
				
				newError(expr.operator, "Operator requirers <number> <operator> <number> or <string> <operator> <string> to run properly. Thanks! :D")
				result =  -1
			end;
			[TokenType.Type.GREATERTHAN] = function(c) 
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result =  false
				end
				result =  tonumber(left) > tonumber(right)
			end;
			[TokenType.Type.GREATERTHANOREQUALTO] = function(c) 
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result =  false
				end
				result =  tonumber(left) >= tonumber(right)
			end;
			[TokenType.Type.LESSTHAN] = function(c) 
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result =  false
				end
				result =  tonumber(left) < tonumber(right)
			end;
			[TokenType.Type.LESSTHANOREQUALTO] = function(c) 
				local res = Interpreter.checkNumberOperands(expr.operator, left, right)
				if (res == -1) then 
					result =  false
				end
				result =  tonumber(left) <= tonumber(right)
			end;
			[TokenType.Type.NOTEQ] = function(c) 
				result =  not Interpreter.isEqual(left, right)
			end;
			[TokenType.Type.DOUBLEQUAL] = function(c) 
				result =  Interpreter.isEqual(left, right)
			end;
		})
		
		return result
	end;




	visitGroupingExpr = function(expr: Types.GroupingReturnType): any 
		return Interpreter.evaluate(expr.expression)
	end;




	visitLiteralExpr = function(expr: Types.LiteralReturnType): any
		return expr.value
	end;
	
	visitCallExpr = function(expr: Types.CallReturnType)
		local callee = Interpreter.evaluate(expr.callee)
		local arguments = {}
		for i,v in pairs(expr.arguments) do
			table.insert(arguments, Interpreter.evaluate(v))
		end
		
		if (not(callee["__name"] == "Callable")) then
			newError(expr.paren, "Only call a function, you goofball.")
		end
		
		local fun: Types.Callable = callee :: Types.Callable
		
		if (#arguments ~= fun.arity()) then
			newError(expr.paren, `Expected {fun.arity()} arguments, got {#arguments} arguments, you for sure forgot something here....`)
		end
		
		return fun.call(Interpreter, arguments)
	end;



	visitUnaryExpr = function(expr: Types.UnaryReturnType): any
		local rtype = expr.right.__name
		local right = Interpreter.evaluate(expr.right)
		
		local result
		
		Utilities.switch(expr.operator.TokenType, {
			[TokenType.Type.TAG] = function(c) 
				if (typeof(right) == "table" and right["__name"] == "Set") then
					result = right["data"]
					local len = 0
					for i, v in pairs(result) do
						len += 1
					end
					result = len
				else
					result = -1
					newError(expr.operator, "Expected <tag> <set>")
				end
			end;
			[TokenType.Type.PLPL] = function(c)
				if (rtype == "Variable" and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.right.name, right + 1)
					result = right
				else
					result = -1
					newError(expr.operator, "Expected <operator> <var>")
				end
			end;
			[TokenType.Type.MINMN] = function(c)
				if (rtype == "Variable" and tonumber(right) ~= nil) then
					Interpreter.environment.assign(expr.right.name, right - 1)
					result = right
				else
					result = -1
					newError(expr.operator, "Expected <operator> <var>")
				end
			end;
			[TokenType.Type.NOT] = function(c) 
				result = not Interpreter.isTruthy(right)
			end;
			[TokenType.Type.MINUS] = function(c)
				local res = Interpreter.checkNumberOperand(expr.operator, right)
				if (res == -1) then 
					result = -1
				end
				result = -(tonumber(right))
			end;
		})
		
		return result
	end;
	
	isTruthy = function(object)
		if (object == NIL) then return false end	
		if (typeof(object) == "boolean") then
			return object :: boolean
		end
		return true
	end;
	
	evaluate = function(expr: Types.Expression)
		local a = expr.accept(Interpreter)
		return a
	end;
	
	isEqual = function(a, b) 
		if a == NIL and b == NIL then return true end
		if a == NIL then return false end
		
		return tostring(a) == tostring(b)
	end;
	
	checkNumberOperand = function(operator, operand) 
		if (typeof(operand) == "number") then return true end
		newError(operator, "Operator requirers <number> to run properly. Thanks! :D")
		return -1
	end;
	
	checkNumberOperands = function(operator, left, right) 
		if (tonumber(left) ~= nil and tonumber(right) ~= nil) then return true end
		newError(operator, "Operator requirers <number> <operator> <number> to run properly. Thanks! :D")
		return -1
	end
}

return {Interpreter, GetErrors}