const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const ascii = std.ascii;
const fmt = std.fmt;

const ArrayList = std.ArrayList;

const Input = struct {
    reports: ArrayList(ArrayList(usize)) = undefined,

    pub fn init(allocator: mem.Allocator, bytes: []u8) !Input {
        var self: Input = undefined;
        
        self.reports = ArrayList(ArrayList(usize)).init(allocator);
        errdefer self.reports.deinit();

        var lines = mem.splitScalar(u8, bytes, '\n');

        while (lines.next()) |line| {
            if (mem.eql(u8, line, ""))
                continue;

            var tokens = mem.tokenizeAny(u8, line, &ascii.whitespace);

            var report = ArrayList(usize).init(allocator);
            errdefer report.deinit();

            while (tokens.next()) |token| {
                const value = try fmt.parseUnsigned(usize, token, 10);
                try report.append(value);
            }

            try self.reports.append(report);
        }

        return self;
    }

    pub fn deinit(self: Input) void {
        for (self.reports.items) |report| {
            report.deinit();
        }
        self.reports.deinit();
    }
};

const Order = enum {
    increasing,
    decreasing,
};

fn isSafeDifference(a: usize, b: usize) bool {
    const difference = @max(a, b) - @min(a, b);

    if (difference < 1 or difference > 3)
        return false;
    return true;
}

fn isReportSafe(report: ArrayList(usize)) bool {
    debug.assert(report.items.len >= 2);

    if (!isSafeDifference(report.items[0], report.items[1]))
        return false;

    const order: Order = switch (report.items[0] < report.items[1]) {
        true => .increasing,
        false => .decreasing,
    };

    var previous = report.items[1];
    for (report.items[2..]) |value| {
        if (!isPairSafe(previous, value, order))
            return false;

        previous = value;
    }

    return true;
}

fn isPairSafe(a: usize, b: usize, order: Order) bool {
    if (!isSafeDifference(a, b))
        return false;
    if (a < b) {
        if (order == .decreasing) {
            return false;
        }
    }
    else if (order == .increasing) {
        return false;
    }
    return true;
}

fn isReportSafe2(report: ArrayList(usize)) !bool {
    debug.assert(report.items.len >= 2);

    if (!isSafeDifference(report.items[0], report.items[1])) {
        for (0..2) |remove_index| {
            var alternate = try report.clone();
            defer alternate.deinit();
            _ = alternate.orderedRemove(remove_index);

            if (isReportSafe(alternate))
                return true;
        }
        return false;
    }

    const order: Order = switch (report.items[0] < report.items[1]) {
        true => .increasing,
        false => .decreasing,
    };

    var previous = report.items[1];
    for (report.items[2..], 2..) |value, index| {
        if (!isPairSafe(previous, value, order)) {
            for (0..3) |sub| {
                var alternate = try report.clone();
                defer alternate.deinit();
                _ = alternate.orderedRemove(index - sub);

                if (isReportSafe(alternate))
                    return true;
            }
            return false;
        }

        previous = value;
    }

    return true;
}

fn partOne(input: Input) usize {
    var safe_report_count: usize = 0;
    for (input.reports.items) |report| {
        if (isReportSafe(report)) 
            safe_report_count += 1;
    }
    return safe_report_count;
}

fn partTwo(input: Input) !usize {
    var safe_report_count: usize = 0;
    for (input.reports.items) |report| {
        if (try isReportSafe2(report)) {
            safe_report_count += 1;
        }
    }
    return safe_report_count;
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
    try stdout.print("{d}\n", .{try partTwo(input)});

    try bw.flush();
}
