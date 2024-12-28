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

const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;
const Vector2d = aoc.Vector2(f64);

const Machine = struct {
    a: Vector2d,
    b: Vector2d,
    prize: Vector2d,

    const Self = @This();

    pub fn cost(self: Self) ?u64 {
        // System of equations by elimination
        const a_equation = Vector2d{ .x = self.a.x, .y = self.b.x };
        var a_value = self.prize.x;

        const b_equation = Vector2d{ .x = self.a.y, .y = self.b.y };
        var b_value = self.prize.y;

        const a_multiplied = a_equation.mul(b_equation.x);
        a_value *= b_equation.x;
        const b_multiplied = b_equation.mul(a_equation.x);
        b_value *= a_equation.x;

        debug.assert(a_multiplied.x == b_multiplied.x);

        const y = if (a_value > b_value)
            (a_value - b_value) / a_multiplied.sub(b_multiplied).y
        else
            (b_value - a_value) / b_multiplied.sub(a_multiplied).y;

        const x = (self.prize.x - a_equation.y * y) / a_equation.x;

        const a_button_scalar = 3;

        if (@floor(x) == x and @floor(y) == y) {
            return @as(u64, @intFromFloat(x)) * a_button_scalar + @as(u64, @intFromFloat(y));
        }

        return null;
    }
};

const Expect = enum {
    skip_1,
    skip_2,
    a_offset_x,
    a_offset_y,
    skip_3,
    skip_4,
    b_offset_x,
    b_offset_y,
    skip_5,
    pos_x,
    pos_y,

    const Self = @This();

    pub fn next(self: Self) Self {
        return @enumFromInt((@intFromEnum(self) + 1) % comptime meta.fields(Self).len);
    }
};

fn parseInput(allocator: Allocator, bytes: []const u8) !ArrayList(Machine) {
    var machines = ArrayList(Machine).init(allocator);
    errdefer machines.deinit();

    var tokens = mem.tokenizeAny(u8, bytes, &ascii.whitespace);
    var expect = Expect.skip_1;

    var machine_current: Machine = undefined;

    while (tokens.next()) |token| : (expect = expect.next()) {
        switch (expect) {
            .skip_1, .skip_2, .skip_3, .skip_4, .skip_5 => continue,
            .a_offset_x => {
                debug.assert(mem.startsWith(u8, token, "X+"));
                machine_current.a.x = @floatFromInt(try fmt.parseUnsigned(u32, token[2 .. token.len - 1], 10));
            },
            .a_offset_y => {
                debug.assert(mem.startsWith(u8, token, "Y+"));
                machine_current.a.y = @floatFromInt(try fmt.parseUnsigned(u32, token[2..], 10));
            },
            .b_offset_x => {
                debug.assert(mem.startsWith(u8, token, "X+"));
                machine_current.b.x = @floatFromInt(try fmt.parseUnsigned(u32, token[2 .. token.len - 1], 10));
            },
            .b_offset_y => {
                debug.assert(mem.startsWith(u8, token, "Y+"));
                machine_current.b.y = @floatFromInt(try fmt.parseUnsigned(u32, token[2..], 10));
            },
            .pos_x => {
                debug.assert(mem.startsWith(u8, token, "X="));
                machine_current.prize.x = @floatFromInt(try fmt.parseUnsigned(u32, token[2 .. token.len - 1], 10));
            },
            .pos_y => {
                debug.assert(mem.startsWith(u8, token, "Y="));
                machine_current.prize.y = @floatFromInt(try fmt.parseUnsigned(u32, token[2..], 10));
                try machines.append(machine_current);
            },
        }
    }

    return machines;
}

fn partOne(machines: ArrayList(Machine)) u64 {
    var sum: u64 = 0;

    for (machines.items) |machine| {
        if (machine.cost()) |cost| {
            sum += @intCast(cost);
        }
    }

    return sum;
}

fn partTwo(machines: ArrayList(Machine)) u64 {
    var sum: u64 = 0;

    for (machines.items) |machine| {
        var machine_adjusted = machine;
        machine_adjusted.prize = machine_adjusted.prize.addValue(10000000000000);

        if (machine_adjusted.cost()) |cost| {
            sum += @intCast(cost);
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

    const machines = try parseInput(allocator, bytes);
    defer machines.deinit();

    try stdout.print("{}\n", .{partOne(machines)});
    try stdout.print("{}\n", .{partTwo(machines)});

    try bw.flush();
}
