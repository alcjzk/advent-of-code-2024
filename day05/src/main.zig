const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const fmt = std.fmt;

const ArrayList = std.ArrayList;

const OrderingRule = struct {
    pages: [2]u8,

    pub fn fromLine(line: []const u8) !OrderingRule {
        var self: OrderingRule = undefined;

        var tokens = mem.tokenizeScalar(u8, line, '|');

        for (0..2) |rule_index| {
            const token = tokens.next() orelse return error.InvalidOrderingRule;
            self.pages[rule_index] = try fmt.parseUnsigned(u8, token, 10);
        }

        debug.assert(tokens.peek() == null);

        return self;
    }

    pub fn before(self: OrderingRule) u8 {
        return self.pages[0];
    }

    pub fn after(self: OrderingRule) u8 {
        return self.pages[1];
    }
};

const Update = struct {
    pages: ArrayList(u8),

    pub fn init(allocator: mem.Allocator, line: []const u8) !Update {
        var self: Update = undefined;

        self.pages = ArrayList(u8).init(allocator);
        errdefer self.pages.deinit();

        var tokens = mem.tokenizeScalar(u8, line, ',');

        while (tokens.next()) |token| {
            try self.pages.append(try fmt.parseUnsigned(u8, token, 10));
        }

        return self;
    }

    pub fn deinit(self: Update) void {
        self.pages.deinit();
    }

    pub fn sort(self: *Update, rules: []const OrderingRule) void {
        mem.sort(u8, self.pages.items, rules, Update.less);
    }

    pub fn less(rules: []const OrderingRule, lhs: u8, rhs: u8) bool {
        for (rules) |rule| {
            if (rule.before() == lhs and rule.after() == rhs)
                return true;
            if (rule.before() == rhs and rule.after() == lhs)
                return false;
        }
        return lhs < rhs;
    }

    fn isValid(self: Update, rules: []const OrderingRule) bool {
        for (0..self.pages.items.len) |page_index| {
            const page = self.pages.items[page_index];

            for (rules) |rule| {
                if (rule.before() != page)
                    continue;

                for (0..page_index) |previous_index| {
                    if (rule.after() == self.pages.items[previous_index])
                        return false;
                }
            }
        }

        return true;
    }
};

const Input = struct {
    ordering_rules: ArrayList(OrderingRule),
    updates: ArrayList(Update),

    pub fn init(allocator: mem.Allocator, bytes: []const u8) !Input {
        var self: Input = undefined;

        self.ordering_rules = ArrayList(OrderingRule).init(allocator);
        errdefer self.ordering_rules.deinit();

        self.updates = ArrayList(Update).init(allocator);
        errdefer self.updates.deinit();

        var lines = mem.splitScalar(u8, bytes, '\n');

        while (lines.next()) |line| {
            if (mem.eql(u8, line, ""))
                break;
            const rule = try OrderingRule.fromLine(line);
            try self.ordering_rules.append(rule);
        }

        while (lines.next()) |line| {
            if (mem.eql(u8, line, ""))
                continue;
            const update = try Update.init(allocator, line);
            try self.updates.append(update);
        }

        return self;
    }

    pub fn deinit(self: Input) void {
        for (self.updates.items) |update| {
            update.deinit();
        }

        self.updates.deinit();
        self.ordering_rules.deinit();
    }
};

fn partOne(input: Input) u64 {
    var result: usize = 0;

    for (input.updates.items) |update| {
        if (!update.isValid(input.ordering_rules.items))
            continue;

        result += update.pages.items[update.pages.items.len / 2];
    }
    return result;
}

fn partTwo(input: Input) u64 {
    var result: usize = 0;

    for (input.updates.items) |*update| {
        if (update.isValid(input.ordering_rules.items))
            continue;

        update.sort(input.ordering_rules.items);
        result += update.pages.items[update.pages.items.len / 2];
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

    const input = try Input.init(allocator, bytes);
    defer input.deinit();

    try stdout.print("{d}\n", .{partOne(input)});
    try stdout.print("{d}\n", .{partTwo(input)});

    try bw.flush();
}
