const std = @import("std");
const aoc = @import("aoc");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;
const meta = std.meta;

const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;
const Map = aoc.Map2D(u8);
const Vector2i = aoc.Vector2(isize);

const directions: [4]Vector2i = .{ Vector2i.up, Vector2i.down, Vector2i.left, Vector2i.right };

const Region = struct {
    positions: ArrayList(Vector2i),
    cell_value: u8,

    const Self = @This();

    pub fn initFromMapPosition(allocator: Allocator, map: *Map, position: Vector2i) !Self {
        var self: Self = undefined;

        self.positions = ArrayList(Vector2i).init(allocator);
        errdefer self.positions.deinit();

        self.cell_value = map.getCellAssumeInBounds(position);

        try self.floodFillRecursive(map, position);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.positions.deinit();
    }

    pub fn floodFillRecursive(self: *Self, map: *Map, position: Vector2i) !void {
        const cell_ptr = map.getCellPtr(position) orelse return;

        if (cell_ptr.* != self.cell_value) {
            return;
        }

        cell_ptr.* = '.';
        try self.positions.append(position);

        for (directions) |direction| {
            try floodFillRecursive(self, map, position.add(direction));
        }
    }

    pub fn area(self: Self) u64 {
        return self.positions.items.len;
    }

    pub fn perimeter(self: Self, map: Map) u64 {
        var result: u64 = 0;

        for (self.positions.items) |position| {
            for (directions) |direction| {
                if (map.getCell(position.add(direction))) |adjacent_cell| {
                    if (adjacent_cell == self.cell_value) {
                        continue;
                    }
                }
                result += 1;
            }
        }

        return result;
    }

    pub fn perimeterSideCount(self: Self, map: Map) u64 {
        var result: u64 = 0;

        for (self.positions.items) |position| {
            for (directions) |direction| {
                const adjacent_position = position.add(direction);

                if (map.getCell(adjacent_position)) |adjacent_cell| {
                    if (adjacent_cell == self.cell_value) {
                        continue;
                    }
                }

                result += 1;

                const perpendicular_direction = if (meta.eql(direction, Vector2i.up) or meta.eql(direction, Vector2i.down))
                    Vector2i.left
                else
                    Vector2i.up;

                const perpendicular_position = position.add(perpendicular_direction);
                const perpendicular_cell = map.getCell(perpendicular_position) orelse continue;

                if (perpendicular_cell != self.cell_value) {
                    continue;
                }

                if (map.getCell(perpendicular_position.add(direction))) |adjacent_cell| {
                    if (adjacent_cell == self.cell_value) {
                        continue;
                    }
                }

                result -= 1;
            }
        }
        return result;
    }
};

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

    const map = try Map.initBytes(allocator, bytes);
    defer map.deinit();

    var fill_map = try map.clone();
    defer fill_map.deinit();

    var price: u64 = 0;
    var discount_price: u64 = 0;
    var positions = fill_map.positions();

    while (positions.next()) |position| {
        const cell = fill_map.getCellAssumeInBounds(position);

        if (cell == '.') {
            continue;
        }

        const region = try Region.initFromMapPosition(allocator, &fill_map, position);
        defer region.deinit();

        price += region.area() * region.perimeter(map);
        discount_price += region.area() * region.perimeterSideCount(map);
    }

    try stdout.print("{}\n", .{price});
    try stdout.print("{}\n", .{discount_price});

    try bw.flush();
}
