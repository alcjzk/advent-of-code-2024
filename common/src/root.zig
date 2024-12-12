pub usingnamespace @import("vector2.zig");
pub usingnamespace @import("map2d.zig");

pub fn countDigits(value: u64) usize {
    return @as(usize, @intFromFloat(@log10(@as(f64, @floatFromInt(value))) + 1));
}
