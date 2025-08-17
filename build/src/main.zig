const std = @import("std");
const patcher = @import("patcher.zig");
const patch_format = @import("patch_format.zig");
const build = @import("build.zig");

const VERSION = "2.0.0";

const Command = enum {
    // Build commands
    build,
    update,
    transform,
    // Patch commands
    apply,
    verify,
    create,
    convert,
    list,
    info,
    rollback,
    // Utility commands
    help,
    version,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check binary name to determine mode
    const exe_name = std.fs.path.basename(args[0]);
    const is_build_mode = std.mem.indexOf(u8, exe_name, "build") != null;
    
    // If running as heimdall-build, go directly to build mode
    if (is_build_mode) {
        try runBuildMode(allocator, args[1..]);
        return;
    }

    // Otherwise, run as patcher
    // Default to apply command if no args
    if (args.len < 2) {
        try cmdApply(allocator, &[_][]const u8{});
        return;
    }

    const command = parseCommand(args[1]) catch {
        // If unknown command, assume it's apply with options
        if (std.mem.startsWith(u8, args[1], "--")) {
            try cmdApply(allocator, args[1..]);
            return;
        }
        try std.io.getStdErr().writer().print("Unknown command: {s}\n", .{args[1]});
        try printHelp();
        std.process.exit(1);
    };

    switch (command) {
        .build => try cmdBuild(allocator, args[2..]),
        .apply => try cmdApply(allocator, args[2..]),
        .verify => try cmdVerify(allocator, args[2..]),
        .create => try cmdCreate(allocator, args[2..]),
        .convert => try cmdConvert(allocator, args[2..]),
        .list => try cmdList(allocator),
        .info => try cmdInfo(allocator, args[2..]),
        .rollback => try cmdRollback(allocator, args[2..]),
        .help => try printHelp(),
        .version => try printVersion(),
        else => {
            try std.io.getStdErr().writer().print("Command not implemented yet\n", .{});
        },
    }
}

fn runBuildMode(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var orchestrator = try build.BuildOrchestrator.init(allocator);
    defer orchestrator.deinit();
    
    // Parse build-specific arguments
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--dry-run")) {
            orchestrator.dry_run = true;
        } else if (std.mem.eql(u8, arg, "--verbose") or std.mem.eql(u8, arg, "-v")) {
            orchestrator.verbose = true;
        } else if (std.mem.eql(u8, arg, "--force")) {
            orchestrator.force = true;
        } else if (std.mem.eql(u8, arg, "--auto-fix")) {
            orchestrator.auto_fix = true;
        } else if (std.mem.eql(u8, arg, "--help")) {
            try printBuildHelp();
            return;
        }
    }
    
    // Run the build
    orchestrator.runAll() catch |err| {
        try std.io.getStdErr().writer().print("Build failed: {}\n", .{err});
        std.process.exit(1);
    };
}

fn printBuildHelp() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  \n", .{});
    try stdout.print("╠═╣║╣ ║║║║ ║║╠═╣║  ║  \n", .{});
    try stdout.print("╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝\n", .{});
    try stdout.print("Unified Build System v1.0\n\n", .{});
    
    try stdout.print("USAGE:\n", .{});
    try stdout.print("  heimdall-build [options]\n\n", .{});
    
    try stdout.print("OPTIONS:\n", .{});
    try stdout.print("  --dry-run      Show what would be done without making changes\n", .{});
    try stdout.print("  --verbose, -v  Show detailed output\n", .{});
    try stdout.print("  --force        Continue even if errors occur\n", .{});
    try stdout.print("  --auto-fix     Attempt to automatically fix issues\n", .{});
    try stdout.print("  --help         Show this help message\n\n", .{});
    
    try stdout.print("STAGES:\n", .{});
    try stdout.print("  1. Update    - Pull latest fork/opencode from upstream\n", .{});
    try stdout.print("  2. Prepare   - Set up build directory\n", .{});
    try stdout.print("  3. Transform - Apply patches and branding\n", .{});
    try stdout.print("  4. Verify    - Check branding completeness\n", .{});
    try stdout.print("  5. Build     - Compile Heimdall\n", .{});
    try stdout.print("  6. Finalize  - Package and cleanup\n\n", .{});
}

