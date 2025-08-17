const std = @import("std");

pub const Git = struct {
    allocator: std.mem.Allocator,
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }
    
    // Helper function to trim newlines and whitespace
    fn trimWhitespace(s: []const u8) []const u8 {
        return std.mem.trim(u8, s, " \t\n\r");
    }
    
    // Helper function to safely extract commit hash
    fn extractCommitHash(s: []const u8) []const u8 {
        const trimmed = trimWhitespace(s);
        // Git commit hashes are 40 characters, return what we have if shorter
        if (trimmed.len >= 40) {
            return trimmed[0..40];
        }
        return trimmed;
    }
    
    pub fn pullUpstream(self: *Self, repo: []const u8, branch: []const u8, path: []const u8) !GitResult {
        // First check if path exists and is a git repository
        var dir = std.fs.openDirAbsolute(path, .{}) catch |err| {
            const error_msg = try std.fmt.allocPrint(self.allocator, "Failed to open directory: {}", .{err});
            return GitResult{
                .success = false,
                .error_message = error_msg,
                .files_changed = 0,
            };
        };
        dir.close();
        
        // Check if .git directory exists
        const git_path = try std.fs.path.join(self.allocator, &[_][]const u8{ path, ".git" });
        defer self.allocator.free(git_path);
        
        var git_dir = std.fs.openDirAbsolute(git_path, .{}) catch |err| {
            const error_msg = try std.fmt.allocPrint(self.allocator, "Not a git repository: {}", .{err});
            return GitResult{
                .success = false,
                .error_message = error_msg,
                .files_changed = 0,
            };
        };
        git_dir.close();
        
        // First, fetch from upstream
        const fetch_result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "git", "fetch", repo, branch },
            .cwd = path,
        });
        defer self.allocator.free(fetch_result.stdout);
        defer self.allocator.free(fetch_result.stderr);
        
        if (fetch_result.term.Exited != 0) {
            // Clone the error message to avoid use-after-free
            const error_msg = try self.allocator.dupe(u8, trimWhitespace(fetch_result.stderr));
            return GitResult{
                .success = false,
                .error_message = error_msg,
                .files_changed = 0,
            };
        }
        
        // Get current commit
        const before_result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "git", "rev-parse", "HEAD" },
            .cwd = path,
        });
        defer self.allocator.free(before_result.stdout);
        defer self.allocator.free(before_result.stderr);
        
        const before_commit = extractCommitHash(before_result.stdout);
        // Clone the commit hash for later use
        const before_commit_copy = try self.allocator.dupe(u8, before_commit);
        defer self.allocator.free(before_commit_copy);
        
        // Pull changes
        const pull_result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "git", "pull", repo, branch },
            .cwd = path,
        });
        defer self.allocator.free(pull_result.stdout);
        defer self.allocator.free(pull_result.stderr);
        
        if (pull_result.term.Exited != 0) {
            // Clone the error message to avoid use-after-free
            const error_msg = try self.allocator.dupe(u8, trimWhitespace(pull_result.stderr));
            return GitResult{
                .success = false,
                .error_message = error_msg,
                .files_changed = 0,
            };
        }
        
        // Get new commit
        const after_result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "git", "rev-parse", "HEAD" },
            .cwd = path,
        });
        defer self.allocator.free(after_result.stdout);
        defer self.allocator.free(after_result.stderr);
        
        const after_commit = extractCommitHash(after_result.stdout);
        
        // Count changed files if commits differ
        var files_changed: usize = 0;
        if (!std.mem.eql(u8, before_commit_copy, after_commit)) {
            // Build the diff command with the commit hashes
            const diff_result = try std.process.Child.run(.{
                .allocator = self.allocator,
                .argv = &[_][]const u8{ 
                    "git", "diff", "--name-only", 
                    before_commit_copy, 
                    after_commit 
                },
                .cwd = path,
            });
            defer self.allocator.free(diff_result.stdout);
            defer self.allocator.free(diff_result.stderr);
            
            // Count lines (files) - handle empty output
            if (diff_result.stdout.len > 0) {
                var iter = std.mem.tokenizeAny(u8, diff_result.stdout, "\n");
                while (iter.next()) |_| {
                    files_changed += 1;
                }
            }
        }
        
        return GitResult{
            .success = true,
            .error_message = null,
            .files_changed = files_changed,
        };
    }
    
    pub fn getStatus(self: *Self, path: []const u8) ![]const u8 {
        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "git", "status", "--short" },
            .cwd = path,
        });
        defer self.allocator.free(result.stderr);
        
        // Return the allocated stdout - caller must free
        return result.stdout;
    }
    
    pub fn hasUncommittedChanges(self: *Self, path: []const u8) !bool {
        const status = try self.getStatus(path);
        defer self.allocator.free(status);
        
        // Trim whitespace before checking length
        const trimmed = trimWhitespace(status);
        return trimmed.len > 0;
    }
    
    pub fn getCurrentBranch(self: *Self, path: []const u8) ![]const u8 {
        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "git", "branch", "--show-current" },
            .cwd = path,
        });
        defer self.allocator.free(result.stderr);
        
        // Trim whitespace and return a copy
        const trimmed = trimWhitespace(result.stdout);
        const branch_copy = try self.allocator.dupe(u8, trimmed);
        self.allocator.free(result.stdout);
        
        return branch_copy;
    }
    
    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

pub const GitResult = struct {
    success: bool,
    error_message: ?[]const u8,  // Caller must free if not null
    files_changed: usize,
    
    pub fn deinit(self: *GitResult, allocator: std.mem.Allocator) void {
        if (self.error_message) |msg| {
            allocator.free(msg);
        }
    }
};