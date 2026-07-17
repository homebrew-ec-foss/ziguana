const std = @import("std");
const TokenTag = @import("lexer.zig").TokenTag;
const TypeKind = @import("lexer.zig").TypeKind;

pub const Literal = union(enum) {
    number: i64,
    string: []const u8,
    boolean: bool,
};

pub const Expr = union(enum) {
    variable: []const u8,

    binary: struct {
        op: TokenTag, //operator
        left: *Expr,
        right: *Expr,
    },
    call: struct {
        calling_func: []const u8,
        args: []Expr,
    },
    index: struct {
        array: []const u8,
        subscript: *Expr,
    },
    literal: Literal,
};

pub const VarInit = union(enum) {
    expr: *Expr,
    array_literal: []Expr,
};

pub const Param = struct {
    type: TypeKind,
    name: []const u8,
};

pub const Stmt = union(enum) {
    var_decl: struct {
        type: TypeKind,
        array_size: ?usize,
        name: []const u8,
        init: ?VarInit,
    },

    assignment: struct {
        name: []const u8,
        index: ?*Expr,
        op: TokenTag,
        value: *Expr,
    },

    func_decl: struct {
        return_type: TypeKind,
        name: []const u8,
        params: []Param,
        body: *Stmt,
    },

    if_stmt: struct {
        condition: *Expr,
        then_branch: *Stmt,
        else_branch: ?*Stmt,
    },

    while_stmt: struct {
        condition: *Expr,
        body: *Stmt,
    },

    return_stmt: ?*Expr,
    block: []Stmt,
    expr_stmt: *Expr,
    program: []Stmt,
};
