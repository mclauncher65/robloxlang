local Token = {}

Token.Type = {
	ITEM = 0x00000001, FUNCTION = 0x00000002, IF = 0x00000003, WHILE = 0x00000004, FOR = 0x00000005, TRUE = 0x00000006, FALSE = 0x00000007, VAR = 0x00000008,
	LCURLY = 0x00000009, RCURLY = 0x0000000a, LBOXY = 0x0000000b, RBOXY = 0x0000000c, LPAREN = 0x0000000d, RPAREN = 0x0000000e, SEMICOLON = 0x0000000f,
	STRING = 0x00000010, IDENTIFIER = 0x00000011, NUMBER = 0x00000012, NIL = 0x00000013,
	AND = 0x00000014, NOT = 0x00000015, OR = 0x00000016,
	PLUS = 0x00000017, MINUS = 0x00000018, DIVIDE = 0x00000019, MULTIPLY = 0x00000020, REMAINDER = 0x00000021, FLOOR = 0x0000002a,
	PLEQ = 0x0000002b, MINEQ = 0x0000002c, DIVIEQ = 0x0000002d, MULTIPEQ = 0x0000002e, REMAINDEQ = 0x0000002f, FLOEQ = 0x00000030,
	PLPL = 0x00000031, MINMN = 0x00000032,
	LTRI = 0x00000033, RTRI = 0x00000034,
	EQUAL = 0x00000035, DOUBLEQUAL = 0x00000036,
	GREATERTHAN = 0x00000037, LESSTHAN = 0x00000038,
	GREATERTHANOREQUALTO = 0x00000039, LESSTHANOREQUALTO = 0x00000040,
	DOT = 0x00000041, COMMA = 0x00000042, NEWLINE = 0x00000043,
	EOF = 0x00000044,
	POW = 0x00000045,
	POWEQ = 0x00000046,
	NOTEQ = 0x00000047,
	RETURN = 0x00000048,
	ELSEIF = 0x00000049,
	ELSE = 0x00000050,
	DOTS = 0x00000051,
	TAG = 0x00000052,
	LAMBDA = 0x00000053,
	CONST = 0x00000054,
	SWITCH = 0x00000055,
	CASE = 0x00000056,
	DEFAULT = 0x00000057,
	PAIRS = 0x00000058,
	ARROW = 0x00000059,
	BREAK = 0x00000060
}

Token.Values = {
	item = Token.Type.ITEM, ["function"] = Token.Type.FUNCTION, ["if"] = Token.Type.IF, ["for"] = Token.Type.FOR, ["true"] = Token.Type.TRUE, ["false"] = Token.Type.FALSE, ["var"] = Token.Type.VAR,
	["{"] = Token.Type.LCURLY, ["}"] = Token.Type.RCURLY, ["["] = Token.Type.LBOXY, ["]"] = Token.Type.RBOXY, ["("] = Token.Type.LPAREN, [")"] = Token.Type.RPAREN, [";"] = Token.Type.SEMICOLON,
	["<string>"] = Token.Type.STRING, ["<identifier>"] = Token.Type.IDENTIFIER, ["<number>"] = Token.Type.NUMBER, ["nil"] = Token.Type.NIL,
	["and"] = Token.Type.AND, ["not"] = Token.Type.NOT, ["or"] = Token.Type.OR,
	["+"] = Token.Type.PLUS, ["-"] = Token.Type.MINUS, ["*"] = Token.Type.MULTIPLY, ["/"] = Token.Type.DIVIDE, ["%"] = Token.Type.REMAINDER, ["//"] = Token.Type.FLOOR,
	["+="] = Token.Type.PLEQ, ["-="] = Token.Type.MINEQ, ["/="] = Token.Type.DIVIEQ, ["*="] = Token.Type.MULTIPEQ, ["%="] = Token.Type.REMAINDEQ, ["//="] = Token.Type.FLOEQ,
	["++"] = Token.Type.PLPL, ["--"] = Token.Type.MINMN,
	["<"] = Token.Type.LTRI, [">"] = Token.Type.RTRI,
	["="] = Token.Type.EQUAL, ["=="] = Token.Type.DOUBLEQUAL,
	[">="] = Token.Type.GREATERTHANOREQUALTO, ["<="] = Token.Type.LESSTHANOREQUALTO,
	["."] = Token.Type.DOT, [","] = Token.Type.COMMA, ["\n"] = Token.Type.NEWLINE,
	["^"] = Token.Type.POW,
	["^="] = Token.Type.POWEQ,
	['!='] = Token.Type.NOTEQ,
	[':'] = Token.Type.DOTS,
	["return"] = Token.Type.RETURN,
	["elif"] = Token.Type.ELSEIF,
	["else"] = Token.Type.ELSE,
	["while"] = Token.Type.WHILE,
	["@"] = Token.Type.TAG,
	["$"] = Token.Type.LAMBDA,
	["const"] = Token.Type.CONST,
	["switch"] = Token.Type.SWITCH,
	["case"] = Token.Type.CASE,
	["default"] = Token.Type.DEFAULT,
	["pairs"] = Token.Type.PAIRS,
	["break"] = Token.Type.BREAK,
	["=>"] = Token.Type.ARROW
}

Token.Indexes = {}

for i,v in pairs(Token.Values) do
	Token.Indexes[v] = i
end

return Token
