const Bus = @import("emulator.zig").Bus;
const Clock = @import("emulator.zig").Clock;

fn x00_nop(cpu: *CPU, bus: *Bus, clock: *Clock) void {
    _ = cpu;
    _ = bus;

    clock.forward(1);

    return;
}

fn make_instructions() [0x100]*const fn (cpu: *CPU, bus: *Bus, clock: *Clock) void {
    var l: [0x100]*const fn (cpu: *CPU, bus: *Bus, clock: *Clock) void = undefined;

    for (l, 0..) |_, i| {
        l[i] = undefined;
    }

    l[0x00] = x00_nop;

    return l;
}

const instructions = make_instructions();

pub const CPU = struct {
    a: u8,
    f: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    h: u8,
    l: u8,
    sp: u16,
    pc: u16,
    halted: bool,

    bus: *Bus,
    clock: *Clock,

    pub fn get_af(cpu: *const CPU) u16 {
        return (@as(u16, cpu.a) << 8) + cpu.f;
    }

    pub fn get_bc(cpu: *const CPU) u16 {
        return (@as(u16, cpu.b) << 8) + cpu.c;
    }

    pub fn get_de(cpu: *const CPU) u16 {
        return (@as(u16, cpu.d) << 8) + cpu.e;
    }

    pub fn get_hl(cpu: *const CPU) u16 {
        return (@as(u16, cpu.h) << 8) + cpu.l;
    }

    pub fn set_af(cpu: *CPU, v: u16) void {
        cpu.a = @as(u8, v >> 8);
        cpu.f = @as(u8, v & 0xf0);
    }

    pub fn set_bc(cpu: *CPU, v: u16) void {
        cpu.b = @as(u8, v >> 8);
        cpu.c = @as(u8, v & 0xff);
    }

    pub fn set_de(cpu: *CPU, v: u16) void {
        cpu.d = @as(u8, v >> 8);
        cpu.e = @as(u8, v & 0xff);
    }

    pub fn set_hl(cpu: *CPU, v: u16) void {
        cpu.h = @as(u8, v >> 8);
        cpu.l = @as(u8, v & 0xff);
    }

    pub fn get_fz(cpu: *const CPU) bool {
        return cpu.f & 0x80 != 0;
    }

    pub fn get_fn(cpu: *const CPU) bool {
        return cpu.f & 0x40 != 0;
    }

    pub fn get_fh(cpu: *const CPU) bool {
        return cpu.f & 0x20 != 0;
    }

    pub fn get_fc(cpu: *const CPU) bool {
        return cpu.f & 0x10 != 0;
    }

    pub fn set_fz(cpu: *CPU) void {
        cpu.f |= 0x80;
    }

    pub fn set_fn(cpu: *CPU) void {
        cpu.f |= 0x40;
    }

    pub fn set_fh(cpu: *CPU) void {
        cpu.f |= 0x20;
    }

    pub fn set_fc(cpu: *CPU) void {
        cpu.f |= 0x10;
    }

    pub fn reset_fz(cpu: *CPU) void {
        cpu.f &= 0x7f;
    }

    pub fn reset_fn(cpu: *CPU) void {
        cpu.f &= 0xbf;
    }

    pub fn reset_fh(cpu: *CPU) void {
        cpu.f &= 0xdf;
    }

    pub fn reset_fc(cpu: *CPU) void {
        cpu.f &= 0xef;
    }

    pub fn init(ptr: anytype) *CPU {
        const cpu: *CPU = @ptrFromInt(@intFromPtr(ptr));

        cpu.a = 0x01;
        cpu.f = 0xb0;
        cpu.b = 0x00;
        cpu.c = 0x13;
        cpu.d = 0x00;
        cpu.e = 0xd8;
        cpu.h = 0x01;
        cpu.l = 0x4d;
        cpu.sp = 0xfffe;
        cpu.pc = 0x0100;
        cpu.halted = false;

        return cpu;
    }

    pub fn step(cpu: *CPU) void {
        if (!cpu.halted) {
            const op = cpu.bus.read(cpu.pc);
            cpu.pc +%= 1;

            const f = instructions[op];
            if (f != undefined) {
                f(cpu, cpu.bus, cpu.clock);
            }
        }
    }
};