fn parseCommand(cmd: []const u8) !Command {
    // Build commands
    if (std.mem.eql(u8, cmd, "build") or std.mem.eql(u8, cmd, "all")) return .build;
    if (std.mem.eql(u8, cmd, "update")) return .update;
    if (std.mem.eql(u8, cmd, "transform")) return .transform;
    // Patch commands
    if (std.mem.eql(u8, cmd, "apply")) return .apply;
    if (std.mem.eql(u8, cmd, "verify")) return .verify;
    if (std.mem.eql(u8, cmd, "create")) return .create;
    if (std.mem.eql(u8, cmd, "convert")) return .convert;
    if (std.mem.eql(u8, cmd, "list")) return .list;
    if (std.mem.eql(u8, cmd, "info")) return .info;
    if (std.mem.eql(u8, cmd, "rollback")) return .rollback;
    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "--help")) return .help;
    if (std.mem.eql(u8, cmd, "version") or std.mem.eql(u8, cmd, "--version")) return .version;
    return error.UnknownCommand;
}

fn cmdBuild(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var orchestrator = try build.BuildOrchestrator.init(allocator);
    defer orchestrator.deinit();

    // Parse arguments
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--dry-run")) {
            orchestrator.dry_run = true;
        } else if (std.mem.eql(u8, arg, "--auto-fix")) {
            orchestrator.auto_fix = true;
        } else if (std.mem.eql(u8, arg, "--force")) {
            orchestrator.force = true;
        } else if (std.mem.eql(u8, arg, "--verbose") or std.mem.eql(u8, arg, "-v")) {
            orchestrator.verbose = true;
            orchestrator.reporter.verbose = true;
        }
    }

    // Run the build pipeline
    orchestrator.runAll() catch |err| {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("\n❌ Build failed: {s}\n", .{@errorName(err)});
        
        if (!orchestrator.verbose) {
            try stderr.print("Run with --verbose for more details\n", .{});
        }
        
        std.process.exit(1);
    };
}

fn cmdUpdate(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    _ = args;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Update command - coming soon!\n", .{});
    try stdout.print("For now, use: heimdall-build\n", .{});
}

fn cmdTransform(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    _ = args;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Transform command - coming soon!\n", .{});
    try stdout.print("For now, use: heimdall-build\n", .{});
}

fn cmdApply(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var patch_engine = patcher.Patcher.init(allocator);
    defer patch_engine.deinit();

    var patch_files = std.ArrayList([]const u8).init(allocator);
    defer patch_files.deinit();

    // Parse arguments
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--dry-run")) {
            patch_engine.dry_run = true;
        } else if (std.mem.eql(u8, args[i], "--verbose") or std.mem.eql(u8, args[i], "-v")) {
            patch_engine.verbose = true;
        } else if (std.mem.eql(u8, args[i], "--no-backup")) {
            patch_engine.backup = false;
        } else if (std.mem.eql(u8, args[i], "--backup-dir")) {
            i += 1;
            if (i >= args.len) {
                try std.io.getStdErr().writer().print("--backup-dir requires an argument\n", .{});
                std.process.exit(1);
            }
            patch_engine.backup_dir = args[i];
        } else if (!std.mem.startsWith(u8, args[i], "--")) {
            try patch_files.append(args[i]);
        }
    }

    // If no patch files specified, look for all .hpatch.json files in patches/
    if (patch_files.items.len == 0) {
        try findPatchFiles(allocator, &patch_files);
    }

    if (patch_files.items.len == 0) {
        try std.io.getStdErr().writer().print("No patch files found\n", .{});
        std.process.exit(1);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  \n", .{});
    try stdout.print("╠═╣║╣ ║║║║ ║║╠═╣║  ║  \n", .{});
    try stdout.print("╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝\n", .{});
    try stdout.print("Intelligent Patcher v{s}\n\n", .{VERSION});

    if (patch_engine.dry_run) {
        try stdout.print("[DRY RUN MODE]\n\n", .{});
    }

    var total_modified: usize = 0;
    var total_failed: usize = 0;

    for (patch_files.items) |patch_file| {
        try stdout.print("Applying patch: {s}\n", .{patch_file});
        
        const result = patch_engine.applyPatchFile(patch_file) catch |err| {
            try std.io.getStdErr().writer().print("Failed to apply {s}: {s}\n", .{ patch_file, @errorName(err) });
            continue;
        };

        total_modified += result.files_modified;
        total_failed += result.files_failed;

        if (result.success) {
            try stdout.print("  ✓ Success: {d} files modified\n", .{result.files_modified});
        } else {
            try stdout.print("  ⚠ Partial success: {d} modified, {d} failed\n", .{ result.files_modified, result.files_failed });
            for (result.errors) |err| {
                try stdout.print("    ✗ {s}: {s}\n", .{ err.file, err.message });
            }
        }
    }

    try stdout.print("\nSummary: {d} files modified, {d} failed\n", .{ total_modified, total_failed });
    
    if (total_failed > 0) {
        std.process.exit(1);
    }
}

