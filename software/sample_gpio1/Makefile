RISCV=riscv32im_2024
CC = riscv32-unknown-elf-gcc
LD = riscv32-unknown-elf-ld
CFLAGS = -I../common -march=rv32imf -mabi=ilp32 -g
LDFLAGS = -L/opt/$(RISCV)/riscv32-unknown-elf/lib -Tlink.ld -static
LIBS = -lc
OBJS = main.o start.o
PROGRAM = sample_gpio
OBJCOPY = riscv32-unknown-elf-objcopy
OBJDUMP = riscv32-unknown-elf-objdump

export PATH := $(PATH):/opt/$(RISCV)/bin/

$(PROGRAM): $(OBJS)
	$(LD) $(OBJS) $(LIBS) $(LDFLAGS) -o $(PROGRAM)

start.o: start.S
	$(CC) $(CFLAGS) -c -o start.o start.S

main.o: main.c
	$(CC) $(CFLAGS) -c -o main.o main.c

all: $(PROGRAM)

simdata:
	$(OBJCOPY) -O binary $(PROGRAM) $(PROGRAM).bin
	$(OBJDUMP) -s -S $(PROGRAM) > $(PROGRAM).dump
	$(OBJCOPY) -O binary --only-section=.rodata* $(PROGRAM) $(PROGRAM)_d.bin
	$(OBJCOPY) -O binary --only-section=.text* $(PROGRAM) $(PROGRAM)_i.bin
	hexdump -v -e '1/1 "@00%04_ax %02x" "\n"' $(PROGRAM)_i.bin > $(PROGRAM)_i.vmf
	hexdump -v -e '1/1 "@01%04_ax %02x" "\n"' $(PROGRAM)_d.bin > $(PROGRAM)_d.vmf
	cat $(PROGRAM)_i.vmf $(PROGRAM)_d.vmf > $(PROGRAM).vmf
	cp $(PROGRAM).vmf ../../romdata/mem.vmf

binary:
	$(OBJCOPY) -O binary $(PROGRAM) $(PROGRAM).bin
	$(OBJDUMP) -s -S $(PROGRAM) > $(PROGRAM).dump
	$(OBJCOPY) -O binary --only-section=.rodata* $(PROGRAM) $(PROGRAM)_d.bin
	$(OBJCOPY) -O binary --only-section=.text* $(PROGRAM) $(PROGRAM)_i.bin
	hexdump -v -e '1/4 "%08x" "\n"' $(PROGRAM)_i.bin > $(PROGRAM)_i.hex
	hexdump -v -e '1/4 "%08x" "\n"' $(PROGRAM)_d.bin > $(PROGRAM)_d.hex

clean:
	rm -rf *.o
	rm -rf *.bin
	rm -rf *.dump
	rm -rf *.hex
	rm -rf *.vmf
	rm -rf $(PROGRAM)
	rm -rf core
