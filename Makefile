KERNEL_ELF_PATH = zig-out/bin/kernel.elf
KERNEL_ISO_NAME = kernel.iso
QEMU_CMD        = qemu-system-x86_64 -cdrom $(KERNEL_ISO_NAME)

ZIG_SOURCES = $(shell find src -type f -name '*.zig')

ZIG_DIR = /usr/local/zig
ZIG_BIN = $(ZIG_DIR)/zig

.PHONY: all install run run-vnc clean uninstall

all: $(KERNEL_ISO_NAME)

install:
	@echo ">>> Installing dependencies..."
	sudo apt update
	sudo apt install -y grub-common grub-pc-bin xorriso mtools qemu-system-x86 wget tar
	@echo ">>> Downloading and installing latest Zig..."
	ZIG_VERSION=$(curl -s "https://api.github.com/repos/ziglang/zig/releases/latest" | grep -Po '"tag_name": "\K[0-9.]+') && \
	wget -qO zig.tar.xz https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz && \
	sudo mkdir -p /opt/zig && \
	sudo tar xf zig.tar.xz --strip-components=1 -C /opt/zig
	@echo ">>> Zig version:"
	@zig version
	@echo ">>> Cleaning up install files..."
	@rm -f zig_releases.json zig.tar.xz

$(KERNEL_ELF_PATH): $(ZIG_SOURCES) build.zig
	@echo ">>> 1. Building x86 kernel.elf..."
	@zig build

$(KERNEL_ISO_NAME): $(KERNEL_ELF_PATH) grub.cfg
	@echo ">>> 2. Creating bootable x86 $(KERNEL_ISO_NAME)..."
	@mkdir -p iso/boot/grub
	@cp $(KERNEL_ELF_PATH) iso/boot/kernel.elf
	@cp grub.cfg iso/boot/grub/grub.cfg
	@grub-mkrescue -o $(KERNEL_ISO_NAME) iso
	@echo ">>> Successfully created $(KERNEL_ISO_NAME)"

run: $(KERNEL_ISO_NAME)
	@echo ">>> 3. Booting $(KERNEL_ISO_NAME) with QEMU (x86)..."
	@$(QEMU_CMD)

run-vnc: $(KERNEL_ISO_NAME)
	@echo ">>> 3. Booting $(KERNEL_ISO_NAME) with QEMU (x86) on VNC..."
	@$(QEMU_CMD) -vga std -display vnc=:0

clean:
	@echo ">>> Cleaning up build files..."
	@rm -rf zig-out zig-cache
	@rm -f $(KERNEL_ISO_NAME)
	@rm -rf iso