fn cmdVerify(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var patch_engine = patcher.Patcher.init(allocator);
    patch_engine.dry_run = true; // Always dry run for verify
    patch_engine.verbose = true;
    defer patch_engine.deinit();

    var patch_files = std.ArrayList([]const u8).init(allocator);
    defer patch_files.deinit();

    for (args) |arg| {
        if (!std.mem.startsWith(u8, arg, "--")) {
            try patch_files.append(arg);
        }
    }

    if (patch_files.items.len == 0) {
        try findPatchFiles(allocator, &patch_files);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Verifying patches...\n\n", .{});

    var all_valid = true;
    for (patch_files.items) |patch_file| {
        try stdout.print("Checking: {s}\n", .{patch_file});
        
        const result = patch_engine.applyPatchFile(patch_file) catch |err| {
            try stdout.print("  ✗ Invalid: {s}\n", .{@errorName(err)});
            all_valid = false;
            continue;
        };

        if (result.success) {
            try stdout.print("  ✓ Valid: All changes can be applied\n", .{});
        } else {
            try stdout.print("  ✗ Invalid: {d} changes would fail\n", .{result.files_failed});
            all_valid = false;
        }
    }

    if (!all_valid) {
        std.process.exit(1);
    }
}

fn cmdCreate(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    if (args.len < 1) {
        try std.io.getStdErr().writer().print("Usage: heimdall-patcher create <name>\n", .{});
        std.process.exit(1);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Creating patch: {s}\n", .{args[0]});
    try stdout.print("This feature is coming soon!\n", .{});
    try stdout.print("For now, create patches manually in JSON format.\n", .{});
}

fn cmdConvert(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    if (args.len < 1) {
        try std.io.getStdErr().writer().print("Usage: heimdall-patcher convert <old-patch>\n", .{});
        std.process.exit(1);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Converting patch: {s}\n", .{args[0]});
    try stdout.print("This feature is coming soon!\n", .{});
}

fn cmdList(allocator: std.mem.Allocator) !void {
    var patch_files = std.ArrayList([]const u8).init(allocator);
    defer patch_files.deinit();

    try findPatchFiles(allocator, &patch_files);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Available patches:\n\n", .{});

    for (patch_files.items) |patch_file| {
        // Try to read and parse to get description
        const file = std.fs.cwd().openFile(patch_file, .{}) catch continue;
        defer file.close();

        const content = file.readToEndAlloc(allocator, 1024 * 1024) catch continue;
        defer allocator.free(content);

        var patch = patch_format.PatchFile.parse(allocator, content) catch {
            try stdout.print("  • {s}\n", .{patch_file});
            continue;
        };
        defer patch.deinit(allocator);

        try stdout.print("  • {s}: {s}\n", .{ patch.name, patch.description });
    }
}

fn cmdInfo(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len < 1) {
        try std.io.getStdErr().writer().print("Usage: heimdall-patcher info <patch>\n", .{});
        std.process.exit(1);
    }

    const file = try std.fs.cwd().openFile(args[0], .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    var patch = try patch_format.PatchFile.parse(allocator, content);
    defer patch.deinit(allocator);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Patch: {s}\n", .{patch.name});
    try stdout.print("Version: {s}\n", .{patch.version});
    try stdout.print("Description: {s}\n", .{patch.description});
    
    if (patch.compatibility) |compat| {
        try stdout.print("\nCompatibility:\n", .{});
        if (compat.opencode) |ver| {
            try stdout.print("  OpenCode: {s}\n", .{ver});
        }
        if (compat.test_command) |cmd| {
            try stdout.print("  Test: {s}\n", .{cmd});
        }
    }

    try stdout.print("\nPatches: {d}\n", .{patch.patches.len});
    for (patch.patches) |p| {
        try stdout.print("  • {s}", .{p.id});
        if (p.description) |desc| {
            try stdout.print(": {s}", .{desc});
        }
        try stdout.print("\n", .{});
    }
}

fn cmdRollback(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    _ = args;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Rollback feature coming soon!\n", .{});
    try stdout.print("Backups are stored in .heimdall-backup/\n", .{});
}

fn findPatchFiles(allocator: std.mem.Allocator, list: *std.ArrayList([]const u8)) !void {
    // Get the directory where the binary is located
    const exe_path = try std.fs.selfExePathAlloc(allocator);
    defer allocator.free(exe_path);
    
    const exe_dir = std.fs.path.dirname(exe_path) orelse ".";
    
    // Look for patches in ../patches relative to binary location (build/bin/../patches = build/patches)
    const patches_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "..", "patches" });
    defer allocator.free(patches_path);
    
    const patches_dir = std.fs.openDirAbsolute(patches_path, .{ .iterate = true }) catch |err| {
        // Fallback to build/patches from current directory
        const alt_dir = std.fs.cwd().openDir("build/patches", .{ .iterate = true }) catch {
            // Final fallback to patches/ from current directory
            const final_dir = std.fs.cwd().openDir("patches", .{ .iterate = true }) catch {
                return err;
            };
            var iter = final_dir.iterate();
            while (try iter.next()) |entry| {
                if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".hpatch.json")) {
                    const full_path = try std.fmt.allocPrint(allocator, "patches/{s}", .{entry.name});
                    try list.append(full_path);
                }
            }
            return;
        };
        var iter = alt_dir.iterate();
        while (try iter.next()) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".hpatch.json")) {
                const full_path = try std.fmt.allocPrint(allocator, "build/patches/{s}", .{entry.name});
                try list.append(full_path);
            }
        }
        return;
    };

    var iter = patches_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".hpatch.json")) {
            // Use absolute path for patches found relative to binary
            const full_path = try std.fs.path.join(allocator, &[_][]const u8{ patches_path, entry.name });
            try list.append(full_path);
        }
    }
}

