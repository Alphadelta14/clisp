/* ANSI-C code produced by gperf version 2.7.2 */
/* Command-line: gperf -t -L ANSI-C -H aliases_hash -N aliases_lookup -7 -C -k '1,3-11,$' -i 1 lib/aliases.gperf  */
struct alias { const char* name; unsigned int encoding_index; };

#define TOTAL_KEYWORDS 301
#define MIN_WORD_LENGTH 2
#define MAX_WORD_LENGTH 45
#define MIN_HASH_VALUE 8
#define MAX_HASH_VALUE 2043
/* maximum key range = 2036, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
aliases_hash (register const char *str, register unsigned int len)
{
  static const unsigned short asso_values[] =
    {
      2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044,
      2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044,
      2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044,
      2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044,
      2044, 2044, 2044, 2044, 2044,    1,   21, 2044,   41,  236,
        26,  141,  351,  131,   61,  196,    1,  246,    1, 2044,
      2044, 2044, 2044, 2044, 2044,   21,   25,  297,  386,    1,
        61,   60,   34,    1,    1,    6,  256,  308,    6,    1,
        31, 2044,   16,    1,    1,  251,   51,    1,  476,    6,
         1, 2044, 2044, 2044, 2044,  166, 2044, 2044, 2044, 2044,
      2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044,
      2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044,
      2044, 2044, 2044, 2044, 2044, 2044, 2044, 2044
    };
  register int hval = len;

  switch (hval)
    {
      default:
      case 11:
        hval += asso_values[(unsigned char) str[10]];
      case 10:
        hval += asso_values[(unsigned char) str[9]];
      case 9:
        hval += asso_values[(unsigned char) str[8]];
      case 8:
        hval += asso_values[(unsigned char) str[7]];
      case 7:
        hval += asso_values[(unsigned char) str[6]];
      case 6:
        hval += asso_values[(unsigned char) str[5]];
      case 5:
        hval += asso_values[(unsigned char) str[4]];
      case 4:
        hval += asso_values[(unsigned char) str[3]];
      case 3:
        hval += asso_values[(unsigned char) str[2]];
      case 2:
      case 1:
        hval += asso_values[(unsigned char) str[0]];
        break;
    }
  return hval + asso_values[(unsigned char) str[len - 1]];
}

#ifdef __GNUC__
__inline
#endif
const struct alias *
aliases_lookup (register const char *str, register unsigned int len)
{
  static const struct alias wordlist[] =
    {
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"SJIS", ei_sjis},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"R8", ei_hp_roman8},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
      {"JP", ei_iso646_jp},
      {""}, {""},
      {"HZ", ei_hz},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"KOI8-R", ei_koi8_r},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"862", ei_cp862},
      {""}, {""}, {""}, {""}, {""},
      {"KOREAN", ei_ksc5601},
      {""}, {""}, {""}, {""}, {""},
      {"TCVN", ei_tcvn},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"GBK", ei_ces_gbk},
      {"GREEK8", ei_iso8859_7},
      {""},
      {"SHIFT-JIS", ei_sjis},
      {"GREEK", ei_iso8859_7},
      {""}, {""}, {""}, {""},
      {"HEBREW", ei_iso8859_8},
      {""},
      {"850", ei_cp850},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"JAVA", ei_java},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"JOHAB", ei_johab},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"JIS0208", ei_jisx0208},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"866", ei_cp866},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-IR-6", ei_ascii},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"ISO-IR-58", ei_gb2312},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-2022-KR", ei_iso2022_kr},
      {""}, {""}, {""}, {""},
      {"TIS620", ei_tis620},
      {""},
      {"TIS-620", ei_tis620},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
      {"ISO-2022-JP-2", ei_iso2022_jp2},
      {""}, {""},
      {"ISO-2022-JP", ei_iso2022_jp},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-IR-226", ei_iso8859_16},
      {""},
      {"BIGFIVE", ei_ces_big5},
      {""},
      {"BIG-FIVE", ei_ces_big5},
      {"GEORGIAN-PS", ei_georgian_ps},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"TIS620-0", ei_tis620},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"SHIFT_JIS", ei_sjis},
      {""}, {""}, {""},
      {"WCHAR_T", ei_local_wchar_t},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"US", ei_ascii},
      {""}, {""}, {""}, {""},
      {"L8", ei_iso8859_14},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"LATIN8", ei_iso8859_14},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"L2", ei_iso8859_2},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"CN", ei_iso646_cn},
      {"EUCTW", ei_euc_tw},
      {""},
      {"EUC-TW", ei_euc_tw},
      {""},
      {"UCS-2", ei_ucs2},
      {""}, {""},
      {"UCS-2BE", ei_ucs2be},
      {""},
      {"CHINESE", ei_gb2312},
      {""},
      {"MS-EE", ei_cp1250},
      {""},
      {"L6", ei_iso8859_10},
      {"UTF-8", ei_utf8},
      {""},
      {"LATIN2", ei_iso8859_2},
      {""}, {""}, {""},
      {"ASCII", ei_ascii},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
      {"EUCKR", ei_euc_kr},
      {""},
      {"EUC-KR", ei_euc_kr},
      {""},
      {"CSKOI8R", ei_koi8_r},
      {"MS-ANSI", ei_cp1252},
      {""}, {""}, {""}, {""},
      {"BIG5", ei_ces_big5},
      {""},
      {"BIG-5", ei_ces_big5},
      {"CHAR", ei_local_char},
      {""}, {""}, {""},
      {"VISCII", ei_viscii},
      {"ROMAN8", ei_hp_roman8},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"EUCJP", ei_euc_jp},
      {""},
      {"EUC-JP", ei_euc_jp},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"ISO-IR-203", ei_iso8859_15},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"L5", ei_iso8859_9},
      {"ISO-IR-100", ei_iso8859_1},
      {""},
      {"LATIN6", ei_iso8859_10},
      {""}, {""},
      {"ISO-8859-8", ei_iso8859_8},
      {""}, {""},
      {"HP-ROMAN8", ei_hp_roman8},
      {"L3", ei_iso8859_3},
      {""}, {""}, {""}, {""},
      {"ISO-2022-JP-1", ei_iso2022_jp1},
      {""}, {""},
      {"MS-GREEK", ei_cp1253},
      {"MS-HEBR", ei_cp1255},
      {"CSSHIFTJIS", ei_sjis},
      {"ISO-IR-138", ei_iso8859_8},
      {""}, {""},
      {"CN-GB", ei_euc_cn},
      {""},
      {"ISO-IR-126", ei_iso8859_7},
      {"CP862", ei_cp862},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-IR-87", ei_jisx0208},
      {"MS-ARAB", ei_cp1256},
      {""}, {""}, {""}, {""},
      {"IBM862", ei_cp862},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"ISO-2022-CN-EXT", ei_iso2022_cn_ext},
      {"ISO-2022-CN", ei_iso2022_cn},
      {""},
      {"ISO-8859-2", ei_iso8859_2},
      {""}, {""}, {""}, {""},
      {"ISO-IR-166", ei_tis620},
      {"ELOT_928", ei_iso8859_7},
      {""}, {""},
      {"L7", ei_iso8859_13},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""},
      {"CSISO2022KR", ei_iso2022_kr},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"CP866", ei_cp866},
      {""}, {""},
      {"CSISO2022JP2", ei_iso2022_jp2},
      {""}, {""}, {""},
      {"CSISO2022JP", ei_iso2022_jp},
      {"L1", ei_iso8859_1},
      {""}, {""}, {""}, {""},
      {"IBM866", ei_cp866},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"GEORGIAN-ACADEMY", ei_georgian_academy},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-8859-6", ei_iso8859_6},
      {"CP850", ei_cp850},
      {"KOI8-U", ei_koi8_u},
      {"MS_KANJI", ei_sjis},
      {""}, {""},
      {"GB2312", ei_euc_cn},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"IBM850", ei_cp850},
      {""}, {""},
      {"LATIN5", ei_iso8859_9},
      {""},
      {"KOI8-RU", ei_koi8_ru},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"UCS-2LE", ei_ucs2le},
      {""}, {""}, {""},
      {"ISO646-JP", ei_iso646_jp},
      {"CN-GB-ISOIR165", ei_isoir165},
      {"X0208", ei_jisx0208},
      {""},
      {"LATIN3", ei_iso8859_3},
      {"ISO-IR-57", ei_iso646_cn},
      {""}, {""},
      {"NEXTSTEP", ei_nextstep},
      {""}, {""}, {""},
      {"ISO_8859-8", ei_iso8859_8},
      {""}, {""}, {""}, {""},
      {"BIG5HKSCS", ei_big5hkscs},
      {"ISO_8859-8:1988", ei_iso8859_8},
      {""},
      {"GB18030", ei_gb18030},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"UCS-2-INTERNAL", ei_ucs2internal},
      {""}, {""},
      {"ASMO-708", ei_iso8859_6},
      {""}, {""}, {""},
      {"US-ASCII", ei_ascii},
      {""}, {""},
      {"ISO-IR-110", ei_iso8859_4},
      {"HZ-GB-2312", ei_hz},
      {""}, {""}, {""},
      {"ISO-IR-165", ei_isoir165},
      {""}, {""}, {""}, {""}, {""},
      {"MS-TURK", ei_cp1254},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"L4", ei_iso8859_4},
      {"ISO_8859-2", ei_iso8859_2},
      {""},
      {"EUCCN", ei_euc_cn},
      {""},
      {"EUC-CN", ei_euc_cn},
      {""}, {""}, {""}, {""}, {""},
      {"ISO-IR-148", ei_iso8859_9},
      {""}, {""}, {""}, {""}, {""},
      {"CSASCII", ei_ascii},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"CSISOLATINHEBREW", ei_iso8859_8},
      {""},
      {"UCS-4BE", ei_ucs4be},
      {""}, {""},
      {"ARMSCII-8", ei_armscii_8},
      {""}, {""},
      {"TIS620.2533-0", ei_tis620},
      {"UTF-16BE", ei_utf16be},
      {""}, {""},
      {"CSISOLATIN2", ei_iso8859_2},
      {""}, {""},
      {"CSBIG5", ei_ces_big5},
      {""},
      {"CN-BIG5", ei_ces_big5},
      {""},
      {"ISO-8859-5", ei_iso8859_5},
      {""}, {""},
      {"CSVISCII", ei_viscii},
      {""}, {""}, {""},
      {"LATIN7", ei_iso8859_13},
      {""}, {""}, {""},
      {"CSISOLATINGREEK", ei_iso8859_7},
      {""},
      {"ARABIC", ei_iso8859_6},
      {""},
      {"MACTHAI", ei_mac_thai},
      {""}, {""}, {""}, {""},
      {"ISO-8859-3", ei_iso8859_3},
      {""},
      {"UTF-16", ei_utf16},
      {""}, {""},
      {"ISO_8859-6", ei_iso8859_6},
      {""}, {""},
      {"TCVN-5712", ei_tcvn},
      {""},
      {"ISO-IR-127", ei_iso8859_6},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"MACINTOSH", ei_mac_roman},
      {"MACHEBREW", ei_mac_hebrew},
      {""}, {""},
      {"ISO_8859-5:1988", ei_iso8859_5},
      {""},
      {"CP1258", ei_cp1258},
      {""}, {""}, {""}, {""},
      {"MACGREEK", ei_mac_greek},
      {""}, {""},
      {"ISO_8859-3:1988", ei_iso8859_3},
      {""}, {""}, {""},
      {"UTF-7", ei_utf7},
      {""},
      {"ISO-8859-10", ei_iso8859_10},
      {""}, {""}, {""}, {""}, {""},
      {"CSISOLATIN6", ei_iso8859_10},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"CSHPROMAN8", ei_hp_roman8},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"ISO646-US", ei_ascii},
      {"CSISO2022CN", ei_iso2022_cn},
      {"CSISO58GB231280", ei_gb2312},
      {"CP932", ei_cp932},
      {"LATIN1", ei_iso8859_1},
      {""}, {""}, {""}, {""}, {""},
      {"CP1252", ei_cp1252},
      {"GB_2312-80", ei_gb2312},
      {""}, {""},
      {"ISO-8859-16", ei_iso8859_16},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"CP950", ei_cp950},
      {""},
      {"JIS_X0208", ei_jisx0208},
      {"UCS-2-SWAPPED", ei_ucs2swapped},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""},
      {"CP1250", ei_cp1250},
      {""},
      {"ISO-IR-101", ei_iso8859_2},
      {""}, {""}, {""}, {""},
      {"ISO-8859-7", ei_iso8859_7},
      {"ISO_8859-2:1987", ei_iso8859_2},
      {""}, {""}, {""},
      {"ISO-IR-157", ei_iso8859_10},
      {""}, {""}, {""},
      {"ISO646-CN", ei_iso646_cn},
      {"X0212", ei_jisx0212},
      {""}, {""}, {""}, {""},
      {"ISO-IR-109", ei_iso8859_3},
      {""}, {""},
      {"WINDOWS-1258", ei_cp1258},
      {"GB_1988-80", ei_iso646_cn},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"CP936", ei_ces_gbk},
      {""},
      {"ECMA-118", ei_iso8859_7},
      {""}, {""}, {""}, {""},
      {"CP1256", ei_cp1256},
      {""},
      {"ISO_8859-5", ei_iso8859_5},
      {"ISO_8859-6:1987", ei_iso8859_6},
      {""},
      {"CSIBM866", ei_cp866},
      {""}, {""}, {""}, {""},
      {"WINDOWS-1252", ei_cp1252},
      {"TIS620.2529-1", ei_tis620},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"TIS620.2533-1", ei_tis620},
      {"ISO_8859-3", ei_iso8859_3},
      {""}, {""},
      {"WINDOWS-1250", ei_cp1250},
      {""},
      {"CSGB2312", ei_euc_cn},
      {""}, {""},
      {"UHC", ei_cp949},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"CSEUCTW", ei_euc_tw},
      {""},
      {"CSISOLATIN5", ei_iso8859_9},
      {""}, {""}, {""}, {""},
      {"WINDOWS-1256", ei_cp1256},
      {""},
      {"ISO-8859-1", ei_iso8859_1},
      {""},
      {"ISO_8859-10:1992", ei_iso8859_10},
      {""},
      {"UCS-4LE", ei_ucs4le},
      {""}, {""}, {""}, {""},
      {"JIS_C6220-1969-RO", ei_iso646_jp},
      {""},
      {"UTF-16LE", ei_utf16le},
      {"ISO_8859-10", ei_iso8859_10},
      {"CSISOLATIN3", ei_iso8859_3},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-8859-9", ei_iso8859_9},
      {""}, {""}, {""}, {""},
      {"ISO-IR-159", ei_jisx0212},
      {"CSEUCKR", ei_euc_kr},
      {"ISO-8859-15", ei_iso8859_15},
      {""}, {""}, {""},
      {"CP367", ei_ascii},
      {""}, {""}, {""},
      {"UCS-4-INTERNAL", ei_ucs4internal},
      {""},
      {"ISO_8859-16:2000", ei_iso8859_16},
      {""}, {""},
      {"MAC", ei_mac_roman},
      {""}, {""}, {""},
      {"IBM367", ei_ascii},
      {""}, {""},
      {"ISO-8859-13", ei_iso8859_13},
      {""}, {""}, {""},
      {"ISO_8859-4:1988", ei_iso8859_4},
      {"ISO_8859-16", ei_iso8859_16},
      {"MACUKRAINE", ei_mac_ukraine},
      {"CSISOLATINARABIC", ei_iso8859_6},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"ISO_8859-15:1998", ei_iso8859_15},
      {"WINDOWS-1255", ei_cp1255},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"WINDOWS-1253", ei_cp1253},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO_8859-7", ei_iso8859_7},
      {""}, {""},
      {"WINBALTRIM", ei_cp1257},
      {""},
      {"ISO-IR-179", ei_iso8859_13},
      {"ISO_8859-7:1987", ei_iso8859_7},
      {""},
      {"CP1255", ei_cp1255},
      {"MACTURKISH", ei_mac_turkish},
      {"UCS-4", ei_ucs4},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-IR-14", ei_iso646_jp},
      {""}, {""},
      {"MACROMAN", ei_mac_roman},
      {"LATIN4", ei_iso8859_4},
      {""}, {""}, {""}, {""},
      {"CSISO159JISX02121990", ei_jisx0212},
      {"CP1253", ei_cp1253},
      {""}, {""}, {""},
      {"ISO_646.IRV:1991", ei_ascii},
      {""}, {""}, {""},
      {"MACCROATIAN", ei_mac_croatian},
      {""}, {""}, {""}, {""}, {""},
      {"CSISO87JISX0208", ei_jisx0208},
      {""}, {""}, {""},
      {"ISO_8859-1:1987", ei_iso8859_1},
      {""},
      {"WINDOWS-1257", ei_cp1257},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO-IR-199", ei_iso8859_14},
      {""}, {""},
      {"JIS_X0212", ei_jisx0212},
      {""},
      {"MACROMANIA", ei_mac_romania},
      {"CSPC862LATINHEBREW", ei_cp862},
      {"CSMACINTOSH", ei_mac_roman},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"X0201", ei_jisx0201},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO_8859-1", ei_iso8859_1},
      {"CP819", ei_iso8859_1},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"WINDOWS-1251", ei_cp1251},
      {""}, {""},
      {"TCVN5712-1:1993", ei_tcvn},
      {""}, {""},
      {"IBM819", ei_iso8859_1},
      {"JIS_X0208-1990", ei_jisx0208},
      {"ISO-10646-UCS-2", ei_ucs2},
      {""}, {""}, {""},
      {"ISO_8859-9", ei_iso8859_9},
      {""}, {""}, {""}, {""}, {""},
      {"ISO_8859-9:1989", ei_iso8859_9},
      {"ISO_8859-15", ei_iso8859_15},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"CSISOLATIN1", ei_iso8859_1},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO_8859-13", ei_iso8859_13},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"CP1257", ei_cp1257},
      {"UCS-4-SWAPPED", ei_ucs4swapped},
      {""}, {""}, {""},
      {"UNICODEBIG", ei_ucs2be},
      {""},
      {"ISO-8859-4", ei_iso8859_4},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
      {"ISO-IR-149", ei_ksc5601},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"TCVN5712-1", ei_tcvn},
      {""},
      {"CSHALFWIDTHKATAKANA", ei_jisx0201},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"JIS_X0208-1983", ei_jisx0208},
      {""},
      {"MS-CYRL", ei_cp1251},
      {""}, {""}, {""}, {""},
      {"ISO_8859-14:1998", ei_iso8859_14},
      {"WINDOWS-1254", ei_cp1254},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
      {"CP1251", ei_cp1251},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""},
      {"KSC_5601", ei_ksc5601},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""},
      {"CSISOLATINCYRILLIC", ei_iso8859_5},
      {"CP1133", ei_cp1133},
      {""}, {""},
      {"CP874", ei_cp874},
      {""}, {""}, {""},
      {"CSISO14JISC6220RO", ei_iso646_jp},
      {""}, {""},
      {"CSISO57GB1988", ei_iso646_cn},
      {""},
      {"UNICODELITTLE", ei_ucs2le},
      {""}, {""},
      {"CP1361", ei_johab},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"MACCENTRALEUROPE", ei_mac_centraleurope},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"JIS_X0201", ei_jisx0201},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"CSUNICODE", ei_ucs2},
      {"EXTENDED_UNIX_CODE_PACKED_FORMAT_FOR_JAPANESE", ei_euc_jp},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"ISO_8859-4", ei_iso8859_4},
      {""}, {""}, {""}, {""},
      {"JIS_X0212-1990", ei_jisx0212},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"JIS_X0212.1990-0", ei_jisx0212},
      {""}, {""}, {""}, {""},
      {"MACARABIC", ei_mac_arabic},
      {""}, {""}, {""}, {""}, {""},
      {"CSISOLATIN4", ei_iso8859_4},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"WINDOWS-874", ei_cp874},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"ISO-IR-144", ei_iso8859_5},
      {""}, {""}, {""}, {""},
      {"MULELAO-1", ei_mulelao},
      {""}, {""},
      {"VISCII1.1-1", ei_viscii},
      {""}, {""}, {""},
      {"ISO-8859-14", ei_iso8859_14},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"ISO-10646-UCS-4", ei_ucs4},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"JISX0201-1976", ei_jisx0201},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"CP949", ei_cp949},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"CP1254", ei_cp1254},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"CYRILLIC", ei_iso8859_5},
      {"ANSI_X3.4-1968", ei_ascii},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
      {"ISO_8859-14", ei_iso8859_14},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"ECMA-114", ei_iso8859_6},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"IBM-CP1133", ei_cp1133},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"KS_C_5601-1987", ei_ksc5601},
      {""}, {""},
      {"CSUCS4", ei_ucs4},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"KS_C_5601-1989", ei_ksc5601},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""},
      {"UNICODE-1-1-UTF-7", ei_utf7},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"UNICODE-1-1", ei_ucs2be},
      {"CSEUCPKDFMTJAPANESE", ei_euc_jp},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"CSKSC56011987", ei_ksc5601},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"CSPC850MULTILINGUAL", ei_cp850},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""},
      {"CSUNICODE11UTF7", ei_utf7},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"CSUNICODE11", ei_ucs2be},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"MACICELAND", ei_mac_iceland},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"MACCYRILLIC", ei_mac_cyrillic}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = aliases_hash (str, len);

      if (key <= MAX_HASH_VALUE && key >= 0)
        {
          register const char *s = wordlist[key].name;

          if (*str == *s && !strcmp (str + 1, s + 1))
            return &wordlist[key];
        }
    }
  return 0;
}
