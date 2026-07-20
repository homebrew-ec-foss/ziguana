const std = @import("std");
const print = std.debug.print;
const Arguments = struct {
    path: []const u8 = "",
    token_print: bool = false,
    ast_print: bool = false,
    output_file: bool = false,
    ask_help: bool = false,
    ask_version: bool = false,
    c_file: bool = false,
};

pub fn parseArgs(init: std.process.Init) !Arguments {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var arguments = Arguments{};

    if (args.len < 2) {
        return error.TooFewArguments;
    }

    if (std.mem.eql(u8, args[1], "--help")) {
        arguments.ask_help = true;
        print("Ziguana\n1) --astprint : Print abstract syntax tree parsed from source file\n2) --tokens : Prints lexed tokens from the source file\n3) --version : Shows ziguana version\n", .{});
        return arguments;
    }
    if (std.mem.eql(u8, args[1], "--version")) {
        arguments.ask_version = true;
        print("Version : 0.0.0", .{});
        return arguments;
    }
    arguments.path = args[1];
    for (args[2..]) |arg| {
        if (std.mem.eql(u8, arg, "--astprint")) {
            arguments.ast_print = true;
        } else if (std.mem.eql(u8, arg, "--tokens")) {
            arguments.token_print = true;
        } else {
            return error.InvalidArguments;
        }
    }
    print("\n", .{});

    return arguments;
}
