# Makefile for building all software samples

# Subdirectories
SUBDIRS = sample_gpio0 sample_gpio1

# Default target
all: build_all binary_all rom

# Build all samples
build_all:
	@echo "=== Building all samples ==="
	@for dir in $(SUBDIRS); do \
		echo "Building $$dir..."; \
		$(MAKE) -C $$dir || exit 1; \
	done
	@echo "=== All samples built successfully ==="

# Build binary outputs for all samples
binary_all:
	@echo "=== Building binary outputs ==="
	@for dir in $(SUBDIRS); do \
		echo "Building binary for $$dir..."; \
		$(MAKE) -C $$dir binary || exit 1; \
	done
	@echo "=== All binary outputs built successfully ==="

# Build ROM images
rom: binary_all
	@echo "=== Creating combined ROM images ==="
	@if [ -x ./create_rom.sh ]; then \
		./create_rom.sh; \
	else \
		echo "Error: create_rom.sh not found or not executable"; \
		exit 1; \
	fi

# Clean all samples
clean:
	@echo "=== Cleaning all samples ==="
	@for dir in $(SUBDIRS); do \
		echo "Cleaning $$dir..."; \
		$(MAKE) -C $$dir clean || exit 1; \
	done
	@rm -f imem_data.hex dmem_data.hex
	@echo "=== All samples cleaned ==="

# Individual targets
sample_gpio0:
	$(MAKE) -C sample_gpio0

sample_gpio1:
	$(MAKE) -C sample_gpio1

sample_gpio0_binary:
	$(MAKE) -C sample_gpio0 binary

sample_gpio1_binary:
	$(MAKE) -C sample_gpio1 binary

# Help
help:
	@echo "Available targets:"
	@echo "  all              - Build all samples, binary outputs, and ROM images"
	@echo "  build_all        - Build all samples"
	@echo "  binary_all       - Create binary outputs for all samples"
	@echo "  rom              - Create combined ROM images (imem_data.hex, dmem_data.hex)"
	@echo "  clean            - Clean all samples"
	@echo "  sample_gpio0     - Build sample_gpio0 only"
	@echo "  sample_gpio1     - Build sample_gpio1 only"
	@echo "  sample_gpio0_binary - Create binary output for sample_gpio0"
	@echo "  sample_gpio1_binary - Create binary output for sample_gpio1"

.PHONY: all build_all binary_all rom clean help $(SUBDIRS) sample_gpio0_binary sample_gpio1_binary