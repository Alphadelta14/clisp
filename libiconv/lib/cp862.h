
/*
 * CP862
 */

static const unsigned short cp862_2uni[128] = {
  /* 0x80 */
  0x05d0, 0x05d1, 0x05d2, 0x05d3, 0x05d4, 0x05d5, 0x05d6, 0x05d7,
  0x05d8, 0x05d9, 0x05da, 0x05db, 0x05dc, 0x05dd, 0x05de, 0x05df,
  /* 0x90 */
  0x05e0, 0x05e1, 0x05e2, 0x05e3, 0x05e4, 0x05e5, 0x05e6, 0x05e7,
  0x05e8, 0x05e9, 0x05ea, 0x00a2, 0x00a3, 0x00a5, 0x20a7, 0x0192,
  /* 0xa0 */
  0x00e1, 0x00ed, 0x00f3, 0x00fa, 0x00f1, 0x00d1, 0x00aa, 0x00ba,
  0x00bf, 0x2310, 0x00ac, 0x00bd, 0x00bc, 0x00a1, 0x00ab, 0x00bb,
  /* 0xb0 */
  0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556,
  0x2555, 0x2563, 0x2551, 0x2557, 0x255d, 0x255c, 0x255b, 0x2510,
  /* 0xc0 */
  0x2514, 0x2534, 0x252c, 0x251c, 0x2500, 0x253c, 0x255e, 0x255f,
  0x255a, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256c, 0x2567,
  /* 0xd0 */
  0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256b,
  0x256a, 0x2518, 0x250c, 0x2588, 0x2584, 0x258c, 0x2590, 0x2580,
  /* 0xe0 */
  0x03b1, 0x00df, 0x0393, 0x03c0, 0x03a3, 0x03c3, 0x00b5, 0x03c4,
  0x03a6, 0x0398, 0x03a9, 0x03b4, 0x221e, 0x03c6, 0x03b5, 0x2229,
  /* 0xf0 */
  0x2261, 0x00b1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00f7, 0x2248,
  0x00b0, 0x2219, 0x00b7, 0x221a, 0x207f, 0x00b2, 0x25a0, 0x00a0,
};

static int
cp862_mbtowc (conv_t conv, ucs4_t *pwc, const unsigned char *s, int n)
{
  unsigned char c = *s;
  if (c < 0x80)
    *pwc = (ucs4_t) c;
  else
    *pwc = (ucs4_t) cp862_2uni[c-0x80];
  return 1;
}

