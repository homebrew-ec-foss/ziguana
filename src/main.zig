const std = @import("std");
const lexerMod = @import("lexer");
const fetcher = @import("fetcher");
const parser = @import("parser");
const cli = @import("cli");
const astprinter = @import("astprinter");
const codegen = @import("codegen");
const checker_mod = @import("checker");
fn printToken(tok: lexerMod.Token) void {
    switch (tok.payload) {
        .identifier => |s| std.debug.print("{d}:{d} identifier(\"{s}\")\n", .{ tok.line, tok.column, s }),
        .string => |s| std.debug.print("{d}:{d} string(\"{s}\")\n", .{ tok.line, tok.column, s }),
        .number => |n| std.debug.print("{d}:{d} number({d})\n", .{ tok.line, tok.column, n }),
        .type_ => |t| std.debug.print("{d}:{d} type({s})\n", .{ tok.line, tok.column, @tagName(t) }),
        else => std.debug.print("{d}:{d} {s}\n", .{ tok.line, tok.column, @tagName(std.meta.activeTag(tok.payload)) }),
    }
}

fn lessThanErr(_: void, a: checker_mod.CheckErr, b: checker_mod.CheckErr) bool {
    if (a.line != b.line) return a.line < b.line;
    return a.column < b.column;
}
fn printCaret(source: []const u8, line: usize, column: usize) void {
    var line_iter = std.mem.splitScalar(u8, source, '\n');
    var current_line: usize = 1;
    var line_content: []const u8 = "";
    var found = false;

    while (line_iter.next()) |l| {
        if (current_line == line) {
            line_content = l;
            found = true;
            break;
        }
        current_line += 1;
    }
    if (!found) return; // line out of range, nothing to show

    // "  12 | " style prefix
    var buf: [32]u8 = undefined;
    const prefix = std.fmt.bufPrint(&buf, "{d} | ", .{line}) catch return;

    std.debug.print("{s}{s}\n", .{ prefix, line_content });

    // pad to the column, then place the caret
    var i: usize = 0;
    while (i < prefix.len) : (i += 1) std.debug.print(" ", .{});
    i = 1;
    while (i < column and i - 1 < line_content.len) : (i += 1) {
        const c = line_content[i - 1];
        if (c == '\t') {
            std.debug.print("\t", .{});
        } else {
            std.debug.print(" ", .{});
        }
    }
    std.debug.print("^\n", .{});
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    const args = try cli.parseArgs(init);
    if (args.ask_help or args.ask_version) {
        return;
    }

    const source = try fetcher.readSource(io, arena, args.path);

    var lex = lexerMod.Lexer.init(source);
    const tokens = try lex.lex(arena);

    if (args.token_print) {
        for (tokens.items) |tok| {
            printToken(tok);
        }
    }

    var p = parser.Parser.init(arena, tokens.items);
    const program = p.parse() catch |err| {
        if (p.errors.items.len > 0) {
            for (p.errors.items) |e| {
                std.debug.print("error: {s}\n", .{e.message});
            }
        } else {
            std.debug.print("error: parsing failed ({s})\n", .{@errorName(err)});
        }
        std.process.exit(1);
    };

    if (args.ast_print) {
        var printer = astprinter.Printer.init();
        try printer.printAst(program);
    }

    var checker = checker_mod.Checker.init(arena);
    try checker.check(program);
    if (args.print_checks) {
        if (checker.errors.items.len > 0) {
            std.mem.sort(checker_mod.CheckErr, checker.errors.items, {}, lessThanErr);
            for (checker.errors.items) |err| {
                std.debug.print("error: {s}\n", .{err.message});
                printCaret(source, err.line, err.column);
            }
            std.process.exit(1);
        } else {
            std.debug.print("No Errors \n", .{});
        }
    }

    if (checker.errors.items.len > 0) {
        std.mem.sort(checker_mod.CheckErr, checker.errors.items, {}, lessThanErr);
        for (checker.errors.items) |err| {
            std.debug.print("error: {s}\n", .{err.message});
            printCaret(source, err.line, err.column);
        }
        std.process.exit(1);
    } else {
        std.debug.print("No Errors \n", .{});
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
        const output_name = if (args.executable.len == 0) "a.out" else args.executable;
        const result = try std.process.run(arena, io, .{
            .argv = &.{
                "gcc",
                "-std=c23",
                c_file,
                "-o",
                output_name,
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
