;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2015 Alberto García García
;;  Copyright (C) 2015 Pablo Martínez González
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
;######################################################################
;### MODULE: Bit Array                                              ###
;### Developed by Alberto García García and Pablo Martínez González ###
;######################################################################
;### This module contains functions to get and set groups of 1, 2   ###
;### and 4 bit in a char array. So data in arrays can be compressed ###
;### in a transparent way to the programmer.                        ###
;######################################################################
;

_cpct_bitWeights:
	.dw #0x0001
	.dw #0x0002
	.dw #0x0004
	.dw #0x0008
	.dw #0x0010
	.dw #0x0020
	.dw #0x0040
	.dw #0x0080

;
;########################################################################
;### FUNCTION: cpct_getBit                                            ###
;########################################################################
;### Returns 0 or >0 depending on the value of the bit at the given   ###
;### position in the specified array.                                 ###
;### It will asume that the array elements have a size of 8 bits and  ###
;### also that the given position is not bigger than the number of    ###
;### bits in the array (size of the array multiplied by eight).       ###
;### Limitations: Maximum of 65536 bits, 8192 bytes per array.        ###
;########################################################################
;### INPUTS (4 Bytes)                                                 ###
;###  * (2B DE) Array Pointer                                         ###
;###  * (2B HL) Position of the bit in the array                      ###
;########################################################################
;### RETURN VALUE                                                     ###
;###  L = 0 if bit was unset                                          ###
;###  L > 0 if bit was set                                            ###
;########################################################################
;### EXIT STATUS                                                      ###
;###  Destroyed Register values: AF, BC, DE, HL                       ###
;########################################################################
;### MEASURES                                                         ###
;### MEMORY: 39 bytes (8 table + 31 code)                             ###
;### TIME: 179 cycles ( 44.75 us)                                     ###                                                            ###
;########################################################################
;

.bndry 8 ;; Make this vector start at a 8-byte aligned address to be able to use 8-bit arithmetic with pointers
cpct_bitWeights: .db #0x01, #0x02, #0x04, #0x08, #0x10, #0x20, #0x40, #0x80

.globl _cpct_getBit
_cpct_getBit::

   ;; Get parameters from the stack
   POP   AF          ;; [10] AF = Return address
   POP   DE          ;; [10] DE = Pointer to the array in memory
   POP   HL          ;; [10] HL = Index of the bit we want to get
   PUSH  HL          ;; [11] << Restore stack status
   PUSH  DE          ;; [11]
   PUSH  AF          ;; [11]

   ;; We only access bytes at once in memory. We need to calculate which
   ;; bit will we have to test in the target byte of our array. That will be
   ;; the remainder of INDEX/8, as INDEX/8 represents the byte to access.
   LD    BC, #cpct_bitWeights ;; [10] BC = Pointer to the start of the bitWeights array
   LD    A, L                 ;; [ 4]
   AND  #0x07                 ;; [ 7] A = L % 8       (bit number to be tested from the target byte of the array) 
   ADD   C                    ;; [ 4] A += C          (We can do this because we know the vector is 8-byte aligned, and incrementing C by less than 8 will never modify B)
   LD    C, A                 ;; [ 4] BC = BC + L % 8 (Points to the weight of the bit number that is to be tested in the target byte of the array)
   LD    A, (BC)              ;; [ 7] A = BC [L % 8]  (bit weight to be tested in the target byte of the array)

   ;; We need to know how many bytes do we have to 
   ;; jump into the array, to move HL to that point.
   ;; We advance 1 byte for each 8 index positions (8 bits)
   ;; So, first, we calculate INDEX/8 (HL/8) to know the target byte.
   SRL  H            ;; [ 8]
   RR   L            ;; [ 8]
   SRL  H            ;; [ 8]
   RR   L            ;; [ 8]
   SRL  H            ;; [ 8]
   RR   L            ;; [ 8] HL = HL / 8 (Target byte index into the array pointed by DE)

   ;; Reach the target byte and test the bit using the bit weight stored in A
   ADD  HL, DE       ;; [11] HL += DE => HL points to the target byte in the array 
   AND  (HL)         ;; [ 7] Test the selected bit in the target byte in the array
   LD   L, A         ;; [ 4] Return value (0 if bit is not set, !=0 if bit is set)

   RET               ;; [10] Return to caller

