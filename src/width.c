/* Determine display width of Unicode character.
   Copyright (C) 2001-2002 Free Software Foundation, Inc.
   Written by Bruno Haible <bruno@clisp.org>, 2002.

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU Library General Public License as published
   by the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
   USA.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

/* Specification.  */
#include "uniwidth.h"

#include "cjk.h"

/*
 * Non-spacing attribute table.
 * Consists of:
 * - Non-spacing characters; generated from PropList.txt or
 *   "grep '^[^;]*;[^;]*;[^;]*;[^;]*;NSM;' UnicodeData.txt"
 * - Format control characters; generated from
 *   "grep '^[^;]*;[^;]*;Cf;' UnicodeData.txt"
 * - Zero width characters; generated from
 *   "grep '^[^;]*;ZERO WIDTH ' UnicodeData.txt"
 */
static const unsigned char nonspacing_table_data[16*64] = {
  /* 0x0000-0x01ff */
  0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, /* 0x0000-0x003f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, /* 0x0040-0x007f */
  0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, /* 0x0080-0x00bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x00c0-0x00ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0100-0x013f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0140-0x017f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0180-0x01bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x01c0-0x01ff */
  /* 0x0200-0x03ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0200-0x023f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0240-0x027f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0280-0x02bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x02c0-0x02ff */
  0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, /* 0x0300-0x033f */
  0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, /* 0x0340-0x037f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0380-0x03bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x03c0-0x03ff */
  /* 0x0400-0x05ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0400-0x043f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0440-0x047f */
  0x78, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0480-0x04bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x04c0-0x04ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0500-0x053f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0540-0x057f */
  0x00, 0x00, 0xfe, 0xff, 0xfb, 0xff, 0xff, 0xbb, /* 0x0580-0x05bf */
  0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x05c0-0x05ff */
  /* 0x0600-0x07ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0600-0x063f */
  0x00, 0xf8, 0x3f, 0x00, 0x00, 0x00, 0x01, 0x00, /* 0x0640-0x067f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0680-0x06bf */
  0x00, 0x00, 0xc0, 0xff, 0x9f, 0x3d, 0x00, 0x00, /* 0x06c0-0x06ff */
  0x00, 0x80, 0x02, 0x00, 0x00, 0x00, 0xff, 0xff, /* 0x0700-0x073f */
  0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0740-0x077f */
  0x00, 0x00, 0x00, 0x00, 0xc0, 0xff, 0x01, 0x00, /* 0x0780-0x07bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x07c0-0x07ff */
  /* 0x0800-0x09ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0800-0x083f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0840-0x087f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0880-0x08bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x08c0-0x08ff */
  0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, /* 0x0900-0x093f */
  0xfe, 0x21, 0x1e, 0x00, 0x0c, 0x00, 0x00, 0x00, /* 0x0940-0x097f */
  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, /* 0x0980-0x09bf */
  0x1e, 0x20, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, /* 0x09c0-0x09ff */
  /* 0x0a00-0x0bff */
  0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, /* 0x0a00-0x0a3f */
  0x86, 0x39, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, /* 0x0a40-0x0a7f */
  0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, /* 0x0a80-0x0abf */
  0xbe, 0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0ac0-0x0aff */
  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, /* 0x0b00-0x0b3f */
  0x0e, 0x20, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0b40-0x0b7f */
  0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0b80-0x0bbf */
  0x01, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0bc0-0x0bff */
  /* 0x0c00-0x0dff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, /* 0x0c00-0x0c3f */
  0xc1, 0x3d, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0c40-0x0c7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, /* 0x0c80-0x0cbf */
  0x40, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0cc0-0x0cff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0d00-0x0d3f */
  0x0e, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0d40-0x0d7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0d80-0x0dbf */
  0x00, 0x04, 0x5c, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0dc0-0x0dff */
  /* 0x0e00-0x0fff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf2, 0x07, /* 0x0e00-0x0e3f */
  0x80, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0e40-0x0e7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf2, 0x1b, /* 0x0e80-0x0ebf */
  0x00, 0x3f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0ec0-0x0eff */
  0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0xa0, 0x02, /* 0x0f00-0x0f3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0x7f, /* 0x0f40-0x0f7f */
  0xdf, 0x00, 0xff, 0xfe, 0xff, 0xff, 0xff, 0x1f, /* 0x0f80-0x0fbf */
  0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x0fc0-0x0fff */
  /* 0x1000-0x11ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0xc5, 0x02, /* 0x1000-0x103f */
  0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, /* 0x1040-0x107f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1080-0x10bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x10c0-0x10ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1100-0x113f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1140-0x117f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1180-0x11bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x11c0-0x11ff */
  /* 0x1600-0x17ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1600-0x163f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1640-0x167f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1680-0x16bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x16c0-0x16ff */
  0x00, 0x00, 0x1c, 0x00, 0x00, 0x00, 0x1c, 0x00, /* 0x1700-0x173f */
  0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x0c, 0x00, /* 0x1740-0x177f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3f, /* 0x1780-0x17bf */
  0x40, 0xfe, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x17c0-0x17ff */
  /* 0x1800-0x19ff */
  0x00, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1800-0x183f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1840-0x187f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, /* 0x1880-0x18bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x18c0-0x18ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1900-0x193f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1940-0x197f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1980-0x19bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x19c0-0x19ff */
  /* 0x2000-0x21ff */
  0x00, 0xf8, 0x00, 0x00, 0x00, 0x7c, 0x00, 0x00, /* 0x2000-0x203f */
  0x00, 0x00, 0x00, 0x00, 0x0f, 0xfc, 0x00, 0x00, /* 0x2040-0x207f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x2080-0x20bf */
  0x00, 0x00, 0xff, 0xff, 0xff, 0x07, 0x00, 0x00, /* 0x20c0-0x20ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x2100-0x213f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x2140-0x217f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x2180-0x21bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x21c0-0x21ff */
  /* 0x3000-0x31ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0xfc, 0x00, 0x00, /* 0x3000-0x303f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x3040-0x307f */
  0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, /* 0x3080-0x30bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30c0-0x30ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x3100-0x313f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x3140-0x317f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x3180-0x31bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x31c0-0x31ff */
  /* 0xfa00-0xfbff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfa00-0xfa3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfa40-0xfa7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfa80-0xfabf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfac0-0xfaff */
  0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, /* 0xfb00-0xfb3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfb40-0xfb7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfb80-0xfbbf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfbc0-0xfbff */
  /* 0xfe00-0xffff */
  0xff, 0xff, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, /* 0xfe00-0xfe3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfe40-0xfe7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xfe80-0xfebf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, /* 0xfec0-0xfeff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xff00-0xff3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xff40-0xff7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xff80-0xffbf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0e, /* 0xffc0-0xffff */
  /* 0x1d000-0x1d1ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1d000-0x1d03f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1d040-0x1d07f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1d080-0x1d0bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1d0c0-0x1d0ff */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x1d100-0x1d13f */
  0x00, 0x00, 0x00, 0x00, 0x80, 0x03, 0x00, 0xf8, /* 0x1d140-0x1d17f */
  0xe7, 0x0f, 0x00, 0x00, 0x00, 0x3c, 0x00, 0x00, /* 0x1d180-0x1d1bf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  /* 0x1d1c0-0x1d1ff */
};
static const signed char nonspacing_table_ind[240] = {
   0,  1,  2,  3,  4,  5,  6,  7, /* 0x0000-0x0fff */
   8, -1, -1,  9, 10, -1, -1, -1, /* 0x1000-0x1fff */
  11, -1, -1, -1, -1, -1, -1, -1, /* 0x2000-0x2fff */
  12, -1, -1, -1, -1, -1, -1, -1, /* 0x3000-0x3fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x4000-0x4fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x5000-0x5fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x6000-0x6fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x7000-0x7fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x8000-0x8fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x9000-0x9fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0xa000-0xafff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0xb000-0xbfff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0xc000-0xcfff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0xd000-0xdfff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0xe000-0xefff */
  -1, -1, -1, -1, -1, 13, -1, 14, /* 0xf000-0xffff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x10000-0x10fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x11000-0x11fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x12000-0x12fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x13000-0x13fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x14000-0x14fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x15000-0x15fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x16000-0x16fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x17000-0x17fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x18000-0x18fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x19000-0x19fff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x1a000-0x1afff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x1b000-0x1bfff */
  -1, -1, -1, -1, -1, -1, -1, -1, /* 0x1c000-0x1cfff */
  15, -1, -1, -1, -1, -1, -1, -1  /* 0x1d000-0x1dfff */
};

