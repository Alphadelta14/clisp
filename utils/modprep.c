/*
 * MODPREP - CLISP module preprocessor
 * Bruno Haible 20.9.1998, 10.-11.10.1998
 */

/* This preprocessor generates all necessary tables for a CLISP module.
The input file is normal C code, modified like this:
- It includes "clisp.h".
- There is one (and only one) declaration
    DEFMODULE(module_name,"PACKAGE-NAME")
  module_name is the clisp module name.
  PACKAGE-NAME is the default package name (in upper case) for Lisp
  functions.
- Constant Lisp objects can be referred to using the backquote syntax:
    pushSTACK(`:TEST`);
    value1 = `#()`;
  The backquoted strings are read in at module load time.
- The definition of Lisp functions is done using the macro
    DEFUN(function_name, lambda_list)
  for example
    DEFUN(foo::bar, x y [&optional z] [&rest foo | &key a b c] )
  &rest and &key cannot be combined (this is a restriction for SUBRs).
  &key requires at least one keyword (this is a restriction for SUBRs too).
- Variables containing Lisp objects (known to the garbage collector) are
  defined using the macro
    DEFVAR(variable_name, initform)
  where initform is a C form. (You can also specify a Lisp initform, by
  using the backquote syntax.) The variable can be referred to as
    O(variable_name)
  These variables are private to the module.

Restrictions and caveats:
- A module should consist of a single file.
- The last line in the input file should be terminated with a newline.
- #line lines should not be separated into multiple lines using
  backslash-newline.
- No multi-line comments should start in a preprocessor line.
- #if conditions are assumed to be constant from the DEFMODULE call to
  the end of the file. All necessary #define's should therefore be done
  before the DEFMODULE call.
*/

typedef int boolean_t;
#define FALSE 0
#define TRUE 1

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" void exit(int);
#endif

#if !(defined(__GNUC__) && !defined(__STRICT_ANSI__))
#define inline
#endif


/* Memory utilities. */
static char* xmalloc (unsigned long count)
{
  char* tmp = (char*)malloc(count);
  if (!tmp) {
    fprintf(stderr,"Virtual memory exhausted.\n");
    exit(1);
  }
  return tmp;
}

static char* xrealloc (void* data, unsigned long count)
{
  char* tmp = (char*)realloc(data,count);
  if (!tmp) {
    fprintf(stderr,"Virtual memory exhausted.\n");
    exit(1);
  }
  return tmp;
}

static inline void xfree (void* ptr)
{
  free((char*)ptr);
}


/* Character utilities. */

/* Determine whether a character (not newline) is whitespace. */
static inline boolean_t is_whitespace (char c)
{
  return (c == ' ') || (c == '\t');
}

/* Determine whether a charater is a digit (locale independent). */
static inline boolean_t is_digit (char c)
{
  return (c >= '0') && (c <= '9');
}


/* String utilities. */

/* Returns the freshly allocated contenation of 2 strings. */
static char* concat2 (const char* str1, const char* str2)
{
  unsigned long len1 = strlen(str1);
  unsigned long len2 = strlen(str2);
  char* result = xmalloc(len1+len2+1);
  memcpy(result+0,str1,len1);
  memcpy(result+len1,str2,len2+1);
  return result;
}

/* Returns the freshly allocated contenation of 3 strings. */
static char* concat3 (const char* str1, const char* str2, const char* str3)
{
  unsigned long len1 = strlen(str1);
  unsigned long len2 = strlen(str2);
  unsigned long len3 = strlen(str3);
  char* result = xmalloc(len1+len2+len3+1);
  memcpy(result+0,str1,len1);
  memcpy(result+len1,str2,len2);
  memcpy(result+len1+len2,str3,len3+1);
  return result;
}

/* Returns the freshly allocated contenation of 4 strings. */
static char* concat4 (const char* str1, const char* str2, const char* str3, const char* str4)
{
  unsigned long len1 = strlen(str1);
  unsigned long len2 = strlen(str2);
  unsigned long len3 = strlen(str3);
  unsigned long len4 = strlen(str4);
  char* result = xmalloc(len1+len2+len3+len4+1);
  memcpy(result+0,str1,len1);
  memcpy(result+len1,str2,len2);
  memcpy(result+len1+len2,str3,len3);
  memcpy(result+len1+len2+len3,str4,len4+1);
  return result;
}

/* Returns a freshly allocated substring. */
static char* substring (const char* str, unsigned long index1, unsigned long index2)
{
  if (!(index1 <= index2)) abort();
  if (!(index2 <= strlen(str))) abort();
  { unsigned long len = index2-index1;
    char* result = xmalloc(len+1);
    if (len > 0) memcpy(result,str+index1,len);
    result[len] = '\0';
    return result;
} }

/* Returns a freshly allocated substring. */
static char* substring_from_to (const char* p1, const char* p2)
{
  unsigned long length = p2 - p1;
  char* result = (char*) xmalloc(length+1);
  memcpy(result,p1,length);
  result[length] = '\0';
  return result;
}

/* Compares two strings for equality. */
static inline boolean_t String_equals (const char* str1, const char* str2)
{
  return !strcmp(str1,str2);
}

/* Compares two strings for case-insensitive equality. */
static boolean_t String_equalsIgnoreCase (const char* str1, const char* str2)
{
  while (*str1 != '\0' && *str2 != '\0') {
    unsigned char c1 = (unsigned char)(*str1++);
    unsigned char c2 = (unsigned char)(*str2++);
    if (c1 < 0x80) /* isascii(c1) */
      c1 = toupper(c1);
    if (c2 < 0x80) /* isascii(c2) */
      c2 = toupper(c2);
    if (c1 != c2)
      return FALSE;
  }
  /* Now *str1 == '\0' || *str2 == '\0'. */
  return (*str1 == *str2);
}


/* Extensible vectors. */

typedef struct {
  unsigned long index;
  unsigned long size;
  const void* * data;
} Vector_t;

static inline void Vector_init (Vector_t* v)
{
  v->size = 5;
  v->data = (const void* *) xmalloc(v->size * sizeof(const void*));
  v->index = 0;
}

static inline unsigned long Vector_length (const Vector_t* v)
{
  return v->index;
}

static void Vector_add (Vector_t* v, const void* elt)
{
  if (v->index >= v->size) {
    v->size = 2 * v->size;
    v->data = (const void* *) xrealloc(v->data, v->size * sizeof(const void*));
  }
  v->data[v->index++] = elt;
}

static const void * Vector_element (const Vector_t* v, unsigned long i)
{
  if (!(i < v->index)) {
    fprintf(stderr,"vector index out of bounds");
    abort();
  }
  return v->data[i];
}

static void Vector_set_element (Vector_t* v, unsigned long i, const void* elt)
{
  if (!(i < v->index)) {
    fprintf(stderr,"vector index out of bounds");
    abort();
  }
  v->data[i] = elt;
}

static void Vector_remove_element (Vector_t* v, unsigned long i)
{
  if (!(i < v->index)) {
    fprintf(stderr,"vector index out of bounds");
    abort();
  }
  v->index--;
  for (; i < v->index; i++)
    v->data[i] = v->data[i+1];
}

#ifdef unused
static void Vector_init_clone (Vector_t* w, const Vector_t* v)
{
  w->size = (v->size < 5 ? 5 : v->size);
  w->data = (const void* *) xmalloc(w->size * sizeof(const void*));
  memcpy(w->data,v->data,v->size * sizeof(const void*));
  w->index = v->size;
}
#endif

#ifdef unused
static Vector_t* Vector_clone (const Vector_t* v)
{
  Vector_t* w = (Vector_t*) xmalloc(sizeof(Vector_t));
  Vector_init_clone(w,v);
  return w;
}
#endif


/* All data is bufferized in lines. */

typedef struct {
  long number;
  char* contents;
} Line_t;

static inline Line_t* make_Line (long number, char* contents)
{
  Line_t* result = (Line_t*) xmalloc(sizeof(Line_t));
  result->number = number;
  result->contents = contents;
  return result;
}


/* Current source file. */

static const char* file = "(stdin)";

/* Current line number (used for input and later the output as well). */

static long lineno;


/* A vector of lines. */

typedef struct {
  Vector_t rep;
} VectorLine_t;

static inline void VectorLine_init (VectorLine_t* v)
{
  Vector_init(&v->rep);
}

static inline unsigned long VectorLine_length (const VectorLine_t* v)
{
  return Vector_length(&v->rep);
}

static inline void VectorLine_add (VectorLine_t* v, const Line_t* elt)
{
  Vector_add(&v->rep,elt);
}

