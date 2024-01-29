local TokenTypes = require(game.ReplicatedStorage.lang.TokenType)
local Errors = require(game.ReplicatedStorage.lang.Errors)
local Util = require(game.ReplicatedStorage.lang.Util)
local Token = require(game.ReplicatedStorage.lang.Token)

local Lexer = {}


function Lexer.new(source: string)
	local self = {}
	local result = {}
	
	self.len = source:len()
	self.source = source:split("")
	self.errors = {}
	self.start = 1
	self.current = 1
	self.line = 1
	self.col = 1
	self.hadError = false
	
	function self.advance()
		self.col += 1
		self.current += 1
		return self.source[self.current]
	end
	
	function self.peek() 
		if(self.finished())then return "\0" end
		return self.source[self.current]
	end
	
	function self.peekNext()
		if(self.finished(self.current+1))then return "\0" end
		return self.source[self.current + 1]
	end
	
	function self.finished(at: number?) 
		if(at~=nil)then
			return at == self.len
		else
			return self.current > self.len
		end
	end
	
	function self.NewWithLiteral(Ttype, ln, col, lit) 
		table.insert(result, Token.new(ln, col, Ttype, Util.substring(self.source, self.start, self.current), lit))
	end
	
	function self.NewWithValue(Ttype, ln, col)
		table.insert(result, Token.new(ln, col, Ttype, Util.substring(self.source, self.start, self.current), nil))
	end
	
	function self.NewEmpty(Ttype, ln, col) 
		table.insert(result, Token.new(ln, col, Ttype, "", nil))
	end
	
	function self.matches(char: string) 
		if(self.finished())then return false end
		if (self.peek() == char) then return true end
		return false
	end
	
	function self.matchesString(s: string)
		
		for _,v in pairs(s:split("")) do
			if (self.peek() ~= v) then
				return false
			end
			self.advance()
		end
		return true
	end
	
	function self.isAlpha(c) 
		return (
			"a" <= c and c <= "z"
		) or (
			"A" <= c and c <= "Z"
		) or c == "_"
	end
	
	function self.isAlphaNumeric(c) 
		return self.isAlpha(c) or self.isDigit(c)
	end
	
	function self.isDigit(c) 
		return (
			"0" <= c and c <= "9"
		)
	end
	
	function self.number()
		local digits = 0
		
		while (not (self.finished(self.current + 1)) and ( (self.isDigit(self.peekNext() or " "))) or self.peekNext() == ".") do
			if (self.peekNext() == ".") then
				if (not(self.finished(self.current + 2))) then
					if (self.isDigit(self.source[self.current + 2])) then
						digits += 1
					else
						break
					end
				else
					break
				end
			end
			self.advance()
		end
		
		if digits <= 1 then
			self.NewWithLiteral(TokenTypes.Type.NUMBER, self.line, self.col, tonumber(Util.substring(self.source, self.start, self.current)))
		else
			self.hadError = true
			table.insert(self.errors, Errors.IncorrectCharacterError.new(`Too many dots in number literal`, self.line, self.col))
		end
	end
	
	
	function self.identifier()
		while (self.isAlphaNumeric(self.peekNext()) and not(self.finished())) do
			self.advance()
		end
		
		local value = Util.substring(self.source, self.start, self.current)
		
		if (TokenTypes.Values[value]) then
			self.NewWithValue(TokenTypes.Values[value], self.line, self.col)
		else
			self.NewWithValue(TokenTypes.Type.IDENTIFIER, self.line, self.col)
		end
	end
	
	function self.string(finishing)
		self.advance()
		
		while (self.peek() ~= finishing and not self.finished()) do
			self.advance()
		end
		
		if (self.finished()) then
			self.hadError = true
			table.insert(self.errors, Errors.IncorrectCharacterError.new(`Expected \`{finishing}\` to complete string`, self.line, self.col))
			return
		end
		
		self.NewWithLiteral(TokenTypes.Type.STRING, self.line, self.col, source:sub(self.start + 1, self.current - 1))
	end
	
	function self.evaluate()
		
		Util.switch(self.peek(), {
			['#'] = function(c)
				while not self.finished() and self.source[self.current] ~= "\n" do
					self.advance()
				end
			end;
			['\n'] = function(c)
				self.line += 1
				self.col = 0
			end;
			["="] = function (c)
				if (self.peekNext() == "=") then
					self.advance()
					self.NewWithValue(TokenTypes.Type.DOUBLEQUAL, self.line, self.col)
				elseif (self.peekNext() == ">") then
					self.advance()
					self.NewWithValue(TokenTypes.Type.ARROW, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.EQUAL, self.line, self.col)
				end
			end;
			["+"] = function(c)
				if (self.peekNext() == "=") then
					self.advance()
					self.NewWithValue(TokenTypes.Type.PLEQ, self.line, self.col)
				elseif (self.peekNext() == "+") then
					self.advance()
					self.NewWithValue(TokenTypes.Type.PLPL, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.PLUS, self.line, self.col)
				end
			end;
			["-"] = function(c)
				if (self.peekNext() == "=") then
					self.advance()
					self.NewWithValue(TokenTypes.Type.MINEQ, self.line, self.col)
				elseif (self.peekNext() == "-") then
					self.advance()
					self.NewWithValue(TokenTypes.Type.MINMN, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.MINUS, self.line, self.col)
				end
			end;
			["/"] = function(c)
				if (self.peekNext() == "/") then
					self.advance()
					if (self.peekNext() == "=") then
						self.advance()
						self.NewWithValue(TokenTypes.Type.FLOEQ, self.line, self.col)
					else
						self.NewWithValue(TokenTypes.Type.FLOOR, self.line, self.col)
					end
				elseif (self.peekNext() == "=") then
					self.advance()
					self.NewWithValue(TokenTypes.Type.DIVIEQ, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.DIVIDE, self.line, self.col)
				end
			end;
			[">"] = function(c) 
				if self.matchesString(">=") then
					self.NewWithValue(TokenTypes.Type.GREATERTHANOREQUALTO, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.RTRI, self.line, self.col)
				end
			end;
			["*"] = function(c) 
				if self.matchesString("*=") then
					self.NewWithValue(TokenTypes.Type.MULTIPEQ, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.MULTIPLY, self.line, self.col)
				end
			end;
			["%"] = function(c) 
				if self.matchesString("%=") then
					self.NewWithValue(TokenTypes.Type.REMAINDEQ, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.REMAINDER, self.line, self.col)
				end
			end;
			["^"] = function(c) 
				if self.matchesString("^=") then
					self.NewWithValue(TokenTypes.Type.POWEQ, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.POW, self.line, self.col)
				end
			end;
			["<"] = function(c) 
				if self.matchesString("<=") then
					self.NewWithValue(TokenTypes.Type.LESSTHANOREQUALTO, self.line, self.col)
				else
					self.NewWithValue(TokenTypes.Type.LTRI, self.line, self.col)
				end
			end;
			["{"] = function(c)
				self.NewWithValue(TokenTypes.Type.LCURLY, self.line, self.col)
			end;
			[":"] = function(c)
				self.NewWithValue(TokenTypes.Type.DOTS, self.line, self.col)
			end;
			["@"] = function(c)
				self.NewWithValue(TokenTypes.Type.TAG, self.line, self.col)
			end;
			["}"] = function(c)
				self.NewWithValue(TokenTypes.Type.RCURLY, self.line, self.col)
			end;
			["("] = function(c)
				self.NewWithValue(TokenTypes.Type.LPAREN, self.line, self.col)
			end;
			[")"] = function(c)
				self.NewWithValue(TokenTypes.Type.RPAREN, self.line, self.col)
			end;
			["["] = function(c)
				self.NewWithValue(TokenTypes.Type.LBOXY, self.line, self.col)
			end;
			["]"] = function(c)
				self.NewWithValue(TokenTypes.Type.RBOXY, self.line, self.col)
			end;
			["."] = function(c)
				self.NewWithValue(TokenTypes.Type.DOT, self.line, self.col)
			end;
			[","] = function(c)
				self.NewWithValue(TokenTypes.Type.COMMA, self.line, self.col)
			end;
			[";"] = function(c)
				self.NewWithValue(TokenTypes.Type.SEMICOLON, self.line, self.col)
			end;
			["!"] = function(c) 
				if self.peekNext() == "=" then
					self.advance()
					self.NewWithValue(TokenTypes.Type.NOTEQ, self.line, self.col)
				end
			end;
			["$"] = function(c)
				self.NewWithValue(TokenTypes.Type.LAMBDA, self.line, self.col)
			end;
			[" "] = function(c) 
				
			end;
			["\t"] = function(c) 
				
			end;
			["\r"] = function(c) 
				
			end;
			['"'] = function(c) 
				self.string('"')
			end;
			["'"] = function(c) 
				self.string("'")
			end;
			['__default'] = function(c)
				if self.isDigit(c) then
					self.number()
				elseif self.isAlpha(c) then
					self.identifier()
				else
					self.hadError = true
					table.insert(self.errors, Errors.IncorrectCharacterError.new(`Unexpected {self.peek()}`, self.line, self.col))
				end
			end
		})
		
		self.advance()
		
	end
	
	function self.scan()
		while (not(self.finished())) do
			self.start = self.current
			self.evaluate()
		end
		
		self.NewEmpty(TokenTypes.Type.EOF, self.line, self.col)
		return result
	end
	
	return self
end


return Lexer
