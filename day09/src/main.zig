const std = @import("std");

const heap = std.heap;
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const debug = std.debug;

const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;

const Input = struct {
    files: ArrayList(usize),
    free_space: ArrayList(usize),

    const Self = @This();

    pub fn init(allocator: Allocator, bytes: []const u8) !Self {
        var self: Self = undefined;

        self.files = ArrayList(usize).init(allocator);
        errdefer self.files.deinit();

        self.free_space = ArrayList(usize).init(allocator);
        errdefer self.free_space.deinit();

        for (0..bytes.len - 1) |index| {
            const digit: usize = bytes[index] - '0';

            if (index % 2 == 0) {
                try self.files.append(digit);
            } else {
                try self.free_space.append(digit);
            }
        }

        return self;
    }

    pub fn deinit(self: Self) void {
        self.files.deinit();
        self.free_space.deinit();
    }
};

const State = enum {
    file,
    space,
};

const File = struct {
    id: usize,
    size: usize,
};

const Space = struct {
    size: usize,
};

const SegmentType = enum {
    file,
    space,
};

const Segment = union(SegmentType) {
    file: File,
    space: Space,
};

const DiskMap = struct {
    segments: ArrayList(Segment),
    file_count: usize,

    const Self = @This();

    pub fn init(allocator: Allocator, bytes: []const u8) !Self {
        var self: Self = undefined;

        self.segments = try ArrayList(Segment).initCapacity(allocator, bytes.len - 1);
        self.file_count = 0;

        for (0..bytes.len - 1) |index| {
            const digit: usize = bytes[index] - '0';
            debug.assert(digit >= 0 and digit < 10);

            const segment = switch (index % 2 == 0) {
                true => blk: {
                    const file_segment = Segment{ .file = .{
                        .id = self.file_count,
                        .size = digit,
                    } };

                    self.file_count += 1;

                    break :blk file_segment;
                },
                false => Segment{ .space = .{ .size = digit } },
            };

            self.segments.appendAssumeCapacity(segment);
        }

        return self;
    }

    pub fn deinit(self: Self) void {
        self.segments.deinit();
    }

    pub fn findSpacePosition(self: Self, size: usize) ?usize {
        for (self.segments.items, 0..) |segment, index| {
            switch (segment) {
                .space => |space| {
                    if (space.size >= size) {
                        return index;
                    }
                },
                .file => continue,
            }
        }
        return null;
    }

    pub fn getFilePositionAssumeExists(self: Self, id: u32) usize {
        for (self.segments.items, 0..) |segment, position| {
            switch (segment) {
                .file => |file| {
                    if (file.id == id) {
                        return position;
                    }
                },
                .space => continue,
            }
        }
        unreachable;
    }
};

pub fn partOne(input: Input) u64 {
    var result: u64 = 0;
    var segment_type = Segment.file;

    var file_first_index: usize = 0;
    var file_last_index: usize = input.files.items.len - 1;
    var space_index: usize = 0;
    var position: usize = 0;

    while (true) {
        switch (segment_type) {
            .file => {
                const file_size = &input.files.items[file_first_index];

                // Zero sized file?
                if (file_size.* == 0) {
                    position += 1;
                    file_first_index += 1;
                    segment_type = .space;
                    continue;
                }

                result += position * file_first_index;
                position += 1;
                file_size.* -= 1;

                // Did we make it zero?
                if (file_size.* == 0) {
                    if (file_first_index == file_last_index) {
                        return result;
                    }
                    file_first_index += 1;
                    segment_type = .space;
                }
            },
            .space => {
                const space_size = &input.free_space.items[space_index];
                const file_size = &input.files.items[file_last_index];

                // Zero sized space? -- switch back to file context
                if (space_size.* == 0) {
                    space_index += 1;
                    segment_type = .file;
                    continue;
                }

                // Zero sized file? -- count in and move to next
                if (file_size.* == 0) {
                    position += 1;
                    if (file_first_index == file_last_index) {
                        return result;
                    }
                    file_last_index -= 1;
                } else {
                    result += position * file_last_index;
                    position += 1;
                    file_size.* -= 1;
                    // Did we make it zero? -- count in and move to next
                    if (file_size.* == 0) {
                        if (file_first_index == file_last_index) {
                            return result;
                        }
                        file_last_index -= 1;
                    }
                }

                space_size.* -= 1;
                if (space_size.* == 0) {
                    // Did we run out of space? -- switch to file context
                    space_index += 1;
                    segment_type = .file;
                }
            },
        }
    }
}

pub fn partTwo(disk_map: *DiskMap) !u64 {
    var file_id: u32 = @intCast(disk_map.file_count);
    while (file_id > 0) {
        file_id -= 1;

        const file_position = disk_map.getFilePositionAssumeExists(file_id);
        const file = disk_map.segments.items[file_position].file;

        if (disk_map.findSpacePosition(file.size)) |space_position| {
            if (space_position >= file_position)
                continue;

            disk_map.segments.items[file_position] = Segment{ .space = .{ .size = file.size } };
            disk_map.segments.items[space_position].space.size -= file.size;

            try disk_map.segments.insert(space_position, Segment{ .file = file });
        }
    }

    var position: usize = 0;
    var result: usize = 0;

    for (disk_map.segments.items) |*segment| {
        switch (segment.*) {
            .space => |*space| {
                while (space.size > 0) {
                    space.size -= 1;
                    position += 1;
                }
            },
            .file => |*file| {
                if (file.size == 0) {
                    position += 1;
                    continue;
                }

                while (file.size > 0) {
                    result += position * file.id;
                    position += 1;
                    file.size -= 1;
                }
            },
        }
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

    var disk_map = try DiskMap.init(allocator, bytes);
    defer disk_map.deinit();

    try stdout.print("{}\n", .{partOne(input)});
    try stdout.print("{}\n", .{try partTwo(&disk_map)});

    try bw.flush();
}