static inline Line_t* VectorLine_element (const VectorLine_t* v,
                                          unsigned long i)
{
  return (Line_t*) Vector_element(&v->rep,i);
}

#ifdef unused
static inline void VectorLine_set_element (VectorLine_t* v, unsigned long i,
                                           const Line_t* elt)
{
  Vector_set_element(&v->rep,i,elt);
}
#endif


/* =============================== INPUT ================================== */


/* The vector of all lines read. */

static VectorLine_t* lines;


/* Read a line, or NULL if EOF is encountered. */

static char* get_line (FILE* fp)
{
  int len = 1;
  char* line = (char*) xmalloc(len);
  int index = 0;
  while (1) {
    int c = getc(fp);
    if (c==EOF) { if (index>0) break; else { xfree(line); return NULL; } }
    if (c=='\n') break;
    if (index >= len-1) {
      len = 2*len;
      line = (char*) xrealloc(line,len);
    }
    line[index++] = c;
  }
  line[index] = '\0';
  return line;
}


/* Decode a #line directive. If the line represents a #line directive,
return the line number. Else return -1. */

static int decode_line_directive (const char* line)
{
  unsigned long n = strlen(line);
  unsigned long i = 0;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Parse a '#'. */
  if (i < n && line[i] == '#')
    i++;
  else
    return -1;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "line". */
  if (i+4 < n
      && line[i+0] == 'l'
      && line[i+1] == 'i'
      && line[i+2] == 'n'
      && line[i+3] == 'e'
      && is_whitespace(line[i+4])) {
    i += 4;
    for (; i < n && is_whitespace(line[i]); i++);
  }
  /* Check for a digit. */
  if (!(i < n && is_digit(line[i])))
    return -1;
  { unsigned long i1 = i;
    for (; i < n && is_digit(line[i]); i++);
    { unsigned long i2 = i;
      /* Convert digit string to a `long'. */
      char* digits = substring(line,i1,i2);
      errno = 0;
      { long result = strtol(digits,NULL,10);
        xfree(digits);
        if (errno != 0) return -1;
        if (result < 0) abort();
        /* Check for a source file name. */
        for (; i < n && is_whitespace(line[i]); i++);
        if (i < n && line[i] == '"') {
          unsigned long i3;
          i++;
          i3 = i;
          for (; i < n && line[i] != '"'; i++);
          if (i < n && line[i] == '"') {
            unsigned long i4 = i;
            file = substring(line,i3,i4);
          }
        }
        return result;
} } } }


/* Read the input file. Fill `lines'. */

static void read_all_input (FILE* fp)
{
  lineno = 1;
  lines = (VectorLine_t*)xmalloc(sizeof(VectorLine_t)); VectorLine_init(lines);
  {
    boolean_t is_continuation_line = FALSE;
    while (1) {
      char* line = get_line(fp);
      if (!line) break;
      if (is_continuation_line) {
        Line_t* last = VectorLine_element(lines,VectorLine_length(lines)-1);
        char* prev = substring(last->contents,0,strlen(last->contents)-1);
        char* conc = concat2(prev,line);
        xfree(last->contents);
        xfree(prev);
        xfree(line);
        line = last->contents = conc;
        lineno++;
      } else {
        long line_directive = decode_line_directive(line);
        if (line_directive >= 0) {
          lineno = line_directive;
          line = "";
        } else {
          VectorLine_add(lines,make_Line(lineno,line));
          lineno++;
        }
      }
      { unsigned long linelen = strlen(line);
        is_continuation_line = (linelen > 0 && line[linelen-1] == '\\');
      }
    }
} }


/* =============================== PARSE ================================== */


/* A vector of strings. */

typedef struct {
  Vector_t rep;
} VectorString_t;

static inline void VectorString_init (VectorString_t* v)
{
  Vector_init(&v->rep);
}

static VectorString_t* make_VectorString (void)
{
  VectorString_t* v = (VectorString_t*) xmalloc(sizeof(VectorString_t));
  VectorString_init(v);
  return v;
}

static inline unsigned long VectorString_length (const VectorString_t* v)
{
  return Vector_length(&v->rep);
}

static inline void VectorString_add (VectorString_t* v, const char* elt)
{
  Vector_add(&v->rep,elt);
}

static inline const char* VectorString_element (const VectorString_t* v,
                                                unsigned long i)
{
  return (const char*) Vector_element(&v->rep,i);
}

static inline void VectorString_set_element (VectorString_t* v,
                                             unsigned long i, const char* elt)
{
  Vector_set_element(&v->rep,i,elt);
}

#ifdef unused
static inline void VectorString_init_clone (VectorString_t* w,
                                            const VectorString_t* v)
{
  Vector_init_clone(&w->rep,&v->rep);
}
#endif

#ifdef unused
static VectorString_t* VectorString_clone (const VectorString_t* v)
{
  VectorString_t* w = (VectorString_t*) xmalloc(sizeof(VectorString_t));
  VectorString_init_clone(w,v);
  return w;
}
#endif

/* Tests whether v starts with w. */
static boolean_t VectorString_startsWith (const VectorString_t* v,
                                          const VectorString_t* w)
{
  unsigned long n = VectorString_length(w);
  if (VectorString_length(v) >= n) {
    unsigned long i;
    for (i = 0; i < n; i++)
      if (!String_equals(VectorString_element(v,i),VectorString_element(w,i)))
        return FALSE;
    return TRUE;
  }
  return FALSE;
}


/* A stack of vectors of strings. */

typedef struct {
  Vector_t rep;
} StackVectorString_t;

static inline void StackVectorString_init (StackVectorString_t* v)
{
  Vector_init(&v->rep);
}

static StackVectorString_t* make_StackVectorString (void)
{
  StackVectorString_t* v =
    (StackVectorString_t*) xmalloc(sizeof(StackVectorString_t));
  StackVectorString_init(v);
  return v;
}

static inline unsigned long StackVectorString_length
(const StackVectorString_t* v)
{
  return Vector_length(&v->rep);
}

#ifdef unused
static inline boolean_t StackVectorString_is_empty
(const StackVectorString_t* v)
{
  return StackVectorString_length(v) == 0;
}
#endif

static inline void StackVectorString_push (StackVectorString_t* v,
                                           const VectorString_t* elt)
{
  Vector_add(&v->rep,elt);
}

static inline VectorString_t* StackVectorString_element
(const StackVectorString_t* v, unsigned long i)
{
  return (VectorString_t*) Vector_element(&v->rep,i);
}

static VectorString_t* StackVectorString_peek (StackVectorString_t* v)
{
  unsigned long n = StackVectorString_length(v);
  if (n == 0) { fprintf(stderr,"stack empty\n"); exit(1); }
  return StackVectorString_element(v,n-1);
}

static VectorString_t* StackVectorString_pop (StackVectorString_t* v)
{
  unsigned long n = StackVectorString_length(v);
  if (n == 0) { fprintf(stderr,"stack empty\n"); exit(1); }
 {VectorString_t* result = StackVectorString_element(v,n-1);
  v->rep.index -= 1;
  return result;
}}

/* Push elt, and optimize: elt can be removed if is starts with an already
present string sequence. If another element starts with elt, that one can
be removed. */
static void StackVectorString_push_optimize (StackVectorString_t* v,
                                             const VectorString_t* elt)
{
  unsigned long n = StackVectorString_length(v);
  unsigned long i;
  for (i = 0; i < n; i++)
    if (VectorString_startsWith(elt,StackVectorString_element(v,i)))
      return;
  for (i = 0; i < n; )
    if (VectorString_startsWith(StackVectorString_element(v,i),elt)) {
      Vector_remove_element(&v->rep,i);
      n--;
    } else
      i++;
  Vector_add(&v->rep,elt);
}


/* The #if[def] stack. All the conditions are implicitly combined by &&.
For every #if we start a new entry in the stack, which is popped when we
see the corresponding #endif. This is a stack of vector of string, not a
stack of string, because when a #elif is seen, we add an element to the
stack without popping the previous one. */

static StackVectorString_t* ifdef_stack;

/* Operations on the #if[def] stack. */

static void do_if (const char * condition)
{
  VectorString_t* v = make_VectorString();
  VectorString_add(v,condition);
  StackVectorString_push(ifdef_stack,v);
}

static void do_else (void)
{
  VectorString_t* v = StackVectorString_peek(ifdef_stack);
  unsigned long i = VectorString_length(v) - 1;
  const char* lastcondition = VectorString_element(v,i);
  lastcondition = concat3("!(",lastcondition,")");
  VectorString_set_element(v,i,lastcondition);
}

