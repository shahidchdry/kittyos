// Library for logging to VM for debugging

const x86 = @import("../libmeow/x86.zig");

// I/O port for COM1
const PORT =  0x3f8;

pub fn init() void {
	x86.out(PORT + 1, @as(u8, 0x00));
	x86.out(PORT + 3, @as(u8, 0x80));
    x86.out(PORT + 0, @as(u8, 0x03));
    x86.out(PORT + 1, @as(u8, 0x00));
    x86.out(PORT + 3, @as(u8, 0x03));
    x86.out(PORT + 2, @as(u8, 0xC7));
    x86.out(PORT + 4, @as(u8, 0x0B));
    x86.out(PORT + 4, @as(u8, 0x1E));
    x86.out(PORT + 0, @as(u8, 0xAE));

    if(x86.in(u8, PORT + 0) != 0xAE) {
       return;
    }
    x86.out(PORT + 4, @as(u8, 0x0F));
}

fn isTransmitEmpty() u8 {
    return x86.in(u8, PORT + 5) & 0x20;
}

fn putChar(char: u8) void {
    while (isTransmitEmpty() == 0) {}
    x86.out(PORT, char);
}

pub fn log(str: []const u8) void {
    for (str) |char| {
        putChar(char);
    }
}
