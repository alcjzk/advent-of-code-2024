const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const ascii = std.ascii;
const fmt = std.fmt;

const ArrayList = std.ArrayList;

fn parseNumber(tokens: *mem.SplitIterator(u8, .any)) !usize {
    var token = tokens.next() orelse return error.MissingToken;
    
    while (mem.eql(u8, token, "")) {
        token = tokens.next() orelse return error.MissingToken;
    }

    return fmt.parseUnsigned(usize, token, 10);
}

const Input = struct {
    left: ArrayList(usize),
    right: ArrayList(usize),

    pub fn init(allocator: mem.Allocator, bytes: []u8) !Input {
        var self: Input = undefined;
        
        self.left = ArrayList(usize).init(allocator);
        self.right = ArrayList(usize).init(allocator);

        errdefer self.left.deinit();
        errdefer self.right.deinit();

        var lines = mem.splitScalar(u8, bytes, '\n');

        while (lines.next()) |line| {
            if (mem.eql(u8, line, ""))
                continue;

            var tokens = mem.splitAny(u8, line, &ascii.whitespace);

            try self.left.append(try parseNumber(&tokens));
            try self.right.append(try parseNumber(&tokens));
        }

        return self;
    }

    pub fn deinit(self: Input) void {
        self.left.deinit();
        self.right.deinit();
    }
};

fn partOne(input: Input) usize {
    mem.sort(usize, input.left.items, {}, comptime std.sort.asc(usize));
    mem.sort(usize, input.right.items, {}, comptime std.sort.asc(usize));

    var total_distance: usize = 0;

    for (input.left.items, input.right.items) |a, b| {
        total_distance += @max(a, b) - @min(a, b);
    }

    return total_distance;
}

fn partTwo(input: Input) usize {
    var score: usize = 0;

    for (input.left.items) |left| {
        var count: usize = 0;

        for (input.right.items) |right| {
            if (left == right)
                count += 1;
        }

        score += left * count;
    }

    return score;
}

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gp_allocator = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gp_allocator.deinit();
    const allocator = gp_allocator.allocator();

    var args = process.args();
    _ = args.skip();
    
    const input_path = args.next() orelse {
        debug.print("Provide path to input file", .{});
        return;
    };

    const cwd = fs.cwd();
    const bytes = try cwd.readFileAlloc(allocator, input_path, 1024 * 1024);
    defer allocator.free(bytes);

    const input = try Input.init(allocator, bytes);
    defer input.deinit();

    try stdout.print("{d}\n", .{partOne(input)});
    try stdout.print("{d}\n", .{partTwo(input)});

    try bw.flush();
}