static void do_elif (const char * condition)
{
  VectorString_t* v = StackVectorString_peek(ifdef_stack);
  unsigned long i = VectorString_length(v) - 1;
  const char* lastcondition = VectorString_element(v,i);
  lastcondition = concat3("!(",lastcondition,")");
  VectorString_set_element(v,i,lastcondition);
  VectorString_add(v,condition);
}

static void do_endif (void)
{
  StackVectorString_pop(ifdef_stack);
}

/* Returns the current #if condition.
It is a vector of strings, implicitly combined by &&.
The vector is freshly constructed, but the strings are shared. */

static VectorString_t* current_condition (void)
{
  VectorString_t* result = make_VectorString();
  unsigned long n = StackVectorString_length(ifdef_stack);
  unsigned long i;
  for (i = 0; i < n; i++) {
    const VectorString_t* v = StackVectorString_element(ifdef_stack,i);
    unsigned long m = VectorString_length(v);
    unsigned long j;
    for (j = 0; j < m; j++)
      VectorString_add(result,VectorString_element(v,j));
  }
  return result;
}


/* Parsing of #if/#else/#elif/#endif lines. */

static const char* is_if (const char* line)
{
  unsigned long n = strlen(line);
  unsigned long i = 0;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Parse a '#'. */
  if (i < n && line[i] == '#')
    i++;
  else
    return NULL;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "if". */
  if (i+2 < n
      && line[i+0] == 'i'
      && line[i+1] == 'f'
      && is_whitespace(line[i+2])) {
    i += 3;
    for (; i < n && is_whitespace(line[i]); i++);
    for (; n > i && is_whitespace(line[n-1]); n--);
    return substring(line,i,n);
  }
  /* Check for "ifdef". */
  if (i+5 < n
      && line[i+0] == 'i'
      && line[i+1] == 'f'
      && line[i+2] == 'd'
      && line[i+3] == 'e'
      && line[i+4] == 'f'
      && is_whitespace(line[i+5])) {
    i += 6;
    for (; i < n && is_whitespace(line[i]); i++);
    for (; n > i && is_whitespace(line[n-1]); n--);
   {char* term = substring(line,i,n);
    const char* result = concat3("defined(",term,")");
    xfree(term);
    return result;
  }}
  /* Check for "ifndef". */
  if (i+6 < n
      && line[i+0] == 'i'
      && line[i+1] == 'f'
      && line[i+2] == 'n'
      && line[i+3] == 'd'
      && line[i+4] == 'e'
      && line[i+5] == 'f'
      && is_whitespace(line[i+6])) {
    i += 7;
    for (; i < n && is_whitespace(line[i]); i++);
    for (; n > i && is_whitespace(line[n-1]); n--);
   {char* term = substring(line,i,n);
    const char* result = concat3("!defined(",term,")");
    xfree(term);
    return result;
  }}
  return NULL;
}

static boolean_t is_else (const char* line)
{
  unsigned long n = strlen(line);
  unsigned long i = 0;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Parse a '#'. */
  if (i < n && line[i] == '#')
    i++;
  else
    return FALSE;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "else". */
  if (i+4 <= n
      && line[i+0] == 'e'
      && line[i+1] == 'l'
      && line[i+2] == 's'
      && line[i+3] == 'e'
      && (i+4 == n || is_whitespace(line[i+4]))) {
    return TRUE;
  }
  return FALSE;
}

static const char* is_elif (const char* line)
{
  unsigned long n = strlen(line);
  unsigned long i = 0;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Parse a '#'. */
  if (i < n && line[i] == '#')
    i++;
  else
    return NULL;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "elif". */
  if (i+4 < n
      && line[i+0] == 'e'
      && line[i+1] == 'l'
      && line[i+2] == 'i'
      && line[i+3] == 'f'
      && is_whitespace(line[i+4])) {
    i += 5;
    for (; i < n && is_whitespace(line[i]); i++);
    for (; n > i && is_whitespace(line[n-1]); n--);
    return substring(line,i,n);
  }
  return NULL;
}

static boolean_t is_endif (const char* line)
{
  unsigned long n = strlen(line);
  unsigned long i = 0;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Parse a '#'. */
  if (i < n && line[i] == '#')
    i++;
  else
    return FALSE;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "endif". */
  if (i+5 <= n
      && line[i+0] == 'e'
      && line[i+1] == 'n'
      && line[i+2] == 'd'
      && line[i+3] == 'i'
      && line[i+4] == 'f'
      && (i+5 == n || is_whitespace(line[i+5]))) {
    return TRUE;
  }
  return FALSE;
}


/* When we see the DEFMODULE(name,package) line, we store the name. */
static const char* name_defmodule = NULL;
/* index of line containing DEFMODULE */
static unsigned long line_defmodule = 0;
static const char* default_packname = NULL;

static boolean_t is_defmodule (const char* line) {
  unsigned long n = strlen(line);
  unsigned long i = 0;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "DEFMODULE". */
  if (i+9 < n
      && line[i+0] == 'D'
      && line[i+1] == 'E'
      && line[i+2] == 'F'
      && line[i+3] == 'M'
      && line[i+4] == 'O'
      && line[i+5] == 'D'
      && line[i+6] == 'U'
      && line[i+7] == 'L'
      && line[i+8] == 'E'
      && (is_whitespace(line[i+9]) || line[i+9] == '(')) {
    i += 9;
    for (; i < n && is_whitespace(line[i]); i++);
    if (i < n && line[i] == '(') {
      unsigned long i1, i2;
      i += 1;
      i1 = i;
      for (; i < n; i++)
        if (line[i] == ',' || line[i] == '(' || line[i] == ')')
          break;
      i2 = i;
      if (i < n && line[i] == ',') {
        unsigned long i3, i4;
        i += 1;
        i3 = i;
        for (; i < n; i++)
          if (line[i] == ',' || line[i] == '(' || line[i] == ')')
            break;
        i4 = i;
        if (i < n && line[i] == ')') {
          /* First macro argument is from i1 to i2, second is from i3 to i4. */
          while (i1 < i2 && is_whitespace(line[i1])) i1++;
          while (i1 < i2 && is_whitespace(line[i2-1])) i2--;
          while (i3 < i4 && is_whitespace(line[i3])) i3++;
          while (i3 < i4 && is_whitespace(line[i4-1])) i4--;
          if (i4-i3 >= 2 && line[i3] == '"' && line[i4-1] == '"') {
            name_defmodule = substring(line,i1,i2);
            default_packname = substring(line,i3+1,i4-1);
            return TRUE;
          }
        }
      }
    }
    fprintf(stderr,"%s:%ld: invalid DEFMODULE macro syntax: %s\n",
            file,lineno,line);
    exit(1);
  }
  return FALSE;
}


/* Entries for the object table. */

typedef struct {
  const char* initstring; /* The string that, when read by the Lisp reader, */
                          /* initializes the object. */
  const char* tag;        /* The struct tag we use for this object. */
  StackVectorString_t* condition; /* The #if condition of this object. */
} Objdef_t;


/* A vector of Objdef. */

typedef struct {
  Vector_t rep;
} VectorObjdef_t;

static inline void VectorObjdef_init (VectorObjdef_t* v)
{
  Vector_init(&v->rep);
}

static VectorObjdef_t* make_VectorObjdef (void)
{
  VectorObjdef_t* v = (VectorObjdef_t*) xmalloc(sizeof(VectorObjdef_t));
  VectorObjdef_init(v);
  return v;
}

static inline unsigned long VectorObjdef_length (const VectorObjdef_t* v)
{
  return Vector_length(&v->rep);
}

static inline void VectorObjdef_add (VectorObjdef_t* v, Objdef_t* elt)
{
  Vector_add(&v->rep,elt);
}

static inline Objdef_t* VectorObjdef_element (const VectorObjdef_t* v,
                                              unsigned long i)
{
  return (Objdef_t*) Vector_element(&v->rep,i);
}

#ifdef unused
static inline void VectorObjdef_set_element (VectorObjdef_t* v,
                                             unsigned long i, Objdef_t* elt)
{
  Vector_set_element(&v->rep,i,elt);
}
#endif


/* The table of all Objdefs. */

static VectorObjdef_t* objdefs;

/* Looks up an Objdef with a given tag. */

static Objdef_t* get_objdef_from_tag (const char* tag)
{
  unsigned long n = VectorObjdef_length(objdefs);
  unsigned long i;
  for (i = 0; i < n; i++) {
    Objdef_t* odef = VectorObjdef_element(objdefs,i);
    if (String_equals(odef->tag,tag))
      return odef;
  }
  return NULL;
}

