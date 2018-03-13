;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2014-2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
.module cpct_sprites

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawTileAligned2x4_f
;;
;;    Copies a 2x4-byte sprite to video memory (or screen buffer), assuming that
;; location to be copied is in Pixel Lines 0-3 of a character line. 
;;
;; C Definition:
;;    void <cpct_drawTileAligned2x4_f> (void* *sprite*, void* *memory*) __z88dk_callee;
;;
;; Input Parameters (4 bytes):
;;  (2B HL) sprite - Source Sprite Pointer (8-byte array with 8-bit pixel data)
;;  (2B DE) memory - Pointer (aligned) to the first byte in video memory where the sprite will be copied.
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_drawTileAligned2x4_f_asm
;;
;; Parameter Restrictions:
;;    * *sprite* must be a pointer to an array array containing sprite's pixels
;; data in screen pixel format. Sprite must be rectangular and all bytes in the 
;; array must be consecutive pixels, starting from top-left corner and going 
;; left-to-right, top-to-bottom down to the bottom-right corner. Total amount of
;; bytes in pixel array should be *8*. You may check screen pixel format for
;; mode 0 (<cpct_px2byteM0>) and mode 1 (<cpct_px2byteM1>) as for mode 2 is 
;; linear (1 bit = 1 pixel).
;;    * *memory* must be a pointer to the first byte in video memory (or screen
;; buffer) where the sprite will be drawn. This location *must be aligned*, 
;; meaning that it must be between Pixel Line 0 and Pixel Line 3 of a screen 
;; character line. To Know more about pixel lines and character lines on screen, 
;; take a look at <cpct_drawSprite>. If *memory* points to a not aligned byte 
;; (one pertaining to a Non-[0-3] Pixel Line of a character line), this function 
;; will overwrite random parts of the memory, with unexpected results (typically, 
;; bad drawing results, erratic program behaviour, hangs and crashes).
;;
;; Known limitations:
;;     * This function does not do any kind of boundary check or clipping. If you 
;; try to draw sprites on the frontier of your video memory or screen buffer 
;; if might potentially overwrite memory locations beyond boundaries. This 
;; could cause your program to behave erratically, hang or crash. Always 
;; take the necessary steps to guarantee that you are drawing inside screen
;; or buffer boundaries.
;;     * As this function receives a byte-pointer to memory, it can only 
;; draw byte-sized and byte-aligned sprites. This means that the sprite cannot
;; start on non-byte aligned pixels (like odd-pixels, for instance) and 
;; their sizes must be a multiple of a byte (2 in mode 0, 4 in mode 1 and
;; 8 in mode 2).
;;    * Although this function can be used under hardware-scrolling conditions,
;; it does not take into account video memory wrap-around (0x?7FF or 0x?FFF 
;; addresses, the end of character pixel lines).It will produce a "step" 
;; in the middle of tiles when drawing near wrap-around.
;;
;; Details:
;;    Copies a 2x4-byte sprite from an array with 8 screen pixel format 
;; bytes to video memory or a screen buffer. This function is tagged 
;; *aligned*, meaning that the destination byte must be *character aligned*. 
;; Being character aligned means that the 4 lines of the sprite need to
;; be withing the 8 lines of a character line in video memory (or 
;; in any screen buffer). For more details about video memory character
;; and pixel lines check table 1 at <cpct_drawSprite>.
;;
;;    As the 4 lines of the sprite must be inside a character line on video 
;; memory (or screen buffer), *memory* destination pointer must point to
;; any of the first 4 lines (Pixel Lines 0 to 3) of a character line. If 
;; hardware scrolling has not been used, all pixel lines 0-3 are contained 
;; inside one of these 4 ranges:
;;
;;    [ 0xC000 -- 0xDFFF ] - RAM Bank 3 (Default Video Memory Bank)
;;    [ 0x8000 -- 0x9FFF ] - RAM Bank 2
;;    [ 0x4000 -- 0x5FFF ] - RAM Bank 1
;;    [ 0x0000 -- 0x1FFF ] - RAM Bank 0
;;
;;    All of them have 1 bit in common: bit 5 is always 0 (xx0xxxxx). Any 
;; address not having this bit set to 0 will refer to Pixel Lines 4-7 
;; in any given Character Line, and are not considered to be aligned.
;;
;;    This function will just copy bytes, not taking care of colours or 
;; transparencies. If you wanted to copy a sprite without erasing the background
;; just check for masked sprites and <cpct_drawMaskedSprite>.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    C-bindings   - 37 bytes
;;    ASM-bindings - 33 bytes 
;;
;; Time Measures:
;; (start code)
;;    Case    | microSecs (us) | CPU Cycles 
;; -----------------------------------------
;;    Any     |       71       |   284
;; -----------------------------------------
;; Asm saving |      -13       |   -52 
;; -----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld    a, d               ;; [1] Save D into A for fastly doing +800h increment of DE
   ld    b, e               ;; [1] Save E into B for fastly restoring DE every "loop"
   ld    c, #9              ;; [2] Ensure LDIs do not modify the value of b

   ;; First line of pixels   
   ldi                      ;; [5] Copy 2 bytes for (HL) to (DE) and decrement BC 
   ldi                      ;; [5]
   add   #8                 ;; [2] D += 8 (To add 800h to DE, we increment previous value of D by 8...
   ld    d, a               ;; [1] ... and move it into D)
   ld    e, b               ;; [1] Restore the original value of E

   ;; Second line of pixels   
   ldi                      ;; [5] Copy 2 bytes for (HL) to (DE) and decrement BC 
   ldi                      ;; [5]
   add   #8                 ;; [2] D += 8 (To add 800h to DE, we increment previous value of D by 8...
   ld    d, a               ;; [1] ... and move it into D)
   ld    e, b               ;; [1] Restore the original value of E

   ;; Third line of pixels   
   ldi                      ;; [5] Copy 2 bytes for (HL) to (DE) and decrement BC 
   ldi                      ;; [5]
   add   #8                 ;; [2] D += 8 (To add 800h to DE, we increment previous value of D by 8...
   ld    d, a               ;; [1] ... and move it into D)
   ld    e, b               ;; [1] Restore the original value of E

   ;; Fourth line of pixels   
   ldi                      ;; [5] Copy 2 bytes for (HL) to (DE) and decrement BC 
   ld    a, (hl)            ;; [2]
   ld (de), a               ;; [2]

   ;; Return
   ret                      ;; [3]
