/*
 * Copyright (C) 1999-2001 Free Software Foundation, Inc.
 * This file is part of the GNU LIBICONV Library.
 *
 * The GNU LIBICONV Library is free software; you can redistribute it
 * and/or modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * The GNU LIBICONV Library is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with the GNU LIBICONV Library; see the file COPYING.LIB.
 * If not, write to the Free Software Foundation, Inc., 59 Temple Place -
 * Suite 330, Boston, MA 02111-1307, USA.
 */

/*
 * CP1258
 */

#include "flushwc.h"
#include "vietcomb.h"

static const unsigned char cp1258_comb_table[] = {
  0xcc, 0xec, 0xde, 0xd2, 0xf2,
};

static const unsigned short cp1258_2uni[128] = {
  /* 0x80 */
  0x20ac, 0xfffd, 0x201a, 0x0192, 0x201e, 0x2026, 0x2020, 0x2021,
  0x02c6, 0x2030, 0xfffd, 0x2039, 0x0152, 0xfffd, 0xfffd, 0xfffd,
  /* 0x90 */
  0xfffd, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014,
  0x02dc, 0x2122, 0xfffd, 0x203a, 0x0153, 0xfffd, 0xfffd, 0x0178,
  /* 0xa0 */
  0x00a0, 0x00a1, 0x00a2, 0x00a3, 0x00a4, 0x00a5, 0x00a6, 0x00a7,
  0x00a8, 0x00a9, 0x00aa, 0x00ab, 0x00ac, 0x00ad, 0x00ae, 0x00af,
  /* 0xb0 */
  0x00b0, 0x00b1, 0x00b2, 0x00b3, 0x00b4, 0x00b5, 0x00b6, 0x00b7,
  0x00b8, 0x00b9, 0x00ba, 0x00bb, 0x00bc, 0x00bd, 0x00be, 0x00bf,
  /* 0xc0 */
  0x00c0, 0x00c1, 0x00c2, 0x0102, 0x00c4, 0x00c5, 0x00c6, 0x00c7,
  0x00c8, 0x00c9, 0x00ca, 0x00cb, 0x0300, 0x00cd, 0x00ce, 0x00cf,
  /* 0xd0 */
  0x0110, 0x00d1, 0x0309, 0x00d3, 0x00d4, 0x01a0, 0x00d6, 0x00d7,
  0x00d8, 0x00d9, 0x00da, 0x00db, 0x00dc, 0x01af, 0x0303, 0x00df,
  /* 0xe0 */
  0x00e0, 0x00e1, 0x00e2, 0x0103, 0x00e4, 0x00e5, 0x00e6, 0x00e7,
  0x00e8, 0x00e9, 0x00ea, 0x00eb, 0x0301, 0x00ed, 0x00ee, 0x00ef,
  /* 0xf0 */
  0x0111, 0x00f1, 0x0323, 0x00f3, 0x00f4, 0x01a1, 0x00f6, 0x00f7,
  0x00f8, 0x00f9, 0x00fa, 0x00fb, 0x00fc, 0x01b0, 0x20ab, 0x00ff,
};

/* In the CP1258 to Unicode direction, the state contains a buffered
   character, or 0 if none. */