/* Looks up or creates an Objdef for a given initstring. */

static Objdef_t* get_objdef_aux (const char* initstring,
                                 VectorString_t* condition)
{
  Objdef_t* odef;
  { /* First search in the table. */
    unsigned long n = VectorObjdef_length(objdefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      odef = VectorObjdef_element(objdefs,i);
      if (String_equals(odef->initstring,initstring))
        goto found;
    }
  }
  { /* Create the tag. */
    char* tagbuf = (char*) xmalloc(3*strlen(initstring)+10);
    char* q = tagbuf;
    strcpy(q,"object_");
    q += strlen(q);
    {
      const char* p;
      for (p = initstring; *p != '\0'; p++) {
        char c = *p;
        if (c >= 'A' && c <= 'Z')
          *q++ = c+32;
        else if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9'))
          *q++ = c;
        else if (c == ':' && p == initstring)
          *q++ = 'K';
        else {
          *q++ = '_';
          *q++ = "0123456789ABCDEF"[((unsigned char)c >> 4) & 0x0F];
          *q++ = "0123456789ABCDEF"[(unsigned char)c & 0x0F];
        }
      }
    }
    *q = '\0';
    if (get_objdef_from_tag(tagbuf) != NULL) {
      int i;
      /* Append a suffix to make sure tags are unique. */
      for (i = 1; ; i++) {
        sprintf(q,"_%d",i);
        if (get_objdef_from_tag(tagbuf) == NULL)
          break;
      }
    }
    { /* Found a unique tag. Allocate a new Objdef. */
      char* tag = (char*) xmalloc(strlen(tagbuf)+1);
      strcpy(tag,tagbuf);
      xfree(tagbuf);
      odef = (Objdef_t*) xmalloc(sizeof(Objdef_t));
      odef->initstring = initstring;
      odef->tag = tag;
      odef->condition = make_StackVectorString();
      VectorObjdef_add(objdefs,odef);
    }
  }
 found:
  StackVectorString_push_optimize(odef->condition,condition);
  return odef;
}

static inline Objdef_t* get_objdef (const char* initstring)
{
  return get_objdef_aux(initstring,current_condition());
}


/* Representation of a function signature. */
typedef enum { /* see lispbibl.d */
  seclass_foldable,
  seclass_no_se,
  seclass_read,
  seclass_write,
  seclass_default,
} seclass_t;
static const char *seclass_table[] = {
  "seclass_foldable", "seclass_no_se", "seclass_read",
  "seclass_write","seclass_default"
};

typedef struct {
  seclass_t seclass;
  int req;
  int opt;
  boolean_t rest;
  boolean_t key;
  VectorObjdef_t* keywords;
  StackVectorString_t* condition; /* The #if condition of this object. */
} Signature_t;

/* Compares two signatures for equality (without condition). */

static boolean_t Signature_equals (const Signature_t* sig1,
                                   const Signature_t* sig2)
{
  if (sig1->req == sig2->req &&
      sig1->opt == sig2->opt &&
      sig1->rest == sig2->rest &&
      sig1->seclass == sig2->seclass &&
      sig1->key == sig2->key) {
    unsigned long len1 = VectorObjdef_length(sig1->keywords);
    unsigned long len2 = VectorObjdef_length(sig2->keywords);
    if (len1 == len2) {
      unsigned long i;
      for (i = 0; i < len1; i++)
        if (VectorObjdef_element(sig1->keywords,i) !=
            VectorObjdef_element(sig2->keywords,i))
          return FALSE;
      return TRUE;
    }
  }
  return FALSE;
}

/* Returns the signature (without condition) denoted by the line, or NULL
in case of syntax error.
Example for line: "x y [&optional z] [&rest foo | &key a b c]" */

static Signature_t* parseSignature (const char* line)
{
  int req = 0;
  int opt = 0;
  int rest = 0;
  VectorObjdef_t* keywords = make_VectorObjdef();
  boolean_t optional_seen = FALSE;
  boolean_t rest_seen = FALSE;
  boolean_t key_seen = FALSE;
  /* Go through the line and tokenize it. */
  const char* p1 = line;
  const char* p2;
  for (;;) {
    while (is_whitespace(*p1))
      p1++;
    if (*p1 == '\0')
      break;
    p2 = p1;
    while (*p2 != '\0' && !is_whitespace(*p2))
      p2++;
    /* Found a token from p1 to p2. */
    {
      char* token = substring_from_to(p1,p2);
      /* Analyze the token. */
      if (String_equalsIgnoreCase(token,"&optional")) {
        if (optional_seen || rest_seen || key_seen)
          return NULL;
        optional_seen = TRUE;
      } else if (String_equalsIgnoreCase(token,"&key")) {
        if (rest_seen || key_seen)
          return NULL;
        key_seen = TRUE;
      } else if (String_equalsIgnoreCase(token,"&rest")) {
        if (rest_seen || key_seen)
          return NULL;
        rest_seen = TRUE;
      } else {
        if (rest_seen)
          rest++;
        else if (key_seen) {
          char* keyword_name;
          char* keyword_initstring;
          Objdef_t* keyword_odef;
          if ((keyword_name = strrchr(token,':')) != NULL)
            keyword_name = keyword_name+1;
          else
            keyword_name = token;
          keyword_initstring = concat2(":",keyword_name);
          keyword_odef = get_objdef(keyword_initstring);
          VectorObjdef_add(keywords,keyword_odef);
        } else if (optional_seen)
          opt++;
        else
          req++;
      }
      xfree(token);
    }
    p1 = p2;
  }
  if (rest_seen && rest != 1)
    return NULL;
  {
    Signature_t* sig = (Signature_t*) xmalloc(sizeof(Signature_t));
    sig->seclass = seclass_default;
    sig->req = req;
    sig->opt = opt;
    sig->rest = rest_seen;
    sig->key = key_seen;
    sig->keywords = keywords;
    return sig;
  }
}


/* A vector of Signature. */

typedef struct {
  Vector_t rep;
} VectorSignature_t;

static inline void VectorSignature_init (VectorSignature_t* v)
{
  Vector_init(&v->rep);
}

static VectorSignature_t* make_VectorSignature (void)
{
  VectorSignature_t* v =
    (VectorSignature_t*) xmalloc(sizeof(VectorSignature_t));
  VectorSignature_init(v);
  return v;
}

static inline unsigned long VectorSignature_length (const VectorSignature_t* v)
{
  return Vector_length(&v->rep);
}

static inline void VectorSignature_add (VectorSignature_t* v, Signature_t* elt)
{
  Vector_add(&v->rep,elt);
}

static inline Signature_t* VectorSignature_element (const VectorSignature_t* v,
                                                    unsigned long i)
{
  return (Signature_t*) Vector_element(&v->rep,i);
}

#ifdef unused
static inline void VectorSignature_set_element (VectorSignature_t* v,
                                                unsigned long i,
                                                Signature_t* elt)
{
  Vector_set_element(&v->rep,i,elt);
}
#endif


/* Entries for the function table. */

typedef struct {
  const char* packname;  /* The symbol's package name */
  const char* printname; /* The symbol's print name */
  const char* tag;       /* The struct tag we use for this function */
  /* The total #if condition of this function. */
  StackVectorString_t* condition;
  /* The functions possible signatures, together
     with their individual #if conditions. */
  VectorSignature_t* signatures;
} Fundef_t;


/* A vector of Fundef. */

typedef struct {
  Vector_t rep;
} VectorFundef_t;

static inline void VectorFundef_init (VectorFundef_t* v)
{
  Vector_init(&v->rep);
}

static VectorFundef_t* make_VectorFundef (void)
{
  VectorFundef_t* v = (VectorFundef_t*) xmalloc(sizeof(VectorFundef_t));
  VectorFundef_init(v);
  return v;
}

static inline unsigned long VectorFundef_length (const VectorFundef_t* v)
{
  return Vector_length(&v->rep);
}

static inline void VectorFundef_add (VectorFundef_t* v, Fundef_t* elt)
{
  Vector_add(&v->rep,elt);
}

static inline Fundef_t* VectorFundef_element (const VectorFundef_t* v,
                                              unsigned long i)
{
  return (Fundef_t*) Vector_element(&v->rep,i);
}

#ifdef unused
static inline void VectorFundef_set_element (VectorFundef_t* v,
                                             unsigned long i, Fundef_t* elt)
{
  Vector_set_element(&v->rep,i,elt);
}
#endif


/* The table of all Fundefs. */

