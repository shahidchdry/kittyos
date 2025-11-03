const isr = @import("isr.zig");
const irq = @import("irq.zig");

pub const InterruptHandler = fn () callconv(.naked) void;
pub const servicer = *fn (*Register) void;

pub const Register = packed struct {
    ds: u32, // Data segment selector

    // Registers
    edi: u32,
    esi: u32,
    ebp: u32,
    esp: u32,
    ebx: u32,
    edx: u32,
    ecx: u32,
    eax: u32,

    // Interrupt number and error code
    int_no: u32,
    err_code: u32,

    // Pushed by the processor automatically
    eip: u32,
    cs: u32,
    eflags: u32,
    useresp: u32,
    ss: u32,	
};

export fn handler(reg: *Register) void {
    if (reg.int_no < 32 or reg.int_no == 128) {
        isr.handler(reg);
    } else {
        irq.handler(reg);
    }
}

export fn commonStub() callconv(.naked) void {
	asm volatile (
		\\push %%eax
        \\push %%ecx
        \\push %%edx
        \\push %%ebx
        \\push %%esp
        \\push %%ebp
        \\push %%esi
        \\push %%edi
        \\push %%ds
        \\mov $0x10, %%bx
        \\mov %%bx, %%ds
        \\call  handler
        \\pop %%ds
        \\pop %%edi
        \\pop %%esi
        \\pop %%ebp
        \\pop %%esp
        \\pop %%ebx
        \\pop %%edx
        \\pop %%ecx
        \\pop %%eax
        \\add $8, %%esp
        \\sti
        \\iret
    );
}

pub fn getInterruptStub(int_no: u32) InterruptHandler {
	const fn_decl = struct {
		fn f() callconv(.naked) void {
	    	asm volatile (
	        	\\ cli
	        );
	        if (int_no != 8 and !(int_no >= 10 and int_no <= 14) and int_no != 17) {
	        	asm volatile (
	            	\\ pushl $0
	            );
	        }
	    	asm volatile (
	        	\\ push %[nr]
	            \\ jmp commonStub
	            :
	            : [nr] "n" (int_no),
	        );
	    }
	};
	return fn_decl.f;
}
