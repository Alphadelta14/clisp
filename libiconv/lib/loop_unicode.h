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

/* This file defines the conversion loop via Unicode as a pivot encoding. */

/* Attempt to transliterate wc. Return code as in xxx_wctomb. */
static int unicode_transliterate (conv_t cd, ucs4_t wc,
                                  unsigned char* outptr, size_t outleft)
{
  if (cd->oflags & HAVE_HANGUL_JAMO) {
    /* Decompose Hangul into Jamo. Use double-width Jamo (contained
       in all Korean encodings and ISO-2022-JP-2), not half-width Jamo
       (contained in Unicode only). */
    ucs4_t buf[3];
    int ret = johab_hangul_decompose(cd,buf,wc);
    if (ret != RET_ILUNI) {
      /* we know 1 <= ret <= 3 */
      state_t backup_state = cd->ostate;
      unsigned char* backup_outptr = outptr;
      size_t backup_outleft = outleft;
      int i, sub_outcount;
      for (i = 0; i < ret; i++) {
        if (outleft == 0) {
          sub_outcount = RET_TOOSMALL;
          goto johab_hangul_failed;
        }
        sub_outcount = cd->ofuncs.xxx_wctomb(cd,outptr,buf[i],outleft);
        if (sub_outcount <= RET_ILUNI)
          goto johab_hangul_failed;
        if (!(sub_outcount <= outleft)) abort();
        outptr += sub_outcount; outleft -= sub_outcount;
      }
      return outptr-backup_outptr;
    johab_hangul_failed:
      cd->ostate = backup_state;
      outptr = backup_outptr;
      outleft = backup_outleft;
      if (sub_outcount < 0)
        return RET_TOOSMALL;
    }
  }
  {
    /* Try to use a variant, but postfix it with
       U+303E IDEOGRAPHIC VARIATION INDICATOR
       (cf. Ken Lunde's "CJKV information processing", p. 188). */
    int indx = -1;
    if (wc == 0x3006)
      indx = 0;
    else if (wc == 0x30f6)
      indx = 1;
    else if (wc >= 0x4e00 && wc < 0xa000)
      indx = cjk_variants_indx[wc-0x4e00];
    if (indx >= 0) {
      for (;; indx++) {
        ucs4_t buf[2];
        unsigned short variant = cjk_variants[indx];
        unsigned short last = variant & 0x8000;
        variant &= 0x7fff;
        variant += 0x3000;
        buf[0] = variant; buf[1] = 0x303e;
        {
          state_t backup_state = cd->ostate;
          unsigned char* backup_outptr = outptr;
          size_t backup_outleft = outleft;
          int i, sub_outcount;
          for (i = 0; i < 2; i++) {
            if (outleft == 0) {
              sub_outcount = RET_TOOSMALL;
              goto variant_failed;
            }
            sub_outcount = cd->ofuncs.xxx_wctomb(cd,outptr,buf[i],outleft);
            if (sub_outcount <= RET_ILUNI)
              goto variant_failed;
            if (!(sub_outcount <= outleft)) abort();
            outptr += sub_outcount; outleft -= sub_outcount;
          }
          return outptr-backup_outptr;
        variant_failed:
          cd->ostate = backup_state;
          outptr = backup_outptr;
          outleft = backup_outleft;
          if (sub_outcount < 0)
            return RET_TOOSMALL;
        }
        if (last)
          break;
      }
    }
  }
  if (wc >= 0x2018 && wc <= 0x201a) {
    /* Special case for quotation marks 0x2018, 0x2019, 0x201a */
    ucs4_t substitute =
      (cd->oflags & HAVE_QUOTATION_MARKS
       ? (wc == 0x201a ? 0x2018 : wc)
       : (cd->oflags & HAVE_ACCENTS
          ? (wc==0x2019 ? 0x00b4 : 0x0060) /* use accents */
          : 0x0027 /* use apostrophe */
      )  );
    int outcount = cd->ofuncs.xxx_wctomb(cd,outptr,substitute,outleft);
    if (outcount != RET_ILUNI)
      return outcount;
  }
  {
    /* Use the transliteration table. */
    int indx = translit_index(wc);
    if (indx >= 0) {
      const unsigned short * cp = &translit_data[indx];
      unsigned int num = *cp++;
      state_t backup_state = cd->ostate;
      unsigned char* backup_outptr = outptr;
      size_t backup_outleft = outleft;
      unsigned int i;
      int sub_outcount;
      for (i = 0; i < num; i++) {
        if (outleft == 0) {
          sub_outcount = RET_TOOSMALL;
          goto translit_failed;
        }
        sub_outcount = cd->ofuncs.xxx_wctomb(cd,outptr,cp[i],outleft);
        if (sub_outcount <= RET_ILUNI)
          goto translit_failed;
        if (!(sub_outcount <= outleft)) abort();
        outptr += sub_outcount; outleft -= sub_outcount;
      }
      return outptr-backup_outptr;
    translit_failed:
      cd->ostate = backup_state;
      outptr = backup_outptr;
      outleft = backup_outleft;
      if (sub_outcount < 0)
        return RET_TOOSMALL;
    }
  }
  return RET_ILUNI;
}

