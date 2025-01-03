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

const Cell = enum (u8) {
    robot = '@',
    box = 'O',
    wall = '#',
    empty = '.',
};

const Move = enum (u8) {
    up = '^',
    left = '<',
    down = 'v',
    right = '>',
};

const Input = struct {
    map: Map2D(Cell),
    moves: ArrayList(Move),

    const Self = @This();

    pub fn parse(bytes: []const u8) Self {
        let self: Self = undefined;

        var lines = mem.splitScalar(u8, bytes, '\n');

        while (lines.next()) |line| {
            if (mem.eql(u8, line, "")) {
                break;
            }


        }



    }
};

fn partOne() u64 {

    return 0;
}

fn partTwo() u64 {
    return 0;
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

    try stdout.print("{}\n", .{partOne()});
    //try stdout.print("{}\n", .{try partTwo(allocator, robots)});

    try bw.flush();
}
