/* Debugging utilities. */

/* Output a memory range in hexadecimal notation */
local const char hex_table[] = "0123456789ABCDEF";
local void mem_hex_out (const void* buf, uintL count) {
  if (count > 0) {
    var DYNAMIC_ARRAY(cbuf,char,3*count+1);
    var const uintB* ptr1 = (const uintB*) buf;
    var char* ptr2 = &cbuf[0];
    dotimespL(count,count, {
      *ptr2++ = ' ';
      *ptr2++ = hex_table[floor(*ptr1,16)]; *ptr2++ = hex_table[*ptr1 % 16];
      ptr1++;
    });
    *ptr2 = '\0';
    fputs(cbuf,stdout);
    FREE_DYNAMIC_ARRAY(cbuf);
  }
}

/* Output a lisp object in lisp notation to standard output.
 can trigger GC */
global object object_out (object obj) {
  pushSTACK(obj);
  pushSTACK(var_stream(S(terminal_io),strmflags_wr_ch_B)); # *TERMINAL-IO*
  prin1(&STACK_0,STACK_1); # output the object
  terpri(&STACK_0); # output a newline
  skipSTACK(1);
  return popSTACK(); # return the same object
}

#ifdef UNICODE
/* see string_to_asciz() */
local void string_out (FILE* out, object str, object encoding) {
  var uintL len;
  var uintL offset;
  var object string = unpack_string_ro(str,&len,&offset);
  var const chart* srcptr;
  unpack_sstring_alloca(string,len,offset, srcptr=);
  var uintL bytelen = cslen(encoding,srcptr,len);
  var DYNAMIC_ARRAY(buffer,uintB,bytelen+1);
  cstombs(encoding,srcptr,len,buffer,bytelen);
  buffer[bytelen] = 0;
  fputs((const char*)buffer,out);
  FREE_DYNAMIC_ARRAY(buffer);
}
#else /* no UNICODE */
  /* not implemented */
#endif