static size_t unicode_loop_convert (iconv_t icd,
                                    const char* * inbuf, size_t *inbytesleft,
                                    char* * outbuf, size_t *outbytesleft)
{
  conv_t cd = (conv_t) icd;
  size_t result = 0;
  const unsigned char* inptr = (const unsigned char*) *inbuf;
  size_t inleft = *inbytesleft;
  unsigned char* outptr = (unsigned char*) *outbuf;
  size_t outleft = *outbytesleft;
  while (inleft > 0) {
    ucs4_t wc;
    int incount;
    int outcount;
    incount = cd->ifuncs.xxx_mbtowc(cd,&wc,inptr,inleft);
    if (incount < 0) {
      if (incount == RET_ILSEQ) {
        /* Case 1: invalid input */
        errno = EILSEQ;
        result = -1;
        break;
      }
      if (incount == RET_TOOFEW(0)) {
        /* Case 2: not enough bytes available to detect anything */
        errno = EINVAL;
        result = -1;
        break;
      }
      /* Case 3: k bytes read, but only a shift sequence */
      incount = -2-incount;
    } else {
      /* Case 4: k bytes read, making up a wide character */
      if (outleft == 0) {
        errno = E2BIG;
        result = -1;
        break;
      }
      outcount = cd->ofuncs.xxx_wctomb(cd,outptr,wc,outleft);
      if (outcount != RET_ILUNI)
        goto outcount_ok;
      /* Handle Unicode tag characters (range U+E0000..U+E007F). */
      if ((wc >> 7) == (0xe0000 >> 7))
        goto outcount_zero;
      /* Try transliteration. */
      result++;
      if (cd->transliterate) {
        outcount = unicode_transliterate(cd,wc,outptr,outleft);
        if (outcount != RET_ILUNI)
          goto outcount_ok;
      }
      outcount = cd->ofuncs.xxx_wctomb(cd,outptr,0xFFFD,outleft);
      if (outcount != RET_ILUNI)
        goto outcount_ok;
      errno = EILSEQ;
      result = -1;
      break;
    outcount_ok:
      if (outcount < 0) {
        errno = E2BIG;
        result = -1;
        break;
      }
      if (!(outcount <= outleft)) abort();
      outptr += outcount; outleft -= outcount;
    outcount_zero: ;
    }
    if (!(incount <= inleft)) abort();
    inptr += incount; inleft -= incount;
  }
  *inbuf = (const char*) inptr;
  *inbytesleft = inleft;
  *outbuf = (char*) outptr;
  *outbytesleft = outleft;
  return result;
}

static size_t unicode_loop_reset (iconv_t icd,
                                  char* * outbuf, size_t *outbytesleft)
{
  conv_t cd = (conv_t) icd;
  if (outbuf == NULL || *outbuf == NULL) {
    /* Reset the states. */
    memset(&cd->istate,'\0',sizeof(state_t));
    memset(&cd->ostate,'\0',sizeof(state_t));
    return 0;
  } else {
    size_t result = 0;
    if (cd->ifuncs.xxx_flushwc) {
      ucs4_t wc;
      if (cd->ifuncs.xxx_flushwc(cd, &wc)) {
        unsigned char* outptr = (unsigned char*) *outbuf;
        size_t outleft = *outbytesleft;
        int outcount = cd->ofuncs.xxx_wctomb(cd,outptr,wc,outleft);
        if (outcount != RET_ILUNI)
          goto outcount_ok;
        /* Handle Unicode tag characters (range U+E0000..U+E007F). */
        if ((wc >> 7) == (0xe0000 >> 7))
          goto outcount_zero;
        /* Try transliteration. */
        result++;
        if (cd->transliterate) {
          outcount = unicode_transliterate(cd,wc,outptr,outleft);
          if (outcount != RET_ILUNI)
            goto outcount_ok;
        }
        outcount = cd->ofuncs.xxx_wctomb(cd,outptr,0xFFFD,outleft);
        if (outcount != RET_ILUNI)
          goto outcount_ok;
        errno = EILSEQ;
        return -1;
      outcount_ok:
        if (outcount < 0) {
          errno = E2BIG;
          return -1;
        }
        if (!(outcount <= outleft)) abort();
        outptr += outcount;
        outleft -= outcount;
      outcount_zero:
        *outbuf = (char*) outptr;
        *outbytesleft = outleft;
      }
    }
    if (cd->ofuncs.xxx_reset) {
      unsigned char* outptr = (unsigned char*) *outbuf;
      size_t outleft = *outbytesleft;
      int outcount = cd->ofuncs.xxx_reset(cd,outptr,outleft);
      if (outcount < 0) {
        errno = E2BIG;
        return -1;
      }
      if (!(outcount <= outleft)) abort();
      *outbuf = (char*) (outptr + outcount);
      *outbytesleft = outleft - outcount;
    }
    memset(&cd->istate,'\0',sizeof(state_t));
    memset(&cd->ostate,'\0',sizeof(state_t));
    return result;
  }
}
