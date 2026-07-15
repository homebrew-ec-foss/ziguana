const std = @import("std");
const lexerMod = @import("lexer.zig");
const fetcher = @import("fetcher.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const path: []const u8 = ""; // handle this later

    const source = try fetcher.readSource(io, allocator, path);
    defer allocator.free(source);

    var lexer = lexerMod.Lexer.create(source);

    lexerMod.lex(&lexer);
}
