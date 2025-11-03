const std = @import("std");

const GDTEntry = packed struct {
    lim0_15: u16,
    base0_15: u16,
    base16_23: u8,
    access: u8,
    lim16_19: u4,
    flags: u4,
    base24_31: u8,
};

const GDTPtr = packed struct {
    limit: u16,
    base: u32,
};

const TSS = packed struct {
    previous_task: u16,
    reserved1: u16,

    esp0: u32,
    ss0: u16,
    reserved2: u16,

    esp1: u32,
    ss1: u16,
    reserved3: u16,

    esp2: u32,
    ss2: u16,
    reserved4: u16,

    cr3: u32,
    eip: u32,
    eflags: u32,
    eax: u32,
    ecx: u32,
    edx: u32,
    ebx: u32,
    esp: u32,
    ebp: u32,
    esi: u32,
    edi: u32,

    es: u16,
    reserved5: u16,
    cs: u16,
    reserved6: u16,
    ss: u16,
    reserved7: u16,
    ds: u16,
    reserved8: u16,
    fs: u16,
    reserved9: u16,
    gs: u16,
    reserved10: u16,

    ldt_selector: u16,
    reserved11: u16,

    debug_flag: u16,
    io_map: u16,
};


const NUMBER_OF_ENTRIES: u16 = 0x06;
const TABLE_SIZE: u16 = @sizeOf(GDTEntry) * NUMBER_OF_ENTRIES - 1;
pub const KERNEL_CODE_OFFSET: u16 = 0x08;
const KERNEL_DATA_OFFSET: u16 = 0x10;
const TSS_OFFSET: u16 = 0x28;


fn initGDTDesc(base: u32, limit: u32, access: u8, flags: u8, gdt_entry: *GDTEntry) void {
	gdt_entry.lim0_15 = @as(u16, @intCast(limit & 0xFFFF));
	gdt_entry.base0_15 = @as(u16, @intCast(base & 0xFFFF));
	gdt_entry.base16_23 = @as(u8, @intCast((base >> 16) & 0xFF));
	gdt_entry.access = access;
	gdt_entry.lim16_19 = @as(u4, @intCast((limit >> 16) & 0xF));
	gdt_entry.flags= @as(u4, @intCast(flags & 0xF));
	gdt_entry.base24_31 = @as(u8, @intCast((base >> 24) & 0xFF));
}

pub var tss = std.mem.zeroes(TSS);
var gdt_desc_table: [NUMBER_OF_ENTRIES]GDTEntry = undefined;
var gdt_ptr = GDTPtr{
	.limit = TABLE_SIZE,
	.base = undefined,
};

pub fn init() void {
	tss.debug_flag = 0x00;
	tss.io_map = @sizeOf(TSS);
	tss.esp0 = 0x1FFF0;
	tss.ss0 = KERNEL_DATA_OFFSET;

	// Null
	initGDTDesc(0x0, 0x0, 0x0, 0x0, &gdt_desc_table[0]);
	// Kernel code
	initGDTDesc(0x0, 0xFFFFF, 0x9B, 0x0D, &gdt_desc_table[1]);
	// Kernel data
	initGDTDesc(0x0, 0xFFFFF, 0x93, 0x0D, &gdt_desc_table[2]);
	// User code
	initGDTDesc(0x0, 0xFFFFF, 0xFF, 0x0D, &gdt_desc_table[3]);
	// User data
	initGDTDesc(0x0, 0xFFFFF, 0xF3, 0x0D, &gdt_desc_table[4]);
	// Tss
	initGDTDesc( @as(u32, @intFromPtr(&tss)), 0x67, 0x89, 0x00, &gdt_desc_table[5]);

	gdt_ptr.base = @as(u32, @intFromPtr(&gdt_desc_table[0]));

	asm volatile ("lgdt (%%eax)"
	    :
	    : [gdt_ptr] "{eax}" (&gdt_ptr),
	);
	asm volatile ("mov %%bx, %%ds"
	    :
	    : [KERNEL_DATA_OFFSET] "{bx}" (KERNEL_DATA_OFFSET),
	);
	asm volatile ("mov %%bx, %%es");
	asm volatile ("mov %%bx, %%fs");
	asm volatile ("mov %%bx, %%gs");
	asm volatile ("mov %%bx, %%ss");
	asm volatile (
	    \\ljmp $0x08, $1f
	    \\1:
	);
	asm volatile ("ltr %%ax"
	    :
	    : [TSS_OFFSET] "{ax}" (TSS_OFFSET),
	);
}