;
;########################################################################
;### FUNCTION: cpct_setBit                                            ###
;########################################################################
;### Set the the value of the bit at the given position in the        ###
;### specified array to a given value (0 or 1).                       ###
;### It will asume that the array elements have a size of 8 bits and  ###
;### also that the given position is not bigger than the number of    ###
;### bits in the array (size of the array multiplied by 8).           ###
;### The value to set is also asumed to be 0 or 1, but other values   ###
;### will work (just the least significant bit will be used, so odd   ###
;### values are treated as 1, even vales as 0)                        ###
;### Limitations: Maximum of 65536 bits, 8192 bytes per array.        ###
;########################################################################
;### INPUTS (5 Bytes)                                                 ###
;###  * (2B DE) Array Pointer                                         ###
;###  * (2B HL) Index of the bit to be set                            ###
;###  * (1B C)  Value from 0 to 1 to set in the given position        ###
;########################################################################
;### EXIT STATUS                                                      ###
;###  Destroyed Register values: AF, BC, DE, HL	                      ###
;########################################################################
;### MEASURES                                                         ###
;### MEMORY: 56 bytes (8 table + 48 code)                             ###
;### TIME:                                                            ###
;###   Best Case  (1) = 236 cycles ( 59.00 us)                        ###                                                            ###
;###   Worst Case (0) = 247 cycles ( 61.75 us)                        ###                                                            ###
;########################################################################
;
.globl _cpct_setBit
_cpct_setBit::
   ;; GET Parameters from the stack (Pop + Restoring SP)
   LD (sb_restoreSP+1), SP     ;; [20] Save SP into placeholder of the instruction LD SP, 0, to quickly restore it later.
   DI                          ;; [ 4] Disable interrupts to ensure no one overwrites return address in the stack
   POP  AF                     ;; [10] AF = Return Address
   POP  DE                     ;; [10] DE = Pointer to the bitarray in memory
   POP  HL                     ;; [10] HL = Index of the bit to be set
   POP  BC                     ;; [10] BC => C = Set Value (0/1), B = Undefined
sb_restoreSP:
   LD SP, #0                   ;; [10] -- Restore Stack Pointer -- (0 is a placeholder which is filled up with actual SP value previously)
   EI                          ;; [ 4] Enable interrupts again

   PUSH  BC                    ;; [11] Save BC for later use

   ;; We only access bytes at once in memory. We need to calculate which
   ;; bit will we have to test in the target byte of our array. That will be
   ;; the remainder of INDEX/8, as INDEX/8 represents the byte to access.
   LD    BC, #cpct_bitWeights ;; [10] BC = Pointer to the start of the bitWeights array
   LD    A, L                 ;; [ 4]
   AND  #0x07                 ;; [ 7] A = L % 8       (bit number to be tested from the target byte of the array) 
   ADD   C                    ;; [ 4] A += C          (We can do this because we know the vector is 8-byte aligned, and incrementing C by less than 8 will never modify B)
   LD    C, A                 ;; [ 4] BC = BC + L % 8 (Points to the weight of the bit number that is to be tested in the target byte of the array)
   LD    A, (BC)              ;; [ 7] A = BC [L % 8]  (bit weight to be tested in the target byte of the array)

   ;; We need to know how many bytes do we have to 
   ;; jump into the array, to move HL to that point.
   ;; We advance 1 byte for each 8 index positions (8 bits)
   ;; So, first, we calculate INDEX/8 (HL/8) to know the target byte.
   SRL  H                  ;; [ 8]
   RR   L                  ;; [ 8]
   SRL  H                  ;; [ 8]
   RR   L                  ;; [ 8]
   SRL  H                  ;; [ 8]
   RR   L                  ;; [ 8] HL = HL / 8 (Target byte index into the array pointed by DE)

   ;; Reach the target byte and set/reset the bit using the bit weight stored in A
   ADD  HL, DE             ;; [11] HL += DE => HL points to the target byte in the array 
   POP  BC                 ;; [10] Recover de value of C, previously saved on the stack
   BIT  0, C               ;; [ 8] Test bit 0 to know if we are setting (1) or resetting (0)
   JP NZ, sb_setBitTo1     ;; [10] If Bit=1, We have to set the bit with OR, else we have to reset it with AND
   CPL                     ;; [ 4] A = !A (All bits to 1 except the bit we want to reset)
   AND (HL)                ;; [ 7] Reset the bit making and AND with only the selected bit to 0
   .db #0x38   ; JR C, xx  ;; [ 7] Fake jumping over OR(HL). Carry is never set after and AND.
