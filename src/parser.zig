const ast = @import("ast.zig");
const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const TokenTag = lexer.TokenTag;
const TokenPayload = lexer.TokenPayload;

const Stmt = ast.Stmt;
const Param = ast.Param;
const VarInit = ast.VarInit;
const Expr = ast.Expr;
const Literal = ast.Literal;

//errors
const parserErros = error{
    UnexpectedLiteral,
    ExpectedAssignmentOperator,
};

//all parser declarations and implementation in this file
pub const ParseErr = struct {
    message: []const u8,
    token: Token,
};

pub const Parser = struct {
    tokens: []const Token,
    current: usize,
    next: usize,
    errors: std.ArrayList(ParseErr),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, tokens: []const Token) Parser {
        return .{ .tokens = tokens, .current = 0, .next = 1, .errors = std.ArrayList(ParseErr).init(allocator), .allocator = allocator };
    }

    fn getTag(token: Token) TokenTag {
        return std.meta.activeTag(token.payload);
    }
    //Parser helper functions start here

    fn peek(self: *Self) Token {
        return self.tokens[self.current];
    }

    fn isAtEnd(self: *const Self) bool {
        if (getTag(self.tokens[self.current]) == .eof) {
            return true;
        }
        return false;
    }

    fn previous(self: *Self) Token {
        return self.tokens[self.current - 1];
    }

    fn advance(self: *Self) Token {
        if (!self.isAtEnd()) {
            self.current += 1;
            self.next = self.current + 1;
            return self.tokens[self.current - 1];
        } else {
            return self.tokens[self.current];
        }
    }
    fn consume(self: *Self, expected: TokenTag) !Token {
        if (getTag(self.peek()) != expected)
            return error.ExpectedToken;

        return self.advance();
    }
    fn peekNext(self: *Self) Token {
        if (self.current + 1 >= self.tokens.len) {
            return self.tokens[self.current];
        }

        return self.tokens[self.current + 1];
    }

    fn parseProgram(self: *Self) !*Stmt {
        _ = self;
    }
    fn parseFunction(self: *Self) !*Stmt {
        _ = self;
    }
    fn parseBlock(self: *Self) !*Stmt {
        _ = self;
    }
    fn parseStatement(self: *Self) !*Stmt {
        _ = self;
    }
    fn parseParameter(self: *Self) !Param {
        const typeToken = self.advance();
        if (getTag(typeToken) != .type_) {
            return error.ExpectedType;
        }
        const ty = typeToken.payload.type_;
        const identToken = self.advance();
        if (getTag(identToken) != .identifier) {
            return error.ExpectedIdentifier;
        }
        const ident = identToken.payload.identifier;

        return .{
            .ty = ty,
            .name = ident,
        };
    }
    fn parseLiteral(self: *Self) !*Expr {
        const token = self.advance();
        switch (token.payload) {
            .number => |value| {
                return try ast.makeLiteral(self.allocator, .{
                    .number = value,
                });
            },
            .string => |value| {
                return try ast.makeLiteral(self.allocator, .{
                    .string = value,
                });
            },
            .true_ => {
                return try ast.makeLiteral(self.allocator, .{
                    .boolean = true,
                });
            },
            .false_ => {
                return try ast.makeLiteral(self.allocator, .{
                    .boolean = false,
                });
            },
            //handle error handling here for unexpected literal
            else => return error.UnexpectedLiteral,
        }
    }
    fn parseVarInit(self: *Self) !*VarInit {
        _ = self;
    }
    fn parseExpression(self: *Self) !*Expr {
        return self.parseEquality();
    }
    fn parseEquality(self: *Self) !*Expr {
        var left = try self.parseComparison();
        while (getTag(self.peek()) == .equality or getTag(self.peek()) == .inequality) {
            const operator = self.advance();
            const right = try self.parseComparison();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right);
        }
        return left;
    }
    fn parseComparison(self: *Self) !*Expr {
        var left = try self.parseTerm();

        while (getTag(self.peek()) == .lessthan or getTag(self.peek()) == .lessthan_equal or getTag(self.peek()) == .greaterthan or getTag(self.peek()) == .greaterthan_equal) {
            const operator = self.advance();
            const right = try self.parseTerm();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right);
        }

        return left;
    }
    fn parseTerm(self: *Self) !*Expr {
        var left = try self.parseFactor();

        while (getTag(self.peek()) == .plus or getTag(self.peek()) == .minus) {
            const operator = self.advance();
            const right = try self.parseFactor();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right);
        }
        return left;
    }
    fn parseFactor(self: *Self) !*Expr {
        var left = try self.parsePrimary();
        while (getTag(self.peek()) == .star or getTag(self.peek()) == .slash or getTag(self.peek()) == .mod) {
            const operator = self.advance();
            const right = try self.parsePrimary();
            left = try ast.makeBinary(self.allocator, getTag(operator), left, right);
        }
        return left;
    }
    fn parsePrimary(self: *Self) !*Expr {
        var token = self.peek();
        switch (getTag(token)) {
            .number, .string, .true_, .false_ => {
                return self.parseLiteral();
            },
            .identifier => {
                if (getTag(self.peekNext()) == .lparen) {
                    return self.parseFunctionCall();
                }

                token = self.advance();
                return try ast.makeVariable(self.allocator, token.payload.identifier);
            },
            .lparen => {
                _ = self.advance();
                const expression = try self.parseExpression();
                _ = try self.consume(.rparen);
                return expression;
            },
            else => {
                return error.expectedexpression;
            },
        }
    }
    fn parseVarDecl(self: *Self) !*Stmt {
        _ = self;
    }
    fn parseAssignment(self: *Self) !*Stmt {
        const nameToken = try self.consume(.identifier);
        const name = nameToken.payload.identifier;
        var index: ?*Expr = null;
        if (getTag(self.peek()) == .lbracket) {
            _ = try self.consume(.lbracket);
            index = try self.parseExpression();
            _ = try self.consume(.rbracket);
        }
        const opToken = self.advance();
        const op = getTag(opToken);
        if (op != .equal and op != .plus_equal and op != .minus_equal) {
            return error.ExpectedAssignmentOperator;
        }
        const value = try self.parseExpression();
        _ = try self.consume(.semicolon);
        return ast.makeAssignment(self.allocator, name, index, op, value);
    }

    fn parseCallStatement(self: *Self) !*Stmt {
        _ = self;
    }
    fn parseIfStatement(self: *Self) !*Stmt {
        _ = try self.consume(.if_);
        _ = try self.consume(.lparen);
        const condition = try self.parseExpression();
        _ = try self.consume(.rparen);

        const if_branch = try self.parseBlock();//just parse the thing in {..}
        //check for else
        var else_branch: ?*Stmt = null;
        if (getTag(self.peek()) == .else_) {
            _ = try self.consume(.else_);
            else_branch = try self.parseBlock();
        }
        return ast.makeIfStmt(self.allocator, condition, if_branch, else_branch);


    }
    fn parseWhileStatement(self: *Self) !*Stmt {
        _ = self;
    }
    fn parseReturnStatement(self: *Self) !*Stmt {
        
    }
    fn parseFunctionCall(self: *Self) !*Expr {
        _ = self;
    }

    pub fn parse(self: *Self) !*Stmt {
        //entry point of parser
        _ = self;
    }
};
