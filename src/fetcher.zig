const std = @import("std");

pub fn readSource(
    io: std.Io,
    allocator: std.mem.Allocator,
    path: []const u8,
) ![]const u8 {
    return try std.Io.Dir.cwd().readFileAlloc(
        io,
        path,
        allocator,
        .limited(10 * 1024 * 1024),
    );
}
