const std = @import("std");
const rem = @import("rem");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var file_buf = std.ArrayList(u8).init(allocator);
    defer file_buf.deinit();
    var decoded_buf = std.ArrayList(u21).init(allocator);
    defer decoded_buf.deinit();
    var token_buf = std.ArrayList(rem.token.Token).init(allocator);
    defer {
        for (token_buf.items) |*t| t.deinit(allocator);
        token_buf.deinit();
    }
    var total_ns: u64 = 0;

    var files_dir = try std.fs.cwd().openDir("files", .{ .iterate = true });
    defer files_dir.close();
    var files_dir_it = files_dir.iterateAssumeFirstIteration();
    while (try files_dir_it.next()) |entry| {
        file_buf.clearRetainingCapacity();
        decoded_buf.clearRetainingCapacity();
        for (token_buf.items) |*t| t.deinit(allocator);
        token_buf.clearRetainingCapacity();

        var file = try files_dir.openFile(entry.name, .{});
        defer file.close();
        const file_reader = file.reader();
        try file_reader.readAllArrayList(&file_buf, std.math.maxInt(usize));

        var it = (try std.unicode.Utf8View.init(file_buf.items)).iterator();
        while (it.nextCodepoint()) |cp| {
            try decoded_buf.append(cp);
        }

        var parser = try rem.Parser.initTokenizerOnly(decoded_buf.items, allocator, .report, .Data, null);
        defer parser.deinitTokenizerOnly();

        var timer = try std.time.Timer.start();
        try parser.runTokenizerOnly(&token_buf);
        const time_ns = timer.read();
        total_ns += time_ns;

        std.debug.print("{s}: {} tokens, {} errors in {}\n", .{
            entry.name,
            token_buf.items.len,
            parser.errors().len,
            std.fmt.fmtDuration(time_ns),
        });
    }

    std.debug.print("Took {} total\n", .{std.fmt.fmtDuration(total_ns)});
}
