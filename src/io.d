# Input/Output for CLISP
# Bruno Haible 1990-2001
# Marcus Daniels 11.3.1997
# Sam Steingold 1998-2001

#include "lispbibl.c"
#include "arilev0.c" # for Division in pr_uint

# IO_DEBUG must be undefined in the code comitted to CVS
#define IO_DEBUG 0
#ifdef IO_DEBUG
#include <stdio.h>
global object car (object o) { return Car(o); }
global object cdr (object o) { return Cdr(o); }
global object pph_str (object o) { return TheStream(o)->strm_pphelp_strings; }
global Stream thestream (object o) { return TheStream(o); }
global char* clisp_type_of (object o) {
  pushSTACK(o); funcall(L(type_of),1);
  pushSTACK(value1); funcall(L(prin1_to_string),1);
  var object ret = string_to_asciz(value1,O(misc_encoding));
  return TheSbvector(ret)->data;
}
global void sstring_printf (object sstr, uintL len, uintL offset) {
  uintL idx;
  ASSERT(simple_string_p(sstr));
  printf("<%d/%d\"",len,offset);
  for(idx=offset;idx<len;idx++) {
    chart ch;
    SstringDispatch(sstr,{ ch=TheSstring(sstr)->data[idx]; },
                    { ch=as_chart(TheSmallSstring(sstr)->data[idx]); });
    printf("%c",as_cint(ch));
  }
  printf("\">");
}
global void string_printf (object str) {
  uintL len, offset, idx;
  ASSERT(stringp(str));
  str = unpack_string_ro(str,&len,&offset);
  sstring_printf(str,len,offset);
}
#define NL_TYPE(x) \
 (eq(x,S(Klinear))? 'L' : eq(x,S(Kmiser)) ? 'M' : eq(x,S(Kfill)) ? 'F' : 'D')
global void pph_top_printf (object top) {
  if (stringp(top)) string_printf(top);
  else if (posfixnump(top)) printf("%d",posfixnum_to_L(top));
  else if (symbolp(top)) printf("%c",NL_TYPE(top));
  else if (mconsp(top))
    printf("%d/%c",posfixnum_to_L(Cdr(top)),NL_TYPE(Car(top)));
  else if (vectorp(top)) {
    var object * data = TheSvector(top)->data;
    printf("[%c/%c/%d/%d]",
           eq(data[0],T) ? 't' : 'n',eq(data[1],T) ? 't' : 'n',
           posfixnum_to_L(data[2]),posfixnum_to_L(data[3]));
  } else { object_out(top); NOTREACHED; }
}
#define PPH_TOP(label,top)                      \
  do { printf(#label "[%d]: [",__LINE__);       \
       pph_top_printf(top);                     \
       printf("]\n"); } while(0)
static bool inside_pp = false;
global void pphelp_printf (object pph) {
  if (inside_pp) return;
  inside_pp = true;
  ASSERT(streamp(pph));
  var object zz = T;
  var object yy = NIL;
  var object list = TheStream(pph)->strm_pphelp_strings;
  printf("#<pphelp[%c/%d]",
         (eq(TheStream(pph)->strm_pphelp_modus,NIL) ? 'e' : 'm'),
         llength(list));
  while (mconsp(list)) {
    printf(" ");
    pph_top_printf(Car(list));
    list = Cdr(list);
  }
  printf(">");
  inside_pp = false;
}
#undef NL_TYPE
#define GC_CHECK \
  do{printf("<%d",__LINE__);fflush(stdout);gar_col();printf(">\n");}while(0)
#define PPH_OUT(label,stream)                   \
  do { printf(#label "[%d]: [",__LINE__);       \
       pphelp_printf(stream);                   \
       printf("]\n"); } while(0)
#else
#define GC_CHECK
#define PPH_OUT(l,s)
#define PPH_TOP(l,s)
#endif

# =============================================================================
# Readtable-functions
# =============================================================================

# Tables indexed by characters.
# allocate_perchar_table()
# perchar_table_get(table,c)
# perchar_table_put(table,c,value)
# copy_perchar_table(table)
#if (small_char_code_limit < char_code_limit)
 # A simple-vector of small_char_code_limit+1 elements, the last entry being
 # a hash table for the non-base characters.
local object allocate_perchar_table (void) {
   # Allocate the hash table.
   pushSTACK(S(Ktest)); pushSTACK(S(eq)); funcall(L(make_hash_table),2);
   pushSTACK(value1);
   # Allocate the simple-vector.
   var object table = allocate_vector(small_char_code_limit+1);
   TheSvector(table)->data[small_char_code_limit] = popSTACK();
   return table;
}
local object perchar_table_get (object table, chart c) {
  if (as_cint(c) < small_char_code_limit) {
    return TheSvector(table)->data[as_cint(c)];
  } else {
    var object value = gethash(code_char(c),
                               TheSvector(table)->data[small_char_code_limit]);
    return (eq(value,nullobj) ? NIL : value);
  }
}
local void perchar_table_put (object table, chart c, object value) {
  if (as_cint(c) < small_char_code_limit) {
    TheSvector(table)->data[as_cint(c)] = value;
  } else {
    shifthash(TheSvector(table)->data[small_char_code_limit],
              code_char(c),value);
  }
}
local object copy_perchar_table (object table) {
  pushSTACK(copy_svector(table));
  # Allocate a new hash table.
  pushSTACK(S(Ktest)); pushSTACK(S(eq)); funcall(L(make_hash_table),2);
  pushSTACK(value1);
  # stack layout: table, newht.
  map_hashtable(TheSvector(STACK_1)->data[small_char_code_limit],
                key,value,{ shifthash(STACK_(0+1),key,value); });
  var object newht = popSTACK();
  var object table = popSTACK();
  TheSvector(table)->data[small_char_code_limit] = newht;
  return table;
}
#else
 # A simple-vector of char_code_limit elements.
#define allocate_perchar_table()  allocate_vector(char_code_limit)
#define perchar_table_get(table,c)  TheSvector(table)->data[(uintP)as_cint(c)]
#define perchar_table_put(table,c,value)  (TheSvector(table)->data[(uintP)as_cint(c)] = (value))
#define copy_perchar_table(table)  copy_svector(table)
#endif

# Structure of Readtables (cf. LISPBIBL.D):
  # readtable_syntax_table
  #    bitvector consisting of char_code_limit bytes: for each character the
  #                                                   syntaxcode is assigned
  # readtable_macro_table
  #    a vector with char_code_limit elements: for each character
  #    either    (if the character is not a read-macro)
  #              NIL
  #    or        (if the character is a dispatch-macro)
  #              a vector with char_code_limit functions/NILs,
  #    or        (if the character is a read-macro defined by a function)
  #              the function, which is called, when the character is read.
  # readtable_case
  #    a fixnum in {0,1,2,3}

# meaning of case (in sync with CONSTOBJ.D!):
  #define case_upcase    0
  #define case_downcase  1
  #define case_preserve  2
  #define case_invert    3

# meaning of the entries in the syntax_table:
  #define syntax_illegal      0  # unprintable, excluding whitespace
  #define syntax_single_esc   1  # '\' (Single Escape)
  #define syntax_multi_esc    2  # '|' (Multiple Escape)
  #define syntax_constituent  3  # the rest (Constituent)
  #define syntax_whitespace   4  # TAB,LF,FF,CR,' ' (Whitespace)
  #define syntax_eof          5  # EOF
  #define syntax_t_macro      6  # '()'"' (Terminating Macro)
  #define syntax_nt_macro     7  # '#' (Non-Terminating Macro)
# <= syntax_constituent : if an object starts with such a character, it's a token.
#                         (syntax_illegal will deliver an error then.)
# >= syntax_t_macro : macro-character.
#                     if an object starts like that: call read-macro function.

# Syntax tables, indexed by characters.
# allocate_syntax_table()
# syntax_table_get(table,c)
# syntax_table_put(table,c,value)
# syntax_table_put can trigger GC
#if (small_char_code_limit < char_code_limit)
 # A cons, consisting of a simple-bit-vector with small_char_code_limit
 # bytes, and a hash table mapping characters to fixnums. Characters not
 # found in the hash table are assumed to have the syntax code
 # (graphic_char_p(ch) ? syntax_constituent : syntax_illegal).
local object allocate_syntax_table (void) {
  # Allocate the hash table.
  pushSTACK(S(Ktest)); pushSTACK(S(eq)); funcall(L(make_hash_table),2);
  pushSTACK(value1);
  # Allocate the simple-bit-vector.
  pushSTACK(allocate_bit_vector(Atype_8Bit,small_char_code_limit));
  var object new_cons = allocate_cons();
  Car(new_cons) = popSTACK();
  Cdr(new_cons) = popSTACK();
  return new_cons;
}
#define syntax_table_get(table,c)  \
      (as_cint(c) < small_char_code_limit           \
       ? TheSbvector(Car(table))->data[as_cint(c)] \
       : syntax_table_get_notinline(table,c))
local uintB syntax_table_get_notinline (object table, chart c) {
  var object val = gethash(code_char(c),Cdr(table));
  if (!eq(val,nullobj))
    return posfixnum_to_L(val);
  else
    return (graphic_char_p(c) ? syntax_constituent : syntax_illegal);
}
#define syntax_table_put(table,c,value)  \
      (as_cint(c) < small_char_code_limit                            \
       ? (void)(TheSbvector(Car(table))->data[as_cint(c)] = (value)) \
       : syntax_table_put_notinline(table,c,value))
local void syntax_table_put_notinline (object table, chart c, uintB value) {
  shifthash(Cdr(table),code_char(c),fixnum(value));
}
#else
 # A simple-bit-vector with char_code_limit bytes.
#define allocate_syntax_table()         \
  allocate_bit_vector(Atype_8Bit,char_code_limit)
#define syntax_table_get(table,c)       \
  TheSbvector(table)->data[as_cint(c)]
#define syntax_table_put(table,c,value) \
  (TheSbvector(table)->data[as_cint(c)] = (value))
#endif
#define syntax_readtable_get(rt,c)     \
  syntax_table_get(TheReadtable(rt)->readtable_syntax_table,c)
#define syntax_readtable_put(rt,c,v)   \
  syntax_table_put(TheReadtable(rt)->readtable_syntax_table,c,v)

# standard(original) syntaxtable(readtable)  for read characters:
local const uintB orig_syntax_table [small_char_code_limit] = {
    #define illg  syntax_illegal
    #define sesc  syntax_single_esc
    #define mesc  syntax_multi_esc
    #define cnst  syntax_constituent
    #define whsp  syntax_whitespace
    #define tmac  syntax_t_macro
    #define nmac  syntax_nt_macro
      illg,illg,illg,illg,illg,illg,illg,illg,   # chr(0) upto chr(7)
      cnst,whsp,whsp,illg,whsp,whsp,illg,illg,   # chr(8) upto chr(15)
      illg,illg,illg,illg,illg,illg,illg,illg,   # chr(16) upto chr(23)
      illg,illg,illg,illg,illg,illg,illg,illg,   # chr(24) upto chr(31)
      whsp,cnst,tmac,nmac,cnst,cnst,cnst,tmac,   # ' !"#$%&''
      tmac,tmac,cnst,cnst,tmac,cnst,cnst,cnst,   # '()*+,-./'
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,   # '01234567'
      cnst,cnst,cnst,tmac,cnst,cnst,cnst,cnst,   # '89:;<=>?'
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,   # '@ABCDEFG'
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,   # 'HIJKLMNO'
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,   # 'PQRSTUVW'
      cnst,cnst,cnst,cnst,sesc,cnst,cnst,cnst,   # 'XYZ[\]^_'
      tmac,cnst,cnst,cnst,cnst,cnst,cnst,cnst,   # '`abcdefg'
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,   # 'hijklmno'
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,   # 'pqrstuvw'
      cnst,cnst,cnst,cnst,mesc,cnst,cnst,cnst,   # 'xyz{|}~',chr(127)
    #if defined(UNICODE) || defined(ISOLATIN_CHS) || defined(HPROMAN8_CHS)
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      whsp,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
    #elif defined(IBMPC_CHS)
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
    #elif defined(NEXTSTEP_CHS)
      whsp,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
      cnst,cnst,cnst,cnst,cnst,cnst,cnst,cnst,
    #else # defined(ASCII_CHS) && !defined(UNICODE)
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
      illg,illg,illg,illg,illg,illg,illg,illg,
    #endif
    #undef illg
    #undef sesc
    #undef mesc
    #undef cnst
    #undef whsp
    #undef tmac
    #undef nmac
    };
#if (small_char_code_limit < char_code_limit)
#define orig_syntax_table_get(c)  \
      (as_cint(c) < small_char_code_limit                          \
       ? orig_syntax_table[as_cint(c)]                             \
       : (graphic_char_p(c) ? syntax_constituent : syntax_illegal))
#else
#define orig_syntax_table_get(c)  orig_syntax_table[as_cint(c)]
#endif

# UP: returns the standard (original) readtable.
# orig_readtable()
# < result: standard(original) readtable
# can trigger GC
local object orig_readtable (void) {
  { # initialize the syntax-table:
    var object s_table = allocate_syntax_table(); # new bitvector
    pushSTACK(s_table); # save
    # and fill with the original:
   #if (small_char_code_limit < char_code_limit)
    s_table = Car(s_table);
   #endif
    var const uintB * ptr1 = &orig_syntax_table[0];
    var uintB* ptr2 = &TheSbvector(s_table)->data[0];
    var uintC count;
    dotimesC(count,small_char_code_limit, { *ptr2++ = *ptr1++; } );
  }
  { # initialize dispatch-macro '#':
    var object d_table = allocate_perchar_table(); # new vector
    pushSTACK(d_table); # save
    # and add the sub-character-functions for '#':
    var object* table = &TheSvector(d_table)->data[0];
    table['\''] = L(function_reader);
    table['|'] = L(comment_reader);
    table['\\'] = L(char_reader);
    table['B'] = L(binary_reader);
    table['O'] = L(octal_reader);
    table['X'] = L(hexadecimal_reader);
    table['R'] = L(radix_reader);
    table['C'] = L(complex_reader);
    table[':'] = L(uninterned_reader);
    table['*'] = L(bit_vector_reader);
    table['('] = L(vector_reader);
    table['A'] = L(array_reader);
    table['.'] = L(read_eval_reader);
    table[','] = L(load_eval_reader);
    table['='] = L(label_definition_reader);
    table['#'] = L(label_reference_reader);
    table['<'] = L(not_readable_reader);
    table[')'] = L(syntax_error_reader);
    table[' '] = L(syntax_error_reader); # #\Space
    table[NL] = L(syntax_error_reader); # #\Newline = 10 = #\Linefeed
    table[BS] = L(syntax_error_reader); # #\Backspace
    table[TAB] = L(syntax_error_reader); # #\Tab
    table[CR] = L(syntax_error_reader); # #\Return
    table[PG] = L(syntax_error_reader); # #\Page
    table[RUBOUT] = L(syntax_error_reader); # #\Rubout
    table['+'] = L(feature_reader);
    table['-'] = L(not_feature_reader);
    table['S'] = L(structure_reader);
    table['Y'] = L(closure_reader);
    table['"'] = L(clisp_pathname_reader);
    table['P'] = L(ansi_pathname_reader);
  }
  { # initialize READ-macros:
    var object m_table = allocate_perchar_table(); # new NIL-filled vector
    # and add the macro-characters:
    var object* table = &TheSvector(m_table)->data[0];
    table['('] = L(lpar_reader);
    table[')'] = L(rpar_reader);
    table['"'] = L(string_reader);
    table['\''] = L(quote_reader);
    table['#'] = popSTACK(); # dispatch-vector for '#'
    table[';'] = L(line_comment_reader);
    table['`'] = S(backquote_reader); # cf. BACKQUOTE.LISP
    table[','] = S(comma_reader); # cf. BACKQUOTE.LISP
    pushSTACK(m_table); # save
  }
  { # build readtable:
    var object readtable = allocate_readtable(); # new readtable
    TheReadtable(readtable)->readtable_macro_table = popSTACK(); # m_table
    TheReadtable(readtable)->readtable_syntax_table = popSTACK(); # s_table
    TheReadtable(readtable)->readtable_case = fixnum(case_upcase); # :UPCASE
    return readtable;
  }
}

# UP: copies a readtable
# copy_readtable_contents(from_readtable,to_readtable)
# > from-readtable
# > to-readtable
# < result : to-Readtable with same content
# can trigger GC
local object copy_readtable_contents (object from_readtable,
                                      object to_readtable) {
  # copy the case-slot:
  TheReadtable(to_readtable)->readtable_case =
    TheReadtable(from_readtable)->readtable_case;
  { # copy the syntaxtable:
    var object stable1;
    var object stable2;
   #if (small_char_code_limit < char_code_limit)
    pushSTACK(to_readtable);
    pushSTACK(from_readtable);
    # Allocate a new hash table.
    pushSTACK(S(Ktest)); pushSTACK(S(eq)); funcall(L(make_hash_table),2);
    pushSTACK(value1);
    # stack layout: to-readtable, from-readtable, newht.
    map_hashtable(Cdr(TheReadtable(STACK_1)->readtable_syntax_table),ch,entry,
                  { shifthash(STACK_(0+1),ch,entry); });
    {
      var object newht = popSTACK();
      from_readtable = popSTACK();
      to_readtable = popSTACK();
      stable1 = Car(TheReadtable(from_readtable)->readtable_syntax_table);
      stable2 = TheReadtable(to_readtable)->readtable_syntax_table;
      Cdr(stable2) = newht;
      stable2 = Car(stable2);
    }
   #else
    stable1 = TheReadtable(from_readtable)->readtable_syntax_table;
    stable2 = TheReadtable(to_readtable)->readtable_syntax_table;
   #endif
    var const uintB* ptr1 = &TheSbvector(stable1)->data[0];
    var uintB* ptr2 = &TheSbvector(stable2)->data[0];
    var uintC count;
    dotimesC(count,small_char_code_limit, { *ptr2++ = *ptr1++; } );
  }
  # copy the macro-table:
  pushSTACK(to_readtable); # save to-readtable
  {
    var object mtable1 = TheReadtable(from_readtable)->readtable_macro_table;
    var object mtable2 = TheReadtable(to_readtable)->readtable_macro_table;
    var uintL i;
    for (i = 0; i < small_char_code_limit; i++) {
      # copy entry number i:
      var object entry = TheSvector(mtable1)->data[i];
      if (simple_vector_p(entry)) {
        # simple-vector is copied element for element:
        pushSTACK(mtable1); pushSTACK(mtable2);
        entry = copy_perchar_table(entry);
        mtable2 = popSTACK(); mtable1 = popSTACK();
      }
      TheSvector(mtable2)->data[i] = entry;
    }
   #if (small_char_code_limit < char_code_limit)
    pushSTACK(mtable2);
    pushSTACK(mtable1);
    # Allocate a new hash table.
    pushSTACK(S(Ktest)); pushSTACK(S(eq)); funcall(L(make_hash_table),2);
    mtable1 = STACK_0;
    STACK_0 = value1;
    # stack layout: mtable2, newht.
    map_hashtable(TheSvector(mtable1)->data[small_char_code_limit],ch,entry, {
      if (simple_vector_p(entry))
        entry = copy_perchar_table(entry);
      shifthash(STACK_(0+1),ch,entry);
    });
    TheSvector(STACK_1)->data[small_char_code_limit] = STACK_0;
    skipSTACK(2);
   #endif
  }
  return popSTACK(); # to-readtable as result
}

# UP: copies a readtable
# copy_readtable(readtable)
# > readtable: Readtable
# < result: copy of readtable, semantically equivalent
# can trigger GC
local object copy_readtable (object from_readtable) {
  pushSTACK(from_readtable); # save
  pushSTACK(allocate_syntax_table()); # new empty syntaxtable
  pushSTACK(allocate_perchar_table()); # new empty macro-table
  var object to_readtable = allocate_readtable(); # new readtable
  # fill:
  TheReadtable(to_readtable)->readtable_macro_table = popSTACK();
  TheReadtable(to_readtable)->readtable_syntax_table = popSTACK();
  # and copy content:
  return copy_readtable_contents(popSTACK(),to_readtable);
}

# error at wrong value of *READTABLE*
# fehler_bad_readtable(); english: error_bad_readtable();
nonreturning_function(local, fehler_bad_readtable, (void)) {
  # correct *READTABLE*:
  var object sym = S(readtablestern); # Symbol *READTABLE*
  var object oldvalue = Symbol_value(sym);
  Symbol_value(sym) = O(standard_readtable); # := CL standard readtable
  # and report the error:
  pushSTACK(oldvalue);     # TYPE-ERROR slot DATUM
  pushSTACK(S(readtable)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(sym);
  fehler(type_error,
         GETTEXT("The value of ~ was not a readtable. It has been reset."));
}

# Macro: fetches the current readtable.
# get_readtable(readtable =);
# < readtable : the current readtable
  #if 0
    #define get_readtable(assignment)  \
      { if (!readtablep(Symbol_value(S(readtablestern)))) { fehler_bad_readtable(); }  \
        assignment Symbol_value(S(readtablestern));                                    \
      }
  #else # oder (optimized):
    #define get_readtable(assignment)  \
      { if (!(orecordp(Symbol_value(S(readtablestern)))                                             \
              && (Record_type( assignment Symbol_value(S(readtablestern)) ) == Rectype_Readtable))) \
          { fehler_bad_readtable(); }                                                               \
      }
  #endif


# =============================================================================
# Initialization
# =============================================================================

# UP: Initializes the reader.
# init_reader();
# can trigger GC
global void init_reader (void) {
 # initialize *READ-BASE*:
  define_variable(S(read_base),fixnum(10)); # *READ-BASE* := 10
 # initialize *READ-SUPPRESS*:
  define_variable(S(read_suppress),NIL);    # *READ-SUPPRESS* := NIL
 # initialize *READ-EVAL*:
  define_variable(S(read_eval),T);          # *READ-EVAL* := T
 # initialize *READTABLE*:
  {
    var object readtable = orig_readtable();
    O(standard_readtable) = readtable; # that is the standard-readtable,
    readtable = copy_readtable(readtable); # one copy of it
    define_variable(S(readtablestern),readtable);   # =: *READTABLE*
  }
 # initialize token_buff_1 and token_buff_2:
  O(token_buff_1) = NIL;
  # token_buff_1 and token_buff_2 will be initialized
  # with a semi-simple-string and a semi-simple-byte-vector
  # at the first call of get_buffers (see below).
  # Displaced-String initialisieren:
  # new array (with data-vector NIL), Displaced, rank=1
  O(displaced_string) =
    allocate_iarray(bit(arrayflags_displaced_bit)|
                    bit(arrayflags_dispoffset_bit)|
                    Atype_Char,
                    1,
                    Array_type_string);
}

LISPFUNN(defio,2)
# (SYS::%DEFIO dispatch-reader vector-index) post-initialises the I/O.
  {
    O(dispatch_reader) = STACK_1;
    O(dispatch_reader_index) = STACK_0;
    value1 = NIL; mv_count=0; skipSTACK(2);
  }


# =============================================================================
# LISP - Functions for readtables
# =============================================================================

# error, if argument is no Readtable.
# fehler_readtable(obj);  means: error_readtable(obj);
# > obj: erroneous Argument
# > subr_self: caller (a SUBR)
nonreturning_function(local, fehler_readtable, (object obj)) {
  pushSTACK(obj);          # TYPE-ERROR slot DATUM
  pushSTACK(S(readtable)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(obj);
  pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: argument ~ is not a readtable"));
}

# Verifies an object is a readtable. Error if not.
# check_readtable(obj);
# > obj: argument
# > subr_self: caller (a SUBR)
#define check_readtable(obj) \
  { if (!readtablep(obj)) fehler_readtable(obj); }

LISPFUN(copy_readtable,0,2,norest,nokey,0,NIL)
# (COPY-READTABLE [from-readtable [to-readtable]]), CLTL p. 361
  {
    var object from_readtable = STACK_1;
    if (eq(from_readtable,unbound)) {
      # no arguments are given
      get_readtable(from_readtable=); # current readtable
      value1 = copy_readtable(from_readtable); # copy
    } else {
      if (nullp(from_readtable)) {
        # instead of NIL take the standard-readtable
        from_readtable = O(standard_readtable);
      } else {
        # check from-readtable:
        check_readtable(from_readtable);
      }
      # from-readtable is OK
      var object to_readtable = STACK_0;
      if (eq(to_readtable,unbound) || nullp(to_readtable)) {
        # copy from-readtable, without to-readtable
        value1 = copy_readtable(from_readtable);
      } else {
        # check to-readtable and perform the copying:
        check_readtable(to_readtable);
        value1 = copy_readtable_contents(from_readtable,to_readtable);
      }
    }
    mv_count=1; skipSTACK(2);
  }

LISPFUN(set_syntax_from_char,2,2,norest,nokey,0,NIL)
# (SET-SYNTAX-FROM-CHAR to-char from-char [to-readtable [from-readtable]]),
# CLTL p. 361
  {
    var object to_char = STACK_3;
    var object from_char = STACK_2;
    var object to_readtable = STACK_1;
    var object from_readtable = STACK_0;
    # check to-char:
    if (!charp(to_char)) # must be a character
      fehler_char(to_char);
    # check from-char:
    if (!charp(from_char)) # must be a character
      fehler_char(from_char);
    # check to-readtable:
    if (eq(to_readtable,unbound)) {
      get_readtable(to_readtable=); # default is the current readtable
    } else {
      check_readtable(to_readtable);
    }
    # check from-readtable:
    if (eq(from_readtable,unbound) || nullp(from_readtable)) {
      from_readtable = O(standard_readtable); # default is the standard-readtable
    } else {
      check_readtable(from_readtable);
    }
    STACK_1 = to_readtable;
    STACK_0 = from_readtable;
    # now to_char, from_char, to_readtable, from_readtable are OK.
    {
      var chart to_c = char_code(to_char);
      var chart from_c = char_code(from_char);
      # copy syntaxcode:
      syntax_readtable_put(to_readtable,to_c,
                           syntax_readtable_get(from_readtable,from_c));
      # copy macro-function/vector:
      var object entry = perchar_table_get(TheReadtable(STACK_0)->readtable_macro_table,from_c);
      if (simple_vector_p(entry))
        # if entry is a simple-vector, it must be copied:
        { entry = copy_perchar_table(entry); }
      perchar_table_put(TheReadtable(STACK_1)->readtable_macro_table,to_c,entry);
    }
    value1 = T; mv_count=1; # value T
    skipSTACK(4);
  }

# UP: checks an optional readtable-argument,
# with default = current readtable.
# > STACK_0: Argument
# > subr_self: caller (a SUBR)
# < STACK: increased by 1
# < result: readtable
local object test_readtable_arg (void) {
  var object readtable = popSTACK();
  if (eq(readtable,unbound)) {
    get_readtable(readtable=); # the current readtable is default
  } else {
    check_readtable(readtable);
  }
  return readtable;
}

# UP: checks an optional readtable-argument,
# with default = current readtable, nil = standard-readtable.
# > STACK_0: Argument
# > subr_self: caller (a SUBR)
# < STACK: increased by 1
# < result: readtable
local object test_readtable_null_arg (void) {
  var object readtable = popSTACK();
  if (eq(readtable,unbound)) {
    get_readtable(readtable=); # the current readtable is default
  } else if (nullp(readtable)) {
    readtable = O(standard_readtable); # respectively the standard-readtable
  } else {
    check_readtable(readtable);
  }
  return readtable;
}

# UP: checks the next-to-last optional argument of
# SET-MACRO-CHARACTER and MAKE-DISPATCH-MACRO-CHARACTER.
# > STACK_0: non-terminating-p - Argument
# > subr_self: caller (a SUBR)
# < STACK: increased by 1
# < result: new syntaxcode
local uintB test_nontermp_arg (void) {
  var object arg = popSTACK();
  if (eq(arg,unbound) || nullp(arg))
    return syntax_t_macro; # terminating is default
  else
    return syntax_nt_macro; # non-terminating-p given and /= NIL
}

LISPFUN(set_macro_character,2,2,norest,nokey,0,NIL)
# (SET-MACRO-CHARACTER char function [non-terminating-p [readtable]]),
# CLTL p. 362
  {
    # check char:
    {
      var object ch = STACK_3;
      if (!charp(ch))
        fehler_char(ch);
    }
    # check function and convert into an object of type FUNCTION:
    {
      var object function = coerce_function(STACK_2);
      if (cclosurep(function)
          && eq(TheCclosure(function)->clos_codevec,TheCclosure(O(dispatch_reader))->clos_codevec)) {
        var object vector =
          ((Srecord)TheCclosure(function))->recdata[posfixnum_to_L(O(dispatch_reader_index))];
        if (simple_vector_p(vector)) {
          # It's a clone of #'dispatch-reader. Pull out the vector.
          function = copy_perchar_table(vector);
        }
      }
      STACK_2 = function;
    }
    var object readtable = test_readtable_arg(); # Readtable
    var uintB syntaxcode = test_nontermp_arg(); # new syntaxcode
    var chart c = char_code(STACK_1);
    STACK_1 = readtable;
    # set syntaxcode:
    syntax_table_put(TheReadtable(readtable)->readtable_syntax_table,c,syntaxcode);
    # add macrodefinition:
    perchar_table_put(TheReadtable(STACK_1)->readtable_macro_table,c,STACK_0);
    value1 = T; mv_count=1; # 1 value T
    skipSTACK(2);
  }

LISPFUN(get_macro_character,1,1,norest,nokey,0,NIL)
# (GET-MACRO-CHARACTER char [readtable]), CLTL p. 362
  {
    # check char:
    {
      var object ch = STACK_1;
      if (!charp(ch))
        fehler_char(ch);
    }
    var object readtable = test_readtable_null_arg(); # Readtable
    var object ch = popSTACK();
    var chart c = char_code(ch);
    # Test the Syntaxcode:
    var object nontermp = NIL; # non-terminating-p Flag
    switch (syntax_readtable_get(readtable,c)) {
      case syntax_nt_macro: nontermp = T;
      case syntax_t_macro: # nontermp = NIL;
        # c is a macro-character.
        {
          var object entry = perchar_table_get(TheReadtable(readtable)->readtable_macro_table,c);
          if (simple_vector_p(entry)) {
            # c is a dispatch-macro-character.
            if (nullp(O(dispatch_reader))) {
              # Shouldn't happen (bootstrapping problem).
              pushSTACK(ch);
              pushSTACK(TheSubr(subr_self)->name);
              fehler(error,GETTEXT("~: ~ is a dispatch macro character"));
            }
            # Clone #'dispatch-reader.
            pushSTACK(copy_perchar_table(entry));
            var object newclos = allocate_cclosure_copy(O(dispatch_reader));
            do_cclosure_copy(newclos,O(dispatch_reader));
            ((Srecord)TheCclosure(newclos))->recdata[posfixnum_to_L(O(dispatch_reader_index))] = popSTACK();
            value1 = newclos;
          } else {
            value1 = entry;
          }
        }
        break;
      default: # nontermp = NIL;
        value1 = NIL; break;
    }
    value2 = nontermp; mv_count=2; # nontermp as second value
  }

LISPFUN(make_dispatch_macro_character,1,2,norest,nokey,0,NIL)
# (MAKE-DISPATCH-MACRO-CHARACTER char [non-terminating-p [readtable]]),
# CLTL p. 363
  {
    var object readtable = test_readtable_arg(); # Readtable
    var uintB syntaxcode = test_nontermp_arg(); # new syntaxcode
    # check char:
    var object ch = popSTACK();
    if (!charp(ch))
      fehler_char(ch);
    var chart c = char_code(ch);
    # fetch new (empty) dispatch-macro-table:
    pushSTACK(readtable);
    pushSTACK(allocate_perchar_table()); # vector, filled with NIL
    # store everything in the readtable:
    # syntaxcode into syntax-table:
    syntax_table_put(TheReadtable(STACK_1)->readtable_syntax_table,c,syntaxcode);
    # new dispatch-macro-table into the macrodefinition table:
    perchar_table_put(TheReadtable(STACK_1)->readtable_macro_table,c,STACK_0);
    value1 = T; mv_count=1; # 1 value T
    skipSTACK(2);
  }

# UP: checks the arguments disp-char and sub-char.
# > STACK: STACK_1 = disp-char, STACK_0 = sub-char
# > readtable: Readtable
# > subr_self: caller (a SUBR)
# < result: the dispatch-macro-table for disp-char,
#             nullobj if sub-char is a digit.
local object test_disp_sub_char (object readtable) {
  var object sub_ch = STACK_0; # sub-char
  var object disp_ch = STACK_1; # disp-char
  if (!charp(disp_ch)) # disp-char must be a character
    fehler_char(disp_ch);
  if (!charp(sub_ch)) # sub-char must be a character
    fehler_char(sub_ch);
  var chart disp_c = char_code(disp_ch);
  var object entry =
    perchar_table_get(TheReadtable(readtable)->readtable_macro_table,disp_c);
  if (!simple_vector_p(entry)) {
    pushSTACK(disp_ch);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~: ~ is not a dispatch macro character"));
  }
  # disp-char is a dispatching-macro-character, entry is the vector.
  var cint sub_c = as_cint(up_case(char_code(sub_ch))); # convert sub-char into upper case
  if ((sub_c >= '0') && (sub_c <= '9')) # digit
    return nullobj;
  else # valid sub-char
    return entry;
}

LISPFUN(set_dispatch_macro_character,3,1,norest,nokey,0,NIL)
# (SET-DISPATCH-MACRO-CHARACTER disp-char sub-char function [readtable]),
# CLTL p. 364
  {
    # check function and convert it into an object of Type FUNCTION:
    STACK_1 = coerce_function(STACK_1);
    subr_self = L(set_dispatch_macro_character);
    var object readtable = test_readtable_arg(); # Readtable
    var object function = popSTACK(); # function
    var object dm_table = test_disp_sub_char(readtable);
    if (eq(dm_table,nullobj)) {
      # STACK_0 = sub-char, TYPE-ERROR slot DATUM
      pushSTACK(O(type_not_digit)); # TYPE-ERROR slot EXPECTED-TYPE
      pushSTACK(STACK_1);
      pushSTACK(TheSubr(subr_self)->name);
      fehler(type_error,GETTEXT("~: digit $ not allowed as sub-char"));
    } else {
      perchar_table_put(dm_table,up_case(char_code(STACK_0)),function); # add function to the dispatch-macro-table
      value1 = T; mv_count=1; skipSTACK(2); # 1st value  T
    }
  }

LISPFUN(get_dispatch_macro_character,2,1,norest,nokey,0,NIL)
# (GET-DISPATCH-MACRO-CHARACTER disp-char sub-char [readtable]), CLTL p. 364
  {
    var object readtable = test_readtable_null_arg(); # Readtable
    var object dm_table = test_disp_sub_char(readtable);
    value1 = (eq(dm_table,nullobj) ? NIL : perchar_table_get(dm_table,up_case(char_code(STACK_0)))); # NIL or Function as value
    mv_count=1; skipSTACK(2);
  }

#define RTCase(rt) ((uintW)posfixnum_to_L(TheReadtable(rt)->readtable_case))

LISPFUNN(readtable_case,1)
# (READTABLE-CASE readtable), CLTL2 S. 549
  {
    var object readtable = popSTACK(); # Readtable
    check_readtable(readtable);
    value1 = (&O(rtcase_0))[RTCase(readtable)];
    mv_count=1;
  }

LISPFUNN(set_readtable_case,2)
# (SYSTEM::SET-READTABLE-CASE readtable value), CLTL2 p. 549
  {
    var object value = popSTACK();
    var object readtable = popSTACK(); # Readtable
    check_readtable(readtable);
    # convert symbol value into an index by searching in table O(rtcase..):
    var const object* ptr = &O(rtcase_0);
    var object rtcase = Fixnum_0;
    var uintC count;
    dotimesC(count,4, {
      if (eq(*ptr,value))
        goto found;
      ptr++; rtcase = fixnum_inc(rtcase,1);
    });
    # invalid value
    pushSTACK(value);          # TYPE-ERROR slot DATUM
    pushSTACK(O(type_rtcase)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(O(rtcase_3)); pushSTACK(O(rtcase_2)); pushSTACK(O(rtcase_1)); pushSTACK(O(rtcase_0));
    pushSTACK(value);
    pushSTACK(S(set_readtable_case));
    fehler(type_error,GETTEXT("~: new value ~ should be ~, ~, ~ or ~."));
   found: # found in  table
    TheReadtable(readtable)->readtable_case = rtcase;
    value1 = value; mv_count=1;
  }

# =============================================================================
# some auxiliary routines and macros for READ and PRINT
# =============================================================================

# Tests the dynamic value of a symbol being /=NIL
# < true, if /= NIL
# #define test_value(sym)  (!nullp(Symbol_value(sym)))
#define test_value(sym)  (!eq(NIL,Symbol_value(sym)))

# UP: fetches the value of a symbol. must be fixnum >=2, <=36.
# get_base(symbol)
# > symbol: Symbol
# < result: value of the Symbols, >=2, <=36.
local uintL get_base (object symbol) {
  var object value = Symbol_value(symbol);
  var uintL wert;
  if (posfixnump(value) &&
      (wert = posfixnum_to_L(value), ((wert >= 2) && (wert <= 36)))) {
    return wert;
  } else {
    Symbol_value(symbol) = fixnum(10);
    pushSTACK(value);         # TYPE-ERROR slot DATUM
    pushSTACK(O(type_radix)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(value);
    pushSTACK(symbol);
    fehler(type_error,
           GETTEXT("The value of ~ should be an integer between 2 and 36, not ~." NLstring
                   "It has been reset to 10."));
  }
}

# UP: fetches the value of *PRINT-BASE*
# get_print_base()
# < uintL result: >=2, <=36
#define get_print_base()  \
    (test_value(S(print_readably)) ? 10 : get_base(S(print_base)))

# UP: fetches the value of *READ-BASE*
# get_read_base()
# < uintL ergebnis: >=2, <=36
#define get_read_base()  get_base(S(read_base))


# =============================================================================
#                              R E A D
# =============================================================================

# Characters are read one by one.
# Their syntax codes are determined by use the readtable, cf. CLTL table 22-1.
# Syntax code 'constituent' starts a new (extended) token.
# For every character in the token, its attribute a_xxxx is looked up by use
# of the attribute table, cf. CLTL table 22-3.
# O(token_buff_1) is a semi-simple-string, which contains the characters of
# the currently read extended-token.
# O(token_buff_2) is a semi-simple-byte-vektor, which contains the attributes
# of the currently read extended-token.
# Both have the same length (in characters respectively bytes).

# Special objects, that can be returned by READ:
#   eof_value: special object, that indicates EOF
#   dot_value: auxiliary value for the detection of single dots

# ------------------------ READ on character-level ---------------------------

# error, if read object is not a character:
# fehler_charread(ch,&stream);  english: error_charread(ch,&stream);
nonreturning_function(local, fehler_charread, (object ch, const object* stream_)) {
  pushSTACK(*stream_); # STREAM-ERROR slot STREAM
  pushSTACK(ch); # Character
  pushSTACK(*stream_); # Stream
  pushSTACK(S(read));
  fehler(stream_error,
         GETTEXT("~ from ~: character read should be a character: ~"));
}

# UP: Reads a character and calculates its syntaxcode.
# read_char_syntax(ch=,scode=,&stream);
# > stream: Stream
# < stream: Stream
# < object ch: Character or eof_value
# < uintWL scode: Syntaxcode (from the current readtable) respectively syntax_eof
# can trigger GC
  #define read_char_syntax(ch_assignment,scode_assignment,stream_)  \
    { var object ch0 = read_char(stream_); # read character            \
      ch_assignment ch0;                                               \
      if (eq(ch0,eof_value)) # EOF ?                                   \
        { scode_assignment syntax_eof; }                               \
        else                                                           \
        { # check for character:                                       \
          if (!charp(ch0)) { fehler_charread(ch0,stream_); }           \
         {var object readtable;                                        \
          get_readtable(readtable = );                                 \
          scode_assignment # fetch syntaxcode from table               \
            syntax_readtable_get(readtable,char_code(ch0));            \
        }}                                                             \
    }

# error-message at EOF outside of objects
# fehler_eof_aussen(&stream); english: error_eof_outside(&stream);
# > stream: Stream
nonreturning_function(local, fehler_eof_aussen, (const object* stream_)) {
  pushSTACK(*stream_); # STREAM-ERROR slot STREAM
  pushSTACK(*stream_); # Stream
  pushSTACK(S(read));
  fehler(end_of_file,GETTEXT("~: input stream ~ has reached its end"));
}

# error-message at EOF inside of objects
# fehler_eof_innen(&stream);  english: error_eof_inside(&stream)
# > stream: Stream
nonreturning_function(local, fehler_eof_innen, (const object* stream_)) {
  pushSTACK(*stream_); # STREAM-ERROR slot STREAM
  if (posfixnump(Symbol_value(S(read_line_number)))) { # check SYS::*READ-LINE-NUMBER*
    pushSTACK(Symbol_value(S(read_line_number))); # line-number
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(end_of_file,
           GETTEXT("~: input stream ~ ends within an object. Last opening parenthesis probably in line ~."));
  } else {
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(end_of_file,GETTEXT("~: input stream ~ ends within an object"));
  }
}

# error-message at EOF, according to *READ-RECURSIVE-P*
# fehler_eof(&stream); english: error_eof(&stream)
# > stream: Stream
nonreturning_function(local, fehler_eof, (const object* stream_)) {
  if (test_value(S(read_recursive_p))) # *READ-RECURSIVE-P* /= NIL ?
    fehler_eof_innen(stream_);
  else
    fehler_eof_aussen(stream_);
}

# UP: read up to the next non-whitespace-character, without consuming it
# At EOF --> Error.
# wpeek_char_syntax(ch=,scode=,&stream);
# > stream: Stream
# < stream: Stream
# < object ch: next character
# < uintWL scode: its syntaxcode
# can trigger GC
#define wpeek_char_syntax(ch_assignment,scode_assignment,stream_)  \
    { loop                                                                 \
        { var object ch0 = read_char(stream_); # read Character            \
          if (eq(ch0,eof_value)) { fehler_eof(stream_); } # EOF -> Error   \
          # check for Character:                                           \
          if (!charp(ch0)) { fehler_charread(ch0,stream_); }               \
          {var object readtable;                                           \
           get_readtable(readtable = );                                    \
           if (!((scode_assignment # fetch Syntaxcode from table           \
                    syntax_readtable_get(readtable,char_code(ch0)))        \
                 == syntax_whitespace))                                    \
             # no Whitespace -> push back last read character              \
             { unread_char(stream_,ch0); ch_assignment ch0; break; }       \
        } }                                                                \
    }

# UP: read up to the next non-whitespace-character, without consuming it.
# wpeek_char_eof(&stream)
# > stream: Stream
# < stream: Stream
# < result: next character or eof_value
# can trigger GC
local object wpeek_char_eof (const object* stream_) {
  loop {
    var object ch = read_char(stream_); # read character
    if (eq(ch,eof_value)) # EOF ?
      return ch;
    # check for Character:
    if (!charp(ch))
      fehler_charread(ch,stream_);
    var object readtable;
    get_readtable(readtable = );
    if (!(( # fetch Syntaxcode from table
           syntax_readtable_get(readtable,char_code(ch)))
          == syntax_whitespace)) {
      # no Whitespace -> push back last read character
      unread_char(stream_,ch); return ch;
    }
  }
}

# ------------------------ READ at token-level -------------------------------

# read_token and test_potential_number_syntax, test_number_syntax need
# the attributes according to CLTL table 22-3.
# During test_potential_number_syntax attributes are transformed,
# a_digit partially into a_alpha or a_letter or a_expo_m.

# meaning of the entries in attribute_table:
  #define a_illg          0   # illegal constituent
  #define a_pack_m        1   # ':' = Package-marker
  #define a_alpha         2   # character without special property (alphabetic)
  #define a_escaped       3   # character without special property, not subject to case conversion
  #define a_ratio         4   # '/'
  #define a_dot           5   # '.'
  #define a_plus          6   # '+'
  #define a_minus         7   # '-'
  #define a_extens        8   # '_^' extension characters
  #define a_digit         9   # '0123456789'
  #define a_letterdigit  10   # 'A'-'Z','a'-'z' less than base, not 'esfdlESFDL'
  #define a_expodigit    11   # 'esfdlESFDL' less than base
  #define a_letter       12   # 'A'-'Z','a'-'z', not 'esfdlESFDL'
  #define a_expo_m       13   # 'esfdlESFDL'
  #    >= a_letter            #  'A'-'Z','a'-'z'
  #    >= a_digit             # '0123456789','A'-'Z','a'-'z'
  #    >= a_ratio             # what a potential number must consist of

# attribute-table for constituents, first interpretation:
# note: first, 0-9,A-Z,a-z are interpreted as a_digit or a_expo_m,
# then (if no integer can be deduced out of token), a_digit
# is interpreted as a_alpha (alphabetic) above of *READ-BASE*.
  local const uintB attribute_table[small_char_code_limit] = {
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,   # chr(0) upto chr(7)
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,   # chr(8) upto chr(15)
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,   # chr(16) upto chr(23)
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,   # chr(24) upto chr(31)
    a_illg,  a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,  # ' !"#$%&''
    a_alpha, a_alpha, a_alpha, a_plus,  a_alpha, a_minus, a_dot,   a_ratio,  # '()*+,-./'
    a_digit, a_digit, a_digit, a_digit, a_digit, a_digit, a_digit, a_digit,  # '01234567'
    a_digit, a_digit, a_pack_m,a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,  # '89:;<=>?'
    a_alpha, a_letter,a_letter,a_letter,a_expo_m,a_expo_m,a_expo_m,a_letter, # '@ABCDEFG'
    a_letter,a_letter,a_letter,a_letter,a_expo_m,a_letter,a_letter,a_letter, # 'HIJKLMNO'
    a_letter,a_letter,a_letter,a_expo_m,a_letter,a_letter,a_letter,a_letter, # 'PQRSTUVW'
    a_letter,a_letter,a_letter,a_alpha, a_alpha, a_alpha, a_extens,a_extens, # 'XYZ[\]^_'
    a_alpha, a_letter,a_letter,a_letter,a_expo_m,a_expo_m,a_expo_m,a_letter, # '`abcdefg'
    a_letter,a_letter,a_letter,a_letter,a_expo_m,a_letter,a_letter,a_letter, # 'hijklmno'
    a_letter,a_letter,a_letter,a_expo_m,a_letter,a_letter,a_letter,a_letter, # 'pqrstuvw'
    a_letter,a_letter,a_letter,a_alpha, a_alpha, a_alpha, a_alpha,           # 'xyz{|}~'
    #if defined(UNICODE) || defined(ISOLATIN_CHS) || defined(HPROMAN8_CHS)
                                                                   a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    #elif defined(IBMPC_CHS)
                                                                   a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    #elif defined(NEXTSTEP_CHS)
                                                                   a_illg,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha, a_alpha,
    #else # defined(ASCII_CHS) && !defined(UNICODE)
                                                                   a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,  a_illg,
    #endif
    };

# Returns the attribute code for a character code.
# attribute_of(c)
# > chart c: character code
# < uintB result: attribute code
  #if (small_char_code_limit < char_code_limit) # i.e. defined(UNICODE)
    #define attribute_of(c)                            \
      (uintB)(as_cint(c) < small_char_code_limit       \
              ? attribute_table[as_cint(c)]            \
              : (graphic_char_p(c) ? a_alpha : a_illg))
  #else
    #define attribute_of(c)  attribute_table[as_cint(c)]
  #endif

# Flag. indicates, if a single-escape- or multiple-escape-character
# occurred in the last read token:
local bool token_escape_flag;

# UP: delivers two buffers.
# if two buffers are available in the reservoir O(token_buff_1), O(token_buff_2),
# they are extracted. Otherwise new ones are allocated.
# If the buffers are not needed anymore, they can be written back to
# O(token_buff_1) and O(token_buff_2).
# < STACK_1: a Semi-Simple String with Fill-Pointer 0
# < STACK_0: a Semi-Simple Byte-Vector with Fill-Pointer 0
# < STACK: decreased by 2
# can trigger GC
local void get_buffers (void) {
  # Mechanism:
  # O(token_buff_1) and O(token_buff_2) hold a Semi-Simple-String
  # and a Semi-Simple-Byte-Vector, which are extracted if necessary (and marked
  # with O(token_buff_1) := NIL as extracted)
  # After use, they can be stored back again. Reentrant!
  var object buff_1 = O(token_buff_1);
  if (!nullp(buff_1)) {
    # extract buffer and empty:
    TheIarray(buff_1)->dims[1] = 0; # Fill-Pointer:=0
    pushSTACK(buff_1); # 1. buffer finished
    var object buff_2 = O(token_buff_2);
    TheIarray(buff_2)->dims[1] = 0; # Fill-Pointer:=0
    pushSTACK(buff_2); # 2. buffer finished
    O(token_buff_1) = NIL; # mark buffer as extracted
  } else {
    # buffers are extracted. New ones must be allocated:
    pushSTACK(make_ssstring(50)); # new Semi-Simple-String with Fill-Pointer=0
    pushSTACK(make_ssbvector(50)); # new Semi-Simple-Byte-Vector with Fill-Pointer=0
  }
}

# UP: Reads an Extended Token.
# read_token(&stream);
# > stream: Stream
# < stream: Stream
# < O(token_buff_1): read Characters
# < O(token_buff_2): their Attributcodes
# < token_escape_flag: Escape-Character-Flag
# can trigger GC
local void read_token (const object* stream_);

# UP: reads an extended token, first character has already been read.
# read_token_1(&stream,ch,scode);
# > stream: Stream
# > ch, scode: first character and its syntaxcode
# < stream: Stream
# < O(token_buff_1): read characters
# < O(token_buff_2): their attributcodes
# < token_escape_flag: Escape-character-Flag
# can trigger GC
local void read_token_1 (const object* stream_, object ch, uintWL scode);

local void read_token (const object* stream_) {
  # read first character:
  var object ch;
  var uintWL scode;
  read_char_syntax(ch = ,scode = ,stream_);
  # build up token:
  read_token_1(stream_,ch,scode);
}

local void read_token_1 (const object* stream_, object ch, uintWL scode) {
  if (terminal_stream_p(*stream_))
    dynamic_bind(S(terminal_read_open_object),S(symbol));
  # fetch empty Token-Buffers, upon STACK:
  get_buffers(); # (don't need to save ch)
  # the two buffers lie up th the end of read_token_1 in the Stack.
  # (thus read_char can call read recursively...)
  # Afterwards (during test_potential_number_syntax, test_number_syntax,
  # test_dots, read_internal up to the end of read_internal)
  # the buffers lie in O(token_buff_1) and O(token_buff_2). After the return of
  # read_internal their content is useless, and they can be used for further
  # read-operations.
  var bool multiple_escape_flag = false;
  var bool escape_flag = false;
  goto char_read;
  loop {
    # Here the token in STACK_1 (Semi-Simple-String for characters)
    # and STACK_0 (Semi-Simple-Byte-Vector for attributecodes) is constructed.
    # Multiple-Escape-Flag indicates, if we are situated between |...|.
    # Escape-Flag indicates, if a Escape-Character has appeared.
    read_char_syntax(ch = ,scode = ,stream_); # read next character
  char_read:
    switch(scode) {
      case syntax_illegal: # illegal -> issue Error:
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(ch); # character
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,GETTEXT("~ from ~: illegal character ~"));
        break;
      case syntax_single_esc: # Single-Escape-Character ->
        # read next character and take over unchanged
        escape_flag = true;
        read_char_syntax(ch = ,scode = ,stream_); # read next character
        if (scode==syntax_eof) { # reached EOF?
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(*stream_);
          pushSTACK(S(read));
          fehler(end_of_file,
                 GETTEXT("~: input stream ~ ends within a token after single escape character"));
        }
    escape:
        # past Escape-character:
        # take over character into token without change
        ssstring_push_extend(STACK_1,char_code(ch));
        ssbvector_push_extend(STACK_0,a_escaped);
        break;
      case syntax_multi_esc: # Multiple-Escape-character
        multiple_escape_flag = !multiple_escape_flag;
        escape_flag = true;
        break;
      case syntax_constituent:
      case syntax_nt_macro: # normal constituent
        if (multiple_escape_flag) # between Multiple-Escape-characters?
          goto escape; # yes -> take over character without change
        # take over into token (capital-conversion takes place later):
        {
          var chart c = char_code(ch);
          ssstring_push_extend(STACK_1,c);
          ssbvector_push_extend(STACK_0,attribute_of(c));
        }
        break;
      case syntax_whitespace:
      case syntax_t_macro: # whitespace or terminating macro ->
        # Token ends before this Character.
        if (multiple_escape_flag) # between multiple-escape-characters?
          goto escape; # yes -> take over character without change
        # Token is finished.
        # Push back character to the Stream,
        # if ( it is no Whitespace ) or
        # ( it is a  Whitespace and also  *READ-PRESERVE-WHITESPACE* /= NIL holds true).
        if ((!(scode == syntax_whitespace))
            || test_value(S(read_preserve_whitespace)))
          unread_char(stream_,ch);
        goto ende;
      case syntax_eof: # EOF reached.
        if (multiple_escape_flag) { # between multiple-escape-character?
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(*stream_);
          pushSTACK(S(read));
          fehler(end_of_file,
                 GETTEXT("~: input stream ~ ends within a token after multiple escape character"));
        }
        # no -> token is finished normally
        goto ende;
      default: NOTREACHED;
    }
  }
 ende:
  # now token is finished, multiple_escape_flag = false.
  token_escape_flag = escape_flag; # store Escape-Flag
  O(token_buff_2) = popSTACK(); # Attributecode-Buffer
  O(token_buff_1) = popSTACK(); # Character-Buffer
  if (terminal_stream_p(*stream_))
    dynamic_unbind(); # S(terminal_read_open_object)
}

# --------------- READ between token-level and objekt-level ------------------

# UP: checks, if the token-buffer contains a potential-number, and
# transforms Attributecodes as preparation on read-routines for digits.
# test_potential_number_syntax(&base,&token_info_t);
# > O(token_buff_1): read characters
# > O(token_buff_2): their attributecodes
# > base: base of number-system (value of *READ-BASE* or *PRINT-BASE*)
# < base: base of number-system (= 10 or old base)
# conversion takes place within O(token_buff_2):
#   if potential number:
#     >=a_letter below the base of number-system -> a_letterdigit, a_expodigit
#   if not potential number:
#     distinction between [a_pack_m | a_dot | others] is preserved.
# < result: true, if potential number
#             (and then token_info_t is filled with {charptr, attrptr, len} )
typedef struct {
  chart* charptr;
  uintB* attrptr;
  uintL len;
} token_info_t;
local bool test_potential_number_syntax (uintWL* base_, token_info_t* info) {
  # A token is a potential number, if (CLTL, p. 341)
  # - it consists exclusively of digits, '+','-','/','^','_','.' and
  #   Number-Markers. The base for the digits ist context-sensitive.
  #   It is always 10, if a dot '.' is in the token.
  #   A Number-Marker is a letter, that is no digit and
  #   is not placed adjacent to another such letter.
  # - it contains at least one digit,
  # - it starts with a digit, '+','-','.','^' or '_',
  # - it does not end with '+' or '-'.
  # Verification:
  # 1. Search for a dot. if ther is one ===> Base:=10.
  # 2. Test, if only chars >=a_ratio are in the token. No -> no potential number.
  # 3. Every char that is >=a_letter (also 'A'-'Z','a'-'z')  and has a value < base,
  #    will be converted to a_letterdigit or a_expodigit.
  # (Now a_digit,a_letterdigit,a_expodigit is interpreted as "digit" and
  #  >=a_letter as "letter".)
  # 4. Test, if an a_digit is in the token. No -> no potential number.
  # (No the length is >0.)
  # 5. Test, if adjacent >=a_letter are in the token.
  #    Yes -> no potential number.
  # 6. Test, if first character attribute is  >=a_dot and <=a_digit.
  #    No -> no potential number.
  # 7. Test, if last character attribute is =a_plus or =a_minus.
  #    Yes -> no potential number.
  # 8. Otherwise it is a potential number.
  var chart* charptr0; # Pointer to the characters
  var uintB* attrptr0; # Pointer to the attributes
  var uintL len; # Length of token
  # initialize:
  {
    var object buff = O(token_buff_1); # Semi-Simple String
    len = TheIarray(buff)->dims[1]; # length = Fill-Pointer
    charptr0 = &TheSstring(TheIarray(buff)->data)->data[0]; # characters from this point on
    buff = O(token_buff_2); # Semi-Simple Byte-Vektor
    attrptr0 = &TheSbvector(TheIarray(buff)->data)->data[0]; # attributecodes from this point on
  }
  # 1. search, if there is a dot:
  {
    if (len > 0) {
      var uintB* attrptr = attrptr0;
      var uintL count;
      dotimespL(count,len, {
        if (*attrptr++ == a_dot) goto dot;
      });
    }
    # no dot -> leave base unchanged
    goto no_dot;
    # dot -> base := 10
  dot: *base_ = 10;
  no_dot: ;
  }
  # 2. Test, if only attributecodes >=a_ratio occur:
  if (len > 0) {
    var uintB* attrptr = attrptr0;
    var uintL count;
    dotimespL(count,len, {
      if (!(*attrptr++ >= a_ratio))
        return false; # no -> no potential number
    });
  }
  # 3. translate everything  >=a_letter with value < base into a_letterdigit, a_expodigit:
  if (len > 0) {
    var uintB* attrptr = attrptr0;
    var chart* charptr = charptr0;
    var uintL count;
    dotimespL(count,len, {
      if (*attrptr >= a_letter) { # Attributecode >= a_letter
        var cint c = as_cint(*charptr); # character, must be 'A'-'Z','a'-'Z'
        if (c >= 'a') { c -= 'a'-'A'; }
        if ((c - 'A') + 10 < *base_) # value < base ?
          *attrptr -= 2; # a_letter -> a_letterdigit, a_expo_m -> a_expodigit
      }
      attrptr++; charptr++;
    });
  }
  # 4. Test, if an a_*digit occurs:
  {
    if (len > 0) {
      var uintB* attrptr = attrptr0;
      var uintL count;
      dotimespL(count,len, {
        var uintB attr = *attrptr++;
        if (attr >= a_digit && attr <= a_expodigit)
            goto digit_ok;
      });
    }
    return false; # no potential number
  digit_ok: ;
  }
  # length len>0.
  # 5. Test, if two attributecodes >= a_letter follow adjacently:
  if (len > 1) {
    var uintB* attrptr = attrptr0;
    var uintL count;
    dotimespL(count,len-1, {
      if (*attrptr++ >= a_letter)
        if (*attrptr >= a_letter)
          return false;
    });
  }
  # 6. Test, if first attributecode is >=a_dot and <=a_*digit:
  {
    var uintB attr = attrptr0[0];
    if (!((attr >= a_dot) && (attr <= a_expodigit)))
      return false;
  }
  # 7. Test, if last attributecode is  =a_plus or =a_minus:
  {
    var uintB attr = attrptr0[len-1];
    if ((attr == a_plus) || (attr == a_minus))
      return false;
  }
  # 8. It is a potential number.
  info->charptr = charptr0; info->attrptr = attrptr0; info->len = len;
  return true;
}

# UP: verifies if the token-buffer contains a number (syntax according to
# CLTL Table 22-2), and provides the parameters which are necessary for
# the translation into a number, where necessary.
# test_number_syntax(&base,&string,&info)
# > O(token_buff_1): read characters
# > O(token_buff_2): their attributecodes
# > token_escape_flag: Escape-Character-Flag
# > base: number-system-base (value of *READ-BASE* or *PRINT-BASE*)
# < base: number-system-base
# < string: Normal-Simple-String with the characters
# < info.sign: sign (/=0 if negative)
# < result: number-type
#     0 : no number (then also base,string,info are meaningless)
#     1 : Integer
#         < index1: Index of the first digit
#         < index2: Index after the last digit
#         (that means index2-index1 digits, incl. a possible decimal
#         dot at the end)
#     2 : Rational
#         < index1: Index of the first digit
#         < index3: Index of '/'
#         < index2: Index after the last digit
#         (that means index3-index1 numerator-digits and
#          index2-index3-1 denominator-digits)
#     3 : Float
#         < index1: Index of the start of mantissa (excl. sign)
#         < index4: Index after the end of mantissa
#         < index2: Index at the  end of the characters
#         < index3: Index after the decimal dot (=index4 if there is no dot)
#         (implies: mantissa with index4-index1 characters: digits and at
#          most one '.')
#         (implies: index4-index3 digits after the dot)
#         (implies: if index4<index2: index4 = Index of the exponent-marker,
#               index4+1 = index of exponenten-sign or of the first
#               exponenten-digit)
typedef struct {
  signean sign;
  uintL index1;
  uintL index2;
  uintL index3;
  uintL index4;
} zahl_info_t;
local uintWL test_number_syntax (uintWL* base_, object* string_,
                                 zahl_info_t* info) {
  # Method:
  # 1. test for potential number.
  #    Then there exist only Attributcodes >= a_ratio,
  #    and with a_dot, the base=10.
  # 2. read sign { a_plus | a_minus | } and store.
  # 3. try to read token as a rational number:
  #    test, if syntax
  #    { a_plus | a_minus | }                               # already read
  #    { a_digit < base }+ { a_ratio { a_digit < base }+ | }
  #    is matching.
  # 4. set base:=10.
  # 5. try to interprete the token as a  floating-point-number or decimal-integer:
  #    Test, if the syntax
  #    { a_plus | a_minus | }                               # already read
  #    { a_digit }* { a_dot { a_digit }* | }
  #    { a_expo_m { a_plus | a_minus | } { a_digit }+ | }
  #    is matching.
  #    if there is an exponent, there must be digits before or after the dot;
  #      it is a float, Type will be determined by exponent-marker
  #      (e,E deliver the value of the variable *read-default-float-format* as type).
  #    if there is no exponent:
  #      if there is no dot, it is not a number (should have been delivered at
  #        step 3, but base obviously did not fit).
  #      if decimal dot exists:
  #        if there are digits after the dot, it is a float (type is
  #          denoted by the variable *read-default-float-format*).
  #        if there are no digits after the dot:
  #          if there were digits before the dot --> decimal-integer.
  #          otherwise no number.
  var chart* charptr0; # Pointer to the characters
  var uintB* attrptr0; # Pointer to the attributes
  var uintL len; # length of the token
  # 1. test for potential number:
  {
    if (token_escape_flag) # token with escape-character ->
      return 0; # no potential number -> no number
    # escape-flag deleted.
    var token_info_t info;
    if (!test_potential_number_syntax(base_,&info)) # potential number ?
      return 0; # no -> no number
    # yes -> read outputparameter returned by test_potential_number_syntax:
    charptr0 = info.charptr;
    attrptr0 = info.attrptr;
    len = info.len;
  }
  *string_ = TheIarray(O(token_buff_1))->data; # Normal-Simple-String
  var uintL index0 = 0;
  # read 2. sign and store:
  info->sign = 0; # sign:=positiv
  switch (*attrptr0) {
    case a_minus: info->sign = -1; # sign:=negativ
    case a_plus: # read over sign:
      charptr0++; attrptr0++; index0++;
    default:
      break;
  }
  info->index1 = index0; # Startindex
  info->index2 = len; # Endindex
  # info->sign, info->index1 and info->index2 finished.
  # charptr0 and attrptr0 and index0 from now on unchanged.
  var uintB flags = 0; # delete all flags
  # 3. Rational number
  {
    var chart* charptr = charptr0;
    var uintB* attrptr = attrptr0;
    var uintL index = index0;
    # flags & bit(0)  indicates, if an a_digit < base
    #                 has already arrived.
    # flags & bit(1)  indicates, if an a_ratio has already arrived
    #                 (and then info->index3 is its position)
    loop {
      # next character
      if (index>=len)
        break;
      var uintB attr = *attrptr++; # its attributcode
      if (attr>=a_digit && attr<=a_expodigit) {
        var cint c = as_cint(*charptr++); # character (Digit, namely '0'-'9','A'-'Z','a'-'z')
        # determine value (== wert):
        var uintB wert = (c<'A' ? c-'0' : c<'a' ? c-'A'+10 : c-'a'+10);
        if (wert >= *base_) # Digit with value >=base ?
          goto schritt4; # yes -> no rational number
        # Digit with value <base
        flags |= bit(0); # set bit 0
        index++;
      } else if (attr==a_ratio) {
        if (flags & bit(1)) # not the only '/' ?
          goto schritt4; # yes -> not a rational number
        flags |= bit(1); # first '/'
        if (!(flags & bit(0))) # no digits before the fraction bar?
          goto schritt4; # yes -> not a rational number
        flags &= ~bit(0); # delete bit 0, new block starts
        info->index3 = index; # store index of '/'
        charptr++; index++;
      } else
        # Attributecode /= a_*digit, a_ratio -> not a rational number
        goto schritt4;
    }
    # Token finished
    if (!(flags & bit(0))) # no digits in the last block ?
      goto schritt4; # yes -> not a rational number
    # rational number
    if (!(flags & bit(1))) # a_ratio?
      # no -> it's an integer, info is ready.
      return 1;
    else
      # yes -> it's a fraction, info is ready.
      return 2;
  }
 schritt4:
  # 4. base:=10
  *base_ = 10;
  # 5. Floating-Point-Number or decimal-integer
  {
    var uintB* attrptr = attrptr0;
    var uintL index = index0;
    # flags & bit(2)  indicates, if an a_dot has arrived already
    #                 (then info->index3 is the subsequent position)
    # flags & bit(3)  zeigt an, ob im letzten Ziffernblock bereits ein
    #                 a_digit angetroffen wurde.
    # flags & bit(4)  indicates, if there was an a_dot with digits in front
    #                 of it
    loop {
      # next character
      if (index>=len)
        break;
      var uintB attr = *attrptr++; # its attributecode
      if (attr==a_digit) {
        # Digit ('0'-'9')
        flags |= bit(3); index++;
      } else if (attr==a_dot) {
        if (flags & bit(2)) # not the only '.' ?
          return 0; # yes -> not a number
        flags |= bit(2); # first '.'
        if (flags & bit(3))
          flags |= bit(4); # maybe with digits in front of the dot
        flags &= ~bit(3); # reset flag
        index++;
        info->index3 = index; # store index after the '.'
      } else if (attr==a_expo_m || attr==a_expodigit)
        goto expo; # treat exponent
      else
        return 0; # not a float, thus not a number
    }
    # token finished, no exponent
    if (!(flags & bit(2))) # only decimal digits without '.' ?
      return 0; # yes -> not a number
    info->index4 = index;
    if (flags & bit(3)) # with digits behind the dot?
      return 3; # yes -> Float, info ready.
    # no.
    if (!(flags & bit(4))) # also without digits in front of dot?
      return 0; # yes -> only '.' -> no number
    # only digits in front of '.',none behind it -> decimal-integer.
    # Don't need to cut '.' away at the end (will be omitted).
    return 1;
  expo:
    # reached exponent.
    info->index4 = index;
    index++; # count exponent-marker
    if (!(flags & bit(2)))
      info->index3 = info->index4; # default for index3
    if (!(flags & (bit(3)|bit(4)))) # were there digits in front of
                                    # or behind the dot?
      return 0; # no -> not a number
    # continue with exponent:
    # flags & bit(5)  indicates, if there has already been
    # an exponent-digit.
    if (index>=len)
      return 0; # string finished -> not a number
    switch (*attrptr) {
      case a_plus:
      case a_minus:
        attrptr++; index++; # skip sign of the exponent
      default:
            break;
    }
    loop {
      # next character in exponent:
      if (index>=len)
        break;
      # from now on only digits are allowed:
      if (!(*attrptr++ == a_digit))
        return 0;
      flags |= bit(5);
      index++;
    }
    # Token is finished after exponent
    if (!(flags & bit(5))) # no digit in exponent?
      return 0; # yes -> not a number
    return 3; # Float, info ready.
  }
}

# Handler: Signals a READER-ERROR with the same error message as the current
# condition.
local void signal_reader_error (void* sp, object* frame, object label,
                                object condition) {
  # (SYS::ERROR-OF-TYPE 'READER-ERROR "~A" condition)
  pushSTACK(S(reader_error)); pushSTACK(O(tildeA)); pushSTACK(condition);
  funcall(L(error_of_type),3);
}

# UP: checks, if a token consists only of Dots.
# test_dots()
# > O(token_buff_1): read characters
# > O(token_buff_2): their attributcodes
# < result: true, if token is empty or consists only of dots
local bool test_dots (void) {
  # search for attributecode /= a_dot:
  var object bvec = O(token_buff_2); # Semi-Simple-Byte-Vector
  var uintL len = TheIarray(bvec)->dims[1]; # Fill-Pointer
  if (len > 0) {
    var uintB* attrptr = &TheSbvector(TheIarray(bvec)->data)->data[0];
    var uintL count;
    dotimespL(count,len, {
      if (!(*attrptr++ == a_dot)) # Attributcode /= a_dot found?
        return false; # yes -> ready, false
    });
  }
  # only dots.
  return true;
}

# UP: converts a number-token into capitals.
# upcase_token();
# > O(token_buff_1): read characters
# > O(token_buff_2): their attributecodes
local void upcase_token (void) {
  var object string = O(token_buff_1); # Semi-Simple-String
  var uintL len = TheIarray(string)->dims[1]; # Fill-Pointer
  if (len > 0) {
    var chart* charptr = &TheSstring(TheIarray(string)->data)->data[0];
    dotimespL(len,len, { *charptr = up_case(*charptr); charptr++; } );
  }
}

# UP: converts a piece of the read Tokens into upper or lower case letters.
# case_convert_token(start_index,end_index,direction);
# > O(token_buff_1): read characters
# > O(token_buff_2): their attributecodes
# > uintL start_index: startindex of range to be converted
# > uintL end_index: endindex of the range to be converted
# > uintW direction: direction of the conversion
local void case_convert_token (uintL start_index, uintL end_index,
                               uintW direction) {
  var chart* charptr =
    &TheSstring(TheIarray(O(token_buff_1))->data)->data[start_index];
  var uintB* attrptr =
    &TheSbvector(TheIarray(O(token_buff_2))->data)->data[start_index];
  var uintL len = end_index - start_index;
  if (len == 0)
    return;
  switch (direction) {
    case case_upcase: # convert un-escaped characters to upper case:
  do_upcase:
      dotimespL(len,len, {
        if (!(*attrptr == a_escaped))
          *charptr = up_case(*charptr);
        charptr++; attrptr++;
      });
      break;
    case case_downcase: # convert un-escaped characters to lower case:
  do_downcase:
      dotimespL(len,len, {
        if (!(*attrptr == a_escaped))
          *charptr = down_case(*charptr);
        charptr++; attrptr++;
      });
      break;
    case case_preserve: # do nothing.
      break;
    case case_invert:
      # if there is no un-escaped lower-case-letter,
      # convert all un-escaped characters to lower case.
      # if there is no un-escaped upper-case-letter,
      # convert all un-escaped characters to upper case.
      # otherwise do nothing.
      {
        var bool seen_uppercase = false;
        var bool seen_lowercase = false;
        var const chart* cptr = charptr;
        var const uintB* aptr = attrptr;
        var uintL count;
        dotimespL(count,len, {
          if (!(*aptr == a_escaped)) {
            var chart c = *cptr;
            if (!chareq(c,up_case(c)))
              seen_lowercase = true;
            if (!chareq(c,down_case(c)))
              seen_uppercase = true;
          }
          cptr++; aptr++;
        });
        if (seen_uppercase) {
          if (!seen_lowercase)
            goto do_downcase;
        } else {
          if (seen_lowercase)
            goto do_upcase;
        }
      }
      break;
    default: NOTREACHED;
  }
}

# UP: converts the whole read token to upper or lower case.
# case_convert_token_1();
local void case_convert_token_1 (void) {
  var object readtable;
  get_readtable(readtable = );
  var uintW direction = RTCase(readtable);
  var uintL len = TheIarray(O(token_buff_1))->dims[1]; # Length = Fill-Pointer
  case_convert_token(0,len,direction);
}

# UP: treatment of read-macro-character:
# calls the appropriate macro-function; for dispatch-characters read
# number-argument and subchar first.
# read_macro(ch,&stream)
# > ch: macro-character, a character
# > stream: Stream
# < stream: Stream
# < mv_count/mv_space: one value at most
# can trigger GC
local Values read_macro (object ch, const object* stream_) {
  var object readtable;
  get_readtable(readtable = ); # current readtable (don't need to save ch)
  var object macrodef = # fetch macro-definition from table
    perchar_table_get(TheReadtable(readtable)->readtable_macro_table,
                      char_code(ch));
  if (nullp(macrodef)) { # =NIL ?
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(ch);
    pushSTACK(*stream_);
    pushSTACK(S(read));
    fehler(stream_error,
           GETTEXT("~ from ~: ~ has no macro character definition"));
  }
  if (!simple_vector_p(macrodef)) { # a simple-vector?
    # ch normal macro-character, macrodef function
    pushSTACK(*stream_); # stream as 1st argument
    pushSTACK(ch); # character as 2nd argument
    funcall(macrodef,2); # call function
    if (mv_count > 1) {
      pushSTACK(fixnum(mv_count)); # value number as Fixnum
      pushSTACK(ch);
      pushSTACK(*stream_);
      pushSTACK(S(read));
      fehler(error,
             GETTEXT("~ from ~: macro character definition for ~ may not return ~ values, only one value."));
    }
    # at most one value.
    return; # retain mv_space/mv_count
  } else {
    # Dispatch-Macro-Character.
    # When this changes, keep DISPATCH-READER in defs2.lisp up to date.
    pushSTACK(macrodef); # save vector
    var object arg; # argument (Integer >=0 or NIL)
    var object subch; # sub-char
    var chart subc; # sub-char
    { # read digits of argument:
      var bool flag = false; # flag, if there has been a digit already
      pushSTACK(Fixnum_0); # previous Integer := 0
      loop {
        var object nextch = read_char(stream_); # read character
        if (eq(nextch,eof_value)) {
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(ch); # main char
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(end_of_file,
                 GETTEXT("~: input stream ~ ends within read macro beginning to ~"));
        }
        # otherwise check for character.
        if (!charp(nextch))
          fehler_charread(nextch,stream_);
        var chart ch = char_code(nextch);
        var cint c = as_cint(ch);
        if (!((c>='0') && (c<='9'))) { # no digit -> loop finished
          subc = ch;
          break;
        }
        # multiply Integer by 10 and add digit:
        STACK_0 = mal_10_plus_x(STACK_0,(uintB)(c-'0'));
        flag = true;
      }
      # argument in STACK_0 finished (only if flag=true).
      arg = popSTACK();
      if (!flag)
        arg = NIL; # there was no digit -> Argument := NIL
    }
    # let's continue with Subchar (Character subc)
    subch = code_char(subc);
    subc = up_case(subc); # convert Subchar to upper case
    macrodef = popSTACK(); # get back Vector
    macrodef = perchar_table_get(macrodef,subc); # Subchar-Function or NIL
    if (nullp(macrodef)) { # NIL -> undefined
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(subch); # Subchar
      pushSTACK(ch); # Mainchar
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: After ~ is ~ an undefined dispatch macro character"));
    }
    pushSTACK(*stream_); # Stream as 1. argument
    pushSTACK(subch); # Subchar as 2. Argument
    pushSTACK(arg); # Argument (NIL or Integer>=0) as 3. Argument
    funcall(macrodef,3); # call function
    if (mv_count > 1) {
      pushSTACK(fixnum(mv_count)); # value number as Fixnum
      pushSTACK(ch); # Mainchar
      pushSTACK(subch); # Subchar
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(error,
             GETTEXT("~ from ~: dispatch macro character definition for ~ after ~ may not return ~ values, only one value."));
    }
    # at most 1 value.
    return; # retain mv_space/mv_count
  }
}

# ------------------------ READ at object-level ------------------------------

# UP: reads an object.
# skip leading  whitespace and comment.
# the curren values of SYS::*READ-PRESERVE-WHITESPACE* are definitive
# (for potentially skipping the first Whitespace behind the object)
# also devinitive is SYS::*READ-RECURSIVE-P* (for EOF-treatment).
# read_internal(&stream)
# > stream: Stream
# < stream: Stream
# < result: read object (eof_value at EOF, dot_value for single dot)
# can trigger GC
local object read_internal (const object* stream_) {
 wloop: # loop for skipping of leading whitespace/comment:
  {
    var object ch;
    var uintWL scode;
    read_char_syntax(ch = ,scode = ,stream_); # read character
    switch(scode) {
      case syntax_whitespace: # Whitespace -> throw away and continue reading
        goto wloop;
      case syntax_t_macro:
      case syntax_nt_macro: # Macro-Character at start of Token
        read_macro(ch,stream_); # call Macro-Function
        if (mv_count==0) # 0 values -> continue reading
          goto wloop;
        else # 1 value -> as result
          return value1;
      case syntax_eof: # EOF at start of Token
        if (test_value(S(read_recursive_p))) # *READ-RECURSIVE-P* /= NIL ?
          # yes -> EOF within an object -> error
          fehler_eof_innen(stream_);
        # otherwise eof_value as value:
        clear_input(*stream_); # clear the EOF char from the stream
        return eof_value;
      case syntax_illegal: # read_token_1 returns Error
      case syntax_single_esc:
      case syntax_multi_esc:
      case syntax_constituent: # read Token: A Token starts with character ch.
        read_token_1(stream_,ch,scode); # finish reading of Token
        break;
      default: NOTREACHED;
    }
  }
  # reading of Token finished
  if (test_value(S(read_suppress))) # *READ-SUPPRESS* /= NIL ?
    return NIL; # yes -> don't interprete Token, NIL as value
  # Token must be interpreted
  # the Token is in O(token_buff_1), O(token_buff_2), token_escape_flag.
  if ((!token_escape_flag) && test_dots()) {
    # Token is a sequence of Dots, read without escape-characters
    # thus Length is automatically >0.
    var uintL len = TheIarray(O(token_buff_1))->dims[1]; # length of Token
    if (len > 1) { # Length>1 -> error
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(*stream_);
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: a token consisting only of dots cannot be meaningfully read in"));
    }
    # Length=1 -> dot_value as value
    return dot_value;
  }
  { # Token is OK
    var uintWL base = get_read_base(); # value of *READ-BASE*
    # Token can be interpreted as number?
    var object string;
    var zahl_info_t info;
    var uintWL numtype = test_number_syntax(&base,&string,&info);
    if (!(numtype==0)) { # number?
      upcase_token(); # convert to upper case
      var object result;
      # ANSI CL 2.3.1.1 requires that we transform ARITHMETIC-ERROR
      # into READER-ERROR
      make_HANDLER_frame(O(handler_for_arithmetic_error),
                         &signal_reader_error,NULL);
      switch (numtype) {
        case 1: # Integer
          result = read_integer(base,info.sign,string,info.index1,info.index2);
          break;
        case 2: # Rational
          result = read_rational(base,info.sign,string,info.index1,
                                 info.index3,info.index2);
          break;
        case 3: # Float
          result = read_float(base,info.sign,string,info.index1,
                              info.index4,info.index2,info.index3);
          break;
        default: NOTREACHED;
      }
      unwind_HANDLER_frame();
      return result;
    }
  }
  # Token cannot be interpreted as number.
  # we interprete the Token as Symbol (even, if the Token matches
  # Potential-number-Syntax, thus being a 'reserved token' (in the spirit
  # of CLTL S. 341 top) ).
  # first determine the distribution of colons (Characters with
  # Attributecode a_pack_m):
  # Beginning at the front, search the first colon. Cases (CLTL S. 343-344):
  # 1. no colon -> current Package
  # 2. one or two colons at the beginning -> Keyword
  # 3. one colon, not at the beginning -> external Symbol
  # 4. two colons, not at the beginning -> internal Symbol
  # In the last three cases no more colons may occur.
  # (It cannot be checked here , that at step 2. the name-part
  # respectively at 3. and 4. the package-part and the name-part
  # do not have the syntax of a number,
  # because TOKEN_ESCAPE_FLAG is valid for the whole Token.
  # Compare |USER|:: and |USER|::|| )
  {
    var uintW direction; # direction of the case-conversion
    {
      var object readtable;
      get_readtable(readtable = );
      direction = RTCase(readtable);
    }
    var object buff_2 = O(token_buff_2); # Attributecode-Buffer
    var uintL len = TheIarray(buff_2)->dims[1]; # length = Fill-Pointer
    var uintB* attrptr = &TheSbvector(TheIarray(buff_2)->data)->data[0];
    var uintL index = 0;
    # always attrptr = &TheSbvector(...)->data[index].
    # Token is split in Packagename and Name:
    var uintL pack_end_index;
    var uintL name_start_index;
    var bool external_internal_flag = false; # preliminary external
    loop {
      if (index>=len)
        goto current; # found no colon -> current package
      if (*attrptr++ == a_pack_m)
        break;
      index++;
    }
    # found first colon at Index index
    pack_end_index = index; # Packagename ends here
    index++;
    name_start_index = index; # Symbolname starts (preliminary) here
    # reached Tokenend -> external Symbol:
    if (index>=len)
      goto ex_in_ternal;
    # is a further colon following, immediately?
    index++;
    if (*attrptr++ == a_pack_m) { # two colons side by side
      name_start_index = index; # Symbolname is starting but now
      external_internal_flag = true; # internal
    } else {
      # first colon was isolated
      # external
    }
    # no more colons are to come:
    loop {
      if (index>=len)
        goto ex_in_ternal; # no further colon found -> ok
      if (*attrptr++ == a_pack_m)
        break;
      index++;
    }
    # error message
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(copy_string(O(token_buff_1))); # copy Character-Buffer
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(stream_error,GETTEXT("~ from ~: too many colons in token ~"));
    # search Symbol or create it:
  current: # search Symbol in the current package.
    # Symbolname = O(token_buff_1) = (subseq O(token_buff_1) 0 len)
    # is a non-simple String.
    {
      var object pack = get_current_package();
      if (!pack_casesensitivep(pack))
        case_convert_token(0,len,direction);
      # intern Symbol (and copy String, if the Symbol must be created freshly):
      var object sym;
      intern(O(token_buff_1),pack,&sym);
      return sym;
    }
  ex_in_ternal: # build external/internal Symbol
    # Packagename = (subseq O(token_buff_1) 0 pack_end_index),
    # Symbolname = (subseq O(token_buff_1) name_start_index len).
    case_convert_token(0,pack_end_index,direction);
    if (pack_end_index==0) {
      # colon(s) at the beginning -> build Keyword:
      # Symbolname = (subseq O(token_buff_1) name_start_index len).
      case_convert_token(name_start_index,len,direction);
      # adjust auxiliary-String:
      var object hstring = O(displaced_string);
      TheIarray(hstring)->data = O(token_buff_1); # Data-vector
      TheIarray(hstring)->dims[0] = name_start_index; # Displaced-Offset
      TheIarray(hstring)->totalsize =
        TheIarray(hstring)->dims[1] = len - name_start_index; # length
      # intern Symbol in the Keyword-Package  (and copy String,
       # if the Symbol must be created newly):
      return intern_keyword(hstring);
    }
    { # Packagename = (subseq O(token_buff_1) 0 pack_end_index).
      # adjust Auxiliary-String:
      var object hstring = O(displaced_string);
      TheIarray(hstring)->data = O(token_buff_1); # Data-vector
      TheIarray(hstring)->dims[0] = 0; # Displaced-Offset
      TheIarray(hstring)->totalsize =
        TheIarray(hstring)->dims[1] = pack_end_index; # length
      # search Package with this name:
      var object pack = find_package(hstring);
      if (nullp(pack)) { # Package not found?
        pushSTACK(copy_string(hstring)); # copy Displaced-String, PACKAGE-ERROR slot PACKAGE
        pushSTACK(STACK_0);
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(package_error,
               GETTEXT("~ from ~: there is no package with name ~"));
      }
      if (!pack_casesensitivep(pack))
        case_convert_token(name_start_index,len,direction);
      # adjust Auxiliary-String:
      TheIarray(hstring)->dims[0] = name_start_index; # Displaced-Offset
      TheIarray(hstring)->totalsize =
        TheIarray(hstring)->dims[1] = len - name_start_index; # Length
      if (external_internal_flag) { # internal
        # intern Symbol (and copy String,
        # if Symbol must be created newly):
        var object sym;
        intern(hstring,pack,&sym);
        return sym;
      } else { # external
        # search external Symbol with this Printnamen:
        var object sym;
        if (find_external_symbol(hstring,pack,&sym)) {
          return sym; # found sym
        } else {
          pushSTACK(pack); # PACKAGE-ERROR slot PACKAGE
          pushSTACK(copy_string(hstring)); # copy Displaced-String
          pushSTACK(STACK_1); # pack
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(package_error,
                 GETTEXT("~ from ~: ~ has no external symbol with name ~"));
        }
      }
    }
  }
}

# UP: reads an Objekt, with SYS::*READ-RECURSIVE-P* /= NIL
# (and SYS::*READ-PRESERVE-WHITESPACE* = NIL, cmp. CLTL p. 377 middle).
# reports error at EOF.
# read_recursive(&stream)
# > stream: Stream
# < stream: Stream
# < result: read Objekt (dot_value at single dot)
# can trigger GC
local object read_recursive (const object* stream_) {
  check_SP(); check_STACK(); # check Stacks for Overflow
  if (test_value(S(read_recursive_p))) { #  recursive
    return read_internal(stream_);
  } else { # bind SYS::*READ-RECURSIVE-P* to T:
    dynamic_bind(S(read_recursive_p),T);
    # and bind SYS::*READ-PRESERVE-WHITESPACE* to NIL:
    dynamic_bind(S(read_preserve_whitespace),NIL);
    # and read Objekt:
    var object ergebnis = read_internal(stream_);
    dynamic_unbind();
    dynamic_unbind();
    return ergebnis;
  }
}

# error-message because of out-of-place Dot
# fehler_dot(stream); english: error_dot(stream);
# > stream: Stream
nonreturning_function(local, fehler_dot, (object stream)) {
  pushSTACK(stream); # STREAM-ERROR slot STREAM
  pushSTACK(stream); # Stream
  pushSTACK(S(read));
  fehler(stream_error,GETTEXT("~ from ~: token \".\" not allowed here"));
}

# UP: reads an Object, with SYS::*READ-RECURSIVE-P* /= NIL
# (and SYS::*READ-PRESERVE-WHITESPACE* = NIL, cmp. CLTL p. 377 middle).
# reports Error at EOF or Token ".".
# (this complies with the Idiom (read stream t nil t).)
# read_recursive_no_dot(&stream)
# > stream: Stream
# < stream: Stream
# < result: read Objekt
# can trigger GC
local object read_recursive_no_dot (const object* stream_) {
  # call READ recursively:
  var object ergebnis = read_recursive(stream_);
  # and report Error at ".":
  if (eq(ergebnis,dot_value))
    fehler_dot(*stream_);
  return ergebnis;
}

# UP: disentangles #n# - References to #n= - markings in an Object.
# > value of SYS::*READ-REFERENCE-TABLE*:
#     Aliste of Pairs (marking . marked Object), where
#     each margink is an Object  #<READ-LABEL n>.
# > obj: Object
# < result: destructively  modified Object without References
local object make_references (object obj) {
  var object alist = Symbol_value(S(read_reference_table));
  # SYS::*READ-REFERENCE-TABLE* = NIL -> nothing to do:
  if (nullp(alist)) {
    return obj;
  } else { # check, if SYS::*READ-REFERENCE-TABLE* is an Aliste:
    {
      var object alistr = alist; # run through list
      while (consp(alistr)) { # each List-Element must be a Cons:
        if (!mconsp(Car(alistr)))
          goto fehler_badtable;
        alistr = Cdr(alistr);
      }
      if (!nullp(alistr)) {
      fehler_badtable:
        pushSTACK(S(read_reference_table));
        pushSTACK(S(read));
        fehler(error,
               GETTEXT("~: the value of ~ has been arbitrarily altered"));
      }
    }
    # Alist alist is OK
    pushSTACK(obj);
    var object bad_reference =
      subst_circ(&STACK_0,alist); # substitute References by Objects
    if (!eq(bad_reference,nullobj)) {
      pushSTACK(unbound); # STREAM-ERROR slot STREAM
      pushSTACK(Symbol_value(S(read_reference_table)));
      pushSTACK(S(read_reference_table));
      pushSTACK(obj);
      pushSTACK(bad_reference);
      pushSTACK(S(read));
      fehler(stream_error,GETTEXT("~: no entry for ~ from ~ in ~ = ~"));
    }
    return popSTACK();
  }
}

# UP: Reads an Object, with SYS::*READ-RECURSIVE-P* = NIL .
# (Top-Level-Call of Reader)
# read_top(&stream,whitespace-p)
# > whitespace-p: indicates, if whitespace has to be consumend afterwards
# > stream: Stream
# < stream: Stream
# < result: read Object (eof_value at EOF, dot_value at single dot)
# can trigger GC
local object read_top (const object* stream_, object whitespace_p) {
#if STACKCHECKR
  var object* STACKbefore = STACK; # retain STACK for later
#endif
  # bind SYS::*READ-RECURSIVE-P* to NIL:
  dynamic_bind(S(read_recursive_p),NIL);
  # and bind SYS::*READ-PRESERVE-WHITESPACE* to whitespace_p:
  dynamic_bind(S(read_preserve_whitespace),whitespace_p);
  # bind SYS::*READ-REFERENCE-TABLE* to the empty Table NIL:
  dynamic_bind(S(read_reference_table),NIL);
  # bind SYS::*BACKQUOTE-LEVEL* to NIL:
  dynamic_bind(S(backquote_level),NIL);
  # read Object:
  var object obj = read_internal(stream_);
  # disentangle references:
  obj = make_references(obj);
  dynamic_unbind();
  dynamic_unbind();
  dynamic_unbind();
  dynamic_unbind();
#if STACKCHECKR
  # verify, if Stack is cleaned up:
  if (!(STACK == STACKbefore))
    abort(); # if not --> go to Debugger
#endif
  return obj;
}

# UP: reads an Object.
# stream_read(&stream,recursive-p,whitespace-p)
# > recursive-p: indicates, if recursive call of READ, with Error at EOF
# > whitespace-p: indicates, if whitespace has to be consumed afterwards
# > stream: Stream
# < stream: Stream
# < result: read Object (eof_value at EOF, dot_value at single dot)
# can trigger GC
global object stream_read (const object* stream_, object recursive_p,
                           object whitespace_p) {
  if (nullp(recursive_p)) # inquire recursive-p
    # no -> Top-Level-Call
    return read_top(stream_,whitespace_p);
  else
    # yes -> recursive Call
    return read_recursive(stream_);
}

# ----------------------------- READ-Macros -----------------------------------

# UP: Read List.
# read_delimited_list(&stream,endch,ifdotted)
# > endch: expected character at the End, a Character
# > ifdotted: #DOT_VALUE if Dotted List is allowed, #EOF_VALUE otherwise
# > stream: Stream
# < stream: Stream
# < result: read Object
# can trigger GC
local object read_delimited_list (const object* stream_, object endch,
                                  object ifdotted);
# Dito with set SYS::*READ-RECURSIVE-P* :
local object read_delimited_list_recursive (const object* stream_, object endch,
                                            object ifdotted);
# first the general function:
#ifdef RISCOS_CCBUG
#pragma -z0
#endif
local object read_delimited_list(const object* stream_, object endch,
                                 object ifdotted) {
  # bind SYS::*READ-LINE-NUMBER* to (SYS::LINE-NUMBER stream)
  # (for error-message, in order to know about the line with the opening parenthese):
  var object lineno = stream_line_number(*stream_);
  dynamic_bind(S(read_line_number),lineno);
  if (terminal_stream_p(*stream_))
    dynamic_bind(S(terminal_read_open_object),S(list));
  var object ergebnis;
  # possibly bind SYS::*READ-RECURSIVE-P* to T, first:
  if (test_value(S(read_recursive_p))) { # recursive?
    ergebnis = read_delimited_list_recursive(stream_,endch,ifdotted);
  } else { # no -> bind SYS::*READ-RECURSIVE-P* to T:
    dynamic_bind(S(read_recursive_p),T);
    ergebnis = read_delimited_list_recursive(stream_,endch,ifdotted);
    dynamic_unbind();
  }
  if (terminal_stream_p(*stream_))
    dynamic_unbind(); # S(terminal_read_open_object)
  dynamic_unbind(); # S(read_line_number)
  return ergebnis;
}
#ifdef RISCOS_CCBUG
#pragma -z1
#endif
# then the more special Function:
local object read_delimited_list_recursive (const object* stream_, object endch,
                                            object ifdotted) {
  # don't need to save endch and ifdotted.
  {
    var object object1; # first List element
    loop { # loop, in order to read first Listenelement
      # next non-whitespace Character:
      var object ch;
      var uintWL scode;
      wpeek_char_syntax(ch = ,scode = ,stream_);
      if (eq(ch,endch)) { # is it the expected ending character?
        # yes -> empty List as result
        read_char(stream_); # consume ending character
        return NIL;
      }
      if (scode < syntax_t_macro) { # Macro-Character?
        # no -> read 1. Objekt:
        object1 = read_recursive_no_dot(stream_);
        break;
      } else { # yes -> read belonging character and execute Macro-Function:
        ch = read_char(stream_);
        read_macro(ch,stream_);
        if (!(mv_count==0)) { # value back?
          object1 = value1; # yes -> take as 1. Object
          break;
        }
        # no -> skip
      }
    }
    # object1 is the 1. Object
    pushSTACK(object1);
  }
  {
    var object new_cons = allocate_cons(); # tinker start of the List
    Car(new_cons) = popSTACK(); # new_cons = (cons object1 nil)
    pushSTACK(new_cons);
    pushSTACK(new_cons);
  }
  # stack layout: entire_list, (last entire_list).
  loop { # loop over further List elements
    var object object1; # further List element
    loop { # loop in order to read another  List element
      # next non-whitespace Character:
      var object ch;
      var uintWL scode;
      wpeek_char_syntax(ch = ,scode = ,stream_);
      if (eq(ch,endch)) { # Is it the expected Ending character?
        # yes -> finish list
      finish_list:
        read_char(stream_); # consume Ending character
        skipSTACK(1); return popSTACK(); # entire list as result
      }
      if (scode < syntax_t_macro) { # Macro-Character?
        # no -> read next Object:
        object1 = read_recursive(stream_);
        if (eq(object1,dot_value))
          goto dot;
        break;
      } else { # yes -> read belonging character and execute Macro-Function:
        ch = read_char(stream_);
        read_macro(ch,stream_);
        if (!(mv_count==0)) { # value back?
          object1 = value1; # yes -> take as next Object
          break;
        }
        # no -> skip
      }
    }
    # insert next Objekt into List:
    pushSTACK(object1);
    {
      var object new_cons = allocate_cons(); # next List-Cons
      Car(new_cons) = popSTACK(); # (cons object1 nil)
      Cdr(STACK_0) = new_cons; # =: (cdr (last Gesamtliste))
      STACK_0 = new_cons;
    }
  }
 dot: # Dot has been read
  if (!eq(ifdotted,dot_value)) # none was allowed?
    fehler_dot(*stream_);
  {
    var object object1; # last List-element
    loop { # loop, in order to read last List-element
      # next non-whitespace Character:
      var object ch;
      var uintWL scode;
      wpeek_char_syntax(ch = ,scode = ,stream_);
      if (eq(ch,endch)) { # is it the expected ending-character?
        # yes -> error
      fehler_dot:
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read_delimited_list));
        fehler(stream_error,GETTEXT("~ from ~: illegal end of dotted list"));
      }
      if (scode < syntax_t_macro) { # Macro-Character?
        # no -> read last Objekt:
        object1 = read_recursive_no_dot(stream_);
        break;
      } else { # yes -> read belonging character and execute Macro-Function:
        ch = read_char(stream_);
        read_macro(ch,stream_);
        if (!(mv_count==0)) { # value back?
          object1 = value1; # yes -> take as last Object
          break;
        }
        # no -> skip
      }
    }
    # object1 is the last Object
    # insert into list as (cdr (last Gesamtliste)):
    Cdr(STACK_0) = object1;
  }
  loop { # loop, in order to read comment after the last List-element
    # next non-whitespace Character:
    var object ch;
    var uintWL scode;
    wpeek_char_syntax(ch = ,scode = ,stream_);
    if (eq(ch,endch)) # Is it the expected Ending-character?
      goto finish_list; # yes -> List finished
    if (scode < syntax_t_macro) # Macro-Character?
      # no -> Dot was there too early, error
      goto fehler_dot;
    else { # yes -> read belonging character and execute Macro-Funktion:
      ch = read_char(stream_);
      read_macro(ch,stream_);
      if (!(mv_count==0)) # value back?
        goto fehler_dot; # yes -> Dot came to early, error
      # no -> skip
    }
  }
}

# Macro: checks the Stream-Argument of a SUBRs.
# stream_ = test_stream_arg(stream);
# > stream: Stream-Argument in STACK
# > subr_self: Caller (a SUBR)
# < stream_: &stream
#define test_stream_arg(stream)  \
    (!streamp(stream) ? (fehler_stream(stream), (object*)NULL) : &(stream))

# (set-macro-character #\(
#   #'(lambda (stream char)
#       (read-delimited-list #\) stream t :dot-allowed t)
# )   )
LISPFUNN(lpar_reader,2) # reads (
  {
    var object* stream_ = test_stream_arg(STACK_1);
    # read List after '(' until ')', Dot allowed:
    value1 = read_delimited_list(stream_,ascii_char(')'),dot_value);
    mv_count=1;
    skipSTACK(2);
  }

# #| ( ( |#
# (set-macro-character #\)
#   #'(lambda (stream char)
#       (error "~ of ~: ~ at the beginning of object" 'read stream char)
# )   )
LISPFUNN(rpar_reader,2) # reads )
  {
    var object* stream_ = test_stream_arg(STACK_1);
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(STACK_(0+1)); # char
    pushSTACK(*stream_); # stream
    pushSTACK(S(read));
    fehler(stream_error,GETTEXT("~ from ~: an object cannot start with ~"));
  }

# (set-macro-character #\"
#   #'(lambda (stream char)
#       (let ((buffer (make-array 50 :element-type 'character
#                                    :adjustable t :fill-pointer 0
#            ))       )
#         (loop
#           (multiple-value-bind (ch sy) (read-char-syntax stream)
#             (cond ((eq sy 'eof-code)
#                    (error "~: inputstream ~ ends within a String."
#                           'read stream
#                   ))
#                   ((eql ch char) (return (coerce buffer 'simple-string)))
#                   ((eq sy 'single-escape)
#                    (multiple-value-setq (ch sy) (read-char-syntax stream))
#                    (when (eq sy 'eof-code) (error ...))
#                    (vector-push-extend ch buffer)
#                   )
#                   (t (vector-push-extend ch buffer))
#         ) ) )
#         (if *read-suppress* nil (coerce buffer 'simple-string))
# )   ) )
LISPFUNN(string_reader,2) # reads "
  {
    var object* stream_ = test_stream_arg(STACK_1);
    var object delim_char = STACK_0;
    if (terminal_stream_p(*stream_)) {
      dynamic_bind(S(terminal_read_open_object),S(string));
      pushSTACK(*stream_);
      pushSTACK(delim_char);
      stream_ = &(STACK_1);
    }
    # stack layout: stream, char.
    if (test_value(S(read_suppress))) { # *READ-SUPPRESS* /= NIL ?
      # yes -> only read ahead of string:
      loop {
        # read next character:
        var object ch;
        var uintWL scode;
        read_char_syntax(ch = ,scode = ,stream_);
        if (scode == syntax_eof) # EOF -> error
          goto fehler_eof;
        if (eq(ch,STACK_0)) # same character as char -> finished
          break;
        if (scode == syntax_single_esc) { # Single-Escape-Character?
          # yes -> read another character:
          read_char_syntax(ch = ,scode = ,stream_);
          if (scode == syntax_eof) # EOF -> error
            goto fehler_eof;
        }
      }
      value1 = NIL; # NIL as value
    } else {
      # no -> really read String
      get_buffers(); # two empty Buffers on the Stack
      # stack layout: stream, char, Buffer, anotherBuffer.
      loop {
        # read next character:
        var object ch;
        var uintWL scode;
        read_char_syntax(ch = ,scode = ,stream_);
        if (scode == syntax_eof) # EOF -> error
          goto fehler_eof;
        if (eq(ch,STACK_2)) # same character as char -> finished
          break;
        if (scode == syntax_single_esc) { # Single-Escape-Character?
          # yes -> read another character:
          read_char_syntax(ch = ,scode = ,stream_);
          if (scode == syntax_eof) # EOF -> error
            goto fehler_eof;
        }
        # push character ch into Buffer:
        ssstring_push_extend(STACK_1,char_code(ch));
      }
      # copy Buffer and convert it into Simple-String:
      {
        var object string;
        #ifndef TYPECODES
        if (TheStream(*stream_)->strmflags & bit(strmflags_immut_bit_B))
          string = coerce_imm_ss(STACK_1);
        else
        #endif
          string = copy_string(STACK_1);
        value1 = string;
      }
      # free Buffer for reuse:
      O(token_buff_2) = popSTACK(); O(token_buff_1) = popSTACK();
    }
    if (terminal_stream_p(*stream_)) {
      skipSTACK(2);
      dynamic_unbind(); # S(terminal_read_open_object)
    }
    mv_count=1; skipSTACK(2);
    return;
   fehler_eof:
    if (terminal_stream_p(*stream_)) {
      skipSTACK(2);
      dynamic_unbind(); # S(terminal_read_open_object)
    }
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(end_of_file,GETTEXT("~: input stream ~ ends within a string"));
  }

# reads an Object and creates a list with two elements.
# list2_reader(stream_);
# > stack layout: stream, symbol.
# increases STACK by 2
# modifies STACK, can trigger GC
# can trigger GC
local Values list2_reader (const object* stream_) {
  var object obj = read_recursive_no_dot(stream_); # read Object
  pushSTACK(obj);
  pushSTACK(allocate_cons()); # second List-cons
  var object new_cons1 = allocate_cons(); # first List-cons
  var object new_cons2 = popSTACK(); # second List-cons
  Car(new_cons2) = popSTACK(); # new_cons2 = (cons obj nil)
  Cdr(new_cons1) = new_cons2; Car(new_cons1) = STACK_0; # new_cons1 = (cons symbol new_cons2)
  value1 = new_cons1; mv_count=1; skipSTACK(2);
}

# (set-macro-character #\'
#   #'(lambda (stream char)
#       (list 'QUOTE (read stream t nil t))
# )   )
LISPFUNN(quote_reader,2) # reads '
  {
    var object* stream_ = test_stream_arg(STACK_1);
    STACK_0 = S(quote); return_Values list2_reader(stream_);
  }

# (set-macro-character #\;
#   #'(lambda (stream char)
#       (loop
#         (let ((ch (read-char stream)))
#           (when (or (eql ch 'eof-code) (eql ch #\Newline)) (return))
#       ) )
#       (values)
# )   )
LISPFUNN(line_comment_reader,2) # reads ;
  {
    var object* stream_ = test_stream_arg(STACK_1);
    loop {
      var object ch = read_char(stream_); # read character
      if (eq(ch,eof_value) || eq(ch,ascii_char(NL)))
        break;
    }
    value1 = NIL; mv_count=0; skipSTACK(2); # return no values
  }

# ------------------------- READ-Dispatch-Macros ------------------------------

# error-message due to forbidden number at Dispatch-Macros
# fehler_dispatch_zahl(); english: error_dispatch_number();
# > STACK_1: Stream
# > STACK_0: sub-char
nonreturning_function(local, fehler_dispatch_zahl, (void)) {
  pushSTACK(STACK_1); # STREAM-ERROR slot STREAM
  pushSTACK(STACK_(0+1)); # sub-char
  pushSTACK(STACK_(1+2)); # Stream
  pushSTACK(S(read));
  fehler(stream_error,
         GETTEXT("~ from ~: no number allowed between #"" and $"));
}

# UP: checks the absence of Infix-Argument n
# test_no_infix()
# > stack layout: Stream, sub-char, n.
# > subr_self: Caller (ein SUBR)
# < result: &stream
# increases STACK by 1
# modifies STACK
local object* test_no_infix (void) {
  var object* stream_ = test_stream_arg(STACK_2);
  var object n = popSTACK();
  if ((!nullp(n)) && (!test_value(S(read_suppress))))
    # if n/=NIL and *READ-SUPPRESS*=NIL : report error
    fehler_dispatch_zahl();
  return stream_;
}

# (set-dispatch-macro-character #\# #\'
#   #'(lambda (stream sub-char n)
#       (when n (error ...))
#       (list 'FUNCTION (read stream t nil t))
# )   )
LISPFUNN(function_reader,3) # reads #'
  {
    var object* stream_ = test_no_infix(); # n must be NIL
    STACK_0 = S(function); return_Values list2_reader(stream_);
  }

# (set-dispatch-macro-character #\# #\|
#   #'(lambda (stream sub-char n) ; with (not (eql sub-char #\#))
#       (when n (error ...))
#       (prog ((depth 0) ch)
#         1
#         (setq ch (read-char))
#         2
#         (case ch
#           (eof-code (error ...))
#           (sub-char (case (setq ch (read-char))
#                       (eof-code (error ...))
#                       (#\# (when (minusp (decf depth)) (return)))
#                       (t (go 2))
#           )         )
#           (#\# (case (setq ch (read-char))
#                  (eof-code (error ...))
#                  (sub-char (incf depth) (go 1))
#                  (t (go 2))
#           )    )
#           (t (go 1))
#       ) )
#       (values)
# )   )
LISPFUNN(comment_reader,3) # reads #|
  {
    var object* stream_ = test_no_infix(); # n must be NIL
    var uintL depth = 0;
    var object ch;
   loop1:
    ch = read_char(stream_);
   loop2:
    if (eq(ch,eof_value)) # EOF -> Error
      goto fehler_eof;
    else if (eq(ch,STACK_0)) {
      # sub-char has been read
      ch = read_char(stream_); # next character
      if (eq(ch,eof_value)) # EOF -> Error
        goto fehler_eof;
      else if (eq(ch,ascii_char('#'))) {
        # sub-char and '#' has been read -> decrease depth:
        if (depth==0)
          goto fertig;
        depth--;
        goto loop1;
      } else
        goto loop2;
    } else if (eq(ch,ascii_char('#'))) {
      # '#' has been read
      ch = read_char(stream_); # next character
      if (eq(ch,eof_value)) # EOF -> Error
        goto fehler_eof;
      else if (eq(ch,STACK_0)) {
        # '#' and sub-char has been read -> increase depth:
        depth++;
        goto loop1;
      } else
        goto loop2;
    } else
      goto loop1;
   fehler_eof:
    pushSTACK(STACK_1); # STREAM-ERROR slot STREAM
    pushSTACK(STACK_(0+1)); # sub-char
    pushSTACK(STACK_(0+2)); # sub-char
    pushSTACK(STACK_(1+3)); # Stream
    pushSTACK(S(read));
    fehler(end_of_file,
           GETTEXT("~: input stream ~ ends within a comment #$ ... $#"));
   fertig:
    value1 = NIL; mv_count=0; skipSTACK(2); # return no values
  }

# (set-dispatch-macro-character #\# #\\
#   #'(lambda (stream sub-char n)
#       (let ((token (read-token-1 stream #\\ 'single-escape)))
#         ; token is a String of Length >=1
#         (unless *read-suppress*
#           (if n
#             (unless (< n char-font-limit) ;  n>=0, anyway
#               (error "~ of ~: Font-Number ~ for Character is too big (must be <~ )."
#                       'read stream        n                 char-font-limit
#             ) )
#             (setq n 0)
#           )
#           (let ((pos 0) (bits 0))
#             (loop
#               (if (= (+ pos 1) (length token))
#                 (return (make-char (char token pos) bits n))
#                 (let ((hyphen (position #\- token :start pos)))
#                   (if hyphen
#                     (flet ((equalx (name)
#                              (or (string-equal token name :start1 pos :end1 hyphen)
#                                  (string-equal token name :start1 pos :end1 hyphen :end2 1)
#                           )) )
#                       (cond ((equalx "CONTROL")
#                              (setq bits (logior bits char-control-bit)))
#                             ((equalx "META")
#                              (setq bits (logior bits char-meta-bit)))
#                             ((equalx "SUPER")
#                              (setq bits (logior bits char-super-bit)))
#                             ((equalx "HYPER")
#                              (setq bits (logior bits char-hyper-bit)))
#                             (t (error "~ of ~: A Character-Bit with Name ~ does not exist."
#                                        'read stream (subseq token pos hyphen)
#                       )     )  )
#                       (setq pos (1+ hyphen))
#                     )
#                     (return
#                       (make-char
#                         (cond ((and (< (+ pos 4) (length token))
#                                     (string-equal token "CODE" :start1 pos :end1 (+ pos 4))
#                                )
#                                (code-char (parse-integer token :start (+ pos 4) :junk-allowed nil)) ; without Sign!
#                               )
#                               ((and (= (+ pos 2) (length token))
#                                     (eql (char token pos) #\^)
#                                     (<= 64 (char-code (char token (+ pos 1))) 95)
#                                )
#                                (code-char (- (char-code (char token (+ pos 1))) 64))
#                               )
#                               ((name-char (subseq token pos)))
#                               (t (error "~ of ~: A Character with Name ~ does not exist."
#                                          'read stream (subseq token pos)
#                         )     )  )
#                         bits n
#                     ) )
#             ) ) ) )
# )   ) ) ) )
LISPFUNN(char_reader,3) # reads #\
  {
    # stack layout: Stream, sub-char, n.
    var object* stream_ = test_stream_arg(STACK_2);
    # read Token, with Dummy-Character '\' as start of Token:
    read_token_1(stream_,ascii_char('\\'),syntax_single_esc);
    # finished at once, when *READ-SUPPRESS* /= NIL:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(3); # NIL as value
      return;
    }
    case_convert_token_1();
    # determine Font:
    if (!nullp(STACK_0)) # n=NIL -> Default-Font 0
      if (!eq(STACK_0,Fixnum_0)) {
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(STACK_(0+1)); # n
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,GETTEXT("~ from ~: font number ~ for character is too large, should be = 0"));
      }
    # Font ready.
    var object token = O(token_buff_1); # read Token as Semi-Simple-String
    var uintL len = TheIarray(token)->dims[1]; # lengh = Fill-Pointer
    var object hstring = O(displaced_string); # auxiliary string
    TheIarray(hstring)->data = token; # Data-vector := O(token_buff_1)
    token = TheIarray(token)->data; # Normal-Simple-String with Token
    var uintL pos = 0; # current Position in Token
    # do not search for bits since this interferes with
    # Unicode names which contain hyphens
    var uintL sub_len = len-pos; # Length of Character name
    if (sub_len == 1) { # character name consists of one letter
      var chart code = TheSstring(token)->data[pos]; # (char token pos)
      value1 = code_char(code); mv_count=1; skipSTACK(3);
      return;
    }
    TheIarray(hstring)->dims[0] = pos; # Displaced-Offset := pos
    /* TheIarray(hstring)->totalsize =          */
    /*   TheIarray(hstring)->dims[1] = sub_len; */ # Length := len-pos
    # hstring = (subseq token pos hyphen) = remaining Charactername
    # Test for Character-Came "CODExxxx" (xxxx Decimalnumber <256):
    if (sub_len > 4) {
      TheIarray(hstring)->totalsize =
        TheIarray(hstring)->dims[1] = 4;
      # hstring = (subseq token pos (+ pos 4))
      if (!string_equal(hstring,O(charname_prefix))) # = "Code" ?
        goto not_codexxxx; # no -> continue
      # decipher Decimal number:
      var uintL code = 0; # so far read xxxx (<char_code_limit)
      var uintL index = pos+4;
      var const chart* charptr = &TheSstring(token)->data[index];
      loop {
        if (index == len) # reached end of Token?
          break;
        var cint c = as_cint(*charptr++); # next Character
        # is to be digit:
        if (!((c>='0') && (c<='9')))
          goto not_codexxxx;
        code = 10*code + (c-'0'); # add digit
        # code is to be < char_code_limit:
        if (code >= char_code_limit)
          goto not_codexxxx;
        index++;
      }
      # Charactername was of type Typ "Codexxxx" with code = xxxx < char_code_limit
      value1 = code_char(as_chart(code)); mv_count=1; skipSTACK(3);
      return;
    }
  not_codexxxx:
    # Test for Pseudo-Character-Name ^X:
    if ((sub_len == 2) && chareq(TheSstring(token)->data[pos],ascii('^'))) {
      var cint code = as_cint(TheSstring(token)->data[pos+1])-64;
      if (code < 32) {
        value1 = ascii_char(code); mv_count=1; skipSTACK(3);
        return;
      }
    }
    # Test for Charactername like NAME-CHAR:
    TheIarray(hstring)->totalsize =
      TheIarray(hstring)->dims[1] = sub_len; # Length := len-pos
    var object ch = name_char(hstring); # search Character with this Name
    if (nullp(ch)) { # not found -> Error
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(copy_string(hstring)); # copy Charactername
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: there is no character with name ~"));
    }
    # found
    value1 = ch; mv_count=1; skipSTACK(3);
    return;
  }

# (defun radix-1 (stream sub-char n base)
#   (let ((token (read-token stream)))
#     (unless *read-suppress*
#       (when n (error ...))
#       (if (case (test-number-syntax token base)
#             (integer t) (decimal-integer nil) (rational t) (float nil)
#           )
#         (read-number token base)
#         (error "~ of ~: The Token ~ after # ~ cannot be interpreted as rational number in Base ~."
#                 'read stream token sub-char base
# ) ) ) ) )
  # UP: for #B #O #X #R
  # radix_2(base)
  # > base: Basis (>=2, <=36)
  # > stack layout: Stream, sub-char, base.
  # > O(token_buff_1), O(token_buff_2), token_escape_flag: read Token
  # < STACK: cleaned up
  # < mv_space/mv_count: values
  # can trigger GC
local Values radix_2 (uintWL base) {
  # check, if the  Token is a rational number:
  upcase_token(); # convert to upper case
  var object string;
  var zahl_info_t info;
  switch (test_number_syntax(&base,&string,&info)) {
    case 1: # Integer
      # is last Character a dot?
      if (chareq(TheSstring(string)->data[info.index2-1],ascii('.')))
        # yes -> Decimal-Integer, not in Base base
        goto not_rational;
      # test_number_syntax finished already in step 3,
      # so base is still unchanged.
      skipSTACK(3);
      value1 = read_integer(base,info.sign,string,info.index1,info.index2);
      mv_count=1; return;
    case 2: # Rational
      # test_number_syntax finished already in step 3,
      # so base is still unchanged.
      skipSTACK(3);
      value1 = read_rational(base,info.sign,string,info.index1,
                             info.index3,info.index2);
      mv_count=1; return;
    case 0: # no number
    case 3: # Float
  not_rational: # no rational number
      pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
      pushSTACK(STACK_(0+1)); # base
      pushSTACK(STACK_(1+2)); # sub-char
      pushSTACK(copy_string(O(token_buff_1))); # Token
      pushSTACK(STACK_(2+4)); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: token ~ after #$ is not a rational number in base ~"));
    default: NOTREACHED;
  }
}
  # UP: for #B #O #X
  # radix_1(base)
  # > base: Base (>=2, <=36)
  # > stack layout: Stream, sub-char, n.
  # > subr_self: caller (ein SUBR)
  # < STACK: cleaned
  # < mv_space/mv_count: values
  # can trigger GC
local Values radix_1 (uintWL base) {
  var object* stream_ = test_stream_arg(STACK_2);
  read_token(stream_); # read Token
  # finished at once when *READ-SUPPRESS* /= NIL:
  if (test_value(S(read_suppress))) {
    value1 = NIL; mv_count=1; skipSTACK(3); # NIL as value
    return;
  }
  if (!nullp(popSTACK())) # n/=NIL -> Error
    fehler_dispatch_zahl();
  pushSTACK(fixnum(base)); # base as Fixnum
  return_Values radix_2(base);
}

# (set-dispatch-macro-character #\# #\B
#   #'(lambda (stream sub-char n) (radix-1 stream sub-char n 2))
# )
LISPFUNN(binary_reader,3) # reads #B
  {
    return_Values radix_1(2);
  }

# (set-dispatch-macro-character #\# #\O
#   #'(lambda (stream sub-char n) (radix-1 stream sub-char n 8))
# )
LISPFUNN(octal_reader,3) # reads #O
  {
    return_Values radix_1(8);
  }

# (set-dispatch-macro-character #\# #\X
#   #'(lambda (stream sub-char n) (radix-1 stream sub-char n 16))
# )
LISPFUNN(hexadecimal_reader,3) # reads #X
  {
    return_Values radix_1(16);
  }

# (set-dispatch-macro-character #\# #\R
#   #'(lambda (stream sub-char n)
#       (if *read-suppress*
#         (if (and n (<= 2 n 36))
#           (radix-1 stream sub-char nil n)
#           (error "~ of ~: Between # and R a base between 2 and 36 must be stated."
#                   'read stream
#         ) )
#         (progn (read-token stream) nil)
# )   ) )
LISPFUNN(radix_reader,3) # reads #R
  {
    var object* stream_ = test_stream_arg(STACK_2);
    read_token(stream_); # read Token
    # finished at once when *READ-SUPPRESS* /= NIL:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(3); # NIL as value
      return;
    }
    # check n:
    if (nullp(STACK_0)) {
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: the number base must be given between #"" and R"));
    }
    var uintL base;
    # n must be a Fixnum between 2 and 36 (inclusive):
    if (posfixnump(STACK_0) &&
        (base = posfixnum_to_L(STACK_0), (base >= 2) && (base <= 36))) {
      return_Values radix_2(base); # interprete Token as rational number
    } else {
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(STACK_(0+1)); # n
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: The base ~ given between #"" and R should lie between 2 and 36"));
    }
  }

# (set-dispatch-macro-character #\# #\C
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (if *read-suppress*
#         (progn (read stream t nil t) nil)
#         (if n
#           (error "~: Zwischen # und C ist keine Zahl erlaubt." 'read)
#           (let ((h (read stream t nil t)))
#             (if (and (consp h) (consp (cdr h)) (null (cddr h))
#                      (numberp (first h)) (not (complexp (first h)))
#                      (numberp (second h)) (not (complexp (second h)))
#                 )
#               (apply #'complex h)
#               (error "~: Wrong Syntax for complex Number: #C~" 'read h)
# )   ) ) ) ) )
LISPFUNN(complex_reader,3) # reads #C
  {
    var object* stream_ = test_no_infix(); # n must be NIL
    var object obj = read_recursive_no_dot(stream_); # read next Object
    # finished at once when *READ-SUPPRESS* /= NIL:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(2); # NIL as value
      return;
    }
    obj = make_references(obj); # unentangle references untimely
    # check, if this is a 2-elemnt List of real numbers:
    if (!consp(obj)) goto bad; # obj must be a Cons !
    {
      var object obj2 = Cdr(obj);
      if (!consp(obj2)) goto bad; # obj2 must be a Cons!
      if (!nullp(Cdr(obj2))) goto bad; # with (cdr obj2) = nil !
      if_realp(Car(obj), ; , goto bad; ); # and (car obj) being a real number!
      if_realp(Car(obj2), ; , goto bad; ); # and (car obj2) being a real number!
      # execute (apply #'COMPLEX obj):
      apply(L(complex),0,obj);
      mv_count=1; skipSTACK(2); return; # value1 as value
    }
   bad:
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(obj); # Object
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(stream_error,
           GETTEXT("~ from ~: bad syntax for complex number: #C~"));
  }

# (set-dispatch-macro-character #\# #\:
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (if *read-suppress*
#         (progn (read stream t nil t) nil)
#         (let ((name (read-token stream))) ; eine Form, die nur ein Token ist
#           (when n (error ...))
#           [verify, if also no Package-Marker occurs in the Token.]
#           (make-symbol token)
# )   ) ) )
LISPFUNN(uninterned_reader,3) # reads #:
  {
    var object* stream_ = test_stream_arg(STACK_2);
    # when *READ-SUPPRESS* /= NIL, read form and return NIL:
    if (test_value(S(read_suppress))) {
      read_recursive(stream_);
      value1 = NIL; mv_count=1; skipSTACK(3); return;
    }
    # read next character:
    {
      var object ch;
      var uintWL scode;
      read_char_syntax(ch = ,scode = ,stream_);
      if (scode == syntax_eof) # EOF -> Error
        fehler_eof_innen(stream_);
      if (scode > syntax_constituent) {
        # no character, that is allowed at beginning of Token -> Error
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,GETTEXT("~ from ~: token expected after #:"));
      }
      # read Token until the end:
      read_token_1(stream_,ch,scode);
      case_convert_token_1();
    }
    if (!nullp(popSTACK())) # n/=NIL -> Error
      fehler_dispatch_zahl();
    # copy Token and convert into Simple-String:
    var object string = coerce_imm_ss(O(token_buff_1));
    # test for Package-Marker:
    {
      var object buff_2 = O(token_buff_2); # Attribut-Code-Buffer
      var uintL len = TheIarray(buff_2)->dims[1]; # length = Fill-Pointer
      if (len > 0) {
        var uintB* attrptr = &TheSbvector(TheIarray(buff_2)->data)->data[0];
        # Test, if one of the len Attribut-Codes starting at attrptr and afterwards is an a_pack_m:
        dotimespL(len,len, { if (*attrptr++ == a_pack_m) goto fehler_dopp; } );
      }
    }
    # build uninterned Symbol with this Name:
    value1 = make_symbol(string); mv_count=1; skipSTACK(2); return;
   fehler_dopp:
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(string); # Token
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(stream_error,
           GETTEXT("~ from ~: token ~ after #: should contain no colon"));
  }

# (set-dispatch-macro-character #\# #\*
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (let* ((token (read-token stream)))
#         (unless *read-suppress*
#           (unless (or [Escape-Zeichen im Token verwendet]
#                       (every #'(lambda (ch) (member ch '(#\0 #\1))) token))
#             (error "~ of ~: After #* only Zeros and Ones may occur."
#                     'read stream
#           ) )
#           (let ((l (length token)))
#             (if n
#               (cond ((< n l)
#                      (error "~ of ~: Bit-Vector longer than specified length ~."
#                              'read stream n
#                     ))
#                     ((and (plusp n) (zerop l))
#                      (error "~ of ~: Element for Bit-Vector of Length ~ must be specified."
#                              'read stream n
#               )     ))
#               (setq n l)
#             )
#             (let ((bv (make-array n :element-type 'bit))
#                   (i 0)
#                   b)
#               (loop
#                 (when (= i n) (return))
#                 (when (< i l) (setq b (case (char token i) (#\0 0) (#\1 1))))
#                 (setf (sbit bv i) b)
#                 (incf i)
#               )
#               bv
# )   ) ) ) ) )
LISPFUNN(bit_vector_reader,3) # reads #*
  {
    var object* stream_ = test_stream_arg(STACK_2);
    read_token(stream_); # read Token
    # finished at once, if *READ-SUPPRESS* /= NIL:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(3); # NIL as value
      return;
    }
    # Test, if no Escape-character and only 0s and 1s are used:
    if (token_escape_flag) {
     fehler_nur01:
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: only zeroes and ones are allowed after #*"));
    }
    var object buff_1 = O(token_buff_1); # Character-Buffer
    var uintL len = TheIarray(buff_1)->dims[1]; # length = Fill-Pointer
    if (len > 0) {
      var const chart* charptr = &TheSstring(TheIarray(buff_1)->data)->data[0];
      var uintL count;
      dotimespL(count,len, {
        var chart c = *charptr++; # next Character
        if (!(chareq(c,ascii('0')) || chareq(c,ascii('1')))) # only '0' and '1' are OK
          goto fehler_nur01;
      });
    }
    # check n:
    var uintL n; # Length of Bitvectors
    if (nullp(STACK_0)) {
      n = len; # Defaultvalue is the Tokenlength
    } else {
      # n specified, an Integer >=0.
      n = (posfixnump(STACK_0) ? posfixnum_to_L(STACK_0) # Fixnum -> value
                               : bitm(oint_data_len)-1); # Bignum -> big value
      if (n<len) {
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(STACK_(0+1)); # n
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: bit vector is longer than the explicitly given length ~"));
      }
      if ((n>0) && (len==0)) {
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(STACK_(0+1)); # n
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: must specify element of bit vector of length ~"));
      }
    }
    # create new Bit-Vector with length n:
    var object bv = allocate_bit_vector(Atype_Bit,n);
    # and fill the Bits into it:
    buff_1 = O(token_buff_1);
    {
      var const chart* charptr = &TheSstring(TheIarray(buff_1)->data)->data[0];
      var chart ch; # last character ('0' or '1')
      var uintL index = 0;
      while (index < n) {
        if (index < len)
          ch = *charptr++; # possibly, fetch next Character
        if (chareq(ch,ascii('0'))) {
          sbvector_bclr(bv,index); # Null -> delete Bit
        } else {
          sbvector_bset(bv,index); # Eins -> set Bit
        }
        index++;
      }
    }
    value1 = bv; mv_count=1; skipSTACK(3); # bv as value
  }

# (set-dispatch-macro-character #\# #\(
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (let* ((elements (read-delimited-list #\) stream t)))
#         (unless *read-suppress*
#           (let ((l (length elements)))
#             (if n
#               (cond ((< n l)
#                      (error "~ of ~: Vector longer than specified length ~."
#                              'read stream n
#                     ))
#                     ((and (plusp n) (zerop l))
#                      (error "~ of ~: Element for Vector of Length ~ must be specified."
#                              'read stream n
#               )     ))
#               (setq n l)
#             )
#             (let ((v (make-array n))
#                   (i 0)
#                   b)
#               (loop
#                 (when (= i n) (return))
#                 (when (< i l) (setq b (pop elements)))
#                 (setf (svref v i) b)
#                 (incf i)
#               )
#               v
# )   ) ) ) ) )
LISPFUNN(vector_reader,3) # reads #(
  {
    var object* stream_ = test_stream_arg(STACK_2);
    # read List until parenthese, Dot is not allowed:
    var object elements = read_delimited_list(stream_,ascii_char(')'),eof_value);
    # already finished when *READ-SUPPRESS* /= NIL:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(3); # NIL as value
      return;
    }
    var uintL len = llength(elements); # Listlength
    # check n:
    var uintL n; # Length of Vector
    if (nullp(STACK_0)) {
      n = len; # Defaultvalue is the length of the Token
    } else {
      # specify n, an Integer >=0.
      n = (posfixnump(STACK_0) ? posfixnum_to_L(STACK_0) # Fixnum -> value
                               : bitm(oint_data_len)-1); # Bignum -> big value
      if (n<len) {
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(STACK_(0+1)); # n
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: vector is longer than the explicitly given length ~"));
      }
      if ((n>0) && (len==0)) {
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(STACK_(0+1)); # n
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: must specify element of vector of length ~"));
      }
    }
    # create new Vector with Length n:
    pushSTACK(elements); # save List
    var object v = allocate_vector(n);
    elements = popSTACK(); # retrieve List
    # und fill it with the Elements:
    {
      var object* vptr = &TheSvector(v)->data[0];
      var object el; # last Element
      var uintL index = 0;
      while (index < n) {
        if (index < len) {
          el = Car(elements); elements = Cdr(elements); # possibly fetch next Element
        }
        *vptr++ = el;
        index++;
      }
    }
    value1 = v; mv_count=1; skipSTACK(3); # v as value
  }

# (set-dispatch-macro-character #\# #\A
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (if *read-suppress*
#         (progn (read stream t nil t) nil)
#         (if (null n)
#           (let ((h (read stream t nil t)))
#             (if (and (consp h) (consp (cdr h)) (consp (cddr h)) (null (cdddr h)))
#               (make-array (second h) :element-type (first h) :initial-contents (third h))
#               (error "~: Wrong Syntax for Array: #A~" 'read h)
#           ) )
#           (let* ((rank n)
#                  (cont (let ((*backquote-level* nil)) (read stream t nil t)))
#                  (dims '())
#                  (eltype 't))
#             (when (plusp rank)
#               (let ((subcont cont) (i 0))
#                 (loop
#                   (let ((l (length subcont)))
#                     (push l dims)
#                     (incf i) (when (>= i rank) (return))
#                     (when (plusp l) (setq subcont (elt subcont 0)))
#                 ) )
#                 (cond ((stringp subcont) (setq eltype 'character))
#                       ((bit-vector-p subcont) (setq eltype 'bit))
#             ) ) )
#             (make-array (nreverse dims) :element-type eltype :initial-contents cont)
# )   ) ) ) )
LISPFUNN(array_reader,3) # reads #A
  {
    var object* stream_ = test_stream_arg(STACK_2);
    # stack layout: stream, sub-char, n.
    if (test_value(S(read_suppress))) { # *READ-SUPPRESS* /= NIL ?
      # yes -> skip next Object:
      read_recursive_no_dot(stream_);
      value1 = NIL; mv_count=1; skipSTACK(3); return;
    }
    if (nullp(STACK_0)) { # n not specified?
      # yes -> read List (eltype dims contents):
      var object obj = read_recursive_no_dot(stream_); # read List
      obj = make_references(obj); # unentangle references
      # (this is harmless, since we don't use this #A-Syntax
      # for Arrays with Elementtyp T, and Byte-Arrays contain no references.)
      if (!consp(obj)) goto bad;
      {
        var object obj2 = Cdr(obj);
        if (!consp(obj2)) goto bad;
        var object obj3 = Cdr(obj2);
        if (!consp(obj3)) goto bad;
        if (!nullp(Cdr(obj3))) goto bad;
        # call (MAKE-ARRAY dims :element-type eltype :initial-contents contents):
        STACK_2 = Car(obj2); STACK_1 = S(Kelement_type); STACK_0 = Car(obj);
        pushSTACK(S(Kinitial_contents)); pushSTACK(Car(obj3));
        goto call_make_array;
      }
     bad:
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(obj); # Object
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(stream_error,GETTEXT("~ from ~: bad syntax for array: #A~"));
    }
    # n specifies the Rank of the Arrays.
    # read content:
    {
      dynamic_bind(S(backquote_level),NIL); # bind SYS::*BACKQUOTE-LEVEL* to NIL
      var object contents = read_recursive_no_dot(stream_);
      dynamic_unbind();
      pushSTACK(contents); pushSTACK(contents);
    }
    STACK_4 = NIL; # dims := '()
    # stack layout: dims, -, rank, subcontents, contents.
    # determine Dimensions and Element-type:
    if (eq(STACK_2,Fixnum_0)) { # rank=0 ?
      STACK_2 = S(t); # yes -> eltype := 'T
    } else {
      var object i = Fixnum_0; # former nesting depth
      loop {
        pushSTACK(STACK_1); funcall(L(length),1); # (LENGTH subcontents)
        # push on dims:
        STACK_3 = value1;
        {
          var object new_cons = allocate_cons();
          Car(new_cons) = STACK_3; Cdr(new_cons) = STACK_4;
          STACK_4 = new_cons;
        }
        # increase depth:
        i = fixnum_inc(i,1); if (eql(i,STACK_2)) break;
        # first Element of subcontents for the following Dimensions:
        if (!eq(STACK_3,Fixnum_0)) { # (only if (length subcontents) >0)
          pushSTACK(STACK_1); pushSTACK(Fixnum_0); funcall(L(elt),2);
          STACK_1 = value1; # subcontents := (ELT subcontents 0)
        }
      }
      nreverse(STACK_4); # reverse List dims
      # determine eltype according to innermost subcontents:
      STACK_2 = (stringp(STACK_1) ? S(character) :          # String: CHARACTER
                 bit_vector_p(Atype_Bit,STACK_1) ? S(bit) : # Bitvector: BIT
                 S(t));                                     # else (Liste): T
    }
    # stack layout: dims, -, eltype, -, contents.
    # call MAKE-ARRAY:
    STACK_3 = S(Kelement_type); STACK_1 = S(Kinitial_contents);
    call_make_array:
    funcall(L(make_array),5);
    mv_count=1; return;
  }

# Errormessage for #. and #, because of *READ-EVAL*.
# fehler_read_eval_forbidden(&stream,obj); english: erro_read_eval_forbidden(&stream,obj);
# > stream: Stream
# > obj: Object, whose Evaluation was examined
nonreturning_function(local, fehler_read_eval_forbidden, (object* stream_, object obj)) {
  pushSTACK(*stream_); # STREAM-ERROR slot STREAM
  pushSTACK(obj); # Object
  pushSTACK(NIL); # NIL
  pushSTACK(S(read_eval)); # *READ-EVAL*
  pushSTACK(*stream_); # Stream
  pushSTACK(S(read));
  fehler(stream_error,
         GETTEXT("~ from ~: ~ = ~ does not allow the evaluation of ~"));
}

# (set-dispatch-macro-character #\# #\.
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (let ((h (read stream t nil t)))
#         (unless *read-suppress*
#           (if n
#             (error "~ of ~: Between # and . no Number is allowed."
#                     'read stream
#             )
#             (eval h)
# )   ) ) ) )
LISPFUNN(read_eval_reader,3) # reads #.
  {
    var object* stream_ = test_stream_arg(STACK_2);
    var object obj = read_recursive_no_dot(stream_); # read Form
    # if *READ-SUPPRESS* /= NIL ==> finished immediately:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(3);
      return;
    }
    if (!nullp(popSTACK())) # n/=NIL -> Error
      fehler_dispatch_zahl();
    obj = make_references(obj); # unentangle references
    # either *READ-EVAL* or the Stream must allow the Evaluation.
    if (!(test_value(S(read_eval)) || stream_get_read_eval(*stream_)))
      fehler_read_eval_forbidden(stream_,obj);
    eval_noenv(obj); # evaluate Form
    mv_count=1; skipSTACK(2); # only 1 value back
  }

# (set-dispatch-macro-character #\# #\,
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (let ((h (read stream t nil t)))
#         (unless *read-suppress*
#           (if n
#             (error "~ of ~: Between # and , no number is allowed."
#                     'read stream
#             )
#             (if sys::*compiling* (make-load-time-eval h) (eval h))
# )   ) ) ) )
LISPFUNN(load_eval_reader,3) # reads #,
  {
    var object* stream_ = test_stream_arg(STACK_2);
    var object obj = read_recursive_no_dot(stream_); # read Form
    # finished immediately, when *READ-SUPPRESS* /= NIL:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(3);
      return;
    }
    if (!nullp(popSTACK())) # n/=NIL -> Error
      fehler_dispatch_zahl();
    obj = make_references(obj); # unentangle references
    if (test_value(S(compiling))) {
      # In Compiler:
      pushSTACK(obj);
      var object newobj = allocate_loadtimeeval(); # Load-time-Eval-Object
      TheLoadtimeeval(newobj)->loadtimeeval_form = popSTACK(); # with obj as Form
      value1 = newobj;
    } else {
      # In Interpreter:
      # either *READ-EVAL* or the Stream must allow the Evaluation.
      if (!(test_value(S(read_eval)) || stream_get_read_eval(*stream_)))
        fehler_read_eval_forbidden(stream_,obj);
      eval_noenv(obj); # evaluate Form
    }
    mv_count=1; skipSTACK(2); # only 1 value back
  }

# (set-dispatch-macro-character #\# #\=
#   #'(lambda (stream sub-char n)
#       (if *read-suppress*
#         (if n
#           (if (sys::fixnump n)
#             (let* ((label (make-internal-label n))
#                    (h (assoc label sys::*read-reference-table* :test #'eq)))
#               (if (consp h)
#                 (error "~ of ~: Label #~= must not be defined twice." 'read stream n)
#                 (progn
#                   (push (setq h (cons label label)) sys::*read-reference-table*)
#                   (let ((obj (read stream t nil t)))
#                     (if (eq obj label)
#                       (error "~ of ~: #~= #~# is not allowed." 'read stream n n)
#                       (setf (cdr h) obj)
#             ) ) ) ) )
#             (error "~ of ~: Label #~= too big" 'read stream n)
#           )
#           (error "~ of ~: Between # and = a number must be specified." 'read stream)
#         )
#         (values) ; no values (comment)
# )   ) )

# (set-dispatch-macro-character #\# #\#
#   #'(lambda (stream sub-char n)
#       (unless *read-suppress*
#         (if n
#           (if (sys::fixnump n)
#             (let* ((label (make-internal-label n))
#                    (h (assoc label sys::*read-reference-table* :test #'eq)))
#               (if (consp h)
#                 label ; will be disentangled later
#                 ; (you could also return (cdr h) )
#                 (error "~ of ~: Label #~= is not defined." 'read stream n)
#               )
#             (error "~ of ~: Label #~# too big" 'read stream n)
#           )
#           (error "~ of ~: Between # and # a number must be specified." 'read stream)
# )   ) ) )

# UP: creates an internal Label and looks it up in *READ-REFERENCE-TABLE*.
# lookup_label()
# > stack layout: Stream, sub-char, n.
# < result: (or (assoc label sys::*read-reference-table* :test #'eq) label)
local object lookup_label (void) {
  var object n = STACK_0;
  if (nullp(n)) { # not specified?
    pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
    pushSTACK(STACK_(1+1)); # sub-char
    pushSTACK(STACK_(2+2)); # Stream
    pushSTACK(S(read));
    fehler(stream_error,
           GETTEXT("~ from ~: a number must be given between #"" and $"));
  }
  # n is an Integer >=0
  if (!read_label_integer_p(n)) { # n is too big
    pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
    pushSTACK(STACK_(1+1)); # sub-char
    pushSTACK(STACK_(0+2)); # n
    pushSTACK(STACK_(2+3)); # Stream
    pushSTACK(S(read));
    fehler(stream_error,GETTEXT("~ from ~: label #~? too large"));
  }
  var object label = make_read_label(posfixnum_to_L(n)); # Internal-Label with Nummer n
  var object alist = # value of SYS::*READ-REFERENCE-TABLE*
    Symbol_value(S(read_reference_table));
  # execute (assoc label alist :test #'eq):
  while (consp(alist)) {
    var object acons = Car(alist); # List-element
    if (!consp(acons)) goto bad_reftab; # must be a Cons !
    if (eq(Car(acons),label)) # its CAR = label ?
      return acons; # yes -> fertig
    alist = Cdr(alist);
  }
  if (nullp(alist)) # List-end with NIL ?
    return label; # yes -> (assoc ...) = NIL -> finished with label
 bad_reftab: # value of SYS::*READ-REFERENCE-TABLE* is no Alist
  pushSTACK(Symbol_value(S(read_reference_table))); # value of SYS::*READ-REFERENCE-TABLE*
  pushSTACK(S(read_reference_table)); # SYS::*READ-REFERENCE-TABLE*
  pushSTACK(STACK_(2+2)); # Stream
  pushSTACK(S(read));
  fehler(error,
         GETTEXT("~ from ~: the value of ~ has been altered arbitrarily, it is not an alist: ~"));
}

LISPFUNN(label_definition_reader,3) # reads #=
  {
    # when *READ-SUPPRESS* /= NIL, #n= is treated as comment:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=0; skipSTACK(3); # no values
      return;
    }
    # create Label and lookup in Table:
    var object lookup = lookup_label();
    if (consp(lookup)) {
      # found -> has already been there -> error:
      pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
      pushSTACK(STACK_(0+1)); # n
      pushSTACK(STACK_(2+2)); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: label #~= may not be defined twice"));
    } else {
      # lookup = label, not jeopardized by GC.
      # (push (setq h (cons label label)) sys::*read-reference-table*) :
      var object* stream_ = test_stream_arg(STACK_2);
      {
        var object new_cons = allocate_cons();
        Car(new_cons) = Cdr(new_cons) = lookup; # h = (cons label label)
        pushSTACK(new_cons); # save h
      }
      {
        var object new_cons = allocate_cons(); # new List-Cons
        Car(new_cons) = STACK_0;
        Cdr(new_cons) = Symbol_value(S(read_reference_table));
        Symbol_value(S(read_reference_table)) = new_cons;
      }
      var object obj = read_recursive_no_dot(stream_); # read Objekt
      var object h = popSTACK();
      if (eq(obj,Car(h))) { # read Objekt = (car h) = label ?
        # yes -> cyclic Definition -> Error
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(STACK_(0+1)); # n
        pushSTACK(STACK_(0+2)); # n
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,GETTEXT("~ from ~: #~= #~#"" is illegal"));
      }
      # insert read Objekt as (cdr h):
      Cdr(h) = obj;
      value1 = obj; mv_count=1; skipSTACK(3); # obj as value
    }
  }

LISPFUNN(label_reference_reader,3) # reads ##
  {
    # when *READ-SUPPRESS* /= NIL, finished immediately:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(3);
      return;
    }
    # construct Label and lookup in Table:
    var object lookup = lookup_label();
    if (consp(lookup)) {
      # found -> return Label as read object:
      value1 = Car(lookup); mv_count=1; skipSTACK(3);
    } else {
      # not found
      pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
      pushSTACK(STACK_(0+1)); # n
      pushSTACK(STACK_(2+2)); # Stream
      pushSTACK(S(read));
      fehler(stream_error,GETTEXT("~ from ~: undefined label #~#"));
    }
  }

# (set-dispatch-macro-character #\# #\<
#   #'(lambda (stream sub-char n)
#       (error "~ of ~: Objects printed as #<...> cannot be reread again."
#               'read stream
# )   ) )
LISPFUNN(not_readable_reader,3) # reads #<
  {
    var object* stream_ = test_stream_arg(STACK_2);
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(stream_error,
           GETTEXT("~ from ~: objects printed as #<...> cannot be read back in"));
  }

# (dolist (ch '(#\) #\Space #\Newline #\Linefeed #\Backspace #\Rubout #\Tab #\Return #\Page))
#   (set-dispatch-macro-character #\# ch
#     #'(lambda (stream sub-char n)
#         (error "~ of ~: Because of ~ as # printed Objects cannot be reread."
#                 'read stream '*print-level*
# ) )   ) )
LISPFUNN(syntax_error_reader,3) # reads #) and #whitespace
  {
    var object* stream_ = test_stream_arg(STACK_2);
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(S(print_level));
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(stream_error,
           GETTEXT("~ from ~: objects printed as #"" in view of ~ cannot be read back in"));
  }

# Auxiliary function for #+ and #- :
# (defun interpret-feature (feature)
#   (flet ((eqs (x y) (and (symbolp x) (symbolp y)
#                          (string= (symbol-name x) (symbol-name y))
#         ))          )
#     (cond ((symbolp feature) (member feature *features* :test #'eq))
#           ((atom feature)
#            (error "~: As Feature ~ is not allowed." 'read feature)
#           )
#           ((eqs (car feature) 'and)
#            (every #'interpret-feature (cdr feature))
#           )
#           ((eqs (car feature) 'or)
#            (some #'interpret-feature (cdr feature))
#           )
#           ((eqs (car feature) 'not)
#            (not (interpret-feature (second feature)))
#           )
#           (t (error "~: As Feature ~ is not allowed." 'read feature))
# ) ) )

# UP: checks, if Feature-Expression is satisfied.
# interpret_feature(expr)
# > expr: a Feature-Expresion
# > STACK_1: Stream
# < result: truth value: 0 if satisfied, ~0 if not.
local uintWL interpret_feature (object expr) {
  check_SP();
  if (symbolp(expr)) { # expr Symbol, search in *FEATURES*:
    var object list = Symbol_value(S(features)); # value of *FEATURES*
    while (consp(list)) {
      if (eq(Car(list),expr))
        goto ja;
      list = Cdr(list);
    }
    goto nein;
  } else if (consp(expr) && symbolp(Car(expr))) {
    var object opname = Symbol_name(Car(expr));
    var uintWL and_or_flag;
    if (string_gleich(opname,Symbol_name(S(and)))) { # expr = (AND ...)
      and_or_flag = 0; goto and_or;
    } else if (string_gleich(opname,Symbol_name(S(or)))) { # expr = (OR ...)
      and_or_flag = ~0;
    and_or:
      # interprete the list-elements of expr, until there is a
      # result /=and_or_flag. Default is and_or_flag.
      var object list = Cdr(expr);
      while (consp(list)) { # interprete on List-element:
        var uintWL sub_erg = interpret_feature(Car(list));
        if (!(sub_erg == and_or_flag))
          return sub_erg;
        list = Cdr(list);
      }
      if (nullp(list))
        return and_or_flag;
      # expr was a Dotted List -> error
    } else if (string_gleich(opname,Symbol_name(S(not)))) {
      # expr = (NOT ...) is to be of the shape (NOT obj):
      var object opargs = Cdr(expr);
      if (consp(opargs) && nullp(Cdr(opargs)))
        return ~interpret_feature(Car(opargs));
      # expr has no correct shape -> error
    }
    # wrong (car expr) -> error
  }
 bad: # wrong structure of Feature-Expression
  pushSTACK(STACK_1); # STREAM-ERROR slot STREAM
  pushSTACK(expr); # Feature-Expression
  pushSTACK(STACK_(1+2)); # Stream
  pushSTACK(S(read));
  fehler(stream_error,GETTEXT("~ from ~: illegal feature ~"));
 ja: return 0; # expr is fulfilled
 nein: return ~0; # expr is not fulfilled
}

# UP: for #+ und #-
# feature(sollwert)
# > expected value: exprected truth value of Feature-Expression
# > Stack Structure: Stream, sub-char, n.
# > subr_self: caller (a SUBR)
# < STACK: increased by 3
# < mv_space/mv_count: values
# can trigger GC
local Values feature (uintWL sollwert) {
  var object* stream_ = test_no_infix(); # n must be NIL
  dynamic_bind(S(read_suppress),NIL); # bind *READ-SUPPRESS* to NIL
  dynamic_bind(S(packagestern),O(keyword_package)); # bind *PACKAGE* to #<PACKAGE KEYWORD>
  var object expr = read_recursive_no_dot(stream_); # read Feature-Expression
  dynamic_unbind();
  dynamic_unbind();
  # interpret Feature-Expression:
  expr = make_references(expr); # first unentangle references
  if (interpret_feature(expr) == sollwert) { # truth value "true"
    # read next Objekt and set for value:
    value1 = read_recursive_no_dot(stream_); mv_count=1;
  } else { # truth value "false"
    # bind *READ-SUPPRESS* to T, read Object, comment
    dynamic_bind(S(read_suppress),T);
    read_recursive_no_dot(stream_);
    dynamic_unbind();
    value1 = NIL; mv_count=0; # no values
  }
  skipSTACK(2);
}

# (set-dispatch-macro-character #\# #\+
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (if n
#         (error "~ of ~: Between # and + no number is allowed." 'read stream)
#         (let ((feature (let ((*read-suppress* nil)) (read stream t nil t))))
#           (if (interpret-feature feature)
#             (read stream t nil t)
#             (let ((*read-suppress* t))
#               (read stream t nil t)
#               (values)
# )   ) ) ) ) )
LISPFUNN(feature_reader,3) # reads #+
  {
    return_Values feature(0);
  }

# (set-dispatch-macro-character #\# #\-
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (if n
#         (error "~ of ~: Between # and - no number is allowed." 'read stream)
#         (let ((feature (let ((*read-suppress* nil)) (read stream t nil t))))
#           (if (interpret-feature feature)
#             (let ((*read-suppress* t))
#               (read stream t nil t)
#               (values)
#             )
#             (read stream t nil t)
# )   ) ) ) )
LISPFUNN(not_feature_reader,3) # reads #-
  {
    return_Values feature(~0);
  }

# (set-dispatch-macro-character #\# #\S
#   #'(lambda (stream char n)
#       (declare (ignore char))
#       (if *read-suppress*
#         (progn (read stream t nil t) nil)
#         (if n
#           (error "~: Between # and S no number is allowed." 'read)
#           (let ((args (let ((*backquote-level* nil)) (read stream t nil t))))
#             (if (consp args)
#               (let ((name (first args)))
#                 (if (symbolp name)
#                   (let ((desc (get name 'DEFSTRUCT-DESCRIPTION)))
#                     (if desc
#                       (if (svref desc 2)
#                         (values
#                           (apply (svref desc 2) ; der Konstruktor
#                                  (structure-arglist-expand name (cdr args))
#                         ) )
#                         (error "~: Structures of Type ~ cannot be read (Constructor-Function unknown)"
#                                'read name
#                       ) )
#                       (error "~: No Structure of Type ~ has been defined"
#                              'read name
#                   ) ) )
#                   (error "~: The Type of a Structure must be a Symbol, nicht ~"
#                          'read name
#               ) ) )
#               (error "~: Behind #S the Type and the contents of the Structure must follow in parenthesis, not ~"
#                      'read args
# )   ) ) ) ) ) )
# (defun structure-arglist-expand (name args)
#   (cond ((null args) nil)
#         ((atom args) (error "~: A Structure ~ must not contain a Component . " 'read name))
#         ((not (symbolp (car args)))
#          (error "~: ~ is no Symbol and thus no Slot of the Structure ~" 'read (car args) name)
#         )
#         ((null (cdr args)) (error "~: Value of the Component ~ in Structure ~ is missing" 'read (car args) name))
#         ((atom (cdr args)) (error "~: A Structure ~ must not contain a Component . " 'read name))
#         (t (let ((kw (intern (symbol-name (car args)) (find-package "KEYWORD"))))
#              (list* kw (cadr args) (structure-arglist-expand name (cddr args)))
# ) )     )  )
LISPFUNN(structure_reader,3) # reads #S
  {
    var object* stream_ = test_no_infix(); # n must be NIL
    # when *READ-SUPPRESS* /= NIL, only read one object:
    if (test_value(S(read_suppress))) {
      read_recursive_no_dot(stream_); # read Objekt and throw away,
      value1 = NIL; mv_count=1; skipSTACK(2); return; # NIL as value
    }
    # bind SYS::*BACKQUOTE-LEVEL* to NIL and read object:
    dynamic_bind(S(backquote_level),NIL);
    var object args = read_recursive_no_dot(stream_);
    dynamic_unbind();
    # check read List:
    if (atomp(args)) {
      pushSTACK(*stream_); # STREAM-ERROR slot STREAM
      pushSTACK(args); # Arguments
      pushSTACK(*stream_); # Stream
      pushSTACK(S(read));
      fehler(stream_error,
             GETTEXT("~ from ~: #S must be followed by the type and the contents of the structure, not ~"));
    }
    {
      var object name = Car(args); # Type of Structure
      STACK_0 = args = Cdr(args); # save Restlist
      # Stack Structure: Stream, remaining Args.
      if (!symbolp(name)) { # Type must be a Symbol !
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(name);
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: the type of a structure should be a symbol, not ~"));
      }
      pushSTACK(name);
      # Stack Structure: Stream, remaining Args, name.
      if (eq(name,S(hash_table))) { # Symbol HASH-TABLE ?
        # yes -> treat specially, no Structure:
        # Hash-Tabelle
        # Remaining Argumentlist must be a Cons:
        if (!consp(args)) {
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(stream_error,GETTEXT("~ from ~: bad HASH-TABLE"));
        }
        # (MAKE-HASH-TABLE :TEST (car args) :INITIAL-CONTENTS (cdr args))
        pushSTACK(S(Ktest)); # :TEST
        pushSTACK(Car(args)); # Test (Symbol)
        pushSTACK(S(Kinitial_contents)); # :INITIAL-CONTENTS
        pushSTACK(Cdr(args)); # Aliste ((Key_1 . Value_1) ... (Key_n . Value_n))
        funcall(L(make_hash_table),4); # build Hash-Table
        mv_count=1; # value1 as value
        skipSTACK(3); return;
      }
      if (eq(name,S(random_state))) { # Symbol RANDOM-STATE ?
        # yes -> treat specially, no Structure:
        # Random-State
        # Remaining Argumentlist must be a Cons with NIL as CDR and
        # a Simple-Bit-Vector of length 64 as CAR:
        if (!(consp(args)
              && nullp(Cdr(args))
              && simple_bit_vector_p(Atype_Bit,Car(args))
              && (Sbvector_length(Car(args)) == 64))) {
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(name);
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(stream_error,GETTEXT("~ from ~: bad ~"));
        }
        STACK_0 = Car(args); # save Simple-Bit-Vector
        var object ergebnis = allocate_random_state(); # new Random-State
        The_Random_state(ergebnis)->random_state_seed = popSTACK(); # fill
        value1 = ergebnis; mv_count=1; skipSTACK(2); return;
      }
      if (eq(name,S(pathname))) { # Symbol PATHNAME ?
        # yes -> treat specially, no Structure:
        STACK_1 = make_references(args); pushSTACK(L(make_pathname));
      }
      #ifdef LOGICAL_PATHNAMES
      else if (eq(name,S(logical_pathname))) { # Symbol LOGICAL-PATHNAME ?
        # yes -> treat specially, no Structure:
        STACK_1 = make_references(args); pushSTACK(L(make_logical_pathname));
      }
      #endif
      else if (eq(name,S(byte))) { # Symbol BYTE ?
        # yes -> treat specially, no Structure:
        pushSTACK(S(make_byte));
      }
      else {
        # execute (GET name 'SYS::DEFSTRUCT-DESCRIPTION):
        var object description = get(name,S(defstruct_description));
        if (eq(description,unbound)) { # nothing found?
          # Structure of this Type undefined
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(name);
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(stream_error,
                 GETTEXT("~ from ~: no structure of type ~ has been defined"));
        }
        # description must be a Simple-Vector of length >=4:
        if (!(simple_vector_p(description) && (Svector_length(description) >= 4))) {
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(name);
          pushSTACK(S(defstruct_description));
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(stream_error,GETTEXT("~ from ~: bad ~ for ~"));
        }
        # fetch constructor-function:
        var object constructor = # (svref description 2)
          TheSvector(description)->data[2];
        if (nullp(constructor)) {
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(name);
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(stream_error,
                 GETTEXT("~ from ~: structures of type ~ cannot be read in, missing constructor function"));
        }
    # call constructor-function with adapted Argumentlist:
        pushSTACK(constructor);
      }
    }
    # stack layout: Stream, remaining Args, name, constructor.
    var uintC argcount = 0; # number of arguments for constructor
    loop { # process remaining Argumentlist,
           # push Arguments for constructor on STACK:
      check_STACK();
      args = *(stream_ STACKop -1); # remaining Args
      if (nullp(args)) # no more -> Arguments in STACK are ready
        break;
      if (atomp(args)) {
       dotted:
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(*(stream_ STACKop -2)); # name
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: a structure ~ may not contain a component \".\""));
      }
      {
        var object slot = Car(args);
        if (!symbolp(slot)) {
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(*(stream_ STACKop -2)); # name
          pushSTACK(slot);
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(stream_error,
                 GETTEXT("~ from ~: ~ is not a symbol, not a slot name of structure ~"));
        }
        if (nullp(Cdr(args))) {
          pushSTACK(*stream_); # STREAM-ERROR slot STREAM
          pushSTACK(*(stream_ STACKop -2)); # name
          pushSTACK(slot);
          pushSTACK(*stream_); # Stream
          pushSTACK(S(read));
          fehler(stream_error,
                 GETTEXT("~ from ~: missing value of slot ~ in structure ~"));
        }
        if (matomp(Cdr(args)))
          goto dotted;
        {
          var object kw = intern_keyword(Symbol_name(slot)); # Slotname as Keyword
          pushSTACK(kw); # Keyword into STACK
        }
      }
      args = *(stream_ STACKop -1); # again the same remaining Args
      args = Cdr(args);
      pushSTACK(Car(args)); # Slot-value into STACK
      *(stream_ STACKop -1) = Cdr(args); # shorten Arglist
      argcount += 2; # and count
      if (argcount == 0) {
        # Argument-Counter has become too big
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(*(stream_ STACKop -2)); # name
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: too many slots for structure ~"));
      }
    }
    funcall(*(stream_ STACKop -3),argcount); # call constructor
    mv_count=1; skipSTACK(4); return; # value1 as value
  }

# (set-dispatch-macro-character #\# #\Y
#   #'(lambda (stream sub-char arg)
#       (declare (ignore sub-char))
#       (if arg
#         (if (eql arg 0)
#           ; Encoding lesen
#           (let ((obj
#                   (let ((*read-suppress* nil)
#                         (*package* (find-package "CHARSET")))
#                     (read stream t nil t)
#                )) )
#             (setf (stream-external-format stream) obj)
#             (values)
#           )
#           ; Codevector lesen
#           (let ((obj (let ((*read-base* 16.)) (read stream t nil t))))
#             (unless *read-suppress*
#               (unless (= (length obj) arg)
#                 (error "Wrong Length of a Closure-Vector: ~S" arg)
#               )
#               (make-code-vector obj) ; Simple-Bit-Vector, Content: arg Bytes
#         ) ) )
#         ; read Closure
#         (let ((obj (read stream t nil t)))
#           (unless *read-suppress*
#             (%make-closure (first obj) (second obj) (cddr obj))
# )   ) ) ) )

  # error-message because of wrong Syntax of a Code-Vector
  # fehler_closure_badchar(); english: error_closure_badchar();
  # > stack layout: stream, sub-char, arg.
nonreturning_function(local, fehler_closure_badchar, (void)) {
  pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
  pushSTACK(STACK_(0+1)); # n
  pushSTACK(STACK_(2+2)); # Stream
  pushSTACK(S(read));
  fehler(stream_error,
         GETTEXT("~ from ~: illegal syntax of closure code vector after #~Y"));
}

  # UP: checks, if Character ch with Syntaxcode scode is a
  # Hexadecimal-Digit, and delivers its value.
  # hexziffer(ch,scode) english: hexdigit(ch,scode)
  # > ch, scode: Character (or eof_value) and its Syntaxcode
  # > stack layout: stream, sub-char, arg.
  # < Result: value (>=0, <16) of Hexdigit
local uintB hexziffer (object ch, uintWL scode) {
  if (scode == syntax_eof)
    fehler_eof_innen(&STACK_2);
  # ch is a Character
  var cint c = as_cint(char_code(ch));
  if (c<'0') goto badchar; if (c<='9') { return (c-'0'); } # '0'..'9'
  if (c<'A') goto badchar; if (c<='F') { return (c-'A'+10); } # 'A'..'F'
  if (c<'a') goto badchar; if (c<='f') { return (c-'a'+10); } # 'a'..'f'
 badchar: fehler_closure_badchar();
}

LISPFUNN(closure_reader,3) # liest #Y
  {
    var object* stream_ = test_stream_arg(STACK_2);
    # when n=0 read an Encoding:
    if (eq(STACK_0,Fixnum_0)) {
      dynamic_bind(S(read_suppress),NIL); # bind *READ-SUPPRESS* to NIL
      dynamic_bind(S(packagestern),O(charset_package)); # bind *PACKAGE* to #<PACKAGE CHARSET>
      var object expr = read_recursive_no_dot(stream_); # read expression
      dynamic_unbind();
      dynamic_unbind();
      expr = make_references(expr); # unentangle references
      pushSTACK(*stream_); pushSTACK(expr); pushSTACK(S(Kinput));
      funcall(L(set_stream_external_format),3); # (SYS::SET-STREAM-EXTERNAL-FORMAT stream expr :input)
      value1 = NIL; mv_count=0; skipSTACK(3); return; # no values
    }
    # when *READ-SUPPRESS* /= NIL, only read one Object:
    if (test_value(S(read_suppress))) {
      read_recursive_no_dot(stream_); # read Object, and throw away
      value1 = NIL; mv_count=1; skipSTACK(3); return; # NIL as value
    }
    # according to n :
    if (nullp(STACK_0)) {
      # n=NIL -> read Closure:
      var object obj = read_recursive_no_dot(stream_); # read Object
      if (!(consp(obj) && mconsp(Cdr(obj)))) { # length >=2 ?
        pushSTACK(*stream_); # STREAM-ERROR slot STREAM
        pushSTACK(obj);
        pushSTACK(*stream_); # Stream
        pushSTACK(S(read));
        fehler(stream_error,
               GETTEXT("~ from ~: object #Y~ has not the syntax of a compiled closure"));
      }
      skipSTACK(3);
      # execute (SYS::%MAKE-CLOSURE (first obj) (second obj) (cddr obj)):
      pushSTACK(Car(obj)); obj = Cdr(obj); # 1. Argument
      pushSTACK(Car(obj)); obj = Cdr(obj); # 2. Argument
      pushSTACK(obj); # 3. Argument
      funcall(L(make_closure),3);
      mv_count=1; # value1 as value
    } else {
      # n specified -> read Codevector:
      # Syntax: #nY(b1 ... bn), where n is a Fixnum >=0 and b1,...,bn
      # are Fixnums >=0, <256 in Base 16  (with one or two digits).
      # e.g. #9Y(0 4 F CD 6B8FD1e4 5)
      # n is an Integer >=0.
      var uintL n =
        (posfixnump(STACK_0) ? posfixnum_to_L(STACK_0) # Fixnum -> value
                             : bitm(oint_data_len)-1); # Bignum -> big value
      # get new Bit-Vector with n Bytes:
      STACK_1 = allocate_bit_vector(Atype_8Bit,n);
      # stack layout: Stream, Codevektor, n.
      var object ch;
      var uintWL scode;
      # skip Whitespace:
      do {
        read_char_syntax(ch = ,scode = ,stream_); # read character
      } until (!(scode == syntax_whitespace));
      # '(' must follow:
      if (!eq(ch,ascii_char('(')))
        fehler_closure_badchar();
      {
        var uintL index = 0;
        until (index==n) {
          # skip Whitespace:
          do {
            read_char_syntax(ch = ,scode = ,stream_); # read character
          } until (!(scode == syntax_whitespace));
          # Hex-digit must follow:
          var uintB zif = hexziffer(ch,scode);
          # read next Character:
          read_char_syntax(ch = ,scode = ,stream_);
          if (scode == syntax_eof) # EOF -> Error
            fehler_eof_innen(stream_);
          if ((scode == syntax_whitespace) || eq(ch,ascii_char(')'))) {
            # Whitespace or closing parenthese
            # will be pushed back to Stream:
            unread_char(stream_,ch);
          } else {
            # it must be a second Hex-digit
            zif = 16*zif + hexziffer(ch,scode); # add to first Hex-digit
            # (no whitespace is demanded after the second Hex-digit.)
          }
          # zif = read Byte. write into Codevector:
          TheSbvector(STACK_1)->data[index] = zif;
          index++;
        }
      }
      # skip Whitespace:
      do {
        read_char_syntax(ch = ,scode = ,stream_); # read character
      } until (!(scode == syntax_whitespace));
      # ')' must follow:
      if (!eq(ch,ascii_char(')')))
        fehler_closure_badchar();
      #if BIG_ENDIAN_P
      # convert Header from Little-Endian to Big-Endian:
      {
        var Sbvector v = TheSbvector(STACK_1);
        swap(uintB, v->data[CCV_SPDEPTH_1], v->data[CCV_SPDEPTH_1+1]);
        swap(uintB, v->data[CCV_SPDEPTH_JMPBUFSIZE], v->data[CCV_SPDEPTH_JMPBUFSIZE+1]);
        swap(uintB, v->data[CCV_NUMREQ], v->data[CCV_NUMREQ+1]);
        swap(uintB, v->data[CCV_NUMOPT], v->data[CCV_NUMOPT+1]);
        if (v->data[CCV_FLAGS] & bit(7)) {
          swap(uintB, v->data[CCV_NUMKEY], v->data[CCV_NUMKEY+1]);
          swap(uintB, v->data[CCV_KEYCONSTS], v->data[CCV_KEYCONSTS+1]);
        }
      }
      #endif
      # Codevector as value:
      value1 = STACK_1; mv_count=1; skipSTACK(3);
    }
  }

# (set-dispatch-macro-character #\# #\"
#   #'(lambda (stream sub-char n)
#       (unless *read-suppress*
#         (if n
#           (error "~ of ~: Between # and " no number is allowed."
#                  'read stream
#       ) ) )
#       (unread-char sub-char stream)
#       (let ((obj (read stream t nil t))) ; String read
#         (unless *read-suppress* (pathname obj))
# )   ) )
LISPFUNN(clisp_pathname_reader,3) # reads #"
  {
    test_no_infix(); # n must be NIL
    # stack layout: Stream, sub-char #\".
    var object string = # read String, that starts with "
      (funcall(L(string_reader),2),value1);
    # when *READ-SUPPRESS* /= NIL, finished immediately:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; return; # NIL as value
    }
    # construct (pathname string) = (values (parse-namestring string)) :
    pushSTACK(string); funcall(L(parse_namestring),1); # (PARSE-NAMESTRING string)
    mv_count=1; # only one value
  }

# (set-dispatch-macro-character #\# #\P
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (if *read-suppress*
#         (progn (read stream t nil t) nil)
#         (if n
#           (error "~ of ~: Between # and P no number is allowed."
#                  'read stream
#           )
#           (let ((obj (read stream t nil t)))
#             (if (stringp obj)
#               (values (parse-namestring obj))
#               (error "~ of ~: Wrong Syntax for Pathname: #P~"
#                      'read stream obj
# )   ) ) ) ) ) )
LISPFUNN(ansi_pathname_reader,3) # reads #P
  {
    var object* stream_ = test_no_infix(); # n must be NIL
    var object obj = read_recursive_no_dot(stream_); # read next Object
    # when *READ-SUPPRESS* /= NIL, finished immediately:
    if (test_value(S(read_suppress))) {
      value1 = NIL; mv_count=1; skipSTACK(2); return;
    }
    obj = make_references(obj); # and unentangle references untimely (unnessecary?)
    if (!stringp(obj)) # obj must be a String!
      goto bad;
    # create (pathname obj) = (values (parse-namestring obj)) :
    pushSTACK(obj); funcall(L(parse_namestring),1); # (PARSE-NAMESTRING obj)
    mv_count=1; skipSTACK(2); return; # only one value
   bad:
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(obj); # Object
    pushSTACK(*stream_); # Stream
    pushSTACK(S(read));
    fehler(stream_error,GETTEXT("~ from ~: bad syntax for pathname: #P~"));
  }

#ifdef UNIX

# (set-dispatch-macro-character #\# #\!
#   #'(lambda (stream sub-char n)
#       (declare (ignore sub-char))
#       (when n (error ...))
#       (read-line stream)
#       (values)
# )   )
LISPFUNN(unix_executable_reader,3) # reads #!
  {
    var object* stream_ = test_no_infix(); # n must be NIL
    # stack layout: Stream, sub-char #\!.
    loop {
      var object ch = read_char(stream_); # read character
      if (eq(ch,eof_value) || eq(ch,ascii_char(NL)))
        break;
    }
    value1 = NIL; mv_count=0; skipSTACK(2); # return no values
  }

#endif

# ------------------------ LISP-Functions of the Reader -----------------------

# UP: checks an Input-Stream-Argument.
# Default is the value of *STANDARD-INPUT*.
# test_istream(&stream);
# > subr_self: caller (ein SUBR)
# > stream: Input-Stream-Argument
# < stream: Input-Stream (a Stream)
local void test_istream (object* stream_) {
  var object stream = *stream_;
  if (eq(stream,unbound) || nullp(stream)) {
    # instead of #<UNBOUND> or NIL: value of *STANDARD-INPUT*
    *stream_ = var_stream(S(standard_input),strmflags_rd_ch_B);
  } else if (eq(stream,T)) { # instead of T: value of *TERMINAL-IO*
    *stream_ = var_stream(S(terminal_io),strmflags_rd_ch_B);
  } else {
    if (!streamp(stream))
      fehler_stream(stream);
  }
}

# EOF-Handling, ends Reader-Functions.
# eof_handling()
# > STACK_3: Input-Stream
# > STACK_2: eof-error-p
# > STACK_1: eof-value
# > STACK_0: recursive-p
# < mv_space/mv_count: values
local Values eof_handling (int mvc) {
  if (!nullp(STACK_2)) { # eof-error-p /= NIL (e.g. = #<UNBOUND>) ?
    # report Error:
    var object recursive_p = STACK_0;
    if (eq(recursive_p,unbound) || nullp(recursive_p))
      fehler_eof_aussen(&STACK_3); # report EOF
    else
      fehler_eof_innen(&STACK_3); # report EOF within Objekt
  } else { # handle EOF:
    var object eofval = STACK_1;
    if (eq(eofval,unbound))
      eofval = NIL; # Default is NIL
    value1 = eofval; mv_count=mvc; skipSTACK(4); # eofval as value
  }
}

# UP: for READ and READ-PRESERVING-WHITESPACE
# read_w(whitespace-p)
# > whitespace-p: indicates, if whitespace has to be consumed afterwards
# > stack layout: input-stream, eof-error-p, eof-value, recursive-p.
# > subr_self: caller (a SUBR) (unnecessary, if input-stream is a Stream)
# < STACK: cleaned up
# < mv_space/mv_count: values
local Values read_w (object whitespace_p) {
  # check input-stream:
  test_istream(&STACK_3);
  # check for recursive-p-Argument:
  var object recursive_p = STACK_0;
  if (eq(recursive_p,unbound) || nullp(recursive_p)) { # non-recursive call
    var object obj = read_top(&STACK_3,whitespace_p);
    if (eq(obj,dot_value))
      fehler_dot(STACK_3); # Dot -> Error
    if (eq(obj,eof_value)) {
      return_Values eof_handling(1); # EOF-treatment
    } else {
      value1 = obj; mv_count=1; skipSTACK(4); # obj as value
    }
  } else { # recursive call
    value1 = read_recursive_no_dot(&STACK_3); mv_count=1; skipSTACK(4);
  }
}

LISPFUN(read,0,4,norest,nokey,0,NIL)
# (READ [input-stream [eof-error-p [eof-value [recursive-p]]]]), CLTL p. 375
  {
    return_Values read_w(NIL); # whitespace-p := NIL
  }

LISPFUN(read_preserving_whitespace,0,4,norest,nokey,0,NIL)
# (READ-PRESERVING-WHITESPACE [input-stream [eof-error-p [eof-value [recursive-p]]]]),
# CLTL p. 376
  {
    return_Values read_w(T); # whitespace-p := T
  }

LISPFUN(read_delimited_list,1,2,norest,nokey,0,NIL)
# (READ-DELIMITED-LIST char [input-stream [recursive-p]]), CLTL p. 377
  {
    # check char:
    var object ch = STACK_2;
    if (!charp(ch))
      fehler_char(ch);
    # check input-stream:
    test_istream(&STACK_1);
    # check for recursive-p-Argument:
    var object recursive_p = popSTACK();
    # stack layout: char, input-stream.
    if (eq(recursive_p,unbound) || nullp(recursive_p)) {
      # non-recursive call
      var object* stream_ = &STACK_0;
      # bind SYS::*READ-REFERENCE-TABLE* to empty Table NIL:
      dynamic_bind(S(read_reference_table),NIL);
      # bind SYS::*BACKQUOTE-LEVEL* to NIL:
      dynamic_bind(S(backquote_level),NIL);
      var object obj = read_delimited_list(stream_,ch,eof_value); # read List
      obj = make_references(obj); # unentangle references
      dynamic_unbind();
      dynamic_unbind();
      value1 = obj; # List as value
    } else {
      # recursive call
      value1 = read_delimited_list(&STACK_0,ch,eof_value);
    }
    # (read List both times, no Dotted List allowed.)
    mv_count=1; skipSTACK(2);
  }

LISPFUN(read_line,0,4,norest,nokey,0,NIL)
# (READ-LINE [input-stream [eof-error-p [eof-value [recursive-p]]]]),
# CLTL p. 378
# This implementation always returns a simple string, if end-of-stream
# is not encountered immediately.  Code in debug.io depends on this.
  {
    # check input-stream:
    var object* stream_ = &STACK_3;
    test_istream(stream_);
    get_buffers(); # two empty Buffers on Stack
    if (!read_line(stream_,&STACK_1)) { # read line
      # End of Line
      # copy Buffer and convert into Simple-String:
      value1 = copy_string(STACK_1);
      # free Buffer for reuse:
      O(token_buff_2) = popSTACK(); O(token_buff_1) = popSTACK();
      value2 = NIL; mv_count=2; # NIL as 2. value
      skipSTACK(4); return;
    } else {
      # End of File
      # Buffer empty?
      if (TheIarray(STACK_1)->dims[1] == 0) { # Length (Fill-Pointer) = 0 ?
        # free Buffer for reuse:
        O(token_buff_2) = popSTACK(); O(token_buff_1) = popSTACK();
        # treat EOF specially:
        value2 = T;
        return_Values eof_handling(2);
      } else {
        # copy Buffer and convert into Simple-String:
        value1 = copy_string(STACK_1);
        # free Buffer for reuse:
        O(token_buff_2) = popSTACK(); O(token_buff_1) = popSTACK();
        value2 = T; mv_count=2; # T as 2. value
        skipSTACK(4); return;
      }
    }
  }

LISPFUN(read_char,0,4,norest,nokey,0,NIL)
# (READ-CHAR [input-stream [eof-error-p [eof-value [recursive-p]]]]),
# CLTL p. 379
  {
    # check input-stream:
    var object* stream_ = &STACK_3;
    test_istream(stream_);
    var object ch = read_char(stream_); # read Character
    if (eq(ch,eof_value)) {
      return_Values eof_handling(1);
    } else {
      value1 = ch; mv_count=1; skipSTACK(4); return; # ch as value
    }
  }

LISPFUN(unread_char,1,1,norest,nokey,0,NIL)
# (UNREAD-CHAR char [input-stream]), CLTL p. 379
  {
    # check input-stream:
    var object* stream_ = &STACK_0;
    test_istream(stream_);
    var object ch = STACK_1; # char
    if (!charp(ch)) # must be a character
      fehler_char(ch);
    unread_char(stream_,ch); # push back char to Stream
    value1 = NIL; mv_count=1; skipSTACK(2); # NIL as value
  }

LISPFUN(peek_char,0,5,norest,nokey,0,NIL)
# (PEEK-CHAR [peek-type [input-stream [eof-error-p [eof-value [recursive-p]]]]]),
# CLTL p. 379
  {
    # check input-stream:
    var object* stream_ = &STACK_3;
    test_istream(stream_);
    # distinction of cases by peek-type:
    var object peek_type = STACK_4;
    if (eq(peek_type,unbound) || nullp(peek_type)) {
      # Default NIL: peek one character
      var object ch = peek_char(stream_);
      if (eq(ch,eof_value))
        goto eof;
      value1 = ch; mv_count=1; skipSTACK(5); return; # ch as value
    } else if (eq(peek_type,T)) {
      # T: Whitespace-Peek
      var object ch = wpeek_char_eof(stream_);
      if (eq(ch,eof_value))
        goto eof;
      value1 = ch; mv_count=1; skipSTACK(5); return; # ch as value
    } else if (charp(peek_type)) {
      # peek-type is a Character
      var object ch;
      loop {
        ch = read_char(stream_); # read character
        if (eq(ch,eof_value))
          goto eof;
        if (eq(ch,peek_type)) # the preset End-character?
          break;
      }
      unread_char(stream_,ch); # push back character
      value1 = ch; mv_count=1; skipSTACK(5); return; # ch as value
    } else {
      pushSTACK(peek_type);        # TYPE-ERROR slot DATUM
      pushSTACK(O(type_peektype)); # TYPE-ERROR slot EXPECTED-TYPE
      pushSTACK(peek_type);
      pushSTACK(TheSubr(subr_self)->name);
      fehler(type_error,
             GETTEXT("~: peek type should be NIL or T or a character, not ~"));
    }
   eof: # EOF
    eof_handling(1); skipSTACK(1); return;
  }

LISPFUN(listen,0,1,norest,nokey,0,NIL)
# (LISTEN [input-stream]), CLTL p. 380
  {
    test_istream(&STACK_0); # check input-stream
    if (ls_avail_p(listen_char(popSTACK()))) {
      value1 = T; mv_count=1; # value T
    } else {
      value1 = NIL; mv_count=1; # value NIL
    }
  }

LISPFUNN(read_char_will_hang_p,1)
# (READ-CHAR-WILL-HANG-P input-stream)
# tests whether READ-CHAR-NO-HANG will return immediately without reading a
# character, but accomplishes this without actually calling READ-CHAR-NO-HANG,
# thus avoiding the need for UNREAD-CHAR and preventing side effects.
  {
    test_istream(&STACK_0); # check input-stream
    value1 = (ls_wait_p(listen_char(popSTACK())) ? T : NIL); mv_count=1;
  }

LISPFUN(read_char_no_hang,0,4,norest,nokey,0,NIL)
# (READ-CHAR-NO-HANG [input-stream [eof-error-p [eof-value [recursive-p]]]]),
# CLTL p. 380
  {
    # check input-stream:
    var object* stream_ = &STACK_3;
    test_istream(stream_);
    var object stream = *stream_;
    if (builtin_stream_p(stream)
        ? !(TheStream(stream)->strmflags & bit(strmflags_rd_ch_bit_B))
        : !instanceof(stream,O(class_fundamental_input_stream)))
      fehler_illegal_streamop(S(read_char_no_hang),stream);
    var signean status = listen_char(stream);
    if (ls_eof_p(status)) { # EOF ?
      return_Values eof_handling(1);
    } else if (ls_avail_p(status)) { # character available
      var object ch = read_char(stream_); # read Character
      if (eq(ch,eof_value)) { # query for EOF, for safety reasons
        return_Values eof_handling(1);
      } else {
        value1 = ch; mv_count=1; skipSTACK(4); return; # ch as value
      }
    } else { # ls_wait_p(status) # no character available
      # instead of waiting, return NIL as value, immediately:
      value1 = NIL; mv_count=1; skipSTACK(4); return;
    }
  }

LISPFUN(clear_input,0,1,norest,nokey,0,NIL)
# (CLEAR-INPUT [input-stream]), CLTL p. 380
  {
    test_istream(&STACK_0); # check input-stream
    clear_input(popSTACK());
    value1 = NIL; mv_count=1; # value NIL
  }

LISPFUN(read_from_string,1,2,norest,key,3,\
        (kw(preserve_whitespace),kw(start),kw(end)) )
# (READ-FROM-STRING string [eof-error-p [eof-value [:preserve-whitespace]
#                   [:start] [:end]]]),
# CLTL p. 380
# Methode:
# (defun read-from-string (string &optional (eof-error-p t) (eof-value nil)
#                          &key (start 0) (end nil) (preserve-whitespace nil)
#                          &aux index)
#   (values
#     (with-input-from-string (stream string :start start :end end :index index)
#       (funcall (if preserve-whitespace #'read-preserving-whitespace #'read)
#                stream eof-error-p eof-value nil
#     ) )
#     index
# ) )
# oder macroexpandiert:
# (defun read-from-string (string &optional (eof-error-p t) (eof-value nil)
#                          &key (start 0) (end nil) (preserve-whitespace nil))
#   (let ((stream (make-string-input-stream string start end)))
#     (values
#       (unwind-protect
#         (funcall (if preserve-whitespace #'read-preserving-whitespace #'read)
#                  stream eof-error-p eof-value nil
#         )
#         (close stream)
#       )
#       (system::string-input-stream-index stream)
# ) ) )
# oder vereinfacht:
# (defun read-from-string (string &optional (eof-error-p t) (eof-value nil)
#                          &key (start 0) (end nil) (preserve-whitespace nil))
#   (let ((stream (make-string-input-stream string start end)))
#     (values
#       (funcall (if preserve-whitespace #'read-preserving-whitespace #'read)
#                stream eof-error-p eof-value nil
#       )
#       (system::string-input-stream-index stream)
# ) ) )
  {
    # stack layout: string, eof-error-p, eof-value, preserve-whitespace, start, end.
    # process :preserve-whitespace-Argument:
    var object preserve_whitespace = STACK_2;
    if (eq(preserve_whitespace,unbound))
      preserve_whitespace = NIL;
    # call MAKE-STRING-INPUT-STREAM with Arguments string, start, end:
    STACK_2 = STACK_5; # string
    if (eq(STACK_1,unbound))
      STACK_1 = Fixnum_0; # start has Default 0
    if (eq(STACK_0,unbound))
      STACK_0 = NIL; # end has Default NIL
    STACK_5 = preserve_whitespace;
    funcall(L(make_string_input_stream),3);
    # stack layout: preserve-whitespace, eof-error-p, eof-value.
    pushSTACK(STACK_1); pushSTACK(STACK_1);
    STACK_3 = STACK_2 = value1;
    # stack layout: preserve-whitespace, stream, stream, eof-error-p, eof-value.
    pushSTACK(NIL); read_w(STACK_5); # READ respectively READ-PRESERVE-WHITESPACE
    # stack layout: preserve-whitespace, stream.
    STACK_1 = value1; # read Objekt
    funcall(L(string_input_stream_index),1); # (SYS::STRING-INPUT-STREAM-INDEX stream)
    value2 = value1; value1 = popSTACK(); # Index as 2., Objekt as 1. value
    mv_count=2;
  }

LISPFUN(parse_integer,1,0,norest,key,4,\
        (kw(start),kw(end),kw(radix),kw(junk_allowed)) )
# (PARSE-INTEGER string [:start] [:end] [:radix] [:junk-allowed]), CLTL p. 381
  {
    # process :junk-allowed-Argument:
    var bool junk_allowed;
    {
      var object arg = popSTACK();
      if (eq(arg,unbound) || nullp(arg))
        junk_allowed = false;
      else
        junk_allowed = true;
    }
    # junk_allowed = value of :junk-allowed-Argument.
    # process :radix-Argument:
    var uintL base;
    {
      var object arg = popSTACK();
      if (eq(arg,unbound)) {
        base = 10; # Default 10
      } else {
        if (posfixnump(arg) &&
            (base = posfixnum_to_L(arg), ((base >= 2) && (base <= 36)))) {
          # OK
        } else {
          pushSTACK(arg);           # TYPE-ERROR slot DATUM
          pushSTACK(O(type_radix)); # TYPE-ERROR slot EXPECTED-TYPE
          pushSTACK(arg); # base
          pushSTACK(S(Kradix));
          pushSTACK(TheSubr(subr_self)->name);
          fehler(type_error,
                 GETTEXT("~: ~ argument should be an integer between 2 and 36, not ~"));
        }
      }
    }
    # base = value of :radix-argument.
    # check string, :start and :end:
    var stringarg arg;
    var object string = test_string_limits_ro(&arg);
    # STACK is not cleared up.
    var uintL start = arg.index; # value of :start-argument
    var uintL len = arg.len; # number of the addressed characters
    var const chart* charptr;
    unpack_sstring_alloca(arg.string,arg.len,arg.offset+arg.index, charptr=);
    # loop variables:
    var uintL index = start;
    var uintL count = len;
    var uintL start_offset;
    var uintL end_offset;
    # and now:
    #   string : the string,
    #   arg.string : its data-vector (a simple-string),
    #   start : index of the first character in the string
    #   charptr : pointer in the data-vector of the next character,
    #   index : index in the string,
    #   count : the number of remaining characters.
    var signean sign;
    {
      var chart c; # the last character read
      # step 1: skip whitespace
      loop {
        if (count==0) # the string has already ended?
          goto badsyntax;
        c = *charptr; # the next character
        if (!(orig_syntax_table_get(c) == syntax_whitespace)) # no whitespace?
          break;
        charptr++; index++; count--; # skip whitespace
      }
      # step 2: read the sign
      sign = 0; # sign := positive
      switch (as_cint(c)) {
        case '-': sign = -1; # sign := negative
        case '+': # sign found
          charptr++; index++; count--; # skip
          if (count==0) # the string has already ended?
            goto badsyntax;
        default: break;
      }
    }
    # done with sign, still should be (count>0).
    start_offset = arg.offset + index;
    # now:  start_offset = offset of the first digit in the data vector
    # step 3: read digits
    loop {
      var cint c = as_cint(*charptr); # the next character
      # check the digits: (digit-char-p (code-char c) base) ?
      # (cf. DIGIT-CHAR-P in CHARSTRG.D)
      if (c > 'z') break; # too large -> no
      if (c >= 'a') { c -= 'a'-'A'; } # upcase 'a'<= char <='z'
      # now $00 <= c <= $60.
      if (c < '0') break;
      # $30 <= c <= $60 convert to the numeric value
      if (c <= '9')
        c = c - '0';
      else if (c >= 'A')
        c = c - 'A' + 10;
      else
        break;
      # now 0 =< c <=41 is the numeric value of the digit
      if (c >= (uintB)base) # only valid if 0 <= c < base.
        break;
      # *charptr is a valid digit.
      charptr++; index++; count--; # skip
      if (count==0)
        break;
    }
    # done with the digit.
    end_offset = arg.offset + index;
    # now:  end_offset = offset after the last digit in the data-vector.
    if (start_offset == end_offset) # there were no digits?
      goto badsyntax;
    # step 4: skip the final whitespace
    if (!junk_allowed) { # if junk_allowed, nothing is to be done
      while (!(count==0)) {
        var chart c = *charptr; # the next character
        if (!(orig_syntax_table_get(c) == syntax_whitespace)) # no whitespace?
          goto badsyntax;
        charptr++; index++; count--; # skip whitespace
      }
    }
    # step 5: convert the sequence of digits into a number
    value1 = read_integer(base,sign,arg.string,start_offset,end_offset);
    value2 = fixnum(index);
    mv_count=2; return;
   badsyntax: # illegal character
    if (!junk_allowed) { # signal an error
      pushSTACK(unbound); # STREAM-ERROR slot STREAM
      pushSTACK(string);
      pushSTACK(TheSubr(subr_self)->name);
      fehler(stream_error,
             GETTEXT("~: string ~ does not have integer syntax"));
    }
    value1 = NIL;
    value2 = fixnum(index);
    mv_count=2; return;
  }


# =============================================================================
#                              P R I N T
# =============================================================================

# The basic idea of the printer:
# Depending on the datatype, the external representation of the
# object is output to the stream, recursively.
# The difference between PRINT and PPRINT is, that on a few occasions
# a Space is emitted instead of a Newline and a few Spaces.
# In order to achieve this, the external representation of the sub-objects
# is output to a auxiliary Pretty-Printer-(PPHELP-)Stream, then checked
# whether several lines are needed or one is sufficient, and finally
# (depending on this) Whitespace is inserted.
# The more detailed specification of the prin_object-routine:
# > Stream,
# > Line length L,
# > Left border for single-liner L1,
# > Left border for mulit-liner LM,
# > Number of parentheses that remain to be closed on the last line at the end
#   K (Fixnum >=0) and Flag, if the last closing parentheses of multi-liners
#   are to be printed on a separate line, placed below the corresponding
#   opening parentheses.
#   [For simplicity,  K=0 and Flag=True, i.e. all
#   closing parentheses of multi-liners appear on their own line.]
# < Stream, to which the object was output,
#   either as single-liner (of length <=L-L1-K)
#   or as multiliner (with Newline and LM Spaces instead of Space between
#   subobjects), each line (if possible) of length <=L, last line
#   (if possible) of length <=L-K.
# < if stream is a PPHELP-Stream, it contains the mode (state) and a
#   non-empty list of the output lines (in reversed order).

# a pr_xxx-Routine receives &stream und obj as argument:
typedef void pr_routine_t (const object* stream_, object obj);

# ---------------------- common sub-routines ----------------------------

# UP: Outputs an unsigned integer with max. 32 Bit decimally to the Stream.
# pr_uint(&stream,uint);
# > uint: Unsigned Integer
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_uint (const object* stream_, uintL x) {
  var uintB ziffern[10]; # max. 10 digits, as 0 <= x < 2^32 <= 10^10
  var uintB* ziffptr = &ziffern[0];
  var uintC ziffcount = 0; # number of digits
  # produce digits:
  do {
    var uintB zif;
    divu_3216_3216(x,10,x=,zif=); # x := floor(x/10), zif := Rest
    *ziffptr++ = zif; ziffcount++; # save digit
  } until (x==0);
  # ouput digits in reversed order:
  dotimespC(ziffcount,ziffcount, {
    write_ascii_char(stream_,'0' + *--ziffptr);
  });
}

# UP: outputs a Nibble hexadecimally (with 1 hex-digit) to stream.
# pr_hex1(&stream,x);
# > x: Nibble (>=0,<16)
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_hex1 (const object* stream_, uint4 x) {
  write_ascii_char(stream_, ( x<10 ? '0'+(uintB)x : 'A'+(uintB)x-10 ) );
}

# UP: outputs a byte hexadecimally (with 2 hex-digits) to stream.
# pr_hex2(&stream,x);
# > x: Byte
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_hex2 (const object* stream_, uint8 x) {
  pr_hex1(stream_,(uint4)(x>>4)); # output Bits 7..4
  pr_hex1(stream_,(uint4)(x & (bit(4)-1))); # output Bits 3..0
}

# UP: outputs an address with 24 Bit hexadecimally (with 6 hex-digits)
# to Stream.
# pr_hex6(&stream,obj);
# > addressbits of obj: unsigned integer
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_hex6 (const object* stream_, object obj) {
  var oint x = (as_oint(obj) >> oint_addr_shift) << addr_shift;
  write_ascii_char(stream_,'#'); write_ascii_char(stream_,'x'); # Prefix for "Hexadecimal"
#define pr_hexpart(k)  # output bits k+7..k:  \
        if (((oint_addr_mask>>oint_addr_shift)<<addr_shift) & minus_wbit(k)) \
          { pr_hex2(stream_,(uint8)((x >> k) & (((oint_addr_mask>>oint_addr_shift)<<addr_shift) >> k) & 0xFF)); }
#ifdef WIDE_HARD
  pr_hexpart(56);
  pr_hexpart(48);
  pr_hexpart(40);
  pr_hexpart(32);
#endif
  pr_hexpart(24);
  pr_hexpart(16);
  pr_hexpart(8);
  pr_hexpart(0);
#undef pr_hexpart
}

#ifdef FOREIGN
# UP: outputs an address with 32 bit hexadecimally (with 8 hex-digits)
# to Stream.
# pr_hex8(&stream,x);
# > x: address
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_hex8 (const object* stream_, uintP x) {
  # Prefix for "Hexadecimal"
  write_ascii_char(stream_,'#'); write_ascii_char(stream_,'x');
  var sintC k = (sizeof(uintP)-1)*8;
  do { pr_hex2(stream_,(uint8)(x >> k));
  } while ((k -= 8) >= 0);
}
#endif

# *PRINT-READABLY* /= NIL causes among other things implicitely the same as
# *PRINT-ESCAPE* = T, *PRINT-BASE* = 10, *PRINT-RADIX* = T,
# *PRINT-CIRCLE* = T, *PRINT-LEVEL* = NIL, *PRINT-LENGTH* = NIL,
# *PRINT-LINES* = NIL,
# *PRINT-GENSYM* = T, *PRINT-ARRAY* = T, *PRINT-CLOSURE* = T.

# error-message when *PRINT-READABLY* /= NIL.
# fehler_print_readably(obj); english: error_print_readably(obj);
nonreturning_function(local, fehler_print_readably, (object obj)) {
  # (error-of-type 'print-not-readable
  #        "~: Despite of ~, ~ cannot be printed readably."
  #        'print '*print-readably* obj
  # )
  dynamic_bind(S(print_readably),NIL); # bind *PRINT-READABLY* to NIL
  pushSTACK(obj); # PRINT-NOT-READABLE slot OBJECT
  pushSTACK(obj);
  pushSTACK(S(print_readably));
  pushSTACK(S(print));
  fehler(print_not_readable,
         GETTEXT("~: Despite of ~, ~ cannot be printed readably."));
}
#define CHECK_PRINT_READABLY(obj)               \
      if (test_value(S(print_readably)))        \
        fehler_print_readably(obj);

# error message for inadmissible value of *PRINT-CASE*.
# fehler_print_case(); english: error_print_case();
nonreturning_function(local, fehler_print_case, (void)) {
  # (error "~: the value ~ of ~ is neither ~ nor ~ nor ~.
  #         it is reset to ~."
  #        'print *print-case* '*print-case* ':upcase ':downcase ':capitalize
  #        ':upcase
  # )
  var object print_case = S(print_case);
  pushSTACK(Symbol_value(print_case)); # TYPE-ERROR slot DATUM
  pushSTACK(O(type_printcase));        # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(S(Kupcase));     # :UPCASE
  pushSTACK(S(Kcapitalize)); # :CAPITALIZE
  pushSTACK(S(Kdowncase));   # :DOWNCASE
  pushSTACK(S(Kupcase));     # :UPCASE
  pushSTACK(print_case);
  pushSTACK(Symbol_value(print_case));
  pushSTACK(S(print));
  Symbol_value(print_case) = S(Kupcase); # (setq *PRINT-CASE* ':UPCASE)
  fehler(type_error,
         GETTEXT("~: the value ~ of ~ is neither ~ nor ~ nor ~." NLstring
                 "It is reset to ~."));
}

# Macro: retrieves value of *PRINT-CASE* and branches appropriately.
# switch_print_case(upcase_statement,downcase_statement,capitalize_statement);
#define switch_print_case(upcase_statement,downcase_statement,capitalize_statement)  \
    {var object print_case = Symbol_value(S(print_case)); # value of *PRINT-CASE* \
     if (eq(print_case,S(Kupcase))) # = :UPCASE ?              \
       { upcase_statement }                                    \
     else if (eq(print_case,S(Kdowncase))) # = :DOWNCASE ?     \
       { downcase_statement }                                  \
     else if (eq(print_case,S(Kcapitalize))) # = :CAPITALIZE ? \
       { capitalize_statement }                                \
     else # none of the three -> Error                         \
       { fehler_print_case(); }                                \
    }

# UP: prints a part of a simple-string elementwise to stream.
# write_sstring_ab(&stream,string,start,len);
# > string: simple-string
# > start: startindex
# > len: number of to-be-printed characters
# > stream: Stream
# < stream: Stream
# can trigger GC
local void write_sstring_ab (const object* stream_, object string,
                             uintL start, uintL len) {
  if (len==0) return;
  pushSTACK(string);
  write_char_array(stream_,&STACK_0,start,len);
  skipSTACK(1);
}

# UP: prints simple-string elementwise to stream.
# write_sstring(&stream,string);
# > string: simple-string
# > stream: Stream
# < stream: Stream
# can trigger GC
global void write_sstring (const object* stream_, object string) {
  write_sstring_ab(stream_,string,0,Sstring_length(string));
}

# UP: prints string elementwise to stream.
# write_string(&stream,string);
# > string: String
# > stream: Stream
# < stream: Stream
# can trigger GC
global void write_string (const object* stream_, object string) {
  if (simple_string_p(string)) { # Simple-String
    write_sstring(stream_,string);
  } else { # non-simpler String
    var uintL len = vector_length(string); # length
    var uintL offset = 0; # offset of string in the data-vector
    var object sstring = iarray_displace_check(string,len,&offset); # data-vector
    write_sstring_ab(stream_,sstring,offset,len);
  }
}

# UP: prints simple-string according to (READTABLE-CASE *READTABLE*) and
# *PRINT-CASE* to stream.
# write_sstring_case(&stream,string);
# > string: Simple-String
# > stream: Stream
# < stream: Stream
# can trigger GC
local void write_sstring_case (const object* stream_, object string) {
# retrieve (READTABLE-CASE *READTABLE*):
  var object readtable;
  get_readtable(readtable = ); # current readtable
  switch (RTCase(readtable)) {
    case case_upcase:
      # retrieve *PRINT-CASE* - determines how the upper case characters
      # are printed; lower case characters are always printed lower case.
      switch_print_case(
      # :UPCASE -> print upper case characters in Upcase:
      {
        write_sstring(stream_,string);
      },
      # :DOWNCASE -> print upper case characters in Downcase:
      do_downcase:
      {
        var uintL count = Sstring_length(string);
        if (count > 0) {
          var uintL index = 0;
          pushSTACK(string); # save simple-string
          SstringDispatch(string,{
            dotimespL(count,count, {
              write_code_char(stream_,down_case(TheSstring(STACK_0)->data[index]));
              index++;
            });
          },{
            dotimespL(count,count, {
              write_code_char(stream_,down_case(as_chart(TheSmallSstring(STACK_0)->data[index])));
              index++;
            });
          });
          skipSTACK(1);
        }
      },
      # :CAPITALIZE -> print the first uppercase letter of word
      # as upper case letter, all other letters as lower case.
      # (cf. NSTRING_CAPITALIZE in CHARSTRG.D)
      # First Version:
      #   (lambda (s &aux (l (length s)))
      #     (prog ((i 0) c)
      #       1 ; search from here the next beginning of a word
      #         (if (= i l) (return))
      #         (setq c (char s i))
      #         (unless (alphanumericp c) (write-char c) (incf i) (go 1))
      #       ; found beginning of word
      #       (write-char c) (incf i) ; upper case --> upper case
      #       2 ; within a word
      #         (if (= i l) (return))
      #         (setq c (char s i))
      #         (unless (alphanumericp c) (write-char c) (incf i) (go 1))
      #         (write-char (char-downcase c)) ; upper case --> lower case
      #         (incf i) (go 2)
      #   ) )
      # Exactly those characters are printed with char-downcase, which
      # were preceded by an alphanumeric character and which are
      # alphanumeric themselves.
      # [As all Uppercase-Characters (according to CLTL p. 236 top) are
      #  alphabetic and thus also alphanumeric and char-downcase does not
      #  change anything on the other characters:
      #  Exactly those characters  are printed with char-downcase,
      #  which were preceded by an alphanumeric character.
      #  We don't use this.]
      # Second version:
      #   (lambda (s &aux (l (length s)))
      #     (prog ((i 0) c (flag nil))
      #       1 (if (= i l) (return))
      #         (setq c (char s i))
      #         (let ((newflag (alphanumericp c)))
      #           (when (and flag newflag) (setq c (char-downcase c)))
      #           (setq flag newflag)
      #         )
      #         (write-char c) (incf i) (go 1)
      #   ) )
      # Third Version:
      #   (lambda (s &aux (l (length s)))
      #     (prog ((i 0) c (flag nil))
      #       1 (if (= i l) (return))
      #         (setq c (char s i))
      #         (when (and (shiftf flag (alphanumericp c)) flag)
      #           (setq c (char-downcase c))
      #         )
      #         (write-char c) (incf i) (go 1)
      #   ) )
      {
        var uintL count = Sstring_length(string);
        if (count > 0) {
          var bool flag = false;
          var uintL index = 0;
          pushSTACK(string); # save simple-string
          SstringDispatch(string,{
            dotimespL(count,count, {
              # flag indicates whether within a word
              var bool oldflag = flag;
              var chart c = TheSstring(STACK_0)->data[index]; # next character
              if ((flag = alphanumericp(c)) && oldflag)
                # alphanumeric character in word:
                c = down_case(c); # upper case --> lower case
              write_code_char(stream_,c); # and print
              index++;
            });
          },{
            dotimespL(count,count, {
              # flag indicates whether within a word
              var bool oldflag = flag;
              var chart c = as_chart(TheSmallSstring(STACK_0)->data[index]); # next character
              if ((flag = alphanumericp(c)) && oldflag)
                # alphanumeric character in word:
                c = down_case(c); # upper case --> lower case
              write_code_char(stream_,c); # and print
              index++;
            });
          });
          skipSTACK(1);
        }
      });
      break;
    case case_downcase:
      # retrieve *PRINT-CASE* - determines how the lower case characters
      # are printed; upper case characters are always printed upper case.
      switch_print_case(
      # :UPCASE -> print lower case letters in Upcase:
      do_upcase:
      {
        var uintL count = Sstring_length(string);
        if (count > 0) {
          var uintL index = 0;
          pushSTACK(string); # save simple-string
          SstringDispatch(string,{
            dotimespL(count,count, {
              write_code_char(stream_,up_case(TheSstring(STACK_0)->data[index]));
              index++;
            });
          },{
            dotimespL(count,count, {
              write_code_char(stream_,up_case(as_chart(TheSmallSstring(STACK_0)->data[index])));
              index++;
            });
          });
          skipSTACK(1);
        }
      },
      # :DOWNCASE -> print lower case letters in Downcase:
      {
        write_sstring(stream_,string);
      },
      # :CAPITALIZE -> print the first lower case letter of word
      # as upper case letter, all other letters as lower case.
      # (ref. NSTRING_CAPITALIZE in CHARSTRG.D)
      # first Version:
      #   (lambda (s &aux (l (length s)))
      #     (prog ((i 0) c)
      #       1 ; search from here the next beginning of a word
      #         (if (= i l) (return))
      #         (setq c (char s i))
      #         (unless (alphanumericp c) (write-char c) (incf i) (go 1))
      #       ; found beginning of word
      #       (write-char (char-upcase c)) ; lower case --> upper case
      #       (incf i)
      #       2 ; within a word
      #         (if (= i l) (return))
      #         (setq c (char s i))
      #         (unless (alphanumericp c) (write-char c) (incf i) (go 1))
      #         (write-char c) ; lower case --> lower case
      #         (incf i) (go 2)
      #   ) )
      # Exactly those characters are printed with char-upcase,
      # which were not preceded by an alphanumeric character but
      # which are alphanumeric themselves.
      # Second version:
      #   (lambda (s &aux (l (length s)))
      #     (prog ((i 0) c (flag nil))
      #       1 (if (= i l) (return))
      #         (setq c (char s i))
      #         (when (and (not (shiftf flag (alphanumericp c))) flag)
      #           (setq c (char-upcase c))
      #         )
      #         (write-char c) (incf i) (go 1)
      #   ) )
      {
        var uintL count = Sstring_length(string);
        if (count > 0) {
          var bool flag = false;
          var uintL index = 0;
          pushSTACK(string); # save simple-string
          SstringDispatch(string,{
            dotimespL(count,count, {
              # flag indicates whether within a word
              var bool oldflag = flag;
              var chart c = TheSstring(STACK_0)->data[index]; # next character
              if ((flag = alphanumericp(c)) && !oldflag)
                # alphanumeric character at the beginning of word:
                c = up_case(c); # lower case --> upper case
              write_code_char(stream_,c); # and print
              index++;
            });
          },{
            dotimespL(count,count, {
              # flag indicates whether within a word
              var bool oldflag = flag;
              var chart c = as_chart(TheSmallSstring(STACK_0)->data[index]); # next character
              if ((flag = alphanumericp(c)) && !oldflag)
                # alphanumeric character at the beginning of word:
                c = up_case(c); # lower case --> upper case
              write_code_char(stream_,c); # and print
              index++;
            });
          });
          skipSTACK(1);
        }
      });
      break;
    case case_preserve:
      # ignore *PRINT-CASE*.
      write_sstring(stream_,string);
      break;
    case case_invert:
      # ignore *PRINT-CASE*.
      {
        var bool seen_uppercase = false;
        var bool seen_lowercase = false;
        var uintL count = Sstring_length(string);
        if (count > 0) {
          SstringDispatch(string,{
            var const chart* cptr = &TheSstring(string)->data[0];
            dotimespL(count,count, {
              var chart c = *cptr++;
              if (!chareq(c,up_case(c)))
                seen_lowercase = true;
              if (!chareq(c,down_case(c)))
                seen_uppercase = true;
            });
          },{
            var const scint* cptr = &TheSmallSstring(string)->data[0];
            dotimespL(count,count, {
              var chart c = as_chart(*cptr++);
              if (!chareq(c,up_case(c)))
                seen_lowercase = true;
              if (!chareq(c,down_case(c)))
                seen_uppercase = true;
            });
          });
        }
        if (seen_uppercase) {
          if (!seen_lowercase)
            goto do_downcase;
        } else {
          if (seen_lowercase)
            goto do_upcase;
        }
        write_sstring(stream_,string);
      }
      break;
    default: NOTREACHED;
  }
}

# UP: prints a number of Spaces to stream.
# spaces(&stream,anzahl); english: spaces(&stream,number_of_spaces);
# > anzahl: number of Spaces (Fixnum>=0)
# > stream: Stream
# < stream: Stream
# can trigger GC
local void spaces (const object* stream_, object anzahl) {
  var uintL count;
 #ifdef IO_DEBUG
  ASSERT(posfixnump(anzahl));
 #endif
  dotimesL(count,posfixnum_to_L(anzahl), {
    write_ascii_char(stream_,' ');
  });
}

# ------------------- Sub-Routines for Pretty-Print -------------------------

# Variables:
# ==========

# line-length L                   value of SYS::*PRIN-LINELENGTH*,
#                                  Fixnum>=0 or NIL
# line-position                   in PPHELP-Stream, Fixnum>=0
# Left border L1 for single-liner value of SYS::*PRIN-L1*, Fixnum>=0
# Left border LM for multi-liner  value of SYS::*PRIN-LM*, Fixnum>=0
# Mode                            in PPHELP-Stream:
#              NIL for single-liner (einzeiler)
#              T   for multi-liner  (mehrzeiler)
  #define einzeiler NIL
  #define mehrzeiler T

# components of a Pretty-Print-Help-Streams:
#   strm_pphelp_lpos     Line Position (Fixnum>=0)
#   strm_pphelp_strings  non-empty list of
#                          Semi-Simple-Strings and
#                          (newline-keyword . indentation) and
#                          tab_spec = #(colon atsig col_num col_inc)
#                        They contain the recent output (in reversed
#                        order: last line as CAR);
#   strm_pphelp_modus    Mode: single-liner, if there is only 1 String and
#                        it contains no NL, otherwise it's a multi-liner.
# WRITE-CHAR always pushes its Character only to the last line
# and updates lpos and modus.

# during Justify:
# previous content of the Streams    values of SYS::*PRIN-JBSTRINGS*,
#                                    SYS::*PRIN-JBMODUS*, SYS::*PRIN-JBLPOS*
# previous blocks (list of blocks,
# multiline block = non-empty list of Semi-Simple-Strings,
# single-line block = Semi-Simple-String)
#                                value of SYS::*PRIN-JBLOCKS*

# for compliance/adherence to *PRINT-LEVEL*:
# SYS::*PRIN-LEVEL*              current output-depth (Fixnum>=0)

# for readability of backquote-expressions:
# SYS::*PRIN-BQLEVEL*            current backquote-depth (Fixnum>=0)

# when thread-of-control leaves the printer:
# SYS::*PRIN-STREAM*             current Stream (Default: NIL),
# in order to recognize a recursive PRINT or WRITE.

# for compliance/adherence to *PRINT-LENGTH*:
# limitation of length   (uintL >=0 oder ~0)       local
# previous length        (uintL >=0)               local

# for pretty printing of parentheses:
# *PRINT-RPARS* (T or NIL) indicates, if parentheses are to be printed
# in an extra line as "   ) ) )" or not.
# SYS::*PRIN-RPAR* = position of the last opening parenthesis (Fixnum>=0,
#                    or NIL if the closing parenthesis should be moved to the
#                    end of the line and not below the opening parenthesis)

# UP: this is a PPHELP helper - used here and in stream.d
# (setf (strm-pphelp-strings *stream_)
#   (list* (make-Semi-Simple-String 50)
#          (cons nl_type *PRIN-INDENTATION*)
#          (strm-pphelp-strings *stream_))
# can trigger GC
global object cons_ssstring (const object* stream_, object nl_type) {
  var object indent = Symbol_value(S(prin_indentation));
  if (eq(unbound,indent)) indent = Fixnum_0;
  pushSTACK(indent);
  pushSTACK(nl_type);
  var object new_cons = allocate_cons();
  Car(new_cons) = popSTACK();
  Cdr(new_cons) = popSTACK();
  pushSTACK(new_cons); # = (nl . ident)
  new_cons = allocate_cons();
  Car(new_cons) = popSTACK(); # new_cons = ((nl . ident) . nil)
  if ((stream_ != NULL) &&
      stringp(Car(TheStream(*stream_)->strm_pphelp_strings)) &&
      vector_length(Car(TheStream(*stream_)->strm_pphelp_strings)) == 0) {
    Cdr(new_cons) = Cdr(TheStream(*stream_)->strm_pphelp_strings);
    Cdr(TheStream(*stream_)->strm_pphelp_strings) = new_cons;
    new_cons = TheStream(*stream_)->strm_pphelp_strings;
  } else {
    pushSTACK(new_cons);
    pushSTACK(make_ssstring(50));
    new_cons = allocate_cons();
    Car(new_cons) = popSTACK();
    Cdr(new_cons) = popSTACK(); # new_cons = ("" (nl . ident))
    if (stream_ != NULL) {
      Cdr(Cdr(new_cons)) = TheStream(*stream_)->strm_pphelp_strings;
      TheStream(*stream_)->strm_pphelp_strings = new_cons;
    }
  }
 #if IO_DEBUG > 1
  PPH_OUT(cons_ssstring,*stream_);
 #endif
  return new_cons;
}
# access the NL type and indentation
#ifdef IO_DEBUG
  #define PPHELP_NL_TYPE(o) (mconsp(o) ? Car(o) : (NOTREACHED,nullobj))
  #define PPHELP_INDENTN(o) (mconsp(o) ? Cdr(o) : (NOTREACHED,nullobj))
#else
  #define PPHELP_NL_TYPE Car
  #define PPHELP_INDENTN Cdr
#endif

# UP: tabulation (see format-tabulate here in io.d and in format.lisp)
#define PPH_TAB_COLON(tab_spec) TheSvector(tab_spec)->data[0]
#define PPH_TAB_ATSIG(tab_spec) TheSvector(tab_spec)->data[1]
#define PPH_TAB_COL_N(tab_spec) TheSvector(tab_spec)->data[2]
#define PPH_TAB_COL_I(tab_spec) TheSvector(tab_spec)->data[3]
#ifdef IO_DEBUG
#define PPH_FORMAT_TAB(out,spec)                                \
  (!vectorp(spec) || 4 != vector_length(spec) ? NOTREACHED,0 :  \
   format_tab(out,PPH_TAB_COLON(spec),PPH_TAB_ATSIG(spec),      \
              PPH_TAB_COL_N(spec),PPH_TAB_COL_I(spec)))
#else
#define PPH_FORMAT_TAB(out,spec)                                \
  format_tab(out,PPH_TAB_COLON(spec),PPH_TAB_ATSIG(spec),       \
             PPH_TAB_COL_N(spec),PPH_TAB_COL_I(spec))
#endif
local uintL format_tab (object stream, object colon_p, object atsig_p,
                        object col_num, object col_inc) {
  var uintL col_num_i;
  if (nullp(col_num)) col_num_i = 1;
  else if (posfixnump(col_num)) col_num_i = posfixnum_to_L(col_num);
  else NOTREACHED; # fehler_posfixnum(col_num);
  var uintL col_inc_i;
  if (nullp(col_inc)) col_inc_i = 1;
  else if (posfixnump(col_inc)) col_inc_i = posfixnum_to_L(col_inc);
  else NOTREACHED; # fehler_posfixnum(col_inc);
  var uintL new_col_i = col_num_i +
    (!nullp(colon_p) && !eq(unbound,Symbol_value(S(prin_indentation)))
     ? posfixnum_to_L(Symbol_value(S(prin_indentation))) : 0);
  var uintL new_inc_i = (col_inc_i == 0 ? 1 : col_inc_i);
  var object pos = get_line_position(stream);
  var uintL pos_i = (nullp(pos) ? (uintL)-1 : posfixnum_to_L(pos));
 #if IO_DEBUG > 1
  printf("format_tab[%s%s]: cn=%d ci=%d nc=%d ni=%d p=%d ==> ",
         (nullp(atsig_p)?"":"@"),(nullp(colon_p)?"":":"),col_num_i,
         col_inc_i,new_col_i,new_inc_i,pos_i);
 #endif
  var uintL ret;
  # MSVC6 has broken %, so both arguments to % must be non-negative!
  if (nullp(atsig_p)) {
    if (nullp(pos)) ret = 2;
    else if (pos_i < new_col_i) ret = new_col_i - pos_i;
    else if (col_inc_i == 0) ret = 0;
    else ret = col_inc_i - (pos_i - new_col_i) % col_inc_i;
  } else {
    if (nullp(pos)) ret = new_col_i;
    else ret = new_col_i +
           (new_inc_i - (pos_i + new_col_i) % new_inc_i) % new_inc_i;
  }
 #if IO_DEBUG > 1
  printf("%d\n",ret);
 #endif
  ASSERT(ret>=0);
  return ret;
}

# Sub-Routines:
# =============

# These work on the stream and must be undone in the right order,
# because they can modify the STACK.

# print the pretty prefix (prefix string and indentation)
# and compute its length
# can trigger GC when stream_ is non-NULL
local uintL pprint_prefix (const object *stream_,object indent) {
  var uintL len = 0;
  var object prefix = Symbol_value(S(prin_line_prefix));
  if (stringp(prefix)) {
    var uintL add = vector_length(prefix);
    len += add;
    if ((stream_ != NULL) && (add != 0))
      write_string(stream_,prefix);
  }
  if (posfixnump(indent)) {
    var uintL add = posfixnum_to_L(indent);
    len += add;
    if ((stream_ != NULL) && (add != 0))
      spaces(stream_,indent);
  }
 #if IO_DEBUG > 1
  printf("pprint_prefix(%s): %d\n",(stream_==NULL?"null":"valid"),len);
 #endif
  return len;
}

# return
#     (- (or *print-right-margin* sys::*prin-linelength*) (pprint_prefix))
local object right_margin (void) {
  var uintL pp_pref_len = pprint_prefix(NULL,Fixnum_0);
  var object prm = Symbol_value(S(print_right_margin));
  if (nullp(prm))
    prm = Symbol_value(S(prin_linelength));
  else if (posfixnump(prm))
    ; # okay
  else if (posbignump(prm))
    prm = fixnum(bit(oint_data_len)-1);
  else {
    pushSTACK(prm); pushSTACK(S(print_right_margin));
    fehler(error,GETTEXT("~: must be a positive integer or NIL, not ~"));
  }
  if (nullp(prm)) return prm; # *PRIN-LINELENGTH* is NIL
  var uintL margin = posfixnum_to_L(prm);
  if (margin <= pp_pref_len) return Fixnum_0;
  else return fixnum(margin - pp_pref_len);
}

# Returns the string-width of a PPHELP stream block.
local uintL pphelp_string_width (object string) {
  var uintL width = 0;
  var uintL len = TheIarray(string)->dims[1]; # length = fill-pointer
  if (len > 0) {
    string = TheIarray(string)->data; # mutable simple-string
    var const chart* charptr = &TheSstring(string)->data[0];
    dotimespL(len,len, {
      width += char_width(*charptr); charptr++;
    });
  }
  return width;
}

# UP: Starts a new line in PPHELP-Stream A5.
# pphelp_newline(&stream);
# > stream: Stream
# < stream: Stream
# can trigger GC
#define LINES_INC                                               \
  do { var object pl = Symbol_value(S(prin_lines));             \
   if (!posfixnump(pl)) fehler_posfixnum(pl);                   \
   if (test_value(S(print_lines)))                              \
     Symbol_value(S(prin_lines)) = fixnum_inc(pl,1); } while(0)
local void pphelp_newline (const object* stream_) {
  # (push (make-ssstring 50) (strm-pphelp-strings stream)) :
  cons_ssstring(stream_,NIL);
  var object stream = *stream_;
  # Line-Position := 0, Modus := multi-liner :
  TheStream(stream)->strm_pphelp_lpos = Fixnum_0;
  TheStream(stream)->strm_pphelp_modus = mehrzeiler;
  LINES_INC;
}

#define PPHELP_STREAM_P(str) \
 (builtin_stream_p(str) && (TheStream(str)->strmtype == strmtype_pphelp))

# open parenthesis (klammer_auf)  and close parenthesis (klammer_zu)
# --------------------------
# to be nested correctly.
  #define KLAMMER_AUF  klammer_auf(stream_);
  #define KLAMMER_ZU   klammer_zu(stream_);

# UP: prints parenthesis '(' to the stream and possibly memorizes
# the position.
# klammer_auf(&stream);  english: open_parenthesis(&stream);
# > stream: Stream
# < stream: Stream
# changes STACK
# can trigger GC
local void klammer_auf (const object* stream_) {
  var object stream = *stream_;
  if (!PPHELP_STREAM_P(stream)) { # normal Stream
    write_ascii_char(stream_,'(');
  } else { # Pretty-Print-Help-Stream
    var object pos = # position for closing parenthesis
      (test_value(S(print_rpars)) # *PRINT-RPARS* /= NIL ?
       ? TheStream(stream)->strm_pphelp_lpos # yes -> current Position (Fixnum>=0)
       : NIL);                               # no -> NIL
    dynamic_bind(S(prin_rpar),pos); # bind SYS::*PRIN-RPAR* to it
    write_ascii_char(stream_,'(');
  }
}

# UP: Prints parenthesis ')' to the Stream, possibly at the memorized
# position.
# klammer_zu(&stream); english: close_parenthesis(&stream);
# > stream: Stream
# < stream: Stream
# changes STACK
# can trigger GC
local void klammer_zu (const object* stream_) {
  var object stream = *stream_;
  if (!PPHELP_STREAM_P(stream)) { # normal Stream
    write_ascii_char(stream_,')');
  } else { # Pretty-Print-Help-Stream
    # fetch desired position of the parenthesis:
    var object pos = Symbol_value(S(prin_rpar)); # SYS::*PRIN-RPAR*
    if (nullp(pos)) goto hinten; # none -> print parenthesis behind
    # print parenthesis at Position pos:
    if (eq(TheStream(stream)->strm_pphelp_modus,mehrzeiler)
        && !nullp(Cdr(TheStream(stream)->strm_pphelp_strings))) {
      # multi-liner with more than one line ("real" multi-liner)
      # print parenthesis at desired Position.
      # Therefore test, if the last line in the stream contains
      # 1. only Spaces up to the desired Position (inclusively)
      # and
      # 2. only Spaces and ')' , otherwise.
      # if yes, put parenthesis to the desired position.
      # if no, start new line, print Spaces and the parenthesis.
      var object lastline = # last line
        Car(TheStream(stream)->strm_pphelp_strings);
      if (!stringp(lastline)) { # drop the newline / indentation / tab
        do { TheStream(stream)->strm_pphelp_strings =
               Cdr(TheStream(stream)->strm_pphelp_strings);
        } while (!stringp(TheStream(stream)->strm_pphelp_strings));
        goto new_line;
      }
      var uintL len = TheIarray(lastline)->dims[1]; # lendgh = Fill-Pointer of line
      var uintL need = posfixnum_to_L(pos) + 1; # necessary number of Spaces
      if (len < need) # line too short ?
        goto new_line; # yes -> start new line
      lastline = TheIarray(lastline)->data; # last line, Normal-Simple-String
      var chart* charptr = &TheSstring(lastline)->data[0];
      # test, if (need) number of spaces are ahead:
      {
        var uintL count;
        dotimespL(count,need, {
          if (!chareq(*charptr++,ascii(' '))) # Space ?
            goto new_line; # no -> start new line
        });
      }
      var chart* charptr1 = charptr; # memorize position
      # test, if (len-need) times Space or ')' is ahead:
      {
        var uintL count;
        dotimesL(count,len-need, {
          var chart c = *charptr++;
          if (!(chareq(c,ascii(' ')) || chareq(c,ascii(')')))) # Space or ')' ?
            goto new_line; # no -> start new line
        });
      }
      # put parenthesis to the desired position pos = need-1:
      *--charptr1 = ascii(')');
    } else {
      # single-liner.
      # parenthesis must be printed behind.
      # Exception: if Line-Position = SYS::*PRIN-LINELENGTH*,
      #           printing would occur past the end of the line;
      #           instead, a new line is started.
      # Max Right Margin == Line-Position ?
      if (eq(right_margin(),TheStream(stream)->strm_pphelp_lpos)) {
      new_line: # start enw line
        pphelp_newline(stream_); spaces(stream_,pos);
      }
    hinten: # print parenthesis behind
      write_ascii_char(stream_,')');
    }
    # unbind SYS::*PRIN-RPAR* :
    dynamic_unbind();
  }
}

/* forward declarations for *PRINT-LINES* */
local bool check_lines_limit (void);
local void double_dots (const object*);
#define CHECK_LINES_LIMIT(finally) \
  if (check_lines_limit()) { double_dots(stream_); finally; }

# Justify
# -------
# to be nested correctly,
# each time, JUSTIFY_START once,
# then arbitrary output, separated by JUSTIFY_SPACE,
# then once either
#  JUSTIFY_END_ENG (collects short blocks even in multi-liners into one line)
#     or
#  JUSTIFY_END_WEIT (in multi-liners each block occupies its own line).
#define JUSTIFY_START(n)  justify_start(stream_,n);
#define JUSTIFY_SPACE     justify_space(stream_);
#define JUSTIFY_END_ENG   justify_end_eng(stream_);
#define JUSTIFY_END_WEIT  justify_end_weit(stream_);

# SYS::*PRIN-TRAILLENGTH* = number of columns that need to be reserved for
#                           closing parentheses on the current line; bound
#                           to 0 for all objects immediately followed by
#                           JUSTIFY_SPACE. Used only if *PRINT-RPARS* = NIL.
# Preparation of an item to be justified.
#define JUSTIFY_LAST(is_last)  \
    { if (is_last) justify_last(); }

# UP: empties a Pretty-Print-Help-Stream.
# justify_empty_1(&stream);
# > stream: Stream
# < stream: Stream
# can trigger GC
local void justify_empty_1 (const object* stream_) {
  var object new_cons = cons_ssstring(NULL,NIL);
  var object stream = *stream_;
  TheStream(stream)->strm_pphelp_strings = new_cons; # new, empty line
  TheStream(stream)->strm_pphelp_modus = einzeiler; # Modus := single-liner
}

# UP: starts a Justify-Block.
# justify_start(&stream,traillength);
# > stream: Stream
# > traillength: additional width that needs to be reserved
#                for closing brackets on this level
# < stream: Stream
# changes STACK
local void justify_start (const object* stream_, uintL traillength) {
  var object stream = *stream_;
  # Bind SYS::*PRIN-TRAILLENGTH* to 0 and save its previous value,
  # incremented by traillength, in SYS::*PRIN-PREV-TRAILLENGTH*.
  dynamic_bind(S(prin_prev_traillength),fixnum_inc(Symbol_value(S(prin_traillength)),traillength));
  dynamic_bind(S(prin_traillength),Fixnum_0);
  if (!PPHELP_STREAM_P(stream)) { # normal Stream -> nothing to do
  } else { # Pretty-Print-Help-Stream
    # bind SYS::*PRIN-JBSTRINGS* to the content of the stream:
    dynamic_bind(S(prin_jbstrings),TheStream(stream)->strm_pphelp_strings);
    # bind SYS::*PRIN-JBMODUS* to the Modus of the Stream:
    dynamic_bind(S(prin_jbmodus),TheStream(stream)->strm_pphelp_modus);
    # bind SYS::*PRIN-JBLPOS* to the Line-Position of the Stream:
    dynamic_bind(S(prin_jblpos),TheStream(stream)->strm_pphelp_lpos);
    # bind SYS::*PRIN-JBLOCKS* to () :
    dynamic_bind(S(prin_jblocks),NIL);
    # empty the Stream:
    justify_empty_1(stream_);
  }
}

# UP: empties the content of Pretty-Print-Hilfsstream into the Variable
# SYS::*PRIN-JBLOCKS*.
# justify_empty_2(&stream);
# > stream: Stream
# < stream: Stream
# can trigger GC
local void justify_empty_2 (const object* stream_) {
  var object stream = *stream_;
  var object new_cons;
  # extend SYS::*PRIN-JBLOCKS* by the content of the Stream:
  if (eq(TheStream(stream)->strm_pphelp_modus,mehrzeiler)) { # multi-liner.
    # (push strings SYS::*PRIN-JBLOCKS*)
    new_cons = allocate_cons(); # new Cons
    Car(new_cons) = TheStream(*stream_)->strm_pphelp_strings;
  } else { # single-liner.
    # (push (first strings) SYS::*PRIN-JBLOCKS*), or shorter:
    # (setq SYS::*PRIN-JBLOCKS* (rplacd strings SYS::*PRIN-JBLOCKS*))
    new_cons = TheStream(stream)->strm_pphelp_strings;
  }
  Cdr(new_cons) = Symbol_value(S(prin_jblocks));
  Symbol_value(S(prin_jblocks)) = new_cons;
}

# UP: prints space, which can be stretched with Justify.
# justify_space(&stream);
# > stream: Stream
# < stream: Stream
# can trigger GC
local void justify_space (const object* stream_) {
  if (!PPHELP_STREAM_P(*stream_)) { # normal Stream -> only one Space
    write_ascii_char(stream_,' ');
  } else { # Pretty-Print-Help-Stream
    justify_empty_2(stream_); # save content of Stream
    justify_empty_1(stream_); # empty Stream
    # Line-Position := SYS::*PRIN-LM* (Fixnum>=0)
    TheStream(*stream_)->strm_pphelp_lpos = Symbol_value(S(prin_lm));
  }
}

local void mutli_line_sub_block_out (object block, const object* stream_) {
  block = nreverse(block); # bring lines into the right order
  if (!stringp(Car(block))) # drop the initial indentation
    block = Cdr(block);
  # print first line on the PPHELP-stream:
  pushSTACK(block);
  write_string(stream_,Car(block));
  block = popSTACK();
  # append remaining lines to the lines in front of the stream:
  var object stream = *stream_;
  TheStream(stream)->strm_pphelp_strings =
    nreconc(Cdr(block),TheStream(stream)->strm_pphelp_strings);
}

# UP: Finalizes a Justify-Block, determines the shape of the Block and
# prints its content to the old Stream.
# justify_end_eng(&stream);
# > stream: Stream
# < stream: Stream
# can trigger GC
local void justify_end_eng (const object* stream_) {
  if (!PPHELP_STREAM_P(*stream_)) { # normal Stream -> nothing to do
  } else { # Pretty-Print-Help-Stream
    justify_empty_2(stream_); # save stream-content
    # restore stream-content, i.e values of SYS::*PRIN-JBSTRINGS*,
    # SYS::*PRIN-JBMODUS*, SYS::*PRIN-JBLPOS* back to the Stream:
    var object stream = *stream_;
    # save current Line-Position:
    pushSTACK(TheStream(stream)->strm_pphelp_lpos);
    # restore old stream-content:
    TheStream(stream)->strm_pphelp_strings = Symbol_value(S(prin_jbstrings));
    TheStream(stream)->strm_pphelp_modus = Symbol_value(S(prin_jbmodus));
    TheStream(stream)->strm_pphelp_lpos = Symbol_value(S(prin_jblpos));
    # print (non-empty) list of blocks to stream:
    pushSTACK(nreverse(Symbol_value(S(prin_jblocks)))); # (nreverse SYS::*PRIN-JBLOCKS*)
    # The blocks are printed one by one. Multi-liners are separated from
    # themselves and from the single-liners by Newline.
    # But as many consecutive single-liners as possible are packed
    # (separated by Space) into one line.
    loop { # Run through Blocklist STACK_0:
      var object block = Car(STACK_0); # next block
      STACK_0 = Cdr(STACK_0); # shorten blocklist
      if (consp(block)) { # Sub-Block with several lines
        mutli_line_sub_block_out(block,stream_);
        # Modus := multi-liner:
        stream = *stream_;
        TheStream(stream)->strm_pphelp_modus = mehrzeiler;
        if (matomp(STACK_0)) { # Restlist empty?
          # yes -> reset Line-Position, finished
          TheStream(stream)->strm_pphelp_lpos = STACK_1;
          break;
        }
        # start new line and proceed:
        goto new_line;
      } else {
        # sub-block consisting of one line
        # print to PPHELP-stream:
        write_string(stream_,block);
        if (matomp(STACK_0)) # remaining list empty?
          break; # yes -> finished
        # is next block a multi-liner?
        block = Car(STACK_0); # next block
        if (atomp(block)) { # a multi-liner or a single-liner?
          # it is a single-liner.
          # Does it still fit on the same line, i.e
          # line-position + 1 + string_width(single-liner) + traillength <= L ?
          var object linelength = right_margin();
          if (nullp(linelength) # =NIL -> yes, it fits
              || (posfixnum_to_L(TheStream(*stream_)->strm_pphelp_lpos) # line-position
                  + pphelp_string_width(block) # width of the single-liner
                  + (nullp(Symbol_value(S(print_rpars))) && matomp(Cdr(STACK_0)) ? posfixnum_to_L(Symbol_value(S(prin_prev_traillength))) : 0) # SYS::*PRIN-PREV-TRAILLENGTH*
                  < posfixnum_to_L(linelength))) { # < linelength ?
            # stil fits.
            # print Space instead of Newline:
            write_ascii_char(stream_,' ');
          } else { # does not fit anymore.
            goto new_line;
          }
        } else { # multi-liner -> new line and proceed
        new_line: # start new line
          pphelp_newline(stream_); # new line with Modus:=multi-liner
          spaces(stream_,Symbol_value(S(prin_lm))); # SYS::*PRIN-LM* Spaces
        }
      }
      CHECK_LINES_LIMIT(break);
    }
    skipSTACK(2); # forget empty remaining list and the old line-position
    # unbind bindings of JUSTIFY_START:
    dynamic_unbind();
    dynamic_unbind();
    dynamic_unbind();
    dynamic_unbind();
  }
  # unbind bindings of JUSTIFY_START:
  dynamic_unbind(); # SYS::*PRIN-TRAILLENGTH*
  dynamic_unbind(); # SYS::*PRIN-PREV-TRAILLENGTH*
}

# UP: finalizes a justify-block, determines the shape of the block and
# prints its content to the old stream.
# justify_end_weit(&stream);
# > stream: stream
# < stream: stream
# can trigger GC
local void justify_end_weit (const object* stream_) {
  if (!PPHELP_STREAM_P(*stream_)) { # normal stream -> nothing to do
  } else { # Pretty-Print-Help-Stream
    justify_empty_2(stream_); # save stream content
    # restore stream content, i.e. move the values of SYS::*PRIN-JBSTRINGS*,
    # SYS::*PRIN-JBMODUS*, SYS::*PRIN-JBLPOS* back into the stream:
    var object stream = *stream_;
    # save present line-position:
    pushSTACK(TheStream(stream)->strm_pphelp_lpos);
    # restore old stream content:
    TheStream(stream)->strm_pphelp_strings = Symbol_value(S(prin_jbstrings));
    TheStream(stream)->strm_pphelp_modus = Symbol_value(S(prin_jbmodus));
    TheStream(stream)->strm_pphelp_lpos = Symbol_value(S(prin_jblpos));
    { # check, if all the blocks in SYS::*PRIN-JBLOCKS* are single-liners:
      var object blocks = Symbol_value(S(prin_jblocks)); # SYS::*PRIN-JBLOCKS*
      do { # peruse (non-empty) block list:
        if (mconsp(Car(blocks))) # is sub-block a multi-liner ?
          goto gesamt_mehrzeiler; # yes -> block is a multi-liner altogether
        blocks = Cdr(blocks);
      } while (consp(blocks));
    }
    # check, if the blocks in SYS::*PRIN-JBLOCKS*
    # (each block is a single-liner) can result in a single-liner altogether:
    # Is L=NIL (no boundary restriction) or
    # L1 + (total width of blocks) + (number of blocks-1) + Traillength <= L ?
    {
      var object linelength = right_margin();
      if (nullp(linelength)) goto gesamt_einzeiler; # =NIL -> single-liner
      var uintL totalneed = posfixnum_to_L(Symbol_value(S(prin_l1))); # Sum := L1 = SYS::*PRIN-L1*
      var object blocks = Symbol_value(S(prin_jblocks)); # SYS::*PRIN-JBLOCKS*
      do { # peruse (non-empty) block list:
        var object block = Car(blocks); # Block (single-liner)
        totalneed += pphelp_string_width(block) + 1; # plus its width+1
        blocks = Cdr(blocks);
      } while (consp(blocks));
      if (nullp(Symbol_value(S(print_rpars))))
        totalneed += posfixnum_to_L(Symbol_value(S(prin_prev_traillength))); # SYS::*PRIN-PREV-TRAILLENGTH*
      # totalneed = L1 + (total width of blocks) + (number of blocks) + Traillength
      # compare this with linelength + 1 :
      if (totalneed <= posfixnum_to_L(linelength)+1)
        goto gesamt_einzeiler;
      else
        goto gesamt_mehrzeiler;
    }
  gesamt_einzeiler: # a single-liner, altogether.
    # print blocks apartly, separated by Spaces, to the stream:
    pushSTACK(nreverse(Symbol_value(S(prin_jblocks)))); # (nreverse SYS::*PRIN-JBLOCKS*)
    loop { # peruse (non-empty) block list STACK_0:
      var object block = Car(STACK_0); # next block
      # (a single-liner, string without #\Newline)
      STACK_0 = Cdr(STACK_0); # shorten block list
      write_string(stream_,block); # print block to the stream
      if (matomp(STACK_0)) # remaining list empty -> done
        break;
      write_ascii_char(stream_,' '); # print #\Space
    }
    goto fertig;
  gesamt_mehrzeiler: # a multi-liner, altogether.
    # print blocks apartly, separated by Newline, to the stream:
    pushSTACK(nreverse(Symbol_value(S(prin_jblocks)))); # (nreverse SYS::*PRIN-JBLOCKS*)
    loop { # peruse (non-empty) block list STACK_0:
      var object block = Car(STACK_0); # next block
      STACK_0 = Cdr(STACK_0); # shorten block list
      if (consp(block)) { # multi-line sub-block
        mutli_line_sub_block_out(block,stream_);
      } else { # single-line sub-block
        # print it on the PPHELP-stream:
        write_string(stream_,block);
      }
      if (matomp(STACK_0)) # remaining list empty?
        break;
      pphelp_newline(stream_); # start new line
      spaces(stream_,Symbol_value(S(prin_lm))); # SYS::*PRIN-LM* Spaces
      CHECK_LINES_LIMIT(break);
    }
    stream = *stream_;
    # restore line-position:
    TheStream(stream)->strm_pphelp_lpos = STACK_1;
    # GesamtModus := multi-liner:
    TheStream(stream)->strm_pphelp_modus = mehrzeiler;
    goto fertig;
  fertig: # line-position is now correct.
    skipSTACK(2); # forget empty remaining list and the old line-position
    # unbind bindings of JUSTIFY_START:
    dynamic_unbind();
    dynamic_unbind();
    dynamic_unbind();
    dynamic_unbind();
  }
  # unbind bindings of JUSTIFY_START:
  dynamic_unbind(); # SYS::*PRIN-TRAILLENGTH*
  dynamic_unbind(); # SYS::*PRIN-PREV-TRAILLENGTH*
}


# Prepares the justification of the last item in a sequence of JUSTIFY_SPACE
# separated items.
# justify_last();
local void justify_last (void) {
  # SYS::*PRIN-TRAILLENGTH* := SYS::*PRIN-PREV-TRAILLENGTH*
  Symbol_value(S(prin_traillength)) = Symbol_value(S(prin_prev_traillength));
}

# Indent
# ------
# in order to nest correctly, alway use INDENT_START and
# INDENT_END each once at a time.
#define INDENT_START(delta)  indent_start(stream_,delta);
#define INDENT_END           indent_end(stream_);

# UP: Binds the left boundaries SYS::*PRIN-L1* and SYS::*PRIN-LM* to
# values increased by delta.
# indent_start(&stream,delta);
# > delta: indentation value
# > stream: stream
# < stream: stream
# changes STACK
local void indent_start (const object* stream_, uintL delta) {
  if (!PPHELP_STREAM_P(*stream_)) { # normal stream -> nothing to do
  } else { # Pretty-Print-Help-Stream
    { # bind SYS::*PRIN-L1*:
      var object new_L1 = fixnum_inc(Symbol_value(S(prin_l1)),delta);
      dynamic_bind(S(prin_l1),new_L1);
    }
    { # bind SYS::*PRIN-LM*:
      var object new_LM = fixnum_inc(Symbol_value(S(prin_lm)),delta);
      dynamic_bind(S(prin_lm),new_LM);
    }
  }
}

# UP: finalizes an indent-block.
# indent_end(&stream);
# > stream: stream
# < stream: stream
# changes STACK
local void indent_end (const object* stream_) {
  if (!PPHELP_STREAM_P(*stream_)) { # normal Stream -> nothing to do
  } else { # Pretty-Print-Help-Stream
    # unbind the two bindings of INDENT_START:
    dynamic_unbind();
    dynamic_unbind();
  }
}

# Indent Preparation
# ------------------
# serves to indent a variable number of characters.
# in order to nest correctly,
#   first INDENTPREP_START once,
#   then a couple of characters (no #\Newline!)
#   and then INDENTPREP_END once.
# After that you can continue immediately with INDENT_START.
#define INDENTPREP_START  indentprep_start(stream_);
#define INDENTPREP_END    indentprep_end(stream_);

# UP: memorizes the present position.
# indentprep_start(&stream);
# > stream: stream
# < stream: stream
# changes STACK
local void indentprep_start (const object* stream_) {
  var object stream = *stream_;
  if (!PPHELP_STREAM_P(stream)) { # normal stream -> nothing to do
  } else { # Pretty-Print-Help-Stream
    # memorize line-position:
    pushSTACK(TheStream(stream)->strm_pphelp_lpos);
  }
}

# UP: subtracts the positions, returns the indentation width.
# indentprep_end(&stream)
# > stream: stream
# < stream: stream
# < result: indentation width
# changes STACK
local uintL indentprep_end (const object* stream_) {
  var object stream = *stream_;
  if (!PPHELP_STREAM_P(stream)) { # normal stream -> nothing to do
    return 0;
  } else { # Pretty-Print-Help-Stream
    var uintL lpos_now = # current line-position
      posfixnum_to_L(TheStream(stream)->strm_pphelp_lpos);
    var uintL lpos_before = # memorized line-position
      posfixnum_to_L(popSTACK());
    return (lpos_now>=lpos_before ? lpos_now-lpos_before : 0);
  }
}

# ------------------ sub-routines for *PRINT-LEVEL* -------------------------

# Level
# -----
# in order to nest correctly,
# once LEVEL_CHECK at the beginning of a pr_xxx-routine
#     and once LEVEL_END at the end.
#define LEVEL_CHECK  { if (level_check(stream_)) return; }
#define LEVEL_END    level_end(stream_);

# UP: prints the representation of a LISP-object when
# *PRINT-LEVEL* is exceeded.
# pr_level(&stream);
# > stream: stream
# < stream: stream
# can trigger GC
#define pr_level(stream_)     write_ascii_char(stream_,'#')

# UP: tests, if SYS::*PRIN-LEVEL* has reached the value of *PRINT-LEVEL*.
# if yes, only print '#' and jump back out of the calling sub-routine (!).
# if no, bind incremented value of SYS::*PRIN-LEVEL*.
# if (level_check(&stream)) return;
# > stream: Stream
# < stream: Stream
# if yes: can trigger GC
# if no: changes STACK
local bool level_check (const object* stream_) {
  var object level = Symbol_value(S(prin_level)); # SYS::*PRIN-LEVEL*, a Fixnum >=0
  var object limit = Symbol_value(S(print_level)); # *PRINT-LEVEL*
  if (!test_value(S(print_readably))
      && posfixnump(limit) # is there a limit?
      && (posfixnum_to_L(level) >= posfixnum_to_L(limit))) { # reached it or exceeded it?
    # yes -> print '#' and return:
    pr_level(stream_); return true;
  } else { # no -> *PRINT-LEVEL* not yet reached.
    # bind SYS::*PRIN-LEVEL* to (1+ SYS::*PRIN-LEVEL*) :
    level = fixnum_inc(level,1); # (incf level)
    dynamic_bind(S(prin_level),level);
    return false;
  }
}

# UP: finalizes a block with increased SYS::*PRIN-LEVEL*.
# level_end(&stream);
# > stream: stream
# < stream: stream
# changes STACK
local void level_end (const object* stream_) {
  dynamic_unbind();
}

# ------------------ sub-routines for *PRINT-LENGTH* ------------------------

# Length
# ------

# UP: returns the length limit for structured objects like e.g. lists.
# get_print_length()
# < result: length limit
local uintL get_print_length (void) {
  var object limit = Symbol_value(S(print_length)); # *PRINT-LENGTH*
  return (!test_value(S(print_readably))
          && posfixnump(limit) # a Fixnum >=0 ?
          ? posfixnum_to_L(limit) # yes
          : ~(uintL)0);           # no -> limit "infinite"
}

# UP: abbreviate the remainder with "..."
# triple_dots(&stream);
# > stream: stream
# < stream: stream
# can trigger GC
local void triple_dots (const object* stream_) {
  JUSTIFY_LAST(true);
  write_ascii_char(stream_,'.');
  write_ascii_char(stream_,'.');
  write_ascii_char(stream_,'.');
}
#define CHECK_LENGTH_LIMIT(test,finally) \
  if (test) { triple_dots(stream_); finally; }

# ------------------ sub-routines for *PRINT-LINES* ------------------------

# UP: check whether we are the end of the rope for *PRINT-LINES*
# check_lines_limit()
# < result: true if it is time to print ".." and bail out
local bool check_lines_limit (void) {
  var object limit = Symbol_value(S(print_lines)); # *PRINT-LINES*
  if (test_value(S(print_readably)) || !posfixnump(limit))
    return false;
  var object now = Symbol_value(S(prin_lines)); # SYS::*PRIN-LINES*
  if (!posfixnump(now))
    return true;
  var uintL max_lines = posfixnum_to_L(limit);
  var uintL cur_lines = posfixnum_to_L(now);
  return max_lines <= cur_lines;
}

# UP: abbreviate the remainder with ".."
# double_dots(&stream);
# > stream: stream
# < stream: stream
# can trigger GC
local void double_dots (const object* stream_) {
  JUSTIFY_LAST(true);
  # if (!eq(Symbol_value(S(prin_lines)),S(Kend))) {
    write_ascii_char(stream_,'.');
    write_ascii_char(stream_,'.');
  #   Symbol_value(S(prin_lines)) = S(Kend); # do not print anything else
  # }
}

# ------------------ sub-routines for *PRINT-CIRCLE* ------------------------

# UP: finds out, if an object has to be printed in #n= or #n# -
# notation because of *PRINT-CIRCLE*.
# circle_p(obj,circle_info_p)
# > obj: object
# < circle_info_p:
# < return: false, if obj is to be printed normally
#            true, if obj is to be printed ABnormally
# in the latter case, circle_info_p, if non-NULL, will contain
#      else: circle_info_p->flag: true, if obj is to be printed as #n=...
#                                false, if obj is to be printed as #n#
#            circle_info_p->n: n
#            circle_info_p->ptr: in case of #n=... the fixnum *ptr has to be
#                            incremented before output takes place.
typedef struct {
  bool flag;
  uintL n;
  object* ptr;
} circle_info_t;
local bool circle_p (object obj,circle_info_t* ci) {
  # check *PRINT-CIRCLE*:
  if (test_value(S(print_circle))) {
    var object table = Symbol_value(S(print_circle_table)); # SYS::*PRINT-CIRCLE-TABLE*
    if (!simple_vector_p(table)) { # should be a simple-vector!
    bad_table:
      dynamic_bind(S(print_circle),NIL); # bind *PRINT-CIRCLE* to NIL
      pushSTACK(S(print_circle_table)); # SYS::*PRINT-CIRCLE-TABLE*
      pushSTACK(S(print));
      fehler(error,
             GETTEXT("~: the value of ~ has been arbitrarily altered"));
    }
    # loop through the vector table = #(i ...) with m+1 (0<=i<=m) elements:
    # if obj is among the elements 1,...,i  -> case false, n:=Index.
    # if obj is among the elements i+1,...,m -> move
    # obj to position i+1, case true, n:=i+1, afterwards i:=i+1.
    # else case NULL.
    var uintL m1 = Svector_length(table); # length m+1
    if (m1==0) goto bad_table; # should be >0!
    var object* ptr = &TheSvector(table)->data[0]; # pointer in the vector
    var uintL i = posfixnum_to_L(*ptr++); # first element i
    var uintL index = 1;
    until (index == m1) { # run through the loop m times
      if (eq(*ptr++,obj)) # compare obj with the next vector-element
        goto found;
      index++;
    }
    # not found -> done
    goto normal;
  found: # foundobj as vector-element index, 1 <= index <= m,
    # ptr = &TheSvector(table)->data[index+1] .
    if (index <= i) { # obj is to be printed as #n#, n=index.
      if (ci) { ci->flag = false; ci->n = index; }
      return true;
    } else { # move obj to position i+1:
      i = i+1;
      # (rotatef (svref Vektor i) (svref Vektor index)) :
      {
        var object* ptr_i = &TheSvector(table)->data[i];
        *--ptr = *ptr_i; *ptr_i = obj;
      }
      # obj is to be printed as #n=..., n=i.
      if (ci) {
        ci->flag = true; ci->n = i;
        ci->ptr = &TheSvector(table)->data[0]; # increase i in the vector, afterwards
      }
      return true;
    }
  }
 normal: # obj is to be printed normally
  return false;
}

# UP: verifies, if an object is circular, and prints it in
# this case as #n# or with #n=-prefix (and otherwise normally).
# pr_circle(&stream,obj,&pr_xxx);
# > obj: object
# > pr_xxx: printing-routine, which receives &stream und obj as arguments
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_circle (const object* stream_, object obj, pr_routine_t* pr_xxx) {
  # determine, if circular:
  var circle_info_t info;
  if (!circle_p(obj,&info)) { # not circular, print obj normally:
    (*pr_xxx)(stream_,obj);
  } else { # circular
    if (info.flag) { # print obj as #n=...:
      { # first increment the fixnum in the vector for circle_p:
        var object* ptr = info.ptr;
        *ptr = fixnum_inc(*ptr,1);
      }
      {
        var uintL n = info.n;
        pushSTACK(obj); # save obj
        # print prefix and calculate indentation depth:
        INDENTPREP_START;
        write_ascii_char(stream_,'#');
        pr_uint(stream_,n);
        write_ascii_char(stream_,'=');
      }
      {
        var uintL indent = INDENTPREP_END;
        obj = popSTACK(); # return obj
        # print obj (indented):
        INDENT_START(indent);
        (*pr_xxx)(stream_,obj);
        INDENT_END;
      }
    } else { # print obj as #n#:
      var uintL n = info.n;
      write_ascii_char(stream_,'#');
      pr_uint(stream_,n);
      write_ascii_char(stream_,'#');
    }
  }
}

# ------------------------ Entering the printer -------------------------------

# check whether the object is a valid Dispatch Table and contains some entries
#define DISPATCH_TABLE_VALID_P(dt)  \
 (mconsp(dt) && eq(Car(dt),S(print_pprint_dispatch)) && !nullp(Cdr(dt)))
# call the appropriate function
local void pretty_print_call (const object* stream_,object obj,
                              pr_routine_t* pr_xxx_default) {
  object ppp_disp = Symbol_value(S(print_pprint_dispatch));
  if (DISPATCH_TABLE_VALID_P(ppp_disp)) {
    pushSTACK(obj); funcall(S(pprint_dispatch),1);
    if (nullp(value2)) goto default_printing;
    pushSTACK(*stream_); pushSTACK(obj); funcall(value1,2);
  } else {
  default_printing:
    (*pr_xxx_default)(stream_,obj);
  }
}
#undef DISPATCH_TABLE_VALID_P

# UP: return the number of spaces available on the current line in this stream
# NIL means unlimited
local object space_available (object stream) {
  var object line_pos = get_line_position(stream);
  if (!posfixnump(line_pos)) return NIL;
  var uintL pos = posfixnum_to_L(line_pos);
  var object prm = right_margin();
  if (!posfixnump(prm)) return NIL;
  var uintL mar = posfixnum_to_L(prm);
  if (mar < pos) return Fixnum_0;
  return fixnum(mar-pos);
}

# UP: return the total length of all the strings in the PPHELP stream
# return NIL if this is a multi-liner
local object pphelp_length (object pph_stream) {
 #if IO_DEBUG > 0
  PPH_OUT(pphelp_length,pph_stream);
 #endif
  if (eq(TheStream(pph_stream)->strm_pphelp_modus,mehrzeiler))
    return NIL;
  var uintL ret = 0;
  var object list = Cdr(TheStream(pph_stream)->strm_pphelp_strings);
  while (mconsp(list)) {
    var object top = Car(list); list = Cdr(list); # (pop list)
    if (stringp(top)) ret += vector_length(top);
    else if (vectorp(top)) ret += PPH_FORMAT_TAB(pph_stream,top);
    else if (mconsp(top)) {
      if (nullp(Car(top))) { # mandatory newline
        TheStream(pph_stream)->strm_pphelp_modus = mehrzeiler;
        return NIL;
      }
    } # else if (posfixnump(top)) ret += posfixnum_to_L(top);
    else NOTREACHED;
  }
  return fixnum(ret);
}

# UP: check whether the string fits into the current line in the stream
# return true iff the next object does fit
local inline bool string_fit_line_p (object list, object stream,
                                     uintL offset) {
  var object avail = space_available(stream);
  if (nullp(avail)) return true; # unlimited space available
  var uintL len;
  var object top = Car(list); list = Cdr(list); # (pop list)
  if (stringp(top)) len = vector_length(top);
  else if (mconsp(top)) return true;
  else if (vectorp(top)) {
    len = PPH_FORMAT_TAB(stream,top);
    while (mconsp(list) && !stringp(Car(list))) list = Cdr(list);
    if (mconsp(list)) len += vector_length(Car(list)); # string!
    else return false; # do not need to print this tab
  } else NOTREACHED;
  return posfixnum_to_L(avail) >= len + offset;
}

# UP: Binds the variables of the printer and then calls a printer-routine.
# pr_enter(&stream,obj,&pr_xxx);
# > obj: object
# > pr_xxx: printing-routine, which receives &stream and obj as arguments
# > stream: stream
# < stream: stream
# can trigger GC
  # first of all only treatment of *PRINT-PRETTY*:
local void pr_enter_1 (const object* stream_, object obj,
                       pr_routine_t* pr_xxx) {
  # Streamtype (PPHELP-stream or not) must fit to *PRINT-PRETTY* .
  if (test_value(S(print_pretty))) {
    # *PRINT-PRETTY* /= NIL.
    # if *stream_ is no PPHELP-Stream,
    # it must be replaced by a PPHELP-stream:
    if (!PPHELP_STREAM_P(*stream_)) { # still a normal stream
      dynamic_bind(S(prin_l1),Fixnum_0); # bind SYS::*PRIN-L1* to 0
      dynamic_bind(S(prin_lm),Fixnum_0); # bind SYS::*PRIN-LM* to 0
      pushSTACK(obj); # save object
      { # Place SYS::*PRIN-L1* to its line-position:
        var object linepos = get_line_position(*stream_);
        if (!posfixnump(linepos))
          linepos = Fixnum_0;
        Symbol_value(S(prin_l1)) = linepos;
      }
      pushSTACK(make_pphelp_stream()); # new PPHELP-Stream, line-position = 0
      if (stream_get_read_eval(*stream_)) # adopt READ-EVAL-Bit
        TheStream(STACK_0)->strmflags |= bit(strmflags_reval_bit_B);
      # print object to the new stream:
      pretty_print_call(&STACK_0,STACK_1,pr_xxx);
      var bool skip_first_nl = false;
      var bool modus_single_p;
      { # print content of the new stream to the old stream:
        var object ppstream = popSTACK(); # the new stream
        STACK_0 = nreverse(TheStream(ppstream)->strm_pphelp_strings);
        TheStream(ppstream)->strm_pphelp_strings = STACK_0;
        # if it has become a multi-liner that does not start with a
        # Newline, and the old line-position is >0 ,
        # print a Newline to the old stream first:
        { var object firststring = Car(Cdr(STACK_0)); # first line
          if (stringp(firststring) &&
              ((TheIarray(firststring)->dims[1] == 0) # empty?
               || chareq(TheSstring(TheIarray(firststring)->data)->data[0],
                         ascii(NL)))) # or Newline at the beginning?
            skip_first_nl = true;
        }
        if (eq(Symbol_value(S(prin_l1)),Fixnum_0)) # or at position 0 ?
          skip_first_nl = true;
        if (nullp(Cdr(Cdr(STACK_0)))) { # DEFINITELY a single-liner
          skip_first_nl = true;
        } else { # several lines, maybe still a single-liner?
          # if modus is mehrzeiler, we KNOW it is so
          # if it is einzeiler, it might have :LINEAR newlines
          var object pphs_len = pphelp_length(ppstream);
          var object prm = right_margin();
          var bool fit_this_line = !nullp(pphs_len);
          if (posfixnump(pphs_len) # could POSSIBLY be a single-liner
              && posfixnump(prm)) { # have right margin
            var uintL pphs_len_i = posfixnum_to_L(pphs_len);
            var uintL prm_i = posfixnum_to_L(prm);
            var uintL pos_i = posfixnum_to_L(Symbol_value(S(prin_l1)));
            fit_this_line = (pphs_len_i <= (prm_i - pos_i));
            if (pphs_len_i > prm_i)
              TheStream(ppstream)->strm_pphelp_modus = mehrzeiler;
            if (fit_this_line
                || nullp(Symbol_value(S(pprint_first_newline))))
              skip_first_nl = true;
          }
          if (skip_first_nl && !fit_this_line)
            TheStream(ppstream)->strm_pphelp_modus = mehrzeiler;
        }
        modus_single_p = eq(TheStream(ppstream)->strm_pphelp_modus,einzeiler);
       #if IO_DEBUG > 0
        PPH_OUT(pr_enter_1,ppstream);
       #endif
      }
      if (skip_first_nl) {
        pprint_prefix(stream_,PPHELP_INDENTN(Car(STACK_0)));
        STACK_0 = Cdr(STACK_0);
        goto skip_NL;
      } else STACK_0 = Cdr(STACK_0);
      # Symbol_value(S(prin_lines)) = Fixnum_0;
      do { # NL & indent
        var object top = Car(STACK_0);
        var object indent = Fixnum_0;
        if (mconsp(top)) { # if :FILL and the next string fits the line
          STACK_0 = Cdr(STACK_0);
          if (modus_single_p ||
              (eq(PPHELP_NL_TYPE(top),S(Kfill)) &&
               string_fit_line_p(STACK_0,*stream_,0)))
            goto skip_NL;
          indent = PPHELP_INDENTN(top);
          if (!mconsp(STACK_0)) break; # end of stream
        } else if (!stringp(top)) { # tab - a vector but not a string
          STACK_0 = Cdr(STACK_0);
          if (!mconsp(STACK_0)) break; # end of stream
          # if the next object is not a NL then indent
          var uintL num_space = PPH_FORMAT_TAB(*stream_,top);
          if (modus_single_p || stringp(Car(STACK_0)) ||
              (mconsp(Car(STACK_0)) &&  # ignored NL
               (eq(PPHELP_NL_TYPE(Car(STACK_0)),S(Kfill)) &&
                string_fit_line_p(Cdr(STACK_0),*stream_,num_space)))) {
            spaces(stream_,fixnum(num_space));
            goto skip_NL;
          } else if (mconsp(Car(STACK_0))) # set indent
            indent = PPHELP_INDENTN(Car(STACK_0));
        }
        write_ascii_char(stream_,NL); # #\Newline as the line separator
        pprint_prefix(stream_,indent); # line prefix & indentation, if any
        # LINES_INC;
        # CHECK_LINES_LIMIT(break);
      skip_NL:
        { # print first element, if string
          var object top = Car(STACK_0);
          if (stringp(top)) {
            write_string(stream_,top); # print single String
            STACK_0 = Cdr(STACK_0);
          }
        }
      } while (mconsp(STACK_0));
      # if we are here because of *PRINT-LINES*, we should print the suffix
      # if (mconsp(STACK_0)) {
      #   while (!nullp(Cdr(STACK_0))) STACK_0 = Cdr(STACK_0);
      #   if (stringp(Car(STACK_0))) write_string(stream_,Car(STACK_0));
      # }
      skipSTACK(1); # strm_pphelp_strings
      dynamic_unbind(); # SYS::*PRIN-LM*
      dynamic_unbind(); # SYS::*PRIN-L1*
    } else { # already a PPHELP-stream
      pretty_print_call(stream_,obj,pr_xxx);
    }
  } else { # *PRINT-PRETTY* = NIL.
    # if *stream_ is a PPHELP-Stream, it must be replaced by a
    # single-element broadcast-stream :
    if (!PPHELP_STREAM_P(*stream_)) { # normal stream
      (*pr_xxx)(stream_,obj);
    } else { # a PPHELP-stream
      pushSTACK(obj);
      pushSTACK(make_broadcast1_stream(*stream_)); # broadcast-stream to the stream *stream_
      (*pr_xxx)(&STACK_0,STACK_1);
      skipSTACK(2);
    }
  }
}
# the same procedure with treatment of *PRINT-CIRCLE* and *PRINT-PRETTY* :
local void pr_enter_2 (const object* stream_, object obj, pr_routine_t* pr_xxx) {
  # if *PRINT-CIRCLE* /= NIL, search in obj for circularities.
  if (test_value(S(print_circle)) || test_value(S(print_readably))) {
    # search circularities:
    pushSTACK(obj);
    var object circularities = # table of circularities
      get_circularities(obj,
                        test_value(S(print_array)) || test_value(S(print_readably)), # /= 0 if, and only if *PRINT-ARRAY* /= NIL
                        test_value(S(print_closure)) || test_value(S(print_readably))); # /= 0 and only if *PRINT-CLOSURE* /= NIL
    obj = popSTACK();
    if (nullp(circularities)) { # no circularities found.
      # can bind *PRINT-CIRCLE* to NIL.
      dynamic_bind(S(print_circle),NIL);
      pr_enter_1(stream_,obj,pr_xxx);
      dynamic_unbind();
    } else if (eq(circularities,T)) { # stack overflow occurred
      # handle overflow of the GET_CIRCULARITIES-routine:
      dynamic_bind(S(print_circle),NIL); # bind *PRINT-CIRCLE* to NIL
      pushSTACK(S(print));
      fehler(storage_condition,
             GETTEXT("~: not enough stack space for carrying out circularity analysis"));
    } else { # circularity vector
      # Bind SYS::*PRINT-CIRCLE-TABLE* to the Simple-Vector:
      dynamic_bind(S(print_circle_table),circularities);
      if (!test_value(S(print_circle))) {
        # *PRINT-READABLY* enforces *PRINT-CIRCLE* = T
        dynamic_bind(S(print_circle),T);
        pr_enter_1(stream_,obj,pr_xxx);
        dynamic_unbind();
      } else {
        pr_enter_1(stream_,obj,pr_xxx);
      }
      dynamic_unbind();
    }
  } else {
    pr_enter_1(stream_,obj,pr_xxx);
  }
}
# The same routine with treatment of *PRINT-CIRCLE*, *PRINT-PRETTY*
# and SYS::*PRIN-STREAM* :
local void pr_enter (const object* stream_, object obj, pr_routine_t* pr_xxx) {
  # value of SYS::*PRIN-STREAM* = this stream ?
  if (eq(Symbol_value(S(prin_stream)),*stream_)) { # yes -> recursive call
    # if SYS::*PRINT-CIRCLE-TABLE* = #<UNBOUND> (which means, that
    # *PRINT-CIRCLE* was NIL beforehand) and now *PRINT-CIRCLE* /= NIL,
    # object obj must be scanned for circularities.
    if (eq(Symbol_value(S(print_circle_table)),unbound)) {
      pr_enter_2(stream_,obj,pr_xxx);
    } else {
      pr_enter_1(stream_,obj,pr_xxx);
    }
  } else { # no -> non-recursive call
#if STACKCHECKP
    var object* STACKbefore = STACK; # save STACK for later
#endif
    dynamic_bind(S(prin_level),Fixnum_0); # bind SYS::*PRIN-LEVEL* to 0
    dynamic_bind(S(prin_lines),Fixnum_0); # bind SYS::*PRIN-LINES* to 0
    dynamic_bind(S(prin_bqlevel),Fixnum_0); # bind SYS::*PRIN-BQLEVEL* to 0
    dynamic_bind(S(prin_l1),Fixnum_0); # bind SYS::*PRIN-L1* to 0 (for Pretty-Print)
    dynamic_bind(S(prin_lm),Fixnum_0); # bind SYS::*PRIN-LM* to 0 (for Pretty-Print)
    dynamic_bind(S(prin_traillength),Fixnum_0); # bind SYS::*PRIN-TRAILLENGTH*
    pr_enter_2(stream_,obj,pr_xxx);
    dynamic_unbind(); # SYS::*PRIN-TRAILLENGTH*
    dynamic_unbind(); # SYS::*PRIN-LM*
    dynamic_unbind(); # SYS::*PRIN-L1*
    dynamic_unbind(); # SYS::*PRIN-BQLEVEL*
    dynamic_unbind(); # SYS::*PRIN-LINES*
    dynamic_unbind(); # SYS::*PRIN-LEVEL*
#if STACKCHECKP
    # check, if Stack is cleaned:
    if (!(STACK == STACKbefore))
      abort(); # if not, go to Debugger
#endif
  }
}

# --------------- Leaving the printer through an external call ----------------

# preparation of the call of an external print-function
# pr_external_1(stream)
# > stream: stream
# < result: number of dynamic bindings, that have to be unbound.
local uintC pr_external_1 (object stream) {
  var uintC count = 1;
  # bind SYM to VAL unless already bound to it
#define BIND_UNLESS(sym,val)                       \
    if (!eq(Symbol_value(S(sym)),val)) { dynamic_bind(S(sym),val); count++; }
  # obey *PRINT-CIRCLE*:
  if (!test_value(S(print_circle))) { # *PRINT-CIRCLE* = NIL ->
    # in case, that *PRINT-CIRCLE* will be bound to T,
    # SYS::*PRINT-CIRCLE-TABLE* must be bound to #<UNBOUND>
    # (unless, it is already = #<UNBOUND>).
    BIND_UNLESS(print_circle_table,unbound);
  }
  # obey *PRINT-READABLY*:
  if (test_value(S(print_readably))) {
    # for the user-defined print-functions, which do not yet know
    # of *PRINT-READABLY*, to behave accordingly,
    # we bind the other printer-variables appropriately:
    # *PRINT-READABLY* enforces *PRINT-ESCAPE* = T :
    BIND_UNLESS(print_escape,T);
    # *PRINT-READABLY* enforces *PRINT-BASE* = 10 :
    BIND_UNLESS(print_base,fixnum(10));
    # *PRINT-READABLY* enforces *PRINT-RADIX* = T :
    BIND_UNLESS(print_radix,T);
    # *PRINT-READABLY* enforces *PRINT-CIRCLE* = T :
    BIND_UNLESS(print_circle,T);
    # *PRINT-READABLY* enforces *PRINT-LEVEL* = NIL :
    BIND_UNLESS(print_level,NIL);
    # *PRINT-READABLY* enforces *PRINT-LENGTH* = NIL :
    BIND_UNLESS(print_length,NIL);
    # *PRINT-READABLY* enforces *PRINT-LINES* = NIL :
    BIND_UNLESS(print_lines,NIL);
    # *PRINT-READABLY* enforces *PRINT-MISER-WIDTH* = NIL :
    BIND_UNLESS(print_miser_width,NIL);
    # *PRINT-READABLY* enforces *PRINT-PPRINT-DISPATCH* = NIL :
    BIND_UNLESS(print_pprint_dispatch,NIL);
    # *PRINT-READABLY* enforces *PRINT-GENSYM* = T :
    BIND_UNLESS(print_gensym,T);
    # *PRINT-READABLY* enforces *PRINT-ARRAY* = T :
    BIND_UNLESS(print_array,T);
    # *PRINT-READABLY* enforces *PRINT-CLOSURE* = T :
    BIND_UNLESS(print_closure,T);
  }
#undef BIND_UNLESS
  # SYS::*PRIN-STREAM* an stream binden:
  dynamic_bind(S(prin_stream),stream);
  return count;
}

# postprocessing after the call of an external print-function
# pr_external_2(count);
# > count: number of dynamic bindungs, that have to be unbound.
#define pr_external_2(countvar)  \
    dotimespC(countvar,countvar, { dynamic_unbind(); } );

# ------------------------ Main-PRINT-routine --------------------------------

# here are the particular pr_xxx-routines:
local pr_routine_t prin_object;
local pr_routine_t prin_object_dispatch;
local pr_routine_t pr_symbol;
local void pr_symbol_part (const object* stream_, object string,
                           bool case_sensitive);
local pr_routine_t pr_like_symbol;
local pr_routine_t pr_character;
local pr_routine_t pr_string;
local pr_routine_t pr_list;
local pr_routine_t pr_cons;
local pr_routine_t pr_list_quote;
local pr_routine_t pr_list_function;
local pr_routine_t pr_list_backquote;
local pr_routine_t pr_list_splice;
local pr_routine_t pr_list_nsplice;
local pr_routine_t pr_list_unquote;
local pr_routine_t pr_real_number;
local pr_routine_t pr_number;
local pr_routine_t pr_array_nil;
local pr_routine_t pr_bvector;
local pr_routine_t pr_vector;
local pr_routine_t pr_array;
local pr_routine_t pr_instance;
local pr_routine_t pr_structure;
local pr_routine_t pr_machine;
local pr_routine_t pr_system;
local pr_routine_t pr_readlabel;
local pr_routine_t pr_framepointer;
local pr_routine_t pr_orecord;
local pr_routine_t pr_subr;
local pr_routine_t pr_fsubr;
local pr_routine_t pr_closure;
local pr_routine_t pr_cclosure;
local pr_routine_t pr_cclosure_lang;
local pr_routine_t pr_cclosure_codevector;
local pr_routine_t pr_stream;

# UP: prints object to Stream.
# prin_object(&stream,obj);
# > obj: object
# > stream: stream
# < stream: stream
# can trigger GC
local void prin_object (const object* stream_, object obj) {
 restart_it:
  # test for keyboard-interrupt:
  interruptp({
    pushSTACK(obj); # save obj in the STACK; the stream is safe
    pushSTACK(S(print)); tast_break(); # PRINT call break-loop
    obj = popSTACK(); # move obj back
    goto restart_it;
  });
  # test for stack overflow:
  check_SP(); check_STACK();
  # handle circularity:
  pr_circle(stream_,obj,&prin_object_dispatch);
}
local void prin_object_dispatch (const object* stream_, object obj) {
  # branch according to type-info:
#ifdef TYPECODES
  switch (typecode(obj)) {
    case_machine: # machine pointer
      pr_machine(stream_,obj); break;
    case_string: # String
      pr_string(stream_,obj); break;
    case_bvector: # Bit-Vector
      pr_bvector(stream_,obj); break;
    case_b2vector:
    case_b4vector:
    case_b8vector:
    case_b16vector:
    case_b32vector:
    case_vector: # (vector t)
      pr_vector(stream_,obj); break;
    case_mdarray: # generic array
      pr_array(stream_,obj); break;
    case_closure: # Closure
      pr_closure(stream_,obj); break;
    case_instance: # CLOS-instance
      pr_instance(stream_,obj); break;
#ifdef case_structure
    case_structure: # Structure
      pr_structure(stream_,obj); break;
#endif
#ifdef case_stream
    case_stream: # Stream
      pr_stream(stream_,obj); break;
#endif
    case_orecord: # OtherRecord
      pr_orecord(stream_,obj); break;
    case_char: # Character
      pr_character(stream_,obj); break;
    case_subr: # SUBR
      pr_subr(stream_,obj); break;
    case_system: # Frame-Pointer, Read-Label, System
      if (as_oint(obj) & wbit(0 + oint_addr_shift)) {
        if (as_oint(obj) & wbit(oint_data_len-1 + oint_addr_shift)) {
          # System-Pointer
          pr_system(stream_,obj);
        } else { # Read-Label
          pr_readlabel(stream_,obj);
        }
      } else { # Frame-Pointer
        pr_framepointer(stream_,obj);
      }
      break;
    case_number: # Number
      pr_number(stream_,obj); break;
    case_symbol: # Symbol
      pr_symbol(stream_,obj); break;
    case_cons: # Cons
      pr_cons(stream_,obj); break;
      default: NOTREACHED;
   }
#else
  if (orecordp(obj))
    pr_orecord(stream_,obj);
  else if (consp(obj))
    pr_cons(stream_,obj);
  else if (immediate_number_p(obj))
    pr_number(stream_,obj);
  else if (charp(obj))
    pr_character(stream_,obj);
  else if (subrp(obj))
    pr_subr(stream_,obj);
  else if (machinep(obj))
    pr_machine(stream_,obj);
  else if (read_label_p(obj))
    pr_readlabel(stream_,obj);
  else if (systemp(obj))
    pr_system(stream_,obj);
  else
    NOTREACHED;
#endif
}


# ------------- PRINT-Routines for various data-types --------------------

#                      -------- Symbols --------

# UP: print a symbol into a stream
# pr_symbol(&stream,sym);
# > sym: symbol
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_symbol (const object* stream_, object sym) {
  # query *PRINT-ESCAPE*:
  if (test_value(S(print_escape)) || test_value(S(print_readably))) {
    # with escape-character and maybe package-name:
    var bool case_sensitive = false;
    var object curr_pack = get_current_package();
    if (accessiblep(sym,curr_pack) &&
        # print PACK::SYMBOL even when the symbol is accessble
        # this is for writing compiled files
        nullp(Symbol_value(S(print_symbols_long)))) {
      # if symbol is accessible and not shadowed,
      # print no package-name and no package-markers.
      case_sensitive = pack_casesensitivep(curr_pack);
    } else {
      var object home;
      pushSTACK(sym); # save symbol
      if (keywordp(sym)) # Keyword ?
        goto one_marker; # yes -> print only 1 package-marker
      home = Symbol_package(sym); # home-package of the symbol
      if (nullp(home)) { # print uninterned symbol
        # query *PRINT-GENSYM*:
        if (test_value(S(print_gensym)) || test_value(S(print_readably))) {
          # use syntax #:name
          write_ascii_char(stream_,'#'); goto one_marker;
        }
        # else print without prefix
      } else { # print symbol with package-name and 1 or 2 package-markers
        pushSTACK(home); # save home-package
        pr_symbol_part(stream_,ThePackage(home)->pack_name,false); # print package-name
        home = popSTACK(); # move home-package back
        case_sensitive = pack_casesensitivep(home);
        if (externalp(STACK_0,home) &&
            # the "raison d'etre" of *PRINT-SYMBOLS-LONG* is FAS files,
            # so it forces even external symbols to be printed with "::"
            nullp(Symbol_value(S(print_symbols_long))))
          goto one_marker; # yes -> 1 package-marker
        write_ascii_char(stream_,':'); # else 2 package-marker
      one_marker:
        write_ascii_char(stream_,':');
      }
      sym = popSTACK(); # move sym back
    }
    pr_symbol_part(stream_,Symbol_name(sym),case_sensitive); # print symbol-name
  } else { # print symbol without Escape-Character:
    # print only the symbol-name under control of *PRINT-CASE*
    write_sstring_case(stream_,Symbol_name(sym));
  }
}

# UP: prints part of a symbol (package-name or symbol-name) with Escape-Character
# pr_symbol_part(&stream,string,case_sensitive);
# > string: Simple-String
# > stream: stream
# > case_sensitive: Flag, if re-reading would be case-sensitive
# < stream: stream
# can trigger GC
local void pr_symbol_part (const object* stream_, object string,
                           bool case_sensitive) {
  # find out, if the name can be printed without |...| surrounding it:
  # This can be done if it:
  # 1. is not empty and
  # 2. starts with a character with syntax-code Constituent and
  # 3. consists only of characters  with syntax-code Constituent or
  #    Nonterminating Macro and
  # 4. if it contains no lower-/upper-case letters
  #    (depending on readtable_case) and no colons and
  # 5. if it does not have Potential-Number Syntax (with *PRINT-BASE* as base).
  var uintL len = Sstring_length(string); # length
  # check condition 1:
  if (len==0)
    goto surround; # length=0 -> must use |...|
  # check conditions 2-4:
  { # need the attribute-code-table and the current syntaxcode-table:
    var object syntax_table; # syntaxcode-table, with char_code_limit elements
    var uintW rtcase; # readtable-case
    {
      var object readtable;
      get_readtable(readtable = ); # current Readtable
      syntax_table = TheReadtable(readtable)->readtable_syntax_table;
      rtcase = RTCase(readtable);
    }
    # traverse string:
    SstringDispatch(string,{
      var const chart* charptr = &TheSstring(string)->data[0];
      var uintL count = len;
      var chart c = *charptr++; # first character
      # its syntaxcode shall be constituent:
      if (!(syntax_table_get(syntax_table,c) == syntax_constituent))
        goto surround; # no -> must use |...|
      loop {
        if (attribute_of(c) == a_pack_m) # attributcode Package-Marker ?
          goto surround; # yes -> must use |...|
        if (!case_sensitive)
          switch (rtcase) {
            case case_upcase:
              if (!chareq(c,up_case(c))) # c was lower-case?
                goto surround; # yes -> must use |...|
              break;
            case case_downcase:
              if (!chareq(c,down_case(c))) # c was upper-case?
                goto surround; # yes -> must use |...|
              break;
            case case_preserve:
              break;
            case case_invert:
              break;
            default: NOTREACHED;
          }
        count--; if (count == 0) break; # string finished -> end of loop
        c = *charptr++; # the next character
        switch (syntax_table_get(syntax_table,c)) { # its syntaxcode
          case syntax_constituent:
          case syntax_nt_macro:
            break;
          default: # Syntaxcode /= Constituent, Nonterminating Macro
            goto surround; # -> must use |...|
        }
      }
    },{
      var const scint* charptr = &TheSmallSstring(string)->data[0];
      var uintL count = len;
      var chart c = as_chart(*charptr++); # first Character
      # its syntaxcode shall be Constituent:
      if (!(syntax_table_get(syntax_table,c) == syntax_constituent))
        goto surround; # no -> must use |...|
      loop {
        if (attribute_of(c) == a_pack_m) # Attributcode Package-Marker ?
          goto surround; # yes -> must use |...|
        if (!case_sensitive)
          switch (rtcase) {
            case case_upcase:
              if (!chareq(c,up_case(c))) # c was lower-case?
                goto surround; # yes -> must use |...|
              break;
            case case_downcase:
              if (!chareq(c,down_case(c))) # c was upper-case?
                goto surround; # yes -> must use |...|
              break;
            case case_preserve:
              break;
            case case_invert:
              break;
            default: NOTREACHED;
        }
        count--; if (count == 0) break; # string finished -> end of loop
        c = as_chart(*charptr++); # the next character
        switch (syntax_table_get(syntax_table,c)) { # its Syntaxcode
          case syntax_constituent:
          case syntax_nt_macro:
            break;
          default: # Syntaxcode /= Constituent, Nonterminating Macro
            goto surround; # -> must use |...|
        }
      }
    });
  }
  # check condition 5:
  {
    pushSTACK(string); # save string
    get_buffers(); # allocate two buffers, in the STACK
    # and fill:
    SstringDispatch(STACK_2,{
      var uintL index = 0;
      until (index == len) {
        var chart c = TheSstring(STACK_2)->data[index]; # the next character
        ssstring_push_extend(STACK_1,c); # into the character-buffer
        ssbvector_push_extend(STACK_0,attribute_of(c)); # and into the Attributcode-Buffer
        index++;
      }
    },{
      var uintL index = 0;
      until (index == len) {
        var chart c = as_chart(TheSmallSstring(STACK_2)->data[index]); # the next character
        ssstring_push_extend(STACK_1,c); # into the character-buffer
        ssbvector_push_extend(STACK_0,attribute_of(c)); # und into the Attributcode-Buffer
        index++;
      }
    });
    O(token_buff_2) = popSTACK(); # Attributcode-Buffer
    O(token_buff_1) = popSTACK(); # Character-Buffer
    string = popSTACK(); # move string back
    if (test_dots()) # only dots -> must use |...|
      goto surround;
    # Potential-Number-Syntax?
    {
      var uintWL base = get_print_base(); # value of *PRINT-BASE*
      var token_info_t info;
      if (test_potential_number_syntax(&base,&info))
        goto surround; # yes -> must use |...|
    }
  }
  # Name can be printed without Escape-Characters.
  if (case_sensitive)
    write_sstring(stream_,string);
  else # But obey *PRINT-CASE* along the way:
    write_sstring_case(stream_,string);
  return;
 surround: # print Names utilizing the Escape-Characters |...|:
  { # fetch syntax code table:
    var object readtable;
    get_readtable(readtable = ); # current Readtable
    pushSTACK(TheReadtable(readtable)->readtable_syntax_table);
  }
  pushSTACK(string);
  # stack layout: syntax_table, string.
  write_ascii_char(stream_,'|');
  SstringDispatch(STACK_0,{
    var uintL index = 0;
    until (index == len) {
      var chart c = TheSstring(STACK_0)->data[index]; # the next character
      switch (syntax_table_get(STACK_1,c)) { # its Syntaxcode
        case syntax_single_esc:
        case syntax_multi_esc: # The Escape-Character c is prepended by '\':
          write_ascii_char(stream_,'\\');
        default: ;
      }
      write_code_char(stream_,c); # print Character
      index++;
    }
  },{
    var uintL index = 0;
    until (index == len) {
      var chart c = as_chart(TheSmallSstring(STACK_0)->data[index]); # the next character
      switch (syntax_table_get(STACK_1,c)) { # its Syntaxcode
        case syntax_single_esc:
        case syntax_multi_esc: # The Escape-Character c is prepended by '\':
          write_ascii_char(stream_,'\\');
        default: ;
      }
      write_code_char(stream_,c); # print Character
      index++;
    }
  });
  write_ascii_char(stream_,'|');
  skipSTACK(2);
}

# UP: prints Simple-String like a part of a Symbol.
# pr_like_symbol(&stream,string);
# > string: simple-string
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_like_symbol (const object* stream_, object string) {
  # query *PRINT-ESCAPE*:
  if (test_value(S(print_escape)) || test_value(S(print_readably)))
    # print with escape-character
    pr_symbol_part(stream_,string,pack_casesensitivep(get_current_package()));
  else # print without escape-character
    write_sstring_case(stream_,string);
}

#                      -------- Characters --------

# UP: prints character to stream.
# pr_character(&stream,ch);
# > ch: character
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_character (const object* stream_, object ch) {
  # query *PRINT-ESCAPE*:
  if (test_value(S(print_escape)) || test_value(S(print_readably))) {
    # print character with escape-character.
    # Syntax:          # \ char
    # respectively     # \ charname
    write_ascii_char(stream_,'#');
    write_ascii_char(stream_,'\\');
    var chart code = char_code(ch); # code
    if (as_cint(code) > 0x20 && as_cint(code) < 0x7F) {
      # graphic standard character -> don't even lookup the name
      write_code_char(stream_,code);
    } else {
      var object charname = char_name(code); # name of the characters
      if (nullp(charname)) # no name available
        write_code_char(stream_,code);
      else # print name (Simple-String)
        write_sstring_case(stream_,charname);
    }
  } else # print character without escape-zeichen
    write_char(stream_,ch); # print ch itself
}

#                      -------- Strings --------

# UP: prints part of a simple-string to stream.
# pr_sstring_ab(&stream,string,start,len);
# > string: simple-string
# > start: startindex
# > len: number of characters to be printed
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_sstring_ab (const object* stream_, object string,
                          uintL start, uintL len) {
  # query *PRINT-ESCAPE*:
  if (test_value(S(print_escape)) || test_value(S(print_readably))) {
    # with escape-character:
    var uintL index = start;
    pushSTACK(string); # save simple-string
    write_ascii_char(stream_,'"'); # prepend a quotation mark
    string = STACK_0;
#if 0
    SstringDispatch(string,{
      dotimesL(len,len, {
        var chart c = TheSstring(STACK_0)->data[index]; # next character
        # if c = #\" or c = #\\ first print a '\':
        if (chareq(c,ascii('"')) || chareq(c,ascii('\\')))
          write_ascii_char(stream_,'\\');
        write_code_char(stream_,c);
        index++;
      });
    },{
      dotimesL(len,len, {
        var chart c = as_chart(TheSmallSstring(STACK_0)->data[index]); # next character
        # if c = #\" or c = #\\ first print a '\':
        if (chareq(c,ascii('"')) || chareq(c,ascii('\\')))
          write_ascii_char(stream_,'\\');
        write_code_char(stream_,c);
        index++;
      });
    });
#else # the same stuff, a little optimized
    SstringDispatch(string,{
      var uintL index0 = index;
      loop { # search the next #\" or #\\ :
        string = STACK_0;
        while (len > 0) {
          var chart c = TheSstring(string)->data[index];
          if (chareq(c,ascii('"')) || chareq(c,ascii('\\')))
            break;
          index++; len--;
        }
        if (!(index==index0))
          write_sstring_ab(stream_,string,index0,index-index0);
        if (len==0)
          break;
        write_ascii_char(stream_,'\\');
        index0 = index; index++; len--;
      }
    },{
      var uintL index0 = index;
      loop { # search the next #\" or #\\ :
        string = STACK_0;
        while (len > 0) {
          var chart c = as_chart(TheSmallSstring(string)->data[index]);
          if (chareq(c,ascii('"')) || chareq(c,ascii('\\')))
            break;
          index++; len--;
        }
        if (!(index==index0))
          write_sstring_ab(stream_,string,index0,index-index0);
        if (len==0)
          break;
        write_ascii_char(stream_,'\\');
        index0 = index; index++; len--;
      }
    });
#endif
    write_ascii_char(stream_,'"'); # append a quotation mark
    skipSTACK(1);
  } else # witout escape-character: only write_sstring_ab
    write_sstring_ab(stream_,string,start,len);
}

# UP: prints string to stream.
# pr_string(&stream,string);
# > string: string
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_string (const object* stream_, object string) {
  var uintL len = vector_length(string); # length
  var uintL offset = 0; # Offset of string in the data-vector
  var object sstring = array_displace_check(string,len,&offset); # data-vector
  pr_sstring_ab(stream_,sstring,offset,len);
}

#                    -------- Conses, Lists --------

# UP: determines, if a Cons is to be printed in a special manner
# special_list_p(obj)
# > obj: object, a Cons
# < result: address of the corresponding pr_list_xxx-routine, if yes,
#                                                       NULL, if no.
local pr_routine_t* special_list_p (object obj) {
  # special lists are those of the form
  # (QUOTE a), (FUNCTION a), (SYS::BACKQUOTE a [b]) and
  # (SYS::SPLICE a), (SYS::NSPLICE a), (SYS::UNQUOTE a)
  # if SYS::*PRIN-BQLEVEL* > 0
  var object head = Car(obj);
  var pr_routine_t* pr_xxx;
  if (eq(head,S(quote))) { # QUOTE
    pr_xxx = &pr_list_quote; goto test2;
  } else if (eq(head,S(function))) { # FUNCTION
    pr_xxx = &pr_list_function; goto test2;
  } else if (eq(head,S(backquote))) { # SYS::BACKQUOTE
    pr_xxx = &pr_list_backquote;
    # test, if obj is a list of length 2 or 3.
    obj = Cdr(obj);   # the CDR
    if (consp(obj) && # must be a Cons,
        (obj = Cdr(obj),                             # the CDDR must be
         (atomp(obj) ? nullp(obj) : nullp(Cdr(obj))))) # NIL or a 1-elt list
      return pr_xxx;
    else
      return (pr_routine_t*)NULL;
  } else if (eq(head,S(splice))) { # SYS::SPLICE
    pr_xxx = &pr_list_splice; goto test2bq;
  } else if (eq(head,S(nsplice))) { # SYS::NSPLICE
    pr_xxx = &pr_list_nsplice; goto test2bq;
  } else if (eq(head,S(unquote))) { # SYS::UNQUOTE
    pr_xxx = &pr_list_unquote; goto test2bq;
  } else
    return (pr_routine_t*)NULL;
 test2bq: # test, if SYS::*PRIN-BQLEVEL* > 0 and
  { # if obj is a list of length 2.
    var object bqlevel = Symbol_value(S(prin_bqlevel));
    if (!(posfixnump(bqlevel) && !eq(bqlevel,Fixnum_0)))
      return (pr_routine_t*)NULL;
  }
 test2: # test, if obj is a list of length 2.
  if (mconsp(Cdr(obj)) && nullp(Cdr(Cdr(obj))))
    return pr_xxx;
  else
    return (pr_routine_t*)NULL;
}

# UP: returns the value of the fixnum *PRINT-INDENT-LISTS*.
# get_indent_lists()
# < result: fixnum > 0
local uintL get_indent_lists (void) {
  var object obj = Symbol_value(S(print_indent_lists));
  if (posfixnump(obj)) {
    var uintL indent = posfixnum_to_L(obj);
    if (indent > 0)
      return indent;
  }
  # default value is 1.
  return 1;
}

# UP: prints list to stream, NIL as ().
# pr_list(&stream,list);
# > list: list
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_list (const object* stream_, object list) {
  if (nullp(list)) { # print NIL as ():
    write_ascii_char(stream_,'('); write_ascii_char(stream_,')');
  } else # a Cons
    pr_cons(stream_,list);
}

# UP: print a Cons to a stream.
# pr_cons(&stream,list);
# > list: cons
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_cons (const object* stream_, object list) {
  { # treat special case:
    var pr_routine_t* special = special_list_p(list);
    if (!(special == (pr_routine_t*)NULL)) {
      (*special)(stream_,list); # call special pr_list_xxx-routine
      return;
    }
  }
  LEVEL_CHECK;
  {
    var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
    var uintL length = 0; # previous length := 0
    pushSTACK(list); # save list
    var object* list_ = &STACK_0; # and memorize, where it is
    KLAMMER_AUF; # '('
    INDENT_START(get_indent_lists()); # indent by 1 character, because of '('
    JUSTIFY_START(1);
    # test for attaining of *PRINT-LENGTH* :
    CHECK_LENGTH_LIMIT(length_limit==0,goto end_of_list);
    # test for attaining of *PRINT-LINES* :
    CHECK_LINES_LIMIT(goto end_of_list);
    loop {
      # print the CAR from here
      list = *list_; *list_ = Cdr(list); # shorten list
      JUSTIFY_LAST(nullp(*list_));
      prin_object(stream_,Car(list)); # print the CAR
      length++; # increment length
      # print the remainder of the list from here
      if (nullp(*list_)) # remainder of list=NIL -> end_of_list
        goto end_of_list;
      JUSTIFY_SPACE; # print one Space
      if (matomp(*list_)) # Dotted List ?
        goto dotted_list;
      # check for attaining *PRINT-LENGTH* :
      CHECK_LENGTH_LIMIT(length >= length_limit,goto end_of_list);
      # check for attaining *PRINT-LINES* :
      CHECK_LINES_LIMIT(goto end_of_list);
      # check, if dotted-list-notation is necessary:
      list = *list_;
      if (circle_p(list,NULL)) # necessary because of circularity?
        goto dotted_list;
      if (!(special_list_p(list) == (pr_routine_t*)NULL)) # necessary because of QUOTE or similar stuff?
        goto dotted_list;
    }
  dotted_list: # print list-remainder in dotted-list-notation:
    JUSTIFY_LAST(false);
    write_ascii_char(stream_,'.');
    JUSTIFY_SPACE;
    JUSTIFY_LAST(true);
    prin_object(stream_,*list_);
    goto end_of_list;
  end_of_list: # print list content.
    JUSTIFY_END_ENG;
    INDENT_END;
    KLAMMER_ZU;
    skipSTACK(1);
  }
  LEVEL_END;
}

# output of ...                             as ...
# (quote object)                               'object
# (function object)                            #'object
# (backquote original-form [expanded-form])    `original-form
# (splice (unquote form))                      ,@form
# (splice form)                                ,@'form
# (nsplice (unquote form))                     ,.form
# (nsplice form)                               ,.'form
# (unquote form)                               ,form

local void pr_list_quote (const object* stream_, object list) {
  # list = (QUOTE object)
  pushSTACK(Car(Cdr(list))); # save (second list)
  write_ascii_char(stream_,'\''); # print "'"
  list = popSTACK();
  INDENT_START(1); # indent by 1 character because of "'"
  prin_object(stream_,list); # print object
  INDENT_END;
}

local void pr_list_function (const object* stream_, object list) {
  # list = (FUNCTION object)
  pushSTACK(Car(Cdr(list))); # save (second list)
  write_ascii_char(stream_,'#'); # print "#"
  write_ascii_char(stream_,'\''); # print "'"
  list = popSTACK();
  INDENT_START(2); # indent by 2 characters because of "#'"
  prin_object(stream_,list); # print object
  INDENT_END;
}

local void pr_list_backquote (const object* stream_, object list) {
  # list = (BACKQUOTE original-form [expanded-form])
  pushSTACK(Car(Cdr(list))); # save (second list)
  write_ascii_char(stream_,'`'); # print '`'
  list = popSTACK();
  { # increase SYS::*PRIN-BQLEVEL* by 1:
    var object bqlevel = Symbol_value(S(prin_bqlevel));
    if (!posfixnump(bqlevel))
      bqlevel = Fixnum_0;
    dynamic_bind(S(prin_bqlevel),fixnum_inc(bqlevel,1));
  }
  INDENT_START(1); # indent by 1 character because of '`'
  prin_object(stream_,list); # print original-form
  INDENT_END;
  dynamic_unbind();
}

local void pr_list_bothsplice (const object* stream_, object list, object ch) {
  # list = (SPLICE object), ch = '@' or
  # list = (NSPLICE object), ch = '.'
  pushSTACK(Car(Cdr(list))); # save (second list)
  write_ascii_char(stream_,','); # print comma
  write_char(stream_,ch); # print '@' resp. '.'
  list = popSTACK();
  # decrease SYS::*PRIN-BQLEVEL* by 1:
  dynamic_bind(S(prin_bqlevel),fixnum_inc(Symbol_value(S(prin_bqlevel)),-1));
  # is this of the form (UNQUOTE form) ?
  if (consp(list) && eq(Car(list),S(unquote))
      && mconsp(Cdr(list)) && nullp(Cdr(Cdr(list)))) { # yes -> print the form:
    list = Car(Cdr(list)); # (second object)
    INDENT_START(2); # indent by 2 characters because of ",@" resp. ",."
    prin_object(stream_,list); # print form
    INDENT_END;
  } else { # no -> print a Quote and the object:
    pushSTACK(list); # save object
    write_ascii_char(stream_,'\''); # print "'"
    list = popSTACK();
    INDENT_START(3); # indent by 3 characters because of ",@'" resp. ",.'"
    prin_object(stream_,list); # print object
    INDENT_END;
  }
  dynamic_unbind();
}

local void pr_list_splice (const object* stream_, object list) {
  # list = (SPLICE object)
  pr_list_bothsplice(stream_,list,ascii_char('@'));
}

local void pr_list_nsplice (const object* stream_, object list) {
  # list = (NSPLICE object)
  pr_list_bothsplice(stream_,list,ascii_char('.'));
}

local void pr_list_unquote (const object* stream_, object list) {
  # list = (UNQUOTE object)
  pushSTACK(Car(Cdr(list))); # save (second list)
  write_ascii_char(stream_,','); # print ','
  list = popSTACK();
  # decrease SYS::*PRIN-BQLEVEL* by 1:
  dynamic_bind(S(prin_bqlevel),fixnum_inc(Symbol_value(S(prin_bqlevel)),-1));
  INDENT_START(1); # indent by 1 character because of ','
  prin_object(stream_,list); # print object
  INDENT_END;
  dynamic_unbind();
}

#                      -------- Numbers --------

# UP: prints real number to stream.
# pr_real_number(&stream,number);
# > number: real number
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_real_number (const object* stream_, object number) {
  if (R_rationalp(number)) { # rational number
    var uintWL base = get_print_base(); # value of *PRINT-BASE*
    # query *PRINT-RADIX*:
    if (test_value(S(print_radix)) || test_value(S(print_readably))) {
      # print Radix-Specifier:
      pushSTACK(number); # save number
      switch (base) {
        case 2: # base 2
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'b'); break;
        case 8: # base 8
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'o'); break;
        case 16: # base 16
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'x'); break;
        case 10: # base 10
          if (RA_integerp(number)) {
            # mark base 10 for integers by appending a period:
            skipSTACK(1);
            print_integer(number,base,stream_);
            write_ascii_char(stream_,'.');
            return;
          }
        default: # print base in #nR-notation:
          write_ascii_char(stream_,'#');
          pr_uint(stream_,base);
          write_ascii_char(stream_,'r');
          break;
      }
      number = popSTACK();
    }
    if (RA_integerp(number)) { # print integer in base base :-) :
      print_integer(number,base,stream_);
    } else { # print ratio in base base:
      pushSTACK(TheRatio(number)->rt_den); # save denominator
      print_integer(TheRatio(number)->rt_num,base,stream_); # print enumerator
      write_ascii_char(stream_,'/'); # fraction bar
      print_integer(popSTACK(),base,stream_); # print denominator
    }
  } else # float
    print_float(number,stream_);
}

# UP: prints number to stream.
# pr_number(&stream,number);
# > number: number
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_number (const object* stream_, object number) {
  if (N_realp(number)) { # real number
    pr_real_number(stream_,number);
  } else { # complex number
    pushSTACK(number); # save number
    var object* number_ = &STACK_0; # and memorize, where it is
    write_ascii_char(stream_,'#'); write_ascii_char(stream_,'C');
    KLAMMER_AUF;
    INDENT_START(3); # indent by 3 characters because of '#C('
    JUSTIFY_START(1);
    JUSTIFY_LAST(false);
    pr_real_number(stream_,TheComplex(*number_)->c_real); # print real part
    JUSTIFY_SPACE;
    JUSTIFY_LAST(true);
    pr_real_number(stream_,TheComplex(*number_)->c_imag); # print imaginary part
    JUSTIFY_END_ENG;
    INDENT_END;
    KLAMMER_ZU;
    skipSTACK(1);
  }
}

#define UNREADABLE_START                                        \
  write_ascii_char(stream_,'#'); write_ascii_char(stream_,'<'); \
  INDENT_START(2); /* indent by 2 characters because of '#<' */ \
  JUSTIFY_START(1)

#define UNREADABLE_END     INDENT_END;write_ascii_char(stream_,'>')

#            -------- Arrays when *PRINT-ARRAY*=NIL --------

# UP: prints array in short form to stream.
# pr_array_nil(&stream,obj);
# > obj: array
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_array_nil (const object* stream_, object obj) {
  pushSTACK(obj); # save array
  var object* obj_ = &STACK_0; # and memorize, where it is
  UNREADABLE_START;
  JUSTIFY_LAST(false);
  write_sstring_case(stream_,O(printstring_array)); # print "ARRAY"
  JUSTIFY_SPACE;
  JUSTIFY_LAST(false);
  prin_object_dispatch(stream_,array_element_type(*obj_)); # print elementtype (symbol or list)
  JUSTIFY_SPACE;
  JUSTIFY_LAST(!array_has_fill_pointer_p(*obj_));
  pr_list(stream_,array_dimensions(*obj_)); # print dimension-list
  if (array_has_fill_pointer_p(*obj_)) {
    # Array with fill-pointer -> also print the fill-pointer:
    JUSTIFY_SPACE;
    JUSTIFY_LAST(true);
    write_sstring_case(stream_,O(printstring_fill_pointer)); # print "FILL-POINTER="
    pr_uint(stream_,vector_length(*obj_)); # print length (=fill-pointer)
  }
  JUSTIFY_END_ENG;
  UNREADABLE_END;
  skipSTACK(1);
}

#                    -------- Bit-Vectors --------

# UP: prints part of a simple-bit-vector to stream.
# pr_sbvector_ab(&stream,bv,start,len);
# > bv: simple-bit-vector
# > start: startindex
# > len: number of the bits to be printed
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_sbvector_ab (const object* stream_, object bv,
                           uintL start, uintL len) {
  var uintL index = start;
  pushSTACK(bv); # save simple-bit-vector
  write_ascii_char(stream_,'#'); write_ascii_char(stream_,'*');
  dotimesL(len,len, {
    write_char(stream_,
               (sbvector_btst(STACK_0,index) ?
                ascii_char('1') : ascii_char('0')));
    index++;
  });
  skipSTACK(1);
}

# UP: prints bit-vector to stream.
# pr_bvector(&stream,bv);
# > bv: bit-vector
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_bvector (const object* stream_, object bv) {
  # query *PRINT-ARRAY*:
  if (test_value(S(print_array)) || test_value(S(print_readably))) {
    # print bv elementwise:
    var uintL len = vector_length(bv); # length
    var uintL offset = 0; # offset of bit-vector into the data-vector
    var object sbv = array_displace_check(bv,len,&offset); # data-vector
    pr_sbvector_ab(stream_,sbv,offset,len);
  } else # *PRINT-ARRAY* = NIL -> print in short form:
    pr_array_nil(stream_,bv);
}

#                -------- Generic Vectors --------

# UP: prints generic vector to stream.
# pr_vector(&stream,v);
# > v: generic vector
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_vector (const object* stream_, object v) {
  # query *PRINT-ARRAY*:
  if (test_value(S(print_array)) || test_value(S(print_readably))) {
    # print v elementwise:
    LEVEL_CHECK;
    {
      var bool readable = # Flag, if length and type are also printed
        (test_value(S(print_readably)) && !general_vector_p(v) ? true : false);
      var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
      var uintL length = 0; # previous length := 0
      # process vector elementwise:
      var uintL len = vector_length(v); # vector-length
      var uintL offset = 0; # offset of vector into the data-vector
      {
        var object sv = array_displace_check(v,len,&offset); # data-vector
        pushSTACK(sv); # save simple-vektor
      }
      var object* sv_ = &STACK_0; # and memorize, where it is
      var uintL index = 0 + offset; # startindex = 0 in the vector
      if (readable) {
        write_ascii_char(stream_,'#'); write_ascii_char(stream_,'A');
        KLAMMER_AUF; # print '('
        INDENT_START(3); # indent by 3 characters because of '#A('
        JUSTIFY_START(1);
        JUSTIFY_LAST(false);
        prin_object_dispatch(stream_,array_element_type(*sv_)); # print elementtype
        JUSTIFY_SPACE;
        JUSTIFY_LAST(false);
        pushSTACK(fixnum(len));
        pr_list(stream_,listof(1)); # print list with the length
        JUSTIFY_SPACE;
        JUSTIFY_LAST(true);
        KLAMMER_AUF; # '('
        INDENT_START(1); # indent by  1 character because of '('
      } else {
        write_ascii_char(stream_,'#');
        KLAMMER_AUF; # '('
        INDENT_START(2); # indent by 2 characters because of '#('
      }
      JUSTIFY_START(1);
      for (; len > 0; len--) {
        # print Space (unless in front of first elemnt):
        if (!(length==0))
          JUSTIFY_SPACE;
        # check for attaining of *PRINT-LENGTH* :
        CHECK_LENGTH_LIMIT(length >= length_limit,break);
        # test for attaining of *PRINT-LINES* :
        CHECK_LINES_LIMIT(break);
        JUSTIFY_LAST(len==1);
        # print vector-element:
        prin_object(stream_,storagevector_aref(*sv_,index));
        length++; # increment length
        index++; # then go to vector-element
      }
      JUSTIFY_END_ENG;
      INDENT_END;
      KLAMMER_ZU;
      if (readable) {
        JUSTIFY_END_ENG;
        INDENT_END;
        KLAMMER_ZU;
      }
      skipSTACK(1);
    }
    LEVEL_END;
  } else # *PRINT-ARRAY* = NIL -> print in short form:
    pr_array_nil(stream_,v);
}

#               -------- Multi-Dimensional Arrays --------

# (defun %print-array (array stream)
#   (let ((rank (array-rank array))
#         (dims (array-dimensions array))
#         (eltype (array-element-type array)))
#     (write-char #\# stream)
#     (if (zerop (array-total-size array))
#       ; rereadable Output of empty multi-dimensional Arrays
#       (progn
#         (write-char #\A stream)
#         (prin1 dims stream)
#       )
#       (progn
#         (let ((*print-base* 10.)) (prin1 rank stream))
#         (write-char #\A stream)
#         (if (and (plusp rank)
#                  (or (eq eltype 'bit) (eq eltype 'character))
#                  (or (null *print-length*) (>= *print-length* (array-dimension array (1- rank))))
#             )
#           ; shorter Output of multidimensional Bit- and Character-Arrays
#           (let* ((lastdim (array-dimension array (1- rank)))
#                  (offset 0)
#                  (sub-array (make-array 0 :element-type eltype :adjustable t)))
#             (labels ((help (dimsr)
#                        (if (null dimsr)
#                          (progn
#                            (prin1
#                              (adjust-array sub-array lastdim :displaced-to array
#                                            :displaced-index-offset offset
#                              )
#                              stream
#                            )
#                            (setq offset (+ offset lastdim))
#                          )
#                          (let ((dimsrr (rest dimsr)))
#                            (write-char #\( stream)
#                            (dotimes (i (first dimsr))
#                              (unless (zerop i) (write-char #\space stream))
#                              (help dimsrr)
#                            )
#                            (write-char #\) stream)
#                     )) ) )
#               (help (nbutlast dims))
#           ) )
#           ; normal Output of multidimensional Arrays
#           (let ((indices (make-list rank))) ; List of rank Indices
#             (labels ((help (dimsr indicesr)
#                        (if (null dimsr)
#                          (prin1 (apply #'aref array indices) stream)
#                          (let ((dimsrr (rest dimsr)) (indicesrr (rest indicesr)))
#                            (write-char #\( stream)
#                            (dotimes (i (first dimsr))
#                              (unless (zerop i) (write-char #\space stream))
#                              (rplaca indicesr i)
#                              (help dimsrr indicesrr)
#                            )
#                            (write-char #\) stream)
#                     )) ) )
#               (help dims indices)
#           ) )
#       ) )
# ) ) )

# sub-routines for printing of an element resp. a sub-array:
# pr_array_elt_xxx(&stream,obj,&info);
# > obj: data-vector
# > info.index: index of the first to be printed element
# > info.count: number of the elements to be printed
# > stream: stream
# < stream: stream
# < info.index: increased by info.count
# can trigger GC
typedef struct {
  uintL index;
  uintL count;
} pr_array_info_t;
typedef void pr_array_elt_routine_t (const object* stream_, object obj,
                                     pr_array_info_t* info);
# subroutine for printing an element:
# info.count = 1 for this routine.
local pr_array_elt_routine_t pr_array_elt_simple;
# Two SRs for printing a sub-array:
local pr_array_elt_routine_t pr_array_elt_bvector; # sub-array is bit-vector
local pr_array_elt_routine_t pr_array_elt_string; # sub-array is string

local void pr_array_elt_simple (const object* stream_, object obj,
                                pr_array_info_t* info) { # simple-vector
  # fetch element of generic type and print:
  prin_object(stream_,storagevector_aref(obj,info->index));
  info->index++;
}

local void pr_array_elt_bvector (const object* stream_, object obj,
                                 pr_array_info_t* info) { # simple-bit-vector
  # print sub-bit-vector:
  pr_sbvector_ab(stream_,obj,info->index,info->count);
  info->index += info->count;
}

local void pr_array_elt_string (const object* stream_, object obj,
                                  pr_array_info_t* info) { # simple-string
  # print sub-string:
  pr_sstring_ab(stream_,obj,info->index,info->count);
  info->index += info->count;
}

# UP: prints part of an array.
# pr_array_recursion(locals,depth);
# > depth: recursion-depth
# > locals: Variables:
#     *(locals->stream_) :   stream
#     *(locals->obj_) :      data-vector
#     locals->dims_sizes:    address of the table of dimensions of the array
#                            and its sub-products
#     *(locals->pr_one_elt): function for printing an element/sub-arrays
#     locals->info:          parameter for this function
#     locals->info.index:    start-index in datenvector
#     locals->length_limit:  length-limit
# < locals->info.index: end-index in the data-vector
# can trigger GC
typedef struct {
  const object* stream_;
  const object* obj_;
  const array_dim_size* dims_sizes;
  pr_array_elt_routine_t* pr_one_elt;
  pr_array_info_t info;
  uintL length_limit;
} pr_array_locals_t;
local void pr_array_recursion (pr_array_locals_t* locals, uintL depth) {
  check_SP(); check_STACK();
  if (depth==0) { # recursion-depth 0 -> start(base) of recursion
    (*(locals->pr_one_elt)) # call function pr_one_elt, with
      (locals->stream_, # address of stream,
       *(locals->obj_), # data-vector obj,
       &(locals->info) # infopointer
       ); # as arguments
    # This function increases locals->info.index itself.
  } else {
    depth--; # decrease recursion-depth (still >=0)
    var const object* stream_ = locals->stream_;
    var uintL length = 0; # previous length := 0
    var uintL endindex = locals->info.index # start-index in data vector
      + locals->dims_sizes[depth].dimprod # + dimension product
      ; # delivers the end-index of this sub-array
    var uintL count = locals->dims_sizes[depth].dim;
    KLAMMER_AUF; # print '('
    INDENT_START(1); # indent by 1 character, because of '('
    JUSTIFY_START(1);
    # loop over dimension (r-depth): print a sub-array at a time
    for (; count > 0; count--) {
      # print Space(except before the first sub-array):
      if (!(length==0))
        JUSTIFY_SPACE;
      # check for attaining of *PRINT-LENGTH* :
      CHECK_LENGTH_LIMIT(length >= locals->length_limit,break);
      # test for attaining of *PRINT-LINES* :
      CHECK_LINES_LIMIT(break);
      JUSTIFY_LAST(count==1);
      # print sub-array:
      # (recursively, with decreased depth, and locals->info.index
      # is passed from one call to the next call
      # without requiring further action)
      pr_array_recursion(locals,depth);
      length++; # increment length :-)
      # locals->info.index is already incremented
    }
    JUSTIFY_END_WEIT;
    INDENT_END;
    KLAMMER_ZU; # print ')'
    locals->info.index = endindex; # reached end-index
  }
}

# UP: prints multi-dimensional array to stream.
# pr_array(&stream,obj);
# > obj: multi-dimensional array
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_array (const object* stream_, object obj) {
  # query *PRINT-ARRAY* :
  if (test_value(S(print_array)) || test_value(S(print_readably))) {
    # print obj elementwise:
    LEVEL_CHECK;
    { # determine rank and fetch dimensions and sub-product:
      var uintL r = (uintL)Iarray_rank(obj); # rank
      var DYNAMIC_ARRAY(dims_sizes,array_dim_size,r); # dynamically allocated array
      iarray_dims_sizes(obj,dims_sizes); # fill
      var uintL depth = r; # depth of recursion
      var pr_array_locals_t locals; # local variables
      var bool readable = true; # Flag, if dimensions and type are also printed
      locals.stream_ = stream_;
      locals.dims_sizes = dims_sizes;
      locals.length_limit = get_print_length(); # length limit
      { # decision over routine to be used:
        var uintB atype = Iarray_flags(obj) & arrayflags_atype_mask;
        if ((r>0) && (locals.length_limit >= dims_sizes[0].dim)) {
          switch (atype) {
            case Atype_Bit: # print whole bitvectors instead of single bits
              locals.pr_one_elt = &pr_array_elt_bvector;
              goto nicht_einzeln;
            case Atype_Char: # print whole Strings instead of single Characters
              locals.pr_one_elt = &pr_array_elt_string;
          nicht_einzeln:
                  # don't print single einzelne elements, but one-dimensional
                  # sub-arrays.
              depth--; # therefore depth := r-1
              locals.info.count = dims_sizes[0].dim; # Dim_r as "Elementary length"
              locals.dims_sizes++; # consider only Dim_1, ..., Dim_(r-1)
              readable = false; # automatically rereadable
              goto routine_ok;
            default: ;
          }
        }
        locals.pr_one_elt = &pr_array_elt_simple;
        locals.info.count = 1; # 1 as "Elementary length"
        if (atype==Atype_T)
          readable = false; # automatically rereadable
      routine_ok:
        locals.info.index = 0; # start-index is 0
      }
      if (!test_value(S(print_readably)))
        readable = false; # does not need to be rereadable
      pushSTACK(obj); # save array
      var object* obj_ = &STACK_0; # and memorize, where it is
      # fetch data-vector:
      var uintL size = TheIarray(obj)->totalsize;
      if (size == 0)
        readable = true; # or else you even don't know the dimensions
      obj = iarray_displace_check(obj,size,&locals.info.index); # data-vector
      # locals.info.index = Offset from  array to the data-vector
      pushSTACK(obj); locals.obj_ = &STACK_0; # store obj in Stack
      # now go ahead.
      if (readable) {
        write_ascii_char(stream_,'#'); write_ascii_char(stream_,'A');
        KLAMMER_AUF; # print '('
        INDENT_START(3); # indent by 3 characters, because of '#A('
        JUSTIFY_START(1);
        JUSTIFY_LAST(false);
        prin_object_dispatch(stream_,array_element_type(*obj_)); # print element-type (Symbol or List)
        JUSTIFY_SPACE;
        JUSTIFY_LAST(false);
        pr_list(stream_,array_dimensions(*obj_)); # print dimension-list
        JUSTIFY_SPACE;
        JUSTIFY_LAST(true);
        pr_array_recursion(&locals,depth); # print array-elements
        JUSTIFY_END_ENG;
        INDENT_END;
        KLAMMER_ZU; # print ')'
      } else {
        # first, print prefix #nA :
        INDENTPREP_START;
        write_ascii_char(stream_,'#');
        pr_uint(stream_,r); # print rank decimally
        write_ascii_char(stream_,'A');
        {
          var uintL indent = INDENTPREP_END;
          # then print the array-elements:
          INDENT_START(indent);
        }
        pr_array_recursion(&locals,depth);
        INDENT_END;
      }
      skipSTACK(2);
      FREE_DYNAMIC_ARRAY(dims_sizes);
    }
    LEVEL_END;
  } else # *PRINT-ARRAY* = NIL -> print in short form:
    pr_array_nil(stream_,obj);
}

#                    -------- CLOS-instances --------

local void pr_sharp_dot (const object* stream_,object obj) {
  pushSTACK(obj); # save form
  write_ascii_char(stream_,'#'); write_ascii_char(stream_,'.');
  obj = popSTACK(); # recall form
  INDENT_START(2); # indent by 2 characters, because of '#.'
  prin_object(stream_,obj); # print form
  INDENT_END;
}

# UP: prints CLOS-instance to stream.
# pr_instance(&stream,obj);
# > obj: CLOS-Instance
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_instance (const object* stream_, object obj) {
  if (test_value(S(compiling))) { # compiling - use MAKE-LOAD-FORM (clos.lisp)
    pushSTACK(obj); # save obj
    pushSTACK(obj); funcall(S(make_init_form),1);
    obj = popSTACK(); # recall obj
    if (!nullp(value1)) {
      pr_sharp_dot(stream_,value1);
      return;
    }
  }
  LEVEL_CHECK;
  # execute (CLOS:PRINT-OBJECT obj stream) :
  var uintC count = pr_external_1(*stream_); # instantiate bindings
  pushSTACK(obj); pushSTACK(*stream_); funcall(S(print_object),2);
  pr_external_2(count); # dissolve bindings
  LEVEL_END;
}

#                     -------- Structures --------

# (defun %print-structure (structure stream)
#   (let ((name (type-of structure)))
#     (let ((fun (get name 'STRUCTURE-PRINT)))
#       (if fun
#         (funcall fun structure stream *PRIN-LEVEL*)
#         (print-object structure stream)
# ) ) ) )
# (defmethod print-object ((structure structure-object) stream)
#   (print-structure structure stream)
# )
# (defun print-structure (structure stream)
#   (let ((description (get name 'DEFSTRUCT-DESCRIPTION)))
#     (if description
#       (let ((readable (svref description 2)))
#         (write-string (if readable "#S(" "#<") stream)
#         (prin1 name stream)
#         (dolist (slot (svref description 3))
#           (when (first slot)
#             (write-char #\space stream)
#             (prin1 (intern (symbol-name (first slot)) *KEYWORD-PACKAGE*) stream)
#             (write-char #\space stream)
#             (prin1 (%structure-ref name structure (second slot)) stream)
#         ) )
#         (write-string (if readable ")" ">") stream)
#       )
#       (progn
#         (write-string "#<" stream)
#         (prin1 name stream)
#         (do ((l (%record-length structure))
#              (i 1 (1+ i)))
#             ((>= i l))
#           (write-char #\space stream)
#           (prin1 (%structure-ref name structure i) stream)
#         )
#         (write-string ">" stream)
# ) ) ) )

# UP: call of a (external) print-function for structures
# pr_structure_external(&stream,structure,function);
# > stream: stream
# > structure: structure
# > function: print-function for structures of this type
# can trigger GC
local void pr_structure_external (const object* stream_, object structure,
                                  object function) {
  LEVEL_CHECK;
  var object stream = *stream_;
  var uintC count = pr_external_1(stream); # create bindings
  # (funcall fun Structure Stream SYS::*PRIN-LEVEL*) :
  pushSTACK(structure); # Structure = 1st argument
  pushSTACK(stream); # Stream = 2nd argument
  pushSTACK(Symbol_value(S(prin_level))); # SYS::*PRIN-LEVEL* = 3rd Argument
  funcall(function,3);
  pr_external_2(count); # dissolve bindings
  LEVEL_END;
}

# UP: prints structure to stream.
# pr_structure(&stream,structure);
# > structure: structure
# > stream: stream
# < stream: stream   :-) (great documentation, right? )
# can trigger GC
local void pr_structure (const object* stream_, object structure) {
  # determine type of the structure (ref. TYPE-OF):
  var object name = Car(TheStructure(structure)->structure_types);
  # name = (car '(name_1 ... name_i-1 name_i)) = name_1.
  # execute (GET name 'SYS::STRUCTURE-PRINT) :
  var object fun = get(name,S(structure_print));
  if (!eq(fun,unbound)) { # call given print-function:
    pr_structure_external(stream_,structure,fun);
  } else { # no given print-function found.
    # call CLOS:PRINT-OBJECT:
    pr_instance(stream_,structure);
  }
}

# UP: print structure to stream.
# pr_structure_default(&stream,structure);
# > structure: structure
# > stream: stream
# < stream: stream
# can trigger GC
local bool some_printable_slots (object slotlist) {
  while (consp(slotlist)) {
    var object slot = Car(slotlist);
    if (simple_vector_p(slot) && (Svector_length(slot) >= 7)
        && !nullp(TheSvector(slot)->data[0]))
      return true;
    slotlist = Cdr(slotlist);
  }
  return false;
}
local void pr_structure_default (const object* stream_, object structure) {
  var object name = Car(TheStructure(structure)->structure_types);
  # name = (car '(name_1 ... name_i-1 name_i)) = name_1.
  pushSTACK(structure);
  pushSTACK(name);
  var object* structure_ = &STACK_1;
  # it is  *(structure_ STACKop 0) = structure
  # and    *(structure_ STACKop -1) = name .
  # execute (GET name 'SYS::DEFSTRUCT-DESCRIPTION) :
  var object description = get(name,S(defstruct_description));
  if (!eq(description,unbound)) { # print structure with slot-name:
    pushSTACK(description);
    # stack layout: structure, name, description.
    # description must be a simple-vector of length >=4 !
    if (!(simple_vector_p(description)
          && (Svector_length(description) >= 4))) {
    bad_description:
      pushSTACK(S(defstruct_description));
      pushSTACK(S(print));
      fehler(error,GETTEXT("~: bad ~"));
    }
    var bool readable = # true if (svref description 2) /= NIL
      !nullp(TheSvector(description)->data[2]);
    if (readable) { # print structure re-readably:
      write_ascii_char(stream_,'#'); write_ascii_char(stream_,'S');
      KLAMMER_AUF;
      INDENT_START(3); # indent by 3 characters, because of '#S('
      JUSTIFY_START(1);
    } else { # print structure non-rereadably:
      CHECK_PRINT_READABLY(*structure_);
      UNREADABLE_START;
    }
    pushSTACK(TheSvector(*(structure_ STACKop -2))->data[3]);
    JUSTIFY_LAST(!some_printable_slots(STACK_0));
    prin_object(stream_,*(structure_ STACKop -1)); # print name
    # loop through slot-list STACK_0 = (svref description 3) :
    {
      var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
      var uintL length = 0; # previous length := 0
      while (mconsp(STACK_0)) {
        var object slot = STACK_0;
        STACK_0 = Cdr(slot); # shorten list
        slot = Car(slot); # a single slot
        if (!(simple_vector_p(slot)
              && (Svector_length(slot) >= 7)))
          goto bad_description; # should be a ds-slot
        if (!nullp(TheSvector(slot)->data[0])) { # skip Slot #(NIL ...)
          pushSTACK(slot); # save slot
          JUSTIFY_SPACE; # print Space
          # check for attaining of *PRINT-LENGTH* :
          CHECK_LENGTH_LIMIT(length >= length_limit,
                             skipSTACK(1); # forget slot
                             break);
          # test for attaining of *PRINT-LINES* :
          CHECK_LINES_LIMIT(skipSTACK(1);break);
          JUSTIFY_LAST(!some_printable_slots(STACK_1));
          var object* slot_ = &STACK_0; # there is the slot
          JUSTIFY_START(0);
          JUSTIFY_LAST(false);
          write_ascii_char(stream_,':'); # keyword-mark
          {
            var object obj = TheSvector(*slot_)->data[0]; # (ds-slot-name slot)
            if (!symbolp(obj)) goto bad_description; # should be a symbol
            pr_like_symbol(stream_,Symbol_name(obj)); # print symbolname of component
          }
          JUSTIFY_SPACE;
          JUSTIFY_LAST(true);
          # (SYS::%%STRUCTURE-REF name Structure (ds-slot-offset slot)):
          pushSTACK(*(structure_ STACKop -1)); # name as 1. Argument
          pushSTACK(*(structure_ STACKop 0)); # Structure as 2. Argument
          pushSTACK(TheSvector(*slot_)->data[2]); # (ds-slot-offset slot) as 3. Argument
          funcall(L(pstructure_ref),3);
          prin_object(stream_,value1); # print component
          JUSTIFY_END_ENG;
          skipSTACK(1); # forget slot
        }
      }
    }
    skipSTACK(1);
    JUSTIFY_END_ENG;
    if (readable) { # completion of fall differentiation from above
      INDENT_END;
      KLAMMER_ZU;
    } else {
      UNREADABLE_END;
    }
    skipSTACK(3);
  } else { # print structure elementwise, without component-name.
    CHECK_PRINT_READABLY(*structure_);
    UNREADABLE_START;
    var uintC len = Structure_length(*structure_); # Length of Structure (>=1)
    JUSTIFY_LAST(len==1);
    prin_object(stream_,*(structure_ STACKop -1)); # print name
    var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
    var uintL length = 0; # Index = previous length := 0
    for (len = len-1; len > 0; len--) {
      JUSTIFY_SPACE; # print Space
      # check for attaining of *PRINT-LENGTH* :
      CHECK_LENGTH_LIMIT(length >= length_limit,break);
      # test for attaining of *PRINT-LINES* :
      CHECK_LINES_LIMIT(break);
      JUSTIFY_LAST(len==1);
      length++; # increase index
      # print component:
      prin_object(stream_,TheStructure(*structure_)->recdata[length]);
    }
    JUSTIFY_END_ENG;
    INDENT_END;
    write_ascii_char(stream_,'>');
    skipSTACK(2);
  }
}

# This is the default-function, which is called by CLOS:PRINT-OBJECT:
LISPFUNN(print_structure,2)
  {
    # stack layout: structure, stream.
    var object structure = STACK_1;
    if (!structurep(structure)) {
      pushSTACK(structure);           # TYPE-ERROR slot DATUM
      pushSTACK(S(structure_object)); # TYPE-ERROR slot EXPECTED-TYPE
      pushSTACK(structure); # structure
      pushSTACK(TheSubr(subr_self)->name); # function name
      fehler(type_error,GETTEXT("~: ~ is not a structure"));
    }
    if (!streamp(STACK_0))
      fehler_stream(STACK_0);
    pr_enter(&STACK_0,structure,&pr_structure_default);
    skipSTACK(2);
    value1 = NIL; mv_count=1;
  }

#                 -------- machine pointer --------

# UP: prints object #<BLABLA #x......> to stream.
# pr_hex6_obj(&stream,obj,string);
# > obj: object
# > string: simple-string "BLABLA"
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_hex6_obj (const object* stream_, object obj, object string) {
  pushSTACK(string); # save string
  var object* string_ = &STACK_0; # and memorize, where it is
  UNREADABLE_START;
  JUSTIFY_LAST(false);
  write_sstring_case(stream_,*string_); # print string
  JUSTIFY_SPACE;
  JUSTIFY_LAST(true);
  pr_hex6(stream_,obj); # print obj as an address
  JUSTIFY_END_ENG;
  UNREADABLE_END;
  skipSTACK(1);
}

# UP: prints machine-pointer to stream.
# pr_machine(&stream,obj);
# > obj: machine-pointer
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_machine (const object* stream_, object obj) {
  # #<ADDRESS #x...>
  CHECK_PRINT_READABLY(obj);
  pr_hex6_obj(stream_,obj,O(printstring_address));
}

#        -------- Frame-Pointer, Read-Label, System --------

# UP: prints systempointer to stream.
# pr_system(&stream,obj);
# > obj: systempointer
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_system (const object* stream_, object obj) {
  CHECK_PRINT_READABLY(obj);
  if (eq(obj,unbound)) # #<UNBOUND>
    write_sstring_case(stream_,O(printstring_unbound));
  else if (eq(obj,specdecl)) # #<SPECIAL REFERENCE>
    write_sstring_case(stream_,O(printstring_special_reference));
  else if (eq(obj,disabled)) # #<DISABLED POINTER>
    write_sstring_case(stream_,O(printstring_disabled_pointer));
  else if (eq(obj,dot_value)) # #<DOT>
    write_sstring_case(stream_,O(printstring_dot));
  else if (eq(obj,eof_value)) # #<END OF FILE>
    write_sstring_case(stream_,O(printstring_eof));
  else # #<SYSTEM-POINTER #x...>
    pr_hex6_obj(stream_,obj,O(printstring_system));
}

# UP: prints  read-label to stream.
# pr_readlabel(&stream,obj);
# > obj: Read-Label
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_readlabel (const object* stream_, object obj) {
  CHECK_PRINT_READABLY(obj);
  # #<READ-LABEL ...>
  UNREADABLE_START;
  JUSTIFY_LAST(false);
  write_sstring_case(stream_,O(printstring_read_label)); # "READ-LABEL"
  JUSTIFY_SPACE;
  JUSTIFY_LAST(true);
#ifdef TYPECODES
  pr_uint(stream_,(as_oint(obj) >> (oint_addr_shift+1)) & (bit(oint_data_len-2)-1)); # print bits 21..0 decimally
#else
  pr_uint(stream_,(as_oint(obj) >> oint_addr_shift) & (bit(oint_data_len)-1)); # print bits decimally
#endif
  JUSTIFY_END_ENG;
  UNREADABLE_END;
}

# UP: prints framepointer to stream.
# pr_framepointer(&stream,obj);
# > obj: Frame-Pointer
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_framepointer (const object* stream_, object obj) {
  CHECK_PRINT_READABLY(obj);
  # #<FRAME-POINTER #x...>
  pr_hex6_obj(stream_,obj,O(printstring_frame_pointer));
}

#                        -------- Records --------

# UP: prints the remainder of a Record. Only within a JUSTIFY-block!
# The output normally starts with a JUSTIFY_SPACE.
# pr_record_ab(&stream,&obj,start,now);
# > obj: record
# > start: startindex
# > now: number of already printed items (for *PRINT-LENGTH*)
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_record_ab (const object* stream_, const object* obj_,
                         uintL index, uintL length) {
  var uintL len = Record_length(*obj_); # length of record
  var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
  loop {
    if (index >= len) break; # index >= Recordlength -> finished
    JUSTIFY_SPACE; # print Space
    # check for attaining of *PRINT-LENGTH* :
    CHECK_LENGTH_LIMIT(length >= length_limit,break);
    # test for attaining of *PRINT-LINES* :
    CHECK_LINES_LIMIT(break);
    JUSTIFY_LAST(index+1 >= len);
    # print component:
    prin_object(stream_,TheRecord(*obj_)->recdata[index]);
    length++; # increase previous length
    index++; # next component
  }
}

# UP: prints a list as the rest of a record.
# Only within a JUSTIFY-blocks!
# The output starts normally with a JUSTIFY_SPACE.
# pr_record_rest(&stream,obj,now);
# > obj: list
# > now: number of already printed items (for *PRINT-LENGTH*)
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_record_rest (const object* stream_, object obj, uintL length) {
  var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
  pushSTACK(obj);
  while (mconsp(STACK_0)) {
    JUSTIFY_SPACE; # print Space
    # check for attaining of *PRINT-LENGTH* :
    CHECK_LENGTH_LIMIT(length >= length_limit,break);
    # test for attaining of *PRINT-LINES* :
    CHECK_LINES_LIMIT(break);
    {
      var object list = STACK_0;
      STACK_0 = Cdr(list); # shorten list
      JUSTIFY_LAST(matomp(STACK_0));
      prin_object(stream_,Car(list)); # print element of list
    }
    length++; # increment length
  }
  skipSTACK(1);
}

# UP: print an OtherRecord with slotname to stream.
# pr_record_descr(&stream,obj,name,readable,slotlist);
# > obj: OtherRecord
# > name: structure-name
# > readable: Flag, if to print re-readably
# > slotlist: list ((slotname . accessor) ...)
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_record_descr (const object* stream_, object obj,
                            object name, bool readable, object slotlist) {
  LEVEL_CHECK;
  {
    pushSTACK(obj);
    pushSTACK(name);
    pushSTACK(slotlist);
    # stack layout: obj, name, slotlist.
    var object* obj_ = &STACK_2;
    # Es ist *(obj_ STACKop 0) = obj
    # und    *(obj_ STACKop -1) = name
    # und    *(obj_ STACKop -2) = slotlist .
    if (readable) { # print obj re-readably:
      write_ascii_char(stream_,'#'); write_ascii_char(stream_,'S');
      KLAMMER_AUF;
      INDENT_START(3); # indent by 3 characters, because of '#S('
      JUSTIFY_START(1);
    } else { # print obj non-re-readably:
      CHECK_PRINT_READABLY(STACK_2);
      UNREADABLE_START;
    }
    pushSTACK(*(obj_ STACKop -2));
    JUSTIFY_LAST(matomp(STACK_0));
    prin_object(stream_,*(obj_ STACKop -1)); # print name
    # loop over slot-list STACK_0 = (svref description 3) :
    {
      var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
      var uintL length = 0; # previous length := 0
      while (mconsp(STACK_0)) {
        {
          var object slotlistr = STACK_0;
          STACK_0 = Cdr(slotlistr); # shorten list
          pushSTACK(Car(slotlistr)); # a single slot
        }
        JUSTIFY_SPACE; # print Space
        # check attaining of *PRINT-LENGTH* :
        CHECK_LENGTH_LIMIT(length >= length_limit,
                           skipSTACK(1); # forget slot
                           break);
        # test for attaining of *PRINT-LINES* :
        CHECK_LINES_LIMIT(skipSTACK(1);break);
        JUSTIFY_LAST(matomp(STACK_1));
        var object* slot_ = &STACK_0; # there's the slot
        JUSTIFY_START(0);
        JUSTIFY_LAST(false);
        write_ascii_char(stream_,':'); # Keyword-mark
        # (first slot) should be a symbol
        pr_like_symbol(stream_,Symbol_name(Car(*slot_))); # print symbolnames of the component
        JUSTIFY_SPACE;
        JUSTIFY_LAST(true);
        pushSTACK(*(obj_ STACKop 0)); # obj as argument
        funcall(Cdr(*slot_),1); # call accessor
        prin_object(stream_,value1); # print component
        JUSTIFY_END_ENG;
        skipSTACK(1); # forget slot
      }
    }
    skipSTACK(1);
    JUSTIFY_END_ENG;
    if (readable) { # completion of fall differentiation from above
      INDENT_END;
      KLAMMER_ZU;
    } else {
      UNREADABLE_END;
    }
    skipSTACK(3);
  }
  LEVEL_END;
}

# UP: prints an OtherRecord to stream.
# pr_orecord(&stream,obj);
# > obj: OtherRecord
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_orecord (const object* stream_, object obj) {
  switch (Record_type(obj)) {
#ifndef TYPECODES
    case Rectype_string: case Rectype_Sstring: case Rectype_Imm_Sstring:
    case Rectype_Imm_SmallSstring: # String
      pr_string(stream_,obj); break;
    case Rectype_bvector: case Rectype_Sbvector: # bit-vector
      pr_bvector(stream_,obj); break;
    case Rectype_b2vector: case Rectype_Sb2vector: # 2bit-vector
    case Rectype_b4vector: case Rectype_Sb4vector: # 4bit-vector
    case Rectype_b8vector: case Rectype_Sb8vector: # 8bit-vector
    case Rectype_b16vector: case Rectype_Sb16vector: # 16bit-vector
    case Rectype_b32vector: case Rectype_Sb32vector: # 32bit-vector
    case Rectype_vector: case Rectype_Svector: # (vector t)
      pr_vector(stream_,obj); break;
    case Rectype_mdarray: # generic Array
      pr_array(stream_,obj); break;
    case Rectype_Closure: # Closure
      pr_closure(stream_,obj); break;
    case Rectype_Instance: # CLOS-Instance
      pr_instance(stream_,obj); break;
    case Rectype_Complex: case Rectype_Ratio:
    case Rectype_Dfloat: case Rectype_Ffloat: case Rectype_Lfloat:
    case Rectype_Bignum: # number
      pr_number(stream_,obj); break;
    case Rectype_Symbol: # Symbol
      pr_symbol(stream_,obj); break;
#endif
    case Rectype_Hashtable:
      # depending on *PRINT-ARRAY* :
      # #<HASH-TABLE #x...> or
      # #S(HASH-TABLE test (Key_1 . Value_1) ... (Key_n . Value_n))
      if (test_value(S(print_array)) || test_value(S(print_readably))) {
        LEVEL_CHECK;
        {
          pushSTACK(obj); # save Hash-Table
          var object* obj_ = &STACK_0; # and memorize, where it is
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'S');
          KLAMMER_AUF;
          INDENT_START(3); # indent by 3 characters, because of '#S('
          JUSTIFY_START(1);
          JUSTIFY_LAST(false);
          prin_object(stream_,S(hash_table)); # print symbol HASH-TABLE
          obj = *obj_;
          {
            var uintL count = posfixnum_to_L(TheHashtable(*obj_)->ht_count);
            var uintL index = # move Index into the Key-Value-Vector
              2*posfixnum_to_L(TheHashtable(obj)->ht_maxcount);
            pushSTACK(TheHashtable(obj)->ht_kvtable); # Key-Value-Vector
            var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
            var uintL length = 0; # previous length := 0
            JUSTIFY_SPACE; # print Space
            # check for attaining of *PRINT-LENGTH* :
            CHECK_LENGTH_LIMIT(length >= length_limit,goto kvtable_end);
            # test for attaining of *PRINT-LINES* :
            CHECK_LINES_LIMIT(goto kvtable_end);
            JUSTIFY_LAST(count==0);
            { # print Hash-Test:
              var uintB flags = record_flags(TheHashtable(*obj_));
              var object test = # Test-Symbol EQ/EQL/EQUAL
                (flags & bit(0) ? S(eq) :
                 flags & bit(1) ? S(eql) :
                 flags & bit(2) ? S(equal) :
                 NIL); # (Default-Symbol)
              prin_object(stream_,test);
            }
            loop {
              length++; # increase previous length
              # search for next to be printed Key-Value-Pair:
              loop {
                if (index==0) # finished kvtable?
                  goto kvtable_end;
                index -= 2; # decrease index
                if (!eq(TheSvector(STACK_0)->data[index+0],unbound)) # Key /= "empty" ?
                  break;
              }
              JUSTIFY_SPACE; # print Space
              # check for attaining of *PRINT-LENGTH* :
              CHECK_LENGTH_LIMIT(length >= length_limit,break);
              # test for attaining of *PRINT-LINES* :
              CHECK_LINES_LIMIT(break);
              count--;
              JUSTIFY_LAST(count==0);
              # create Cons (Key . Value) and print:
              obj = allocate_cons();
              {
                var object* ptr = &TheSvector(STACK_0)->data[index];
                Car(obj) = ptr[0]; # Key
                Cdr(obj) = ptr[1]; # Value
              }
              prin_object(stream_,obj);
            }
          kvtable_end: # output of Key-Value-Pairs finished
            skipSTACK(1);
          }
          JUSTIFY_END_ENG;
          INDENT_END;
          KLAMMER_ZU;
          skipSTACK(1);
        }
        LEVEL_END;
      } else {
        pr_hex6_obj(stream_,obj,O(printstring_hash_table));
      }
      break;
    case Rectype_Package:
      # depending on *PRINT-READABLY*:
      # #<PACKAGE name> or #.(SYSTEM::%FIND-PACKAGE "name")
      {
        pushSTACK(obj); # save package
        var object* obj_ = &STACK_0; # and memorize, where it is
        if (!test_value(S(print_readably))) {
          UNREADABLE_START;
          JUSTIFY_LAST(false);
          if (pack_deletedp(*obj_))
            write_sstring_case(stream_,O(printstring_deleted)); # "DELETED "
          write_sstring_case(stream_,O(printstring_package)); # "PACKAGE"
          JUSTIFY_SPACE;
          JUSTIFY_LAST(true);
          pr_like_symbol(stream_,ThePackage(*obj_)->pack_name); # print Name
          JUSTIFY_END_ENG;
          UNREADABLE_END;
        } else {
          if (!(test_value(S(read_eval)) || stream_get_read_eval(*stream_)))
            fehler_print_readably(*obj_);
          if (pack_deletedp(*obj_))
            fehler_print_readably(*obj_);
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'.');
          KLAMMER_AUF; # '('
          INDENT_START(3); # indent by 3 characters, because of '#.('
          JUSTIFY_START(1);
          JUSTIFY_LAST(false);
          pr_symbol(stream_,S(pfind_package)); # SYSTEM::%FIND-PACKAGE
          JUSTIFY_SPACE;
          JUSTIFY_LAST(true);
          pr_string(stream_,ThePackage(*obj_)->pack_name); # print Name
          JUSTIFY_END_ENG;
          INDENT_END;
          KLAMMER_ZU;
        }
        skipSTACK(1);
      }
      break;
    case Rectype_Readtable: # #<READTABLE #x...>
      CHECK_PRINT_READABLY(obj);
      pr_hex6_obj(stream_,obj,O(printstring_readtable));
      break;
    case Rectype_Pathname:
#if 0
      pr_record_descr(stream_,obj,S(pathname),true,O(pathname_slotlist));
#else
      pushSTACK(obj); # pathname
      # call (NAMESTRING pathname)
      pushSTACK(obj); funcall(L(namestring),1); obj = value1;
      ASSERT(stringp(obj));
      if (test_value(S(print_readably))
          && !test_value(S(print_pathnames_ansi))) {
        pushSTACK(obj); # string
        var object* obj_ = &STACK_0;
        JUSTIFY_START(0);
        JUSTIFY_LAST(false);
        {
          JUSTIFY_START(0);
          JUSTIFY_LAST(false);
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'-');
          write_sstring(stream_,O(lisp_implementation_type_string));
          JUSTIFY_SPACE;
          JUSTIFY_LAST(true);
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'P');
          pr_string(stream_,*obj_);
          JUSTIFY_END_ENG;
        }
        JUSTIFY_SPACE;
        JUSTIFY_LAST(true);
        {
          JUSTIFY_START(0);
          JUSTIFY_LAST(false);
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'+');
          write_sstring(stream_,O(lisp_implementation_type_string));
          JUSTIFY_SPACE;
          JUSTIFY_LAST(true);
          pr_record_descr(stream_,*(obj_ STACKop 1),S(pathname),true,
                          O(pathname_slotlist));
          JUSTIFY_END_ENG;
        }
        JUSTIFY_END_ENG;
        skipSTACK(1);
      } else {
        STACK_0 = obj; # String
        if (test_value(S(print_escape)) || test_value(S(print_readably))) {
          # print "#P"
          write_ascii_char(stream_,'#'); write_ascii_char(stream_,'P');
        }
        pr_string(stream_,STACK_0); # print the string
      }
      skipSTACK(1);
#endif
      break;
#ifdef LOGICAL_PATHNAMES
    case Rectype_Logpathname:
      # #S(LOGICAL-PATHNAME :HOST host :DIRECTORY directory :NAME name
      #    :TYPE type :VERSION version)
      pr_record_descr(stream_,obj,S(logical_pathname),
                      true,O(pathname_slotlist));
      break;
#endif
    case Rectype_Random_State: # #S(RANDOM-STATE seed)
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save Random-State
        var object* obj_ = &STACK_0; # and memorize, where it is
        write_ascii_char(stream_,'#'); write_ascii_char(stream_,'S');
        KLAMMER_AUF;
        INDENT_START(3); # indent by 3 characters, because of '#S('
        JUSTIFY_START(1);
        JUSTIFY_LAST(false);
        prin_object(stream_,S(random_state)); # print Symbol RANDOM-STATE
        pr_record_ab(stream_,obj_,0,0); # print component
        JUSTIFY_END_ENG;
        INDENT_END;
        KLAMMER_ZU;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
#ifndef case_structure
    case Rectype_Structure: # Structure
      pr_structure(stream_,obj); break;
#endif
#ifndef case_stream
    case Rectype_Stream: # Stream
      pr_stream(stream_,obj); break;
#endif
    case Rectype_Byte:
#if 0
      # #<BYTE size position>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save Byte
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        JUSTIFY_LAST(false);
        write_sstring_case(stream_,O(printstring_byte)); # "BYTE"
        pr_record_ab(stream_,obj_,0,0); # print component
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
#else
      # #S(BYTE :SIZE size :POSITION position)
      pr_record_descr(stream_,obj,S(byte),true,O(byte_slotlist));
#endif
      break;
    case Rectype_Fsubr: # Fsubr
      pr_fsubr(stream_,obj);
      break;
    case Rectype_Loadtimeeval: # #.form
      if (test_value(S(print_readably)))
        if (!(test_value(S(read_eval)) || stream_get_read_eval(*stream_)))
          fehler_print_readably(obj);
      pr_sharp_dot(stream_,TheLoadtimeeval(obj)->loadtimeeval_form);
      break;
    case Rectype_Symbolmacro: # #<SYMBOL-MACRO expansion>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save Symbol-Macro
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        JUSTIFY_LAST(false);
        write_sstring_case(stream_,O(printstring_symbolmacro)); # SYMBOL-MACRO
        pr_record_ab(stream_,obj_,0,0); # print component
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
    case Rectype_Macro: # #<MACRO expansion>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save Macro
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        JUSTIFY_LAST(false);
        write_sstring_case(stream_,O(printstring_macro)); # "MACRO"
        pr_record_ab(stream_,obj_,0,0); # print component
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
    case Rectype_FunctionMacro: # #<FUNCTION-MACRO expansion>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save FunctionMacro
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        JUSTIFY_LAST(false);
        write_sstring_case(stream_,O(printstring_functionmacro)); # FUNCTION-MACRO
        pr_record_ab(stream_,obj_,0,0); # print component
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
    case Rectype_Encoding: # #<ENCODING [charset] line-terminator>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save Encoding
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
#ifdef UNICODE
        JUSTIFY_LAST(length_limit==0);
#else
        JUSTIFY_LAST(true);
#endif
        write_sstring_case(stream_,O(printstring_encoding)); # "ENCODING"
        {
          var uintL length = 0; # previous length := 0
#ifdef UNICODE
          # check for attaining of *PRINT-LENGTH* :
          if (length >= length_limit) goto encoding_end;
          JUSTIFY_SPACE; # print Space
          JUSTIFY_LAST(length+1 >= length_limit);
          # print Charset:
          prin_object(stream_,TheEncoding(*obj_)->enc_charset);
          length++; # increase previous length
#endif
          # check for attaining of *PRINT-LENGTH* :
          if (length >= length_limit) goto encoding_end;
          JUSTIFY_SPACE; # print Space
          JUSTIFY_LAST(true);
          # print Line-Terminator:
          prin_object(stream_,TheEncoding(*obj_)->enc_eol);
          length++; # increase previous length
        }
      encoding_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
#ifdef FOREIGN
    case Rectype_Fpointer: # #<FOREIGN-POINTER address>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        var bool validp = fp_validp(TheFpointer(obj));
        var uintP val = (uintP)(TheFpointer(obj)->fp_pointer); # fetch value
        UNREADABLE_START;
        var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
        JUSTIFY_LAST(length_limit==0);
        if (!validp)
          write_sstring_case(stream_,O(printstring_invalid)); # "INVALID "
        write_sstring_case(stream_,O(printstring_fpointer)); # FOREIGN-POINTER
        {
          var uintL length = 0; # previous length := 0
          # check for attaining of *PRINT-LENGTH* :
          if (length >= length_limit) goto fpointer_end;
          JUSTIFY_SPACE; # print Space
          JUSTIFY_LAST(true);
          # print Address:
          pr_hex8(stream_,val);
          length++; # increase previous length
        }
      fpointer_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
      }
      LEVEL_END;
      break;
#endif
#ifdef DYNAMIC_FFI
    case Rectype_Faddress: # #<FOREIGN-ADDRESS #x...>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
        JUSTIFY_LAST(length_limit==0);
        if (!fp_validp(TheFpointer(TheFaddress(*obj_)->fa_base)))
          write_sstring_case(stream_,O(printstring_invalid)); # "INVALID "
        write_sstring_case(stream_,O(printstring_faddress)); # FOREIGN-ADDRESS
        {
          var uintL length = 0; # previous length := 0
          # check for attaining of *PRINT-LENGTH* :
          if (length >= length_limit) goto faddress_end;
          JUSTIFY_SPACE; # print Space
          JUSTIFY_LAST(true);
          # print Address, ref. Macro Faddress_value():
          pr_hex8(stream_,(uintP)TheFpointer(TheFaddress(*obj_)->fa_base)->fp_pointer
                  +  TheFaddress(*obj_)->fa_offset);
          length++; # increase previous length
        }
      faddress_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
    case Rectype_Fvariable: # #<FOREIGN-VARIABLE name #x...>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
        JUSTIFY_LAST(length_limit==0);
        write_sstring_case(stream_,O(printstring_fvariable)); # FOREIGN-VARIABLE
        {
          var uintL length = 0; # previous length := 0
          # check for attaining of *PRINT-LENGTH* :
          if (length >= length_limit) goto fvariable_end;
          JUSTIFY_SPACE; # print Space
          # print Name:
          if (!nullp(TheFvariable(*obj_)->fv_name)) {
            JUSTIFY_LAST(length+1 >= length_limit);
                prin_object(stream_,TheFvariable(*obj_)->fv_name);
                length++; # increase previous length
                if (length >= length_limit) goto fvariable_end;
                JUSTIFY_SPACE; # print Space
          }
          JUSTIFY_LAST(true);
          # print Address:
          pr_hex8(stream_,(uintP)Faddress_value(TheFvariable(*obj_)->fv_address));
          length++; # increase previous length
        }
      fvariable_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
    case Rectype_Ffunction: # #<FOREIGN-FUNCTION name #x...>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
        JUSTIFY_LAST(length_limit==0);
        write_sstring_case(stream_,O(printstring_ffunction)); # FOREIGN-FUNCTION
        {
          var uintL length = 0; # previous length := 0
          # check for attaining of *PRINT-LENGHT*:
          if (length >= length_limit) goto ffunction_end;
          JUSTIFY_SPACE; # print Space
          # print Name:
          if (!nullp(TheFfunction(*obj_)->ff_name)) {
            JUSTIFY_LAST(length+1 >= length_limit);
            prin_object(stream_,TheFfunction(*obj_)->ff_name);
            length++; # increase previous length
            if (length >= length_limit) goto ffunction_end;
            JUSTIFY_SPACE; # print Space
          }
          JUSTIFY_LAST(true);
          # print Address:
          pr_hex8(stream_,(uintP)Faddress_value(TheFfunction(*obj_)->ff_address));
          length++; # increase previous length
        }
      ffunction_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
#endif
    case Rectype_Weakpointer: # #<WEAK-POINTER value> or #<BROKEN WEAK-POINTER>
      CHECK_PRINT_READABLY(obj);
      if (!eq(TheWeakpointer(obj)->wp_cdr,unbound)) {
        LEVEL_CHECK;
        {
          pushSTACK(TheWeakpointer(obj)->wp_value); # save value
          var object* value_ = &STACK_0; # and memorize, where it is
          UNREADABLE_START;
          var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
          JUSTIFY_LAST(length_limit==0);
          write_sstring_case(stream_,O(printstring_weakpointer)); # WEAK-POINTER
          {
            var uintL length = 0; # previous length := 0
            # check for attaining of *PRINT-LENGHT*:
            if (length >= length_limit) goto weakpointer_end;
            JUSTIFY_SPACE; # print Space
            JUSTIFY_LAST(true);
            prin_object(stream_,*value_); # output value
            length++; # increase previous length
          }
        weakpointer_end:
          JUSTIFY_END_ENG;
          UNREADABLE_END;
          skipSTACK(1);
        }
        LEVEL_END;
      } else
        write_sstring_case(stream_,O(printstring_broken_weakpointer));
      break;
    case Rectype_Finalizer: # #<FINALIZER>
      CHECK_PRINT_READABLY(obj);
      write_sstring_case(stream_,O(printstring_finalizer));
      break;
#ifdef SOCKET_STREAMS
    case Rectype_Socket_Server: # #<SOCKET-SERVER host:port>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
        JUSTIFY_LAST(length_limit==0);
        # if closed, print "CLOSED " :
        if (nullp(TheSocketServer(*obj_)->socket_handle))
          write_sstring_case(stream_,O(printstring_closed));
        write_sstring_case(stream_,O(printstring_socket_server)); # SOCKET-SERVER
        {
          var uintL length = 0; # previous length := 0
          # check for attaining of *PRINT-LENGHT*:
          if (length >= length_limit) goto socket_server_end;
          JUSTIFY_SPACE; # print Space
          JUSTIFY_LAST(true);
          # output host
          write_string(stream_,TheSocketServer(*obj_)->host);
          write_ascii_char(stream_,':'); # print Port:
          pr_number(stream_,TheSocketServer(*obj_)->port);
          length++; # increase previous length
        }
      socket_server_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
#endif
#ifdef DIR_KEY
    case Rectype_Dir_Key: # #<DIR-KEY type path>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj);
        var object* obj_ = &STACK_0;
        UNREADABLE_START;
        var uintL length_limit = get_print_length();
        JUSTIFY_LAST(length_limit==0);
        if (TheDirKey(*obj_)->closed_p)
          write_sstring_case(stream_,O(printstring_closed));
        write_sstring_case(stream_,O(printstring_dir_key));
        {
          var uintL length = 0;
          if (length >= length_limit) goto dir_key_end;
          JUSTIFY_SPACE;
          JUSTIFY_LAST(length+1 >= length_limit);
          pr_symbol(stream_,TheDirKey(*obj_)->type);
          length++;
          if (length >= length_limit) goto dir_key_end;
          JUSTIFY_SPACE;
          JUSTIFY_LAST(TheDirKey(*obj_)->closed_p || (length+1 >= length_limit));
          pr_string(stream_,TheDirKey(*obj_)->path);
          if (!TheDirKey(*obj_)->closed_p) {
            length++;
            if (length >= length_limit) goto dir_key_end;
            JUSTIFY_SPACE;
            JUSTIFY_LAST(true);
            pr_symbol(stream_,TheDirKey(*obj_)->direction);
          }
        }
      dir_key_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
#endif
#ifdef YET_ANOTHER_RECORD
    case Rectype_Yetanother: # #<YET-ANOTHER address>
      CHECK_PRINT_READABLY(obj);
      LEVEL_CHECK;
      {
        pushSTACK(obj); # save Yetanother
        var object* obj_ = &STACK_0; # and memorize, where it is
        UNREADABLE_START;
        var uintL length_limit = get_print_length(); # *PRINT-LENGTH*
        JUSTIFY_LAST(length_limit==0);
        write_sstring_case(stream_,O(printstring_yetanother)); # YET-ANOTHER
        {
          var uintL length = 0; # previous length := 0
          # check for attaining of *PRINT-LENGHT*:
          if (length >= length_limit) goto yetanother_end;
          JUSTIFY_SPACE; # print Space
          JUSTIFY_LAST(true);
          # print x:
          pr_hex6(stream_,TheYetanother(*obj_)->yetanother_x);
          length++; # increase previous length
        }
      yetanother_end:
        JUSTIFY_END_ENG;
        UNREADABLE_END;
        skipSTACK(1);
      }
      LEVEL_END;
      break;
#endif
    default:
      pushSTACK(S(print));
      fehler(serious_condition,
             GETTEXT("~: an unknown record type has been generated!"));
  }
}

#                    -------- SUBRs, FSUBRs --------

# UP: prints Object in the form #<BLABLA other> to stream.
# pr_other_obj(&stream,other,string);
# > other: object
# > string: Simple-String "BLABLA"
# > stream: stream
# < stream: stream
# can trigger GC
local void pr_other_obj (const object* stream_, object other, object string) {
  pushSTACK(other); # save other
  pushSTACK(string); # save String
  var object* string_ = &STACK_0; # and memorize, where both are
  UNREADABLE_START;
  JUSTIFY_LAST(false);
  write_sstring_case(stream_,*string_); # print String
  JUSTIFY_SPACE;
  JUSTIFY_LAST(true);
  prin_object(stream_,*(string_ STACKop 1)); # print other
  JUSTIFY_END_ENG;
  UNREADABLE_END;
  skipSTACK(2);
}

# UP: prints SUBR to Stream.
# pr_subr(&stream,obj);
# > obj: SUBR
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_subr (const object* stream_, object obj) {
  # #<SYSTEM-FUNCTION name> bzw. #<ADD-ON-SYSTEM-FUNCTION name>
  # bzw. #.(SYSTEM::%FIND-SUBR 'name)
  if (test_value(S(print_readably))) {
    if (!(test_value(S(read_eval)) || stream_get_read_eval(*stream_)))
      fehler_print_readably(obj);
    pushSTACK(obj); # save obj
    var object* obj_ = &STACK_0; # and memorize, where it is
    write_ascii_char(stream_,'#'); write_ascii_char(stream_,'.');
    KLAMMER_AUF; # '('
    INDENT_START(3); # indent by 3 characters, because of '#.('
    JUSTIFY_START(1);
    JUSTIFY_LAST(false);
    pr_symbol(stream_,S(find_subr)); # SYSTEM::%FIND-SUBR
    JUSTIFY_SPACE;
    JUSTIFY_LAST(true);
    write_ascii_char(stream_,'\'');
    pr_symbol(stream_,TheSubr(*obj_)->name); # print Name
    JUSTIFY_END_ENG;
    INDENT_END;
    KLAMMER_ZU;
    skipSTACK(1);
  } else {
    pr_other_obj(stream_,TheSubr(obj)->name,
                 ((as_oint(subr_tab_ptr_as_object(&subr_tab)) <=
                   as_oint(obj))
                  && (as_oint(obj) <
                      as_oint(subr_tab_ptr_as_object(&subr_tab+1))))
                 ? O(printstring_subr) : O(printstring_addon_subr));
  }
}

# UP: prints FSUBR to Stream.
# pr_fsubr(&stream,obj);
# > obj: FSUBR
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_fsubr (const object* stream_, object obj) {
  # #<SPECIAL-OPERATOR name>
  CHECK_PRINT_READABLY(obj);
  pr_other_obj(stream_,TheFsubr(obj)->name,O(printstring_fsubr));
}

#                       -------- Closures --------

# UP: prints Closure to Stream.
# pr_closure(&stream,obj);
# > obj: Closure
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_closure (const object* stream_, object obj) {
  if (simple_bit_vector_p(Atype_8Bit,TheClosure(obj)->clos_codevec)) {
    # compiled Closure
    pr_cclosure(stream_,obj);
  } else {
    # print interpreted Closure: #<CLOSURE ...>
    # if *PRINT-CLOSURE* /= NIL, print everything, else print Name and
    # (if still existing) Lambdalist and forms:
    CHECK_PRINT_READABLY(obj);
    LEVEL_CHECK;
    {
      pushSTACK(obj); # save Closure
      var object* obj_ = &STACK_0; # and memorize, where it is
      UNREADABLE_START;
      JUSTIFY_LAST(false);
      write_sstring_case(stream_,O(printstring_closure));
      if (test_value(S(print_closure))) { # query *PRINT-CLOSURE*
        # *PRINT-CLOSURE* /= NIL -> print #<CLOSURE komponente1 ...> :
        pr_record_ab(stream_,obj_,0,0); # print the remaining components
      } else {
        # *PRINT-CLOSURE* = NIL -> print #<CLOSURE name . form> :
        JUSTIFY_SPACE;
        prin_object(stream_,TheIclosure(*obj_)->clos_name); # print Name
        # print form-list elementwise:
        pr_record_rest(stream_,TheIclosure(*obj_)->clos_form,1);
      }
      JUSTIFY_END_ENG;
      UNREADABLE_END;
      skipSTACK(1);
    }
    LEVEL_END;
  }
}

# UP: prints compiled Closure to Stream.
# pr_cclosure(&stream,obj);
# > obj: compiled Closure
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_cclosure (const object* stream_, object obj) {
  # query *PRINT-CLOSURE* :
  if (test_value(S(print_closure)) || test_value(S(print_readably))) {
    # *PRINT-CLOSURE /= NIL -> print in re-readable form #Y(...)
    pr_cclosure_lang(stream_,obj);
  } else {
    # *PRINT-CLOSURE* = NIL ->
    # only print #<GENERIC-FUNCTION name> resp. #<COMPILED-CLOSURE name> :
    pr_other_obj(stream_,TheClosure(obj)->clos_name,
                 (TheCodevec(TheClosure(obj)->clos_codevec)->ccv_flags & bit(4) # generic function?
                  ? O(printstring_generic_function)
                  : O(printstring_compiled_closure)));
  }
}

# print compiled Closure in rereadable Form:
# (defun %print-cclosure (closure)
#   (princ "#Y(")
#   (prin1 (closure-name closure))
#   (princ " #")
#   (let ((L (closure-codevec closure)))
#     (let ((*print-base* 10.)) (prin1 (length L)))
#     (princ "Y(")
#     (let ((*print-base* 16.))
#       (do ((i 0 (1- i))
#            (x L (cdr x)))
#           ((endp x))
#         (when (zerop i) (terpri) (setq i 25))
#         (princ " ")
#         (prin1 (car x))
#     ) )
#     (princ ")")
#   )
#   (terpri)
#   (dolist (x (closure-consts closure))
#     (princ " ")
#     (prin1 x)
#   )
#   (princ ")")
# )
# UP: prints compiled Closure in re-readable form
# to stream.
# pr_cclosure_lang(&stream,obj);
# > obj: compiled Closure
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_cclosure_lang (const object* stream_, object obj) {
  LEVEL_CHECK;
  {
    pushSTACK(obj); # save Closure
    var object* obj_ = &STACK_0; # and memorize, where it is
    write_ascii_char(stream_,'#'); write_ascii_char(stream_,'Y');
    KLAMMER_AUF;
    INDENT_START(3); # indent by 3 characters, because of '#Y('
    JUSTIFY_START(1);
    JUSTIFY_LAST(false);
    prin_object(stream_,TheClosure(*obj_)->clos_name); # print Name
    JUSTIFY_SPACE;
    # print Codevector bytewise, treat possible circularity:
    pr_circle(stream_,TheClosure(*obj_)->clos_codevec,&pr_cclosure_codevector);
    pr_record_ab(stream_,obj_,2,2); # print remaining components
    JUSTIFY_END_ENG;
    INDENT_END;
    KLAMMER_ZU;
    skipSTACK(1);
  }
  LEVEL_END;
}

# UP: prints Closure-Codevector in #nY(...)-notation
# to Stream.
# pr_cclosure_codevector(&stream,codevec);
# > codevec: a Simple-Bit-Vector
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_cclosure_codevector (const object* stream_, object codevec) {
  LEVEL_CHECK;
  {
    pushSTACK(codevec); # save Codevector
    var object* codevec_ = &STACK_0; # and memorize, where it is
    var uintL len = Sbvector_length(codevec); # length in Bytes
#if BIG_ENDIAN_P
    var uintL header_end_index =
      (TheSbvector(codevec)->data[CCV_FLAGS] & bit(7) ?
       CCV_START_KEY : CCV_START_NONKEY);
#endif
    # print prefix:
    INDENTPREP_START;
    write_ascii_char(stream_,'#');
    pr_uint(stream_,len); # print length decimally
    write_ascii_char(stream_,'Y');
    {
      var uintL indent = INDENTPREP_END;
# print main part:
      INDENT_START(indent); # indent
    }
    KLAMMER_AUF;
    INDENT_START(1); # indent by 1 character, because of '('
    JUSTIFY_START(1);
    {
      var uintL length_limit = get_print_length(); # *PRINT-LENGTH*-limit
      var uintL length = 0; # Index = previous length := 0
      for ( ; len > 0; len--) {
        # print Space (except before the first element):
        if (!(length==0))
          JUSTIFY_SPACE;
        # check for attaining of *PRINT-LENGHT*:
        CHECK_LENGTH_LIMIT(length >= length_limit,break);
        # test for attaining of *PRINT-LINES* :
        CHECK_LINES_LIMIT(break);
        JUSTIFY_LAST(len==1 || length+1 >= length_limit);
        codevec = *codevec_;
        var uintL index = length;
#if BIG_ENDIAN_P
         # calculate Byte-Index, converting Big-Endian -> Little-Endian :
        if (index < header_end_index) {
          switch (index) {
            case CCV_SPDEPTH_1:          case CCV_SPDEPTH_1+1:
            case CCV_SPDEPTH_JMPBUFSIZE: case CCV_SPDEPTH_JMPBUFSIZE+1:
            case CCV_NUMREQ:             case CCV_NUMREQ+1:
            case CCV_NUMOPT:             case CCV_NUMOPT+1:
            case CCV_NUMKEY:             case CCV_NUMKEY+1:
            case CCV_KEYCONSTS:          case CCV_KEYCONSTS+1:
              index = index^1;
              break;
            default:
              break;
          }
        }
#endif
        # print Byte:
        pr_hex2(stream_,TheSbvector(codevec)->data[index]);
        length++; # increase index
      }
    }
    JUSTIFY_END_ENG;
    INDENT_END;
    KLAMMER_ZU;
    INDENT_END;
    skipSTACK(1);
  }
  LEVEL_END;
}

#                       -------- Streams --------

# UP: prints stream to stream.
# pr_stream(&stream,obj);
# > obj: Stream to be printed
# > stream: Stream
# < stream: Stream
# can trigger GC
local void pr_stream (const object* stream_, object obj) {
  CHECK_PRINT_READABLY(obj);
  pushSTACK(obj); # save Stream
  var object* obj_ = &STACK_0; # and memorize, where it is
  UNREADABLE_START;
  JUSTIFY_LAST(false);
  # if Stream is closed, print "CLOSED " :
  if ((TheStream(*obj_)->strmflags & strmflags_open_B) == 0)
    write_sstring_case(stream_,O(printstring_closed));
  else { # INPUT/OUTPUT/IO
    var bool input_p = (TheStream(*obj_)->strmflags & strmflags_rd_B) != 0;
    var bool output_p = (TheStream(*obj_)->strmflags & strmflags_wr_B) != 0;
    if (input_p) {
      if (output_p) write_sstring_case(stream_,O(printstring_io));
      else write_sstring_case(stream_,O(printstring_input));
    } else {
      if (output_p) write_sstring_case(stream_,O(printstring_output));
      else write_sstring_case(stream_,O(printstring_invalid));
    }
  }
  # if a channel or socket stream, print "BUFFERED " or "UNBUFFERED ":
  var uintL type = TheStream(*obj_)->strmtype;
  switch (type) {
    case strmtype_file:
#ifdef PIPES
    case strmtype_pipe_in:
    case strmtype_pipe_out:
#endif
#ifdef X11SOCKETS
    case strmtype_x11socket:
#endif
#ifdef SOCKET_STREAMS
    case strmtype_socket:
    case strmtype_twoway_socket:
#endif
      write_sstring_case(stream_,
                         stream_isbuffered(*obj_)
                         ? O(printstring_buffered)
                         : O(printstring_unbuffered));
      break;
    default:
      break;
  }
  # print Streamtype:
  {
    var const object* stringtable = &O(printstring_strmtype_synonym);
    write_sstring_case(stream_,stringtable[type]); # fetch string from table
  }
  # print "-STREAM" :
  write_sstring_case(stream_,O(printstring_stream));
  # Stream-specific supplementary information:
  switch (type) {
    case strmtype_synonym: # Synonym-Stream
      JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      prin_object(stream_,TheStream(*obj_)->strm_synonym_symbol); # Symbol
      break;
    case strmtype_broad: # Broadcast-Stream
      pr_record_rest(stream_,TheStream(*obj_)->strm_broad_list,0); # Streams
      break;
    case strmtype_concat: # Concatenated-Stream
      pr_record_rest(stream_,TheStream(*obj_)->strm_concat_list,0); # Streams
      break;
    case strmtype_buff_in: # Buffered-Input-Stream
      JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      prin_object(stream_,TheStream(*obj_)->strm_buff_in_fun); # Function
      break;
    case strmtype_buff_out: # Buffered-Output-Stream
      JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      prin_object(stream_,TheStream(*obj_)->strm_buff_out_fun); # Function
      break;
#ifdef GENERIC_STREAMS
    case strmtype_generic: # Generic Streams
      JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      prin_object(stream_,TheStream(*obj_)->strm_controller_object); # Controller
      break;
#endif
    case strmtype_file: # File-Stream
      JUSTIFY_SPACE;
      JUSTIFY_LAST(nullp(TheStream(*obj_)->strm_file_name) &&
                   !eq(TheStream(*obj_)->strm_eltype,S(character)));
      prin_object(stream_,TheStream(*obj_)->strm_eltype); # Stream-Element-Type
      if (!nullp(TheStream(*obj_)->strm_file_name)) {
        JUSTIFY_SPACE;
        JUSTIFY_LAST(!eq(TheStream(*obj_)->strm_eltype,S(character)));
        prin_object(stream_,TheStream(*obj_)->strm_file_name); # Filename
      }
      if (eq(TheStream(*obj_)->strm_eltype,S(character))) {
        JUSTIFY_SPACE;
        JUSTIFY_LAST(true);
        # print line-number, in which stream currently is:
        write_ascii_char(stream_,'@');
        pr_number(stream_,stream_line_number(*obj_));
      }
      break;
#ifdef PIPES
    case strmtype_pipe_in: case strmtype_pipe_out: # Pipe-In/Out-Stream
      JUSTIFY_SPACE;
      JUSTIFY_LAST(false);
      prin_object(stream_,TheStream(*obj_)->strm_eltype); # Stream-Element-Type
      JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      pr_uint(stream_,I_to_UL(TheStream(*obj_)->strm_pipe_pid)); # Process-Id
      break;
#endif
#ifdef X11SOCKETS
    case strmtype_x11socket: # X11-Socket-Stream
      JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      prin_object(stream_,TheStream(*obj_)->strm_x11socket_connect); # connection destination
      break;
#endif
#ifdef SOCKET_STREAMS
    case strmtype_twoway_socket:
      *obj_ = TheStream(*obj_)->strm_twoway_socket_input;
      /*FALLTHROUGH*/
    case strmtype_socket: # Socket-Stream
      JUSTIFY_SPACE;
      JUSTIFY_LAST(false);
      prin_object(stream_,TheStream(*obj_)->strm_eltype); # Stream-Element-Type
      JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      {
        var object host = TheStream(*obj_)->strm_socket_host;
        if (!nullp(host))
          write_string(stream_,host);
      }
      write_ascii_char(stream_,':');
      pr_number(stream_,TheStream(*obj_)->strm_socket_port);
      break;
#endif
    default: # else no supplementary information
      break;
  }
  JUSTIFY_END_ENG;
  UNREADABLE_END;
  skipSTACK(1);
}

# ---------------------- Top-Level-Call of the Printers ----------------------

# UP: prints object to stream.
# prin1(&stream,obj);
# > obj: object
# > stream: stream
# < stream: stream
# can trigger GC
global void prin1 (const object* stream_, object obj) {
  pr_enter(stream_,obj,&prin_object);
}

# UP: print Newline first, then print an object to stream.
# print(&stream,obj);
# > obj: Object
# > stream: Stream
# < stream: Stream
# can trigger GC
global void print (const object* stream_, object obj) {
  pushSTACK(obj); # save Object
  write_ascii_char(stream_,NL); # print #\Newline
  obj = popSTACK();
  prin1(stream_,obj); # print Object
}

# ----------------------- Helper-functions of the Printer --------------------

# UP: Check ein Output-Stream-Argument.
# The value of *STANDARD-OUTPUT* is default.
# test_ostream();
# > subr_self: caller (ein SUBR)
# > STACK_0: Output-Stream-Argument
# < STACK_0: Output-Stream (a Stream)
local void test_ostream (void) {
  var object stream = STACK_0; # Output-Stream-Argument
  if (eq(stream,unbound) || nullp(stream)) {
    # #<UNBOUND> or NIL -> value of *STANDARD-OUTPUT*
    STACK_0 = var_stream(S(standard_output),strmflags_wr_ch_B);
  } else if (eq(stream,T)) {
    # T -> value of *TERMINAL-IO*
    STACK_0 = var_stream(S(terminal_io),strmflags_wr_ch_B);
  } else {
    # should be a stream
    if (!streamp(stream))
      fehler_stream(stream);
  }
}

LISPFUNN(whitespacep,1) # (SYS::WHITESPACEP CHAR)
{
  var object ch = popSTACK();
  value1 = NIL;
  if (charp(ch)) {
    var cint ci = as_cint(char_code(ch));
    if (cint_white_p(ci))
      value1 = T;
  }
  mv_count=1;
}

LISPFUN(write_spaces,1,1,norest,nokey,0,NIL)
# (SYS::WRITE-SPACES num &optional stream)
{
  test_ostream();
  if (!posfixnump(STACK_1)) fehler_posfixnum(STACK_1);
  spaces(&STACK_0,STACK_1);
  skipSTACK(2);
  mv_count = 1;
  value1 = NIL;
}

# ---------------------- Pretty Printer ----------------------

LISPFUN(pprint_indent,2,1,norest,nokey,0,NIL)
# (PPRINT-INDENT relative-to n &optional stream) ==> NIL
# relative-to---either :block or :current.
# n          ---a real.
# stream     ---an output stream designator. The default is standard output.
{
  test_ostream();
  # check the indentation increment
  var int offset=0;
  if (numberp(STACK_1) && !complexp(STACK_1)) {
    var object num = STACK_1;
    if (!integerp(num)) {
      pushSTACK(num); funcall(L(round),1);
      num = value1;
    }
    if (!fixnump(num)) {
      pushSTACK(STACK_1);   # TYPE-ERROR slot DATUM
      pushSTACK(S(fixnum)); # TYPE-ERROR slot EXPECTED-TYPE
      pushSTACK(STACK_1); pushSTACK(S(pprint_indent));
      fehler(type_error,GETTEXT("~: argument ~ is too large"));
    }
    offset = fixnum_to_L(num);
  } else fehler_not_R(STACK_1);
  # check the relative-to arg
  var object indent = Symbol_value(S(prin_indentation));
  var object linepos = get_line_position(STACK_0);
  var uintL linepos_i = (posfixnump(linepos) ? posfixnum_to_L(linepos) : 0);
  if (eq(S(Kblock),STACK_2)) {
    if (posfixnump(indent))
      offset += posfixnum_to_L(indent);
  } else if (eq(S(Kcurrent),STACK_2)) {
    if (linepos_i > 0)
      offset += linepos_i;
  } else { # invalid value
    pushSTACK(STACK_2);               # TYPE-ERROR slot DATUM
    pushSTACK(O(type_pprint_indent)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(S(Kblock)); pushSTACK(S(Kcurrent));
    pushSTACK(STACK_2);
    pushSTACK(S(pprint_indent));
    fehler(type_error,GETTEXT("~: argument ~ should be ~ or ~."));
  }
  if (PPHELP_STREAM_P(STACK_0) && test_value(S(print_pretty))) {
    # set indentation
    if (offset<0) offset = 0;
   #if IO_DEBUG > 1
    printf("pprint-indent: %d --> %d\n",
           eq(unbound,Symbol_value(S(prin_indentation))) ? -1 :
           posfixnum_to_L(Symbol_value(S(prin_indentation))),offset);
   #endif
    Symbol_value(S(prin_indentation)) = fixnum(offset);
    if (linepos_i < offset)
      spaces(&STACK_0,fixnum(offset-linepos_i));
  }
  skipSTACK(3);
  value1=NIL;
  mv_count=1;
}

typedef enum {
  PPRINT_NEWLINE_LINEAR,
  PPRINT_NEWLINE_FILL,
  PPRINT_NEWLINE_MISER,
  PPRINT_NEWLINE_MANDATORY
} pprint_newline_t;

LISPFUN(pprint_newline,1,1,norest,nokey,0,NIL)
# (PPRINT-NEWLINE kind &optional stream) ==> NIL
# kind  ---one of :linear, :fill, :miser, or :mandatory.
# stream---a stream designator. The default is standard output.
{
  test_ostream();
  var pprint_newline_t ppn_type = PPRINT_NEWLINE_MANDATORY;
  if (eq(S(Klinear),STACK_1))         ppn_type = PPRINT_NEWLINE_LINEAR;
  else if (eq(S(Kfill),STACK_1))      ppn_type = PPRINT_NEWLINE_FILL;
  else if (eq(S(Kmiser),STACK_1))     ppn_type = PPRINT_NEWLINE_MISER;
  else if (eq(S(Kmandatory),STACK_1)) ppn_type = PPRINT_NEWLINE_MANDATORY;
  else { # invalid value
    pushSTACK(STACK_1);                # TYPE-ERROR slot DATUM
    pushSTACK(O(type_pprint_newline)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(S(Klinear)); pushSTACK(S(Kfill));
    pushSTACK(S(Kmiser));  pushSTACK(S(Kmandatory));
    pushSTACK(STACK_1);
    pushSTACK(S(pprint_newline));
    fehler(type_error,GETTEXT("~: argument ~ should be ~, ~, ~ or ~."));
  }
  if (PPHELP_STREAM_P(STACK_0) && test_value(S(print_pretty)))
    switch (ppn_type) {
      case PPRINT_NEWLINE_MISER:
        if (!test_value(S(prin_miserp))) # miser style
          break;
        STACK_1 = S(Klinear);
        /*FALLTHROUGH*/
      case PPRINT_NEWLINE_LINEAR:
        if (eq(TheStream(STACK_0)->strm_pphelp_modus,mehrzeiler))
          goto mandatory;
        /*FALLTHROUGH*/
      case PPRINT_NEWLINE_FILL:
        cons_ssstring(&STACK_0,STACK_1);
        break;
      case PPRINT_NEWLINE_MANDATORY:
    mandatory:
        cons_ssstring(&STACK_0,NIL);
        break;
    }
  skipSTACK(2);
  value1=NIL;
  mv_count=1;
}

pr_routine_t pprin_object;
pr_routine_t pprin_object_dispatch;
local void pprin_object (const object* stream_,object obj) {
 restart_it:
  # test for keyboard-interrupt:
  interruptp({
    pushSTACK(obj); # save obj in the STACK; the stream is safe
    pushSTACK(S(print)); tast_break(); # PRINT call break-loop
    obj = popSTACK(); # move obj back
    goto restart_it;
  });
  # test for stack overflow:
  check_SP(); check_STACK();
  # handle circularity:
  pr_circle(stream_,obj,&pprin_object_dispatch);
}
# SYS::*PRIN-PPRINTER* == the lisp function
local void pprin_object_dispatch (const object* stream_,object obj) {
  LEVEL_CHECK;
  var uintC count = pr_external_1(*stream_); # instantiate bindings
  pushSTACK(*stream_); pushSTACK(obj);
  funcall(Symbol_value(S(prin_pprinter)),2);
  pr_external_2(count); # dissolve bindings
  LEVEL_END;
}

LISPFUNN(ppprint_logical_block,3)
# (%PPRINT-LOGICAL-BLOCK function object stream)
{
  test_ostream();
  if (listp(STACK_1)) {
    var object stream = STACK_0;
    var object obj = STACK_1;
    var object func = STACK_2;
    dynamic_bind(S(prin_pprinter),func); # *PRIN-PPRINTER*
    pr_enter(&stream,obj,&pprin_object);
    dynamic_unbind(); # *PRIN-PPRINTER*
  } else
    pr_enter(&STACK_0,STACK_1,&prin_object);
  skipSTACK(3);
  value1=NIL;
  mv_count=1;
}

LISPFUNN(pcirclep,2)
# (%CIRCLEP object stream)
# return the appropriate read label or NIL
# called from PPRINT-POP
{
  test_ostream();
  # var circle_info_t ci;
  if (!circle_p(STACK_1,NULL) || !PPHELP_STREAM_P(STACK_0)) # &ci
    value1 = NIL;
  else {
    write_ascii_char(&STACK_0,'.');
    write_ascii_char(&STACK_0,' ');
    prin_object(&STACK_0,STACK_1);
    value1 = T; # make_read_label(ci.n);
  }
  skipSTACK(2);
  mv_count = 1;
}

LISPFUN(format_tabulate,3,2,norest,nokey,0,NIL)
# (format-tabulate stream colon-modifier atsign-modifier
#                  &optional (colnum 1) (colinc 1))
# see format.lisp
{
  swap(object,STACK_0,STACK_4); # get the stream into STACK_0
  test_ostream();
 #define COL_ARG(x) (eq(x,unbound) || nullp(x) ? Fixnum_1 : \
                     (posfixnump(x) ? x : (fehler_posfixnum(x),Fixnum_1)))
  STACK_1 = COL_ARG(STACK_1);
  STACK_4 = COL_ARG(STACK_4);
 #undef COL_ARG
  if (PPHELP_STREAM_P(STACK_0) && test_value(S(print_pretty))) {
    var object tab_spec = allocate_vector(4);
    PPH_TAB_COLON(tab_spec) = STACK_3;
    PPH_TAB_ATSIG(tab_spec) = STACK_2;
    PPH_TAB_COL_N(tab_spec) = STACK_1;
    PPH_TAB_COL_I(tab_spec) = STACK_4;
    var object list = TheStream(STACK_0)->strm_pphelp_strings;
    pushSTACK(tab_spec);
    if (stringp(Car(list)) && (0==vector_length(Car(list)))) {
      # last string is empty -- keep it!
      var object new_cons = allocate_cons();
      Car(new_cons) = popSTACK();
      Cdr(new_cons) = Cdr(TheStream(STACK_0)->strm_pphelp_strings);
      TheStream(STACK_0)->strm_pphelp_strings = new_cons;
    } else {
      pushSTACK(make_ssstring(50));
      swap(object,STACK_0,STACK_1);
      var object new_cons = listof(2);
      Cdr(Cdr(new_cons)) = TheStream(STACK_0)->strm_pphelp_strings;
      TheStream(STACK_0)->strm_pphelp_strings = new_cons;
    }
  } else
    spaces(&STACK_0,
           fixnum(format_tab(STACK_0,STACK_3,STACK_2,STACK_1,STACK_4)));
  skipSTACK(5);
  value1=NIL;
  mv_count=1;
}

# ----------------------- LISP-functions of the Printer ----------------------

# Print-Variables (ref. CONSTSYM.D):
#   *PRINT-CASE*        ----+
#   *PRINT-LEVEL*           |
#   *PRINT-LENGTH*          |
#   *PRINT-GENSYM*          |
#   *PRINT-ESCAPE*          | order fixed!
#   *PRINT-RADIX*           | the same order as in CONSTSYM.D
#   *PRINT-BASE*            | also for the SUBRs WRITE, WRITE-TO-STRING
#   *PRINT-ARRAY*           |
#   *PRINT-CIRCLE*          |
#   *PRINT-PRETTY*          |
#   *PRINT-CLOSURE*         |
#   *PRINT-READABLY*        |
#   *PRINT-LINES*           |
#   *PRINT-MISER-WIDTH*     |
#   *PRINT-PPRINT-DISPATCH* |
#   *PRINT-RIGHT-MARGIN* ---+
# first Print-Variable:
#define first_print_var  S(print_case)
# number of Print-Variables:
#define print_vars_anz  16

# UP: for WRITE and WRITE-TO-STRING
# > STACK_(print_vars_anz+1): Object
# > STACK_(print_vars_anz)..STACK_(1): Arguments to the Print-Variables
# > STACK_0: Stream
local void write_up (void) {
  # Pointer over the Keyword-Arguments
  var object* argptr = args_end_pointer STACKop (1+print_vars_anz+1);
  var object obj = NEXT(argptr); # first Argument = Object
  # bind the specified Variable:
  var uintC bindcount = 0; # number of bindings
  {
    var object sym = first_print_var; # loops over the Symbols
    var uintC count;
    dotimesC(count,print_vars_anz, {
      var object arg = NEXT(argptr); # next Keyword-Argument
      if (!eq(arg,unbound)) { # specified?
        dynamic_bind(sym,arg); bindcount++; # yes -> pind Variable to it
      }
      sym = objectplus(sym,(soint)sizeof(*TheSymbol(sym))<<(oint_addr_shift-addr_shift)); # next Symbol
    });
  }
  {
    var object* stream_ = &NEXT(argptr); # next Argument is the Stream
    prin1(stream_,obj); # print Object
  }
  # dissolve bindings:
  dotimesC(bindcount,bindcount, { dynamic_unbind(); } );
}

LISPFUN(write,1,0,norest,key,17,\
        (kw(case),kw(level),kw(length),kw(gensym),kw(escape),kw(radix),\
         kw(base),kw(array),kw(circle),kw(pretty),kw(closure),kw(readably),\
         kw(lines),kw(miser_width),kw(pprint_dispatch),
         kw(right_margin),kw(stream)))
# (WRITE object [:stream] [:escape] [:radix] [:base] [:circle] [:pretty]
#               [:level] [:length] [:case] [:gensym] [:array] [:closure]
#               [:readably] [:lines] [:miser-width] [:pprint-dispatch]
#               [:right-margin]),
# CLTL p. 382
  {
    # stack layout: object, Print-Variablen-Arguments, Stream-Argument.
    test_ostream(); # check Output-Stream
    write_up(); # execute WRITE
    skipSTACK(print_vars_anz+1);
    value1 = popSTACK(); mv_count=1; # object as value
  }

# (defun prin1 (object &optional stream)
#   (test-output-stream stream)
#   (let ((*print-escape* t))
#     (prin object stream)
#   )
#   object
# )

# UP: for PRIN1, PRINT and PRIN1-TO-STRING
# > STACK_1: Object
# > STACK_0: Stream
local void prin1_up (void) {
  var object obj = STACK_1;
  var object* stream_ = &STACK_0;
  dynamic_bind(S(print_escape),T); # bind *PRINT-ESCAPE* to T
  prin1(stream_,obj); # print object
  dynamic_unbind();
}

LISPFUN(prin1,1,1,norest,nokey,0,NIL)
# (PRIN1 object [stream]), CLTL p. 383
  {
    test_ostream(); # check Output-Stream
    prin1_up(); # execute PRIN1
    skipSTACK(1);
    value1 = popSTACK(); mv_count=1; # object as value
  }

# (defun print (object &optional stream)
#   (test-output-stream stream)
#   (terpri stream)
#   (let ((*print-escape* t))
#     (prin object stream)
#   )
#   (write-char #\Space stream)
#   object
# )
LISPFUN(print,1,1,norest,nokey,0,NIL)
# (PRINT object [stream]), CLTL p. 383
  {
    test_ostream(); # check Output-Stream
    terpri(&STACK_0); # new line
    prin1_up(); # execute PRIN1
    write_ascii_char(&STACK_0,' '); # add Space
    skipSTACK(1);
    value1 = popSTACK(); mv_count=1; # object as value
  }

# (defun pprint (object &optional stream)
#   (test-output-stream stream)
#   (terpri stream)
#   (let ((*print-escape* t) (*print-pretty* t))
#     (prin object stream)
#   )
#   (values)
# )
LISPFUN(pprint,1,1,norest,nokey,0,NIL)
# (PPRINT object [stream]), CLTL p. 383
  {
    test_ostream(); # check Output-Stream
    terpri(&STACK_0); # new line
    var object obj = STACK_1;
    var object* stream_ = &STACK_0;
    dynamic_bind(S(print_pretty),T); # bind *PRINT-PRETTY* to T
    dynamic_bind(S(print_escape),T); # bind *PRINT-ESCAPE* to T
    prin1(stream_,obj); # print object
    dynamic_unbind();
    dynamic_unbind();
    skipSTACK(2);
    value1 = NIL; mv_count=0; # no values
  }

# (defun princ (object &optional stream)
#   (test-output-stream stream)
#   (let ((*print-escape* nil)
#         (*print-readably* nil))
#     (prin object stream)
#   )
#   object
# )

# UP: for PRINC and PRINC-TO-STRING
# > STACK_1: Objekt
# > STACK_0: Stream
local void princ_up (void) {
  var object obj = STACK_1;
  var object* stream_ = &STACK_0;
  dynamic_bind(S(print_escape),NIL); # bind *PRINT-ESCAPE* to NIL
  dynamic_bind(S(print_readably),NIL); # bind *PRINT-READABLY* to NIL
  prin1(stream_,obj); # print object
  dynamic_unbind();
  dynamic_unbind();
}

LISPFUN(princ,1,1,norest,nokey,0,NIL)
# (PRINC object [stream]), CLTL p. 383
  {
    test_ostream(); # check Output-Stream
    princ_up(); # execute PRINC
    skipSTACK(1);
    value1 = popSTACK(); mv_count=1; # object as value
  }

# (defun write-to-string (object &rest args
#                                &key escape radix base circle pretty level
#                                     length case gensym array closure
#                                     readably lines miser-width
#                                     pprint-dispatch right-margin)
#   (with-output-to-string (stream)
#     (apply #'write object :stream stream args)
# ) )
LISPFUN(write_to_string,1,0,norest,key,16,\
        (kw(case),kw(level),kw(length),kw(gensym),kw(escape),kw(radix),\
         kw(base),kw(array),kw(circle),kw(pretty),kw(closure),kw(readably),\
         kw(lines),kw(miser_width),kw(pprint_dispatch),kw(right_margin)))
# (WRITE-TO-STRING object [:escape] [:radix] [:base] [:circle] [:pretty]
#                         [:level] [:length] [:case] [:gensym] [:array]
#                         [:closure] [:readably] [:lines] [:miser-width]
#                         [:pprint-dispatch] [:right-margin]),
# CLTL p. 383
  {
    pushSTACK(make_string_output_stream()); # String-Output-Stream
    write_up(); # execute WRITE
    value1 = get_output_stream_string(&STACK_0); mv_count=1; # Result-String as value
    skipSTACK(1+print_vars_anz+1);
  }

# (defun prin1-to-string (object)
#   (with-output-to-string (stream) (prin1 object stream))
# )
LISPFUNN(prin1_to_string,1)
# (PRIN1-TO-STRING object), CLTL p. 383
  {
    pushSTACK(make_string_output_stream()); # String-Output-Stream
    prin1_up(); # execute PRIN1
    value1 = get_output_stream_string(&STACK_0); mv_count=1; # Result-String as value
    skipSTACK(2);
  }

# (defun princ-to-string (object)
#   (with-output-to-string (stream) (princ object stream))
# )
LISPFUNN(princ_to_string,1)
# (PRINC-TO-STRING object), CLTL p. 383
  {
    pushSTACK(make_string_output_stream()); # String-Output-Stream
    princ_up(); # execute PRINC
    value1 = get_output_stream_string(&STACK_0); mv_count=1; # Result-String as value
    skipSTACK(2);
  }

LISPFUN(write_char,1,1,norest,nokey,0,NIL)
# (WRITE-CHAR character [stream]), CLTL p. 384
  {
    test_ostream(); # check Output-Stream
    var object ch = STACK_1; # character-Argument
    if (!charp(ch))
      fehler_char(ch);
    write_char(&STACK_0,ch);
    value1 = ch; mv_count=1; # ch (not jeopardized by GC) as value
    skipSTACK(2);
  }

# UP: for WRITE-STRING and WRITE-LINE:
# checks the Arguments and prints a sub-string to stream.
# > subr_self: caller (a SUBR)
# > stack layout: String-Argument, Stream-Argument, :START-Argument, :END-Argument.
# < stack layout: Stream, String.
# can trigger GC
local void write_string_up (void) {
  pushSTACK(STACK_2); # Stream to the end of the STACK
  test_ostream(); # check
  STACK_(2+1) = STACK_(3+1);
  STACK_(3+1) = STACK_0;
  skipSTACK(1);
  # stack layout: stream, string, :START-Argument, :END-Argument.
  # check borders:
  var stringarg arg;
  var object string = test_string_limits_ro(&arg);
  pushSTACK(string);
  # stack layout: stream, string.
  write_sstring_ab(&STACK_1,arg.string,arg.offset+arg.index,arg.len);
}

LISPFUN(write_string,1,1,norest,key,2, (kw(start),kw(end)) )
# (WRITE-STRING string [stream] [:start] [:end]), CLTL p. 384
  {
    write_string_up(); # check and print
    value1 = popSTACK(); mv_count=1; skipSTACK(1); # string as value
  }

LISPFUN(write_line,1,1,norest,key,2, (kw(start),kw(end)) )
# (WRITE-LINE string [stream] [:start] [:end]), CLTL p. 384
  {
    write_string_up(); # check and print
    terpri(&STACK_1); # new line
    value1 = popSTACK(); mv_count=1; skipSTACK(1); # string as value
  }

LISPFUN(terpri,0,1,norest,nokey,0,NIL)
# (TERPRI [stream]), CLTL p. 384
  {
    test_ostream(); # check Output-Stream
    terpri(&STACK_0); # new line
    value1 = NIL; mv_count=1; skipSTACK(1); # NIL as value
  }

LISPFUN(fresh_line,0,1,norest,nokey,0,NIL)
# (FRESH-LINE [stream]), CLTL p. 384
  {
    test_ostream(); # check Output-Stream
    if (eq(get_line_position(STACK_0),Fixnum_0)) { # Line-Position = 0 ?
      value1 = NIL; mv_count=1; # yes -> NIL as value
    } else {
      terpri(&STACK_0); # no -> new line
      value1 = T; mv_count=1; # and T as value
    }
    skipSTACK(1);
  }

LISPFUN(finish_output,0,1,norest,nokey,0,NIL)
# (FINISH-OUTPUT [stream]), CLTL p. 384
  {
    test_ostream(); # check Output-Stream
    finish_output(popSTACK()); # bring Output to the destination
    value1 = NIL; mv_count=1; # NIL as value
  }

LISPFUN(force_output,0,1,norest,nokey,0,NIL)
# (FORCE-OUTPUT [stream]), CLTL p. 384
  {
    test_ostream(); # check Output-Stream
    force_output(popSTACK()); # bring output to destination
    value1 = NIL; mv_count=1; # NIL as value
  }

LISPFUN(clear_output,0,1,norest,nokey,0,NIL)
# (CLEAR-OUTPUT [stream]), CLTL p. 384
  {
    test_ostream(); # check Output-Stream
    clear_output(popSTACK()); # delete output
    value1 = NIL; mv_count=1; # NIL as value
  }

LISPFUN(write_unreadable,3,0,norest,key,2, (kw(type),kw(identity)) )
# (SYSTEM::WRITE-UNREADABLE function object stream [:type] [:identity]),
# ref. CLtL2 p. 580
  {
    var bool flag_fun = false;
    var bool flag_type = false;
    var bool flag_id = false;
    {
      var object arg = popSTACK(); # :identity - Argument
      if (!(eq(arg,unbound) || nullp(arg)))
        flag_id = true;
    }
    {
      var object arg = popSTACK(); # :type - Argument
      if (!(eq(arg,unbound) || nullp(arg)))
        flag_type = true;
    }
    if (!nullp(STACK_2))
      flag_fun = true;
    test_ostream(); # check Output-Stream
    CHECK_PRINT_READABLY(STACK_1);
    var object* stream_ = &STACK_0;
    UNREADABLE_START;
    if (flag_type) {
      JUSTIFY_LAST(!flag_fun && !flag_id);
      # print (TYPE-OF object) :
      pushSTACK(*(stream_ STACKop 1)); funcall(L(type_of),1);
      prin1(stream_,value1);
      if (flag_fun || flag_id)
        JUSTIFY_SPACE;
    }
    if (flag_fun) {
      JUSTIFY_LAST(!flag_id);
      funcall(*(stream_ STACKop 2),0); # (FUNCALL function)
    }
    if (flag_id) {
      if (flag_fun)
        JUSTIFY_SPACE;
      JUSTIFY_LAST(true);
      pr_hex6(stream_,*(stream_ STACKop 1));
    }
    JUSTIFY_END_ENG;
    UNREADABLE_END;
    skipSTACK(3);
    value1 = NIL; mv_count=1;
  }

LISPFUN(line_position,0,1,norest,nokey,0,NIL)
# (SYS::LINE-POSITION [stream]), Auxiliary function for FORMAT ~T,
# returns the position of an (Output-)Stream in the current line, or NIL.
  {
    test_ostream(); # check Output-Stream
    value1 = get_line_position(popSTACK()); mv_count=1;
  }

