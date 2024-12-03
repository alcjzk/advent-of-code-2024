const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const fmt = std.fmt;

fn parseMultiplyResult(input: []u8, start: *usize) ?usize {
    const lhs_start = start.* + 4;
    const lhs_end = mem.indexOfPos(u8, input, lhs_start, ",") orelse return null;
    const lhs = fmt.parseUnsigned(usize, input[lhs_start..lhs_end], 10) catch return null;

    const rhs_start = lhs_end + 1;
    const rhs_end = mem.indexOfPos(u8, input, rhs_start, ")") orelse return null;
    const rhs = fmt.parseUnsigned(usize, input[rhs_start..rhs_end], 10) catch return null;

    start.* = rhs_end + 1;

    return lhs * rhs;
}

fn partOne(input: []u8) usize {
    var start: usize = 0;
    var result: usize = 0;

    while (true) {
        start = mem.indexOfPos(u8, input, start, "mul(") orelse break;

        if (parseMultiplyResult(input, &start)) |value| {
            result += value;
        } else {
            start += 1;
        }
    }
    return result;
}

fn partTwo(input: []u8) usize {
    var start: usize = 0;
    var skip = false;
    var result: usize = 0;

    while (true) {
        start = mem.indexOfAnyPos(u8, input, start, "md") orelse break;

        if (mem.startsWith(u8, input[start..], "do()")) {
            skip = false;
            start += 4;
            continue;
        }
        if (mem.startsWith(u8, input[start..], "don't()")) {
            skip = true;
            start += 7;
            continue;
        }
        if (mem.startsWith(u8, input[start..], "mul(")) {
            if (parseMultiplyResult(input, &start)) |value| {
                if (!skip) {
                    result += value;
                }
                continue;
            }
        }
        start += 1;
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

    try stdout.print("{d}\n", .{partOne(bytes)});
    try stdout.print("{d}\n", .{partTwo(bytes)});

    try bw.flush();
}