static const unsigned char cp862_page00[96] = {
  0xff, 0xad, 0x9b, 0x9c, 0x00, 0x9d, 0x00, 0x00, /* 0xa0-0xa7 */
  0x00, 0x00, 0xa6, 0xae, 0xaa, 0x00, 0x00, 0x00, /* 0xa8-0xaf */
  0xf8, 0xf1, 0xfd, 0x00, 0x00, 0xe6, 0x00, 0xfa, /* 0xb0-0xb7 */
  0x00, 0x00, 0xa7, 0xaf, 0xac, 0xab, 0x00, 0xa8, /* 0xb8-0xbf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xc0-0xc7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xc8-0xcf */
  0x00, 0xa5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xd0-0xd7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe1, /* 0xd8-0xdf */
  0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xe0-0xe7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0xa1, 0x00, 0x00, /* 0xe8-0xef */
  0x00, 0xa4, 0x00, 0xa2, 0x00, 0x00, 0x00, 0xf6, /* 0xf0-0xf7 */
  0x00, 0x00, 0xa3, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xf8-0xff */
};
static const unsigned char cp862_page03[56] = {
  0x00, 0x00, 0x00, 0xe2, 0x00, 0x00, 0x00, 0x00, /* 0x90-0x97 */
  0xe9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x98-0x9f */
  0x00, 0x00, 0x00, 0xe4, 0x00, 0x00, 0xe8, 0x00, /* 0xa0-0xa7 */
  0x00, 0xea, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xa8-0xaf */
  0x00, 0xe0, 0x00, 0x00, 0xeb, 0xee, 0x00, 0x00, /* 0xb0-0xb7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xb8-0xbf */
  0xe3, 0x00, 0x00, 0xe5, 0xe7, 0x00, 0xed, 0x00, /* 0xc0-0xc7 */
};
static const unsigned char cp862_page22[80] = {
  0x00, 0xf9, 0xfb, 0x00, 0x00, 0x00, 0xec, 0x00, /* 0x18-0x1f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x20-0x27 */
  0x00, 0xef, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x38-0x3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x40-0x47 */
  0xf7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x48-0x4f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x50-0x57 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x58-0x5f */
  0x00, 0xf0, 0x00, 0x00, 0xf3, 0xf2, 0x00, 0x00, /* 0x60-0x67 */
};
static const unsigned char cp862_page25[168] = {
  0xc4, 0x00, 0xb3, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x00-0x07 */
  0x00, 0x00, 0x00, 0x00, 0xda, 0x00, 0x00, 0x00, /* 0x08-0x0f */
  0xbf, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0xd9, 0x00, 0x00, 0x00, 0xc3, 0x00, 0x00, 0x00, /* 0x18-0x1f */
  0x00, 0x00, 0x00, 0x00, 0xb4, 0x00, 0x00, 0x00, /* 0x20-0x27 */
  0x00, 0x00, 0x00, 0x00, 0xc2, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0x00, 0x00, 0x00, 0x00, 0xc1, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0x00, 0x00, 0x00, 0xc5, 0x00, 0x00, 0x00, /* 0x38-0x3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x40-0x47 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x48-0x4f */
  0xcd, 0xba, 0xd5, 0xd6, 0xc9, 0xb8, 0xb7, 0xbb, /* 0x50-0x57 */
  0xd4, 0xd3, 0xc8, 0xbe, 0xbd, 0xbc, 0xc6, 0xc7, /* 0x58-0x5f */
  0xcc, 0xb5, 0xb6, 0xb9, 0xd1, 0xd2, 0xcb, 0xcf, /* 0x60-0x67 */
  0xd0, 0xca, 0xd8, 0xd7, 0xce, 0x00, 0x00, 0x00, /* 0x68-0x6f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x70-0x77 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x78-0x7f */
  0xdf, 0x00, 0x00, 0x00, 0xdc, 0x00, 0x00, 0x00, /* 0x80-0x87 */
  0xdb, 0x00, 0x00, 0x00, 0xdd, 0x00, 0x00, 0x00, /* 0x88-0x8f */
  0xde, 0xb0, 0xb1, 0xb2, 0x00, 0x00, 0x00, 0x00, /* 0x90-0x97 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x98-0x9f */
  0xfe, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xa0-0xa7 */
};

static int
cp862_wctomb (conv_t conv, unsigned char *r, ucs4_t wc, int n)
{
  unsigned char c = 0;
  if (wc < 0x0080) {
    *r = wc;
    return 1;
  }
  else if (wc >= 0x00a0 && wc < 0x0100)
    c = cp862_page00[wc-0x00a0];
  else if (wc == 0x0192)
    c = 0x9f;
  else if (wc >= 0x0390 && wc < 0x03c8)
    c = cp862_page03[wc-0x0390];
  else if (wc >= 0x05d0 && wc < 0x05eb)
    c = wc-0x0550;
  else if (wc == 0x207f)
    c = 0xfc;
  else if (wc == 0x20a7)
    c = 0x9e;
  else if (wc >= 0x2218 && wc < 0x2268)
    c = cp862_page22[wc-0x2218];
  else if (wc == 0x2310)
    c = 0xa9;
  else if (wc >= 0x2320 && wc < 0x2322)
    c = wc-0x222c;
  else if (wc >= 0x2500 && wc < 0x25a8)
    c = cp862_page25[wc-0x2500];
  if (c != 0) {
    *r = c;
    return 1;
  }
  return RET_ILSEQ;
}
