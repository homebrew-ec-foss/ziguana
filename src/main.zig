const std = @import("std");
const lexerMod = @import("lexer.zig");
const fetcher = @import("fetcher.zig");
const parser = @import("parser.zig");
const cli = @import("cli.zig");
const astprinter = @import("astprinter.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try cli.parseArgs(init);
    if (args.ask_help or args.ask_version) {
        return;
    }
    const source = try fetcher.readSource(io, arena, args.path);
    var lexer = lexerMod.Lexer.init(source);
    const tokens = try lexer.lex(arena);

    if (args.token_print) {
        // print tokens
    }
    var p = parser.Parser.init(arena, tokens.items);
    const program = try p.parse();
    if (args.ast_print) {
        var printer = astprinter.Printer.init();
        try printer.printAst(program);
    }
}
