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

; Simple cartridge/assembly test program
; that copies a couple of strings to the screen and then stops.

screen_ram = $c400 ; Default base address of screen memory

; Zero page variables
src: .addr ?
dest: .addr ?

LOAD_POSITION = $3000
; Program header for Cody Basic's loader (needs to be first).
* = 0
.word LOAD_POSITION ; Starting address
.word (LOAD_POSITION + LAST - START - 1) ; Ending address

; Cody Basic's loader will put the data at LOAD_POSITION.
.logical LOAD_POSITION
START:
	;;lda #$42
	;;sta screen_ram+16
	
	lda #<TEXT
	sta src
	lda #>TEXT
	sta src+1
	
	lda #<screen_ram
	sta dest
	lda #>screen_ram
	sta dest+1
	
	jsr strcpy
	
	lda #<TEXT2
	sta src
	lda #>TEXT2
	sta src+1
	
	lda #<(screen_ram+6)
	sta dest
	lda #>(screen_ram+6)
	sta dest+1
	
	jsr strcpy

; Loop forever.
_done:
	jmp _done

strcpy:
	lda (src)
	beq _ret
	sta (dest)
	
	inc src
	bne _no_carry_src
	inc src+1
_no_carry_src:
	
	inc dest
	bne _no_carry_dest
	inc dest+1
_no_carry_dest:
	
	bra strcpy
	
_ret:
	rts

TEXT: .null "Copy!"
TEXT2: .null "that."

LAST:
.endlogical
