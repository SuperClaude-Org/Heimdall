const std = @import("std");

pub const Reporter = struct {
    allocator: std.mem.Allocator,
    stages: std.ArrayList(Stage),
    start_time: i64,
    current_stage: ?*Stage = null,
    verbose: bool = false,
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .stages = std.ArrayList(Stage).init(allocator),
            .start_time = std.time.milliTimestamp(),
        };
    }
    
    pub fn startStage(self: *Self, name: []const u8, description: []const u8) !void {
        const stage_num = self.stages.items.len + 1;
        const total_stages = 6; // We know we have 6 stages
        
        const stdout = std.io.getStdOut().writer();
        try stdout.print("[{d}/{d}] {s}...\n", .{ stage_num, total_stages, name });
        
        if (self.verbose) {
            try stdout.print("  {s}\n", .{description});
        }
        
        const stage = Stage{
            .name = try self.allocator.dupe(u8, name),
            .description = try self.allocator.dupe(u8, description),
            .start_time = std.time.milliTimestamp(),
            .end_time = null,
            .success = false,
            .message = null,
        };
        
        try self.stages.append(stage);
        self.current_stage = &self.stages.items[self.stages.items.len - 1];
    }
    
    pub fn endStage(self: *Self, success: bool, message: []const u8) !void {
        if (self.current_stage) |stage| {
            stage.end_time = std.time.milliTimestamp();
            stage.success = success;
            stage.message = try self.allocator.dupe(u8, message);
            
            const stdout = std.io.getStdOut().writer();
            const symbol = if (success) "✓" else "✗";
            const color = if (success) "\x1b[32m" else "\x1b[31m";
            const reset = "\x1b[0m";
            
            try stdout.print("  {s}{s}{s} {s}\n", .{ color, symbol, reset, message });
            
            if (stage.end_time) |end| {
                const duration = end - stage.start_time;
                if (self.verbose and duration > 100) {
                    try stdout.print("  Time: {d}ms\n", .{duration});
                }
            }
        }
        
        self.current_stage = null;
    }
    
    pub fn printSummary(self: *Self) !void {
        const stdout = std.io.getStdOut().writer();
        const total_time = std.time.milliTimestamp() - self.start_time;
        
        try stdout.print("\n", .{});
        
        var all_success = true;
        for (self.stages.items) |stage| {
            if (!stage.success) {
                all_success = false;
                break;
            }
        }
        
        if (all_success) {
            try stdout.print("\x1b[32m✅ Build successful!\x1b[0m\n", .{});
            try stdout.print("   Time: {d:.1}s\n", .{@as(f64, @floatFromInt(total_time)) / 1000.0});
            try stdout.print("   Output: dist/heimdall\n", .{});
            try stdout.print("   Run: ./dist/heimdall --help\n", .{});
        } else {
            try stdout.print("\x1b[31m❌ Build failed!\x1b[0m\n", .{});
            try stdout.print("\nFailed stages:\n", .{});
            for (self.stages.items) |stage| {
                if (!stage.success) {
                    try stdout.print("  - {s}: {s}\n", .{ stage.name, stage.message orelse "Unknown error" });
                }
            }
            try stdout.print("\nRun with --verbose for more details\n", .{});
        }
    }
    
    pub fn reportConflict(_: *Self, patch_name: []const u8, details: ConflictDetails) !void {
        const stdout = std.io.getStdOut().writer();
        
        try stdout.print("\n", .{});
        try stdout.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});
        try stdout.print("CONFLICT DETECTED\n", .{});
        try stdout.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});
        try stdout.print("Patch: {s}\n", .{patch_name});
        try stdout.print("File: {s}\n", .{details.file});
        
        if (details.line) |line| {
            try stdout.print("Line: {d}\n", .{line});
        }
        
        try stdout.print("\nExpected Context:\n", .{});
        try stdout.print("  {s}\n", .{details.expected});
        
        try stdout.print("\nActual Context:\n", .{});
        try stdout.print("  {s}\n", .{details.actual});
        
        if (details.suggestion) |suggestion| {
            try stdout.print("\nSuggested Fix:\n", .{});
            try stdout.print("  {s}\n", .{suggestion});
        }
        
        if (details.confidence) |confidence| {
            try stdout.print("\nAuto-Fix Confidence: {d}%\n", .{confidence});
            if (confidence >= 80) {
                try stdout.print("  Run with --auto-fix to apply\n", .{});
            }
        }
        
        try stdout.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});
    }
    
    pub fn saveReport(self: *Self, path: []const u8) !void {
        // Ensure reports directory exists
        std.fs.cwd().makeDir("reports") catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        
        var json_writer = std.json.writeStream(file.writer(), .{ .whitespace = .indent_2 });
        
        try json_writer.beginObject();
        
        try json_writer.objectField("timestamp");
        try json_writer.write(std.time.milliTimestamp());
        
        try json_writer.objectField("total_time_ms");
        try json_writer.write(std.time.milliTimestamp() - self.start_time);
        
        try json_writer.objectField("success");
        var success = true;
        for (self.stages.items) |stage| {
            if (!stage.success) {
                success = false;
                break;
            }
        }
        try json_writer.write(success);
        
        try json_writer.objectField("stages");
        try json_writer.beginArray();
        for (self.stages.items) |stage| {
            try json_writer.beginObject();
            try json_writer.objectField("name");
            try json_writer.write(stage.name);
            try json_writer.objectField("success");
            try json_writer.write(stage.success);
            if (stage.message) |msg| {
                try json_writer.objectField("message");
                try json_writer.write(msg);
            }
            if (stage.end_time) |end| {
                try json_writer.objectField("duration_ms");
                try json_writer.write(end - stage.start_time);
            }
            try json_writer.endObject();
        }
        try json_writer.endArray();
        
        try json_writer.endObject();
    }
    
    pub fn deinit(self: *Self) void {
        for (self.stages.items) |*stage| {
            self.allocator.free(stage.name);
            self.allocator.free(stage.description);
            if (stage.message) |msg| {
                self.allocator.free(msg);
            }
        }
        self.stages.deinit();
    }
};

const Stage = struct {
    name: []u8,
    description: []u8,
    start_time: i64,
    end_time: ?i64,
    success: bool,
    message: ?[]u8,
};

pub const ConflictDetails = struct {
    file: []const u8,
    line: ?usize = null,
    expected: []const u8,
    actual: []const u8,
    suggestion: ?[]const u8 = null,
    confidence: ?u32 = null,
};