const std = @import("std");

pub const Transformer = struct {
    allocator: std.mem.Allocator,
    transformations: std.ArrayList(Transformation),
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .transformations = std.ArrayList(Transformation).init(allocator),
        };
    }
    
    pub fn applyTransformations(self: *Self, build_dir: []const u8) !void {
        // Load default transformations
        try self.loadDefaultTransformations();
        
        // Apply each transformation
        for (self.transformations.items) |trans| {
            try self.applyTransformation(build_dir, &trans);
        }
        
        // Special handling for package.json files
        try self.transformPackageJsonFiles(build_dir);
        
        // Update workspace references
        try self.updateWorkspaceReferences(build_dir);
        
        // Rename binary files
        try self.renameBinaryFiles(build_dir);
    }
    
    fn loadDefaultTransformations(self: *Self) !void {
        // Add default branding transformations
        try self.transformations.append(.{
            .from = "opencode",
            .to = "heimdall",
            .case_sensitive = true,
        });
        try self.transformations.append(.{
            .from = "OpenCode",
            .to = "Heimdall",
            .case_sensitive = true,
        });
        try self.transformations.append(.{
            .from = "OPENCODE",
            .to = "HEIMDALL",
            .case_sensitive = true,
        });
        try self.transformations.append(.{
            .from = "Opencode",
            .to = "Heimdall",
            .case_sensitive = true,
        });
    }
    
    fn applyTransformation(self: *Self, dir: []const u8, trans: *const Transformation) !void {
        const cwd = try std.fs.cwd().openDir(dir, .{ .iterate = true });
        
        var walker = try cwd.walk(self.allocator);
        defer walker.deinit();
        
        while (try walker.next()) |entry| {
            if (entry.kind != .file) continue;
            
            // Skip binary and image files
            if (self.shouldSkipFile(entry.path)) continue;
            
            const full_path = try std.fs.path.join(self.allocator, &[_][]const u8{ dir, entry.path });
            defer self.allocator.free(full_path);
            
            try self.transformFile(full_path, trans);
        }
    }
    
    fn transformFile(self: *Self, path: []const u8, trans: *const Transformation) !void {
        // Read file
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        
        const stat = try file.stat();
        if (stat.size > 10 * 1024 * 1024) return; // Skip large files
        
        const contents = try file.readToEndAlloc(self.allocator, @intCast(stat.size));
        defer self.allocator.free(contents);
        
        // Perform replacements
        var modified = false;
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();
        
        var i: usize = 0;
        while (i < contents.len) {
            if (self.matchesPattern(contents[i..], trans.from)) {
                try result.appendSlice(trans.to);
                i += trans.from.len;
                modified = true;
            } else {
                try result.append(contents[i]);
                i += 1;
            }
        }
        
        // Write back if modified
        if (modified) {
            const out_file = try std.fs.cwd().createFile(path, .{});
            defer out_file.close();
            try out_file.writeAll(result.items);
        }
    }
    
    fn matchesPattern(self: *Self, text: []const u8, pattern: []const u8) bool {
        _ = self;
        if (text.len < pattern.len) return false;
        return std.mem.eql(u8, text[0..pattern.len], pattern);
    }
    
    fn transformPackageJsonFiles(self: *Self, build_dir: []const u8) !void {
        // Find all package.json files
        const cwd = try std.fs.cwd().openDir(build_dir, .{ .iterate = true });
        
        var walker = try cwd.walk(self.allocator);
        defer walker.deinit();
        
        while (try walker.next()) |entry| {
            if (entry.kind == .file and std.mem.eql(u8, std.fs.path.basename(entry.path), "package.json")) {
                const full_path = try std.fs.path.join(self.allocator, &[_][]const u8{ build_dir, entry.path });
                defer self.allocator.free(full_path);
                
                try self.transformPackageJson(full_path);
            }
        }
    }
    
    fn transformPackageJson(self: *Self, path: []const u8) !void {
        // Read package.json
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        
        const stat = try file.stat();
        const contents = try file.readToEndAlloc(self.allocator, @intCast(stat.size));
        defer self.allocator.free(contents);
        
        // Simple string replacement for package.json
        var buffer = try self.allocator.alloc(u8, contents.len * 2);
        defer self.allocator.free(buffer);
        
        // Replace package name
        var len = contents.len;
        const count1 = std.mem.replace(u8, contents, "\"opencode\"", "\"heimdall\"", buffer);
        if (count1 > 0) {
            len = contents.len - (count1 * 9) + (count1 * 9); // Same length
        }
        
        // Replace workspace references
        var buffer2 = try self.allocator.alloc(u8, len * 2);
        defer self.allocator.free(buffer2);
        const count2 = std.mem.replace(u8, buffer[0..len], "opencode@workspace", "heimdall@workspace", buffer2);
        
        if (count1 > 0 or count2 > 0) {
            const final_len = len - (count2 * 18) + (count2 * 18); // Same length
            const out_file = try std.fs.cwd().createFile(path, .{});
            defer out_file.close();
            try out_file.writeAll(buffer2[0..final_len]);
        }
    }
    
    fn updateWorkspaceReferences(self: *Self, build_dir: []const u8) !void {
        // Update workspace references in package.json files
        const packages_dir = try std.fs.path.join(self.allocator, &[_][]const u8{ build_dir, "packages" });
        defer self.allocator.free(packages_dir);
        
        const dir = std.fs.cwd().openDir(packages_dir, .{ .iterate = true }) catch return;
        
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            if (entry.kind == .directory) {
                const pkg_json = try std.fs.path.join(
                    self.allocator,
                    &[_][]const u8{ packages_dir, entry.name, "package.json" }
                );
                defer self.allocator.free(pkg_json);
                
                // Update workspace references
                self.updateWorkspaceInFile(pkg_json) catch continue;
            }
        }
    }
    
    fn updateWorkspaceInFile(self: *Self, path: []const u8) !void {
        const file = std.fs.cwd().openFile(path, .{}) catch return;
        defer file.close();
        
        const stat = try file.stat();
        const contents = try file.readToEndAlloc(self.allocator, @intCast(stat.size));
        defer self.allocator.free(contents);
        
        const modified = try self.allocator.dupe(u8, contents);
        defer self.allocator.free(modified);
        
        // Replace workspace references
        _ = std.mem.replace(u8, modified, "\"opencode\": \"workspace:", "\"heimdall\": \"workspace:", modified);
        
        const out_file = try std.fs.cwd().createFile(path, .{});
        defer out_file.close();
        try out_file.writeAll(modified);
    }
    
    fn renameBinaryFiles(self: *Self, build_dir: []const u8) !void {
        const bin_dir = try std.fs.path.join(self.allocator, &[_][]const u8{ build_dir, "packages/opencode/bin" });
        defer self.allocator.free(bin_dir);
        
        const dir = std.fs.cwd().openDir(bin_dir, .{}) catch return;
        
        // Rename opencode -> heimdall
        dir.rename("opencode", "heimdall") catch {};
        dir.rename("opencode.cmd", "heimdall.cmd") catch {};
        dir.rename("opencode.ps1", "heimdall.ps1") catch {};
    }
    
    fn shouldSkipFile(self: *Self, path: []const u8) bool {
        _ = self;
        const extensions = [_][]const u8{
            ".png", ".jpg", ".jpeg", ".gif", ".ico",
            ".woff", ".woff2", ".ttf", ".otf",
            ".exe", ".dll", ".so", ".dylib",
            ".zip", ".tar", ".gz", ".bz2",
            ".mp3", ".mp4", ".avi", ".mov",
            ".pdf", ".doc", ".docx",
        };
        
        for (extensions) |ext| {
            if (std.mem.endsWith(u8, path, ext)) return true;
        }
        
        // Skip node_modules and .git
        if (std.mem.indexOf(u8, path, "node_modules/") != null) return true;
        if (std.mem.indexOf(u8, path, ".git/") != null) return true;
        
        return false;
    }
    
    pub fn deinit(self: *Self) void {
        self.transformations.deinit();
    }
};

const Transformation = struct {
    from: []const u8,
    to: []const u8,
    case_sensitive: bool = true,
};