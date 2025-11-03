// Library for logging to VM for debugging

const x86 = @import("../libmeow/x86.zig");

// I/O port for COM1
const SERIAL_PORT =  0x3f8;

// Register offsets from the base port
const SERIAL_DATA_PORT = SERIAL_PORT + 0;
const SERIAL_INT_ENABLE_PORT = SERIAL_PORT + 1;
const SERIAL_FIFO_CONTROL_PORT = SERIAL_PORT + 2;
const SERIAL_LINE_CONTROL_PORT = SERIAL_PORT + 3;
const SERIAL_MODEM_CONTROL_PORT = SERIAL_PORT + 4;
const SERIAL_LINE_STATUS_PORT = SERIAL_PORT + 5;

pub fn init() void {
    x86.out(SERIAL_INT_ENABLE_PORT, @as(u8, 0x00));
    x86.out(SERIAL_LINE_CONTROL_PORT, @as(u8, 0x80)); 
    x86.out(SERIAL_DATA_PORT, @as(u8, 0x03)); 
    x86.out(SERIAL_INT_ENABLE_PORT, @as(u8, 0x00));
    x86.out(SERIAL_LINE_CONTROL_PORT, @as(u8, 0x03));
    x86.out(SERIAL_FIFO_CONTROL_PORT, @as(u8, 0xC7));
    x86.out(SERIAL_MODEM_CONTROL_PORT, @as(u8, 0x0B));
}

fn isTransmitEmpty() u8 {
    return x86.in(u8, SERIAL_LINE_STATUS_PORT) & 0x20;
}

fn putChar(char: u8) void {
    while (isTransmitEmpty() == 0) {
    	x86.out(SERIAL_DATA_PORT, char);
    }
}

pub fn log(str: []const u8) void {
    for (str) |char| {
        putChar(char);
    }
}
