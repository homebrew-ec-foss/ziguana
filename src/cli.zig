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
        return error.pathNotProvided;
    }

    var errorFlag: u8 = 0;
    arguments.path = args[1];
    for (args[2..]) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            print("Ziguana\n1) --astprint : Print abstract syntax tree parsed from source file\n2) --tokens : Prints lexed tokens from the source file\n3) --version : Shows ziguana version", .{});
            arguments.ask_help = true;
            errorFlag = 1;
        }
        if (std.mem.eql(u8, arg, "--astprint")) {
            arguments.ast_print = true;
            errorFlag = 1;
        }
        if (std.mem.eql(u8, arg, "--tokens")) {
            arguments.token_print = true;
            errorFlag = 1;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            print("Version : 0.0.0", .{}); //hardcoded for now
            arguments.ask_version = true;
            errorFlag = 1;
        }
    }
    if (args.len > 2 and errorFlag == 0) {
        return error.InvalidArguments;
    }
    print("\n", .{});

    return arguments;
}
