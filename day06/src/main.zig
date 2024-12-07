const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const meta = std.meta;

const ArrayList = std.ArrayList;

const directions = [4]Vector2(isize){
    .{ .x = 0, .y = -1 },
    .{ .x = 1, .y = 0 },
    .{ .x = 0, .y = 1 },
    .{ .x = -1, .y = 0 },
};

const GuardUniquePositions = struct {
    input: *const Input,
    index: usize = 0,

    const Self = @This();

    pub fn next(self: *Self) ?Vector2(isize) {
        for (self.input.map.items[self.index..]) |cell| {
            self.index += 1;
            if (cell.isVisited()) {
                return self.input.indexToPosition(self.index - 1);
            }
        }
        return null;
    }
};

const Cell = packed struct {
    up: bool = false,
    right: bool = false,
    down: bool = false,
    left: bool = false,
    is_obstacle: bool,

    const Self = @This();

    pub fn isVisited(self: Self) bool {
        return (self.up or self.right or self.down or self.left);
    }

    pub fn isSetDirection(self: *Self, direction: Direction) bool {
        switch (direction) {
            .up => return self.up,
            .right => return self.right,
            .down => return self.down,
            .left => return self.left,
        }
    }

    pub fn setDirection(self: *Self, direction: Direction) void {
        switch (direction) {
            .up => self.up = true,
            .right => self.right = true,
            .down => self.down = true,
            .left => self.left = true,
        }
    }

    pub fn fromChar(char: u8) !Cell {
        return switch (char) {
            '#' => .{ .is_obstacle = true },
            '.' => .{ .is_obstacle = false },
            else => error.InvalidCell,
        };
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

        pub fn eql(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }
    };
}

const Direction = enum(u4) {
    up,
    right,
    down,
    left,

    pub fn next(self: Direction) Direction {
        return @enumFromInt((@intFromEnum(self) + 1) % comptime meta.tags(Direction).len);
    }
};

const Input = struct {
    width: usize,
    height: usize,
    map: ArrayList(Cell),
    guard_position: Vector2(isize),
    guard_direction: Direction,

    pub fn init(allocator: mem.Allocator, bytes: []const u8) !Input {
        var self: Input = undefined;

        var rows = std.mem.tokenizeScalar(u8, bytes, '\n');

        const first_row = rows.peek() orelse return error.EmptyInput;

        self.width = first_row.len;
        self.height = 0;
        self.guard_direction = Direction.up;

        self.map = ArrayList(Cell).init(allocator);
        errdefer self.map.deinit();

        var guard_set = false;

        while (rows.next()) |row| : (self.height += 1) {
            debug.assert(row.len == self.width);
            for (row, 0..) |char, x| {
                const cell = Cell.fromChar(char) catch blk: {
                    debug.assert(char == '^');
                    debug.assert(!guard_set);

                    self.guard_position = .{ .x = @intCast(x), .y = @intCast(self.height) };
                    guard_set = true;

                    break :blk Cell{ .is_obstacle = false };
                };

                try self.map.append(cell);
            }
        }

        return self;
    }

    pub fn deinit(self: Input) void {
        self.map.deinit();
    }

    pub fn positionAhead(self: Input) Vector2(isize) {
        return self.guard_position.add(directions[@intFromEnum(self.guard_direction)]);
    }

    pub fn getCell(self: *Input, position: Vector2(isize)) ?*Cell {
        if (position.x < 0 or position.x >= self.width)
            return null;
        if (position.y < 0 or position.y >= self.height)
            return null;

        return &self.map.items[self.width * @as(usize, @intCast(position.y)) + @as(usize, @intCast(position.x))];
    }

    pub fn turn(self: *Input) void {
        self.guard_direction = self.guard_direction.next();
    }

    pub fn clone(self: Input) !Input {
        var new = self;

        new.map = try new.map.clone();

        return new;
    }

    pub fn drawGuardRoute(self: *Input) !void {
        const start_cell = self.getCell(self.guard_position).?;
        start_cell.setDirection(self.guard_direction);

        while (self.getCell(self.positionAhead())) |cell| {
            if (cell.is_obstacle) {
                self.turn();
                continue;
            }

            if (cell.isSetDirection(self.guard_direction)) {
                return error.GuardWouldLoop;
            }

            cell.setDirection(self.guard_direction);
            self.guard_position = self.positionAhead();
        }
    }

    pub fn indexToPosition(self: Input, index: usize) Vector2(isize) {
        return .{
            .x = @intCast(index % self.width),
            .y = @intCast(index / self.width),
        };
    }

    pub fn guardUniquePositions(self: *const Input) GuardUniquePositions {
        return .{ .input = self };
    }
};

fn partOne(_input: Input) !u64 {
    var input = try _input.clone();
    defer input.deinit();

    try input.drawGuardRoute();

    var unique_positions = input.guardUniquePositions();
    var unique_positions_count: usize = 0;

    while (unique_positions.next()) |_| {
        unique_positions_count += 1;
    }

    return unique_positions_count;
}

fn partTwo(_input: Input) !u64 {
    var input = try _input.clone();
    defer input.deinit();

    try input.drawGuardRoute();

    var looping_positions: usize = 0;
    var unique_positions = input.guardUniquePositions();

    while (unique_positions.next()) |position| {
        if (position.eql(_input.guard_position))
            continue;

        var iteration = try _input.clone();
        defer iteration.deinit();

        iteration.getCell(position).?.is_obstacle = true;

        iteration.drawGuardRoute() catch {
            looping_positions += 1;
        };
    }

    return looping_positions;
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

    var input = try Input.init(allocator, bytes);
    defer input.deinit();

    try stdout.print("{d}\n", .{try partOne(input)});
    try stdout.print("{d}\n", .{try partTwo(input)});

    try bw.flush();
}
