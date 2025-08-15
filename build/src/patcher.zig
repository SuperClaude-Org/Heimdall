const std = @import("std");
const patch_format = @import("patch_format.zig");
const exact_matcher = @import("matchers/exact.zig");
const fuzzy_matcher = @import("matchers/fuzzy.zig");
const context_matcher = @import("matchers/context.zig");

pub const PatchResult = struct {
    success: bool,
    files_modified: usize,
    files_failed: usize,
    errors: []PatchError,
};

pub const PatchError = struct {
    file: []const u8,
    patch_id: []const u8,
    message: []const u8,
    line: ?usize = null,
};

pub const Patcher = struct {
    allocator: std.mem.Allocator,
    dry_run: bool,
    verbose: bool,
    backup: bool,
    backup_dir: []const u8,

    pub fn init(allocator: std.mem.Allocator) Patcher {
        return .{
            .allocator = allocator,
            .dry_run = false,
            .verbose = false,
            .backup = true,
            .backup_dir = ".heimdall-backup",
        };
    }

    pub fn applyPatchFile(self: *Patcher, patch_file_path: []const u8) !PatchResult {
        // Read patch file
        const file = try std.fs.cwd().openFile(patch_file_path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 10 * 1024 * 1024); // 10MB max
        defer self.allocator.free(content);

        // Parse patch file
        var patch_file = try patch_format.PatchFile.parse(self.allocator, content);
        defer patch_file.deinit(self.allocator);

        // Apply patches
        return self.applyPatches(&patch_file);
    }

    pub fn applyPatches(self: *Patcher, patch_file: *patch_format.PatchFile) !PatchResult {
        var files_modified: usize = 0;
        var files_failed: usize = 0;
        var errors = std.ArrayList(PatchError).init(self.allocator);
        defer errors.deinit();

        if (self.verbose) {
            std.debug.print("Applying patch: {s}\n", .{patch_file.name});
            std.debug.print("Description: {s}\n", .{patch_file.description});
        }

        for (patch_file.patches) |patch| {
            if (self.verbose) {
                std.debug.print("\nApplying patch: {s}\n", .{patch.id});
            }

            for (patch.files) |file_pattern| {
                const files = try self.findFiles(file_pattern);
                defer self.allocator.free(files);

                for (files) |file_path| {
                    if (self.applyPatchToFile(file_path, &patch)) {
                        files_modified += 1;
                        if (self.verbose) {
                            std.debug.print("  ✓ Modified: {s}\n", .{file_path});
                        }
                    } else |err| {
                        files_failed += 1;
                        try errors.append(.{
                            .file = file_path,
                            .patch_id = patch.id,
                            .message = @errorName(err),
                        });
                        if (self.verbose) {
                            std.debug.print("  ✗ Failed: {s} - {s}\n", .{ file_path, @errorName(err) });
                        }
                    }
                }
            }
        }

        return PatchResult{
            .success = files_failed == 0,
            .files_modified = files_modified,
            .files_failed = files_failed,
            .errors = try errors.toOwnedSlice(),
        };
    }

    fn applyPatchToFile(self: *Patcher, file_path: []const u8, patch: *const patch_format.Patch) !void {
        // Create backup if needed
        if (self.backup and !self.dry_run) {
            try self.createBackup(file_path);
        }

        // Read file content
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 50 * 1024 * 1024); // 50MB max
        defer self.allocator.free(content);

        // Apply changes
        var modified_content = try self.allocator.dupe(u8, content);
        defer self.allocator.free(modified_content);

        for (patch.changes) |change| {
            modified_content = try self.applyChange(modified_content, &change);
        }

        // Write back if not dry run
        if (!self.dry_run) {
            const out_file = try std.fs.cwd().createFile(file_path, .{});
            defer out_file.close();
            try out_file.writeAll(modified_content);
        } else if (self.verbose) {
            std.debug.print("  [DRY RUN] Would modify: {s}\n", .{file_path});
        }
    }

    fn applyChange(self: *Patcher, content: []const u8, change: *const patch_format.Change) ![]u8 {
        // Find match using matchers
        var match_result: ?patch_format.MatchResult = null;

        for (change.matchers) |matcher| {
            match_result = try self.runMatcher(content, &matcher);
            if (match_result.?.found) break;
        }

        if (match_result == null or !match_result.?.found) {
            return error.NoMatchFound;
        }

        // Apply strategy
        return switch (change.strategy) {
            .replace => try self.applyReplace(content, match_result.?, change),
            .inject_before => try self.applyInjectBefore(content, match_result.?, change),
            .inject_after => try self.applyInjectAfter(content, match_result.?, change),
            .wrap => try self.applyWrap(content, match_result.?, change),
            .delete => try self.applyDelete(content, match_result.?),
        };
    }

    fn runMatcher(self: *Patcher, content: []const u8, matcher: *const patch_format.Matcher) !patch_format.MatchResult {
        return switch (matcher.type) {
            .exact => {
                var exact = exact_matcher.ExactMatcher.init(self.allocator);
                defer exact.deinit();
                return exact.match(content, matcher.pattern);
            },
            .fuzzy => {
                var fuzzy = fuzzy_matcher.FuzzyMatcher.init(self.allocator, matcher.confidence_threshold);
                defer fuzzy.deinit();
                return fuzzy.match(content, matcher.pattern);
            },
            .context => {
                var context = context_matcher.ContextMatcher.init(self.allocator);
                defer context.deinit();
                return context.match(content, matcher.pattern, matcher.context orelse "");
            },
            else => return patch_format.MatchResult{ .found = false, .confidence = 0.0 },
        };
    }

    fn applyReplace(self: *Patcher, content: []const u8, match: patch_format.MatchResult, change: *const patch_format.Change) ![]u8 {
        const replacement = change.replacement orelse return error.NoReplacementText;
        
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();

        try result.appendSlice(content[0..match.start]);
        try result.appendSlice(replacement);
        try result.appendSlice(content[match.end..]);

        return result.toOwnedSlice();
    }

    fn applyInjectBefore(self: *Patcher, content: []const u8, match: patch_format.MatchResult, change: *const patch_format.Change) ![]u8 {
        const injection = change.content orelse return error.NoInjectionContent;
        
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();

        try result.appendSlice(content[0..match.start]);
        try result.appendSlice(injection);
        if (injection.len == 0 or injection[injection.len - 1] != '\n') {
            try result.append('\n');
        }
        try result.appendSlice(content[match.start..]);

        return result.toOwnedSlice();
    }

    fn applyInjectAfter(self: *Patcher, content: []const u8, match: patch_format.MatchResult, change: *const patch_format.Change) ![]u8 {
        const injection = change.content orelse return error.NoInjectionContent;
        
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();

        try result.appendSlice(content[0..match.end]);
        if (match.end == 0 or content[match.end - 1] != '\n') {
            try result.append('\n');
        }
        try result.appendSlice(injection);
        if (injection.len == 0 or injection[injection.len - 1] != '\n') {
            try result.append('\n');
        }
        try result.appendSlice(content[match.end..]);

        return result.toOwnedSlice();
    }

    fn applyWrap(self: *Patcher, content: []const u8, match: patch_format.MatchResult, change: *const patch_format.Change) ![]u8 {
        _ = match;
        _ = change;
        // TODO: Implement wrap strategy
        return self.allocator.dupe(u8, content);
    }

    fn applyDelete(self: *Patcher, content: []const u8, match: patch_format.MatchResult) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();

        try result.appendSlice(content[0..match.start]);
        try result.appendSlice(content[match.end..]);

        return result.toOwnedSlice();
    }

    fn findFiles(self: *Patcher, pattern: []const u8) ![][]const u8 {
        var files = std.ArrayList([]const u8).init(self.allocator);
        defer files.deinit();

        // Simple implementation - just check if file exists
        // TODO: Implement glob pattern matching
        if (std.fs.cwd().access(pattern, .{})) {
            try files.append(try self.allocator.dupe(u8, pattern));
        } else |_| {
            // Pattern might be a glob, try to expand it
            // For now, just return empty if file doesn't exist
        }

        return files.toOwnedSlice();
    }

    fn createBackup(self: *Patcher, file_path: []const u8) !void {
        // Create backup directory if it doesn't exist
        std.fs.cwd().makeDir(self.backup_dir) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        // Generate backup filename with timestamp
        const timestamp = std.time.timestamp();
        const backup_name = try std.fmt.allocPrint(
            self.allocator,
            "{s}/{s}.{d}.backup",
            .{ self.backup_dir, std.fs.path.basename(file_path), timestamp }
        );
        defer self.allocator.free(backup_name);

        // Copy file to backup
        try std.fs.cwd().copyFile(file_path, std.fs.cwd(), backup_name, .{});
    }

    pub fn deinit(self: *Patcher) void {
        _ = self;
    }
};