fn printHelp() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(
        \\╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  
        \\╠═╣║╣ ║║║║ ║║╠═╣║  ║  
        \\╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝
        \\Intelligent Patcher v{s}
        \\
        \\USAGE:
        \\  heimdall-patcher <command> [options]
        \\
        \\COMMANDS:
        \\  apply [patches...]     Apply patches (default: all in patches/)
        \\    --dry-run           Show what would change without modifying
        \\    --verbose, -v       Show detailed output
        \\    --no-backup         Don't create backups
        \\    --backup-dir <dir>  Backup directory (default: .heimdall-backup)
        \\
        \\  verify [patches...]    Verify patches can be applied
        \\  create <name>          Create a new patch interactively
        \\  convert <old-patch>    Convert old format to new format
        \\  list                   List available patches
        \\  info <patch>           Show patch details
        \\  rollback <patch>       Rollback a patch using backups
        \\  help                   Show this help
        \\  version                Show version
        \\
        \\EXAMPLES:
        \\  heimdall-patcher apply --dry-run
        \\  heimdall-patcher apply patches/heimdall-branding.hpatch.json
        \\  heimdall-patcher verify
        \\  heimdall-patcher info patches/heimdall-branding.hpatch.json
        \\
    , .{VERSION});
}

fn printVersion() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("heimdall-patcher v{s}\n", .{VERSION});
}