static int
cp1258_mbtowc (conv_t conv, ucs4_t *pwc, const unsigned char *s, int n)
{
  unsigned char c = *s;
  unsigned short wc;
  unsigned short last_wc;
  if (c < 0x80) {
    wc = c;
  } else {
    wc = cp1258_2uni[c-0x80];
    if (wc == 0xfffd)
      return RET_ILSEQ;
  }
  last_wc = conv->istate;
  if (last_wc) {
    if (wc >= 0x0300 && wc < 0x0340) {
      /* See whether last_wc and wc can be combined. */
      unsigned int k;
      unsigned int i1, i2;
      switch (wc) {
        case 0x0300: k = 0; break;
        case 0x0301: k = 1; break;
        case 0x0303: k = 2; break;
        case 0x0309: k = 3; break;
        case 0x0323: k = 4; break;
        default: abort();
      }
      i1 = viet_comp_table[k].idx;
      i2 = i1 + viet_comp_table[k].len-1;
      if (last_wc >= viet_comp_table_data[i1].base
          && last_wc <= viet_comp_table_data[i2].base) {
        unsigned int i;
        for (;;) {
          i = (i1+i2)>>1;
          if (last_wc == viet_comp_table_data[i].base)
            break;
          if (last_wc < viet_comp_table_data[i].base) {
            if (i1 == i)
              goto not_combining;
            i2 = i;
          } else {
            if (i1 != i)
              i1 = i;
            else {
              i = i2;
              if (last_wc == viet_comp_table_data[i].base)
                break;
              goto not_combining;
            }
          }
        }
        last_wc = viet_comp_table_data[i].composed;
        /* Output the combined character. */
        conv->istate = 0;
        *pwc = (ucs4_t) last_wc;
        return 1;
      }
    }
  not_combining:
    /* Output the buffered character. */
    conv->istate = 0;
    *pwc = (ucs4_t) last_wc;
    return 0; /* Don't advance the input pointer. */
  }
  if (wc >= 0x0041 && wc <= 0x01b0) {
    /* wc is a possible match in viet_comp_table_data. Buffer it. */
    conv->istate = wc;
    return RET_TOOFEW(1);
  } else {
    /* Output wc immediately. */
    *pwc = (ucs4_t) wc;
    return 1;
  }
}

#define cp1258_flushwc normal_flushwc

static const unsigned char cp1258_page00[88] = {
  0xc0, 0xc1, 0xc2, 0x00, 0xc4, 0xc5, 0xc6, 0xc7, /* 0xc0-0xc7 */
  0xc8, 0xc9, 0xca, 0xcb, 0x00, 0xcd, 0xce, 0xcf, /* 0xc8-0xcf */
  0x00, 0xd1, 0x00, 0xd3, 0xd4, 0x00, 0xd6, 0xd7, /* 0xd0-0xd7 */
  0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0x00, 0x00, 0xdf, /* 0xd8-0xdf */
  0xe0, 0xe1, 0xe2, 0x00, 0xe4, 0xe5, 0xe6, 0xe7, /* 0xe0-0xe7 */
  0xe8, 0xe9, 0xea, 0xeb, 0x00, 0xed, 0xee, 0xef, /* 0xe8-0xef */
  0x00, 0xf1, 0x00, 0xf3, 0xf4, 0x00, 0xf6, 0xf7, /* 0xf0-0xf7 */
  0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0x00, 0x00, 0xff, /* 0xf8-0xff */
  /* 0x0100 */
  0x00, 0x00, 0xc3, 0xe3, 0x00, 0x00, 0x00, 0x00, /* 0x00-0x07 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x08-0x0f */
  0xd0, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x10-0x17 */
};
static const unsigned char cp1258_page01[104] = {
  0x00, 0x00, 0x8c, 0x9c, 0x00, 0x00, 0x00, 0x00, /* 0x50-0x57 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x58-0x5f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x60-0x67 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x68-0x6f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x70-0x77 */
  0x9f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x78-0x7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x80-0x87 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x88-0x8f */
  0x00, 0x00, 0x83, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x90-0x97 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x98-0x9f */
  0xd5, 0xf5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xa0-0xa7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdd, /* 0xa8-0xaf */
  0xfd, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xb0-0xb7 */
};
static const unsigned char cp1258_page02[32] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x88, 0x00, /* 0xc0-0xc7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xc8-0xcf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xd0-0xd7 */
  0x00, 0x00, 0x00, 0x00, 0x98, 0x00, 0x00, 0x00, /* 0xd8-0xdf */
};
static const unsigned char cp1258_page03[40] = {
  0xcc, 0xec, 0x00, 0xde, 0x00, 0x00, 0x00, 0x00, /* 0x00-0x07 */
  0x00, 0xd2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x08-0x0f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x18-0x1f */
  0x00, 0x00, 0x00, 0xf2, 0x00, 0x00, 0x00, 0x00, /* 0x20-0x27 */
};
static const unsigned char cp1258_page20[48] = {
  0x00, 0x00, 0x00, 0x96, 0x97, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0x91, 0x92, 0x82, 0x00, 0x93, 0x94, 0x84, 0x00, /* 0x18-0x1f */
  0x86, 0x87, 0x95, 0x00, 0x00, 0x00, 0x85, 0x00, /* 0x20-0x27 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0x89, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0x8b, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x38-0x3f */
};