/* non-consing, STACK non-modifying */
global object nobject_out (FILE* out, object obj) {
  if (out == NULL) out = stdout;
  if (stringp(obj)) {
    fputc('"',out);
    string_out(out,obj,O(terminal_encoding));
    fputc('\"',out);
  } else if (charp(obj)) {
    var object name = char_name(char_code(obj));
    fprintf(out,"[%c]",as_cint(char_code(obj)));
    if (!nullp(name)) {
      fputs("=#\\",out);
      string_out(out,name,O(terminal_encoding));
    }
  } else if (symbolp(obj)) {
    var object pack = Symbol_package(obj);
    if (nullp(pack)) fputs("#:",out); /* uninterned symbol */
    else if (eq(pack,O(keyword_package))) fputc(':',out);
    else {
      string_out(out,ThePackage(pack)->pack_name,O(terminal_encoding));
      fputs("::",out);
    }
    string_out(out,Symbol_name(obj),O(terminal_encoding));
  } else if (simple_vector_p(obj)) {
    var uintL len = vector_length(obj);
    var uintL idx = 0;
    fputs("#(",out);
    while (idx < len) {
      if (idx) fputc(' ',out);
      nobject_out(out,TheSvector(obj)->data[idx++]);
    }
    fputc(')',out);
  } else if (consp(obj)) {
    fputc('(',out);
    loop {
      nobject_out(out,Car(obj));
      obj = Cdr(obj);
      if (atomp(obj)) break;
      fputc(' ',out);
    }
    if (!nullp(obj)) {
      fputs(" . ",out);
      nobject_out(out,obj);
    }
    fputc(')',out);
  } else if (functionp(obj)) {
    fputs("#<",out);
    if (subrp(obj)) {
      string_out(out,
                 ((as_oint(subr_tab_ptr_as_object(&subr_tab)) <=
                   as_oint(obj))
                  && (as_oint(obj) <
                      as_oint(subr_tab_ptr_as_object(&subr_tab+1))))
                 ? O(printstring_subr) : O(printstring_addon_subr),
                 O(terminal_encoding));
      obj = TheSubr(obj)->name;
    } else if (cclosurep(obj)) {
      string_out(out,
                 genericfunctionp(obj)
                 ? O(printstring_generic_function)
                 : O(printstring_compiled_closure),
                 O(terminal_encoding));
      obj = TheClosure(obj)->clos_name;
    }
    #ifdef DYNAMIC_FFI
      else if (ffunctionp(obj)) {
      string_out(out,O(printstring_ffunction),O(terminal_encoding));
      obj = TheFfunction(obj)->ff_name;
    }
    #endif
      else { /* interpreted closure */
      string_out(out,O(printstring_closure),O(terminal_encoding));
      obj = TheIclosure(obj)->clos_name;
    }
    fputc(' ',out);
    nobject_out(out,obj);
    fputc('>',out);
  } else if (fsubrp(obj)) {
    fputs("#<",out);
    string_out(out,O(printstring_fsubr),O(terminal_encoding));
    fputc(' ',out);
    nobject_out(out,TheFsubr(obj)->name);
    fputc('>',out);
  } else if (pathnamep(obj)) {
    fputs("#(",out); nobject_out(out,S(pathname));
   #define SLOT(s) fputc(' ',out); nobject_out(out,S(K##s)); fputc(' ',out); \
     nobject_out(out,ThePathname(obj)->pathname_##s)
   #if HAS_HOST
    SLOT(host);
   #endif
   #if HAS_DEVICE
    SLOT(device);
   #endif
    SLOT(directory); SLOT(name); SLOT(type);
   #if HAS_VERSION
    SLOT(version);
   #endif
   #undef SLOT
    fputs(")",out);
  } else if (logpathnamep(obj)) {
   #ifdef LOGICAL_PATHNAMES
    fputs("#(",out); nobject_out(out,S(logical_pathname));
   #define SLOT(s) fputc(' ',out); nobject_out(out,S(K##s)); fputc(' ',out); \
     nobject_out(out,TheLogpathname(obj)->pathname_##s)
    SLOT(host); SLOT(directory); SLOT(name); SLOT(type); SLOT(version);
    fputs(")",out);
   #endif
  } else if (fixnump(obj)) fprintf(out,"%d",fixnum_to_L(obj));
  else if (eq(obj,unbound))   fputs("#<UNBOUND>",out);
  else if (eq(obj,nullobj))   fputs("#<NULLOBJ>",out);
  else if (eq(obj,disabled))  fputs("#<DISABLED>",out);
  else if (eq(obj,specdecl))  fputs("#<SPECDECL>",out);
  else if (eq(obj,eof_value)) fputs("#<EOF>",out);
  else if (eq(obj,dot_value)) fputs("#<DOT>",out);
  else if (as_oint(obj) & wbit(frame_bit_o)) {
    fputs("#<frame ",out);
    switch (framecode(obj)) {
      case DYNBIND_frame_info: fputs("DYNBIND",out); break;
      case ENV1V_frame_info: fputs("ENV1V",out); break;
      case ENV1F_frame_info: fputs("ENV1F",out); break;
      case ENV1B_frame_info: fputs("ENV1B",out); break;
      case ENV1G_frame_info: fputs("ENV1G",out); break;
      case ENV1D_frame_info: fputs("ENV1D",out); break;
      case ENV2VD_frame_info: fputs("ENV2VD",out); break;
      case ENV5_frame_info: fputs("ENV5",out); break;
     #ifdef HAVE_SAVED_REGISTERS
      case CALLBACK_frame_info: fputs("CALLBACK",out); break;
     #endif
      case VAR_frame_info: fputs("VAR",out); break;
      case FUN_frame_info: fputs("FUN",out); break;
      case IBLOCK_frame_info: fputs("IBLOCK",out); break;
      case NESTED_IBLOCK_frame_info: fputs("NESTED_IBLOCK",out); break;
      case ITAGBODY_frame_info: fputs("ITAGBODY",out); break;
      case NESTED_ITAGBODY_frame_info: fputs("NESTED_ITAGBODY",out); break;
      case CBLOCK_CTAGBODY_frame_info: fputs("CBLOCK_CTAGBODY",out); break;
      case APPLY_frame_info: fputs("APPLY",out); break;
      case TRAPPED_APPLY_frame_info: fputs("TRAPPED_APPLY",out); break;
      case EVAL_frame_info: fputs("EVAL",out); break;
      case TRAPPED_EVAL_frame_info: fputs("TRAPPED_EVAL",out); break;
      case CATCH_frame_info: fputs("CATCH",out); break;
      case HANDLER_frame_info: fputs("HANDLER",out); break;
      case UNWIND_PROTECT_frame_info: fputs("UNWIND_PROTECT",out); break;
      case DRIVER_frame_info: fputs("DRIVER",out); break;
      default: fputs("**UNKNOWN**",out);
    }
    fprintf(out," 0x%X>",as_oint(obj));
  } else if (varobjectp(obj))
    fprintf(out,"#<varobject type=%d address=0x%X>",
            varobject_type(TheVarobject(obj)),ThePointer(obj));
  else fprintf(out,"#<huh?! address=0x%X>",ThePointer(obj));
  fflush(out);
  return obj;
}

/* use (struct backtrace_t*) and not p_backtrace_t
   so that this is useable from the p_backtrace_t C++ definition */
local int back_trace_depth (const struct backtrace_t *bt) {
  var uintL index = 0;
  for (bt = (bt ? bt : back_trace); bt; bt=bt->bt_next, index++)
    if (bt == bt->bt_next) return -index;
  return index;
}

local uintL back_trace_out (FILE* out, const struct backtrace_t *bt) {
  var uintL index = 0;
  if (out == NULL) out = stdout;
  if (!bt) bt = back_trace;
  for (; bt; bt=bt->bt_next, index++) {
    fprintf(out,"[%d/0x%X]%s ",index,bt,bt_beyond_stack_p(bt,STACK)?"<":">");
    nobject_out(out,bt->bt_caller);
    if (bt->bt_num_arg >= 0)
      fprintf(out," %d args",bt->bt_num_arg);
    if (bt->bt_next)
      fprintf(out," delta: STACK=%d; SP=%d",
              STACK_item_count(bt->bt_stack,bt->bt_next->bt_stack),
              /* SP and STACK go in the opposite directions: */
              STACK_item_count(bt->bt_next,bt));
    fputc('\n',out);
    if (bt == bt->bt_next) {
      fprintf(out,"*** error: circularity detected!\n");
      break;
    }
  }
  return index;
}

global void back_trace_check (const struct backtrace_t *bt,
                              char* label,char* file,int line) {
  if (bt && back_trace_depth(bt)<0) {
    fprintf(stderr,"\n%s:%d:%s: circularity!\n",file,line,label);
    back_trace_out(stderr,bt);
    abort();
  }
}

#ifdef DEBUG_SPVW
#define FUN(from,to,name) local to CONCAT(name,_) (from x) { return name(x); }
FUN(chart,cint,as_cint);
FUN(cint,chart,as_chart);
FUN(object,chart,char_code);
FUN(chart,object,code_char);
FUN(object,cint,char_int);
FUN(cint,object,int_char);
FUN(object,oint,as_oint);
FUN(oint,object,as_object);
#undef FUN
#endif
