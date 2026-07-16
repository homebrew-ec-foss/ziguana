const std = @import("std");
const print = std.debug.print();

pub const TypeKind = enum {
    Int,
    Bool, //B is in Upper-case
    String,
};

pub const TokenTag = enum {
    eof,
    lparen,
    rparen,
    lbrace, // {
    rbrace, // }
    lbracket, //[
    rbracket, //]
    comma,
    plus,
    minus,
    star,
    slash,
    mod,
    equal, // =
    plus_equal, // +=
    minus_equal, // -=
    star_equal, // *=
    slash_equal, // /=
    mod_equal, // %=
    equality, // ==
    inequality, // !=
    lessthan,
    lessthan_equal, // <=
    greaterthan,
    greaterthan_equal, // >=
    return_,
    type_,
    string,
    identifier,
    number,
    colon,
    if_,
    else_,
    while_,
    func,
    semicolon,
    true_,
    false_,
};

pub const TokenPayload = union(TokenTag) {
    eof: void,
    lparen: void,
    rparen: void,
    lbrace: void, // {
    rbrace: void, // }
    lbracket: void, //[
    rbracket: void, //]
    comma: void,
    plus: void,
    minus: void,
    star: void,
    slash: void,
    mod: void,
    equal: void, // =
    plus_equal: void, // +=
    minus_equal: void, // -=
    star_equal: void, // *=
    slash_equal: void, // /=
    mod_equal: void, // %=
    equality: void, // ==
    inequality: void, // !=
    lessthan: void,
    lessthan_equal: void, // <=
    greaterthan: void,
    greaterthan_equal: void, // >=
    return_: void,
    type_: TypeKind,
    string: []const u8,
    identifier: []const u8,
    number: i64,
    colon: void,
    if_: void,
    else_: void,
    while_: void,
    func: void,
    semicolon: void,
    true_: void,
    false_: void,
};

pub const Token = struct {
    payload: TokenPayload,
    line: usize,
    column: usize,
};

// Lexer structure - 
pub const Lexer = struct {
    input: []const u8,        // file content
    position: usize = 0,      // current character position
    read_position: usize = 0, // next character position
    ch: u8 = 0,               // character at the current position
    line: usize = 1,          // line number
    column: usize = 0,        // column number
};


// Helper Functions - 
pub fn readChar(self:*Lexer) void
{
    if(self.read_position >= self.input.len)
    {
        self.ch = 0;
    }
    else
    {
        self.ch = self.input[self.read_position];
    }
    self.position = self.read_position;
    self.read_position += 1;
    self.column +=1;
}
pub fn peekChar(self:*Lexer) u8
{
    if(self.read_position >= self.input.len)
    {
        return 0;
    }
    else
    {
        return self.input[self.read_position];
    }
}
pub fn skipWhiteSpace(self:*Lexer) void
{
    while(self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r')
    {
        if(self.ch == '\n')
        {
            self.line += 1;
            self.column = 0;
        }
        self.readChar();
    }
}
pub fn skipComment(self:*Lexer) void
{
    while(self.ch != '\n' and self.ch != 0)
    {
        self.readChar();
    }
    self.skipWhiteSpace();
}
fn isDigit(chr:u8) bool
{
    if(chr >= '0' and chr <= '9')
    {
        return true;
    }
    else
    {
        return false;
    }
}
fn isAlpha(chr:u8) bool
{
    if((chr >= 'A' and chr <= 'Z') or (chr >= 'a' and chr <= 'z'))
    {
        return true;
    }
    else
    {
        return false;
    }
}
pub fn readNumber(self:*Lexer) i64
{
    const start = self.position;
    while(isDigit(self.ch))
    {
        self.readChar();
    }
    const number_slice: []const u8 = self.input[start..self.position];
    return std.fmt.parseInt(i64, number_slice, 10) catch 0;
}
pub fn readString(self:*Lexer) []const u8
{
    self.readChar(); // ignoring the opening quote
    const start:usize = self.position;
    while(self.ch != '"' and self.ch != 0)
    {
        if(self.ch == '\n')
        {
            self.line += 1;
            self.column = 0;
        }
        self.readChar();
    }
    if(self.ch == 0)
    {
        // ** should work on this
        return self.input[start..self.position];
        //error did not put closing quote for the string
    }
    const string_slice: []const u8 = self.input[start..self.position];
    self.readChar(); // ignoring the closing quote
    return string_slice;
}
pub fn readIdentifier(self: *Lexer) []const u8
{
    const start:usize = self.position;
    while(isDigit(self.ch) or isAlpha(self.ch) or self.ch == '_')
    {
        self.readChar();
    }
    return self.input[start..self.position];
}  
pub fn lookUpKeyword(word: []const u8) TokenPayload
{
    if (std.mem.eql(u8, word, "fn")) return .{ .func = {} };
    if (std.mem.eql(u8, word, "int")) return .{ .type_ = .Int };
    if (std.mem.eql(u8, word, "bool")) return .{ .type_ = .Bool };
    if (std.mem.eql(u8, word, "string")) return .{ .type_ = .String};
    if (std.mem.eql(u8, word, "if")) return .{ .if_ = {} };
    if (std.mem.eql(u8, word, "else")) return .{ .else_ = {} };
    if (std.mem.eql(u8, word, "while")) return .{ .while_ = {} };
    if (std.mem.eql(u8, word, "return")) return .{ .return_ = {} };
    if (std.mem.eql(u8, word, "true")) return .{ .true_ = {} };
    if (std.mem.eql(u8, word, "false")) return .{ .false_ = {} };
    return .{ .identifier = word };
}