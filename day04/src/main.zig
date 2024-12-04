const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const fmt = std.fmt;

const ArrayList = std.ArrayList;

const Input = struct {
    width: usize,
    height: usize,
    data: ArrayList(u8),

    pub fn init(allocator: mem.Allocator, bytes: []const u8) !Input {
        var lines = mem.tokenizeAny(u8, bytes, "\r\n");

        var data = ArrayList(u8).init(allocator);
        errdefer data.deinit();

        const first_line = lines.next() orelse return error.EmptyInput;
        try data.appendSlice(first_line);

        var line_count: usize = 1;

        while (lines.next()) |line| : (line_count += 1) {
            debug.assert(line.len == first_line.len);
            try data.appendSlice(line);
        }

        return .{ .width = first_line.len, .height = line_count, .data = data };
    }

    pub fn deinit(self: Input) void {
        self.data.deinit();
    }

    pub fn get(self: Input, position: Vector2) ?u8 {
        if (position.x < 0 or position.x >= @as(isize, @intCast(self.width)))
            return null;
        if (position.y < 0 or position.y >= @as(isize, @intCast(self.height)))
            return null;
        return self.data.items[@as(usize, @intCast(position.y)) * self.width + @as(usize, @intCast(position.x))];
    }
};

fn parseInput(allocator: mem.Allocator, bytes: []const u8) !Input {
    var lines = mem.tokenizeAny(u8, bytes, "\r\n");

    var data = ArrayList(u8).init(allocator);
    errdefer data.deinit();

    const first_line = lines.next() orelse return error.EmptyInput;
    try data.appendSlice(first_line);

    var line_count: usize = 1;

    while (lines.next()) |line| : (line_count += 1) {
        debug.assert(line.len == first_line.len);
        try data.appendSlice(line);
    }

    return .{ .width = first_line.len, .height = line_count, .data = data };
}

const Vector2 = struct {
    x: isize = 0,
    y: isize = 0,

    pub fn mul(self: Vector2, scalar: isize) Vector2 {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
        };
    }

    pub fn add(self: Vector2, other: Vector2) Vector2 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
};

const directions: [8]Vector2 = .{
    .{ .x = 0, .y = 1 },
    .{ .x = 1, .y = 1 },
    .{ .x = 1, .y = 0 },
    .{ .x = 1, .y = -1 },
    .{ .x = 0, .y = -1 },
    .{ .x = -1, .y = -1 },
    .{ .x = -1, .y = 0 },
    .{ .x = -1, .y = 1 },
};

const corner_tl: Vector2 = .{ .x = -1, .y = 1 };
const corner_tr: Vector2 = .{ .x = 1, .y = 1 };
const corner_bl: Vector2 = .{ .x = -1, .y = -1 };
const corner_br: Vector2 = .{ .x = 1, .y = -1 };

fn match(input: Input, direction: Vector2, start_position: Vector2) bool {
    debug.assert(input.get(start_position) == 'X');
    const haystack = "XMAS";

    for (1..haystack.len) |haystack_index| {
        const position = start_position.add(direction.mul(@intCast(haystack_index)));
        if (input.get(position)) |letter| {
            if (letter != haystack[haystack_index])
                return false;
        } else {
            return false;
        }
    }

    return true;
}

fn partOne(input: Input) usize {
    var match_count: usize = 0;

    for (0..input.height) |y| {
        for (0..input.width) |x| {
            const position: Vector2 = .{ .x = @intCast(x), .y = @intCast(y) };

            if (input.get(position)) |letter| {
                if (letter != 'X')
                    continue;
            } else {
                continue;
            }

            for (directions) |direction| {
                if (match(input, direction, position)) {
                    match_count += 1;
                }
            }
        }
    }

    return match_count;
}

fn getOpposite(letter: u8) ?u8 {
    const opposite: u8 = switch (letter) {
        'S' => 'M',
        'M' => 'S',
        else => return null,
    };
    return opposite;
}

fn match2(input: Input, start_position: Vector2) bool {
    if (input.get(start_position.add(corner_tl))) |letter| {
        const opposite_target = getOpposite(letter) orelse return false;

        if (input.get(start_position.add(corner_br))) |opposite| {
            if (opposite != opposite_target)
                return false;
        } else return false;
    } else return false;

    if (input.get(start_position.add(corner_tr))) |letter| {
        const opposite_target = getOpposite(letter) orelse return false;

        if (input.get(start_position.add(corner_bl))) |opposite| {
            if (opposite != opposite_target)
                return false;
        } else return false;
    } else return false;

    return true;
}

fn partTwo(input: Input) usize {
    var match_count: usize = 0;

    for (0..input.height) |y| {
        for (0..input.width) |x| {
            const position: Vector2 = .{ .x = @intCast(x), .y = @intCast(y) };

            if (input.get(position)) |letter| {
                if (letter != 'A')
                    continue;
            } else {
                continue;
            }

            if (match2(input, position)) {
                match_count += 1;
            }
        }
    }
    return match_count;
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
