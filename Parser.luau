local TokenType = require(game.ReplicatedStorage.lang.TokenType)
local Types = require(game.ReplicatedStorage.lang.Types)
local Expression = require(game.ReplicatedStorage.lang.Expression)
local NIL = require(game.ReplicatedStorage.lang.NIL)
local Errors = require(game.ReplicatedStorage.lang.Errors)
local Utilities = require(game.ReplicatedStorage.lang.Util)
local Statements = require(game.ReplicatedStorage.lang.Statement)
local Parser = {}

function Parser.new(tokens: {any}) 
	if tokens == nil then
		return nil, nil
	end
	
	local self = {}
	
	self.errors = {}
	self.hasError = false
	
	self.tokens = tokens
	self.current = 1
	
	function self.previous() 
		return self.tokens[self.current - 1]
	end
	
	function self.peek() 
		return self.tokens[self.current]
	end
	
	function self.isAtEnd()
		return self.peek().TokenType == TokenType.Type.EOF
	end
	
	function self.advance() 
		if (not(self.isAtEnd())) then self.current += 1 end
		return self.previous()
	end
	
	function self.check(TYPE) 
		if (self.isAtEnd()) then return false end
		return self.peek().TokenType == TYPE
	end
	
	function self.match(types: {number}) 
		for _, TYPE in types do 
			if (self.check(TYPE)) then 
				self.advance()
				return true
			end
		end
		
		return false
	end

	
	function self.synchronize() 
		self.advance()
		
		local done = false
		
		while (not(self.isAtEnd())) do 
			
			if (self.previous().TokenType == TokenType.Type.SEMICOLON) then return end
			
			Utilities.switch(self.peek().TokenType, {
				[TokenType.Type.FUNCTION] = function(c) 
					done = true
				end;
				[TokenType.Type.VAR] = function(c) 
					done = true
				end;
				[TokenType.Type.FOR] = function(c) 
					done = true
				end;
				[TokenType.Type.IF] = function(c) 
					done = true
				end;
				[TokenType.Type.WHILE] = function(c) 
					done = true
				end;
				[TokenType.Type.RETURN] = function(c) 
					done = true
				end;
			})
			
			if done then
				return
			end
			
			self.advance()
		end
	end
	
	function self.error(token, message)
		self.hasError = true
		local err = Errors.ParserError.new(message, token.line, token.col)
		table.insert(self.errors, err)
		return err
	end
	
	function self.consume(TYPE, message)
		if (self.check(TYPE)) then return self.advance(), true end
		
		return self.error(self.peek(), message), false
	end
	
	function self.consumeMatch(types: {number}, msg) 
		for _, TYPE in types do 
			if (self.check(TYPE)) then 
				self.advance()
				return true, true
			end
		end
		return self.error(self.peek(), msg), false
	end
	
	function self.primary()

		if (self.match({TokenType.Type.FALSE})) then return Expression.Literal.new(false) end
		if (self.match({TokenType.Type.TRUE})) then return Expression.Literal.new(true) end
		if (self.match({TokenType.Type.NIL})) then return Expression.Literal.new(NIL) end
		
		if (self.match({TokenType.Type.NUMBER, TokenType.Type.STRING})) then
			return Expression.Literal.new(self.previous().value)
		end
		
		if (self.match({TokenType.Type.IDENTIFIER})) then
			return Expression.Variable.new(self.previous())
		end
		
		if (self.match({TokenType.Type.LPAREN})) then
			local expr = self.expression()
			if not self.consume(TokenType.Type.RPAREN, "Expected ')' to end '('") then return Expression.Literal.new("-1") end
			return Expression.Grouping.new(expr)
		end
		
		if (self.match({TokenType.Type.LCURLY})) then
			return self.newSet()
		end
		
		if (self.match({TokenType.Type.LAMBDA})) then
			return self.lambda()
		end
		
		if (self.match({TokenType.Type.SWITCH})) then 
			return self.switch()
		end
		
		self.error(self.peek(), "Expected <expr>")
	end
	
	function self.finishCall(callee)
		local arguments = {}
		if (not(self.check(TokenType.Type.RPAREN))) then
			repeat
				table.insert(arguments, self.expression())
			until not (self.match({TokenType.Type.COMMA}))
		end
		
		local paren = self.consume(TokenType.Type.RPAREN, "Expected ')' to end '('")
		
		return Expression.Call.new(callee, paren, arguments)
	end
	
	function self.finishSetCall(callee)
		local index = self.expression()
		local paren = self.consume(TokenType.Type.RBOXY, "Expected ']' to end '['")
		
		return Expression.SetCall.new(callee, paren, index)
	end
	
	function self.finishDotSetCall(callee)
		local index = self.consume(TokenType.Type.IDENTIFIER, "Expected identifier in set call")
		
		local e = Expression.Literal.new("\""..index.value.."\"")
		
		return Expression.SetCall.new(callee, e, e)
	end
	
	function self.call()
		local expr = self.primary()
		
		while (true) do
			if (self.match({TokenType.Type.LPAREN})) then
				expr = self.finishCall(expr)
			elseif (self.match({TokenType.Type.LBOXY})) then
				expr = self.finishSetCall(expr)
			elseif (self.match({TokenType.Type.DOT})) then
				expr = self.finishDotSetCall(expr)
			else
				break
			end
		end
		
		return expr
	end
	
	function self.newSet()
		local index = {}
		local values = {}
		
		if not self.check(TokenType.Type.RCURLY) then
			repeat
				table.insert(index, self.expression())
				self.consume(TokenType.Type.DOTS, "Expected ':' to start value of set...?")
				table.insert(values, self.expression())
			until not (self.match({TokenType.Type.COMMA}))
		end
		
		self.consume(TokenType.Type.RCURLY, "Expected '}' to finish '{'")
		
		return Expression.Set.new({i = index, v = values})
	end
	
	function self.unary()
		if (self.match({TokenType.Type.TAG, TokenType.Type.NOT, TokenType.Type.MINUS, TokenType.Type.PLPL, TokenType.Type.MINMN})) then 
			local operator = self.previous()
			local right = self.unary()
			return Expression.Unary.new(operator, right)
		end
		
		return self.call()
	end
	
	function self.rightunary()
		local expr = self.unary()
		if (self.match({TokenType.Type.PLPL, TokenType.Type.MINMN})) then 
			local operator = self.previous()
			return Expression.Unary.new(operator, expr)
		end

		return expr
	end
	
	function self.pow() 
		local expr = self.rightunary()

		while (self.match({TokenType.Type.POW, TokenType.Type.POWEQ})) do
			local operator = self.previous()
			local right = self.rightunary()
			expr = Expression.Binary.new(expr, operator, right)
		end

		return expr
	end
	
	function self.factor() 
		local expr = self.pow()

		while (self.match({TokenType.Type.DIVIDE, TokenType.Type.MULTIPLY, TokenType.Type.DIVIEQ, TokenType.Type.MULTIPEQ, TokenType.Type.FLOOR, TokenType.Type.FLOEQ, TokenType.Type.REMAINDEQ, TokenType.Type.REMAINDER})) do
			local operator = self.previous()
			local right = self.pow()
			expr = Expression.Binary.new(expr, operator, right)
		end
		
		return expr
	end
	
	function self.term() 
		local expr = self.factor()
		
		while (self.match({TokenType.Type.MINUS, TokenType.Type.PLUS, TokenType.Type.PLEQ, TokenType.Type.MINEQ})) do
			local operator = self.previous()
			local right = self.factor()
			expr = Expression.Binary.new(expr, operator, right)
		end
		
		return expr
	end
	
	function self.comparison() 
		local expr = self.term()
		
		while (self.match({TokenType.Type.RTRI, TokenType.Type.GREATERTHANOREQUALTO, TokenType.Type.LTRI, TokenType.Type.LESSTHANOREQUALTO})) do
			local operator = self.previous()
			if operator.TokenType == TokenType.Type.RTRI then
				operator.TokenType = TokenType.Type.GREATERTHAN
			end
			
			if operator.TokenType == TokenType.Type.LTRI then
				operator.TokenType = TokenType.Type.LESSTHAN
			end
			
			local right = self.term()
			
			expr = Expression.Binary.new(expr, operator, right)
		end
		
		return expr
	end
	
	function self.equality() 
		local expr = self.comparison()
		
		while (self.match({TokenType.Type.NOTEQ, TokenType.Type.DOUBLEQUAL})) do 
			local operator = self.previous()
			local right = self.comparison()
			
			expr = Expression.Binary.new(expr, operator, right)
		end
		
		return expr
	end
	
	function self.land()
		local expr = self.equality()
		
		while (self.match({TokenType.Type.AND})) do
			local operator = self.previous()
			local right = self.equality()
			expr = Expression.Logical.new(expr, operator, right)
		end
		
		return expr
	end
	
	function self.lor() 
		local expr = self.land()
		
		while self.match({TokenType.Type.OR})  do
			local operator = self.previous()
			local right = self.land()
			expr = Expression.Logical.new(expr, operator, right)
		end
		
		return expr
	end
	
	function self.assignment()
		local expr = self.lor()
		
		if (self.match({TokenType.Type.EQUAL})) then
			local equals = self.previous()
			local value = self.assignment()
			
			if (expr.__name == "Variable") then
				local name = expr.name
				return Expression.Assign.new(name, value)
			end
			
			self.error(self.peek(), "Invalid assigment target... make you are actually putting an expression in and NOT WASTING MY TIME!")
			
		end
		
		return expr
	end
	
	function self.expression() 
		return self.assignment()
	end
	
	function self.expressionStatement()
		local expr = self.expression()
		self.consumeMatch({TokenType.Type.SEMICOLON}, "Expected ';' end statement")
		return Statements.Expression.new(expr)
	end
	
	function self.block()
		local statements = {}
		
		while (not (self.check(TokenType.Type.RCURLY)) and not self.isAtEnd()) do
			table.insert(statements, self.declaration())
		end
		
		
		self.consumeMatch({TokenType.Type.RCURLY, TokenType.Type.END}, "Expected '}' after block syntax")
		
		return statements
	end
	
	function self.IfStatement()
		self.consumeMatch({TokenType.Type.LPAREN}, "Expected '(' after if")
		local condition = self.expression()
		self.consumeMatch({TokenType.Type.RPAREN}, "Expected ')' after condition")
		
		local thenBranch = self.statement()
		local elseIfBranch = {}
		
		while (true) do
			if (not self.isAtEnd() and self.match({TokenType.Type.ELSEIF})) then
				self.consumeMatch({TokenType.Type.LPAREN}, "Expected '(' after elif")
				local econdition = self.expression()
				self.consumeMatch({TokenType.Type.RPAREN}, "Expected ')' after condition")
				
				local ethenBranch = self.statement()
				
				table.insert(elseIfBranch, {condition = econdition, thenBranch = ethenBranch})
			else
				break
			end
		end
		
		local elseBranch = NIL
		if (self.match({TokenType.Type.ELSE})) then
			elseBranch = self.statement()
		end
		
		return Statements.If.new(condition, thenBranch, elseIfBranch, elseBranch)
	end
	
	function self.whileStatement()
		self.consumeMatch({TokenType.Type.LPAREN}, "Expected '(' after while")
		local condition = self.expression()
		self.consumeMatch({TokenType.Type.RPAREN}, "Expected ')' after condition")
		
		local body = self.statement()
		
		return Statements.While.new(condition, body)
	end
	
	function self.forStatement()
		
		self.consume(TokenType.Type.LPAREN, "Expected '(' after for")
		
		local initializer
		if ((self.match({TokenType.Type.SEMICOLON}))) then
			initializer = nil
		elseif (self.match({TokenType.Type.VAR})) then
			initializer = self.varDeclaration()
		else
			initializer = self.expressionStatement()
		end
		
		local condition = nil
		if (not(self.check(TokenType.Type.SEMICOLON))) then
			condition = self.expression()
		end
		self.consume(TokenType.Type.SEMICOLON, "Expected ';' after loop condition")
		
		local increment = nil
		if (not(self.check(TokenType.Type.RPAREN))) then
			increment = self.expression()
		end
	
		
		self.consumeMatch({TokenType.Type.RPAREN}, "Expected ')' after for expression")
		
		local body = self.statement()
		
		if (increment ~= nil) then
			body = Statements.Block.new({body, Statements.Expression.new(increment)})
		end
		
		if (condition == nil) then
			condition = Expression.Literal.new(true)
		end
		
		body = Statements.While.new(condition, body)
		
		if (initializer ~= nil) then
			body = Statements.Block.new({initializer, body})
		end
		
		return body
		
	end
	
	function self.lambda()
		self.consume(TokenType.Type.LPAREN, `Expected '(' after lambda declaration, pls add dat`)
		local parameters = {}
		if (not(self.check(TokenType.Type.RPAREN))) then
			repeat
				local r = self.consume(TokenType.Type.IDENTIFIER, "Expected some sort of, param name?")
				table.insert(parameters, r)

			until not (self.match({TokenType.Type.COMMA}))
		end
		self.consume(TokenType.Type.RPAREN, "Expected ')' after params, please don't hurt my eyes. From: Parser")

		self.consume(TokenType.Type.LCURLY, `Expected '\{' for like, a lambda body of sorts.`)
		local body = self.block()
		return Expression.Lambda.new(parameters, body)
	end
	
	function self.func(kind)
		local name = self.consume(TokenType.Type.IDENTIFIER, `Expected {kind} name or smth`)
		self.consume(TokenType.Type.LPAREN, `Expected '(' after {kind} name, pls do so`)
		local parameters = {}
		if (not(self.check(TokenType.Type.RPAREN))) then
			repeat
				local r = self.consume(TokenType.Type.IDENTIFIER, "Expected some sort of, param name?")
				table.insert(parameters, r)
				
			until not (self.match({TokenType.Type.COMMA}))
		end
		self.consume(TokenType.Type.RPAREN, "Expected ')' after params, please don't hurt my eyes. From: Parser")
		
		self.consume(TokenType.Type.LCURLY, `Expected '\{' for like, a {kind} body of sorts.`)
		local body = self.block()
		return Statements.Function.new(name, parameters, body)
	end
	
	function self.returnStatement()
		local keyword = self.previous()
		local value = NIL
		if (not(self.check(TokenType.Type.SEMICOLON))) then
			value = self.expression()
		end
		
		self.consume(TokenType.Type.SEMICOLON, "Oh, don't worry. Your return statement ALSO requires a semicolon!")
		
		return Statements.Return.new(keyword, value)
	end
	
	function self.itemStatement()
		self.consume(TokenType.Type.LCURLY, "Expected '{' to start an item 🤣")
		local body = self.block()
		return Statements.Item.new(Statements.Block.new(body))
	end
	
	function self.switch()
		local expr = self.expression()
		local exprs = {case={}}
		
		self.consume(TokenType.Type.LCURLY, "Expect { to begin switch")
		
		while (self.match({TokenType.Type.CASE})) do
			local e = self.expression()
			self.consume(TokenType.Type.ARROW, "Expect => cuz yea")
			local b = self.expression()
			
			local look = { witness = e, ifTrue = b }
			self.consume(TokenType.Type.SEMICOLON, "Expect ; cuz ye")
			table.insert(exprs.case, look)
		end
		
		if (self.match({TokenType.Type.DEFAULT})) then
			self.consume(TokenType.Type.ARROW, "Expect => cuz yea")
			local b = self.expression()

			local look = {ifTrue = b }
			self.consume(TokenType.Type.SEMICOLON, "Expect ; cuz ye")
			exprs["default"] = look
		end
		
		self.consume(TokenType.Type.RCURLY, "Expect } to end switch")
		
		return Expression.Switch.new(expr, exprs)
	end
	
	function self.switchStatement()
		self.consume(TokenType.Type.LPAREN, "We need '(' after switch, thanks bud. ")
		local suspect = self.expression()
		self.consume(TokenType.Type.RPAREN, "We need ')' to end your suspect declaration! ")
		
		self.consume(TokenType.Type.LCURLY, "'{' required to begin the investigation ")
		
		local cases = {case = {}}
		
		while (self.match({TokenType.Type.CASE})) do
			local witness = self.expression()
			self.consume(TokenType.Type.LCURLY, "Hey, we need a '{' to continue our investigation on this switch, thanks")
			local block = self.block()
			
			local look = { witness = witness, ifTrue = Statements.Block.new(block) }
			table.insert(cases.case, look)
		end
		
		if (self.match({TokenType.Type.DEFAULT})) then
			self.consume(TokenType.Type.LCURLY, "Hey, we need a '{' to continue our investigation on this switch, thanks")
			local block = self.block()
			
			local look = { ifTrue = Statements.Block.new(block) }
			cases["default"] = look
		end
		
		self.consume(TokenType.Type.RCURLY, "'}' required to end, and evaluate this very important investigation")
		return Statements.Switch.new(suspect, cases)
	end
	
	function self.pairsStatement()
		local keyword = self.peek()
		self.advance()
		
		self.consume(TokenType.Type.LPAREN, "We need '(' to start the pairs stmt")
		local set = self.expression()
		self.consume(TokenType.Type.RPAREN, "need ')' to end the expression")
		self.consume(TokenType.Type.LCURLY, "Expected '{' to begin block")
		local block = Statements.Block.new(self.block())
		return Statements.Pairs.new(keyword, set, block)
	end
	
	function self.breakout() 
		return Statements.Break.new()
	end
	
	
	function self.statement()
		if (self.match({TokenType.Type.ITEM})) then return self.itemStatement() end
		if (self.match({TokenType.Type.IF})) then return self.IfStatement() end
		if (self.match({TokenType.Type.LCURLY, TokenType.Type.DO})) then return Statements.Block.new(self.block()) end
		if (self.match({TokenType.Type.WHILE})) then return self.whileStatement() end
		if (self.match({TokenType.Type.FOR})) then return self.forStatement() end
		if (self.match({TokenType.Type.FUNCTION})) then return self.func("function") end
		if (self.match({TokenType.Type.RETURN})) then return self.returnStatement() end
		if (self.match({TokenType.Type.SWITCH})) then return self.switchStatement() end
		if (self.check(TokenType.Type.PAIRS)) then return self.pairsStatement() end
		if (self.match({TokenType.Type.BREAK})) then return self.breakout() end
		return self.expressionStatement()
	end
	
	function self.varDeclaration()
		local name, success = self.consume(TokenType.Type.IDENTIFIER, "Expected <identifier> here.")
		
		if not success then
			return name, success
		end
		
		local initializer = NIL
		if (self.match({TokenType.Type.EQUAL})) then
			initializer = self.expression()
		end
		
		local result, success = self.consumeMatch({TokenType.Type.SEMICOLON}, "Expected ';' end statement")
		
		if (not success) then
			return result, success
		end
		
		return Statements.Var.new(name, initializer), true
	end
	
	function self.constVarDeclaration()
		local name, success = self.consume(TokenType.Type.IDENTIFIER, "Expected <identifier> here.")

		if not success then
			return name, success
		end

		local initializer = nil
		if (self.match({TokenType.Type.EQUAL})) then
			initializer = self.expression()
		end

		local result, success = self.consumeMatch({TokenType.Type.SEMICOLON}, "Expected ';' end statement")

		if (not success) then
			return result, success
		end

		return Statements.ConstVar.new(name, initializer), true
	end
	
	function self.declaration()
		local success, result = pcall(function()
			if (self.match({TokenType.Type.VAR})) then return self.varDeclaration() 
			elseif (self.match({TokenType.Type.CONST})) then return self.constVarDeclaration() end
			return self.statement()
		end)
		
		if success then
			return result
		else
			self.synchronize()
			return nil
		end
	end
	
	function self.parse()
		local statements = {}
		while (not self.isAtEnd()) do
			table.insert(statements, self.declaration())
		end
		
		if #statements == 0 then return statements end
		
		if (#statements ~= 1 or statements[1].__name ~= "Item") then
			self.error(self.peek(), "Couldn't find an item.... I need one!")
		else
			for i,v in pairs(statements[1]["body"]["statements"]) do
				if (v.__name ~= "Function" and v.__name ~= "Var" and v.__name ~= "ConstVar" and v.__name ~= "Variable" and v.__name ~= "Assign") then
					self.error(self.peek(), "Items can only have functions and variable declarations")
				end
			end
		end
		
		return statements
	end
	
	return self
end

return Parser
