
/*
 * MacRomania
 */

static const unsigned short mac_romania_2uni[128] = {
  /* 0x80 */
  0x00c4, 0x00c5, 0x00c7, 0x00c9, 0x00d1, 0x00d6, 0x00dc, 0x00e1,
  0x00e0, 0x00e2, 0x00e4, 0x00e3, 0x00e5, 0x00e7, 0x00e9, 0x00e8,
  /* 0x90 */
  0x00ea, 0x00eb, 0x00ed, 0x00ec, 0x00ee, 0x00ef, 0x00f1, 0x00f3,
  0x00f2, 0x00f4, 0x00f6, 0x00f5, 0x00fa, 0x00f9, 0x00fb, 0x00fc,
  /* 0xa0 */
  0x2020, 0x00b0, 0x00a2, 0x00a3, 0x00a7, 0x2022, 0x00b6, 0x00df,
  0x00ae, 0x00a9, 0x2122, 0x00b4, 0x00a8, 0x2260, 0x0102, 0x015e,
  /* 0xb0 */
  0x221e, 0x00b1, 0x2264, 0x2265, 0x00a5, 0x00b5, 0x2202, 0x2211,
  0x220f, 0x03c0, 0x222b, 0x00aa, 0x00ba, 0x2126, 0x0103, 0x015f,
  /* 0xc0 */
  0x00bf, 0x00a1, 0x00ac, 0x221a, 0x0192, 0x2248, 0x2206, 0x00ab,
  0x00bb, 0x2026, 0x00a0, 0x00c0, 0x00c3, 0x00d5, 0x0152, 0x0153,
  /* 0xd0 */
  0x2013, 0x2014, 0x201c, 0x201d, 0x2018, 0x2019, 0x00f7, 0x25ca,
  0x00ff, 0x0178, 0x2044, 0x00a4, 0x2039, 0x203a, 0x0162, 0x0163,
  /* 0xe0 */
  0x2021, 0x00b7, 0x201a, 0x201e, 0x2030, 0x00c2, 0x00ca, 0x00c1,
  0x00cb, 0x00c8, 0x00cd, 0x00ce, 0x00cf, 0x00cc, 0x00d3, 0x00d4,
  /* 0xf0 */
  0xfffd, 0x00d2, 0x00da, 0x00db, 0x00d9, 0x0131, 0x02c6, 0x02dc,
  0x00af, 0x02d8, 0x02d9, 0x02da, 0x00b8, 0x02dd, 0x02db, 0x02c7,
};

static int
mac_romania_mbtowc (conv_t conv, ucs4_t *pwc, const unsigned char *s, int n)
{
  unsigned char c = *s;
  if (c < 0x80) {
    *pwc = (ucs4_t) c;
    return 1;
  }
  else {
    unsigned short wc = mac_romania_2uni[c-0x80];
    if (wc != 0xfffd) {
      *pwc = (ucs4_t) wc;
      return 1;
    }
  }
  return RET_ILSEQ;
}

