# Choice of character set, and internationalization.

# ------------------------------ Specification ---------------------------------

  local void init_ctype (void);

# ------------------------------ Implementation --------------------------------

#ifdef UNICODE
  global const char* locale_charset = NULL;
#endif

  local void init_ctype()
    {
      #if defined(HAVE_LOCALE_H) || defined(UNICODE)
      # When you call setlocale(LC_CTYPE,""), is examines the environment
      # variables:
      # 1. environment variable LC_ALL - an override for all LC_* variables,
      # 2. environment variable LC_CTYPE,
      # 3. environment variable LANG - a default for all LC_* variables.
      var const char * locale;
      locale = getenv("CLISP_LC_CTYPE");
      if (!locale || !*locale) {
        locale = getenv("LC_ALL");
        if (!locale || !*locale) {
          locale = getenv("LC_CTYPE");
          if (!locale || !*locale)
            locale = getenv("LANG");
        }
      }
      #ifdef HAVE_LOCALE_H
      # Make the <ctype.h> functions 8-bit clean, if the LC_CTYPE environment
      # variable is set accordingly.
      # (We don't use these functions directly, but additional modules like
      # regexp use them and profit from this.)
      if (locale && *locale)
        setlocale(LC_CTYPE,locale);
      #endif
      #ifdef UNICODE
      # Determine locale_charset from the environment variables.
      # Unfortunately there is no documented way of getting the character set
      # that was specified as part of the LC_CTYPE category. We have to parse
      # the environment variables ourselves.
      # Recall that a locale specification has the form
      #   language_COUNTRY.charset
      # but there are also aliases. Here is the union of what I found in
      # /usr/X11R6/lib/X11/locale/locale.alias (X11R6) and
      # /usr/share/locale/locale.alias (GNU libc2).
      #
      # X11R6 locale.alias:
      #   POSIX                   C
      #   POSIX-UTF2              C
      #   C_C.C                   C
      #   C.en                    C
      #   C.iso88591              en_US.ISO8859-1
      #   Cextend                 en_US.ISO8859-1
      #   Cextend.en              en_US.ISO8859-1
      #   English_United-States.437       C
      #   #
      #   ar                      ar_AA.ISO8859-6
      #   ar_AA                   ar_AA.ISO8859-6
      #   ar_AA.ISO_8859-6        ar_AA.ISO8859-6
      #   ar_SA.iso88596          ar_AA.ISO8859-6
      #   bg                      bg_BG.ISO8859-5
      #   bg_BG                   bg_BG.ISO8859-5
      #   bg_BG.ISO_8859-5        bg_BG.ISO8859-5
      #   bg_BG.iso88595          bg_BG.ISO8859-5
      #   cs                      cs_CZ.ISO8859-2
      #   cs_CS                   cs_CZ.ISO8859-2
      #   cs_CS.ISO8859-2         cs_CZ.ISO8859-2
      #   cs_CS.ISO_8859-2        cs_CZ.ISO8859-2
      #   cs_CZ.iso88592          cs_CZ.ISO8859-2
      #   cz                      cz_CZ.ISO8859-2
      #   cz_CZ                   cz_CZ.ISO8859-2
      #   cs_CZ.ISO_8859-2        cs_CZ.ISO8859-2
      #   da                      da_DK.ISO8859-1
      #   da_DK                   da_DK.ISO8859-1
      #   da_DK.88591             da_DK.ISO8859-1
      #   da_DK.88591.en          da_DK.ISO8859-1
      #   da_DK.iso88591          da_DK.ISO8859-1
      #   da_DK.ISO_8859-1        da_DK.ISO8859-1
      #   de                      de_DE.ISO8859-1
      #   de_AT                   de_AT.ISO8859-1
      #   de_AT.ISO_8859-1        de_AT.ISO8859-1
      #   de_CH                   de_CH.ISO8859-1
      #   de_CH.ISO_8859-1        de_CH.ISO8859-1
      #   de_DE                   de_DE.ISO8859-1
      #   de_DE.88591             de_DE.ISO8859-1
      #   de_DE.88591.en          de_DE.ISO8859-1
      #   de_DE.iso88591          de_DE.ISO8859-1
      #   de_DE.ISO_8859-1        de_DE.ISO8859-1
      #   GER_DE.8859             de_DE.ISO8859-1
      #   GER_DE.8859.in          de_DE.ISO8859-1
      #   el                      el_GR.ISO8859-7
      #   el_GR                   el_GR.ISO8859-7
      #   el_GR.iso88597          el_GR.ISO8859-7
      #   el_GR.ISO_8859-7        el_GR.ISO8859-7
      #   en                      en_US.ISO8859-1
      #   en_AU                   en_AU.ISO8859-1
      #   en_AU.ISO_8859-1        en_AU.ISO8859-1
      #   en_CA                   en_CA.ISO8859-1
      #   en_CA.ISO_8859-1        en_CA.ISO8859-1
      #   en_GB                   en_GB.ISO8859-1
      #   en_GB.88591             en_GB.ISO8859-1
      #   en_GB.88591.en          en_GB.ISO8859-1
      #   en_GB.iso88591          en_GB.ISO8859-1
      #   en_GB.ISO_8859-1        en_GB.ISO8859-1
      #   en_UK                   en_GB.ISO8859-1
      #   ENG_GB.8859             en_GB.ISO8859-1
      #   ENG_GB.8859.in          en_GB.ISO8859-1
      #   en_IE                   en_IE.ISO8859-1
      #   en_NZ                   en_NZ.ISO8859-1
      #   en_US                   en_US.ISO8859-1
      #   en_US.88591             en_US.ISO8859-1
      #   en_US.88591.en          en_US.ISO8859-1
      #   en_US.iso88591          en_US.ISO8859-1
      #   en_US.ISO_8859-1        en_US.ISO8859-1
      #   es                      es_ES.ISO8859-1
      #   es_AR                   es_AR.ISO8859-1
      #   es_BO                   es_BO.ISO8859-1
      #   es_CL                   es_CL.ISO8859-1
      #   es_CO                   es_CO.ISO8859-1
      #   es_CR                   es_CR.ISO8859-1
      #   es_EC                   es_EC.ISO8859-1
      #   es_ES                   es_ES.ISO8859-1
      #   es_ES.88591             es_ES.ISO8859-1
      #   es_ES.88591.en          es_ES.ISO8859-1
      #   es_ES.iso88591          es_ES.ISO8859-1
      #   es_ES.ISO_8859-1        es_ES.ISO8859-1
      #   es_GT                   es_GT.ISO8859-1
      #   es_MX                   es_MX.ISO8859-1
      #   es_NI                   es_NI.ISO8859-1
      #   es_PA                   es_PA.ISO8859-1
      #   es_PE                   es_PE.ISO8859-1
      #   es_PY                   es_PY.ISO8859-1
      #   es_SV                   es_SV.ISO8859-1
      #   es_UY                   es_UY.ISO8859-1
      #   es_VE                   es_VE.ISO8859-1
      #   fi                      fi_FI.ISO8859-1
      #   fi_FI                   fi_FI.ISO8859-1
      #   fi_FI.88591             fi_FI.ISO8859-1
      #   fi_FI.88591.en          fi_FI.ISO8859-1
      #   fi_FI.iso88591          fi_FI.ISO8859-1
      #   fi_FI.ISO_8859-1        fi_FI.ISO8859-1
      #   fr                      fr_FR.ISO8859-1
      #   fr_BE                   fr_BE.ISO8859-1
      #   fr_BE.88591             fr_BE.ISO8859-1
      #   fr_BE.88591.en          fr_BE.ISO8859-1
      #   fr_BE.ISO_8859-1        fr_BE.ISO8859-1
      #   fr_CA                   fr_CA.ISO8859-1
      #   fr_CA.88591             fr_CA.ISO8859-1
      #   fr_CA.88591.en          fr_CA.ISO8859-1
      #   fr_CA.iso88591          fr_CA.ISO8859-1
      #   fr_CA.ISO_8859-1        fr_CA.ISO8859-1
      #   fr_CH                   fr_CH.ISO8859-1
      #   fr_CH.88591             fr_CH.ISO8859-1
      #   fr_CH.88591.en          fr_CH.ISO8859-1
      #   fr_CH.ISO_8859-1        fr_CH.ISO8859-1
      #   fr_FR                   fr_FR.ISO8859-1
      #   fr_FR.88591             fr_FR.ISO8859-1
      #   fr_FR.88591.en          fr_FR.ISO8859-1
      #   fr_FR.iso88591          fr_FR.ISO8859-1
      #   fr_FR.ISO_8859-1        fr_FR.ISO8859-1
      #   FRE_FR.8859             fr_FR.ISO8859-1
      #   FRE_FR.8859.in          fr_FR.ISO8859-1
      #   he                      he_IL.ISO8859-8
      #   he_IL                   he_IL.ISO8859-8
      #   he_IL.iso88598          he_IL.ISO8859-8
      #   hr                      hr_HR.ISO8859-2
      #   hr_HR                   hr_HR.ISO8859-2
      #   hr_HR.iso88592          hr_HR.ISO8859-2
      #   hr_HR.ISO_8859-2        hr_HR.ISO8859-2
      #   hu                      hu_HU.ISO8859-2
      #   hu_HU                   hu_HU.ISO8859-2
      #   hu_HU.iso88592          hu_HU.ISO8859-2
      #   hu_HU.ISO_8859-2        hu_HU.ISO8859-2
      #   is                      is_IS.ISO8859-1
      #   is_IS                   is_IS.ISO8859-1
      #   is_IS.iso88591          is_IS.ISO8859-1
      #   is_IS.ISO_8859-1        is_IS.ISO8859-1
      #   it                      it_IT.ISO8859-1
      #   it_CH                   it_CH.ISO8859-1
      #   it_CH.ISO_8859-1        it_CH.ISO8859-1
      #   it_IT                   it_IT.ISO8859-1
      #   it_IT.88591             it_IT.ISO8859-1
      #   it_IT.88591.en          it_IT.ISO8859-1
      #   it_IT.iso88591          it_IT.ISO8859-1
      #   it_IT.ISO_8859-1        it_IT.ISO8859-1
      #   iw                      iw_IL.ISO8859-8
      #   iw_IL                   iw_IL.ISO8859-8
      #   iw_IL.iso88598          iw_IL.ISO8859-8
      #   iw_IL.ISO_8859-8        iw_IL.ISO8859-8
      #   ja                      ja_JP.eucJP
      #   ja_JP                   ja_JP.eucJP
      #   ja_JP.ujis              ja_JP.eucJP
      #   ja_JP.eucJP             ja_JP.eucJP
      #   Jp_JP                   ja_JP.eucJP
      #   ja_JP.AJEC              ja_JP.eucJP
      #   ja_JP.EUC               ja_JP.eucJP
      #   ja_JP.ISO-2022-JP       ja_JP.JIS7
      #   ja_JP.JIS               ja_JP.JIS7
      #   ja_JP.jis7              ja_JP.JIS7
      #   ja_JP.mscode            ja_JP.SJIS
      #   ja_JP.SJIS              ja_JP.SJIS
      #   ko                      ko_KR.eucKR
      #   ko_KR                   ko_KR.eucKR
      #   ko_KR.EUC               ko_KR.eucKR
      #   ko_KR.euc               ko_KR.eucKR
      #   # most locales in FreeBSD 2.1.[56] do not work, allow use of generic latin-1
      #   lt_LN.ISO_8859-1        lt_LN.ISO8859-1
      #   mk                      mk_MK.ISO8859-5
      #   mk_MK                   mk_MK.ISO8859-5
      #   mk_MK.ISO_8859-5        mk_MK.ISO8859-5
      #   nl                      nl_NL.ISO8859-1
      #   nl_BE                   nl_BE.ISO8859-1
      #   nl_BE.88591             nl_BE.ISO8859-1
      #   nl_BE.88591.en          nl_BE.ISO8859-1
      #   nl_BE.ISO_8859-1        nl_BE.ISO8859-1
      #   nl_NL                   nl_NL.ISO8859-1
      #   nl_NL.88591             nl_NL.ISO8859-1
      #   nl_NL.88591.en          nl_NL.ISO8859-1
      #   nl_NL.iso88591          nl_NL.ISO8859-1
      #   nl_NL.ISO_8859-1        nl_NL.ISO8859-1
      #   no                      no_NO.ISO8859-1
      #   no_NO                   no_NO.ISO8859-1
      #   no_NO.88591             no_NO.ISO8859-1
      #   no_NO.88591.en          no_NO.ISO8859-1
      #   no_NO.iso88591          no_NO.ISO8859-1
      #   no_NO.ISO_8859-1        no_NO.ISO8859-1
      #   pl                      pl_PL.ISO8859-2
      #   pl_PL                   pl_PL.ISO8859-2
      #   pl_PL.iso88592          pl_PL.ISO8859-2
      #   pl_PL.ISO_8859-2        pl_PL.ISO8859-2
      #   pt                      pt_PT.ISO8859-1
      #   pt_BR                   pt_BR.ISO8859-1
      #   pt_PT                   pt_PT.ISO8859-1
      #   pt_PT.88591             pt_PT.ISO8859-1
      #   pt_PT.88591.en          pt_PT.ISO8859-1
      #   pt_PT.iso88591          pt_PT.ISO8859-1
      #   pt_PT.ISO_8859-1        pt_PT.ISO8859-1
      #   ro                      ro_RO.ISO8859-2
      #   ro_RO                   ro_RO.ISO8859-2
      #   ro_RO.iso88592          ro_RO.ISO8859-2
      #   ro_RO.ISO_8859-2        ro_RO.ISO8859-2
      #   ru                      ru_RU.ISO8859-5
      #   ru_RU                   ru_RU.ISO8859-5
      #   ru_RU.iso88595          ru_RU.ISO8859-5
      #   ru_RU.ISO_8859-5        ru_RU.ISO8859-5
      #   ru_SU                   ru_RU.ISO8859-5
      #   ru_SU.ISO8859-5         ru_RU.ISO8859-5
      #   ru_SU.ISO_8859-5        ru_RU.ISO8859-5
      #   ru_SU.KOI8-R            ru_RU.KOI8-R
      #   sh                      sh_YU.ISO8859-2
      #   sh_YU                   sh_YU.ISO8859-2
      #   sh_YU.ISO_8859-2        sh_YU.ISO8859-2
      #   sh_SP                   sh_YU.ISO8859-2
      #   sk                      sk_SK.ISO8859-2
      #   sk_SK                   sk_SK.ISO8859-2
      #   sk_SK.ISO_8859-2        sk_SK.ISO8859-2
      #   sl                      sl_CS.ISO8859-2
      #   sl_CS                   sl_CS.ISO8859-2
      #   sl_CS.ISO_8859-2        sl_CS.ISO8859-2
      #   sl_SI                   sl_SI.ISO8859-2
      #   sl_SI.iso88592          sl_SI.ISO8859-2
      #   sl_SI.ISO_8859-2        sl_SI.ISO8859-2
      #   sp                      sp_YU.ISO8859-5
      #   sp_YU                   sp_YU.ISO8859-5
      #   sp_YU.ISO_8859-5        sp_YU.ISO8859-5
      #   sr_SP                   sr_SP.ISO8859-2
      #   sr_SP.ISO_8859-2        sr_SP.ISO8859-2
      #   sv                      sv_SE.ISO8859-1
      #   sv_SE                   sv_SE.ISO8859-1
      #   sv_SE.88591             sv_SE.ISO8859-1
      #   sv_SE.88591.en          sv_SE.ISO8859-1
      #   sv_SE.iso88591          sv_SE.ISO8859-1
      #   sv_SE.ISO_8859-1        sv_SE.ISO8859-1
      #   th_TH                   th_TH.TACTIS
      #   tr                      tr_TR.ISO8859-9
      #   tr_TR                   tr_TR.ISO8859-9
      #   tr_TR.iso88599          tr_TR.ISO8859-9
      #   tr_TR.ISO_8859-9        tr_TR.ISO8859-9
      #   zh                      zh_CN.eucCN
      #   zh_CN                   zh_CN.eucCN
      #   zh_CN.EUC               zh_CN.eucCN
      #   zh_TW                   zh_TW.eucTW
      #   zh_TW.EUC               zh_TW.eucTW
      #   # The following locale names are used in SCO 3.0
      #   english_uk.8859         en_GB.ISO8859-1
      #   english_us.8859         en_US.ISO8859-1
      #   english_us.ascii        en_US.ISO8859-1
      #   french_france.8859      fr_FR.ISO8859-1
      #   german_germany.8859     de_DE.ISO8859-1
      #   portuguese_brazil.8859  pt_BR.ISO8859-1
      #   spanish_spain.8859      es_ES.ISO8859-1
      #   # The following locale names are used in HPUX 9.x
      #   american.iso88591       en_US.ISO8859-1
      #   arabic.iso88596         ar_AA.ISO8859-6
      #   bulgarian               bg_BG.ISO8859-5
      #   c-french.iso88591       fr_CA.ISO8859-1
      #   chinese-s               zh_CN.eucCN
      #   chinese-t               zh_TW.eucTW
      #   croatian                hr_HR.ISO8859-2
      #   czech                   cs_CS.ISO8859-2
      #   danish.iso88591         da_DK.ISO8859-1
      #   dutch.iso88591          nl_BE.ISO8859-1
      #   english.iso88591        en_EN.ISO8859-1
      #   finnish.iso88591        fi_FI.ISO8859-1
      #   french.iso88591         fr_CH.ISO8859-1
      #   german.iso88591         de_CH.ISO8859-1
      #   greek.iso88597          el_GR.ISO8859-7
      #   hebrew.iso88598         iw_IL.ISO8859-8
      #   hungarian               hu_HU.ISO8859-2
      #   icelandic.iso88591      is_IS.ISO8859-1
      #   italian.iso88591        it_IT.ISO8859-1
      #   japanese                ja_JP.SJIS
      #   japanese.euc            ja_JP.eucJP
      #   korean                  ko_KR.eucKR
      #   norwegian.iso88591      no_NO.ISO8859-1
      #   polish                  pl_PL.ISO8859-2
      #   portuguese.iso88591     pt_PT.ISO8859-1
      #   rumanian                ro_RO.ISO8859-2
      #   russian                 ru_SU.ISO8859-5
      #   serbocroatian           sh_YU.ISO8859-2
      #   slovak                  sk_SK.ISO8859-2
      #   slovene                 sl_CS.ISO8859-2
      #   spanish.iso88591        es_ES.ISO8859-1
      #   swedish.iso88591        sv_SE.ISO8859-1
      #   turkish.iso88599        tr_TR.ISO8859-9
      #   # Solaris and SunOS have iso_8859_1 LC_CTYPES to augment LANG=C
      #   iso_8859_1              en_US.ISO8859-1
      #   # Microsoft Windows/NT 3.51 Japanese Edition
      #   Korean_Korea.949        ko_KR.eucKR
      #   Japanese_Japan.932      ja_JP.SJIS
      #   # Other miscellaneous locale names
      #   ISO8859-1               en_US.ISO8859-1
      #   ISO-8859-1              en_US.ISO8859-1
      #   japan                   ja_JP.eucJP
      #   Japanese-EUC            ja_JP.eucJP
      #
      # GNU locale.alias:
      #   czech                   cs_CZ.ISO-8859-2
      #   danish                  da_DK.ISO-8859-1
      #   dansk                   da_DK.ISO-8859-1
      #   deutsch                 de_DE.ISO-8859-1
      #   dutch                   nl_NL.ISO-8859-1
      #   finnish                 fi_FI.ISO-8859-1
      #   fran#ais                fr_FR.ISO-8859-1
      #   french                  fr_FR.ISO-8859-1
      #   german                  de_DE.ISO-8859-1
      #   greek                   el_GR.ISO-8859-7
      #   hebrew                  iw_IL.ISO-8859-8
      #   hungarian               hu_HU.ISO-8859-2
      #   icelandic               is_IS.ISO-8859-1
      #   italian                 it_IT.ISO-8859-1
      #   japanese                ja_JP.SJIS
      #   japanese.euc            ja_JP.eucJP
      #   norwegian               no_NO.ISO-8859-1
      #   polish                  pl_PL.ISO-8859-2
      #   portuguese              pt_PT.ISO-8859-1
      #   romanian                ro_RO.ISO-8859-2
      #   russian                 ru_RU.ISO-8859-5
      #   slovak                  sk_SK.ISO-8859-2
      #   slovene                 sl_CS.ISO-8859-2
      #   spanish                 es_ES.ISO-8859-1
      #   swedish                 sv_SE.ISO-8859-1
      #   turkish                 tr_TR.ISO-8859-9
      #
      if (locale && *locale) {
        # The most general syntax of a locale (not all optional parts
        # recognized by all systems) is
        # language[_territory][.codeset][@modifier][+special][,[sponsor][_revision]]
        # To retrieve the codeset, search the first dot. Stop searching when
        # a '@' or '+' or ',' is encountered.
        var DYNAMIC_ARRAY(buf,char,strlen(locale)+1);
        var const char* codeset = NULL;
        {
          var const char* cp = locale;
          for (; *cp != '\0' && *cp != '@' && *cp != '+' && *cp != ','; cp++) {
            if (*cp == '.') {
              codeset = ++cp;
              for (; *cp != '\0' && *cp != '@' && *cp != '+' && *cp != ','; cp++);
              if (*cp != '\0') {
                var uintL n = cp-codeset;
                memcpy(buf,codeset,n);
                buf[n] = '\0';
                codeset = buf;
              }
              break;
            }
          }
        }
        if (codeset) {
          # Canonicalize the charset given after the dot.
          if (   asciz_equal(codeset,"ISO8859-1")
              || asciz_equal(codeset,"ISO_8859-1")
              || asciz_equal(codeset,"iso88591")
              || asciz_equal(codeset,"88591")
              || asciz_equal(codeset,"88591.en")
              || asciz_equal(codeset,"8859")
              || asciz_equal(codeset,"8859.in")
              || asciz_equal(codeset,"ascii")
             )
            locale_charset = "ISO-8859-1";
          else
          if (   asciz_equal(codeset,"ISO8859-2")
              || asciz_equal(codeset,"ISO_8859-2")
              || asciz_equal(codeset,"iso88592")
             )
            locale_charset = "ISO-8859-2";
          else
          if (   asciz_equal(codeset,"ISO8859-5")
              || asciz_equal(codeset,"ISO_8859-5")
              || asciz_equal(codeset,"iso88595")
             )
            locale_charset = "ISO-8859-5";
          else
          if (   asciz_equal(codeset,"ISO8859-6")
              || asciz_equal(codeset,"ISO_8859-6")
              || asciz_equal(codeset,"iso88596")
             )
            locale_charset = "ISO-8859-6";
          else
          if (   asciz_equal(codeset,"ISO8859-7")
              || asciz_equal(codeset,"ISO_8859-7")
              || asciz_equal(codeset,"iso88597")
             )
            locale_charset = "ISO-8859-7";
          else
          if (   asciz_equal(codeset,"ISO8859-8")
              || asciz_equal(codeset,"iso88598")
             )
            locale_charset = "ISO-8859-8";
          else
          if (   asciz_equal(codeset,"ISO8859-9")
              || asciz_equal(codeset,"ISO_8859-9")
              || asciz_equal(codeset,"iso88599")
             )
            locale_charset = "ISO-8859-9";
          else
          if (asciz_equal(codeset,"KOI8-R"))
            locale_charset = "KOI8-R";
          else
          if (asciz_equal(codeset,"KOI8-U"))
            locale_charset = "KOI8-U";
          else
          if (   asciz_equal(codeset,"eucJP")
              || asciz_equal(codeset,"ujis")
              || asciz_equal(codeset,"AJEC")
             )
            locale_charset = "eucJP";
          else
          if (   asciz_equal(codeset,"JIS7")
              || asciz_equal(codeset,"jis7")
              || asciz_equal(codeset,"JIS")
              || asciz_equal(codeset,"ISO-2022-JP")
             )
            locale_charset = "JIS7";
          else
          if (   asciz_equal(codeset,"SJIS")
              || asciz_equal(codeset,"mscode")
              || asciz_equal(codeset,"932")
             )
            locale_charset = "SJIS";
          else
          if (   asciz_equal(codeset,"eucKR")
              || asciz_equal(codeset,"949")
             )
            locale_charset = "eucKR";
          else
          if (asciz_equal(codeset,"eucCN"))
            locale_charset = "eucCN";
          else
          if (asciz_equal(codeset,"eucTW"))
            locale_charset = "eucTW";
          else
          if (asciz_equal(codeset,"TACTIS"))
            locale_charset = "TACTIS";
          else
          if (asciz_equal(codeset,"EUC") || asciz_equal(codeset,"euc")) {
            if (locale[0]=='j' && locale[1]=='a')
              locale_charset = "eucJP";
            elif (locale[0]=='k' && locale[1]=='o')
              locale_charset = "eucKR";
            elif (locale[0]=='z' && locale[1]=='h' && locale[2]=='_') {
              if (locale[3]=='C' && locale[4]=='N')
                locale_charset = "eucCN";
              elif (locale[3]=='T' && locale[4]=='W')
                locale_charset = "eucTW";
            }
          }
          else
          # The following are CLISP extensions.
          if (   asciz_equal(codeset,"UTF-8")
              || asciz_equal(codeset,"utf8")
             )
            locale_charset = "UTF-8";
        } else {
          # No dot found. Choose a default, based on locale.
          if (   asciz_equal(locale,"iso_8859_1")
              || asciz_equal(locale,"ISO8859-1")
              || asciz_equal(locale,"ISO-8859-1")
             )
            locale_charset = "ISO-8859-1";
          else
          if (0)
            locale_charset = "ISO-8859-2";
          else
          if (0)
            locale_charset = "ISO-8859-5";
          else
          if (0)
            locale_charset = "ISO-8859-6";
          else
          if (0)
            locale_charset = "ISO-8859-7";
          else
          if (0)
            locale_charset = "ISO-8859-8";
          else
          if (0)
            locale_charset = "ISO-8859-9";
          else
          if (0)
            locale_charset = "KOI8-R";
          else
          if (0)
            locale_charset = "KOI8-U";
          else
          if (0)
            locale_charset = "eucJP";
          else
          if (0)
            locale_charset = "JIS7";
          else
          if (0)
            locale_charset = "SJIS";
          else
          if (0)
            locale_charset = "eucKR";
          else
          if (asciz_equal(locale,"zh_CN") || asciz_equal(locale,"zh")
             )
            locale_charset = "eucCN";
          else
          if (asciz_equal(locale,"zh_TW")
             )
            locale_charset = "eucTW";
          else
          if (0)
            locale_charset = "TACTIS";
          else {
            # Choose a default, based on the language only.
            var const char* underscore = strchr(locale,'_');
            var const char* lang;
            if (underscore) {
              var uintL n = underscore-locale;
              memcpy(buf,locale,n);
              buf[n] = '\0';
              lang = buf;
            } else {
              lang = locale;
            }
            if (   asciz_equal(lang,"da") || asciz_equal(lang,"danish") || asciz_equal(lang,"dansk")
                || asciz_equal(lang,"de") || asciz_equal(lang,"german") || asciz_equal(lang,"deutsch")
                || asciz_equal(lang,"en")
                || asciz_equal(lang,"es") || asciz_equal(lang,"spanish")
                || asciz_equal(lang,"fi") || asciz_equal(lang,"finnish")
                || asciz_equal(lang,"fr") || asciz_equal(lang,"french")
                                          #ifndef ASCII_CHS
                                          || asciz_equal(lang,"fran�ais")
                                          #endif
                || asciz_equal(lang,"is") || asciz_equal(lang,"icelandic")
                || asciz_equal(lang,"it") || asciz_equal(lang,"italian")
                || asciz_equal(lang,"nl") || asciz_equal(lang,"dutch")
                || asciz_equal(lang,"no") || asciz_equal(lang,"norwegian")
                || asciz_equal(lang,"pt") || asciz_equal(lang,"portuguese")
                || asciz_equal(lang,"sv") || asciz_equal(lang,"swedish")
               )
              locale_charset = "ISO-8859-1";
            else
            if (   asciz_equal(lang,"cs") || asciz_equal(lang,"czech")
                || asciz_equal(lang,"cz")
                || asciz_equal(lang,"hr") || asciz_equal(lang,"croatian")
                || asciz_equal(lang,"hu") || asciz_equal(lang,"hungarian")
                || asciz_equal(lang,"pl") || asciz_equal(lang,"polish")
                || asciz_equal(lang,"ro") || asciz_equal(lang,"romanian") || asciz_equal(lang,"rumanian")
                || asciz_equal(lang,"sh") /* || asciz_equal(lang,"serbocroatian") ?? */
                || asciz_equal(lang,"sk") || asciz_equal(lang,"slovak")
                || asciz_equal(lang,"sl") || asciz_equal(lang,"slovene")
                || asciz_equal(lang,"sr")
               )
              locale_charset = "ISO-8859-2";
            else
            if (   asciz_equal(lang,"bg") || asciz_equal(lang,"bulgarian")
                || asciz_equal(lang,"mk")
                || asciz_equal(lang,"ru") || asciz_equal(lang,"russian")
                || asciz_equal(lang,"sp")
               )
              locale_charset = "ISO-8859-5";
            else
            if (asciz_equal(lang,"ar")
               )
              locale_charset = "ISO-8859-6";
            else
            if (asciz_equal(lang,"el") || asciz_equal(lang,"greek")
               )
              locale_charset = "ISO-8859-7";
            else
            if (asciz_equal(lang,"iw") || asciz_equal(lang,"he") || asciz_equal(lang,"hebrew")
               )
              locale_charset = "ISO-8859-8";
            else
            if (asciz_equal(lang,"tr") || asciz_equal(lang,"turkish")
               )
              locale_charset = "ISO-8859-9";
            else
            if (0)
              locale_charset = "KOI8-R";
            else
            if (0)
              locale_charset = "KOI8-U";
            else
            if (   asciz_equal(lang,"ja")
                || asciz_equal(lang,"Jp")
                || asciz_equal(lang,"japan")
                || asciz_equal(lang,"Japanese-EUC")
               )
              locale_charset = "eucJP";
            else
            if (0)
              locale_charset = "JIS7";
            else
            if (asciz_equal(lang,"japanese")
               )
              locale_charset = "SJIS";
            else
            if (asciz_equal(lang,"ko") || asciz_equal(lang,"korean")
               )
              locale_charset = "eucKR";
            else
            if (asciz_equal(lang,"chinese-s")
               )
              locale_charset = "eucCN";
            else
            if (asciz_equal(lang,"chinese-t")
               )
              locale_charset = "eucTW";
            else
            if (asciz_equal(lang,"th")
               )
              locale_charset = "TACTIS";
            else {
            }
          }
        }
        FREE_DYNAMIC_ARRAY(buf);
      }
      #endif # UNICODE
      #endif # HAVE_LOCALE_H || UNICODE
    }

