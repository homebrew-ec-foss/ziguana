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
    c_file: bool = false,
    print_checks: bool = false,
};
pub fn parseArgs(init: std.process.Init) !Arguments {
    const banner =
        \\_________ ___
        \\\$$$$$$$$\\$$\                                                
        \\ \____$$  |\__|                                                
        \\     $$  / $$\ $$$$$$\  $$\   $$\ $$$$$$\  $$$$$$$\   $$$$$$\  
        \\    $$  /  $$ |$$  __$$\ $$ |  $$ | \____$$\ $$  __$$\ \____$$\ 
        \\   $$  /   $$ |$$ /  $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ | $$$$$$$ |
        \\  $$  /    $$ |$$ |  $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$  __$$ |
        \\ $$$$$$$$\ $$ |\$$$$$$$ |\$$$$$$  |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |
        \\ \________|\__| \____$$ | \______/  \_______|\__|  \__| \_______|
        \\               $$\   $$ |                                      
        \\               \$$$$$$  |                                      
        \\                \______/                                       
        \\
        \\ Ziguana
        \\ 1) --version  : Shows ziguana Version
        \\ 2) --help     : Shows the available flags
        \\ 1) --tokens   : Prints lexed tokens from the source file
        \\ 2) --astprint : Print abstract syntax tree parsed from source file 
        \\ 3) --check    : Prints Syntax errors from the source file
        \\ 4) --emit-c   : Emit generated C source
        \\ 5) -o         : Generate output file
    ;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var arguments = Arguments{};
    var pathSet = false;
    var i: usize = 1;
    while (i < args.len) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help")) {
            print("{s}\n", .{banner});
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
        } else if (std.mem.eql(u8, arg, "--check")) { //cn be changed later
            arguments.print_checks = true;
        }
        i += 1;
    }
    if (!pathSet and !arguments.ask_help and !arguments.ask_version) {
        return error.pathNotProvided;
    }
    return arguments;
}
