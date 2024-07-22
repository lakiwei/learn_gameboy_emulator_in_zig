const std = @import("std");

fn get_cartridge_type_name(cartridge_type: u8) []const u8 {
    return switch (cartridge_type) {
        0 => "ROM ONLY",
        1 => "MBC1",
        2 => "MBC1+RAM",
        3 => "MBC1+RAM+BATTERY",
        4 => "0x04 ???",
        5 => "MBC2",
        6 => "MBC2+BATTERY",
        7 => "0x07 ???",
        8 => "ROM+RAM 1",
        9 => "ROM+RAM+BATTERY 1",
        10 => "0x0A ???",
        11 => "MMM01",
        12 => "MMM01+RAM",
        13 => "MMM01+RAM+BATTERY",
        14 => "0x0E ???",
        15 => "MBC3+TIMER+BATTERY",
        16 => "MBC3+TIMER+RAM+BATTERY 2",
        17 => "MBC3",
        18 => "MBC3+RAM 2",
        19 => "MBC3+RAM+BATTERY 2",
        20 => "0x14 ???",
        21 => "0x15 ???",
        22 => "0x16 ???",
        23 => "0x17 ???",
        24 => "0x18 ???",
        25 => "MBC5",
        26 => "MBC5+RAM",
        27 => "MBC5+RAM+BATTERY",
        28 => "MBC5+RUMBLE",
        29 => "MBC5+RUMBLE+RAM",
        30 => "MBC5+RUMBLE+RAM+BATTERY",
        31 => "0x1F ???",
        32 => "MBC6",
        33 => "0x21 ???",
        34 => "MBC7+SENSOR+RUMBLE+RAM+BATTERY",
        else => "UNKNOWN",
    };
}

fn get_cartridge_ram_size_name(ram_size_code: u8) []const u8 {
    return switch (ram_size_code) {
        0 => "0",
        1 => "-",
        2 => "8 KB (1 bank)",
        3 => "32 KB (4 banks of 8KB each)",
        4 => "128 KB (16 banks of 8KB each)",
        5 => "64 KB (8 banks of 8KB each)",
        else => "UNKNOWN",
    };
}

fn get_cartridge_lic_code_name(lic_code: u8) []const u8 {
    return switch (lic_code) {
        0x00 => "None",
        0x01 => "Nintendo R&D1",
        0x08 => "Capcom",
        0x13 => "Electronic Arts",
        0x18 => "Hudson Soft",
        0x19 => "b-ai",
        0x20 => "kss",
        0x22 => "pow",
        0x24 => "PCM Complete",
        0x25 => "san-x",
        0x28 => "Kemco Japan",
        0x29 => "seta",
        0x30 => "Viacom",
        0x31 => "Nintendo",
        0x32 => "Bandai",
        0x33 => "Ocean/Acclaim",
        0x34 => "Konami",
        0x35 => "Hector",
        0x37 => "Taito",
        0x38 => "Hudson",
        0x39 => "Banpresto",
        0x41 => "Ubi Soft",
        0x42 => "Atlus",
        0x44 => "Malibu",
        0x46 => "angel",
        0x47 => "Bullet-Proof",
        0x49 => "irem",
        0x50 => "Absolute",
        0x51 => "Acclaim",
        0x52 => "Activision",
        0x53 => "American sammy",
        0x54 => "Konami",
        0x55 => "Hi tech entertainment",
        0x56 => "LJN",
        0x57 => "Matchbox",
        0x58 => "Mattel",
        0x59 => "Milton Bradley",
        0x60 => "Titus",
        0x61 => "Virgin",
        0x64 => "LucasArts",
        0x67 => "Ocean",
        0x69 => "Electronic Arts",
        0x70 => "Infogrames",
        0x71 => "Interplay",
        0x72 => "Broderbund",
        0x73 => "sculptured",
        0x75 => "sci",
        0x78 => "THQ",
        0x79 => "Accolade",
        0x80 => "misawa",
        0x83 => "lozc",
        0x86 => "Tokuma Shoten Intermedia",
        0x87 => "Tsukuda Original",
        0x91 => "Chunsoft",
        0x92 => "Video system",
        0x93 => "Ocean/Acclaim",
        0x95 => "Varie",
        0x96 => "Yonezawa/s’pal",
        0x97 => "Kaneko",
        0x99 => "Pack in soft",
        0xA4 => "Konami (Yu-Gi-Oh!)",
        else => "UNKNOWN",
    };
}

pub const CartridgeHeader = struct {
    entry: [4]u8,
    logo: [48]u8,
    title: [16]u8,
    new_lic_code: [2]u8,
    sgb_flag: u8,
    cartridge_type: u8,
    rom_size: u8,
    ram_size_code: u8,
    dest_code: u8,
    lic_code: u8,
    version: u8,
    checksum: u8,
    global_checksum: [2]u8,

    pub fn type_name(header: *const CartridgeHeader) []const u8 {
        return get_cartridge_type_name(header.cartridge_type);
    }

    pub fn ram_size_name(header: *const CartridgeHeader) []const u8 {
        return get_cartridge_ram_size_name(header.ram_size_code);
    }

    pub fn lic_code_name(header: *const CartridgeHeader) []const u8 {
        return get_cartridge_lic_code_name(header.lic_code);
    }
};

pub const Cartridge = struct {
    var bad: [0x100 + @sizeOf(CartridgeHeader)]u8 = undefined;

    buffer: []u8,
    header: *CartridgeHeader,

    pub fn reset(cartridge: *Cartridge) void {
        cartridge.buffer = &bad;
        cartridge.header = @ptrFromInt(@intFromPtr(&cartridge.buffer[0x100]));
    }

    pub fn set(cartridge: *Cartridge, buffer: []u8) void {
        if (buffer.len < 0x100 + @sizeOf(CartridgeHeader)) {
            cartridge.reset();
        } else {
            cartridge.buffer = buffer;
            cartridge.header = @ptrFromInt(@intFromPtr(&cartridge.buffer[0x100]));
        }
    }

    pub fn init(ptr: anytype) *Cartridge {
        const cartridge: *Cartridge = @ptrFromInt(@intFromPtr(ptr));

        cartridge.reset();

        return cartridge;
    }

    pub fn read(cartridge: *const Cartridge, addr: u16) u8 {
        if (addr < 0x7fff and addr < cartridge.buffer.len) {
            return cartridge.buffer[addr];
        } else {
            return 0;
        }
    }

    pub fn write(cartridge: *const Cartridge, addr: u16, data: u8) void {
        if (addr < 0x7fff and addr < cartridge.buffer.len) {
            cartridge.buffer[addr] = data;
        }
    }
};