static int
cp1258_wctomb (conv_t conv, unsigned char *r, ucs4_t wc, int n)
{
  unsigned char c = 0;
  if (wc < 0x0080) {
    *r = wc;
    return 1;
  }
  else if (wc >= 0x00a0 && wc < 0x00c0)
    c = wc;
  else if (wc >= 0x00c0 && wc < 0x0118)
    c = cp1258_page00[wc-0x00c0];
  else if (wc >= 0x0150 && wc < 0x01b8)
    c = cp1258_page01[wc-0x0150];
  else if (wc >= 0x02c0 && wc < 0x02e0)
    c = cp1258_page02[wc-0x02c0];
  else if (wc >= 0x0300 && wc < 0x0328)
    c = cp1258_page03[wc-0x0300];
  else if (wc >= 0x0340 && wc < 0x0342) /* deprecated Vietnamese tone marks */
    c = cp1258_page03[wc-0x0340];
  else if (wc >= 0x2010 && wc < 0x2040)
    c = cp1258_page20[wc-0x2010];
  else if (wc == 0x20ab)
    c = 0xfe;
  else if (wc == 0x20ac)
    c = 0x80;
  else if (wc == 0x2122)
    c = 0x99;
  if (c != 0) {
    *r = c;
    return 1;
  }
  /* Try canonical decomposition. */
  {
    /* Binary search through viet_decomp_table. */
    unsigned int i1 = 0;
    unsigned int i2 = sizeof(viet_decomp_table)/sizeof(viet_decomp_table[0])-1;
    if (wc >= viet_decomp_table[i1].composed
        && wc <= viet_decomp_table[i2].composed) {
      unsigned int i;
      for (;;) {
        /* Here i2 - i1 > 0. */
        i = (i1+i2)>>1;
        if (wc == viet_decomp_table[i].composed)
          break;
        if (wc < viet_decomp_table[i].composed) {
          if (i1 == i)
            return RET_ILUNI;
          /* Here i1 < i < i2. */
          i2 = i;
        } else {
          /* Here i1 <= i < i2. */
          if (i1 != i)
            i1 = i;
          else {
            /* Here i2 - i1 = 1. */
            i = i2;
            if (wc == viet_decomp_table[i].composed)
              break;
            else
              return RET_ILUNI;
          }
        }
      }
      /* Found a canonical decomposition. */
      wc = viet_decomp_table[i].base;
      /* wc is one of 0x0020, 0x0041..0x005a, 0x0061..0x007a, 0x00a5, 0x00a8,
         0x00c2, 0x00c5..0x00c7, 0x00ca, 0x00cf, 0x00d3, 0x00d4, 0x00d6,
         0x00d8, 0x00da, 0x00dc, 0x00e2, 0x00e5..0x00e7, 0x00ea, 0x00ef,
         0x00f3, 0x00f4, 0x00f6, 0x00f8, 0x00fc, 0x0102, 0x0103, 0x01a0,
         0x01a1, 0x01af, 0x01b0. */
      if (wc < 0x0100)
        c = wc;
      else if (wc < 0x0118)
        c = cp1258_page00[wc-0x00c0];
      else
        c = cp1258_page01[wc-0x0150];
      if (n < 2)
        return RET_TOOSMALL;
      r[0] = c;
      r[1] = cp1258_comb_table[viet_decomp_table[i].comb1];
      return 2;
    }
  }
  return RET_ILUNI;
}
