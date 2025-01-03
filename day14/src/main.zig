const std = @import("std");
const aoc = @import("aoc");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const meta = std.meta;
const ascii = std.ascii;
const fmt = std.fmt;
const math = std.math;

const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;
const Vector2i = aoc.Vector2(i64);
const Map = aoc.Map2D(u8);

const Robot = struct {
    position: Vector2i,
    velocity: Vector2i,
};

const map_width = 101;
const map_height = 103;

fn parseVector(bytes: []const u8) !Vector2i {
    var vector: Vector2i = undefined;
    var tokens = mem.tokenizeScalar(u8, bytes, ',');

    var token = tokens.next() orelse return error.InvalidVector;
    vector.x = try fmt.parseInt(i64, token, 10);

    token = tokens.next() orelse return error.InvalidVector;
    vector.y = try fmt.parseInt(i64, token, 10);

    return vector;
}

fn parseInput(allocator: Allocator, bytes: []const u8) !ArrayList(Robot) {
    var robots = ArrayList(Robot).init(allocator);
    errdefer robots.deinit();

    var tokens = mem.tokenizeAny(u8, bytes, &ascii.whitespace);

    while (true) {
        var robot: Robot = undefined;

        var token = tokens.next() orelse break;
        debug.assert(mem.startsWith(u8, token, "p="));
        robot.position = try parseVector(token[2..]);

        token = tokens.next().?;
        debug.assert(mem.startsWith(u8, token, "v="));
        robot.velocity = try parseVector(token[2..]);

        try robots.append(robot);
    }

    return robots;
}

fn partOne(allocator: Allocator, robots: ArrayList(Robot)) u64 {
    var sector_a_robot_count: u64 = 0;
    var sector_b_robot_count: u64 = 0;
    var sector_c_robot_count: u64 = 0;
    var sector_d_robot_count: u64 = 0;

    var map = Map.initSized(allocator, 101, 103) catch unreachable;
    defer map.deinit();

    var positions = ArrayList(Vector2i).init(allocator);
    defer positions.deinit();

    for (robots.items) |robot| {
        var position = robot.position.add(robot.velocity.mul(100));
        position.x = @mod(position.x, 101);
        position.y = @mod(position.y, 103);

        positions.append(position) catch continue;

        if (position.x == map_width / 2 or position.y == map_height / 2) {
            continue;
        }

        if (position.x < map_width / 2) {
            if (position.y < map_height / 2) {
                sector_a_robot_count += 1;
            } else {
                sector_b_robot_count += 1;
            }
        } else {
            if (position.y < map_height / 2) {
                sector_c_robot_count += 1;
            } else {
                sector_d_robot_count += 1;
            }
        }
    }

    return sector_a_robot_count * sector_b_robot_count * sector_c_robot_count * sector_d_robot_count;
}

fn partTwo(allocator: Allocator, robots: ArrayList(Robot)) !u64 {
    for (1..math.maxInt(i64)) |seconds| {
        var map = try Map.initSized(allocator, map_width, map_height);
        defer map.deinit();

        for (robots.items) |robot| {
            var position = robot.position.add(robot.velocity.mul(@intCast(seconds)));
            position.x = @mod(position.x, map_width);
            position.y = @mod(position.y, map_height);

            map.getCellPtrAssumeInBounds(.{ .x = position.x, .y = position.y }).* = 'X';
        }

        for (0..map.height) |y| {
            const row = map.inner.items[y * map.width .. (y + 1) * map.width];
            if (mem.indexOf(u8, row, "XXXXXXXXXXXXXXXXXXXXX") != null) {
                return seconds;
            }
        }
    }

    return error.NotFound;
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
        debug.print("Provide path to input file\n", .{});
        return;
    };

    const cwd = fs.cwd();
    const bytes = try cwd.readFileAlloc(allocator, input_path, 1024 * 1024);
    defer allocator.free(bytes);

    const robots = try parseInput(allocator, bytes);
    defer robots.deinit();

    try stdout.print("{}\n", .{partOne(allocator, robots)});
    try stdout.print("{}\n", .{try partTwo(allocator, robots)});

    try bw.flush();
}
