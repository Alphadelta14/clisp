
/*
 * HP-ROMAN8
 */

static const unsigned short hp_roman8_2uni[96] = {
  /* 0xa0 */
  0x00a0, 0x00c0, 0x00c2, 0x00c8, 0x00ca, 0x00cb, 0x00ce, 0x00cf,
  0x00b4, 0x02cb, 0x02c6, 0x00a8, 0x02dc, 0x00d9, 0x00db, 0x20a4,
  /* 0xb0 */
  0x00af, 0x00dd, 0x00fd, 0x00b0, 0x00c7, 0x00e7, 0x00d1, 0x00f1,
  0x00a1, 0x00bf, 0x00a4, 0x00a3, 0x00a5, 0x00a7, 0x0192, 0x00a2,
  /* 0xc0 */
  0x00e2, 0x00ea, 0x00f4, 0x00fb, 0x00e1, 0x00e9, 0x00f3, 0x00fa,
  0x00e0, 0x00e8, 0x00f2, 0x00f9, 0x00e4, 0x00eb, 0x00f6, 0x00fc,
  /* 0xd0 */
  0x00c5, 0x00ee, 0x00d8, 0x00c6, 0x00e5, 0x00ed, 0x00f8, 0x00e6,
  0x00c4, 0x00ec, 0x00d6, 0x00dc, 0x00c9, 0x00ef, 0x00df, 0x00d4,
  /* 0xe0 */
  0x00c1, 0x00c3, 0x00e3, 0x00d0, 0x00f0, 0x00cd, 0x00cc, 0x00d3,
  0x00d2, 0x00d5, 0x00f5, 0x0160, 0x0161, 0x00da, 0x0178, 0x00ff,
  /* 0xf0 */
  0x00de, 0x00fe, 0x00b7, 0x00b5, 0x00b6, 0x00be, 0x2014, 0x00bc,
  0x00bd, 0x00aa, 0x00ba, 0x00ab, 0x25a0, 0x00bb, 0x00b1, 0xfffd,
};

static int
hp_roman8_mbtowc (conv_t conv, wchar_t *pwc, const unsigned char *s, int n)
{
  unsigned char c = *s;
  if (c < 0xa0) {
    *pwc = (wchar_t) c;
    return 1;
  }
  else {
    unsigned short wc = hp_roman8_2uni[c-0xa0];
    if (wc != 0xfffd) {
      *pwc = (wchar_t) wc;
      return 1;
    }
  }
  return RET_ILSEQ;
}

static const unsigned char hp_roman8_page00[96] = {
  0xa0, 0xb8, 0xbf, 0xbb, 0xba, 0xbc, 0x00, 0xbd, /* 0xa0-0xa7 */
  0xab, 0x00, 0xf9, 0xfb, 0x00, 0x00, 0x00, 0xb0, /* 0xa8-0xaf */
  0xb3, 0xfe, 0x00, 0x00, 0xa8, 0xf3, 0xf4, 0xf2, /* 0xb0-0xb7 */
  0x00, 0x00, 0xfa, 0xfd, 0xf7, 0xf8, 0xf5, 0xb9, /* 0xb8-0xbf */
  0xa1, 0xe0, 0xa2, 0xe1, 0xd8, 0xd0, 0xd3, 0xb4, /* 0xc0-0xc7 */
  0xa3, 0xdc, 0xa4, 0xa5, 0xe6, 0xe5, 0xa6, 0xa7, /* 0xc8-0xcf */
  0xe3, 0xb6, 0xe8, 0xe7, 0xdf, 0xe9, 0xda, 0x00, /* 0xd0-0xd7 */
  0xd2, 0xad, 0xed, 0xae, 0xdb, 0xb1, 0xf0, 0xde, /* 0xd8-0xdf */
  0xc8, 0xc4, 0xc0, 0xe2, 0xcc, 0xd4, 0xd7, 0xb5, /* 0xe0-0xe7 */
  0xc9, 0xc5, 0xc1, 0xcd, 0xd9, 0xd5, 0xd1, 0xdd, /* 0xe8-0xef */
  0xe4, 0xb7, 0xca, 0xc6, 0xc2, 0xea, 0xce, 0x00, /* 0xf0-0xf7 */
  0xd6, 0xcb, 0xc7, 0xc3, 0xcf, 0xb2, 0xf1, 0xef, /* 0xf8-0xff */
};
static const unsigned char hp_roman8_page01[56] = {
  0xeb, 0xec, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x60-0x67 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x68-0x6f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x70-0x77 */
  0xee, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x78-0x7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x80-0x87 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x88-0x8f */
  0x00, 0x00, 0xbe, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x90-0x97 */
};
static const unsigned char hp_roman8_page02[32] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaa, 0x00, /* 0xc0-0xc7 */
  0x00, 0x00, 0x00, 0xa9, 0x00, 0x00, 0x00, 0x00, /* 0xc8-0xcf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xd0-0xd7 */
  0x00, 0x00, 0x00, 0x00, 0xac, 0x00, 0x00, 0x00, /* 0xd8-0xdf */
};

static int
hp_roman8_wctomb (conv_t conv, unsigned char *r, wchar_t wc, int n)
{
  unsigned char c = 0;
  if (wc < 0x00a0) {
    *r = wc;
    return 1;
  }
  else if (wc >= 0x00a0 && wc < 0x0100)
    c = hp_roman8_page00[wc-0x00a0];
  else if (wc >= 0x0160 && wc < 0x0198)
    c = hp_roman8_page01[wc-0x0160];
  else if (wc >= 0x02c0 && wc < 0x02e0)
    c = hp_roman8_page02[wc-0x02c0];
  else if (wc == 0x2014)
    c = 0xf6;
  else if (wc == 0x20a4)
    c = 0xaf;
  else if (wc == 0x25a0)
    c = 0xfc;
  if (c != 0) {
    *r = c;
    return 1;
  }
  return RET_ILSEQ;
}