static VectorFundef_t* fundefs;

/* Looks up an Fundef with a given tag. */

static Fundef_t* get_fundef_from_tag (const char* tag)
{
  unsigned long n = VectorFundef_length(fundefs);
  unsigned long i;
  for (i = 0; i < n; i++) {
    Fundef_t* fdef = VectorFundef_element(fundefs,i);
    if (String_equals(fdef->tag,tag))
      return fdef;
  }
  return NULL;
}

/* Looks up or creates a Fundef for a given function name,
   and adds the given signature to it. */

static Fundef_t* get_fundef_aux (const char* funname, Signature_t* sig,
                               VectorString_t* condition)
{
  Fundef_t* fdef;
  /* Split the function name into a package name and a print name. */
  const char* packname;
  const char* printname;
  {
    const char* tmp = strchr(funname,':');
    if (tmp) {
      packname = substring_from_to(funname,tmp);
      tmp++;
      if (*tmp == ':')
        tmp++;
      if (strchr(tmp,':')) {
        fprintf(stderr,"%s:%ld: Function definition symbol has too many package markers: %s\n",file,lineno,funname);
        exit(1);
      }
      printname = substring(tmp,0,strlen(tmp));
    } else {
      if (default_packname == NULL) {
        fprintf(stderr,"%s:%ld: Function definition needs a packaged symbol: %s\n",file,lineno,funname);
        exit(1);
      } else {
        packname = default_packname;
        printname = funname;
      }
    }
  }
  /* First search in the table. */
  {
    unsigned long n = VectorFundef_length(fundefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      fdef = VectorFundef_element(fundefs,i);
      if (String_equals(fdef->packname,packname) &&
          String_equals(fdef->printname,printname))
        goto found;
    }
  }
  /* Create the tag. */
  {
    char* initstring = concat3(packname,":",printname);
    char* tagbuf = (char*) xmalloc(3*strlen(initstring)+10);
    char* q = tagbuf;
    strcpy(q,"subr_t");
    q += strlen(q);
    {
      const char* p;
      for (p = initstring; *p != '\0'; p++) {
        char c = *p;
        if (c >= 'A' && c <= 'Z')
          *q++ = c+32;
        else if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9'))
          *q++ = c;
        else if (c == ':') {
          *q++ = '_';
          *q++ = '_';
        } else {
          *q++ = '_';
          *q++ = "0123456789ABCDEF"[((unsigned char)c >> 4) & 0x0F];
          *q++ = "0123456789ABCDEF"[(unsigned char)c & 0x0F];
        }
      }
    }
    *q = '\0';
    if (get_fundef_from_tag(tagbuf) != NULL) {
      int i;
      /* Append a suffix to make sure tags are unique. */
      for (i = 1; ; i++) {
        sprintf(q,"_%d",i);
        if (get_fundef_from_tag(tagbuf) == NULL)
          break;
      }
    }
    /* Found a unique tag. Allocate a new Fundef. */
    {
      char* tag = (char*) xmalloc(strlen(tagbuf)+1);
      strcpy(tag,tagbuf);
      xfree(tagbuf);
      fdef = (Fundef_t*) xmalloc(sizeof(Fundef_t));
      fdef->packname = packname;
      fdef->printname = printname;
      fdef->tag = tag;
      fdef->condition = make_StackVectorString();
      fdef->signatures = make_VectorSignature();
      VectorFundef_add(fundefs,fdef);
    }
  }
found:
  StackVectorString_push_optimize(fdef->condition,condition);
  /* Now add the signature. */
  {
    VectorSignature_t* signatures = fdef->signatures;
    unsigned long n = VectorSignature_length(signatures);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Signature_t* sig_i = VectorSignature_element(signatures,i);
      if (Signature_equals(sig_i,sig)) {
        StackVectorString_push_optimize(sig_i->condition,condition);
        goto done_signature;
      }
    }
    sig->condition = make_StackVectorString();
    StackVectorString_push_optimize(sig->condition,condition);
    VectorSignature_add(signatures,sig);
  }
done_signature:
  return fdef;
}

static inline Fundef_t* get_fundef (const char* funname, Signature_t* sig)
{
  return get_fundef_aux(funname,sig,current_condition());
}


/* Print a signature in a form suitable as argument list for LISPFUN. */

static char* get_signature_for_LISPFUN (const Fundef_t* fdef,
                                        const Signature_t* sig)
{
  /* sprintf(buffer,"(%s,%d,%d,%s,%s,%lu,NIL)",
             fdef->tag,
             sig->req,
             sig->opt,
             (sig->rest?"rest":"norest"),
             (sig->key?"key":"nokey"),
             VectorObjdef_length(sig->keywords)); */
  char buffer[1+15+1+10+1+10+1+6+1+5+10+5+1];
  sprintf(buffer,",%s,%d,%d,%s,%s,%lu,NIL)",
          seclass_table[sig->seclass],sig->req,sig->opt,
          (sig->rest?"rest":"norest"),
          (sig->key?"key":"nokey"),
          VectorObjdef_length(sig->keywords));
  return concat3("(",fdef->tag,buffer);
}


/* Parse a  DEFUN(funname,lambdalist)  line,
and turn it into  DEFUN(funname,lambdalist,signature). */

static char* is_defun (const char* line) {
  unsigned long n = strlen(line);
  unsigned long i = 0;
  seclass_t seclass = seclass_default;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "DEFUN". */
  if (i+5 < n
      && line[i+0] == 'D'
      && line[i+1] == 'E'
      && line[i+2] == 'F'
      && line[i+3] == 'U'
      && line[i+4] == 'N'
      && (is_whitespace(line[i+5]) || line[i+5] == '('
          || (line[i+5]=='F' ? seclass = seclass_foldable,++i : 0)
          || (line[i+5]=='N' ? seclass = seclass_no_se,   ++i : 0)
          || (line[i+5]=='R' ? seclass = seclass_read,    ++i : 0)
          || (line[i+5]=='W' ? seclass = seclass_write,   ++i : 0)
          || (line[i+5]=='D' ? seclass = seclass_default, ++i : 0))) {
    i += 5;
    for (; i < n && is_whitespace(line[i]); i++);
    if (i < n && line[i] == '(') {
      unsigned long i1, i2, i3, i4;
      i += 1;
      i1 = i;
      for (; i < n; i++)
        if (line[i] == ',' || line[i] == '(' || line[i] == ')')
          break;
      i2 = i;
      if (i < n && line[i] == ',') {
        i += 1;
        i3 = i;
        for (; i < n; i++)
          if (line[i] == ',' || line[i] == '(' || line[i] == ')')
            break;
        i4 = i;
        if (i < n && line[i] == ')') {
          /* First macro argument is from i1 to i2, second is from i3 to i4. */
          while (i1 < i2 && is_whitespace(line[i1])) i1++;
          while (i1 < i2 && is_whitespace(line[i2-1])) i2--;
          {
            char* funname = substring(line,i1,i2);
            char* lambdalist = substring(line,i3,i4);
            Signature_t* signature = parseSignature(lambdalist);
            if (signature == NULL) {
              fprintf(stderr,"%s:%ld: invalid lambdalist syntax for function `%s': %s\n",file,lineno,funname,lambdalist);
              exit(1);
            }
            signature->seclass = seclass;
            {
              Fundef_t* fdef = get_fundef(funname,signature);
              return concat4(substring(line,0,i),",",
                             get_signature_for_LISPFUN(fdef,signature),
                             substring(line,i,n));
            }
          }
        }
      }
    }
    fprintf(stderr,"%s:%ld: invalid DEFUN macro syntax: %s\n",
            file,lineno,line);
    exit(1);
  }
  return NULL;
}


/* Entries for the variable table. */

typedef struct {
  const char* tag;              /* The struct tag of this variable. */
  /* The total #if condition of this variable. */
  StackVectorString_t* condition;
} Vardef_t;


/* A vector of Vardef. */

typedef struct {
  Vector_t rep;
} VectorVardef_t;

static inline void VectorVardef_init (VectorVardef_t* v)
{
  Vector_init(&v->rep);
}

static VectorVardef_t* make_VectorVardef (void)
{
  VectorVardef_t* v = (VectorVardef_t*) xmalloc(sizeof(VectorVardef_t));
  VectorVardef_init(v);
  return v;
}

static inline unsigned long VectorVardef_length (const VectorVardef_t* v)
{
  return Vector_length(&v->rep);
}

static inline void VectorVardef_add (VectorVardef_t* v, Vardef_t* elt)
{
  Vector_add(&v->rep,elt);
}

