//To do add separate handlers for each isr interrupts
const idt = @import("idt.zig");
const int = @import("interrupt.zig");
const console = @import("../libmeow/console.zig");

const exception_messages = [_][]const u8{
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Into Detected Overflow",
    "Out of Bounds",
    "Invalid Opcode",
    "No Coprocessor",

    "Double Fault",
    "Coprocessor Segment Overrun",
    "Bad TSS",
    "Segment Not Present",
    "Stack Fault",
    "General Protection Fault",
    "Page Fault",
    "Unknown Interrupt",

    "Coprocessor Fault",
    "Alignment Check",
    "Machine Check",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",

    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
};

pub fn handler(reg: *int.Register) void {
	console.printStd("\nReceived interrupt no : ");
	console.printStd(exception_messages[reg.int_no]);
}

pub fn init() void {
	inline for (0..32) |i| {
        const interrupt_handler = int.getInterruptStub(@as(u32, i));
		idt.setGate(i, idt.INTERRUPT_GATE, interrupt_handler);
	}
}
