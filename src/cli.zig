const std = @import("std");
const print = std.debug.print;
pub const Arguments = struct {
    path: []const u8 = "",
    token_print: bool = false,
    ast_print: bool = false,
    ask_help: bool = false,
    ask_version: bool = false,
    emit_c: bool = false,
    output_c: []const u8 = "",
    executable: []const u8 = "",
};
pub fn parseArgs(init: std.process.Init) !Arguments {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var arguments = Arguments{};
    var pathSet = false;
    var i: usize = 1;
    while (i < args.len) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help")) {
            print("Ziguana\n1) --astprint : Print abstract syntax tree parsed from source file\n2) --tokens : Prints lexed tokens from the source file\n3) --version : Shows ziguana version\n4) --emit-c <file> : Emit generated C source\n5) -o <file> : Output executable name\n", .{});
            arguments.ask_help = true;
        } else if (std.mem.eql(u8, arg, "--astprint")) {
            arguments.ast_print = true;
        } else if (std.mem.eql(u8, arg, "--tokens")) {
            arguments.token_print = true;
        } else if (std.mem.eql(u8, arg, "--version")) {
            print("Version : 0.0.0\n", .{});
            arguments.ask_version = true;
        } else if (std.mem.eql(u8, arg, "--emit-c")) {
            i += 1;
            if (i >= args.len) {
                return error.ExpectedCOutputFilename;
            }
            arguments.emit_c = true;
            arguments.output_c = args[i];
        } else if (std.mem.eql(u8, arg, "-o")) {
            i += 1;
            if (i >= args.len) {
                return error.ExpectedExecutableFilename;
            }
            arguments.executable = args[i];
        } else if (!pathSet) {
            arguments.path = arg;
            pathSet = true;
        } else {
            return error.UnknownArgument;
        }
        i += 1;
    }
    if (!pathSet and !arguments.ask_help and !arguments.ask_version) {
        return error.pathNotProvided;
    }
    return arguments;
}
