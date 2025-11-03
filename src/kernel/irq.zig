const std = @import("std");
const idt = @import("idt.zig");
const int = @import("interrupt.zig");
const x86 = @import("../libmeow/x86.zig");

const interrupt_handlers: [256]?int.servicer = [_]?int.servicer{null} ** 256;

pub fn registerHandler(n: u8, interrupt_handler: int.servicer) void {
	interrupt_handlers[n] = interrupt_handler;
}

pub fn handler(reg: *int.Register) void {
	if (reg.int_no >= 40) {
		x86.out(0xA0, @as(u8, 0x20));
	}
	x86.out(0x20, @as(u8, 0x20));
	if (interrupt_handlers[reg.int_no]) |interrupt_handler| {
		interrupt_handler(reg);
	}
}

fn remapPic() void {
	x86.out(0x20, @as(u8, 0x11));
    x86.out(0xA0, @as(u8, 0x11));
    x86.out(0x21, @as(u8, 0x20));
    x86.out(0xA1, @as(u8, 0x28));
    x86.out(0x21, @as(u8, 0x04));
    x86.out(0xA1, @as(u8, 0x02));
    x86.out(0x21, @as(u8, 0x01));
    x86.out(0xA1, @as(u8, 0x01));
    x86.out(0x21, @as(u8, 0x0));
    x86.out(0xA1, @as(u8, 0x0)); 
}

pub fn init() void {
	remapPic();
	inline for (32..47) |i| {
        const interrupt_handler = int.getInterruptStub(@as(u32, i));
		idt.setGate(i, idt.INTERRUPT_GATE, interrupt_handler);
	}
}
