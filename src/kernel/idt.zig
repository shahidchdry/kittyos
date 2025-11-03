const gdt = @import("gdt.zig");
const int = @import("interrupt.zig");

pub const INTERRUPT_GATE = 0x8E;
pub const SYSCALL_GATE   = 0xEE;
const IDT_ENTRIES = 256;

const IDTEntry = packed struct {
    base_low: u16,   // Lower 16 bits of handler function address
    sel: u16,        // Kernel segment selector
    always0: u8 = 0, // Must always be zero
    flags: u8,       // Type and attributes
    base_high: u16,  // Higher 16 bits of handler function address
};

const IDTRegister = packed struct {
    limit: u16,
    base: u32,
};

var idt: [IDT_ENTRIES]IDTEntry = undefined;
var idt_reg = IDTRegister{
	.limit = IDT_ENTRIES * @sizeOf(IDTEntry) - 1,
	.base = undefined,
};

pub fn setGate(n: u8, flags: u8, handler: int.InterruptHandler) void {
	const offset = @intFromPtr(&handler);
    idt[n].base_low = @truncate(offset);
    idt[n].sel = gdt.KERNEL_CODE_OFFSET;
    idt[n].always0 = 0;
    idt[n].flags = flags;
    idt[n].base_high = @truncate(offset >> 16);
}

pub fn init() void {
	idt_reg.base = @as(u32, @intFromPtr(&idt));
	asm volatile ("lidt (%[idt_reg])" : : [idt_reg] "r" (&idt_reg));
}
