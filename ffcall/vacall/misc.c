/*
 * Copyright 1995-1997 Bruno Haible, <haible@clisp.cons.org>
 *
 * This is free software distributed under the GNU General Public Licence
 * described in the file COPYING. Contact the author if you don't have this
 * or can't live with it. There is ABSOLUTELY NO WARRANTY, explicit or implied,
 * on this software.
 */

#include <stdio.h>

#ifndef REENTRANT
#include "vacall.h"
#else /* REENTRANT */
#include "vacall_r.h"
#endif
#include "config.h"

#ifndef REENTRANT
/* This is the function called by vacall(). */
#if defined(__STDC__) || defined(__GNUC__)
void (* vacall_function) (va_alist);
#else
void (* vacall_function) ();
#endif
#endif

/* Room for returning structs according to the pcc non-reentrant struct return convention. */
__va_struct_buffer_t __va_struct_buffer;

extern ABORT_VOLATILE RETABORTTYPE abort ();

int /* no return type, since this never returns */
__va_error1 (start_type, return_type)
  enum __VAtype start_type;
  enum __VAtype return_type;
{
  /* If you see this, fix your code. */
  fprintf (stderr, "vacall: va_start type %d and va_return type %d disagree.\n",
                   (int)start_type, (int)return_type);
  abort();
}

int /* no return type, since this never returns */
__va_error2 (size)
  unsigned int size;
{
  /* If you see this, increase __VA_ALIST_WORDS: */
  fprintf (stderr, "vacall: struct of size %u too large for pcc struct return.\n",
                   size);
  abort();
}