sb_setBitTo1:
   OR (HL)                 ;; [ 7] Setting the bit with an OR.

   LD  (HL), A             ;; [ 7] Saving the new byte in memory, with the bit setted/resetted

   RET                     ;; [10] Return to caller 

;
;########################################################################
;### FUNCTION: cpct_get2Bits                                          ###
;########################################################################
;### Returns 0, 1, 2 or 3 depending on the value of the group of 2    ###
;### bits at the given position in the specified array.               ###
;### It will asume that the array elements have a size of 8 bits and  ###
;### also that the given position is not bigger than the number of    ###
;### groups of two bits in the array (size of the array multiplied    ###
;### by four).                                                        ###
;########################################################################
;### INPUTS (4 Bytes)                                                 ###
;###  * (2B) Array Pointer                                            ###
;###  * (2B) Position of the group of two bits in the array           ###
;########################################################################
;### EXIT STATUS                                                      ###
;###  0, 1, 2 or 3 in HL     					                      ###
;########################################################################
;### MEASURED TIME                                                    ###
;###  Not computed 	                                                  ###
;########################################################################
;
.globl _cpct_get2Bits
_cpct_get2Bits::

	pop 	af
	pop 	de
	pop 	hl 
	push 	hl 
	push 	de
	push 	af				;; Stack:

	sla 	l 				;; HL <- pos*2 with one left shift.
	rl 		h

	ld		c, l 			;; BC = pos*2+1
	ld		b, h
	inc		bc

	push	hl 				;; Stack: pos*2
	push	bc 				;; Stack: pos*2+1 | pos*2
	push	de 				;; Stack: array | pos*2+1 | pos*2

	call	_cpct_getBit	;; HL = bit2Val

							;; Stack: array | pos*2+1 | pos*2
	pop		de 				;; Stack: pos*2+1 | pos*2
	pop 	bc 				;; Stack: pos*2
	pop 	bc 				;; Stack:
	push 	hl 				;; Stack: bit2Val
	push 	bc 				;; Stack: pos*2 | bit2Val
	push 	de 				;; Stack: array | pos*2 | bit2Val

	call	_cpct_getBit	;; HL = bit1Val

							;; Stack: array | pos*2 | bit2Val
	pop		de 				;; Stack: pos*2 | bit2Val
	pop 	de 				;; Stack: bit2Val
	pop 	de 				;; Stack:

	;; DE = bit2Val, HL = bit1Val

	sla 	l 				;; HL <- bit1Val*2 with one left shift.
	rl 		h

	add 	hl, de 			;; HL <- bit1Val*2 + bit2Val

	ret


