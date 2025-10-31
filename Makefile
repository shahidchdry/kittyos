KERNEL_ELF_PATH = zig-out/bin/kernel.elf
KERNEL_ISO_NAME = kernel.iso
QEMU_CMD = qemu-system-x86_64 -cdrom $(KERNEL_ISO_NAME)

.PHONY: all build iso run clean

all: iso

install:
	sudo apt update
	sudo apt install -y grub-common grub-pc-bin xorriso mtools qemu-system-x86 wget tar
	wget https://ziglang.org/download/index.json -O zig_releases.json
	LATEST_URL=$(grep -oP '(?<=x86_64-linux": ")[^"]+' zig_releases.json | head -n 1)
	wget $LATEST_URL -O zig.tar.xz
	tar -xf zig.tar.xz
	sudo mv zig-* /usr/local/zig
	sudo ln -s /usr/local/zig/zig /usr/local/bin/zig
	zig version
	

build:
	@echo ">>> 1. Building x86 kernel.elf..."
	@zig build

iso: build
	@echo ">>> 2. Creating bootable x86 $(KERNEL_ISO_NAME)..."
	@mkdir -p iso/boot/grub
	@cp $(KERNEL_ELF_PATH) iso/boot/kernel.elf
	@cp grub.cfg iso/boot/grub/grub.cfg
	@grub-mkrescue -o $(KERNEL_ISO_NAME) iso
	@echo ">>> Successfully created $(KERNEL_ISO_NAME)"

run: iso
	@echo ">>> 3. Booting $(KERNEL_ISO_NAME) with QEMU (x86)..."
	@$(QEMU_CMD)

run-vnc: iso
	@echo ">>> 3. Booting $(KERNEL_ISO_NAME) with QEMU (x86)..."
	@$(QEMU_CMD) -vga std -display vnc=:0

clean:
	@echo ">>> Cleaning up build files..."
	@rm -rf zig-out zig-cache
	@rm -f $(KERNEL_ISO_NAME)
	@rm -rf iso
