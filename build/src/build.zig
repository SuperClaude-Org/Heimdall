const std = @import("std");
const patcher = @import("patcher.zig");
const verifier = @import("verifier.zig");
const transformer = @import("transformer.zig");
const reporter = @import("reporter.zig");
const git_ops = @import("git.zig");
const config = @import("config.zig");

const BuildError = error{
    UpdateFailed,
    PrepareFailed,
    TransformFailed,
    VerificationFailed,
    CompilationFailed,
    ConfigError,
};

const StageResult = struct {
    success: bool,
    message: []const u8,  // Owned by the result, must be freed
    
    pub fn deinit(self: *StageResult, allocator: std.mem.Allocator) void {
        allocator.free(self.message);
    }
};

pub const BuildOrchestrator = struct {
    allocator: std.mem.Allocator,
    config: config.BuildConfig,
    reporter: reporter.Reporter,
    dry_run: bool = false,
    auto_fix: bool = false,
    force: bool = false,
    verbose: bool = false,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const build_config = try config.BuildConfig.load(allocator, "build/config/build.yaml");
        const build_reporter = reporter.Reporter.init(allocator);
        
        return Self{
            .allocator = allocator,
            .config = build_config,
            .reporter = build_reporter,
        };
    }

    pub fn runAll(self: *Self) !void {
        try self.printBanner();
        
        // Stage 1: Update
        try self.reporter.startStage("Update", "Updating fork/opencode");
        var update_result = try self.updateVendor();
        defer update_result.deinit(self.allocator);
        try self.reporter.endStage(update_result.success, update_result.message);
        if (!update_result.success and !self.force) return BuildError.UpdateFailed;

        // Stage 2: Prepare
        try self.reporter.startStage("Prepare", "Setting up build directory");
        var prepare_result = try self.prepareBuildDir();
        defer prepare_result.deinit(self.allocator);
        try self.reporter.endStage(prepare_result.success, prepare_result.message);
        if (!prepare_result.success) return BuildError.PrepareFailed;

        // Stage 3: Transform
        try self.reporter.startStage("Transform", "Applying patches and branding");
        var transform_result = try self.transform();
        defer transform_result.deinit(self.allocator);
        try self.reporter.endStage(transform_result.success, transform_result.message);
        if (!transform_result.success and !self.force) return BuildError.TransformFailed;

        // Stage 4: Verify
        try self.reporter.startStage("Verify", "Checking branding completeness");
        var verify_result = try self.verifyBranding();
        defer verify_result.deinit(self.allocator);
        try self.reporter.endStage(verify_result.success, verify_result.message);
        if (!verify_result.success and !self.force) return BuildError.VerificationFailed;

        // Stage 5: Build
        try self.reporter.startStage("Build", "Compiling Heimdall");
        var build_result = try self.buildHeimdall();
        defer build_result.deinit(self.allocator);
        try self.reporter.endStage(build_result.success, build_result.message);
        if (!build_result.success) return BuildError.CompilationFailed;

        // Stage 6: Finalize
        try self.reporter.startStage("Finalize", "Packaging and cleanup");
        var finalize_result = try self.finalize();
        defer finalize_result.deinit(self.allocator);
        try self.reporter.endStage(finalize_result.success, finalize_result.message);

        try self.reporter.printSummary();
    }

    fn printBanner(self: *Self) !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("\n", .{});
        try stdout.print("╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  \n", .{});
        try stdout.print("╠═╣║╣ ║║║║ ║║╠═╣║  ║  \n", .{});
        try stdout.print("╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝\n", .{});
        try stdout.print("Unified Build System v1.0\n\n", .{});
        
        if (self.dry_run) {
            try stdout.print("[DRY RUN MODE - No changes will be made]\n\n", .{});
        }
    }

    fn updateVendor(self: *Self) !StageResult {
        if (self.dry_run) {
            return StageResult{
                .success = true,
                .message = try self.allocator.dupe(u8, "Skipped (dry run)"),
            };
        }

        var git = git_ops.Git.init(self.allocator);
        defer git.deinit();

        // Check if vendor directory exists
        if (self.verbose) {
            std.debug.print("Checking vendor directory: {s}\n", .{self.config.source.path});
        }
        var vendor_dir = std.fs.cwd().openDir(self.config.source.path, .{}) catch |err| {
            if (self.verbose) {
                std.debug.print("Vendor directory check failed: {}\n", .{err});
            }
            return StageResult{
                .success = false,
                .message = try self.allocator.dupe(u8, "Vendor directory not found"),
            };
        };
        vendor_dir.close();

        // Check if it's a git repository
        const git_path = try std.fs.path.join(self.allocator, &[_][]const u8{ self.config.source.path, ".git" });
        defer self.allocator.free(git_path);
        
        if (std.fs.cwd().openDir(git_path, .{})) |git_dir| {
            var git_dir_mut = git_dir;
            git_dir_mut.close();
            // It's a git repo, proceed with git operations
        } else |_| {
            // Not a git repo, skip git operations
            return StageResult{
                .success = true,
                .message = try self.allocator.dupe(u8, "Vendor directory ready (no git operations needed)"),
            };
        }

        // Pull latest from upstream
        var result = try git.pullUpstream(
            self.config.source.repository,
            self.config.source.branch,
            self.config.source.path,
        );
        defer result.deinit(self.allocator);

        if (result.success) {
            var msg_buf: [256]u8 = undefined;
            const msg = try std.fmt.bufPrint(&msg_buf, "{d} files changed", .{result.files_changed});
            
            // Create a heap-allocated copy of the message
            const msg_copy = try self.allocator.dupe(u8, msg);
            
            return StageResult{
                .success = true,
                .message = msg_copy,
            };
        } else {
            // Create a copy of the error message for the result
            const error_msg = if (result.error_message) |msg|
                try self.allocator.dupe(u8, msg)
            else
                try self.allocator.dupe(u8, "Unknown error");
            
            return StageResult{
                .success = false,
                .message = error_msg,
            };
        }
    }

    fn prepareBuildDir(self: *Self) !StageResult {
        if (self.dry_run) {
            return StageResult{
                .success = true,
                .message = try self.allocator.dupe(u8, "Skipped (dry run)"),
            };
        }
        
        const build_path = self.config.build.temp_dir;
        
        // Remove existing build directory
        std.fs.cwd().deleteTree(build_path) catch {};

        // Create fresh build directory
        try std.fs.cwd().makePath(build_path);

        // Copy fork/opencode to .build/heimdall
        try self.copyDirectory(self.config.source.path, build_path);

        return StageResult{
            .success = true,
            .message = try self.allocator.dupe(u8, "Build directory ready"),
        };
    }

    fn transform(self: *Self) !StageResult {
        if (self.dry_run) {
            return StageResult{
                .success = true,
                .message = try self.allocator.dupe(u8, "Skipped (dry run)"),
            };
        }
        
        // Apply patches
        var patch_engine = patcher.Patcher.init(self.allocator);
        patch_engine.verbose = self.verbose;
        patch_engine.dry_run = self.dry_run;
        defer patch_engine.deinit();

        var patches_applied: usize = 0;
        var patches_failed: usize = 0;

        // Find and apply all patches
        const patches_dir = try std.fs.cwd().openDir(self.config.patches.directory, .{ .iterate = true });
        var iter = patches_dir.iterate();
        
        while (try iter.next()) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".hpatch.json")) {
                const patch_path = try std.fmt.allocPrint(
                    self.allocator,
                    "{s}/{s}",
                    .{ self.config.patches.directory, entry.name }
                );
                defer self.allocator.free(patch_path);

                // Apply patch to build directory
                const result = patch_engine.applyPatchFile(patch_path) catch |err| {
                    patches_failed += 1;
                    if (self.verbose) {
                        std.debug.print("Failed to apply {s}: {}\n", .{ entry.name, err });
                    }
                    continue;
                };

                if (result.success) {
                    patches_applied += 1;
                } else {
                    patches_failed += 1;
                    if (self.auto_fix) {
                        if (try self.attemptAutoFix(patch_path)) {
                            patches_applied += 1;
                            patches_failed -= 1;
                        }
                    }
                }
            }
        }

        // Apply additional transformations
        var trans = transformer.Transformer.init(self.allocator);
        defer trans.deinit();
        try trans.applyTransformations(self.config.build.temp_dir);

        var msg_buf: [256]u8 = undefined;
        const msg = try std.fmt.bufPrint(&msg_buf, "{d} patches applied, {d} failed", .{ patches_applied, patches_failed });
        
        return StageResult{
            .success = patches_failed == 0 or self.force,
            .message = try self.allocator.dupe(u8, msg),
        };
    }

    fn verifyBranding(self: *Self) !StageResult {
        if (self.dry_run) {
            return StageResult{
                .success = true,
                .message = try self.allocator.dupe(u8, "Skipped (dry run)"),
            };
        }
        
        var branding_verifier = try verifier.BrandingVerifier.init(self.allocator);
        defer branding_verifier.deinit();

        const result = try branding_verifier.verify(self.config.build.temp_dir);
        
        var msg_buf: [256]u8 = undefined;
        const msg = if (result.critical_issues == 0)
            try std.fmt.bufPrint(&msg_buf, "All branding verified (score: {d}%)", .{result.score})
        else
            try std.fmt.bufPrint(&msg_buf, "{d} critical issues found", .{result.critical_issues});
        
        return StageResult{
            .success = result.critical_issues == 0 or self.force,
            .message = try self.allocator.dupe(u8, msg),
        };
    }

    fn buildHeimdall(self: *Self) !StageResult {
        if (self.dry_run) {
            return StageResult{
                .success = true,
                .message = try self.allocator.dupe(u8, "Skipped (dry run)"),
            };
        }

        const build_dir = self.config.build.temp_dir;
        
        // Run bun install
        const install_result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "bun", "install" },
            .cwd = build_dir,
        });
        defer self.allocator.free(install_result.stdout);
        defer self.allocator.free(install_result.stderr);

        if (install_result.term.Exited != 0) {
            return StageResult{
                .success = false,
                .message = try self.allocator.dupe(u8, "Failed to install dependencies"),
            };
        }

        // Run bun build
        const build_result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "bun", "run", "build" },
            .cwd = build_dir,
        });
        defer self.allocator.free(build_result.stdout);
        defer self.allocator.free(build_result.stderr);

        if (build_result.term.Exited != 0) {
            return StageResult{
                .success = false,
                .message = try self.allocator.dupe(u8, "Build failed"),
            };
        }

        return StageResult{
            .success = true,
            .message = try self.allocator.dupe(u8, "Build successful"),
        };
    }

    fn finalize(self: *Self) !StageResult {
        if (self.dry_run) {
            return StageResult{
                .success = true,
                .message = try self.allocator.dupe(u8, "Skipped (dry run)"),
            };
        }
        
        const output_dir = self.config.build.output_dir;
        
        // Create output directory
        try std.fs.cwd().makePath(output_dir);

        // Copy built artifacts
        const artifacts = [_][]const u8{
            "bin/heimdall",
            "packages/opencode/dist",
            "packages/plugin/dist",
        };

        for (artifacts) |artifact| {
            const src = try std.fs.path.join(self.allocator, &[_][]const u8{ self.config.build.temp_dir, artifact });
            defer self.allocator.free(src);
            const dest = try std.fs.path.join(self.allocator, &[_][]const u8{ output_dir, artifact });
            defer self.allocator.free(dest);
            
            // Ensure destination directory exists
            if (std.fs.path.dirname(dest)) |dir| {
                try std.fs.cwd().makePath(dir);
            }
            
            // Copy file or directory
            std.fs.cwd().copyFile(src, std.fs.cwd(), dest, .{}) catch |err| {
                if (err == error.IsDir) {
                    try self.copyDirectory(src, dest);
                } else {
                    return err;
                }
            };
        }

        // Generate build report
        try self.reporter.saveReport("reports/build-report.json");

        return StageResult{
            .success = true,
            .message = try self.allocator.dupe(u8, "Build complete"),
        };
    }

    fn copyDirectory(self: *Self, src: []const u8, dest: []const u8) !void {
        // Simple recursive copy implementation
        const src_dir = try std.fs.cwd().openDir(src, .{ .iterate = true });
        try std.fs.cwd().makePath(dest);
        
        var walker = try src_dir.walk(self.allocator);
        defer walker.deinit();
        
        while (try walker.next()) |entry| {
            const src_path = try std.fs.path.join(self.allocator, &[_][]const u8{ src, entry.path });
            defer self.allocator.free(src_path);
            const dest_path = try std.fs.path.join(self.allocator, &[_][]const u8{ dest, entry.path });
            defer self.allocator.free(dest_path);
            
            switch (entry.kind) {
                .directory => try std.fs.cwd().makePath(dest_path),
                .file => try std.fs.cwd().copyFile(src_path, std.fs.cwd(), dest_path, .{}),
                else => {},
            }
        }
    }

    fn attemptAutoFix(self: *Self, patch_path: []const u8) !bool {
        // TODO: Implement intelligent auto-fix
        _ = self;
        _ = patch_path;
        return false;
    }

    pub fn deinit(self: *Self) void {
        self.config.deinit();
        self.reporter.deinit();
    }
};