;
;########################################################################
;### FUNCTION: cpct_get4Bits					                      ###
;########################################################################
;### Returns an integer from 0 to 15 depending on the value of the    ###
;### group of 4 bits at the given position in the specified array.    ###
;### It will asume that the array elements have a size of 8 bits and  ###
;### also that the given position is not bigger than the number of    ###
;### groups of four bits in the array (size of the array multiplied   ###
;### by 2).                                                           ###
;########################################################################
;### INPUTS (4 Bytes)                                                 ###
;###  * (2B) Array Pointer                                            ###
;###  * (2B) Position of the group of four bits in the array          ###
;########################################################################
;### EXIT STATUS                                                      ###
;###  A value from 0 to 15 in HL				                      ###
;########################################################################
;### MEASURED TIME                                                    ###
;###  Not computed 	                                                  ###
;########################################################################
;
.globl _cpct_get4Bits
_cpct_get4Bits::

	pop 	af
	pop 	de
	pop 	hl 
	push 	hl 
	push 	de
	push 	af				;; Stack:

	sla 	l 				;; HL <- pos*2 with one left shift.
	rl 		h

	ld		c, l 			;; BC = pos*2+1
	ld		b, h
	inc		bc

	push	hl 				;; Stack: pos*2
	push	bc 				;; Stack: pos*2+1 | pos*2
	push	de 				;; Stack: array | pos*2+1 | pos*2

	call	_cpct_get2Bits	;; HL = bitPair2Val

							;; Stack: array | pos*2+1 | pos*2
	pop		de 				;; Stack: pos*2+1 | pos*2
	pop 	bc 				;; Stack: pos*2
	pop 	bc 				;; Stack:
	push 	hl 				;; Stack: bitPair2Val
	push 	bc 				;; Stack: pos*2 | bitPair2Val
	push 	de 				;; Stack: array | pos*2 | bitPair2Val

	call	_cpct_get2Bits	;; HL = bitPair1Val

							;; Stack: array | pos*2 | bitPair2Val
	pop		de 				;; Stack: pos*2 | bitPair2Val
	pop 	de 				;; Stack: bitPair2Val
	pop 	de 				;; Stack:

	;; DE = bitPair2Val, HL = bitPair1Val

	sla 	l 				;; HL <- bitPair1Val*4 with two left shifts.
	rl 		h
	sla 	l 
	rl 		h

	add 	hl, de 			;; HL <- bitPair1Val*4 + bitPair2Val

	ret

;
;########################################################################
;### FUNCTION: cpct_set2Bits					                      ###
;########################################################################
;### Set the the value of the group of 2 bits at the given position   ###
;### in the specified array to a given value.                         ###
;### It will asume that the array elements have a size of 8 bits and  ###
;### also that the given position is not bigger than the number of    ###
;### groups of four bits in the array (size of the array multiplied   ###
;### by 4). The value to set is also asumed to be lower than 4.       ###
;########################################################################
;### INPUTS (4 Bytes)                                                 ###
;###  * (2B) Array Pointer                                            ###
;###  * (2B) Position of the group of four bits in the array          ###
;###  * (2B) Value from 0 to 3  to set in the given position          ###
;########################################################################
;### EXIT STATUS                                                      ###
;###  Destroyed Register values: AF, BC, DE, HL	                      ###
;########################################################################
;### MEASURED TIME                                                    ###
;###  Not computed 	                                                  ###
;########################################################################
;
.globl _cpct_set2Bits
_cpct_set2Bits::

	pop 	af
	pop 	de 				;; DE <- array
	pop 	bc  			;; BC <- pos
	pop 	hl 				;; HL <- value
	push 	hl 
	push 	bc 
	push 	de
	push 	af 				;; Stack:

	push	hl 				;; Stack: value

	srl 	h 				;; HL <- value/2 with one right shift.
	rr 		l

	pop		af
	push 	hl 				;; Stack: value/2

	push 	af 				;; HL <- value 
	pop		hl

	ld 		a, l 			;; HL = value%2
	and 	a, #0x01
	ld 		l, a
	ld 		h, #0x00
	;;add 	hl, hl

	sla 	c 				;; BC <- pos*2 with one left shift.
	rl 		b

	push	bc 				;; Stack: pos*2 | value/2

	inc		bc 				;; BC = pos*2+1

	push	hl 				;; Stack: value%2 | pos*2 | value/2
	push	bc 				;; Stack: pos*2+1 | value%2 | pos*2 | value/2
	push	de 				;; Stack: array | pos*2+1 | value%2 | pos*2 | value/2

	call	_cpct_setBit

							;; Stack: array | pos*2+1 | value%2 | pos*2 | value/2
	pop		de 				;; Stack: pos*2+1 | value%2 | pos*2 | value/2
	pop 	bc 				;; Stack: value%2 | pos*2 | value/2
	pop 	bc 				;; Stack: pos*2 | value/2

	push 	de 				;; Stack: array | pos*2 | value/2

	call	_cpct_setBit

							;; Stack: array | pos*2 | value/2
	pop		de 				;; Stack: pos*2 | value/2
	pop 	de 				;; Stack: value/2
	pop 	de 				;; Stack:

	ret


