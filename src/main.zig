const std = @import("std");
const lexerMod = @import("lexer.zig");
const fetcher = @import("fetcher.zig");
const parser = @import("parser.zig");
const cli = @import("cli.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const args = try cli.parseArgs(init);
    if (args.ask_help or args.ask_version) {
        return;
    }
    const source = try fetcher.readSource(io, init.gpa, args.path);
    var lexer = lexerMod.Lexer.init(source);
    var tokens = try lexer.lex(init.gpa);

    if (args.token_print) {
        // print tokens
    }
    var p = parser.Parser.init(init.gpa, tokens.items);
    const program = try p.parse();
    _ = program;
    if (args.ast_print) {
        // ast printer
    }
    defer init.gpa.free(source);
    defer tokens.deinit(init.gpa);
}