static inline Vardef_t* VectorVardef_element (const VectorVardef_t* v,
                                            unsigned long i)
{
  return (Vardef_t*) Vector_element(&v->rep,i);
}

static inline void VectorVardef_set_element (VectorVardef_t* v,
                                             unsigned long i, Vardef_t* elt)
{
  Vector_set_element(&v->rep,i,elt);
}


/* The table of all Vardefs. */

static VectorVardef_t* vardefs;


/* Looks up an Vardef with a given tag. */

static Vardef_t* get_vardef_from_tag (const char* tag)
{
  unsigned long n = VectorVardef_length(vardefs);
  unsigned long i;
  for (i = 0; i < n; i++) {
    Vardef_t* vdef = VectorVardef_element(vardefs,i);
    if (String_equals(vdef->tag,tag))
      return vdef;
  }
  return NULL;
}

/* Looks up or creates a Vardef for a given variable name. */

static Vardef_t* get_vardef_aux (const char* varname,
                                 VectorString_t* condition)
{
  Vardef_t* vdef;
  /* First search in the table. */
  vdef = get_vardef_from_tag(varname);
  if (vdef == NULL) {
    /* Allocate a new Vardef. */
    vdef = (Vardef_t*) xmalloc(sizeof(Vardef_t));
    vdef->tag = varname;
    vdef->condition = make_StackVectorString();
    VectorVardef_add(vardefs,vdef);
  }
  StackVectorString_push_optimize(vdef->condition,condition);
  return vdef;
}

static inline Vardef_t* get_vardef (const char* varname)
{
  return get_vardef_aux(varname,current_condition());
}


/* Variable initializers. (We treat them separately from the variables
 themselves, so that they are executed in order.) */

typedef struct {
  const char* tag;         /* The struct tag of this variable. */
  const char* initform;    /* A C expression initializing this variable. */
  VectorString_t* condition; /* The #if condition of this initializer. */
} Varinit_t;

static inline Varinit_t* make_Varinit (const char* tag, const char* initform,
                                       VectorString_t* condition)
{
  Varinit_t* v = (Varinit_t*) xmalloc(sizeof(Varinit_t));
  v->tag = tag;
  v->initform = initform;
  v->condition = condition;
  return v;
}


/* A vector of Varinit. */

typedef struct {
  Vector_t rep;
} VectorVarinit_t;

static inline void VectorVarinit_init (VectorVarinit_t* v)
{
  Vector_init(&v->rep);
}

static VectorVarinit_t* make_VectorVarinit (void)
{
  VectorVarinit_t* v = (VectorVarinit_t*) xmalloc(sizeof(VectorVarinit_t));
  VectorVarinit_init(v);
  return v;
}

static inline unsigned long VectorVarinit_length (const VectorVarinit_t* v)
{
  return Vector_length(&v->rep);
}

static inline void VectorVarinit_add (VectorVarinit_t* v, Varinit_t* elt)
{
  Vector_add(&v->rep,elt);
}

static inline Varinit_t* VectorVarinit_element (const VectorVarinit_t* v,
                                              unsigned long i)
{
  return (Varinit_t*) Vector_element(&v->rep,i);
}

static inline void VectorVarinit_set_element (VectorVarinit_t* v,
                                              unsigned long i, Varinit_t* elt)
{
  Vector_set_element(&v->rep,i,elt);
}


/* The list of all variable initializers, as they appear in the source. */

static VectorVarinit_t* varinits;


/* Parse a  DEFVAR(varname,initform)  line, and turn it into  DEFVAR(varname).
 (We remove the initform because it might contain backquoted stuff including
  commas and parentheses.) */

static char* is_defvar (const char* line) {
  unsigned long n = strlen(line);
  unsigned long i = 0;
  /* Skip whitespace. */
  for (; i < n && is_whitespace(line[i]); i++);
  /* Check for "DEFVAR". */
  if (i+6 < n
      && line[i+0] == 'D'
      && line[i+1] == 'E'
      && line[i+2] == 'F'
      && line[i+3] == 'V'
      && line[i+4] == 'A'
      && line[i+5] == 'R'
      && (is_whitespace(line[i+6]) || line[i+6] == '(')) {
    i += 6;
    for (; i < n && is_whitespace(line[i]); i++);
    if (i < n && line[i] == '(') {
      unsigned long i1, i2, i3, i4;
      i += 1;
      i1 = i;
      for (; i < n; i++)
        if (line[i] == ',' || line[i] == '(' || line[i] == ')')
          break;
      i2 = i;
      if (i < n && line[i] == ',') {
        i += 1;
        i3 = i;
        /* Start a lexical analysis. */
        {
          int in_comment = 0; /* comment depth */
          boolean_t in_string = FALSE; /* in "..." ? */
          boolean_t in_char = FALSE;   /* in '...' ? */
          boolean_t in_subst = FALSE;  /* in `...` ? */
          long subst_start = -1;
          int in_paren = 0;   /* parentheses depth */
          while (i < n) {
            char c = line[i];
            if (!in_comment && !in_char && !in_string && !in_subst
                && c == '(') {
              in_paren++;
              i++;
            } else if (!in_comment && !in_char && !in_string && !in_subst
                       && !in_paren && c == ',') {
              fprintf(stderr,"%s:%ld: DEFmacro with two many arguments\n",file,lineno);
              exit(1);
            } else if (!in_comment && !in_char && !in_string && !in_subst
                       && c == ')') {
              if (in_paren > 0) {
                in_paren--;
                i++;
              } else
                break;
            } else if (!in_char && !in_string && !in_subst
                       && i+1 < n && c == '/' && line[i+1] == '*') {
              in_comment++;
              i += 2;
            } else if (!in_char && !in_string && !in_subst
                       && i+1 < n && c == '*' && line[i+1] == '/') {
              in_comment--;
              if (in_comment < 0)
                in_comment = 0;
              i += 2;
            } else if (i+1 < n && c == '\\') {
              if (in_subst && line[i+1] == '`') {
                /* Inside subst, convert \` to simple ` */
                line = concat2(substring(line,0,i),substring(line,i+1,n));
                n--;
                i++;
              } else
                i += 2;
            } else if (!in_comment && !in_char && !in_subst && c == '"') {
              in_string = !in_string;
              i++;
            } else if (!in_comment && !in_string && !in_subst && c == '\'') {
              in_char = !in_char;
              i++;
            } else if (!in_comment && !in_char && !in_string && c == '`') {
              if (!in_subst) {
                in_subst = TRUE;
                subst_start = i;
                i++;
              } else {
                const char* initstring = substring(line,subst_start+1,i);
                Objdef_t* odef = get_objdef(initstring);
                line = concat3(substring(line,0,subst_start),odef->tag,substring(line,i+1,n));
                n = strlen(line);
                i = subst_start + strlen(odef->tag);
                in_subst = FALSE;
                subst_start = -1;
              }
            } else
              i++;
          }
          if (i == n) {
            if (in_string) {
              fprintf(stderr,"%s:%ld: string not terminated\n",file,lineno);
              exit(1);
            }
            if (in_char) {
              fprintf(stderr,"%s:%ld: character not terminated\n",file,lineno);
              exit(1);
            }
            if (in_subst) {
              fprintf(stderr,"%s:%ld: backquote not terminated\n",file,lineno);
              exit(1);
            }
            if (in_comment) {
              fprintf(stderr,"%s:%ld: comment inside DEFnot terminated\n",file,lineno);
              exit(1);
            }
            fprintf(stderr,"%s:%ld: DEFmacro not terminated\n",file,lineno);
            exit(1);
          }
        }
        i4 = i;
        /* First macro argument is from i1 to i2, second is from i3 to i4. */
        while (i1 < i2 && is_whitespace(line[i1])) i1++;
        while (i1 < i2 && is_whitespace(line[i2-1])) i2--;
        {
          char* varname = substring(line,i1,i2);
          Vardef_t* vdef = get_vardef(varname);
          VectorVarinit_add(varinits,make_Varinit(vdef->tag,substring(line,i3,i4),current_condition()));
          /* Remove the second macro argument. */
          return concat2(substring(line,0,i3-1),substring(line,i4,n));
        }
      }
    }
    fprintf(stderr,"%s:%ld: invalid DEFmacro syntax: %s\n",file,lineno,line);
    exit(1);
  }
  return NULL;
}


/* Parse the entire input. */

