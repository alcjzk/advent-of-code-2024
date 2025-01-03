const std = @import("std");
const aoc = @import("root.zig");

const mem = std.mem;

const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const Vector2 = aoc.Vector2;

pub fn Map2D(comptime T: type) type {
    return struct {
        width: usize,
        height: usize,
        inner: ArrayList(T),

        const Self = @This();

        const Positions = struct {
            x: isize = -1,
            y: isize = 0,
            map: *const Self,

            pub fn next(self: *@This()) ?Vector2(isize) {
                if (self.x < self.map.width - 1) {
                    self.x += 1;
                } else if (self.y < self.map.height - 1) {
                    self.x = 0;
                    self.y += 1;
                } else {
                    return null;
                }

                return .{ .x = self.x, .y = self.y };
            }
        };

        pub fn initBytes(allocator: Allocator, bytes: []const u8) !Self {
            if (T != u8)
                @compileError("Map2D.initBytes only supports type u8\n");

            var self: Self = undefined;

            self.inner = ArrayList(u8).init(allocator);
            errdefer self.inner.deinit();

            var lines = mem.tokenizeScalar(u8, bytes, '\n');
            self.width = lines.peek().?.len;
            self.height = 0;

            while (lines.next()) |line| {
                try self.inner.appendSlice(line);
                self.height += 1;
            }

            return self;
        }

        pub fn initSized(allocator: Allocator, width: usize, height: usize, value: T) !Self {
            var self: Self = undefined;

            const size = width * height;

            self.inner = try ArrayList(T).initCapacity(allocator, size);
            self.inner.appendNTimesAssumeCapacity(value, size);
            self.width = width;
            self.height = height;

            return self;
        }

        pub fn deinit(self: Self) void {
            self.inner.deinit();
        }

        pub fn getCell(self: Self, position: Vector2(isize)) ?T {
            if (position.x < 0 or position.x >= self.width)
                return null;
            if (position.y < 0 or position.y >= self.height)
                return null;

            return self.getCellAssumeInBounds(position);
        }

        pub fn getCellAssumeInBounds(self: Self, position: Vector2(isize)) T {
            const x: usize = @intCast(position.x);
            const y: usize = @intCast(position.y);

            return self.inner.items[self.width * y + x];
        }

        pub fn getCellPtr(self: *Self, position: Vector2(isize)) ?*T {
            if (position.x < 0 or position.x >= self.width)
                return null;
            if (position.y < 0 or position.y >= self.height)
                return null;

            return self.getCellPtrAssumeInBounds(position);
        }

        pub fn getCellPtrAssumeInBounds(self: *Self, position: Vector2(isize)) *T {
            const x: usize = @intCast(position.x);
            const y: usize = @intCast(position.y);

            return &self.inner.items[self.width * y + x];
        }

        pub fn countMatchingCells(self: Self, value: T) usize {
            var count: usize = 0;
            for (self.inner.items) |cell| {
                if (cell == value)
                    count += 1;
            }
            return count;
        }

        /// Returns an iterator over all the positions in the map.
        pub fn positions(self: *const Self) Positions {
            return Positions{ .map = self };
        }

        pub fn clone(self: Self) !Self {
            return Self{
                .width = self.width,
                .height = self.height,
                .inner = try self.inner.clone(),
            };
        }
    };
}
