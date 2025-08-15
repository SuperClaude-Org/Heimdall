const std = @import("std");

pub const BuildConfig = struct {
    source: SourceSettings,
    build: BuildSettings,
    patches: PatchSettings,
    allocator: std.mem.Allocator,
    
    pub fn load(allocator: std.mem.Allocator, path: []const u8) !BuildConfig {
        // Default path if not specified
        const config_path = if (std.mem.eql(u8, path, "config/build.yaml"))
            "build/config/build.yaml"
        else
            path;
            
        const file = try std.fs.cwd().openFile(config_path, .{});
        defer file.close();

        // For now, return default configuration
        // TODO: Implement YAML parsing
        _ = path;
        
        return BuildConfig{
            .source = SourceSettings{
                .repository = "https://github.com/opencode/opencode.git",
                .branch = "main",
                .path = "/home/anton/opencode-heimdall/vendor/opencode",
            },
            .build = BuildSettings{
                .temp_dir = ".build/heimdall",
                .output_dir = "dist",
                .clean_after_build = true,
            },
            .patches = PatchSettings{
                .directory = "build/patches",
                .auto_fix = false,
                .backup = true,
            },
            .allocator = allocator,
        };
    }
    
    pub fn loadFromString(allocator: std.mem.Allocator, content: []const u8) !BuildConfig {
        // Parse YAML/JSON content
        // For now, return default
        _ = content;
        return load(allocator, "");
    }
    
    pub fn deinit(self: *BuildConfig) void {
        // Free allocated memory if needed
        _ = self;
    }
};

pub const SourceSettings = struct {
    repository: []const u8,
    branch: []const u8,
    path: []const u8,
};

pub const BuildSettings = struct {
    temp_dir: []const u8,
    output_dir: []const u8,
    clean_after_build: bool,
};

pub const PatchSettings = struct {
    directory: []const u8,
    auto_fix: bool,
    backup: bool,
};

pub const BrandingConfig = struct {
    transformations: []Transformation,
    whitelist: []WhitelistEntry,
    critical_paths: [][]const u8,
    
    pub fn loadDefault(allocator: std.mem.Allocator) !BrandingConfig {
        _ = allocator;
        return BrandingConfig{
            .transformations = &[_]Transformation{
                .{ .from = "opencode", .to = "heimdall" },
                .{ .from = "OpenCode", .to = "Heimdall" },
                .{ .from = "OPENCODE", .to = "HEIMDALL" },
            },
            .whitelist = &[_]WhitelistEntry{
                .{ .pattern = "github.com/sst/opencode", .reason = "Original repository" },
                .{ .pattern = "Copyright.*OpenCode", .reason = "Legal attribution" },
            },
            .critical_paths = &[_][]const u8{
                "package.json",
                "bin/",
                "src/cli/",
                "README.md",
            },
        };
    }
};

pub const Transformation = struct {
    from: []const u8,
    to: []const u8,
};

pub const WhitelistEntry = struct {
    pattern: []const u8,
    reason: []const u8,
};