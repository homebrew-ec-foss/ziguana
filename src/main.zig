const std = @import("std");
const lexerMod = @import("lexer.zig");
const fetcher = @import("fetcher.zig");
const parser = @import("parser.zig");
const cli = @import("cli.zig");
const astprinter = @import("astprinter.zig");
const codegen = @import("codegen.zig");
pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const args = try cli.parseArgs(init);
    if (args.ask_help or args.ask_version) {
        return;
    }
    const source = try fetcher.readSource(io, arena, args.path);
    var lexer = lexerMod.Lexer.init(source);
    const tokens = try lexer.lex(arena);

    if (args.token_print) {
        for (tokens.items) |token| {
            std.debug.print("{}\n", .{token});
        }
    }
    var p = parser.Parser.init(arena, tokens.items);
    const program = try p.parse();
    if (args.ast_print) {
        var printer = astprinter.Printer.init();
        try printer.printAst(program);
    }
    const c_file = if (args.emit_c)
        args.output_c
    else
        "ziguana_temp.c";
    var gen = codegen.CodeGen.init(arena);
    defer gen.deinit();
    const c_source = try gen.generate(program);
    var file = try std.Io.Dir.cwd().createFile(io, c_file, .{
        .truncate = true,
    });
    defer file.close(io);
    var buffer: [4096]u8 = undefined;
    var writer = file.writer(io, &buffer);
    try writer.interface.writeAll(c_source);
    try writer.interface.flush();
    if (!args.emit_c) {
        const result = try std.process.run(arena, io, .{
            .argv = &.{
                "gcc",
                c_file,
                "-o",
                args.executable,
            },
        });
        switch (result.term) {
            .exited => |code| {
                if (code != 0) {
                    return error.CompilationFailed;
                }
            },
            else => return error.CompilationFailed,
        }
    }
}
