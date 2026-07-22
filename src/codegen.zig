const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const TokenTag = lexer.TokenTag;
const TypeKind = lexer.TypeKind;

pub const CodeGen = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),
    indentation: usize,
    pub fn init(allocator: std.mem.Allocator) CodeGen {
        return .{
            .allocator = allocator,
            .output = .empty(),
            .indentation = 0,
        };
    }
    //pub fn generate(self: *CodeGen, progam: *ast.Stmt) []const u8 {

    //  }
    fn write(self: *CodeGen, bytes: []const u8) void {
        self.output.appendSlice(self.allocator, bytes);
    }
    fn writeFmt(self: *CodeGen, fmt: []const u8, args: anytype) void {
        const text = std.fmt.allocPrint(self.allocator, fmt, args);
        self.output.appendSlice(self.allocator, text);
    }
    fn writeIndent(self: *CodeGen) void {
        for (0..self.indentation) |_| {
            self.write("    ");
        }
    }
    fn addLevel(self: *CodeGen) void {
        self.indentation += 1;
    }
    fn removeLevel(self: *CodeGen) void {
        if (self.indentation > 0) {
            self.indentation -= 1;
        }
    }
};
