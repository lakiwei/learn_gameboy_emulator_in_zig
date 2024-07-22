const Emulator = @import("emulator.zig").Emulator;
const Cartridge = @import("cartridge.zig").Cartridge;

const rl = @import("raylib");
const std = @import("std");

const log = struct {
    const d = std.log.debug;
    const e = std.log.err;
    const i = std.log.info;
    const w = std.log.warn;
};

pub fn load_rom(allocator: std.mem.Allocator) ![]u8 {
    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();

    _ = args.next();
    const path = args.next().?;

    const realpath = try std.fs.realpathAlloc(allocator, path);
    defer allocator.free(realpath);

    const file = try std.fs.openFileAbsolute(realpath, .{});
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;

    const buffer = try file.readToEndAlloc(allocator, size);

    return buffer;
}

const Timer = struct {
    c: f64,
    d: f64,
    p: f64,

    pub fn init(ptr: anytype) *Timer {
        const timer: *Timer = @ptrFromInt(@intFromPtr(ptr));

        timer.c = rl.getTime();
        timer.d = 0.0;
        timer.p = 0.0;

        return timer;
    }

    pub fn update(t: *Timer) void {
        t.p = t.c;
        t.c = rl.getTime();
        t.d = t.c - t.p;
    }
};

pub fn run() anyerror!void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer log.d("{}", .{general_purpose_allocator.deinit()});
    const allocator = general_purpose_allocator.allocator();

    const screenWidth = 800;
    const screenHeight = 450;

    const buffer = try load_rom(allocator);
    defer allocator.free(buffer);

    var emulator: Emulator = undefined;
    _ = Emulator.init(&emulator);

    emulator.clock.scale(0.001);

    emulator.cartridge.set(buffer);
    const header = emulator.cartridge.header;

    log.d("title:   {s}", .{header.title});
    log.d("type:    {s}", .{header.type_name()});
    log.d("rom:     {d}", .{@as(u32, 32) << @truncate(header.rom_size)});
    log.d("ram:     {s}", .{header.ram_size_name()});
    log.d("lic:     {s}", .{header.lic_code_name()});
    log.d("version: {d}", .{header.version});

    rl.initWindow(screenWidth, screenHeight, "window");
    defer rl.closeWindow();

    var timer: Timer = undefined;
    _ = Timer.init(&timer);

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        log.d("update start", .{});

        timer.update();
        emulator.update(timer.d);

        log.d("update end", .{});

        rl.clearBackground(rl.Color.white);
        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
    }
}

pub fn main() anyerror!void {
    try run();
}
