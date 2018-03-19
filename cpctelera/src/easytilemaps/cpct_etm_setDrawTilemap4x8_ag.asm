;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_easytilemaps
;;-------------------------------------------------------------------------------
;; C bindings for <cpct_etm_setDrawTileMap4x8_ag>
;;
;; BC  = B:Height, C:Width
;; DE  = Tileset Pointer
;; HL  = tilemapWidth
;;
;; Destroyed Register values: 
;;      AF, DE
;;
;; Required memory:
;;      C-bindings - 48 bytes (+165 bytes from <cpct_etm_drawTileMap4x8_ag> which is included)
;;    ASM-bindings - 44 bytes (+153 bytes from <cpct_etm_drawTileMap4x8_ag_asm> which is included)
;;
;; Time Measures:
;; (start code)
;;    Case     | microSecs (us) | CPU Cycles  
;; ------------------------------------------
;;    Any      |      71        |    284
;; ------------------------------------------
;; ASM Saving  |     -15        |    -60
;; ------------------------------------------
;; (end code)
;;    W - Map width (number of horizontal tiles)
;;-------------------------------------------------------------------------------

;;
;; Macro that generates the code for setDrawTileMap4x8_ag and couples it to the labels
;; that it has to modify. A label prefix is passed to generate different kinds of labels
;; for different bindings
;;
.macro setDrawTileMap4x8_ag_gen lblPrf

;; Declare global symbols used here
.globl lblPrf'tilesetPtr
.globl lblPrf'widthHeightSet
.globl lblPrf'restoreWidth
.globl lblPrf'updateWidth
.globl lblPrf'incrementHL
.globl lblPrf'restoreI

   ;; Set (tilesetPtr) placeholder
   ld (lblPrf'tilesetPtr), hl     ;; [5] Save HL into tilesetPtr placeholder

   ;; Set all Width values required by drawTileMap4x8_ag. First two values
   ;; (heightSet, widthSet) are values used at the start of the function for
   ;; initialization. The other one (restoreWidth) restores the value of the
   ;; width after each loop, as it is used as counter and decremented to 0.
   ld (lblPrf'widthHeightSet), bc ;; [6]
   ld     a, c                    ;; [1]
   ld (lblPrf'restoreWidth), a    ;; [4] Set restore width after each loop placeholder
   
   ;; In order to properly show a view of (Width x Height) tiles from within the
   ;; tilemap, every time a row has been drawn, we need to move tilemap pointer
   ;; to the start of the next row. As the complete tilemap is (tilemapWidth) bytes
   ;; wide and we are showing a view only (Width) tiles wide, to complete (tilemapWidth)
   ;; bytes at each loop, we need to add (tilemapWidth - Width) bytes.
   sub_de_a                      ;; [7] tilemapWidth - Width
   ld (lblPrf'updateWidth), de   ;; [6] set the difference in updateWidth placeholder

   ;; Calculate HL update that has to be performed for each new row loop.
   ;; HL advances through video memory as tiles are being drawn. When a row
   ;; is completely drawn, HL is at the right-most place of the screen.
   ;; As each screen row has a width of 0x50 bytes (in standard modes), 
   ;; if the Row that has been drawn has less than 0x50 bytes, this difference
   ;; has to be added to HL to make it point to the start of next screen row.
   ;; As each tile is 4-bytes wide, this amount is (0x50 - 4*Width). Also,
   ;; taking into account that 4*Width cannot exceed 255 (1-byte), a maximum
   ;; of 63 tiles can be considered as Width.
   ld     a, c                ;; [1] A = Width
   add    a                   ;; [1] A = 2*Width
   add    a                   ;; [1] A = 4*Width
   cpl                        ;; [1] A = -4*Width - 1
   add #0x50 + 1              ;; [2] A = -4*Width-1 + 0x50+1 = 0x50 - 4*Width
   ld (lblPrf'incrementHL), a ;; [4] Set HL increment in its placeholder

   ;; Set the restoring of Interrupt Status. drawTileMap4x8_ag disables interrupts before
   ;; drawing each tile row, and then it restores previous interrupt status after the row
   ;; has been drawn. To do this, present interrupt status is considered. This code detects
   ;; present interrupt status and sets a EI/DI instruction at the end of tile row drawing
   ;; to either reactivate interrupts or preserve interrupts disabled.
   ld     a, i             ;; [3] P/V flag set to current interrupt status (IFF2 flip-flop)
   ld     a, #opc_EI       ;; [2] A = Opcode for Enable Interrupts instruction (EI = 0xFB)
   jp    pe, int_enabled   ;; [3] If interrupts are enabled, EI is the appropriate instruction
     ld   a, #opc_DI       ;; [2] Otherwise, it is DI, so A = Opcode for Disable Interrupts instruction (DI = 0xF3)
int_enabled:
   ld (lblPrf'restoreI), a ;; [4] Set the Restore Interrupt status at the end with corresponding DI or EI

   ret                     ;; [3] Return to caller

.endm
