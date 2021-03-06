//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine 
//  Copyright (C) 2014-2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//------------------------------------------------------------------------------

#include <types.h>

//
// Sprite definitions used in this example
//

// Waves sprite, 2x4 bytes size (4x4 mode 0 pixels)
const u8 waves_2x4[8] = {
   0xE0,0xE0,
   0xD0,0xD0,
   0x58,0x58,
   0xA4,0xA4
};


// Waves sprite, 2x8 bytes size (4x8 mode 0 pixels)
const u8 waves_2x8[16] = {
   0xE0,0xE0,
   0xD0,0xD0,
   0x58,0x58,
   0xA4,0xA4,
   0xD8,0xD8,
   0xE4,0xE4,
   0xF2,0xF2,
   0xF1,0xF1 };

// F sprite, 2x8 bytes size (4x8 mode 0 pixels)
const u8 F_2x8[16] = {
   0x0C,0x3C,
   0x4C,0x9C,
   0x4C,0x3C,
   0x6C,0x8C,
   0x6C,0x0C,
   0x6C,0x58,
   0x3C,0x58,
   0xF0,0xF0  };
        
// Waves sprite, 4x4 bytes size (8x4 mode 0 pixels)
const u8 waves_4x4[16] = {       
  0x03,0xC3,0x0C,0xC0,
  0x47,0xE1,0x4C,0x60,
  0x52,0xCB,0x18,0xC8,
  0x47,0xE1,0x4C,0x60
};

// Waves sprite, 4x8 bytes size (8x8 mode 0 pixels)
const u8 waves_4x8[32] = {       
  0x03,0xC3,0x0C,0xC0,
  0x47,0xE1,0x4C,0x60,
  0x52,0xCB,0x18,0xC8,
  0x47,0xE1,0x4C,0x60,
  0x52,0xCB,0x18,0xC8,
  0x47,0xE1,0x4C,0x60,
  0x52,0xCB,0x18,0xC8,
  0x03,0xC3,0x0C,0xC0 
};

// Inverted waves sprite, 4x8 bytes size (8x8 mode 0 pixels)
const u8 FF_4x8[32] = {
  0x61,0xC3,0xC3,0x92,
  0x61,0x33,0x33,0x72,
  0x61,0x72,0xF0,0xF0,
  0x61,0x33,0x32,0x30,
  0x61,0x33,0x72,0x30,
  0x61,0x72,0xF0,0x30,
  0x61,0x72,0x30,0x30,
  0x30,0xF0,0x30,0x30  
}; 