static const unsigned char mac_romania_page00[248] = {
  0xca, 0xc1, 0xa2, 0xa3, 0xdb, 0xb4, 0x00, 0xa4, /* 0xa0-0xa7 */
  0xac, 0xa9, 0xbb, 0xc7, 0xc2, 0x00, 0xa8, 0xf8, /* 0xa8-0xaf */
  0xa1, 0xb1, 0x00, 0x00, 0xab, 0xb5, 0xa6, 0xe1, /* 0xb0-0xb7 */
  0xfc, 0x00, 0xbc, 0xc8, 0x00, 0x00, 0x00, 0xc0, /* 0xb8-0xbf */
  0xcb, 0xe7, 0xe5, 0xcc, 0x80, 0x81, 0x00, 0x82, /* 0xc0-0xc7 */
  0xe9, 0x83, 0xe6, 0xe8, 0xed, 0xea, 0xeb, 0xec, /* 0xc8-0xcf */
  0x00, 0x84, 0xf1, 0xee, 0xef, 0xcd, 0x85, 0x00, /* 0xd0-0xd7 */
  0x00, 0xf4, 0xf2, 0xf3, 0x86, 0x00, 0x00, 0xa7, /* 0xd8-0xdf */
  0x88, 0x87, 0x89, 0x8b, 0x8a, 0x8c, 0x00, 0x8d, /* 0xe0-0xe7 */
  0x8f, 0x8e, 0x90, 0x91, 0x93, 0x92, 0x94, 0x95, /* 0xe8-0xef */
  0x00, 0x96, 0x98, 0x97, 0x99, 0x9b, 0x9a, 0xd6, /* 0xf0-0xf7 */
  0x00, 0x9d, 0x9c, 0x9e, 0x9f, 0x00, 0x00, 0xd8, /* 0xf8-0xff */
  /* 0x0100 */
  0x00, 0x00, 0xae, 0xbe, 0x00, 0x00, 0x00, 0x00, /* 0x00-0x07 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x08-0x0f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x18-0x1f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x20-0x27 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0x00, 0xf5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x38-0x3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x40-0x47 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x48-0x4f */
  0x00, 0x00, 0xce, 0xcf, 0x00, 0x00, 0x00, 0x00, /* 0x50-0x57 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaf, 0xbf, /* 0x58-0x5f */
  0x00, 0x00, 0xde, 0xdf, 0x00, 0x00, 0x00, 0x00, /* 0x60-0x67 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x68-0x6f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x70-0x77 */
  0xd9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x78-0x7f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x80-0x87 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x88-0x8f */
  0x00, 0x00, 0xc4, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x90-0x97 */
};
static const unsigned char mac_romania_page02[32] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf6, 0xff, /* 0xc0-0xc7 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xc8-0xcf */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xd0-0xd7 */
  0xf9, 0xfa, 0xfb, 0xfe, 0xf7, 0xfd, 0x00, 0x00, /* 0xd8-0xdf */
};
static const unsigned char mac_romania_page20[56] = {
  0x00, 0x00, 0x00, 0xd0, 0xd1, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0xd4, 0xd5, 0xe2, 0x00, 0xd2, 0xd3, 0xe3, 0x00, /* 0x18-0x1f */
  0xa0, 0xe0, 0xa5, 0x00, 0x00, 0x00, 0xc9, 0x00, /* 0x20-0x27 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0xe4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0xdc, 0xdd, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x38-0x3f */
  0x00, 0x00, 0x00, 0x00, 0xda, 0x00, 0x00, 0x00, /* 0x40-0x47 */
};
static const unsigned char mac_romania_page21[8] = {
  0x00, 0x00, 0xaa, 0x00, 0x00, 0x00, 0xbd, 0x00, /* 0x20-0x27 */
};
static const unsigned char mac_romania_page22[104] = {
  0x00, 0x00, 0xb6, 0x00, 0x00, 0x00, 0xc6, 0x00, /* 0x00-0x07 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb8, /* 0x08-0x0f */
  0x00, 0xb7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x10-0x17 */
  0x00, 0x00, 0xc3, 0x00, 0x00, 0x00, 0xb0, 0x00, /* 0x18-0x1f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x20-0x27 */
  0x00, 0x00, 0x00, 0xba, 0x00, 0x00, 0x00, 0x00, /* 0x28-0x2f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x30-0x37 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x38-0x3f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x40-0x47 */
  0xc5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x48-0x4f */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x50-0x57 */
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x58-0x5f */
  0xad, 0x00, 0x00, 0x00, 0xb2, 0xb3, 0x00, 0x00, /* 0x60-0x67 */
};

static int
mac_romania_wctomb (conv_t conv, unsigned char *r, ucs4_t wc, int n)
{
  unsigned char c = 0;
  if (wc < 0x0080) {
    *r = wc;
    return 1;
  }
  else if (wc >= 0x00a0 && wc < 0x0198)
    c = mac_romania_page00[wc-0x00a0];
  else if (wc >= 0x02c0 && wc < 0x02e0)
    c = mac_romania_page02[wc-0x02c0];
  else if (wc == 0x03c0)
    c = 0xb9;
  else if (wc >= 0x2010 && wc < 0x2048)
    c = mac_romania_page20[wc-0x2010];
  else if (wc >= 0x2120 && wc < 0x2128)
    c = mac_romania_page21[wc-0x2120];
  else if (wc >= 0x2200 && wc < 0x2268)
    c = mac_romania_page22[wc-0x2200];
  else if (wc == 0x25ca)
    c = 0xd7;
  if (c != 0) {
    *r = c;
    return 1;
  }
  return RET_ILSEQ;
}
