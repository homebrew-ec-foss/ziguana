const ast = @import("ast.zig");
const std = @import("std");
const lexer = @import("lexer.zig");
const Token = lexer.Token;
const TokenTag = lexer.TokenTag;

//all parser declarations and implementation in this file
const ParseErr = struct {
    message: []const u8,
    token: Token,
};

pub const Parser = struct {
    tokens: []const Token,
    current: usize,
    next: usize,
    errors: std.ArrayList(ParseErr),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, tokens: []const Token) Parser {
        return .{ .tokens = tokens, .current = 0, .next = 1, .errors = std.ArrayList(ParseErr).init(allocator) };
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

    fn match(self: *Self, expectedTag: TokenTag) bool {
        if (expectedTag == getTag(self.tokens[self.current])) {
            return true;
        } else {
            return false;
        }
    }

    fn previous(self: *Self) Token {
        return self.tokens[self.current - 1];
    }

    fn advance(self: *Self) Token {
        if (!self.isAtEnd()) {
            self.current += 1;
            return self.tokens[self.current - 1];
        } else {
            return self.tokens[self.current];
        }
    }
};

pub fn parse() !void {}
