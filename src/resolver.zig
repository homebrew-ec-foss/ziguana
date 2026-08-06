const std = @import("std");
const fetcher = @import("fetcher");
const lexerMod = @import("lexer");
const parser = @import("parser");
const ast = @import("ast");

pub const LoadedFile = struct {
    path: []const u8,
    program: *ast.Stmt, //files own .program
};
const ResolveState = struct {
    io: std.Io,
    allocator: std.mem.Allocator,
    loaded: std.ArrayList(LoadedFile),
    visited: std.StringHashMap(void), // every path loaded anywhere in the graph — dedup
    stack: std.StringHashMap(void), // ancestors on the *current* chain — cycle check
};
fn loadFile(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !*ast.Stmt {
    const source = try fetcher.readSource(io, allocator, path);
    var lex = lexerMod.Lexer.init(source);
    const tokens = try lex.lex(allocator);
    var p = parser.Parser.init(allocator, tokens.items);
    return p.parse() catch |err| {
        for (p.errors.items) |e| {
            std.debug.print("{s}:{d}:{d}: error: {s}\n", .{ path, e.token.line, e.token.column, e.message });
        }
        if (p.errors.items.len == 0) {
            std.debug.print("{s}: error: parsing failed ({s})\n", .{ path, @errorName(err) });
        }
        return err;
    };
}
// needed so say f1.zg -> f2.zg -> f3.zg
fn resolveFile(state: *ResolveState, path: []const u8) !void {
    if (state.stack.contains(path)) {
        std.debug.print("error: import cycle detected at {s}\n", .{path});
        return error.ImportCycle;
    }
    if (state.visited.contains(path)) return;

    try state.stack.put(path, {});
    try state.visited.put(path, {});

    const program = try loadFile(state.io, state.allocator, path);
    const dir = std.fs.path.dirname(path) orelse ".";

    std.debug.assert(program.* == .program);
    for (program.program) |stmt| {
        if (stmt.* != .import_decl) continue;
        const import_path = try std.fs.path.join(state.allocator, &.{ dir, stmt.import_decl.path });
        try resolveFile(state, import_path);
    }

    try state.loaded.append(state.allocator, .{ .path = path, .program = program });
    _ = state.stack.remove(path);
}
pub fn merge(allocator: std.mem.Allocator, files: []const LoadedFile) !*ast.Stmt {
    var merged = std.ArrayList(*ast.Stmt).empty;

    for (files) |file| {
        std.debug.assert(file.program.* == .program);
        for (file.program.program) |stmt| {
            if (stmt.* == .import_decl) continue;
            try merged.append(allocator, stmt);
        }
    }
    return try ast.makeProgram(allocator, try merged.toOwnedSlice(allocator));
}
pub fn resolve(io: std.Io, allocator: std.mem.Allocator, entry_path: []const u8) ![]LoadedFile {
    var state = ResolveState{
        .io = io,
        .allocator = allocator,
        .loaded = std.ArrayList(LoadedFile).empty,
        .visited = std.StringHashMap(void).init(allocator),
        .stack = std.StringHashMap(void).init(allocator),
    };
    try resolveFile(&state, entry_path);
    return try state.loaded.toOwnedSlice(allocator);
}
