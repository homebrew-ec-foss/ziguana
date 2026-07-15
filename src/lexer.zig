const std = @import("std");

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
pub const Lexer = struct {
    source: []const u8,
    current: usize,
    line: usize,
    column: usize,
    pub fn create(source: []const u8) Lexer {
        return .{
            .source = source,
            .current = 0,
            .line = 1,
            .column = 1,
        };
    }
}; //current, line and colum reprsent the current state of the lexer

fn peekNext(lexer: *Lexer) ?u8 {
    if (lexer.current + 1 >= lexer.source.len) {
        return null;
    } else {
        return (lexer.source[lexer.current + 1]);
    }
}

fn isAtEnd(lexer: *Lexer) bool {
    return (lexer.current >= lexer.source.len);
}

fn match(lexer: *Lexer, expected: u8) bool {
    if (isAtEnd(lexer)) {
        return false;
    }
    if (lexer.source[lexer.current] != expected) {
        return false;
    } else {
        lexer.current += 1;
        return true;
    }
}
fn moveNext(lexer: *Lexer) ?u8 {
    if (isAtEnd(lexer)) {
        return null;
    }
    const c = lexer.source[lexer.current];
    lexer.current += 1;
    return c;
}

pub fn lex(lexer: *Lexer) void {
    while (!isAtEnd(lexer)) {
        //main lexing loop
    }
}