static void parse (void)
{
  /* Initialize variables. */
  ifdef_stack = make_StackVectorString();
  objdefs = make_VectorObjdef();
  fundefs = make_VectorFundef();
  vardefs = make_VectorVardef();
  varinits = make_VectorVarinit();
  {
    int in_comment = 0; /* comment depth */
    boolean_t in_string = FALSE; /* in "..." ? */
    boolean_t in_char = FALSE;   /* in '...' ? */
    boolean_t in_subst = FALSE;  /* in `...` ? */
    long subst_start = -1;
    int m = VectorLine_length(lines);
    int j;
    for (j = 0; j < m; j++) {
      char* line = VectorLine_element(lines,j)->contents;
      lineno = VectorLine_element(lines,j)->number;
      if (in_comment == 0) {
        /* Check for DEFMODULE. */
        if (is_defmodule(line))
          line_defmodule = j;
        { /* Check for preprocessor commands. */
          const char* condition;
          if ((condition = is_if(line)) != NULL)
            do_if(condition);
          else if (is_else(line))
            do_else();
          else if ((condition = is_elif(line)) != NULL)
            do_elif(condition);
          else if (is_endif(line))
            do_endif();
        }
        { /* Check for DEFUN. */
          char* expanded_line = is_defun(line);
          if (expanded_line != NULL)
            line = expanded_line;
        }
        { /* Check for DEFVAR. */
          char* expanded_line = is_defvar(line);
          if (expanded_line != NULL)
            line = expanded_line;
        }
      }
      { /* General lexical analysis of the line. */
        unsigned long n = strlen(line);
        unsigned long i;
        for (i = 0; i < n; ) {
          char c = line[i];
          if (!in_char && !in_string && !in_subst
              && i+1 < n && c == '/' && line[i+1] == '*') {
            in_comment++;
            i += 2;
          } else if (!in_char && !in_string && !in_subst
                     && i+1 < n && c == '*' && line[i+1] == '/') {
            in_comment--;
            if (in_comment < 0)
              in_comment = 0;
            i += 2;
          } else if (i+1 < n && c == '\\') {
            if (in_subst && line[i+1] == '`') {
              /* Inside subst, convert \` to simple ` */
              line = concat2(substring(line,0,i),substring(line,i+1,n));
              n--;
              i++;
            } else
              i += 2;
          } else if (!in_comment && !in_char && !in_subst && c == '"') {
            in_string = !in_string;
            i++;
          } else if (!in_comment && !in_string && !in_subst && c == '\'') {
            in_char = !in_char;
            i++;
          } else if (!in_comment && !in_char && !in_string && c == '`') {
            if (!in_subst) {
              in_subst = TRUE;
              subst_start = i;
              i++;
            } else {
              const char* initstring = substring(line,subst_start+1,i);
              Objdef_t* odef = get_objdef(initstring);
              line = concat3(substring(line,0,subst_start),odef->tag,substring(line,i+1,n));
              n = strlen(line);
              i = subst_start + strlen(odef->tag);
              in_subst = FALSE;
              subst_start = -1;
            }
          } else
            i++;
        }
      }
      VectorLine_element(lines,j)->contents = line;
      if (in_string) {
        fprintf(stderr,"%s:%ld: string not terminated\n",file,lineno);
        exit(1);
      }
      if (in_char) {
        fprintf(stderr,"%s:%ld: character not terminated\n",file,lineno);
        exit(1);
      }
      if (in_subst) {
        fprintf(stderr,"%s:%ld: backquote not terminated\n",file,lineno);
        exit(1);
      }
    }
  }
}


/* =============================== OUTPUT ================================= */


/* Print a list (cond1 && cond2 && ...) to a stream. */
static void print_condition_part (FILE* stream,
                                  const VectorString_t* condition)
{
  unsigned long n = VectorString_length(condition);
  if (n == 0) {
    fprintf(stream,"1");
    return;
  }
  if (n == 1) {
    fprintf(stream,"%s",VectorString_element(condition,0));
    return;
  }
  {
    unsigned long i;
    for (i = 0; i < n; i++) {
      if (i > 0)
        fprintf(stream," && ");
      fprintf(stream,"(%s)",VectorString_element(condition,i));
    }
  }
}

/* Tests whether a condition is equivalent to 1 (true). */
static inline boolean_t is_true_condition_part (VectorString_t* condition)
{
  unsigned long n = VectorString_length(condition);
  return (n == 0);
}

/* Print a list of lists (cond1 || cond2 || ...) to a stream. */
static void print_condition (FILE* stream, StackVectorString_t* condition)
{
  unsigned long n = StackVectorString_length(condition);
  if (n == 0) {
    fprintf(stream,"0");
    return;
  }
  if (n == 1) {
    print_condition_part(stream,StackVectorString_element(condition,0));
    return;
  }
  {
    unsigned long i;
    for (i = 0; i < n; i++) {
      if (i > 0)
        fprintf(stream," || ");
      fprintf(stream,"(");
      print_condition_part(stream,StackVectorString_element(condition,i));
      fprintf(stream,")");
    }
  }
}

/* Tests whether a condition is equivalent to 0 (false). */
static inline boolean_t is_false_condition (StackVectorString_t* condition)
{
  unsigned long n = StackVectorString_length(condition);
  return (n == 0);
}

/* Tests whether a condition is equivalent to 1 (true). */
static boolean_t is_true_condition (StackVectorString_t* condition)
{
  unsigned long n = StackVectorString_length(condition);
  unsigned long i;
  for (i = 0; i < n; i++)
    if (is_true_condition_part(StackVectorString_element(condition,i)))
      return TRUE;
  return FALSE;
}

/* Prints a newline. Don't print a "\n" directly! */
static inline void print_nl (FILE* stream)
{
  fprintf(stream,"\n");
  lineno++;
}

/* Prints a string in C syntax. */
static void print_C_string (FILE* stream, const char* data)
{
  putc('"',stream);
  for (; *data != '\0'; data++) {
    char c = *data;
    if (c == '"' || c == '\\')
      putc('\\',stream);
    putc(c,stream);
  }
  putc('"',stream);
}

