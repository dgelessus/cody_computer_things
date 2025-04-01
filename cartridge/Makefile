64TASS ?= 64tass

all: \
    basic_coexist.bin \
    fat12.bin \
    spi.bin \
    strcpy.bin

%.bin: %.asm
	$(64TASS) --mw65c02 --nostart -o $@ $<

.PHONY: clean
clean:
	$(RM) *.bin
