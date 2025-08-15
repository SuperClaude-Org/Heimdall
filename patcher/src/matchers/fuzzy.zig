const std = @import("std");
const patch_format = @import("../patch_format.zig");

pub const FuzzyMatcher = struct {
    allocator: std.mem.Allocator,
    threshold: f32,

    pub fn init(allocator: std.mem.Allocator, threshold: f32) FuzzyMatcher {
        return .{
            .allocator = allocator,
            .threshold = threshold,
        };
    }

    /// Calculate Levenshtein distance between two strings
    fn levenshteinDistance(self: *FuzzyMatcher, s1: []const u8, s2: []const u8) !usize {
        if (s1.len == 0) return s2.len;
        if (s2.len == 0) return s1.len;

        var matrix = try self.allocator.alloc([]usize, s1.len + 1);
        defer self.allocator.free(matrix);

        for (matrix) |*row| {
            row.* = try self.allocator.alloc(usize, s2.len + 1);
        }
        defer for (matrix) |row| {
            self.allocator.free(row);
        };

        // Initialize first row and column
        for (matrix[0], 0..) |*cell, j| {
            cell.* = j;
        }
        for (matrix, 0..) |row, i| {
            row[0] = i;
        }

        // Fill the matrix
        for (s1, 0..) |c1, i| {
            for (s2, 0..) |c2, j| {
                const cost: usize = if (c1 == c2) 0 else 1;
                matrix[i + 1][j + 1] = @min(
                    matrix[i][j + 1] + 1, // deletion
                    @min(
                        matrix[i + 1][j] + 1, // insertion
                        matrix[i][j] + cost, // substitution
                    ),
                );
            }
        }

        return matrix[s1.len][s2.len];
    }

    /// Calculate similarity score (0.0 to 1.0)
    fn similarity(self: *FuzzyMatcher, s1: []const u8, s2: []const u8) !f32 {
        const distance = try self.levenshteinDistance(s1, s2);
        const max_len = @max(s1.len, s2.len);
        if (max_len == 0) return 1.0;
        return 1.0 - @as(f32, @floatFromInt(distance)) / @as(f32, @floatFromInt(max_len));
    }

    pub fn match(self: *FuzzyMatcher, haystack: []const u8, pattern: []const u8) !patch_format.MatchResult {
        var best_match = patch_format.MatchResult{
            .found = false,
            .confidence = 0.0,
        };

        // Slide a window of pattern length through haystack
        const window_size = @min(pattern.len * 2, haystack.len);
        var i: usize = 0;
        while (i + pattern.len <= haystack.len) : (i += 1) {
            const end = @min(i + window_size, haystack.len);
            const window = haystack[i..end];
            
            // Try different substring lengths around pattern length
            const min_len = @max(1, pattern.len / 2);
            const max_len = @min(window.len, pattern.len * 2);
            
            var len = min_len;
            while (len <= max_len and len <= window.len) : (len += 1) {
                const substring = window[0..len];
                const score = try self.similarity(substring, pattern);
                
                if (score > best_match.confidence) {
                    best_match = .{
                        .found = score >= self.threshold,
                        .start = i,
                        .end = i + len,
                        .confidence = score,
                        .matched_text = substring,
                        .context_info = null,
                    };
                }
            }
        }

        return best_match;
    }

    pub fn deinit(self: *FuzzyMatcher) void {
        _ = self;
    }
};