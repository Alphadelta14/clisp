
/*
 * JOHAB
 */

/*
   Conversion between JOHAB codes (s1,s2) and KSX1001 codes (c1,c2):
   Example. (s1,s2) = 0xD931, (c1,c2) = 0x2121.
            (s1,s2) = 0xDEF1, (c1,c2) = 0x2C71.
            (s1,s2) = 0xE031, (c1,c2) = 0x4A21.
            (s1,s2) = 0xF9FE, (c1,c2) = 0x7D7E.
   0xD9 <= s1 <= 0xDE || 0xE0 <= s1 <= 0xF9,
   0x31 <= s2 <= 0x7E || 0x91 <= s2 <= 0xFE,
   0x21 <= c1 <= 0x2C || 0x4A <= c1 <= 0x7D,
   0x21 <= c2 <= 0x7E.
   Invariant:
     94*(s1 < 0xE0 ? 2*s1-0x1B2 : 2*s1-0x197) + (s2 < 0x91 ? s2-0x31 : s2-0x43)
     = 94*(c1-0x21)+(c2-0x21)
   Conversion (s1,s2) -> (c1,c2):
     t1 := (s1 < 0xE0 ? 2*s1-0x1B2 : 2*s1-0x197)
     t2 := (s2 < 0x91 ? s2-0x31 : s2-0x43)
     c1 := t1 + (t2 < 0x5E ? 0 : 1) + 0x21
     c2 := (t2 < 0x5E ? t2 : t2-0x5E) + 0x21
   Conversion (c1,c2) -> (s1,s2):
     t := (c1 < 0x4A ? (c1-0x21+0x1B2) : (c1-0x21+0x197))
     s1 := t >> 1
     t2 := (t & 1) * 0x5E + (c2 - 0x21)
     s2 := (t2 < 0x4E ? t2+0x31 : t2+0x43)
 */

static int
johab_mbtowc (conv_t conv, wchar_t *pwc, const unsigned char *s, int n)
{
  unsigned char c = *s;
  if (c < 0x80) {
    if (c == 0x5c)
      *pwc = (wchar_t) 0x20a9;
    else
      *pwc = (wchar_t) c;
    return 1;
  } else if (c < 0xd8) {
    return johab_hangul_mbtowc(conv,pwc,s,n);
  } else {
    unsigned char s1, s2;
    s1 = c;
    if ((s1 >= 0xd9 && s1 <= 0xde) || (s1 >= 0xe0 && s1 <= 0xf9)) {
      if (n < 2)
        return RET_TOOFEW(0);
      s2 = s[1];
      if ((s2 >= 0x31 && s2 <= 0x7e) || (s2 >= 0x91 && s2 <= 0xfe)) {
        unsigned char t1 = (s1 < 0xe0 ? 2*(s1-0xd9) : 2*s1-0x197);
        unsigned char t2 = (s2 < 0x91 ? s2-0x31 : s2-0x43);
        unsigned char buf[2];
        buf[0] = t1 + (t2 < 0x5e ? 0 : 1) + 0x21;
        buf[1] = (t2 < 0x5e ? t2 : t2-0x5e) + 0x21;
        return ksc5601_mbtowc(conv,pwc,buf,2);
      }
    }
    return RET_ILSEQ;
  }
}

static int
johab_wctomb (conv_t conv, unsigned char *r, wchar_t wc, int n)
{
  unsigned char buf[2];
  int ret;

  /* Try ASCII variation. */
  if (wc < 0x0080 && wc != 0x005c) {
    *r = wc;
    return 1;
  }
  if (wc == 0x20a9) {
    *r = 0x5c;
    return 1;
  }

  /* Try JOHAB Hangul table before KSC5601 table, because the KSC5601 table
     contains some (2350 out of 11172) Hangul syllables (rows 0x30XX..0x48XX),
     and we want the search to return the JOHAB Hangul table entry. */

  /* Try JOHAB Hangul. */
  ret = johab_hangul_wctomb(conv,buf,wc,2);
  if (ret != RET_ILSEQ) {
    if (ret != 2) abort();
    if (n < 2)
      return RET_TOOSMALL;
    r[0] = buf[0];
    r[1] = buf[1];
    return 2;
  }

  /* Try KSC5601. */
  ret = ksc5601_wctomb(conv,buf,wc,2);
  if (ret != RET_ILSEQ) {
    unsigned char c1, c2;
    if (ret != 2) abort();
    if (n < 2)
      return RET_TOOSMALL;
    c1 = buf[0];
    c2 = buf[1];
    if (((c1 >= 0x21 && c1 <= 0x2c) || (c1 >= 0x4a && c1 <= 0x7d))
        && (c2 >= 0x21 && c2 <= 0x7e)) {
      unsigned int t = (c1 < 0x4A ? (c1-0x21+0x1B2) : (c1-0x21+0x197));
      unsigned char t2 = ((t & 1) ? 0x5e : 0) + (c2 - 0x21);
      r[0] = t >> 1;
      r[1] = (t2 < 0x4e ? t2+0x31 : t2+0x43);
      return 2;
    }
  }

  return RET_ILSEQ;
}
