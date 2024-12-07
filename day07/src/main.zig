const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const fmt = std.fmt;
const math = std.math;

const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;

const CalibrationEquation = struct {
    test_value: usize,
    operands: ArrayList(u16),

    const Self = @This();

    pub fn init(allocator: Allocator, line: []const u8) !Self {
        var self: Self = undefined;

        self.operands = ArrayList(u16).init(allocator);
        errdefer self.operands.deinit();

        var tokens = mem.tokenizeAny(u8, line, ": ");
        debug.assert(tokens.peek() != null);

        self.test_value = try fmt.parseUnsigned(usize, tokens.next().?, 10);

        while (tokens.next()) |token| {
            const operand = try fmt.parseUnsigned(u16, token, 10);
            try self.operands.append(operand);
        }

        debug.assert(self.operands.items.len >= 2);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.operands.deinit();
    }
};

const Input = struct {
    equations: ArrayList(CalibrationEquation),

    const Self = @This();

    pub fn init(allocator: Allocator, bytes: []const u8) !Self {
        var self: Self = undefined;

        self.equations = ArrayList(CalibrationEquation).init(allocator);
        errdefer self.equations.deinit();

        var lines = mem.tokenizeScalar(u8, bytes, '\n');

        while (lines.next()) |line| {
            const equation = try CalibrationEquation.init(allocator, line);
            errdefer equation.deinit();

            try self.equations.append(equation);
        }

        return self;
    }

    pub fn deinit(self: Self) void {
        for (self.equations.items) |equation| {
            equation.deinit();
        }
        self.equations.deinit();
    }
};

pub fn partOne(input: Input) u64 {
    var sum: u64 = 0;
    for (input.equations.items) |equation| {
        const permutation_bits_end = @as(u16, 1) << @intCast(equation.operands.items.len);

        for (0..permutation_bits_end) |permutation_bits| {
            var result: u64 = equation.operands.items[0];

            for (0..equation.operands.items.len - 1) |index| {
                switch ((permutation_bits >> @intCast(index)) & 1) {
                    0 => result += equation.operands.items[index + 1],
                    else => result *= equation.operands.items[index + 1],
                }
            }

            if (result == equation.test_value) {
                sum += result;
                break;
            }
        }
    }
    return sum;
}

pub fn partTwo(input: Input) u64 {
    var sum: u64 = 0;

    for (input.equations.items) |equation| {
        const permutation_bits_end = @as(u32, 1) << @intCast(equation.operands.items.len * 2);

        outer: for (0..permutation_bits_end) |permutation_bits| {
            var result: u64 = equation.operands.items[0];
            for (0..equation.operands.items.len - 1) |index| {
                const rhs = equation.operands.items[index + 1];

                switch ((permutation_bits >> @intCast(index * 2)) & 0b11) {
                    0b00 => result += rhs,
                    0b01 => result *= rhs,
                    0b10 => {
                        const result_digits_count: u64 = @intFromFloat(@floor(@log10(@as(f32, @floatFromInt(rhs))) + 1));
                        result = result * math.pow(u64, 10, result_digits_count) + rhs;
                    },
                    else => continue :outer,
                }
            }

            if (result == equation.test_value) {
                sum += result;
                break;
            }
        }
    }
    return sum;
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

    try stdout.print("{d}\n", .{partOne(input)});
    try stdout.print("{d}\n", .{partTwo(input)});

    try bw.flush();
}
