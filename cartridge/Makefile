# User-customizable variables:
64TASS ?= 64tass
64TASS_FLAGS ?=
BUILD_DIR ?= build

# Internal variables - normally shouldn't be overridden:
DEFAULT_64TASS_FLAGS = \
    -Wall \
    -Walias \
    -Walign \
    -Waltmode \
    -Wcase-symbol \
    -Wfloat-round \
    -Wimmediate \
    -Wimplied-reg \
    -Wleading-zeros \
    -Wlong-branch \
    -Wmacro-prefix \
    -Wold-equal \
    -Wshadow \
    -Wstrict-bool \
    -Wunused \
    --quiet
ALL_64TASS_FLAGS = $(DEFAULT_64TASS_FLAGS) $(64TASS_FLAGS)

all: \
    basic_coexist.bin \
    fat12.bin \
    spi.bin \
    strcpy.bin

$(BUILD_DIR):
	mkdir -p $@

%.bin: %.asm $(BUILD_DIR)
	$(64TASS) $(ALL_64TASS_FLAGS) --mw65c02 --nostart -o $(BUILD_DIR)/$@ $<

.PHONY: clean
clean:
	$(RM) -r $(BUILD_DIR)
