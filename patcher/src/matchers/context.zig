const std = @import("std");
const patch_format = @import("../patch_format.zig");

pub const ContextMatcher = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ContextMatcher {
        return .{ .allocator = allocator };
    }

    /// Match based on code context (e.g., "last_import", "first_function", etc.)
    pub fn match(self: *ContextMatcher, haystack: []const u8, pattern: []const u8, context: []const u8) !patch_format.MatchResult {
        if (std.mem.eql(u8, context, "last_import")) {
            return self.findLastImport(haystack);
        } else if (std.mem.eql(u8, context, "first_import")) {
            return self.findFirstImport(haystack);
        } else if (std.mem.eql(u8, context, "last_function")) {
            return self.findLastFunction(haystack);
        } else if (std.mem.eql(u8, context, "class_start")) {
            return self.findClassStart(haystack, pattern);
        } else if (std.mem.eql(u8, context, "file_start")) {
            return self.findFileStart(haystack);
        } else if (std.mem.eql(u8, context, "file_end")) {
            return self.findFileEnd(haystack);
        }
        
        return patch_format.MatchResult{
            .found = false,
            .confidence = 0.0,
            .context_info = "Unknown context type",
        };
    }

    fn findLastImport(self: *ContextMatcher, haystack: []const u8) !patch_format.MatchResult {
        _ = self;
        
        // Find all import statements
        var last_import_end: ?usize = null;
        var i: usize = 0;
        
        while (i < haystack.len) {
            // Look for TypeScript/JavaScript imports
            if (std.mem.indexOf(u8, haystack[i..], "import ")) |pos| {
                const import_start = i + pos;
                // Find the end of the import statement
                if (std.mem.indexOf(u8, haystack[import_start..], "\n")) |end_pos| {
                    last_import_end = import_start + end_pos + 1;
                    i = last_import_end.?;
                } else {
                    break;
                }
            } else if (std.mem.indexOf(u8, haystack[i..], "const ")) |pos| {
                // Check for require statements
                const const_start = i + pos;
                if (std.mem.indexOf(u8, haystack[const_start..], "require(")) |_| {
                    if (std.mem.indexOf(u8, haystack[const_start..], "\n")) |end_pos| {
                        last_import_end = const_start + end_pos + 1;
                        i = last_import_end.?;
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            } else {
                break;
            }
        }
        
        if (last_import_end) |end| {
            return patch_format.MatchResult{
                .found = true,
                .start = end,
                .end = end,
                .confidence = 1.0,
                .context_info = "After last import statement",
            };
        }
        
        return patch_format.MatchResult{
            .found = false,
            .confidence = 0.0,
            .context_info = "No import statements found",
        };
    }

    fn findFirstImport(self: *ContextMatcher, haystack: []const u8) !patch_format.MatchResult {
        _ = self;
        
        // Find first import or require statement
        const import_pos = std.mem.indexOf(u8, haystack, "import ");
        const require_pos = std.mem.indexOf(u8, haystack, "require(");
        
        var first_pos: ?usize = null;
        if (import_pos != null and require_pos != null) {
            first_pos = @min(import_pos.?, require_pos.?);
        } else if (import_pos != null) {
            first_pos = import_pos;
        } else if (require_pos != null) {
            // Find the const/let/var before require
            if (require_pos.? > 10) {
                var check_pos = require_pos.? - 1;
                while (check_pos > 0) : (check_pos -= 1) {
                    if (haystack[check_pos] == '\n') {
                        first_pos = check_pos + 1;
                        break;
                    }
                }
            }
        }
        
        if (first_pos) |pos| {
            return patch_format.MatchResult{
                .found = true,
                .start = pos,
                .end = pos,
                .confidence = 1.0,
                .context_info = "Before first import statement",
            };
        }
        
        return patch_format.MatchResult{
            .found = false,
            .confidence = 0.0,
            .context_info = "No import statements found",
        };
    }

    fn findLastFunction(self: *ContextMatcher, haystack: []const u8) !patch_format.MatchResult {
        
        // Find last function declaration
        var last_func_end: ?usize = null;
        var i: usize = 0;
        
        while (i < haystack.len) {
            const func_keywords = [_][]const u8{
                "function ",
                "async function",
                "export function",
                "export async function",
                "const ",
                "let ",
                "var ",
            };
            
            var found_func = false;
            for (func_keywords) |keyword| {
                if (std.mem.indexOf(u8, haystack[i..], keyword)) |pos| {
                    const start = i + pos;
                    // Check if it's a function (arrow or regular)
                    if (std.mem.indexOf(u8, haystack[start..], "=>") != null or
                        std.mem.indexOf(u8, haystack[start..], "function") != null) {
                        // Find the closing brace
                        if (self.findClosingBrace(haystack[start..])) |end| {
                            last_func_end = start + end + 1;
                            i = last_func_end.?;
                            found_func = true;
                            break;
                        }
                    }
                }
            }
            
            if (!found_func) break;
        }
        
        if (last_func_end) |end| {
            return patch_format.MatchResult{
                .found = true,
                .start = end,
                .end = end,
                .confidence = 1.0,
                .context_info = "After last function",
            };
        }
        
        return patch_format.MatchResult{
            .found = false,
            .confidence = 0.0,
            .context_info = "No functions found",
        };
    }

    fn findClassStart(self: *ContextMatcher, haystack: []const u8, class_name: []const u8) !patch_format.MatchResult {
        
        const search_pattern = try std.fmt.allocPrint(self.allocator, "class {s}", .{class_name});
        defer self.allocator.free(search_pattern);
        
        if (std.mem.indexOf(u8, haystack, search_pattern)) |pos| {
            // Find the opening brace
            if (std.mem.indexOf(u8, haystack[pos..], "{")) |brace_pos| {
                const start = pos + brace_pos + 1;
                // Skip to next line after opening brace
                if (std.mem.indexOf(u8, haystack[start..], "\n")) |newline| {
                    return patch_format.MatchResult{
                        .found = true,
                        .start = start + newline + 1,
                        .end = start + newline + 1,
                        .confidence = 1.0,
                        .context_info = "Inside class body",
                    };
                }
            }
        }
        
        return patch_format.MatchResult{
            .found = false,
            .confidence = 0.0,
            .context_info = "Class not found",
        };
    }

    fn findFileStart(self: *ContextMatcher, haystack: []const u8) !patch_format.MatchResult {
        _ = self;
        _ = haystack;
        
        return patch_format.MatchResult{
            .found = true,
            .start = 0,
            .end = 0,
            .confidence = 1.0,
            .context_info = "Start of file",
        };
    }

    fn findFileEnd(self: *ContextMatcher, haystack: []const u8) !patch_format.MatchResult {
        _ = self;
        
        return patch_format.MatchResult{
            .found = true,
            .start = haystack.len,
            .end = haystack.len,
            .confidence = 1.0,
            .context_info = "End of file",
        };
    }

    fn findClosingBrace(self: *ContextMatcher, text: []const u8) ?usize {
        _ = self;
        var depth: i32 = 0;
        var in_string = false;
        var escape_next = false;
        var string_char: ?u8 = null;
        
        for (text, 0..) |char, i| {
            if (escape_next) {
                escape_next = false;
                continue;
            }
            
            if (char == '\\') {
                escape_next = true;
                continue;
            }
            
            if (!in_string) {
                if (char == '"' or char == '\'' or char == '`') {
                    in_string = true;
                    string_char = char;
                } else if (char == '{') {
                    depth += 1;
                } else if (char == '}') {
                    depth -= 1;
                    if (depth == 0) {
                        return i;
                    }
                }
            } else {
                if (char == string_char.?) {
                    in_string = false;
                    string_char = null;
                }
            }
        }
        
        return null;
    }

    pub fn deinit(self: *ContextMatcher) void {
        _ = self;
    }
};