/* Output the tables just after the DEFMODULE line. */
static void output_tables1 (FILE* stream)
{
  const char* modname = name_defmodule;
  const char* object_tab = concat3("module__",modname,"__object_tab");
  const char* object_tab_initdata =
    concat3("module__",modname,"__object_tab_initdata");
  fprintf(stream,"#define O(varname) %s._##varname",object_tab);
  print_nl(stream);
  print_nl(stream);
  fprintf(stream,"struct {");
  print_nl(stream);
  {
    unsigned long n = VectorObjdef_length(objdefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Objdef_t* odef = VectorObjdef_element(objdefs,i);
      if (!is_false_condition(odef->condition)) {
        if (!is_true_condition(odef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,odef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  object _%s;",odef->tag);
        print_nl(stream);
        if (!is_true_condition(odef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  {
    unsigned long n = VectorVardef_length(vardefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Vardef_t* vdef = VectorVardef_element(vardefs,i);
      if (!is_false_condition(vdef->condition)) {
        if (!is_true_condition(vdef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,vdef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  object _%s;",vdef->tag);
        print_nl(stream);
        if (!is_true_condition(vdef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  fprintf(stream,"} %s;",object_tab);
  print_nl(stream);
  {
    unsigned long n = VectorObjdef_length(objdefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Objdef_t* odef = VectorObjdef_element(objdefs,i);
      if (!is_false_condition(odef->condition)) {
        fprintf(stream,"#define %s  %s._%s",odef->tag,object_tab,odef->tag);
        print_nl(stream);
      }
    }
  }
  fprintf(stream,"uintC module__%s__object_tab_size = sizeof(%s)/sizeof(object);",modname,object_tab);
  print_nl(stream);
  print_nl(stream);
  fprintf(stream,"struct {");
  print_nl(stream);
  {
    unsigned long n = VectorObjdef_length(objdefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Objdef_t* odef = VectorObjdef_element(objdefs,i);
      if (!is_false_condition(odef->condition)) {
        if (!is_true_condition(odef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,odef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  object_initdata_t _%s;",odef->tag);
        print_nl(stream);
        if (!is_true_condition(odef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  {
    unsigned long n = VectorVardef_length(vardefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Vardef_t* vdef = VectorVardef_element(vardefs,i);
      if (!is_false_condition(vdef->condition)) {
        if (!is_true_condition(vdef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,vdef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  object_initdata_t _%s;",vdef->tag);
        print_nl(stream);
        if (!is_true_condition(vdef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  fprintf(stream,"  int _dummy_to_avoid_trailing_comma_in_initializer;");
  print_nl(stream);
  fprintf(stream,"} %s = {",object_tab_initdata);
  print_nl(stream);
  {
    unsigned long n = VectorObjdef_length(objdefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Objdef_t* odef = VectorObjdef_element(objdefs,i);
      if (!is_false_condition(odef->condition)) {
        if (!is_true_condition(odef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,odef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  { ");
        print_C_string(stream,odef->initstring);
        fprintf(stream," },");
        print_nl(stream);
        if (!is_true_condition(odef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  {
    unsigned long n = VectorVardef_length(vardefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Vardef_t* vdef = VectorVardef_element(vardefs,i);
      if (!is_false_condition(vdef->condition)) {
        if (!is_true_condition(vdef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,vdef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  { ");
        print_C_string(stream,"NIL");
        fprintf(stream," },");
        print_nl(stream);
        if (!is_true_condition(vdef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  fprintf(stream,"  0");
  print_nl(stream);
  fprintf(stream,"};");
  print_nl(stream);
  print_nl(stream);
}

/* Output the tables at the end of the file. */
static void output_tables2 (FILE* stream)
{
  const char* modname = name_defmodule;
  const char* subr_tab = concat3("module__",modname,"__subr_tab");
  const char* subr_tab_initdata =
    concat3("module__",modname,"__subr_tab_initdata");
  print_nl(stream);
  fprintf(stream,"struct {");
  print_nl(stream);
  {
    unsigned long n = VectorFundef_length(fundefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Fundef_t* fdef = VectorFundef_element(fundefs,i);
      if (!is_false_condition(fdef->condition)) {
        if (!is_true_condition(fdef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,fdef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  subr_t _%s;",fdef->tag);
        print_nl(stream);
        if (!is_true_condition(fdef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  fprintf(stream,"  int _dummy_to_avoid_trailing_comma_in_initializer;");
  print_nl(stream);
  fprintf(stream,"} %s = {",subr_tab);
  print_nl(stream);
  {
    unsigned long n = VectorFundef_length(fundefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Fundef_t* fdef = VectorFundef_element(fundefs,i);
      VectorSignature_t* signatures = fdef->signatures;
      unsigned long m = VectorSignature_length(signatures);
      unsigned long j;
      for (j = 0; j < m; j++) {
        Signature_t* sig = VectorSignature_element(signatures,j);
        if (!is_false_condition(sig->condition)) {
          if (!is_true_condition(sig->condition)) {
            fprintf(stream,"#if ");
            print_condition(stream,sig->condition);
            print_nl(stream);
          }
          fprintf(stream,"  LISPFUN_F%s",get_signature_for_LISPFUN(fdef,sig));
          print_nl(stream);
          if (!is_true_condition(sig->condition)) {
            fprintf(stream,"#endif");
            print_nl(stream);
          }
        }
      }
    }
  }
  fprintf(stream,"  0");
  print_nl(stream);
  fprintf(stream,"};");
  print_nl(stream);
  fprintf(stream,"uintC module__%s__subr_tab_size = ((char*)&%s._dummy_to_avoid_trailing_comma_in_initializer-(char*)&%s)/sizeof(subr_t);",modname,subr_tab,subr_tab);
  print_nl(stream);
  print_nl(stream);
  fprintf(stream,"struct {");
  print_nl(stream);
  {
    unsigned long n = VectorFundef_length(fundefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Fundef_t* fdef = VectorFundef_element(fundefs,i);
      if (!is_false_condition(fdef->condition)) {
        if (!is_true_condition(fdef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,fdef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  subr_initdata_t _%s;",fdef->tag);
        print_nl(stream);
        if (!is_true_condition(fdef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  fprintf(stream,"  int _dummy_to_avoid_trailing_comma_in_initializer;");
  print_nl(stream);
  fprintf(stream,"} %s = {",subr_tab_initdata);
  print_nl(stream);
  {
    unsigned long n = VectorFundef_length(fundefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Fundef_t* fdef = VectorFundef_element(fundefs,i);
      if (!is_false_condition(fdef->condition)) {
        if (!is_true_condition(fdef->condition)) {
          fprintf(stream,"#if ");
          print_condition(stream,fdef->condition);
          print_nl(stream);
        }
        fprintf(stream,"  { ");
        print_C_string(stream,fdef->packname);
        fprintf(stream,", ");
        print_C_string(stream,fdef->printname);
        fprintf(stream," },");
        print_nl(stream);
        if (!is_true_condition(fdef->condition)) {
          fprintf(stream,"#endif");
          print_nl(stream);
        }
      }
    }
  }
  fprintf(stream,"  0");
  print_nl(stream);
  fprintf(stream,"};");
  print_nl(stream);
  print_nl(stream);
  fprintf(stream,"void module__%s__init_function_1 (module_t* module)",modname);
  print_nl(stream);
  fprintf(stream,"{");
  print_nl(stream);
  {
    unsigned long n = VectorFundef_length(fundefs);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Fundef_t* fdef = VectorFundef_element(fundefs,i);
      VectorSignature_t* signatures = fdef->signatures;
      unsigned long m = VectorSignature_length(signatures);
      unsigned long j;
      for (j = 0; j < m; j++) {
        Signature_t* sig = VectorSignature_element(signatures,j);
        if (sig->key) {
          if (!is_false_condition(sig->condition)) {
            if (!is_true_condition(sig->condition)) {
              fprintf(stream,"#if ");
              print_condition(stream,sig->condition);
              print_nl(stream);
            }
            {
              unsigned long o = VectorObjdef_length(sig->keywords);
              unsigned long k;
              for (k = 0; k < o; k++) {
                fprintf(stream,"  pushSTACK(%s);",VectorObjdef_element(sig->keywords,k)->tag);
                print_nl(stream);
              }
              fprintf(stream,"  %s._%s.keywords = vectorof(%lu);",subr_tab,fdef->tag,o);
              print_nl(stream);
            }
            if (!is_true_condition(sig->condition)) {
              fprintf(stream,"#endif");
              print_nl(stream);
            }
          }
        }
      }
    }
  }
  {
    unsigned long n = VectorVarinit_length(varinits);
    unsigned long i;
    for (i = 0; i < n; i++) {
      Varinit_t* vinit = VectorVarinit_element(varinits,i);
      if (!is_true_condition_part(vinit->condition)) {
        fprintf(stream,"#if ");
        print_condition_part(stream,vinit->condition);
        print_nl(stream);
      }
      fprintf(stream,"  O(%s) = (%s);",vinit->tag,vinit->initform);
      print_nl(stream);
      if (!is_true_condition_part(vinit->condition)) {
        fprintf(stream,"#endif");
        print_nl(stream);
      }
    }
  }
  fprintf(stream,"}");
  print_nl(stream);
  print_nl(stream);
  fprintf(stream,"void module__%s__init_function_2 (module_t* module)",modname);
  print_nl(stream);
  fprintf(stream,"{");
  print_nl(stream);
  fprintf(stream,"}");
  print_nl(stream);
}

/* Output everything. */
static void output (FILE* stream, const char* infilename)
{
  if (infilename != NULL)
    fprintf(stdout,"#line 1 \"%s\"\n",infilename);
  lineno = 1;
  {
    unsigned long m = VectorLine_length(lines);
    unsigned long j;
    for (j = 0; j < m; j++) {
      const Line_t* line = VectorLine_element(lines,j);
      if (line->number != lineno) {
        fprintf(stream,"#line %ld\n",line->number);
        lineno = line->number;
      }
      fprintf(stream,"%s",line->contents);
      print_nl(stream);
      if (j == line_defmodule)
        output_tables1(stream);
    }
  }
  output_tables2(stream);
}


/* ============================ MAIN PROGRAM ============================== */

int main (int argc, char* argv[])
{
  char* infilename;
  FILE* infile;
  FILE* outfile;
  /* Argument parsing. */
  if (argc == 2) {
    infilename = argv[1];
    infile = fopen(infilename,"r");
    if (infile == NULL) {
      fprintf(stderr,"%s: cannot open `%s'\n",argv[0],argv[1]);
      exit(1);
    }
    file = infilename;
  } else if (argc == 1) {
    infilename = NULL;
    infile = stdin;
  } else {
    fprintf(stderr,"usage: %s [input] > output\n",argv[0]);
    exit(1);
  }
  outfile = stdout;
  /* Main job. */
  read_all_input(infile);
  parse();
  output(stdout,infilename);
  /* Clean up. */
  if (ferror(infile) || ferror(outfile)) {
    fclose(infile);
    fclose(outfile);
    fprintf(stderr,"%s: i/o error\n",argv[0]);
    exit(1);
  }
  fclose(infile);
  fclose(outfile);
  exit(0);
}
