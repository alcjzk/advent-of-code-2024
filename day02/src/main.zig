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
        if (!isSafeDifference(previous, value))
            return false;

        if (previous < value) {
            if (order == .decreasing)
                return false;
        }
        else if (order == .increasing) {
            return false;
        }

        previous = value;
    }

    return true;
}

fn isReportSafe2(report: ArrayList(usize)) !bool {
    debug.assert(report.items.len >= 2);

    if (!isSafeDifference(report.items[0], report.items[1])) {
        var first_alternate = try report.clone();
        defer first_alternate.deinit();
        _ = first_alternate.orderedRemove(0);

        if (!isReportSafe(first_alternate)) {
            var second_alternate = try report.clone();
            defer second_alternate.deinit();
            _ = second_alternate.orderedRemove(1);

            return isReportSafe(second_alternate);
        }
        else return true;
    }

    const order: Order = switch (report.items[0] < report.items[1]) {
        true => .increasing,
        false => .decreasing,
    };

    var previous = report.items[1];
    for (report.items[2..], 2..) |value, index| {
        if (!isSafeDifference(previous, value)) {
            var first_alternate = try report.clone();
            defer first_alternate.deinit();
            _ = first_alternate.orderedRemove(index - 1);

            if (!isReportSafe(first_alternate)) {
                var second_alternate = try report.clone();
                defer second_alternate.deinit();
                _ = second_alternate.orderedRemove(index);

                return isReportSafe(second_alternate);
            }
            else return true;
        }

        if (previous < value) {
            if (order == .decreasing) {
                var first_alternate = try report.clone();
                defer first_alternate.deinit();
                _ = first_alternate.orderedRemove(index - 1);

                if (isReportSafe(first_alternate))
                    return true;

                var second_alternate = try report.clone();
                defer second_alternate.deinit();
                _ = second_alternate.orderedRemove(index);

                if (isReportSafe(second_alternate))
                    return true;

                var third_alternate = try report.clone();
                defer third_alternate.deinit();
                _ = third_alternate.orderedRemove(index - 2);

                return isReportSafe(third_alternate);
            }
        }
        else if (order == .increasing) {
            var first_alternate = try report.clone();
            defer first_alternate.deinit();
            _ = first_alternate.orderedRemove(index - 1);

            if (isReportSafe(first_alternate))
                return true;

            var second_alternate = try report.clone();
            defer second_alternate.deinit();
            _ = second_alternate.orderedRemove(index);

            if (isReportSafe(second_alternate))
                return true;

            var third_alternate = try report.clone();
            defer third_alternate.deinit();
            _ = third_alternate.orderedRemove(index - 2);

            return isReportSafe(third_alternate);
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
