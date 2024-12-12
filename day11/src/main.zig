const std = @import("std");
const aoc = @import("aoc");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const fmt = std.fmt;
const ascii = std.ascii;
const math = std.math;

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = mem.Allocator;

const Stone = u64;
const BlinkRecursiveCache = AutoHashMap(BlinkRecursiveCacheKey, u64);

const BlinkRecursiveCacheKey = struct {
    stones: BlinkResult,
    max_depth: u8,
};

const BlinkResultType = enum {
    single,
    pair,
};

const BlinkResult = union(BlinkResultType) {
    single: Stone,
    pair: [2]Stone,
};

pub fn blink(stone: Stone) BlinkResult {
    if (stone == 0) {
        return .{ .single = 1 };
    }

    const digit_count = aoc.countDigits(stone);

    if (digit_count % 2 == 0) {
        const scalar = math.pow(u64, 10, digit_count / 2);

        const first: Stone = stone / scalar;
        const second: Stone = stone - (stone / scalar) * scalar;

        return .{ .pair = .{ first, second } };
    }

    return .{ .single = stone * 2024 };
}

pub fn blinkRecursive(stones: BlinkResult, max_depth: u8) u64 {
    if (max_depth == 0) {
        if (stones == .single) {
            return 1;
        }
        return 2;
    }

    switch (stones) {
        .single => |single| return blinkRecursive(blink(single), max_depth - 1),
        .pair => |pair| return blinkRecursive(blink(pair[0]), max_depth - 1) +
            blinkRecursive(blink(pair[1]), max_depth - 1),
    }
}

pub fn blinkRecursiveCached(stones: BlinkResult, max_depth: u8, cache: *BlinkRecursiveCache) !u64 {
    if (max_depth == 0) {
        if (stones == .single) {
            return 1;
        }
        return 2;
    }

    const cache_key = BlinkRecursiveCacheKey{
        .stones = stones,
        .max_depth = max_depth,
    };

    if (cache.get(cache_key)) |cached_result| {
        return cached_result;
    }

    const result = switch (stones) {
        .single => |single| try blinkRecursiveCached(blink(single), max_depth - 1, cache),
        .pair => |pair| try blinkRecursiveCached(blink(pair[0]), max_depth - 1, cache) +
            try blinkRecursiveCached(blink(pair[1]), max_depth - 1, cache),
    };

    try cache.put(cache_key, result);

    return result;
}

pub fn partOne(stones: []const Stone) u64 {
    var result: u64 = 0;

    for (stones) |stone| {
        result += blinkRecursive(.{ .single = stone }, 25);
    }
    return result;
}

pub fn partTwo(allocator: Allocator, stones: []const Stone) !u64 {
    var result: u64 = 0;

    var cache = BlinkRecursiveCache.init(allocator);
    defer cache.deinit();

    for (stones) |stone| {
        result += try blinkRecursiveCached(.{ .single = stone }, 75, &cache);
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

    var stones = ArrayList(Stone).init(allocator);
    defer stones.deinit();

    var tokens = mem.tokenizeAny(u8, bytes, &ascii.whitespace);
    while (tokens.next()) |token| {
        try stones.append(try fmt.parseUnsigned(Stone, token, 10));
    }

    try stdout.print("{}\n", .{partOne(stones.items)});
    try stdout.print("{}\n", .{try partTwo(allocator, stones.items)});

    try bw.flush();
}
