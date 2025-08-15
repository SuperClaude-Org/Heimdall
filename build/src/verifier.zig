const std = @import("std");

pub const VerificationResult = struct {
    score: u32 = 100,
    critical_issues: usize = 0,
    warnings: usize = 0,
    ignored: usize = 0,
    issues: std.ArrayList(Issue),
    
    pub fn init(allocator: std.mem.Allocator) VerificationResult {
        return .{
            .issues = std.ArrayList(Issue).init(allocator),
        };
    }
    
    pub fn deinit(self: *VerificationResult) void {
        self.issues.deinit();
    }
};

pub const Issue = struct {
    level: Level,
    file: []const u8,
    line: ?usize = null,
    pattern: []const u8,
    context: []const u8,
    suggestion: ?[]const u8 = null,
    
    pub const Level = enum {
        critical,
        warning,
        info,
        ignored,
    };
};

pub const BrandingVerifier = struct {
    allocator: std.mem.Allocator,
    patterns: []const []const u8,
    whitelist: std.ArrayList(WhitelistEntry),
    critical_paths: std.ArrayList([]const u8),
    
    const Self = @This();
    
    const BRANDING_PATTERNS = [_][]const u8{
        "opencode",
        "OpenCode",
        "OPENCODE",
        "Opencode",
        "open-code",
        "open_code",
    };
    
    pub fn init(allocator: std.mem.Allocator) !Self {
        var whitelist = std.ArrayList(WhitelistEntry).init(allocator);
        var critical_paths = std.ArrayList([]const u8).init(allocator);
        
        // Add default whitelist entries
        try whitelist.append(.{ .pattern = "github.com/sst/opencode", .reason = "Original repository" });
        try whitelist.append(.{ .pattern = "Copyright.*OpenCode", .reason = "Legal attribution" });
        try whitelist.append(.{ .file = "CHANGELOG.md", .reason = "Historical record" });
        try whitelist.append(.{ .file = "LICENSE", .reason = "Legal document" });
        
        // Add critical paths
        try critical_paths.append("package.json");
        try critical_paths.append("bin/");
        try critical_paths.append("src/cli/");
        try critical_paths.append("README.md");
        
        return Self{
            .allocator = allocator,
            .patterns = &BRANDING_PATTERNS,
            .whitelist = whitelist,
            .critical_paths = critical_paths,
        };
    }
    
    pub fn verify(self: *Self, path: []const u8) !VerificationResult {
        var result = VerificationResult.init(self.allocator);
        
        // Scan directory recursively
        try self.scanDirectory(path, &result);
        
        // Calculate score
        const total_issues = result.critical_issues + result.warnings;
        if (total_issues > 0) {
            const penalty = @min(total_issues * 5, 100);
            result.score = 100 - @as(u32, @intCast(penalty));
        }
        
        return result;
    }
    
    fn scanDirectory(self: *Self, path: []const u8, result: *VerificationResult) !void {
        const dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
        
        var walker = try dir.walk(self.allocator);
        defer walker.deinit();
        
        while (try walker.next()) |entry| {
            if (entry.kind != .file) continue;
            
            // Skip binary files and common non-text extensions
            if (std.mem.endsWith(u8, entry.path, ".png") or
                std.mem.endsWith(u8, entry.path, ".jpg") or
                std.mem.endsWith(u8, entry.path, ".ico") or
                std.mem.endsWith(u8, entry.path, ".woff") or
                std.mem.endsWith(u8, entry.path, ".ttf") or
                std.mem.endsWith(u8, entry.path, ".exe") or
                std.mem.endsWith(u8, entry.path, ".so") or
                std.mem.endsWith(u8, entry.path, ".dylib")) {
                continue;
            }
            
            const full_path = try std.fs.path.join(self.allocator, &[_][]const u8{ path, entry.path });
            defer self.allocator.free(full_path);
            
            // Check filename for branding issues
            try self.checkFilename(entry.path, result);
            
            // Check file contents
            try self.checkFileContents(full_path, entry.path, result);
        }
    }
    
    fn checkFilename(self: *Self, filename: []const u8, result: *VerificationResult) !void {
        for (self.patterns) |pattern| {
            if (std.mem.indexOf(u8, filename, pattern) != null) {
                // Check if whitelisted
                if (self.isWhitelisted(filename, pattern)) {
                    result.ignored += 1;
                    continue;
                }
                
                // Check if critical path
                const is_critical = self.isCriticalPath(filename);
                
                try result.issues.append(.{
                    .level = if (is_critical) .critical else .warning,
                    .file = filename,
                    .pattern = pattern,
                    .context = "Filename contains branding issue",
                    .suggestion = "Rename file to use 'heimdall' instead",
                });
                
                if (is_critical) {
                    result.critical_issues += 1;
                } else {
                    result.warnings += 1;
                }
            }
        }
    }
    
    fn checkFileContents(self: *Self, full_path: []const u8, relative_path: []const u8, result: *VerificationResult) !void {
        const file = std.fs.cwd().openFile(full_path, .{}) catch |err| {
            if (err == error.IsDir) return;
            return err;
        };
        defer file.close();
        
        const stat = try file.stat();
        if (stat.size > 10 * 1024 * 1024) return; // Skip files > 10MB
        
        const contents = try file.readToEndAlloc(self.allocator, @intCast(stat.size));
        defer self.allocator.free(contents);
        
        // Split into lines for line number tracking
        var line_iter = std.mem.tokenize(u8, contents, "\n");
        var line_num: usize = 1;
        
        while (line_iter.next()) |line| {
            defer line_num += 1;
            
            for (self.patterns) |pattern| {
                if (std.mem.indexOf(u8, line, pattern) != null) {
                    // Check if whitelisted
                    if (self.isWhitelistedContent(relative_path, line)) {
                        result.ignored += 1;
                        continue;
                    }
                    
                    // Determine criticality
                    const is_critical = self.isCriticalPath(relative_path) or
                                       self.isUserFacingString(line);
                    
                    try result.issues.append(.{
                        .level = if (is_critical) .critical else .warning,
                        .file = relative_path,
                        .line = line_num,
                        .pattern = pattern,
                        .context = line,
                        .suggestion = "Replace with 'heimdall' variant",
                    });
                    
                    if (is_critical) {
                        result.critical_issues += 1;
                    } else {
                        result.warnings += 1;
                    }
                }
            }
        }
    }
    
    fn isWhitelisted(self: *Self, filename: []const u8, pattern: []const u8) bool {
        _ = pattern;
        for (self.whitelist.items) |entry| {
            if (entry.file) |file| {
                if (std.mem.eql(u8, filename, file)) return true;
            }
        }
        return false;
    }
    
    fn isWhitelistedContent(self: *Self, filename: []const u8, content: []const u8) bool {
        for (self.whitelist.items) |entry| {
            if (entry.file) |file| {
                if (std.mem.indexOf(u8, filename, file) != null) return true;
            }
            if (entry.pattern) |pattern| {
                if (std.mem.indexOf(u8, content, pattern) != null) return true;
            }
        }
        return false;
    }
    
    fn isCriticalPath(self: *Self, path: []const u8) bool {
        for (self.critical_paths.items) |critical| {
            if (std.mem.indexOf(u8, path, critical) != null) return true;
        }
        return false;
    }
    
    fn isUserFacingString(self: *Self, line: []const u8) bool {
        _ = self;
        // Check for common user-facing patterns
        return std.mem.indexOf(u8, line, "console.log") != null or
               std.mem.indexOf(u8, line, "print") != null or
               std.mem.indexOf(u8, line, "\"name\":") != null or
               std.mem.indexOf(u8, line, "description") != null or
               std.mem.indexOf(u8, line, "Welcome") != null or
               std.mem.indexOf(u8, line, "Usage:") != null or
               std.mem.indexOf(u8, line, "help") != null;
    }
    
    pub fn autoFix(self: *Self, result: *VerificationResult) !void {
        for (result.issues.items) |issue| {
            if (issue.level != .critical) continue;
            
            // Attempt to fix the issue
            try self.fixIssue(&issue);
        }
    }
    
    fn fixIssue(self: *Self, issue: *const Issue) !void {
        _ = self;
        // TODO: Implement auto-fix for each issue type
        std.debug.print("Would fix: {s} in {s}\n", .{ issue.pattern, issue.file });
    }
    
    pub fn deinit(self: *Self) void {
        self.whitelist.deinit();
        self.critical_paths.deinit();
    }
};

const WhitelistEntry = struct {
    pattern: ?[]const u8 = null,
    file: ?[]const u8 = null,
    reason: []const u8,
};