const std = @import("std");
const patch_format = @import("../patch_format.zig");

pub const ExactMatcher = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ExactMatcher {
        return .{ .allocator = allocator };
    }

    pub fn match(_: *ExactMatcher, haystack: []const u8, pattern: []const u8) !patch_format.MatchResult {
        if (std.mem.indexOf(u8, haystack, pattern)) |pos| {
            return patch_format.MatchResult{
                .found = true,
                .start = pos,
                .end = pos + pattern.len,
                .confidence = 1.0,
                .matched_text = pattern,
                .context_info = null,
            };
        }
        return patch_format.MatchResult{
            .found = false,
            .confidence = 0.0,
        };
    }

    pub fn matchAll(self: *ExactMatcher, haystack: []const u8, pattern: []const u8) ![]patch_format.MatchResult {
        var results = std.ArrayList(patch_format.MatchResult).init(self.allocator);
        defer results.deinit();

        var offset: usize = 0;
        while (offset < haystack.len) {
            if (std.mem.indexOf(u8, haystack[offset..], pattern)) |pos| {
                const absolute_pos = offset + pos;
                try results.append(.{
                    .found = true,
                    .start = absolute_pos,
                    .end = absolute_pos + pattern.len,
                    .confidence = 1.0,
                    .matched_text = pattern,
                    .context_info = null,
                });
                offset = absolute_pos + pattern.len;
            } else {
                break;
            }
        }

        return results.toOwnedSlice();
    }

    pub fn deinit(self: *ExactMatcher) void {
        _ = self;
    }
};