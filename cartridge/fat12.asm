; Copyright (C) 2025 dgelessus
; 
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

; Proof of concept bootable Cody cartridge
; that is also a valid (empty) FAT12 file system.
; The code does nothing interesting yet,
; but I'm sure you can guess what I want to do with this eventually.

; Loading address for the boot code.
; HACK: Make sure that the first byte of the address is $e9
; so that it looks like a PC/x86 jump instruction.
; In particular, 7-Zip only recognizes FAT images as such
; if their first byte is $e9 AND they have a PC boot sector signature (see below).
LOAD_POSITION = $30e9

; File system parameters
INIT_TOTAL_BYTES = 128*1024 ; Must be a multiple of the sector size
INIT_BYTES_PER_SECTOR = 512 ; 512 is usual and treated as the minimum by some tools, but supposedly 256 and 128 should also work
INIT_SECTORS_PER_CLUSTER = 1
INIT_ROOT_DIR_ENTRIES = 64 ; This times 32 must be a multiple of the sector size. dosfstools mkfs.fat claims to use either 112 or 224 for floppies and 512 for HDDs. An empty 160k floppy from pcjs.org (with 320 sectors of 512 bytes) uses 64 root directory entries.
INIT_FAT_MEDIA_DESCRIPTOR = $f0 ; 0xf0 is used for 3.5 inch 1440 KiB floppies, but also for "other" media types apparently
INIT_SECTORS_PER_FAT = 1 ; idk, just guessing
INIT_VOLUME_ID = $00000000 ; 32-bit value, supposed to be unique for each volume, but we can't do that well in assembly...
INIT_VOLUME_LABEL = "CODYFS BOOT" ; 11 bytes

; Program header for Cody Basic's loader (needs to be first).
.word LOAD_POSITION ; Starting address
.word (LOAD_POSITION + LAST - START - 1) ; Ending address

; Cody Basic's loader will put the data at LOAD_POSITION.
.logical LOAD_POSITION

START:
	; Jump over the boot sector header and BPB.
	jmp BOOT

; FAT boot sector header.
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Boot_Sector

; The first two fields of the boot sector are:
; * 3 bytes of free space for a jump instruction
; * 8 bytes for the OEM name string

; Unfortunately, we need a total of 7 bytes for our own purposes:
; 4 bytes for the Cody Basic loader header,
; followed by 3 bytes for the jmp instruction.
; Thus, we also have to occupy the first 4 bytes of the OEM name field.
; Thankfully this is not a big issue,
; because the OEM name string can be set to anything for most purposes.
; (If necessary, we could even make sure that the bytes there are valid ASCII...)

; The remaining 4 bytes of the OEM name field:
.text "CODY"

; BIOS Parameter Block (BPB).
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#BIOS_Parameter_Block

INIT_RESERVED_SECTORS = $200 / INIT_BYTES_PER_SECTOR
INIT_FATS = 2
INIT_TOTAL_SECTORS = INIT_TOTAL_BYTES / INIT_BYTES_PER_SECTOR

.word INIT_BYTES_PER_SECTOR ; Sector size in bytes
.byte INIT_SECTORS_PER_CLUSTER ; Cluster size in sectors
.word INIT_RESERVED_SECTORS ; Number of reserved sectors
.byte INIT_FATS ; Number of file allocation tables (2 is usual, but 1 is apparently also possible)
.word INIT_ROOT_DIR_ENTRIES ; Maximum number of root directory entries
.word INIT_TOTAL_SECTORS ; Total number of sectors (16-bit version)
.byte INIT_FAT_MEDIA_DESCRIPTOR
.word INIT_SECTORS_PER_FAT ; Number of sectors per file allocation table

; CHS geometry - not relevant for us, so put dummy values here.
.word 1 ; Number of physical sectors per track
.word 1 ; Number of heads

.dword 0 ; Number of hidden sectors before this partition - 0 because this is an unpartitioned medium
.dword INIT_TOTAL_SECTORS ; Total number of sectors (32-bit version)

; Extended BPB.
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Extended_BIOS_Parameter_Block

.byte 0 ; BIOS drive number - not meaningful for us on a non-PC platform.
.byte 0 ; Reserved, should be set to 0 when formatting
.byte $29 ; Extended BPB signature
.dword INIT_VOLUME_ID
.text bytes(INIT_VOLUME_LABEL, 11)
.text "FAT12   " ; File system type string

; Boot code (not actually yet - for now, this is a variant of codycart.asm).

SCREEN_RAM = $C400 ; The default location of screen memory

BOOT:
	ldx #0 ; The program starts running from here

_LOOP:
	lda TEXT, x ; Copies TEXT into screen memory
	beq _DONE
	
	sta SCREEN_RAM, x
	
	inx
	bra _LOOP

; Loop forever.
_DONE:
	jmp _DONE

TEXT:
	.null "Cody!" ; TEXT as a null-terminated string

; End of the boot code that must be loaded by the Cody Basic loader.
LAST:
.endlogical
; Everything below here is further file system stuff that doesn't need to be initially loaded.

; HACK: PC boot sector signature.
; For some reason, some tools will only recognize a FAT file system if it has this signature,
; even though it specifically indicates a disk *that is bootable by a PC*.
; Ours is very much not that!
; So we should only keep this temporarily and remove it later if it doesn't cause too much trouble.
* = $1fe
.word $aa55

; File allocation tables.
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#File_Allocation_Table

* = INIT_RESERVED_SECTORS * INIT_BYTES_PER_SECTOR

.for i := 0, i < INIT_FATS, i += 1
	.byte INIT_FAT_MEDIA_DESCRIPTOR
	.word $ffff
	.fill (INIT_SECTORS_PER_FAT * INIT_BYTES_PER_SECTOR) - 3, $00
.endfor

; Root directory.
; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Directory_table

.fill INIT_ROOT_DIR_ENTRIES * 32, $e5 ; $e5 as the first byte in a directory entry means that the entry is free/unused, and filling all other bytes with $e5 as well seems to work fine
