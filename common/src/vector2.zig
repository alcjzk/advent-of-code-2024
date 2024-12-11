pub fn Vector2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        const Self = @This();

        pub fn add(self: Self, other: Self) Self {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn mul(self: Self, value: T) Self {
            return .{
                .x = self.x * value,
                .y = self.y * value,
            };
        }

        /// Element-wise exact division. Caller provides guarantees equivalent to @divExact.
        pub fn divExact(self: Self, value: T) Self {
            return .{
                .x = @divExact(self.x, value),
                .y = @divExact(self.y, value),
            };
        }

        pub fn eql(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }
    };
}