include $(BUILD_DIR)/software/include/generated/variables.mak
include $(SOC_DIRECTORY)/software/common.mak

LIBS := $(filter-out liblitesdcard libfatfs,$(LIBS))
PACKAGES := $(filter-out liblitesdcard libfatfs,$(PACKAGES))

OBJECTS = crt0.o main.o nes_loader.o rom_rotator.o power.o heap.o tlsf.o spisdcard.o ff.o ffunicode.o ffsystem.o
CFLAGS += -Os -flto

all: icepi-zero-nes.bin

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
ifneq ($(OS),Windows_NT)
	chmod -x $@
endif

vpath %.a $(PACKAGES:%=../%)

icepi-zero-nes.elf: $(OBJECTS)
	$(CC) $(LDFLAGS) -T linker.ld -N -o $@ \
		$(OBJECTS) \
		$(PACKAGES:%=-L$(BUILD_DIR)/software/%) \
		-Wl,--start-group \
		$(LIBS:lib%=-l%) \
		-Wl,--end-group \
		-Wl,--gc-sections \
		-Wl,-Map,$@.map

ifneq ($(OS),Windows_NT)
	chmod -x $@
endif

# pull in dependency info for *existing* .o files
-include $(OBJECTS:.o=.d)

tlsf.o: CFLAGS += -U__GNUC__

VPATH = $(BIOS_DIRECTORY):$(BIOS_DIRECTORY)/cmds:$(CPU_DIRECTORY)

%.o: %.cpp
	$(compilexx)

%.o: %.c
	$(compile)

%.o: %.S
	$(assemble)

clean:
	$(RM) $(OBJECTS) icepi-zero-nes.elf icepi-zero-nes.bin .*~ *~

.PHONY: all clean
