const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const TOTAL_CELLS = VGA_WIDTH * VGA_HEIGHT;

var current_offset: usize = 0;
const VGA: [*]volatile u16 = @ptrFromInt(0xb8000);

pub const ColorType = enum(u4) {
    black = 0,
    blue = 1,
    green = 2,
    cyan = 3,
    red = 4,
    magenta = 5,
    brown = 6,
    light_gray = 7,
    dark_gray = 8,
    light_blue = 9,
    light_green = 10,
    light_cyan = 11,
    light_red = 12,
    light_magenta = 13,
    light_brown = 14,
    white = 15,
};

const Color = packed struct(u8) {
    text: ColorType,
    bg: ColorType,

    pub fn init(text: ColorType, bg: ColorType) Color {
        return .{ .text = text, .bg = bg };
    }

    pub fn getVgaChar(self: Color, char: u8) u16 {
        return @as(u16, @as(u8, @bitCast(self))) << 8 | char;
    }
};


// Offset helpers
inline fn getOffset(row: usize, column: usize) usize {
	return (row * VGA_WIDTH) + column;
}

inline fn getRow(offset: usize) usize {
	return offset / VGA_WIDTH;
}

inline fn getColumn(offset: usize) usize {
	return offset % VGA_WIDTH;
}


// Print helpers
fn scrollDown() void {
	// Pushing the rest of the screen by row + 1
	const offset = TOTAL_CELLS - VGA_WIDTH;
	@memmove(@as([*] volatile u16, @volatileCast(VGA))[0..offset], @as([*]const volatile u16, @volatileCast(VGA))[VGA_WIDTH..TOTAL_CELLS]);

	// Clearing offset of the last row
	const last_row_vga = @as([*] volatile u16, @volatileCast(VGA))[offset..TOTAL_CELLS];
	for (last_row_vga) |*cell| {
	    cell.* = 0x0F00 | ' ';
	}
	current_offset = offset;
}

pub fn printCharOffset(char: u8, color: Color, offset: usize) void {
	if (offset < TOTAL_CELLS) {
		const vgaChar = color.getVgaChar(char);
		VGA[offset] = vgaChar;
	}
}

pub fn printChar(char: u8, color: Color, row: usize, column: usize) void {
	if (row < VGA_HEIGHT and column < VGA_WIDTH) {
		const vgaChar = color.getVgaChar(char);
		const offset = getOffset(row, column);
		VGA[offset] = vgaChar;
	}
}

pub fn printFmt(str: []const u8, color: Color) void {
	for (str) |char| {
		if (char == '\n') {
	    	current_offset = ((current_offset / VGA_WIDTH) + 1) * VGA_WIDTH;
	    	if (current_offset >= TOTAL_CELLS) {
	    	    scrollDown();
	    	}
	    } else {
	        if (current_offset >= TOTAL_CELLS) {
	            scrollDown();
	        }
	        printCharOffset(char, color, current_offset);
	        current_offset += 1;
	    }
	}
}

pub fn printStd(str: []const u8) void {
	const color: Color = Color{.text = .white, .bg = .black};
	printFmt(str, color);
}

pub fn backspace() void {
	if (current_offset != 0) {
		current_offset -= 1;
		VGA[current_offset] = 0x0F00 | ' ';
	}
}

pub fn clear() void {
	@memset(@as([*] volatile u16, @volatileCast(VGA))[0..TOTAL_CELLS], 0x0F00 | ' ');
	current_offset = 0;
}