/* Determine number of column positions required for UC.  */
int
uc_width (ucs4_t uc, const char *encoding)
{
  /* Test for non-spacing or control character.  */
  if ((uc >> 9) < 240)
    {
      int ind = nonspacing_table_ind[uc >> 9];
      if (ind >= 0)
	if ((nonspacing_table_data[64*ind + ((uc >> 3) & 63)] >> (uc & 7)) & 1)
	  {
	    if (uc > 0 && uc < 0x100)
	      return -1;
	    else
	      return 0;
	  }
    }
  else if ((uc >> 9) == (0xe0000 >> 9))
    {
      if (uc >= 0xe0020 ? uc <= 0xe007f : uc == 0xe0001)
	return 0;
    }
  /* Test for double-width character.
   * Generated from "grep '^....;[WF]' EastAsianWidth.txt"
   * and            "grep '^....;[^WF]' EastAsianWidth.txt"
   */
  if (uc >= 0x1100
      && ((uc < 0x1160) /* Hangul Jamo */
	  || (uc >= 0x2e80 && uc < 0xa4d0  /* CJK ... Yi */
	      && !(uc == 0x303f))
	  || (uc >= 0xac00 && uc < 0xd7a4) /* Hangul Syllables */
	  || (uc >= 0xf900 && uc < 0xfb00) /* CJK Compatibility Ideographs */
	  || (uc >= 0xfe30 && uc < 0xfe70) /* CJK Compatibility Forms */
	  || (uc >= 0xff00 && uc < 0xff61) /* Fullwidth Forms */
	  || (uc >= 0xffe0 && uc < 0xffe7)
	  || (uc >= 0x20000 && uc <= 0x2a6d6) /* CJK */
	  || (uc >= 0x2f800 && uc <= 0x2fa1d) /* CJK Compatibility Ideographs */
     )   )
    return 2;
  /* In ancient CJK encodings, Cyrillic and most other characters are
     double-width as well.  */
  if (uc >= 0x00A1 && uc < 0xFF61 && uc != 0x20A9
      && is_cjk_encoding (encoding))
    return 2;
  return 1;
}