;
;########################################################################
;### FUNCTION: cpct_set4Bits					                      ###
;########################################################################
;### Set the the value of the group of 4 bits at the given position   ###
;### in the specified array to a given value.                         ###
;### It will asume that the array elements have a size of 8 bits and  ###
;### also that the given position is not bigger than the number of    ###
;### groups of four bits in the array (size of the array multiplied   ###
;### by 2). The value to set is also asumed to be lower than 16.      ###
;########################################################################
;### INPUTS (4 Bytes)                                                 ###
;###  * (2B) Array Pointer                                            ###
;###  * (2B) Position of the group of four bits in the array          ###
;###  * (2B) Value from 0 to 15 to set in the given position          ###
;########################################################################
;### EXIT STATUS                                                      ###
;###  Destroyed Register values: AF, BC, DE, HL	                      ###
;########################################################################
;### MEASURED TIME                                                    ###
;###  Not computed 	                                                  ###
;########################################################################
;
.globl _cpct_set4Bits
_cpct_set4Bits::

	pop 	af
	pop 	de
	pop 	bc 
	pop 	hl
	push 	hl 
	push 	bc 
	push 	de
	push 	af 				;; Stack:

	push	hl 				;; AF <- value

	srl 	h 				;; HL <- value/4 with two rigth shifts.
	rr 		l
	srl 	h 
	rr 		l

	pop		af
	push 	hl 				;; Stack: value/4

	push 	af 				;; hl <- value 
	pop		hl

	ld 		a, l 			;; HL = value%4
	and 	a, #0x03
	ld 		l, a
	ld 		h, #0x00

	sla 	c 				;; HL <- pos*2 with one left shift.
	rl 		b

	push	bc 				;; Stack: pos*2 | value/4

	inc		bc 				;; BC = pos*2+1

	push	hl 				;; Stack: value%4 | pos*2 | value/4
	push	bc 				;; Stack: pos*2+1 | value%4 | pos*2 | value/4
	push	de 				;; Stack: array | pos*2+1 | value%4 | pos*2 | value/4

	call	_cpct_set2Bits

							;; Stack: array | pos*2+1 | value%4 | pos*2 | value/4
	pop		de 				;; Stack: pos*2+1 | value%4 | pos*2 | value/4
	pop 	bc 				;; Stack: value%4 | pos*2 | value/4
	pop 	bc 				;; Stack: pos*2 | value/4

	push 	de 				;; Stack: array | pos*2 | value/4

	call	_cpct_set2Bits

							;; Stack: array | pos*2 | value/4
	pop		de 				;; Stack: pos*2 | value/4
	pop 	de 				;; Stack: value/4
	pop 	de 				;; Stack:

	ret