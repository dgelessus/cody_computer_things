all: \
    basic_coexist.bin \
    fat12.bin \
    spi.bin \
    strcpy.bin

%.bin: %.asm
	64tass --mw65c02 --nostart -o $@ $<
