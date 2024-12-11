const std = @import("std");
const aoc = @import("aoc");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;

const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;
const Map = aoc.Map2D(u8);
const Position = aoc.Vector2(isize);

pub fn fullTrailCount(map: Map, position: Position, trail_ends: *ArrayList(Position)) !u64 {
    const current_cell = map.getCellAssumeInBounds(position);

    if (current_cell == '9') {
        for (trail_ends.items) |trail_end| {
            if (trail_end.eql(position)) {
                return 0;
            }
        }
        try trail_ends.append(position);
        return 1;
    }

    const directions: [4]Position = .{ Position.left, Position.right, Position.up, Position.down };

    var result: u64 = 0;

    for (directions) |direction| {
        const next_position = position.add(direction);
        if (map.getCell(next_position)) |cell| {
            if (cell == current_cell + 1) {
                result += try fullTrailCount(map, next_position, trail_ends);
            }
        }
    }

    return result;
}

pub fn fullTrailCount2(map: Map, position: Position) u64 {
    const current_cell = map.getCellAssumeInBounds(position);

    if (current_cell == '9') {
        return 1;
    }

    const directions: [4]Position = .{ Position.left, Position.right, Position.up, Position.down };

    var result: u64 = 0;

    for (directions) |direction| {
        const next_position = position.add(direction);
        if (map.getCell(next_position)) |cell| {
            if (cell == current_cell + 1) {
                result += fullTrailCount2(map, next_position);
            }
        }
    }

    return result;
}

pub fn partOne(allocator: Allocator, map: Map) !u64 {
    var result: u64 = 0;

    for (0..map.height) |y| {
        for (0..map.width) |x| {
            const position = Position{ .x = @intCast(x), .y = @intCast(y) };

            if (map.getCellAssumeInBounds(position) != '0') {
                continue;
            }

            var trail_ends = ArrayList(Position).init(allocator);
            defer trail_ends.deinit();

            const score = try fullTrailCount(map, position, &trail_ends);
            result += score;
        }
    }

    return result;
}

pub fn partTwo(map: Map) u64 {
    var result: u64 = 0;

    for (0..map.height) |y| {
        for (0..map.width) |x| {
            const position = Position{ .x = @intCast(x), .y = @intCast(y) };

            if (map.getCellAssumeInBounds(position) != '0') {
                continue;
            }

            const score = fullTrailCount2(map, position);
            result += score;
        }
    }

    return result;
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

    const map = try Map.initBytes(allocator, bytes);
    defer map.deinit();

    try stdout.print("{}\n", .{try partOne(allocator, map)});
    try stdout.print("{}\n", .{partTwo(map)});

    try bw.flush();
}
