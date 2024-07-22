const Cartridge = @import("cartridge.zig").Cartridge;
const CPU = @import("cpu.zig").CPU;

pub const Clock = struct {
    const freq: f64 = 4194304;
    const rate: f64 = 4;

    s: f64,
    c: u64,
    t: u64,

    pub fn init(ptr: anytype) *Clock {
        const clock: *Clock = @ptrFromInt(@intFromPtr(ptr));

        clock.s = 1.0;
        clock.c = 0;
        clock.t = 0;

        return clock;
    }

    pub fn delta(c: *Clock, d: f64) void {
        const t: u64 = @intFromFloat(c.s * d * Clock.freq);
        c.t = c.t + t;
    }

    pub fn forward(c: *Clock, t: u64) void {
        c.c += t;
    }

    pub fn scale(c: *Clock, s: f64) void {
        if (s >= 0) {
            c.s = s;
        }
    }

    pub fn check(c: *Clock) bool {
        return c.c < c.t;
    }
};

pub const Bus = struct {
    emulator: *Emulator,

    pub fn init(ptr: anytype) *Bus {
        const bus: *Bus = @ptrFromInt(@intFromPtr(ptr));
        return bus;
    }

    pub fn read(bus: *Bus, addr: u16) u8 {
        _ = bus;
        _ = addr;
        return 0;
    }

    pub fn write(addr: u16, data: u8) void {
        _ = addr;
        _ = data;
    }
};

pub const Emulator = struct {
    clock: Clock,
    bus: Bus,
    cpu: CPU,

    vram: [8 * 1024]u8,
    wram: [8 * 1024]u8,
    hram: [128]u8,

    cartridge: Cartridge,

    pub fn init(ptr: anytype) *Emulator {
        const emulator: *Emulator = @ptrFromInt(@intFromPtr(ptr));

        _ = Clock.init(&(emulator.clock));
        _ = Bus.init(&(emulator.bus));
        _ = CPU.init(&(emulator.cpu));

        emulator.bus.emulator = emulator;
        emulator.cpu.bus = &(emulator.bus);
        emulator.cpu.clock = &(emulator.clock);

        _ = Cartridge.init(&(emulator.cartridge));

        return emulator;
    }

    pub fn update(emulator: *Emulator, dt: f64) void {
        emulator.clock.delta(dt);
        while (emulator.clock.check()) {
            emulator.cpu.step();
        }
    }
};
