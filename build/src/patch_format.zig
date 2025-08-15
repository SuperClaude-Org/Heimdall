const std = @import("std");
const json = std.json;

/// Represents a complete patch file
pub const PatchFile = struct {
    version: []const u8,
    name: []const u8,
    description: []const u8,
    compatibility: ?Compatibility = null,
    patches: []Patch,

    pub fn parse(allocator: std.mem.Allocator, content: []const u8) !PatchFile {
        const parsed = try json.parseFromSlice(PatchFile, allocator, content, .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        });
        return parsed.value;
    }

    pub fn deinit(self: *PatchFile, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
        // JSON parsed data cleanup handled by allocator
    }
};

pub const Compatibility = struct {
    opencode: ?[]const u8 = null,
    test_command: ?[]const u8 = null,
};

pub const Patch = struct {
    id: []const u8,
    description: ?[]const u8 = null,
    files: []const []const u8,
    changes: []Change,
};

pub const Change = struct {
    strategy: Strategy,
    matchers: []Matcher,
    replacement: ?[]const u8 = null,
    content: ?[]const u8 = null,
    all_occurrences: bool = false,
    validation: ?Validation = null,
};

pub const Strategy = enum {
    replace,
    inject_before,
    inject_after,
    wrap,
    delete,

    pub fn fromString(str: []const u8) !Strategy {
        if (std.mem.eql(u8, str, "replace")) return .replace;
        if (std.mem.eql(u8, str, "inject_before")) return .inject_before;
        if (std.mem.eql(u8, str, "inject_after")) return .inject_after;
        if (std.mem.eql(u8, str, "wrap")) return .wrap;
        if (std.mem.eql(u8, str, "delete")) return .delete;
        return error.UnknownStrategy;
    }
};

pub const Matcher = struct {
    type: MatcherType,
    pattern: []const u8,
    context: ?[]const u8 = null,
    capture: bool = false,
    confidence_threshold: f32 = 0.8,
};

pub const MatcherType = enum {
    exact,
    regex,
    fuzzy,
    context,
    ast,

    pub fn fromString(str: []const u8) !MatcherType {
        if (std.mem.eql(u8, str, "exact")) return .exact;
        if (std.mem.eql(u8, str, "regex")) return .regex;
        if (std.mem.eql(u8, str, "fuzzy")) return .fuzzy;
        if (std.mem.eql(u8, str, "context")) return .context;
        if (std.mem.eql(u8, str, "ast")) return .ast;
        return error.UnknownMatcherType;
    }
};

pub const Validation = struct {
    test_command: ?[]const u8 = null,
    expected_output: ?[]const u8 = null,
    must_compile: bool = true,
};

/// Match result with confidence scoring
pub const MatchResult = struct {
    found: bool,
    start: usize = 0,
    end: usize = 0,
    confidence: f32 = 1.0,
    matched_text: ?[]const u8 = null,
    context_info: ?[]const u8 = null,
};