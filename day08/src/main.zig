const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const fmt = std.fmt;
const math = std.math;

const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;

const Position = Vector2(isize);
const Frequency = u8;

const empty_cell = '.';
const antinode = '#';

const Map = struct {
    width: usize,
    height: usize,
    map: ArrayList(u8),

    const Self = @This();

    pub fn init(allocator: Allocator, bytes: []const u8) !Self {
        var self: Self = undefined;

        self.map = ArrayList(u8).init(allocator);
        errdefer self.map.deinit();

        var lines = mem.tokenizeScalar(u8, bytes, '\n');
        self.width = lines.peek().?.len;
        self.height = 0;

        while (lines.next()) |line| {
            try self.map.appendSlice(line);
            self.height += 1;
        }

        return self;
    }

    pub fn initSized(allocator: Allocator, width: usize, height: usize) !Self {
        var self: Self = undefined;

        const size = width * height;

        self.map = try ArrayList(u8).initCapacity(allocator, size);
        self.map.appendNTimesAssumeCapacity(0, size);
        self.width = width;
        self.height = height;

        return self;
    }

    pub fn deinit(self: Self) void {
        self.map.deinit();
    }

    pub fn getCell(self: Self, position: Position) ?u8 {
        if (position.x < 0 or position.x >= self.width)
            return null;
        if (position.y < 0 or position.y >= self.height)
            return null;

        return self.getCellAssumeInBounds(position);
    }

    pub fn getCellAssumeInBounds(self: Self, position: Position) u8 {
        const x: usize = @intCast(position.x);
        const y: usize = @intCast(position.y);

        return self.map.items[self.width * y + x];
    }

    pub fn getCellPtr(self: *Self, position: Position) ?*u8 {
        if (position.x < 0 or position.x >= self.width)
            return null;
        if (position.y < 0 or position.y >= self.height)
            return null;

        const x: usize = @intCast(position.x);
        const y: usize = @intCast(position.y);

        return &self.map.items[self.width * y + x];
    }

    pub fn countMatchingCells(self: Self, value: u8) usize {
        var count: usize = 0;
        for (self.map.items) |cell| {
            if (cell == value)
                count += 1;
        }
        return count;
    }
};

const Antennas = struct {
    inner: AutoHashMap(Frequency, ArrayList(Position)),

    const Self = @This();

    pub fn init(allocator: Allocator, map: Map) !Self {
        var self: Self = undefined;

        self.inner = AutoHashMap(Frequency, ArrayList(Position)).init(allocator);

        for (0..map.height) |y| {
            for (0..map.width) |x| {
                const position = Position{ .x = @intCast(x), .y = @intCast(y) };
                const cell = map.getCellAssumeInBounds(position);

                if (cell == empty_cell)
                    continue;

                const entry = try self.inner.getOrPut(cell);

                if (!entry.found_existing) {
                    entry.value_ptr.* = ArrayList(Position).init(allocator);
                }

                try entry.value_ptr.append(position);
            }
        }

        return self;
    }

    pub fn deinit(self: *Self) void {
        var values = self.inner.valueIterator();
        while (values.next()) |value| {
            value.deinit();
        }
        self.inner.deinit();
    }
};

pub fn Vector2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        const Self = @This();

        pub fn add(self: Self, other: Self) Self {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn mul(self: Self, value: T) Self {
            return .{
                .x = self.x * value,
                .y = self.y * value,
            };
        }

        pub fn divExact(self: Self, value: T) Self {
            return .{
                .x = @divExact(self.x, value),
                .y = @divExact(self.y, value),
            };
        }

        pub fn eql(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }
    };
}

pub fn Pairs(comptime T: type) type {
    return struct {
        array: []const T,
        a_index: usize = 0,
        b_index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?struct { a: T, b: T } {
            if (self.b_index < self.array.len - 1) {
                self.b_index += 1;
            } else if (self.a_index < self.b_index - 1) {
                self.a_index += 1;
                self.b_index = self.a_index + 1;
            } else {
                return null;
            }

            return .{
                .a = self.array[self.a_index],
                .b = self.array[self.b_index],
            };
        }
    };
}

pub fn partOne(allocator: mem.Allocator, antennas: Antennas, map_width: usize, map_height: usize) !u64 {
    var antinodes = try Map.initSized(allocator, map_width, map_height);
    defer antinodes.deinit();

    var entries = antennas.inner.iterator();
    while (entries.next()) |entry| {
        var pairs = Pairs(Position){ .array = entry.value_ptr.items };

        while (pairs.next()) |pair| {
            const distance = pair.b.sub(pair.a);

            if (antinodes.getCellPtr(pair.b.add(distance))) |cell_ptr| {
                cell_ptr.* = antinode;
            }

            if (antinodes.getCellPtr(pair.a.sub(distance))) |cell_ptr| {
                cell_ptr.* = antinode;
            }
        }
    }

    return antinodes.countMatchingCells(antinode);
}

pub fn partTwo(allocator: mem.Allocator, antennas: Antennas, map_width: usize, map_height: usize) !u64 {
    var antinodes = try Map.initSized(allocator, map_width, map_height);
    defer antinodes.deinit();

    var entries = antennas.inner.iterator();
    while (entries.next()) |entry| {
        var pairs = Pairs(Position){ .array = entry.value_ptr.items };

        while (pairs.next()) |pair| {
            var distance = pair.b.sub(pair.a);

            if (distance.x != 0 and distance.y != 0) {
                if (@rem(@max(distance.x, distance.y), @min(distance.x, distance.y)) == 0) {
                    distance = distance.divExact(@min(distance.x, distance.y));
                }
            }

            var n: isize = 0;
            while (antinodes.getCellPtr(pair.b.add(distance.mul(n)))) |cell_ptr| : (n += 1) {
                cell_ptr.* = antinode;
            }

            n = 1;
            while (antinodes.getCellPtr(pair.b.sub(distance.mul(n)))) |cell_ptr| : (n += 1) {
                cell_ptr.* = antinode;
            }
        }
    }

    return antinodes.countMatchingCells(antinode);
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

    var map = try Map.init(allocator, bytes);
    defer map.deinit();

    var antennas = try Antennas.init(allocator, map);
    defer antennas.deinit();

    try stdout.print("{d}\n", .{try partOne(allocator, antennas, map.width, map.height)});
    try stdout.print("{d}\n", .{try partTwo(allocator, antennas, map.width, map.height)});

    try bw.flush();
}
