/*
 * Copyright (C) 1999-2000 Free Software Foundation, Inc.
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
 * CP1250
 */

static const unsigned short cp1250_2uni[128] = {
  /* 0x80 */
  0x20ac, 0xfffd, 0x201a, 0xfffd, 0x201e, 0x2026, 0x2020, 0x2021,
  0xfffd, 0x2030, 0x0160, 0x2039, 0x015a, 0x0164, 0x017d, 0x0179,
  /* 0x90 */
  0xfffd, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014,
  0xfffd, 0x2122, 0x0161, 0x203a, 0x015b, 0x0165, 0x017e, 0x017a,
  /* 0xa0 */
  0x00a0, 0x02c7, 0x02d8, 0x0141, 0x00a4, 0x0104, 0x00a6, 0x00a7,
  0x00a8, 0x00a9, 0x015e, 0x00ab, 0x00ac, 0x00ad, 0x00ae, 0x017b,
  /* 0xb0 */
  0x00b0, 0x00b1, 0x02db, 0x0142, 0x00b4, 0x00b5, 0x00b6, 0x00b7,
  0x00b8, 0x0105, 0x015f, 0x00bb, 0x013d, 0x02dd, 0x013e, 0x017c,
  /* 0xc0 */
  0x0154, 0x00c1, 0x00c2, 0x0102, 0x00c4, 0x0139, 0x0106, 0x00c7,
  0x010c, 0x00c9, 0x0118, 0x00cb, 0x011a, 0x00cd, 0x00ce, 0x010e,
  /* 0xd0 */
  0x0110, 0x0143, 0x0147, 0x00d3, 0x00d4, 0x0150, 0x00d6, 0x00d7,
  0x0158, 0x016e, 0x00da, 0x0170, 0x00dc, 0x00dd, 0x0162, 0x00df,
  /* 0xe0 */
  0x0155, 0x00e1, 0x00e2, 0x0103, 0x00e4, 0x013a, 0x0107, 0x00e7,
  0x010d, 0x00e9, 0x0119, 0x00eb, 0x011b, 0x00ed, 0x00ee, 0x010f,
  /* 0xf0 */
  0x0111, 0x0144, 0x0148, 0x00f3, 0x00f4, 0x0151, 0x00f6, 0x00f7,
  0x0159, 0x016f, 0x00fa, 0x0171, 0x00fc, 0x00fd, 0x0163, 0x02d9,
};

static int
cp1250_mbtowc (conv_t conv, ucs4_t *pwc, const unsigned char *s, int n)
{
  unsigned char c = *s;
  if (c < 0x80) {
    *pwc = (ucs4_t) c;
    return 1;
  }
  else {
    unsigned short wc = cp1250_2uni[c-0x80];
    if (wc != 0xfffd) {
      *pwc = (ucs4_t) wc;
      return 1;
    }
  }
  return RET_ILSEQ;
}

static const unsigned char cp1250_page00[224] = {
  0xa0, 0x00, 0x00, 0x00, 0xa4, 0x00, 0xa6, 0xa7, /* 0xa0-0xa7 */
  0xa8, 0xa9, 0x00, 0xab, 0xac, 0xad, 0xae, 0x00, /* 0xa8-0xaf */
  0xb0, 0xb1, 0x00, 0x00, 0xb4, 0xb5, 0xb6, 0xb7, /* 0xb0-0xb7 */
  0xb8, 0x00, 0x00, 0xbb, 0x00, 0x00, 0x00, 0x00, /* 0xb8-0xbf */
  0x00, 0xc1, 0xc2, 0x00, 0xc4, 0x00, 0x00, 0xc7, /* 0xc0-0xc7 */
  0x00, 0xc9, 0x00, 0xcb, 0x00, 0xcd, 0xce, 0x00, /* 0xc8-0xcf */
  0x00, 0x00, 0x00, 0xd3, 0xd4, 0x00, 0xd6, 0xd7, /* 0xd0-0xd7 */
  0x00, 0x00, 0xda, 0x00, 0xdc, 0xdd, 0x00, 0xdf, /* 0xd8-0xdf */
  0x00, 0xe1, 0xe2, 0x00, 0xe4, 0x00, 0x00, 0xe7, /* 0xe0-0xe7 */
  0x00, 0xe9, 0x00, 0xeb, 0x00, 0xed, 0xee, 0x00, /* 0xe8-0xef */
  0x00, 0x00, 0x00, 0xf3, 0xf4, 0x00, 0xf6, 0xf7, /* 0xf0-0xf7 */
  0x00, 0x00, 0xfa, 0x00, 0xfc, 0xfd, 0x00, 0x00, /* 0xf8-0xff */
  /* 0x0100 */
  0x00, 0x00, 0xc3, 0xe3, 0xa5, 0xb9, 0xc6, 0xe6, /* 0x00-0x07 */
  0x00, 0x00, 0x00, 0x00, 0xc8, 0xe8, 0xcf, 0xef, /* 0x08-0x0f */
  0xd0, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0xca, 0xea, 0xcc, 0xec, 0x00, 0x00, 0x00, 0x00, /* 0x18-0x1f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x20-0x27 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0xc5, 0xe5, 0x00, 0x00, 0xbc, 0xbe, 0x00, /* 0x38-0x3f */
  0x00, 0xa3, 0xb3, 0xd1, 0xf1, 0x00, 0x00, 0xd2, /* 0x40-0x47 */
  0xf2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x48-0x4f */
  0xd5, 0xf5, 0x00, 0x00, 0xc0, 0xe0, 0x00, 0x00, /* 0x50-0x57 */
  0xd8, 0xf8, 0x8c, 0x9c, 0x00, 0x00, 0xaa, 0xba, /* 0x58-0x5f */
  0x8a, 0x9a, 0xde, 0xfe, 0x8d, 0x9d, 0x00, 0x00, /* 0x60-0x67 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd9, 0xf9, /* 0x68-0x6f */
  0xdb, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x70-0x77 */
  0x00, 0x8f, 0x9f, 0xaf, 0xbf, 0x8e, 0x9e, 0x00, /* 0x78-0x7f */
};
static const unsigned char cp1250_page02[32] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xa1, /* 0xc0-0xc7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xc8-0xcf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xd0-0xd7 */
  0xa2, 0xff, 0x00, 0xb2, 0x00, 0xbd, 0x00, 0x00, /* 0xd8-0xdf */
};
static const unsigned char cp1250_page20[48] = {
  0x00, 0x00, 0x00, 0x96, 0x97, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0x91, 0x92, 0x82, 0x00, 0x93, 0x94, 0x84, 0x00, /* 0x18-0x1f */
  0x86, 0x87, 0x95, 0x00, 0x00, 0x00, 0x85, 0x00, /* 0x20-0x27 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0x89, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0x8b, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x38-0x3f */
};

static int
cp1250_wctomb (conv_t conv, unsigned char *r, ucs4_t wc, int n)
{
  unsigned char c = 0;
  if (wc < 0x0080) {
    *r = wc;
    return 1;
  }
  else if (wc >= 0x00a0 && wc < 0x0180)
    c = cp1250_page00[wc-0x00a0];
  else if (wc >= 0x02c0 && wc < 0x02e0)
    c = cp1250_page02[wc-0x02c0];
  else if (wc >= 0x2010 && wc < 0x2040)
    c = cp1250_page20[wc-0x2010];
  else if (wc == 0x20ac)
    c = 0x80;
  else if (wc == 0x2122)
    c = 0x99;
  if (c != 0) {
    *r = c;
    return 1;
  }
  return RET_ILSEQ;
}
