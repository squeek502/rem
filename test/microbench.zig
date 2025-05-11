const std = @import("std");
const rem = @import("rem");

const input = @embedFile("named-char-test.html");
const decoded_input = blk: {
    @setEvalBranchQuota(input.len * 10);
    var decoded: [input.len]u21 = undefined;
    for (input, 0..) |c, i| {
        decoded[i] = c;
    }
    break :blk decoded;
};

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const allocator = arena_state.allocator();

    var token_buf = std.ArrayList(rem.token.Token).init(allocator);

    var parser = try rem.Parser.initTokenizerOnly(&decoded_input, allocator, .report, .Data, null);
    defer parser.deinitTokenizerOnly();

    try parser.runTokenizerOnly(&token_buf);
}
