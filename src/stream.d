# Streams for CLISP
# Bruno Haible 1990-2002
# Sam Steingold 1998-2002
# Generic Streams: Marcus Daniels 8.4.1994
# SCREEN package for Win32: Arseny Slobodjuck 2001-02-14
# German comments translated into English: Stefan Kain 2001-11-02

#include "lispbibl.c"
#include "arilev0.c" # for R_sign

#ifdef GNU_READLINE
  /* older readline versions appear to need <stdio.h> for FILE* */
  #include <stdio.h>
  #include <readline/readline.h>
  #include <readline/history.h>
#endif
#ifdef STDC_HEADERS
  #include <string.h>  # declares strcpy(), strcat()
#endif

# once again the structure of Streams:
# strmflags = Flags
  # Bits in the Flags:
  # define strmflags_open_bit_B  0  # set, if the Stream is open
  # define strmflags_immut_bit_B 1  # set if read literals are immutable
  # define strmflags_reval_bit_B 2  # set if Read-Eval is allowed
  #define strmflags_unread_bit_B 3  # set while strm_rd_ch_last is back
  # define strmflags_rd_by_bit_B 4  # set if READ-BYTE is possible
  # define strmflags_wr_by_bit_B 5  # set if WRITE-BYTE is possible
  # define strmflags_rd_ch_bit_B 6  # set if READ-CHAR is possible
  # define strmflags_wr_ch_bit_B 7  # set if WRITE-CHAR is possible
  # Bitmasks in the Flags:
  # define strmflags_open_B  bit(strmflags_open_bit_B)
  #define strmflags_immut_B  bit(strmflags_immut_bit_B)
  #define strmflags_reval_B  bit(strmflags_reval_bit_B)
  #define strmflags_unread_B bit(strmflags_unread_bit_B)
  # define strmflags_rd_by_B bit(strmflags_rd_by_bit_B)
  # define strmflags_wr_by_B bit(strmflags_wr_by_bit_B)
  # define strmflags_rd_ch_B bit(strmflags_rd_ch_bit_B)
  # define strmflags_wr_ch_B bit(strmflags_wr_ch_bit_B)
  # define strmflags_rd_B  (strmflags_rd_by_B | strmflags_rd_ch_B)
  # define strmflags_wr_B  (strmflags_wr_by_B | strmflags_wr_ch_B)
  #define strmflags_by_B  (strmflags_rd_by_B | strmflags_wr_by_B)
  #define strmflags_ch_B  (strmflags_rd_ch_B | strmflags_wr_ch_B)
  #define strmflags_rdwr_B (strmflags_rd_B | strmflags_wr_B)
# strmtype = further Typinfo. See LISPBIBL.D.

# individual fields:
  # strm_rd_by         pseudofunction for READ-BYTE
  # strm_rd_by_array   pseudofunction for READ-BYTE-SEQUENCE
  # strm_wr_by         pseudofunction for WRITE-BYTE
  # strm_wr_by_array   pseudofunction for WRITE-BYTE-SEQUENCE
  # strm_rd_ch         pseudofunction for READ-CHAR
  # strm_pk_ch         pseudofunction for PEEK-CHAR
  # strm_rd_ch_array   pseudofunction for READ-CHAR-SEQUENCE
  # strm_rd_ch_last    last character read by READ-CHAR, NIL if none has been
  #                    read upto now, eof_value after EOF has been seen.
  #                    After UNREAD-CHAR, additionally the bit
  #                    strmflags_unread_bit_B is set.
  # strm_wr_ch         pseudofunction for WRITE-CHAR
  # strm_wr_ch_array   pseudofunction for WRITE-CHAR-SEQUENCE
  # strm_wr_ch_lpos    line-position in the current line after last WRITE-CHAR,
  #                    a fixnum >=0
# further (type-specific) components:
  # See in LISPBIBL.D and at the Stream-Types.


# =============================================================================
#                           S T R E A M S

# Since MAKE-TWO-WAY-STREAM possibly can return a Stream that is, e.g.,
# Character-Input and Byte-Output, and therewith in particular all
# READ-/WRITE-Operations must run efficiently, Streams are built up
# as follows:
#    - Type of the Stream,
#    - Components for READ-BYTE, READ-BYTE-SEQUENCE,
#    - Components for WRITE-BYTE, WRITE-BYTE-SEQUENCE,
#    - Components for READ-CHAR, READ-CHAR-SEQUENCE,
#    - Components for WRITE-CHAR, WRITE-CHAR-SEQUENCE,
#    - Components, depending on the Type of the Stream.

# Specification of the nine Types of Pseudo-Functions:

  # Specification for READ-BYTE - Pseudo-Function:
  # fun(stream)
  # > stream: Stream
  # < result: read Integer (eof_value at EOF)
  # can trigger GC
    typedef object (* rd_by_Pseudofun) (object stream);

  # Specification for READ-BYTE-ARRAY - Pseudo-Function:
  # fun(&stream,&bytearray,start,len)
  # > stream: stream
  # > object bytearray: simple-bit-vector
  # > uintL start: start index of byte sequence to be filled
  # > uintL len: length of byte sequence to be filled, >0
  # < uintL result: number of bytes that have been filled
  # can trigger GC
    typedef uintL (* rd_by_array_Pseudofun) (const object* stream_, const object* bytearray_, uintL start, uintL len);

  # Specification for WRITE-BYTE - Pseudo-Function:
  # fun(stream,obj)
  # > stream: Stream
  # > obj: Integer to be written
  # can trigger GC
    typedef void (* wr_by_Pseudofun) (object stream, object obj);

  # Specification for WRITE-BYTE-ARRAY - Pseudo-Function:
  # fun(&stream,&bytearray,start,len)
  # > stream: stream
  # > object bytearray: simple-bit-vector
  # > uintL start: start index of byte sequence to be written
  # > uintL len: length of byte sequence to be written, >0
  # can trigger GC
    typedef void (* wr_by_array_Pseudofun) (const object* stream_, const object* bytearray_, uintL start, uintL len);

  # Specification for READ-CHAR - Pseudo-Function:
  # fun(&stream)
  # > stream: Stream
  # < stream: Stream
  # < result: read Character (eof_value at EOF)
  # can trigger GC
    typedef object (* rd_ch_Pseudofun) (const object* stream_);

  # Specification for PEEK-CHAR - Pseudo-Function:
  # fun(&stream)
  # Like READ-CHAR with sequencing UNREAD-CHAR. Only side-effects up
  # to the next real READ-CHAR are retarded (if possible).
  # > stream: Stream (with strmflags_unread_bit_B deleted)
  # < stream: Stream
  # < result: read Character (eof_value at EOF)
  # can trigger GC
    typedef object (* pk_ch_Pseudofun) (const object* stream_);

  # Specification for READ-CHAR-ARRAY - Pseudo-Function:
  # fun(&stream,&chararray,start,len)
  # > stream: stream
  # > object chararray: a mutable string that is or was simple
  # > uintL start: start index of character sequence to be filled
  # > uintL len: length of character sequence to be filled, >0
  # < uintL result: number of characters that have been filled
  # can trigger GC
    typedef uintL (* rd_ch_array_Pseudofun) (const object* stream_, const object* chararray_, uintL start, uintL len);

  # Specification for WRITE-CHAR - Pseudo-Function:
  # fun(&stream,obj)
  # > stream: Stream
  # < stream: Stream
  # > obj: Character to be written
  # can trigger GC
    typedef void (* wr_ch_Pseudofun) (const object* stream_, object obj);

  # Specification for WRITE-CHAR-ARRAY - Pseudo-Function:
  # fun(&stream,&chararray,start,len)
  # > stream: stream
  # > object chararray: simple-string
  # > uintL start: start index of character sequence to be written
  # > uintL len: length of character sequence to be written, >0
    typedef void (* wr_ch_array_Pseudofun) (const object* stream_, const object* chararray_, uintL start, uintL len);

# extract Pseudo-Functions out of a Stream:
#define rd_by(strm)       \
        (*(rd_by_Pseudofun)(ThePseudofun(TheStream(strm)->strm_rd_by)))
#define rd_by_array(strm) \
  (*(rd_by_array_Pseudofun)(ThePseudofun(TheStream(strm)->strm_rd_by_array)))
#define wr_by(strm)       \
        (*(wr_by_Pseudofun)(ThePseudofun(TheStream(strm)->strm_wr_by)))
#define wr_by_array(strm) \
  (*(wr_by_array_Pseudofun)(ThePseudofun(TheStream(strm)->strm_wr_by_array)))
#define rd_ch(strm)       \
        (*(rd_ch_Pseudofun)(ThePseudofun(TheStream(strm)->strm_rd_ch)))
#define pk_ch(strm)       \
        (*(pk_ch_Pseudofun)(ThePseudofun(TheStream(strm)->strm_pk_ch)))
#define rd_ch_array(strm) \
  (*(rd_ch_array_Pseudofun)(ThePseudofun(TheStream(strm)->strm_rd_ch_array)))
#define wr_ch(strm)       \
        (*(wr_ch_Pseudofun)(ThePseudofun(TheStream(strm)->strm_wr_ch)))
#define wr_ch_array(strm) \
  (*(wr_ch_array_Pseudofun)(ThePseudofun(TheStream(strm)->strm_wr_ch_array)))

#  Possible Types of Streams               Additional Components
#  -------------------------               ---------------------

#  Synonym-Stream                          Symbol
#  Broadcast-(Output-)Stream               list of streams
#  Concatenated-(Input-)Stream             list of streams
#  Two-Way-Stream                          Stream for Input, Stream for Output
#  Echo-Stream                             Stream for Input, Stream for Output
#  String-Input-Stream                     total string, character counter
#  String-Output-Stream                    Buffer (Semi-Simple-String)
#  String-Push-Stream                      String with Fill-Pointer
#  Pretty-Printer-Helper-Stream            List of Buffers, Mode
#  Buffered-Input-Stream                   fun, mode, String, character counter
#  Buffered-Output-Stream                  fun, Buffer (Semi-Simple-String)
#ifdef GENERIC_STREAMS
#  Generic-Stream                          Private Controller Object
#endif
#
#  Keyboard-Stream
#  Interactive Terminal Stream             input-buffer, character counter
#  File-Stream                             Handle, Pathname, File-Position,
#  (Input, Output, I/O, Closed=Probe)      Buffer, [Bit-Buffer]
#  Window-Stream                           ---
#ifdef PRINTER
#  Printer-Stream
#endif
#  File-Handle-Stream                      Handle, Pathname
#ifdef PIPES
#  Pipe-Input-Stream                       Pid, Handle
#  Pipe-Output-Stream                      Pid, Handle
#endif
#ifdef X11SOCKETS
#  X11-Socket-Stream                       Info, Handle
#endif
#ifdef SOCKET_STREAMS
#  Socket-Stream                           Host, Port
#endif

# Additionally a list of all open File-Streams is maintained (for safety).

# error-message, if a Stream-Operation on a Stream is not allowed.
# fehler_illegal_streamop(caller,stream);
# > caller: Caller (a Symbol)
# > stream: Stream
nonreturning_function(global, fehler_illegal_streamop, (object caller, object stream)) {
  pushSTACK(stream); # STREAM-ERROR slot STREAM
  pushSTACK(stream);
  pushSTACK(caller);
  fehler(stream_error,GETTEXT("~ on ~ is illegal"));
}

# Dummy-Pseudo-Functions, that signal errors:
local object rd_by_error (object stream) {
  fehler_illegal_streamop(S(read_byte),stream);
}

local uintL rd_by_array_error (const object* stream_, const object* bytearray_,
                               uintL start, uintL len) {
  fehler_illegal_streamop(S(read_byte),*stream_);
}

local uintL rd_by_array_dummy (const object* stream_, const object* bytearray_,
                               uintL start, uintL len) {
  var uintL end = start + len;
  var uintL index = start;
  do {
    var object stream = *stream_;
    var object obj = rd_by(stream)(stream);
    if (eq(obj,eof_value))
      break;
    if (!uint8_p(obj))
      fehler_uint8(obj);
    TheSbvector(*bytearray_)->data[index] =
      (uintB)(as_oint(obj) >> oint_data_shift);
    index++;
  } while (index < end);
  return index - start;
}

local void wr_by_error (object stream, object obj) {
  fehler_illegal_streamop(S(write_byte),stream);
}

local void wr_by_array_error (const object* stream_, const object* bytearray_,
                              uintL start, uintL len) {
  fehler_illegal_streamop(S(write_byte),*stream_);
}

local void wr_by_array_dummy (const object* stream_, const object* bytearray_,
                              uintL start, uintL len) {
  var uintL end = start + len;
  var uintL index = start;
  do {
    var object stream = *stream_;
    wr_by(stream)(stream,fixnum(TheSbvector(*bytearray_)->data[index]));
    index++;
  } while (index < end);
}

local object rd_ch_error (const object* stream_) {
  fehler_illegal_streamop(S(read_char),*stream_);
}

local object pk_ch_dummy (const object* stream_) {
  var object newch = rd_ch(*stream_)(stream_);
  TheStream(*stream_)->strm_rd_ch_last = newch;
  if (!eq(newch,eof_value))
    TheStream(*stream_)->strmflags |= strmflags_unread_B;
  return newch;
}

local uintL rd_ch_array_error (const object* stream_, const object* chararray_,
                               uintL start, uintL len) {
  fehler_illegal_streamop(S(read_char),*stream_);
}

local uintL rd_ch_array_dummy (const object* stream_, const object* chararray_,
                               uintL start, uintL len) {
  var uintL end = start + len;
  var uintL index = start;
  do {
    var object obj = rd_ch(*stream_)(stream_);
    if (eq(obj,eof_value))
      break;
    if (!charp(obj))
      fehler_char(obj);
    sstring_store(*chararray_,index,char_code(obj));
    index++;
  } while (index < end);
  return index - start;
}

local void wr_ch_error (const object* stream_, object obj) {
  fehler_illegal_streamop(S(write_char),*stream_);
}

local void wr_ch_array_error (const object* stream_, const object* chararray_,
                              uintL start, uintL len) {
  fehler_illegal_streamop(S(write_char),*stream_);
}

local void wr_ch_array_dummy (const object* stream_, const object* chararray_,
                              uintL start, uintL len) {
  var uintL end = start + len;
  var uintL index = start;
  SstringDispatch(*chararray_,X, {
    do {
      write_char(stream_,code_char(as_chart(((SstringX)TheVarobject(*chararray_))->data[index])));
      index++;
    } while (index < end);
  });
}

# check whether the stream is a terminal stream
global bool terminal_stream_p (object stream) {
  if (!streamp(stream)) return false;
  if (eq(stream,Symbol_value(S(terminal_read_stream)))) return true;
  if (TheStream(stream)->strmtype == strmtype_terminal) return true;
  if (TheStream(stream)->strmtype == strmtype_synonym)
    return terminal_stream_p(Symbol_value # get_synonym_stream
                             (TheStream(stream)->strm_synonym_symbol));
  # if (TheStream(stream)->strmtype == strmtype_concat) {
  #  # this is a gross hack for the CLISP kludge
  #  # of reading the first line with READ-LINE for *KEY-BINDINGS*
  #  # and then concatenating the line with the terminal stream
  #  object list = TheStream(stream)->strm_concat_list;
  #  while (consp(list)) {
  #    if (terminal_stream_p(Car(list)))
  #      return true;
  #    list = Cdr(list);
  #  }
  #  return false;
  return false;
}

# At the end of a wr_ch_array, update the Line-Position:
# wr_ss_lpos(stream,ptr,len);
# > stream: Builtin-Stream, not the Terminal-Stream
# > ptr: Pointer to the End(!) of the already written characters to the Stream
# > len: number of characters, >0
# < result: true, if a NL is among the characters, else false
local bool wr_ss_lpos (object stream, const chart* ptr, uintL len) {
 #ifdef TERMINAL_USES_KEYBOARD
  if (TheStream(stream)->strmtype == strmtype_terminal)
    return false; # On the Atari wr_ch_terminal() would do this.
 #endif
  # Add together the widths of the characters since the last NL:
  var bool result;
  var uintL pos = 0;
  var uintL count;
  dotimespL(count,len, {
    if (chareq(*--ptr,ascii(NL)))
      goto found_NL;
    pos++;
  });
  if (false) {
  found_NL: # pos characters since the last NL
    ptr++; len = pos; pos = 0; result = true;
  } else { # pos==len
    pos = posfixnum_to_L(TheStream(stream)->strm_wr_ch_lpos); result = false;
  }
  # There were len characters starting from ptr, pos is the Position there.
 #ifdef TERMINAL_USES_KEYBOARD
  pos += len;
 #else
  if (len > 0) {
    if (TheStream(stream)->strmtype == strmtype_terminal) {
      dotimespL(count,len, {
        var chart c = *ptr++;
        # How do the control characters effect at that Position?
        if (chareq(c,ascii(BS))) {
          # Backspace ==> decrement Line Position, if possible:
          if (pos > 0)
            pos--;
        } else
          pos += char_width(c);
      });
    } else {
      dotimespL(count,len, {
        var chart c = *ptr++;
        pos += char_width(c);
      });
    }
  }
 #endif
  TheStream(stream)->strm_wr_ch_lpos = fixnum(pos);
  return result;
}

# Reads a Byte from a Stream.
# read_byte(stream)
# > stream: Stream
# < result: read Integer (eof_value at EOF)
# can trigger GC
global object read_byte (object stream) {
  if (builtin_stream_p(stream)) {
    if (TheStream(stream)->strmflags & strmflags_unread_B) {
      # UNREAD-CHAR was followed by a (SETF STREAM-ELEMENT-TYPE)
      # thus we _know_ that the stream element type is ([UN]SIGNED-BYTE 8)
     #ifdef UNICODE
      var object enc = TheStream(stream)->strm_encoding;
      var chart ch = char_code(TheStream(stream)->strm_rd_ch_last);
      var uint8 buf[4]; # are there characters longer than 4 bytes?!
      var uint8 char_len = cslen(enc,&ch,1);
      cstombs(enc,&ch,1,buf,char_len);
      var uint8 code = buf[0];
      if (char_len == 1) { # the char was just one byte
        TheStream(stream)->strmflags &= ~strmflags_unread_B;
        TheStream(stream)->strm_rd_ch_last = NIL;
      } else { # encode the rest
        var const uint8* cbuf = buf+1; # skip the first byte
        var chart* cptr = &ch;
        Encoding_mbstowcs(enc)(enc,stream,&cbuf,buf+char_len,&cptr,cptr+1);
        TheStream(stream)->strm_rd_ch_last = code_char(*cptr);
      }
     #else # no UNICODE
      var uint8 code = as_cint(char_code(TheStream(stream)->strm_rd_ch_last));
      TheStream(stream)->strmflags &= ~strmflags_unread_B;
      TheStream(stream)->strm_rd_ch_last = NIL;
     #endif
      var object eltype = TheStream(stream)->strm_eltype;
      if (eq(eltype,S(signed_byte))
          || (mconsp(eltype) && eq(Car(eltype),S(signed_byte))))
        return sfixnum((sint8)code);
      else
        return fixnum((uint8)code);
    } else
      return rd_by(stream)(stream);
  } else {
    # Call the generic function (STREAM-READ-BYTE stream):
    pushSTACK(stream); funcall(S(stream_read_byte),1);
    var object result = value1;
    if (eq(result,S(Keof)))
      return eof_value;
    else
      return result;
  }
}

# Function: Reads several bytes from a stream.
# read_byte_array(&stream,&bytearray,start,len)
# > stream: stream (on the STACK)
# > object bytearray: simple-bit-vector (on the STACK)
# > uintL start: start index of byte sequence to be filled
# > uintL len: length of byte sequence to be filled
# < uintL result: number of bytes that have been filled
# can trigger GC
global uintL read_byte_array (const object* stream_, const object* bytearray_,
                              uintL start, uintL len) {
  if (len==0)
    return 0;
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    return rd_by_array(stream)(stream_,bytearray_,start,len);
  } else {
    # Call the generic function
    # (STREAM-READ-BYTE-SEQUENCE stream bytearray start start+len):
    pushSTACK(stream); pushSTACK(*bytearray_);
    pushSTACK(fixnum(start)); pushSTACK(fixnum(start+len));
    funcall(S(stream_read_byte_sequence),4);
    var uintL result;
    if (!(posfixnump(value1)
          && (result = posfixnum_to_L(value1),
              result >= start && result <= start+len))) {
      pushSTACK(fixnum(start+len));
      pushSTACK(fixnum(start));
      pushSTACK(S(stream_read_byte_sequence));
      pushSTACK(value1);
      fehler(error,GETTEXT("Return value ~ of call to ~ should be an integer between ~ and ~."));
    }
    return result-start;
  }
}

# Writes a Byte to a Stream.
# write_byte(stream,byte);
# > stream: Stream
# > byte: Integer to be written
# can trigger GC
global void write_byte (object stream, object byte) {
  if (builtin_stream_p(stream)) {
    wr_by(stream)(stream,byte);
  } else {
    # Call the generic function (STREAM-WRITE-BYTE stream byte):
    pushSTACK(stream); pushSTACK(byte); funcall(S(stream_write_byte),2);
  }
}

# Function: Writes several bytes to a stream.
# write_byte_array(&stream,&bytearray,start,len)
# > stream: Stream (on the STACK)
# > object bytearray: simple-bit-vector (on the STACK)
# > uintL start: start index of byte sequence to be written
# > uintL len: length of byte sequence to be written
global void write_byte_array (const object* stream_, const object* bytearray_,
                              uintL start, uintL len) {
  if (len==0)
    return;
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    wr_by_array(stream)(stream_,bytearray_,start,len);
  } else {
    # Call the generic function
    # (STREAM-WRITE-BYTE-SEQUENCE stream bytearray start start+len):
    pushSTACK(stream); pushSTACK(*bytearray_);
    pushSTACK(fixnum(start)); pushSTACK(fixnum(start+len));
    funcall(S(stream_write_byte_sequence),4);
  }
}

# Reads a Character from a Stream.
# read_char(&stream)
# > stream: Stream
# < stream: Stream
# < result: read Character (eof_value at EOF)
# can trigger GC
global object read_char (const object* stream_) {
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    if (!(TheStream(stream)->strmflags & strmflags_unread_B)) { # Char after UNREAD ?
      # no -> fetch next character:
      var object newch = rd_ch(stream)(stream_);
      stream = *stream_;
      TheStream(stream)->strm_rd_ch_last = newch; # and store
      TheStream(stream)->strmflags &= ~strmflags_unread_B;
      return newch;
    } else {
      # yes -> deleteFlagbit and fetch last character:
      TheStream(stream)->strmflags &= ~strmflags_unread_B;
      return TheStream(stream)->strm_rd_ch_last;
    }
  } else {
    # Call the generic function (STREAM-READ-CHAR stream):
    pushSTACK(stream); funcall(S(stream_read_char),1);
    var object result = value1;
    if (eq(result,S(Keof)))
      return eof_value;
    else
      return result;
  }
}

# pushes the last read Character back to the Stream.
# unread_char(&stream,ch);
# > ch: last read Character
# > stream: Stream
# < stream: Stream
global void unread_char (const object* stream_, object ch) {
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    if (eq(TheStream(stream)->strm_rd_ch_last,ch)
        && !(TheStream(stream)->strmflags & strmflags_unread_B)) {
      TheStream(stream)->strmflags |= strmflags_unread_B; # set Flagbit
    } else {
      if (!nullp(TheStream(stream)->strm_rd_ch_last)
          && !(TheStream(stream)->strmflags & strmflags_unread_B)) {
        pushSTACK(stream); # STREAM-ERROR slot STREAM
        pushSTACK(ch);
        pushSTACK(stream);
        pushSTACK(S(unread_char));
        fehler(stream_error,GETTEXT("~: the last character read from ~ was not ~"));
      } else {
        pushSTACK(stream); # STREAM-ERROR slot STREAM
        pushSTACK(S(read_char));
        pushSTACK(stream);
        pushSTACK(S(unread_char));
        fehler(stream_error,GETTEXT("~ from ~ without ~ before it"));
      }
    }
  } else {
    # Call the generic function (STREAM-UNREAD-CHAR stream ch):
    pushSTACK(stream); pushSTACK(ch); funcall(S(stream_unread_char),2);
  }
}

# Reads a Character from a Stream, without consuming it.
# peek_char(&stream)
# > stream: Stream
# < stream: Stream
# < result: read Character (eof_value at EOF)
# can trigger GC
global object peek_char (const object* stream_) {
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    if (!(TheStream(stream)->strmflags & strmflags_unread_B)) # Char after UNREAD ?
      # no -> fetch new character:
      return pk_ch(stream)(stream_);
    else
      # yes -> fetch last character:
      return TheStream(stream)->strm_rd_ch_last;
  } else {
    # Call the generic function (STREAM-PEEK-CHAR stream):
    pushSTACK(stream); funcall(S(stream_peek_char),1);
    var object result = value1;
    if (eq(result,S(Keof)))
      return eof_value;
    else
      return result;
  }
}

# Function: Reads several characters from a stream.
# read_char_array(&stream,&chararray,start,len)
# > stream: stream (on the STACK)
# > object chararray: a mutable string that is or was simple (on the STACK)
# > uintL start: start index of character sequence to be filled
# > uintL len: length of character sequence to be filled
# < uintL result: number of characters that have been filled
# can trigger GC
global uintL read_char_array (const object* stream_, const object* chararray_,
                              uintL start, uintL len) {
  if (len==0)
    return 0;
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    var object lastchar = TheStream(stream)->strm_rd_ch_last;
    if (eq(lastchar,eof_value)) # EOF ?
      return 0;
    var uintL index = start;
    if (TheStream(stream)->strmflags & strmflags_unread_B) {
      if (!charp(lastchar))
        fehler_char(lastchar);
      sstring_store(*chararray_,index++,char_code(lastchar));
      stream = *stream_;
      len--;
      if (len==0) {
        TheStream(stream)->strmflags &= ~strmflags_unread_B;
        return 1;
      }
    }
    var uintL count = rd_ch_array(stream)(stream_,chararray_,index,len);
    index += count;
    stream = *stream_;
    if (count == len) {
      var object chararray = *chararray_;
      simple_array_to_storage(chararray);
      var chart last_ch = schar(chararray,index-1);
      TheStream(stream)->strm_rd_ch_last = code_char(last_ch);
    } else
      TheStream(stream)->strm_rd_ch_last = eof_value;
    TheStream(stream)->strmflags &= ~strmflags_unread_B;
    return index - start;
  } else {
    # Call the generic function
    # (STREAM-READ-CHAR-SEQUENCE stream chararray start start+len):
    pushSTACK(stream); pushSTACK(*chararray_);
    pushSTACK(fixnum(start)); pushSTACK(fixnum(start+len));
    funcall(S(stream_read_char_sequence),4);
    var uintL result;
    if (!(posfixnump(value1)
          && (result = posfixnum_to_L(value1),
              result >= start && result <= start+len))) {
      pushSTACK(fixnum(start+len));
      pushSTACK(fixnum(start));
      pushSTACK(S(stream_read_char_sequence));
      pushSTACK(value1);
      fehler(error,GETTEXT("Return value ~ of call to ~ should be an integer between ~ and ~."));
    }
    return result-start;
  }
}

# writes a Character to a Stream.
# write_char(&stream,ch);
# > ch: Character to be written
# > stream: Stream
# < stream: Stream
# can trigger GC
global void write_char (const object* stream_, object ch) {
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    var chart c = char_code(ch);
    # write Char:
    wr_ch(stream)(stream_,ch);
    # update Line Position:
    var object stream = *stream_;
    if (!(TheStream(stream)->strmtype == strmtype_terminal)) {
      # not the Terminal-Stream
      if (chareq(c,ascii(NL))) # After Newline: Line Position := 0
        TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
      else # increment line position
        TheStream(stream)->strm_wr_ch_lpos =
          fixnum_inc(TheStream(stream)->strm_wr_ch_lpos,char_width(c));
    } else { # it is the Terminal-Stream
     #ifdef TERMINAL_USES_KEYBOARD
      # On the Atari, wr_ch_terminal() would do this.
     #else
      # How do the control-characters effect in that Position?
      if (chareq(c,ascii(NL))) { # Newline -> Line Position := 0
        TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
      } else if (chareq(c,ascii(BS))) {
        # Backspace -> Line Position, if possible, decrement:
        if (!eq(TheStream(stream)->strm_wr_ch_lpos,Fixnum_0))
          TheStream(stream)->strm_wr_ch_lpos =
            fixnum_inc(TheStream(stream)->strm_wr_ch_lpos,-1);
      } else # increment line position
        TheStream(stream)->strm_wr_ch_lpos =
          fixnum_inc(TheStream(stream)->strm_wr_ch_lpos,char_width(c));
     #endif
    }
  } else {
    # Call the generic function (STREAM-WRITE-CHAR stream ch):
    pushSTACK(stream); pushSTACK(ch); funcall(S(stream_write_char),2);
  }
}

# Function: Writes several characters to a stream.
# write_char_array(&stream,&chararray,start,len)
# > stream: stream (on the STACK)
# > object chararray: simple-string (on the STACK)
# > uintL start: start index of character sequence to be written
# > uintL len: length of character sequence to be written
global void write_char_array (const object* stream_, const object* chararray_,
                              uintL start, uintL len) {
  if (len==0)
    return;
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    wr_ch_array(stream)(stream_,chararray_,start,len);
  } else {
    # Call the generic function
    # (STREAM-WRITE-CHAR-SEQUENCE stream chararray start start+len):
    pushSTACK(stream); pushSTACK(*chararray_);
    pushSTACK(fixnum(start)); pushSTACK(fixnum(start+len));
    funcall(S(stream_write_char_sequence),4);
  }
}

# UP: when closing, fill the stream with the dummy pseudo-functions
#     and remove the capability flags
# close_dummys(stream);
# > stream: Stream
#define close_dummys(s)                                                 \
  stream_dummy_fill(s);                                                 \
  # delete capability flags                                             \
  TheStream(s)->strmflags &= ~(strmflags_open_B|strmflags_unread_B)

# fill the stream with dummy pseudo-functions
local void stream_dummy_fill (object stream) {
  var Stream s = TheStream(stream);
  s->strm_rd_by = P(rd_by_error);
  s->strm_rd_by_array = P(rd_by_array_error);
  s->strm_wr_by = P(wr_by_error);
  s->strm_wr_by_array = P(wr_by_array_error);
  s->strm_rd_ch = P(rd_ch_error);
  s->strm_pk_ch = P(pk_ch_dummy);
  s->strm_rd_ch_array = P(rd_ch_array_error);
  s->strm_rd_ch_last = NIL; # Lastchar := NIL
  s->strm_wr_ch_lpos = Fixnum_0;
  s->strm_wr_ch = P(wr_ch_error);
  s->strm_wr_ch_array = P(wr_ch_array_error);
}

# returns error-message, if the value of the Symbol sym is not a Stream.
nonreturning_function(local, fehler_value_stream, (object sym));
# see below

# UP: Returns the Stream, that is the value of a Variable.
# var_stream(sym,strmflags)
# > sym: Variable (Symbol)
# > strmflags: set of Operations, that are to be possible on the Stream
# < result: Stream
global object var_stream (object sym, uintB strmflags) {
  var object result = Symbol_value(sym);
  var object stream;
 recurse:
  stream = Symbol_value(sym);
  if (builtin_stream_p(stream)) {
    if (strmflags & ~ TheStream(stream)->strmflags)
      fehler_value_stream(sym);
    if (TheStream(stream)->strmtype == strmtype_synonym) {
      sym = TheStream(stream)->strm_synonym_symbol;
      goto recurse;
    }
  } else if (instanceof(stream,O(class_fundamental_stream))) {
    # Among instances of FUNDAMENTAL-STREAM:
    # Only instances of FUNDAMENTAL-INPUT-STREAM can do input.
    # Only instances of FUNDAMENTAL-OUTPUT-STREAM can do output.
    if (((strmflags & strmflags_rd_B)
         && !instanceof(stream,O(class_fundamental_input_stream)))
        || ((strmflags & strmflags_wr_B)
            && !instanceof(stream,O(class_fundamental_output_stream))))
      fehler_value_stream(sym);
  } else
    fehler_value_stream(sym);
  return result;
}

# (SYSTEM::SYMBOL-STREAM symbol [direction])
# returns the Stream, that is the value of the Symbol, and checks, if it is an
# open Stream with Direction direction (:PROBE, :INPUT, :OUTPUT or :IO) .
LISPFUN(symbol_stream,1,1,norest,nokey,0,NIL) {
  var object direction = popSTACK();
  var object symbol = popSTACK();
  if (!symbolp(symbol))
    fehler_symbol(symbol);
  VALUES1(var_stream(symbol,(uintB)(
                    eq(direction,S(Kinput)) ? strmflags_rd_ch_B : /* :INPUT */
                    eq(direction,S(Koutput)) ? strmflags_wr_ch_B : /* :OUTPUT */
                    eq(direction,S(Kio)) ?
                    strmflags_rd_ch_B | strmflags_wr_ch_B : # :IO
                    0))); /* :PROBE or not given */
}

# signal an error if for some obscure reason a WRITE should not work:
nonreturning_function(local, fehler_unwritable, (object caller, object stream)) {
  pushSTACK(stream); # FILE-ERROR slot PATHNAME
  pushSTACK(stream);
  pushSTACK(caller);
  fehler(file_error,GETTEXT("~: cannot output to ~"));
}

# signal an error if an Object is not a Character:
# fehler_wr_char(stream,obj);
nonreturning_function(local, fehler_wr_char, (object stream, object obj)) {
  pushSTACK(obj);          # TYPE-ERROR slot DATUM
  pushSTACK(S(character)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(stream);
  pushSTACK(obj);
  fehler(type_error,GETTEXT("~ is not a character, cannot be output onto ~"));
}

# signal an error if an Object is not an Integer:
# fehler_wr_integer(stream,obj);
nonreturning_function(local, fehler_wr_integer, (object stream, object obj)) {
  pushSTACK(obj);        # TYPE-ERROR slot DATUM
  pushSTACK(S(integer)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(stream);
  pushSTACK(obj);
  fehler(type_error,GETTEXT("~ is not an integer, cannot be output onto ~"));
}

# signal an error if an Integer is out of range:
# fehler_bad_integer(stream,obj);
nonreturning_function(local, fehler_bad_integer, (object stream, object obj)) {
  pushSTACK(stream); # STREAM-ERROR slot STREAM
  pushSTACK(stream);
  pushSTACK(obj);
  fehler(stream_error,GETTEXT("integer ~ is out of range, cannot be output onto ~"));
}

# barf if the object is not a stream
#define check_stream(obj) (streamp(obj) ? obj : (fehler_stream(obj),NIL))
# barf if the object is not a stream of the specific type
#define check_streamtype(obj,type)                                        \
  if (!streamp(obj)) fehler_stream(obj); else fehler_streamtype(obj,type)
# barf if the object is not a built-in stream
#define check_builtin_stream(obj)                               \
  (builtin_stream_p(obj) ? obj                                  \
   : (fehler_streamtype(obj,O(type_builtin_stream)), NIL))
# barf of the object is not an integer
#define check_wr_int(str,obj)                                   \
  (integerp(obj) ? obj : (fehler_wr_integer(str,obj),NIL))

# UP: checks, if Arguments are Streams.
# test_stream_args(args_pointer,argcount);
# > args_pointer: Pointer to the Arguments
# > argcount: number of Arguments
# > subr_self: caller (a SUBR)
local void test_stream_args (object* args_pointer, uintC argcount) {
  dotimesC(argcount,argcount, {
    var object next_arg = NEXT(args_pointer);
    check_stream(next_arg);
  });
}

# Function: Tests whether an object is an input-stream.
# input_stream_p(stream)
# > stream: object
local inline bool input_stream_p (object stream) {
  return (builtin_stream_p(stream) ?
          (TheStream(stream)->strmflags & strmflags_rd_B) != 0
          : instanceof(stream,O(class_fundamental_input_stream)));
}

# Function: Tests whether an object is an output-stream.
# output_stream_p(stream)
# > stream: object
local inline bool output_stream_p (object stream) {
  return (builtin_stream_p(stream) ?
          (TheStream(stream)->strmflags & strmflags_wr_B) != 0
          : instanceof(stream,O(class_fundamental_output_stream)));
}

# UP: checks an Input-Stream.
# test_input_stream(stream);
# > stream: Stream
# > subr_self: caller (a SUBR)
#define test_input_stream(stream)  \
    if (!input_stream_p(stream)) fehler_input_stream(stream);
nonreturning_function(local, fehler_input_stream, (object stream)) {
  pushSTACK(stream);               # TYPE-ERROR slot DATUM
  pushSTACK(O(type_input_stream)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(stream); pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: argument ~ should be an input stream"));
}

# UP: checks an Output-Stream.
# test_output_stream(stream);
# > stream: Stream
# > subr_self: caller (a SUBR)
#define test_output_stream(stream)  \
    if (!output_stream_p(stream)) fehler_output_stream(stream);
nonreturning_function(local, fehler_output_stream, (object stream)) {
  pushSTACK(stream);                # TYPE-ERROR slot DATUM
  pushSTACK(O(type_output_stream)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(stream); pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: argument ~ should be an output stream"));
}

# UP: checks, if Arguments are Input-Streams.
# test_input_stream_args(args_pointer,argcount);
# > args_pointer: Pointer to the Arguments
# > argcount: number of Arguments
# > subr_self: caller (a SUBR)
#define test_input_stream_args(args_pointer,argcount)   \
    if (argcount > 0) {                                 \
      var object* pointer = (args_pointer);             \
      var uintC count;                                  \
      dotimespC(count,argcount, {                       \
        var object arg = NEXT(pointer);                 \
        check_stream(arg);                              \
        test_input_stream(arg);                         \
      });                                               \
    }

# UP: checks, if Arguments are Output-Streams.
# test_output_stream_args(args_pointer,argcount);
# > args_pointer: Pointer to the Arguments
# > argcount: number of Arguments
# > subr_self: caller (a SUBR)
#define test_output_stream_args(args_pointer,argcount)  \
    if (argcount > 0) {                                 \
      var object* pointer = (args_pointer);             \
      var uintC count;                                  \
      dotimespC(count,argcount, {                       \
        var object arg = NEXT(pointer);                 \
        check_stream(arg);                              \
        test_output_stream(arg);                        \
      });                                               \
    }


# Synonym-Stream
# ==============

# Additional Components:
  # define strm_synonym_symbol  strm_other[0]  # Symbol, whose value is referred to

# Macro: Returns the value of a Symbol, a Stream.
# get_synonym_stream(sym)
# > sym: Symbol, a variable
# < result: its value, a Stream
#define get_synonym_stream(sym)                 \
    (!streamp(Symbol_value(sym))                \
     ? (fehler_value_stream(sym), unbound)      \
     : Symbol_value(sym))

# Macro: resolve the synonym stream
#define resolve_as_synonym(stream)                              \
  do { object symbol = TheStream(stream)->strm_synonym_symbol;  \
       stream = get_synonym_stream(symbol); } while (0)

# Function: resolve the synonym stream
local object resolve_synonym_stream (object stream) {
  while (builtin_stream_p(stream)
         && TheStream(stream)->strmtype == strmtype_synonym) {
    object symbol = TheStream(stream)->strm_synonym_symbol;
    stream = get_synonym_stream(symbol);
  }
  return stream;
}

# READ-BYTE - Pseudo-Function for Synonym-Streams:
local object rd_by_synonym (object stream) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  return read_byte(get_synonym_stream(symbol));
}

# READ-BYTE-ARRAY - Pseudo-Function for Synonym-Streams:
local uintL rd_by_array_synonym (const object* stream_,
                                 const object* bytearray_,
                                 uintL start, uintL len) {
  check_SP(); check_STACK();
  var object symbol = TheStream(*stream_)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  var uintL result = read_byte_array(&STACK_0,bytearray_,start,len);
  skipSTACK(1);
  return result;
}

# WRITE-BYTE - Pseudo-Function for Synonym-Streams:
local void wr_by_synonym (object stream, object obj) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  write_byte(get_synonym_stream(symbol),obj);
}

# WRITE-BYTE-ARRAY - Pseudo-Function for Synonym-Streams:
local void wr_by_array_synonym (const object* stream_,
                                const object* bytearray_,
                                uintL start, uintL len) {
  check_SP(); check_STACK();
  var object symbol = TheStream(*stream_)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  write_byte_array(&STACK_0,bytearray_,start,len);
  skipSTACK(1);
}

# READ-CHAR - Pseudo-Function for Synonym-Streams:
local object rd_ch_synonym (const object* stream_) {
  check_SP(); check_STACK();
  var object stream = *stream_;
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  var object ergebnis = read_char(&STACK_0);
  skipSTACK(1);
  return ergebnis;
}

# PEEK-CHAR - Pseudo-Function for Synonym-Streams:
local object pk_ch_synonym (const object* stream_) {
  check_SP(); check_STACK();
  var object stream = *stream_;
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  var object ergebnis = peek_char(&STACK_0);
  skipSTACK(1);
  return ergebnis;
}

# READ-CHAR-ARRAY - Pseudo-Function for Synonym-Streams:
local uintL rd_ch_array_synonym (const object* stream_,
                                 const object* chararray_,
                                 uintL start, uintL len) {
  check_SP(); check_STACK();
  var object symbol = TheStream(*stream_)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  var uintL result = read_char_array(&STACK_0,chararray_,start,len);
  skipSTACK(1);
  return result;
}

# WRITE-CHAR - Pseudo-Function for Synonym-Streams:
local void wr_ch_synonym (const object* stream_, object obj) {
  check_SP(); check_STACK();
  var object stream = *stream_;
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  write_char(&STACK_0,obj);
  skipSTACK(1);
}

# WRITE-CHAR-ARRAY - Pseudo-Function for Synonym-Streams:
local void wr_ch_array_synonym (const object* stream_,
                                const object* chararray_,
                                uintL start, uintL len) {
  check_SP(); check_STACK();
  var object symbol = TheStream(*stream_)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  write_char_array(&STACK_0,chararray_,start,len);
  skipSTACK(1);
  # No need to update wr_ch_lpos here. (See get_line_position().)
}

# Closes a Synonym-Stream.
# close_synonym(stream);
# > stream : Synonym-Stream
#ifdef X3J13_014
  #define close_synonym(stream)
#else
  local void close_synonym (object stream) {
    check_SP(); check_STACK();
    var object symbol = TheStream(stream)->strm_synonym_symbol;
    pushSTACK(get_synonym_stream(symbol));
    funcall(S(close),1);
  }
#endif

# Reads a line of characters from a synonym-stream.
# read_line_synonym(stream,&buffer)
# > stream: synonym-stream
# > buffer: a semi-simple string
# < buffer: contains the read characters, excluding the terminating #\Newline
# < result: true if EOF was seen before newline, else false
# can trigger GC
local bool read_line_synonym (object stream, const object* buffer_) {
  check_SP(); check_STACK();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  pushSTACK(get_synonym_stream(symbol));
  var bool eofp = read_line(&STACK_0,buffer_);
  skipSTACK(1);
  return eofp;
}

# Determines, if a character is available on the Synonym-Stream.
# listen_char_synonym(stream)
# > stream : Synonym-Stream
# < result:  ls_avail if a character is available,
#            ls_eof   if EOF is reached,
#            ls_wait  if no character is available, but not because of EOF
# can trigger GC
local signean listen_char_synonym (object stream) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  return listen_char(get_synonym_stream(symbol));
}

# UP: Deletes already entered interactive Input from a Synonym-Stream.
# clear_input_synonym(stream)
# > stream: Synonym-Stream
# < result: true if Input was deleted
# can trigger GC
local bool clear_input_synonym (object stream) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  return clear_input(get_synonym_stream(symbol));
}

# Determines, if a Byte is available on a Synonym-Stream.
# listen_byte_synonym(stream)
# > stream : Synonym-Stream
# < result:  ls_avail if a byte is available,
#            ls_eof   if EOF is reached,
#            ls_wait  if no byte is available, but not because of EOF
# can trigger GC
local signean listen_byte_synonym (object stream) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  return listen_byte(get_synonym_stream(symbol));
}

# UP: bring pending Output of a Synonym-Stream to the destination.
# finish_output_synonym(stream);
# > stream: Synonym-Stream
# can trigger GC
local void finish_output_synonym (object stream) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  finish_output(get_synonym_stream(symbol));
}

# UP: bring pending Output of a Synonym-Stream to the destination.
# force_output_synonym(stream);
# > stream: Synonym-Stream
# can trigger GC
local void force_output_synonym (object stream) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  force_output(get_synonym_stream(symbol));
}

# UP: delete the pending Output of a Synonym-Stream.
# clear_output_synonym(stream);
# > stream: Synonym-Stream
# can trigger GC
local void clear_output_synonym (object stream) {
  check_SP();
  var object symbol = TheStream(stream)->strm_synonym_symbol;
  clear_output(get_synonym_stream(symbol));
}

# Returns a Synonym-Stream for a Symbol.
# make_synonym_stream(symbol)
# > symbol : Symbol
# < result : new Synonym-Stream
# can trigger GC
local object make_synonym_stream (object symbol) {
  pushSTACK(symbol); # save Symbol
  var object stream = # new Stream, all Operations permitted
    allocate_stream(strmflags_rdwr_B,strmtype_synonym,strm_len+1,0);
  TheStream(stream)->strm_rd_by = P(rd_by_synonym);
  TheStream(stream)->strm_rd_by_array = P(rd_by_array_synonym);
  TheStream(stream)->strm_wr_by = P(wr_by_synonym);
  TheStream(stream)->strm_wr_by_array = P(wr_by_array_synonym);
  TheStream(stream)->strm_rd_ch = P(rd_ch_synonym);
  TheStream(stream)->strm_pk_ch = P(pk_ch_synonym);
  TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_synonym);
  TheStream(stream)->strm_rd_ch_last = NIL;
  TheStream(stream)->strm_wr_ch = P(wr_ch_synonym);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_synonym);
  TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
  TheStream(stream)->strm_synonym_symbol = popSTACK();
  return stream;
}

# (MAKE-SYNONYM-STREAM symbol), CLTL p. 329
LISPFUNN(make_synonym_stream,1) {
  var object arg = popSTACK();
  if (!symbolp(arg)) {
    pushSTACK(arg);       # TYPE-ERROR slot DATUM
    pushSTACK(S(symbol)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(arg); pushSTACK(TheSubr(subr_self)->name);
    fehler(type_error,GETTEXT("~: argument should be a symbol, not ~"));
  }
  VALUES1(make_synonym_stream(arg));
}

# (SYS::SYNONYM-STREAM-P stream) == (TYPEP stream 'SYNONYM-STREAM)
LISPFUNN(synonym_stream_p,1) {
  var object arg = popSTACK();
  VALUES_IF(builtin_stream_p(arg)
            && (TheStream(arg)->strmtype == strmtype_synonym));
}

# (SYNONYM-STREAM-SYMBOL stream), CLtL2 p. 507
LISPFUNN(synonym_stream_symbol,1) {
  var object stream = popSTACK();
  if (!(builtin_stream_p(stream)
        && (TheStream(stream)->strmtype == strmtype_synonym))) {
    check_streamtype(stream,S(synonym_stream));
  }
  VALUES1(TheStream(stream)->strm_synonym_symbol);
}


# Broadcast-Stream
# ================

# Additional Components:
  # define strm_broad_list  strm_other[0] # list of streams

# WRITE-BYTE - Pseudo-Function for Broadcast-Streams:
local void wr_by_broad (object stream, object obj) {
  check_SP(); check_STACK();
  pushSTACK(obj);
  { # list of streams
    var object streamlist = TheStream(stream)->strm_broad_list;
    # write obj to each Stream on the List:
    while (consp(streamlist)) {
      pushSTACK(Cdr(streamlist)); # remaining Streams
      write_byte(Car(streamlist),STACK_1); # write obj
      streamlist = popSTACK();
    }
  }
  skipSTACK(1);
}

# WRITE-BYTE-ARRAY - Pseudo-Function for Broadcast-Streams:
local void wr_by_array_broad (const object* stream_, const object* bytearray_,
                              uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_broad_list); # list of streams
  var object streamlist;
  while (streamlist = STACK_0, consp(streamlist)) {
    STACK_0 = Cdr(streamlist);
    pushSTACK(Car(streamlist));
    write_byte_array(&STACK_0,bytearray_,start,len);
    skipSTACK(1);
  }
  skipSTACK(1);
}

# WRITE-CHAR - Pseudo-Function for Broadcast-Streams:
local void wr_ch_broad (const object* stream_, object obj) {
  check_SP(); check_STACK();
  pushSTACK(obj);
  pushSTACK(NIL); # dummy
  pushSTACK(TheStream(*stream_)->strm_broad_list); # list of streams
  # write obj to each Stream on the List:
  while (mconsp(STACK_0)) {
    # Stack Layout: obj, dummy, streamlistr.
    STACK_1 = Car(STACK_0); # a Stream from the Liste
    write_char(&STACK_1,STACK_2); # write obj
    STACK_0 = Cdr(STACK_0);
  }
  skipSTACK(3);
}

# WRITE-CHAR-ARRAY - Pseudo-Function for Broadcast-Streams:
local void wr_ch_array_broad (const object* stream_, const object* chararray_,
                              uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_broad_list); # list of streams
  pushSTACK(NIL); # dummy
  var object streamlist;
  while (streamlist = STACK_1, consp(streamlist)) {
    STACK_1 = Cdr(streamlist);
    STACK_0 = Car(streamlist);
    write_char_array(&STACK_0,chararray_,start,len);
  }
  skipSTACK(2);
  # No need to update wr_ch_lpos here. (See get_line_position().)
}

# UP: Moves the pending Output of a Broadcast-Stream to the destination.
# finish_output_broad(stream);
# > stream: Broadcast-Stream
# can trigger GC
local void finish_output_broad (object stream) {
  check_SP(); check_STACK();
  var object streamlist = TheStream(stream)->strm_broad_list; # list of streams
  # treat each Stream from the List separately:
  while (consp(streamlist)) {
    pushSTACK(Cdr(streamlist)); # remaining Streams
    finish_output(Car(streamlist));
    streamlist = popSTACK();
  }
}

# UP: Moves the pending Output of a Broadcast-Stream to the destination.
# force_output_broad(stream);
# > stream: Broadcast-Stream
# can trigger GC
local void force_output_broad (object stream) {
  check_SP(); check_STACK();
  var object streamlist = TheStream(stream)->strm_broad_list; # list of streams
  # treat each Stream from the List separately:
  while (consp(streamlist)) {
    pushSTACK(Cdr(streamlist)); # remaining Streams
    force_output(Car(streamlist));
    streamlist = popSTACK();
  }
}

# UP: Deletes the pending Output of a Broadcast-Stream.
# clear_output_broad(stream);
# > stream: Broadcast-Stream
# can trigger GC
local void clear_output_broad (object stream) {
  check_SP(); check_STACK();
  var object streamlist = TheStream(stream)->strm_broad_list; # list of streams
  # treat each Stream from the List separately:
  while (consp(streamlist)) {
    pushSTACK(Cdr(streamlist)); # remaining Streams
    clear_output(Car(streamlist));
    streamlist = popSTACK();
  }
}

# Returns a Broadcast-Stream for a list of Streams.
# make_broadcast_stream(list)
# > list : list of streams
# < result : Broadcast-Stream
# Thereby the List list is destroyed.
# can trigger GC
local object make_broadcast_stream (object list) {
  pushSTACK(list); # save list
  var object stream = # new Stream, only WRITEs allowed
    allocate_stream(strmflags_wr_B,strmtype_broad,strm_len+1,0);
  list = popSTACK();
  stream_dummy_fill(stream);
  TheStream(stream)->strm_wr_by = P(wr_by_broad);
  TheStream(stream)->strm_wr_by_array = P(wr_by_array_broad);
  TheStream(stream)->strm_wr_ch = P(wr_ch_broad);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_broad);
  TheStream(stream)->strm_broad_list = list;
  return stream;
}

# returns a Broadcast-Stream for Stream stream.
# make_broadcast1_stream(stream)
# > stream : Stream
# < result : Broadcast-Stream
# can trigger GC
global object make_broadcast1_stream (object oldstream) {
  pushSTACK(oldstream);
  # pack oldstream in a one-element List:
  var object new_cons = allocate_cons();
  Car(new_cons) = STACK_0;
  var object stream = make_broadcast_stream(new_cons); # new Stream
  oldstream = popSTACK();
  # take over Line-Position:
  TheStream(stream)->strm_wr_ch_lpos = TheStream(oldstream)->strm_wr_ch_lpos;
  return stream;
}

# (MAKE-BROADCAST-STREAM {stream}), CLTL p. 329
LISPFUN(make_broadcast_stream,0,0,rest,nokey,0,NIL) {
  # check that all Arguments are Streams:
  test_output_stream_args(rest_args_pointer,argcount);
  # collect to one List:
  var object list = listof(argcount);
  # build Stream:
  VALUES1(make_broadcast_stream(list));
}

# (SYS::BROADCAST-STREAM-P stream) == (TYPEP stream 'BROADCAST-STREAM)
LISPFUNN(broadcast_stream_p,1) {
  var object arg = popSTACK();
  VALUES_IF(builtin_stream_p(arg)
            && (TheStream(arg)->strmtype == strmtype_broad));
}

# (BROADCAST-STREAM-STREAMS stream), CLtL2 p. 507
LISPFUNN(broadcast_stream_streams,1) {
  var object stream = popSTACK();
  if (!(builtin_stream_p(stream)
        && (TheStream(stream)->strmtype == strmtype_broad))) {
    check_streamtype(stream,S(broadcast_stream));
  }
  # copy List of Streams as a precaution
  VALUES1(copy_list(TheStream(stream)->strm_broad_list));
}


# Concatenated-Stream
# ===================

# Additional Components:
  # define strm_concat_list      strm_other[0]  # list of not exhausted streams
  #define strm_concat_totallist  strm_other[1]  # list of all streams

# READ-BYTE - Pseudo-Function for Concatenated-Streams:
local object rd_by_concat (object stream) {
  check_SP(); check_STACK();
  pushSTACK(stream);
  var object streamlist = TheStream(stream)->strm_concat_list; # list of streams
  var object result;
  while (consp(streamlist)) {
    result = read_byte(Car(streamlist)); # read Integer
    if (!eq(result,eof_value)) # not EOF ?
      goto OK;
    # EOF reached -> remove emptied Stream from the List:
    stream = STACK_0;
    streamlist = TheStream(stream)->strm_concat_list =
             Cdr(TheStream(stream)->strm_concat_list);
  }
  # all Streams emptied -> return EOF:
  result = eof_value;
 OK:
  skipSTACK(1);
  return result;
}

# READ-BYTE-ARRAY - Pseudo-Function for Concatenated-Streams:
local uintL rd_by_array_concat (const object* stream_,
                                const object* bytearray_,
                                uintL start, uintL len) {
  check_SP(); check_STACK();
  var uintL result = 0;
  var object stream = *stream_;
  var object streamlist = TheStream(stream)->strm_concat_list; # list of streams
  loop {
    if (atomp(streamlist))
      break;
    pushSTACK(Car(streamlist));
    var uintL count = read_byte_array(&STACK_0,bytearray_,start,len);
    skipSTACK(1);
    result += count;
    start += count; len -= count;
    if (len == 0)
      break;
    # EOF reached -> remove emptied stream from the list:
    stream = *stream_;
    streamlist = TheStream(stream)->strm_concat_list =
             Cdr(TheStream(stream)->strm_concat_list);
  }
  return result;
}

# READ-CHAR - Pseudo-Function for Concatenated-Streams:
local object rd_ch_concat (const object* stream_) {
  check_SP(); check_STACK();
  var object streamlist = TheStream(*stream_)->strm_concat_list; # list of streams
  while (consp(streamlist)) {
    pushSTACK(Car(streamlist));
    var object result = read_char(&STACK_0); # read Character
    skipSTACK(1);
    if (!eq(result,eof_value))
      return result;
    # EOF reached -> remove emptied stream from the list:
    var object stream = *stream_;
    streamlist = TheStream(stream)->strm_concat_list =
             Cdr(TheStream(stream)->strm_concat_list);
  }
  # all Streams emptied -> return EOF:
  return eof_value;
}

# PEEK-CHAR - Pseudo-Function for Concatenated-Streams:
local object pk_ch_concat (const object* stream_) {
  check_SP(); check_STACK();
  var object streamlist = TheStream(*stream_)->strm_concat_list; # list of streams
  while (consp(streamlist)) {
    pushSTACK(Car(streamlist));
    var object result = peek_char(&STACK_0); # read Character
    skipSTACK(1);
    if (!eq(result,eof_value))
      return result;
    # EOF reached -> remove emptied stream from the list:
    var object stream = *stream_;
    streamlist = TheStream(stream)->strm_concat_list =
             Cdr(TheStream(stream)->strm_concat_list);
  }
  # all Streams emptied -> return EOF:
  return eof_value;
}

# READ-CHAR-ARRAY - Pseudo-Function for Concatenated-Streams:
local uintL rd_ch_array_concat (const object* stream_,
                                const object* chararray_,
                                uintL start, uintL len) {
  check_SP(); check_STACK();
  var uintL result = 0;
  var object stream = *stream_;
  var object streamlist = TheStream(stream)->strm_concat_list; # list of streams
  loop {
    if (atomp(streamlist))
      break;
    pushSTACK(Car(streamlist));
    var uintL count = read_char_array(&STACK_0,chararray_,start,len);
    skipSTACK(1);
    result += count;
    start += count; len -= count;
    if (len == 0)
      break;
    # EOF reached -> remove emptied stream from the list:
    stream = *stream_;
    streamlist = TheStream(stream)->strm_concat_list =
             Cdr(TheStream(stream)->strm_concat_list);
  }
  return result;
}

# Determines, if a character is available on the Concatenated-Stream.
# listen_char_concat(stream)
# > stream : Concatenated-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
# can trigger GC
local signean listen_char_concat (object stream) {
  pushSTACK(stream);
  var object streamlist = TheStream(stream)->strm_concat_list; # list of streams
  var signean result;
  while (consp(streamlist)) {
    result = listen_char(Car(streamlist));
    if (!ls_eof_p(result)) # not EOF ?
      goto OK;
    # EOF reached -> remove emptied stream from the list:
    stream = STACK_0;
    streamlist = TheStream(stream)->strm_concat_list =
             Cdr(TheStream(stream)->strm_concat_list);
  }
  # all Streams emptied -> return EOF:
  result = ls_eof;
 OK:
  skipSTACK(1);
  return result;
}

# UP: Deletes already entered interactive Input from a
# Concatenated-Stream.
# clear_input_concat(stream)
# > stream: Concatenated-Stream
# < result: true if Input was deleted
# can trigger GC
local bool clear_input_concat (object stream) {
  var bool result = false; # no Input deleted yet
  # treat all Streams separately:
  var object streamlist = TheStream(stream)->strm_concat_list; # list of streams
  while (consp(streamlist)) {
    pushSTACK(Cdr(streamlist)); # remaining list ofStreams
    result |= clear_input(Car(streamlist)); # delete all Input of the sub-streams
    streamlist = popSTACK();
  }
  return result;
}

# Determines, if a Byte is available on the Concatenated-Stream.
# listen_byte_concat(stream)
# > stream : Concatenated-Stream
# < result:   ls_avail if a byte is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no byte is available, but not because of EOF
# can trigger GC
local signean listen_byte_concat (object stream) {
  pushSTACK(stream);
  var object streamlist = TheStream(stream)->strm_concat_list; # list of streams
  var signean result;
  while (consp(streamlist)) {
    result = listen_byte(Car(streamlist));
    if (!ls_eof_p(result)) # not EOF ?
      goto OK;
    # EOF reached -> remove emptied stream from the list:
    stream = STACK_0;
    streamlist = TheStream(stream)->strm_concat_list =
             Cdr(TheStream(stream)->strm_concat_list);
  }
  # all Streams emptied -> return EOF:
  result = ls_eof;
 OK:
  skipSTACK(1);
  return result;
}

# Returns a Concatenated-Stream for a list of Stream.
# make_concatenated_stream(list)
# > list : list of streams
# < result : Concatenated-Stream
# Thereby the List list is destroyed.
# can trigger GC
local object make_concatenated_stream (object list) {
  pushSTACK(list); # save list
  var object stream = # new Stream, only READs allowed
    allocate_stream(strmflags_rd_B,strmtype_concat,strm_len+2,0);
  stream_dummy_fill(stream);
  TheStream(stream)->strm_rd_by = P(rd_by_concat);
  TheStream(stream)->strm_rd_by_array = P(rd_by_array_concat);
  TheStream(stream)->strm_rd_ch = P(rd_ch_concat);
  TheStream(stream)->strm_pk_ch = P(pk_ch_concat);
  TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_concat);
  TheStream(stream)->strm_concat_list =
    TheStream(stream)->strm_concat_totallist = popSTACK();
  return stream;
}

# (MAKE-CONCATENATED-STREAM {stream}), CLTL p. 329
LISPFUN(make_concatenated_stream,0,0,rest,nokey,0,NIL) {
  # check that all Arguments are Streams:
  test_input_stream_args(rest_args_pointer,argcount);
  # collect to one List:
  var object list = listof(argcount);
  # build Stream:
  VALUES1(make_concatenated_stream(list));
}

# (SYS::CONCATENATED-STREAM-P stream) == (TYPEP stream 'CONCATENATED-STREAM)
LISPFUNN(concatenated_stream_p,1) {
  var object arg = popSTACK();
  VALUES_IF(builtin_stream_p(arg)
            && (TheStream(arg)->strmtype == strmtype_concat));
}

# (CONCATENATED-STREAM-STREAMS stream), CLtL2 p. 507
LISPFUNN(concatenated_stream_streams,1) {
  var object stream = popSTACK();
  if (!(builtin_stream_p(stream)
        && (TheStream(stream)->strmtype == strmtype_concat))) {
    check_streamtype(stream,S(concatenated_stream));
  }
  # copy List of Streams as a precaution
  VALUES1(copy_list(TheStream(stream)->strm_concat_list));
}


# Two-Way-Stream, Echo-Stream
# ===========================

# Additional Components:
  # define strm_twoway_input   strm_other[0]  # Stream for Input
  # define strm_twoway_output  strm_other[1]  # Stream for Output

# WRITE-BYTE - Pseudo-Function for Two-Way- and Echo-Streams:
local void wr_by_twoway (object stream, object obj) {
  check_SP();
  write_byte(TheStream(stream)->strm_twoway_output,obj);
}

# WRITE-BYTE-ARRAY - Pseudo-Function for Two-Way- and Echo-Streams:
local void wr_by_array_twoway (const object* stream_, const object* bytearray_,
                               uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_output);
  write_byte_array(&STACK_0,bytearray_,start,len);
  skipSTACK(1);
}

# WRITE-CHAR - Pseudo-Function for Two-Way- and Echo-Streams:
local void wr_ch_twoway (const object* stream_, object obj) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_output);
  write_char(&STACK_0,obj);
  skipSTACK(1);
}

# WRITE-CHAR-ARRAY - Pseudo-Function for Two-Way- and Echo-Streams:
local void wr_ch_array_twoway (const object* stream_, const object* chararray_,
                               uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_output);
  write_char_array(&STACK_0,chararray_,start,len);
  skipSTACK(1);
  # No need to update wr_ch_lpos here. (See get_line_position().)
}

# Determines, if a Character is available on a Two-Way- or Echo-Stream.
# listen_char_twoway(stream)
# > stream : Two-Way- or Echo-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
# can trigger GC
local signean listen_char_twoway (object stream) {
  check_SP();
  return listen_char(TheStream(stream)->strm_twoway_input);
}

# UP: Deletes already entered interactive Input from a Two-Way-
# or Echo-Stream.
# clear_input_twoway(stream)
# > stream: Two-Way- or Echo-Stream
# < result: true if Input was deleted
# can trigger GC
local bool clear_input_twoway (object stream) {
  check_SP();
  return clear_input(TheStream(stream)->strm_twoway_input);
}

# Determines, if a Byte is available on a Two-Way- or Echo-Stream.
# listen_byte_twoway(stream)
# > stream : Two-Way- or Echo-Stream
# < result:   ls_avail if a byte is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no byte is available, but not because of EOF
# can trigger GC
local signean listen_byte_twoway (object stream) {
  check_SP();
  return listen_byte(TheStream(stream)->strm_twoway_input);
}

# UP: Moves the pending Output of a Two-Way- or Echo-Stream to the destination.
# finish_output_twoway(stream);
# > stream: Two-Way- or Echo-Stream
# can trigger GC
local void finish_output_twoway (object stream) {
  check_SP();
  finish_output(TheStream(stream)->strm_twoway_output);
}

# UP: Moves the pending Output of a Two-Way- or Echo-Stream to the destination.
# force_output_twoway(stream);
# > stream: Two-Way- or Echo-Stream
# can trigger GC
local void force_output_twoway (object stream) {
  check_SP();
  force_output(TheStream(stream)->strm_twoway_output);
}

# UP: Deletes the pending Output of a Two-Way- or Echo-Stream.
# clear_output_twoway(stream);
# > stream: Two-Way- or Echo-Stream
# can trigger GC
local void clear_output_twoway (object stream) {
  check_SP();
  clear_output(TheStream(stream)->strm_twoway_output);
}

# Two-Way-Stream
# ==============

# READ-BYTE - Pseudo-Function for Two-Way-Streams:
local object rd_by_twoway (object stream) {
  check_SP();
  return read_byte(TheStream(stream)->strm_twoway_input);
}

# READ-BYTE-ARRAY - Pseudo-Function for Two-Way-Streams:
local uintL rd_by_array_twoway (const object* stream_,
                                const object* bytearray_,
                                uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_input);
  var uintL result = read_byte_array(&STACK_0,bytearray_,start,len);
  skipSTACK(1);
  return result;
}

# READ-CHAR - Pseudo-Function for Two-Way-Streams:
local object rd_ch_twoway (const object* stream_) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_input);
  var object result = read_char(&STACK_0);
  skipSTACK(1);
  return result;
}

# PEEK-CHAR - Pseudo-Function for Two-Way-Streams:
local object pk_ch_twoway (const object* stream_) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_input);
  var object result = peek_char(&STACK_0);
  skipSTACK(1);
  return result;
}

# READ-CHAR-ARRAY - Pseudo-Function for Two-Way-Streams:
local uintL rd_ch_array_twoway (const object* stream_,
                                const object* chararray_,
                                uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_input);
  var uintL result = read_char_array(&STACK_0,chararray_,start,len);
  skipSTACK(1);
  return result;
}

# Reads a line of characters from a two-way-stream.
# read_line_twoway(stream,&buffer)
# > stream: two-way-stream
# > buffer: a semi-simple string
# < buffer: contains the read characters, excluding the terminating #\Newline
# < result: true if EOF was seen before newline, else false
# can trigger GC
local bool read_line_twoway (object stream, const object* buffer_) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(stream)->strm_twoway_input);
  var bool eofp = read_line(&STACK_0,buffer_);
  skipSTACK(1);
  return eofp;
}

# Returns a Two-Way-Stream for an Input-Stream and an Output-Stream.
# make_twoway_stream(input_stream,output_stream)
# > input_stream : Input-Stream
# > output_stream : Output-Stream
# < result : Two-Way-Stream
# can trigger GC
global object make_twoway_stream (object input_stream, object output_stream) {
  pushSTACK(input_stream); pushSTACK(output_stream); # save Streams
  var uintB flags = strmflags_rdwr_B
    | (TheStream(input_stream)->strmflags & strmflags_immut_B);
  var object stream = # new Stream, all Operations allowed
    allocate_stream(flags,strmtype_twoway,strm_len+2,0);
  TheStream(stream)->strm_rd_by = P(rd_by_twoway);
  TheStream(stream)->strm_rd_by_array = P(rd_by_array_twoway);
  TheStream(stream)->strm_wr_by = P(wr_by_twoway);
  TheStream(stream)->strm_wr_by_array = P(wr_by_array_twoway);
  TheStream(stream)->strm_rd_ch = P(rd_ch_twoway);
  TheStream(stream)->strm_pk_ch = P(pk_ch_twoway);
  TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_twoway);
  TheStream(stream)->strm_rd_ch_last = NIL;
  TheStream(stream)->strm_wr_ch = P(wr_ch_twoway);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_twoway);
  output_stream = popSTACK(); input_stream = popSTACK(); # put back Streams
  TheStream(stream)->strm_wr_ch_lpos =
    TheStream(output_stream)->strm_wr_ch_lpos;
  TheStream(stream)->strm_twoway_input = input_stream;
  TheStream(stream)->strm_twoway_output = output_stream;
  return stream;
}

# (MAKE-TWO-WAY-STREAM input-stream output-stream), CLTL p. 329
LISPFUNN(make_two_way_stream,2) {
  # check that both are Streams:
  test_stream_args(args_end_pointer STACKop 2, 2);
  var object output_stream = popSTACK();
  var object input_stream = popSTACK();
  test_input_stream(input_stream);
  test_output_stream(output_stream);
  # build Stream:
  VALUES1(make_twoway_stream(input_stream,output_stream));
}

# check whether the stream S is a two-way-stream
#define stream_twoway_p(s)                                              \
  (builtin_stream_p(s) && (TheStream(s)->strmtype == strmtype_twoway))

# (SYS::TWO-WAY-STREAM-P stream) == (TYPEP stream 'TWO-WAY-STREAM)
LISPFUNN(two_way_stream_p,1) {
  var object arg = popSTACK();
  VALUES_IF(stream_twoway_p(arg));
}

# (TWO-WAY-STREAM-INPUT-STREAM stream), CLtL2 p. 507
LISPFUNN(two_way_stream_input_stream,1) {
  var object stream = popSTACK();
  if (!stream_twoway_p(stream))
    check_streamtype(stream,S(two_way_stream));
  VALUES1(TheStream(stream)->strm_twoway_input);
}

# (TWO-WAY-STREAM-OUTPUT-STREAM stream), CLtL2 p. 507
LISPFUNN(two_way_stream_output_stream,1) {
  var object stream = popSTACK();
  if (!stream_twoway_p(stream))
    check_streamtype(stream,S(two_way_stream));
  VALUES1(TheStream(stream)->strm_twoway_output);
}


# Echo-Stream
# ===========

# READ-BYTE - Pseudo-Function for Echo-Streams:
local object rd_by_echo (object stream) {
  check_SP(); check_STACK();
  pushSTACK(stream);
  var object obj = read_byte(TheStream(stream)->strm_twoway_input);
  stream = popSTACK();
  if (!eq(obj,eof_value)) {
    pushSTACK(obj);
    write_byte(TheStream(stream)->strm_twoway_output,obj);
    obj = popSTACK();
  }
  return obj;
}

# READ-BYTE-ARRAY - Pseudo-Function for Echo-Streams:
local uintL rd_by_array_echo (const object* stream_, const object* bytearray_,
                              uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_input);
  var uintL result = read_byte_array(&STACK_0,bytearray_,start,len);
  STACK_0 = TheStream(*stream_)->strm_twoway_output;
  write_byte_array(&STACK_0,bytearray_,start,result);
  skipSTACK(1);
  return result;
}

# READ-CHAR - Pseudo-Function for Echo-Streams:
local object rd_ch_echo (const object* stream_) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_input);
  var object obj = read_char(&STACK_0);
  if (!eq(obj,eof_value)) {
    STACK_0 = TheStream(*stream_)->strm_twoway_output;
    pushSTACK(obj);
    write_char(&STACK_1,obj);
    obj = popSTACK();
  }
  skipSTACK(1);
  return obj;
}

# READ-CHAR-ARRAY - Pseudo-Function for Echo-Streams:
local uintL rd_ch_array_echo (const object* stream_, const object* chararray_,
                              uintL start, uintL len) {
  check_SP(); check_STACK();
  pushSTACK(TheStream(*stream_)->strm_twoway_input);
  var uintL result = read_char_array(&STACK_0,chararray_,start,len);
  STACK_0 = TheStream(*stream_)->strm_twoway_output;
  write_char_array(&STACK_0,chararray_,start,result);
  skipSTACK(1);
  return result;
}

# returns an Echo-Stream for an Input-Stream and an Output-Stream.
# make_echo_stream(input_stream,output_stream)
# > input_stream : Input-Stream
# > output_stream : Output-Stream
# < result : Echo-Stream
# can trigger GC
local object make_echo_stream (object input_stream, object output_stream) {
  pushSTACK(input_stream); pushSTACK(output_stream); # save Streams
  var uintB flags = strmflags_rdwr_B
    | (TheStream(input_stream)->strmflags & strmflags_immut_B);
  var object stream = # new Stream, all Operations allowed
    allocate_stream(flags,strmtype_echo,strm_len+2,0);
  TheStream(stream)->strm_rd_by = P(rd_by_echo);
  TheStream(stream)->strm_rd_by_array = P(rd_by_array_echo);
  TheStream(stream)->strm_wr_by = P(wr_by_twoway);
  TheStream(stream)->strm_wr_by_array = P(wr_by_array_twoway);
  TheStream(stream)->strm_rd_ch = P(rd_ch_echo);
  TheStream(stream)->strm_pk_ch = P(pk_ch_twoway);
  TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_echo);
  TheStream(stream)->strm_rd_ch_last = NIL;
  TheStream(stream)->strm_wr_ch = P(wr_ch_twoway);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_twoway);
  output_stream = popSTACK(); input_stream = popSTACK(); # put back Streams
  TheStream(stream)->strm_wr_ch_lpos =
    TheStream(output_stream)->strm_wr_ch_lpos;
  TheStream(stream)->strm_twoway_input = input_stream;
  TheStream(stream)->strm_twoway_output = output_stream;
  return stream;
}

# (MAKE-ECHO-STREAM input-stream output-stream), CLTL p. 330
LISPFUNN(make_echo_stream,2) {
  # check that both are Streams:
  test_stream_args(args_end_pointer STACKop 2, 2);
  var object output_stream = popSTACK();
  var object input_stream = popSTACK();
  test_input_stream(input_stream);
  test_output_stream(output_stream);
  # build Stream:
  VALUES1(make_echo_stream(input_stream,output_stream));
}

# check whether the stream S is a two-way-stream
#define stream_echo_p(s)                                                 \
  (builtin_stream_p(s) && (TheStream(s)->strmtype == strmtype_echo))

# (SYS::ECHO-STREAM-P stream) == (TYPEP stream 'ECHO-STREAM)
LISPFUNN(echo_stream_p,1) {
  var object arg = popSTACK();
  VALUES_IF(stream_echo_p(arg));
}

# (ECHO-STREAM-INPUT-STREAM stream), CLtL2 p. 507
LISPFUNN(echo_stream_input_stream,1) {
  var object stream = popSTACK();
  if (!stream_echo_p(stream))
    check_streamtype(stream,S(echo_stream));
  VALUES1(TheStream(stream)->strm_twoway_input);
}

# (ECHO-STREAM-OUTPUT-STREAM stream), CLtL2 p. 507
LISPFUNN(echo_stream_output_stream,1) {
  var object stream = popSTACK();
  if (!stream_echo_p(stream))
    check_streamtype(stream,S(echo_stream));
  VALUES1(TheStream(stream)->strm_twoway_output);
}


# String-Input-Stream
# ===================

# Additional Components:
  #define strm_str_in_string    strm_other[0]  # String for Input
  #define strm_str_in_index     strm_other[1]  # Index in the String (Fixnum >=0)
  #define strm_str_in_endindex  strm_other[2]  # Endindex (Fixnum >= index >=0)

# error-message, if index >= length(string):
# fehler_str_in_adjusted(stream);
# > stream: problematic String-Input-Stream
nonreturning_function(local, fehler_str_in_adjusted, (object stream)) {
  pushSTACK(stream); # STREAM-ERROR slot STREAM
  pushSTACK(TheStream(stream)->strm_str_in_string);
  pushSTACK(stream);
  fehler(stream_error,GETTEXT("~ is beyond the end because the string ~ has been adjusted"));
}

# READ-CHAR - Pseudo-Function for String-Input-Streams:
local object rd_ch_str_in (const object* stream_) {
  var object stream = *stream_;
  var uintL index = posfixnum_to_L(TheStream(stream)->strm_str_in_index);
  var uintL endindex = posfixnum_to_L(TheStream(stream)->strm_str_in_endindex);
  if (index >= endindex) {
    return eof_value; # EOF reached
  } else { # index < endvalid
    var uintL len;
    var uintL offset;
    var object string = unpack_string_ro(TheStream(stream)->strm_str_in_string,&len,&offset);
    if (index >= len) # Index too big?
      fehler_str_in_adjusted(stream);
    /* fetch character from String */
    var object ch = code_char(schar(string,offset+index));
    # increase Index:
    TheStream(stream)->strm_str_in_index =
      fixnum_inc(TheStream(stream)->strm_str_in_index,1);
    return ch;
  }
}

# READ-CHAR-ARRAY - Pseudo-Function for String-Input-Streams:
local uintL rd_ch_array_str_in (const object* stream_,
                                const object* chararray_,
                                uintL start, uintL len) {
  var object stream = *stream_;
  var uintL index = posfixnum_to_L(TheStream(stream)->strm_str_in_index);
  var uintL endindex = posfixnum_to_L(TheStream(stream)->strm_str_in_endindex);
  if (index < endindex) {
    var uintL srclen;
    var uintL srcoffset;
    var object string = unpack_string_ro(TheStream(stream)->strm_str_in_string,&srclen,&srcoffset);
    if (srclen < endindex)
      fehler_str_in_adjusted(stream);
    var uintL count = endindex - index;
    if (count > len)
      count = len;
    # count = min(len,endindex-index) > 0.
    var object chararray = *chararray_;
    simple_array_to_storage(chararray);
    elt_copy(string,srcoffset+index,chararray,start,count);
    TheStream(stream)->strm_str_in_index = fixnum_inc(TheStream(stream)->strm_str_in_index,count);
    return count;
  } else {
    return 0;
  }
}

# Closes a String-Input-Stream.
# close_str_in(stream);
# > stream : String-Input-Stream
local void close_str_in (object stream) {
  TheStream(stream)->strm_str_in_string = NIL; # String := NIL
}

# Determines, if a character is available on a String-Input-Stream.
# listen_char_str_in(stream)
# > stream : String-Input-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
# can trigger GC
local signean listen_char_str_in (object stream) {
  var uintL index = posfixnum_to_L(TheStream(stream)->strm_str_in_index);
  var uintL endindex = posfixnum_to_L(TheStream(stream)->strm_str_in_endindex);
  if (index >= endindex)
    return ls_eof; # EOF reached
  else
    return ls_avail;
}

# (MAKE-STRING-INPUT-STREAM string [start [end]]), CLTL p. 330
LISPFUN(make_string_input_stream,1,2,norest,nokey,0,NIL) {
  # fetch String and check range:
  var stringarg arg;
  var object string = test_string_limits_ro(&arg);
  var object start_arg = fixnum(arg.index); # start-Argument (Fixnum >=0)
  var object end_arg = fixnum_inc(start_arg,arg.len); # end-Argument (Fixnum >=0)
  pushSTACK(string); # save String
  var object stream = # new Stream, only READ-CHAR allowed
    allocate_stream(strmflags_rd_ch_B,strmtype_str_in,strm_len+3,0);
  stream_dummy_fill(stream);
  TheStream(stream)->strm_rd_ch = P(rd_ch_str_in);
  TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_str_in);
  TheStream(stream)->strm_str_in_string = popSTACK();
  TheStream(stream)->strm_str_in_index = start_arg; # Index := start-Argument
  TheStream(stream)->strm_str_in_endindex = end_arg; # Endindex := end-Argument
  VALUES1(stream); # stream as value
}

# (SYSTEM::STRING-INPUT-STREAM-INDEX string-input-stream) returns the Index
LISPFUNN(string_input_stream_index,1) {
  var object stream = popSTACK(); # Argument
  # must be a String-Input-Stream:
  if (!(builtin_stream_p(stream)
        && (TheStream(stream)->strmtype == strmtype_str_in))) {
    pushSTACK(stream);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~: ~ is not a string input stream"));
  }
  var object index = TheStream(stream)->strm_str_in_index;
  # if a Character was pushed back with UNREAD-CHAR,
  # use (1- index), a Fixnum >=0, as value:
  if (TheStream(stream)->strmflags & strmflags_unread_B)
    index = fixnum_inc(index,-1);
  VALUES1(index);
}


# String-Output-Stream
# ====================

# Additional Components:
  #define strm_str_out_string  strm_other[0]  # Semi-Simple-String for Output

# WRITE-CHAR - Pseudo-Function for String-Output-Streams:
local void wr_ch_str_out (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # obj must be a character
    fehler_wr_char(stream,ch);
  # push Character in the String:
  ssstring_push_extend(TheStream(stream)->strm_str_out_string,char_code(ch));
}

# WRITE-CHAR-ARRAY - Pseudo-Function for String-Output-Streams:
local void wr_ch_array_str_out (const object* stream_,
                                const object* chararray_,
                                uintL start, uintL len) {
  var object ssstring = TheStream(*stream_)->strm_str_out_string; # Semi-Simple-String
  ssstring = ssstring_append_extend(ssstring,*chararray_,start,len);
  wr_ss_lpos(*stream_,&TheSstring(TheIarray(ssstring)->data)->data[TheIarray(ssstring)->dims[1]],len); # update Line-Position
}

# Returns a String-Output-Stream.
# make_string_output_stream()
# can trigger GC
global object make_string_output_stream (void) {
  pushSTACK(make_ssstring(SEMI_SIMPLE_DEFAULT_SIZE));
  var object stream = # new Stream, only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_str_out,strm_len+1,0);
  stream_dummy_fill(stream);
  TheStream(stream)->strm_wr_ch = P(wr_ch_str_out);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_str_out);
  TheStream(stream)->strm_str_out_string = popSTACK(); # enter the String
  return stream;
}

# (MAKE-STRING-OUTPUT-STREAM [:element-type] [:line-position])
LISPFUN(make_string_output_stream,0,0,norest,key,2,
        (kw(element_type),kw(line_position))) {
  # check line-position:
  if (missingp(STACK_0)) {
    STACK_0 = Fixnum_0; # Default value 0
  } else { # line-position specified, should be a Fixnum >=0 :
    if (!posfixnump(STACK_0))
      fehler_posfixnum(STACK_0);
  }
  # check element-type:
  if (boundp(STACK_1)) {
    var object eltype = STACK_1;
    if (!eq(eltype,S(character))) {
      # Verify (SUBTYPEP eltype 'CHARACTER):
      pushSTACK(eltype); pushSTACK(S(character)); funcall(S(subtypep),2);
      if (nullp(value1)) {
        pushSTACK(STACK_1); # eltype
        pushSTACK(S(character)); # CHARACTER
        pushSTACK(S(Kelement_type)); # :ELEMENT-TYPE
        pushSTACK(S(make_string_output_stream));
        fehler(error,GETTEXT("~: ~ argument must be a subtype of ~, not ~"));
      }
    }
  }
  var object stream = make_string_output_stream(); # String-Output-Stream
  TheStream(stream)->strm_wr_ch_lpos = popSTACK(); # Line Position eintragen
  VALUES1(stream); /* return stream */
  skipSTACK(1);
}

# UP: Returns the collected stuff from a String-Output-Stream.
# get_output_stream_string(&stream)
# > stream: String-Output-Stream
# < stream: emptied Stream
# < result: collected stuff, a Simple-String
# can trigger GC
global object get_output_stream_string (const object* stream_) {
  var object string = TheStream(*stream_)->strm_str_out_string; # old String
  string = coerce_ss(string); # convert to Simple-String (enforces copying)
  # empty old String by Fill-Pointer:=0 :
  TheIarray(TheStream(*stream_)->strm_str_out_string)->dims[1] = 0;
  return string;
}

# (GET-OUTPUT-STREAM-STRING string-output-stream), CLTL p. 330
LISPFUNN(get_output_stream_string,1) {
  var object stream = STACK_0; # Argument
  # must be a String-Output-Stream:
  if (!(builtin_stream_p(stream) &&
        (TheStream(stream)->strmtype == strmtype_str_out))) {
    # stream in STACK_0
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~: ~ is not a string output stream"));
  }
  # the collected stuff is the value
  VALUES1(get_output_stream_string(&STACK_0));
  skipSTACK(1);
}


# String-Push-Stream
# ==================

# Additional Components:
  #define strm_str_push_string  strm_other[0]  # String with Fill-Pointer for Output

# WRITE-CHAR - Pseudo-Function for String-Push-Streams:
local void wr_ch_str_push (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(stream,ch);
  # push Character in the String:
  pushSTACK(ch); pushSTACK(TheStream(stream)->strm_str_push_string);
  funcall(L(vector_push_extend),2); # (VECTOR-PUSH-EXTEND ch string)
}

# (SYSTEM::MAKE-STRING-PUSH-STREAM string) returns a Stream, whose
# WRITE-CHAR-Operation is equivalent to a VECTOR-PUSH-EXTEND
# on the given String.
LISPFUNN(make_string_push_stream,1) {
  {
    var object arg = STACK_0; # Argument
    # must be a String with Fill-Pointer:
    if (!(stringp(arg) && array_has_fill_pointer_p(arg))) {
      pushSTACK(arg);                              # TYPE-ERROR slot DATUM
      pushSTACK(O(type_string_with_fill_pointer)); # TYPE-ERROR slot EXPECTED-TYPE
      pushSTACK(S(with_output_to_string));
      fehler(type_error,
             GETTEXT("~: argument ~ should be a string with fill pointer"));
    }
  }
  var object stream = # new Stream, only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_str_push,strm_len+1,0);
  stream_dummy_fill(stream);
  TheStream(stream)->strm_wr_ch = P(wr_ch_str_push);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_dummy);
  TheStream(stream)->strm_str_push_string = popSTACK(); # enter String
  VALUES1(stream); /* return stream */
}


# String-Stream in general
# =======================

# (SYS::STRING-STREAM-P stream) == (TYPEP stream 'STRING-STREAM)
LISPFUNN(string_stream_p,1) {
  var object arg = popSTACK();
  if (builtin_stream_p(arg)) {
    switch (TheStream(arg)->strmtype) {
      case strmtype_str_in:   # String-Input-Stream
      case strmtype_str_out:  # String-Output-Stream
      case strmtype_str_push: # String-Push-Stream
        VALUES1(T); break;
      default:
        VALUES1(NIL); break;
    }
  } else
    VALUES1(NIL);
}


# Pretty-Printer-Help-Stream
# ==========================

# Additional Components:
  # define strm_pphelp_strings  strm_other[0]   # Semi-Simple-Strings for Output
  # define strm_pphelp_modus    strm_other[1]   # Mode (NIL=single-liner, T=multi-liner)

# WRITE-CHAR - Pseudo-Function for Pretty-Printer-Auxiliary-Streams:
local void wr_ch_pphelp (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(stream,ch);
  var chart c = char_code(ch); # Character
  # At NL: Now  Mode := Multi-liner
  if (chareq(c,ascii(NL))) {
    TheStream(stream)->strm_pphelp_modus = T;
    cons_ssstring(stream_,NIL);
  } else if ((chareq(c,ascii(' ')) || chareq(c,ascii('\t')))
             && !nullpSv(print_pretty_fill)) {
    var object list = TheStream(stream)->strm_pphelp_strings;
    if (!(vector_length(Car(list)) == 0 && mconsp(Cdr(list))
          && mconsp(Car(Cdr(list))) && eq(S(Kfill),Car(Car(Cdr(list)))))) {
      ssstring_push_extend(Car(list),c);
      # spaces right after a :FILL newline or multiple spaces are ignored
      cons_ssstring(stream_,S(Kfill));
    }
  } else
    # push Character in the first String:
    ssstring_push_extend(Car(TheStream(stream)->strm_pphelp_strings),c);
}

# WRITE-CHAR-ARRAY - Pseudo-Function for Pretty-Printer-Auxiliary-Streams:
local void wr_ch_array_pphelp (const object* stream_, const object* chararray_,
                               uintL start, uintL len) {
  var bool filling = !nullpSv(print_pretty_fill);
  var uintL beg = start;
  # if (start) sstring_printf(*chararray_,start+len,0);
  # sstring_printf(*chararray_,start+len,start);
  loop {
    var uintL end = beg;
    var object nl_type = NIL;
    # printf(" [%d/",beg);
    while (end < start+len) {
      var chart ch = schar(*chararray_,end);
      if (chareq(ch,ascii(NL))) { /*printf("%d=NL",end);*/break; }
      if (filling && (chareq(ch,ascii(' ')) || chareq(ch,ascii('\t')))) {
        # printf("%d=SPC",end);
        end++; # include the space
        nl_type = S(Kfill);
        break;
      }
      end++;
    }
    # printf("/%d]",end);
    if (beg != end) {
      var uintL count = end-beg;
      var object ssstring = Car(TheStream(*stream_)->strm_pphelp_strings); # Semi-Simple-String
      ssstring = ssstring_append_extend(ssstring,*chararray_,beg,count);
      if (wr_ss_lpos(*stream_,&TheSstring(TheIarray(ssstring)->data)->data[TheIarray(ssstring)->dims[1]],count)) # update Line-Position
        TheStream(*stream_)->strm_pphelp_modus = T; # After NL: Mode := multi-liner
    }
    if (end == start+len)
      break;
    if (nullp(nl_type))
      TheStream(*stream_)->strm_pphelp_modus = T;
    cons_ssstring(stream_,nl_type);
    beg = end;
    if (nullp(nl_type))
      beg++; # skip the newline
  }
  # printf("\n");
}

# UP: Returns a Pretty-Printer-Auxiliary-Stream.
# make_pphelp_stream()
# can trigger GC
global object make_pphelp_stream (void) {
  pushSTACK(cons_ssstring(NULL,NIL));
  var object stream = # new Stream, only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_pphelp,strm_len+2,0);
  stream_dummy_fill(stream);
  TheStream(stream)->strm_wr_ch = P(wr_ch_pphelp);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_pphelp);
  TheStream(stream)->strm_pphelp_strings = popSTACK(); # enter String-List
  TheStream(stream)->strm_pphelp_modus = NIL; # Mode := single-liner
  return stream;
}


# Buffered-Input-Stream
# =====================

# Element-Type: character
# Directions: only input
# (make-buffered-input-stream fun mode) returns a Buffered-Input-Stream.
#   fun is a Function of 0 Arguments, that returns upon call
#   either NIL (stands for EOF) or up to three values string, start, end.
#   Functionality: (read-char ...) returns one after another the characters
#   of the current String; if it is consumed, fun is called, and if the returning
#   value is a String, the new current String is given by
#     (multiple-value-bind (str start end) (funcall fun)
#       (subseq str (or start 0) (or end 'NIL))
#     )
#   The String returned by fun should not be changed.
#   (Otherwise fun should copy the String with COPY-SEQ beforehand.)
#   mode determines, how the Stream acts regarding to LISTEN.
#   mode = NIL: Stream acts like a File-Stream, i.e. on LISTEN
#               and empty current String fun is called.
#   mode = T: Stream acts like an interactive Stream without EOF,
#             i.e. one can assume, that always further characters will
#             arrive, without calling fun.
#   mode a Function: This Function tells, upon call, if
#             further non-empty Strings are to be expected.
#   (clear-input ...) finishes the processing of the current String.

# Additional Components:
  # define strm_buff_in_fun      strm_other[0]  # Read-Function
  #define strm_buff_in_mode      strm_other[1]  # Mode or Listen-Function
  #define strm_buff_in_string    strm_other[2]  # current String for Input
  #define strm_buff_in_index     strm_other[3]  # Index in the String (Fixnum >=0)
  #define strm_buff_in_endindex  strm_other[4]  # Endindex (Fixnum >= index >=0)

# READ-CHAR - Pseudo-Function for Buffered-Input-Streams:
local object rd_ch_buff_in (const object* stream_) {
  var object stream = *stream_;
  var uintL index = posfixnum_to_L(TheStream(stream)->strm_buff_in_index);
  var uintL endindex =
    posfixnum_to_L(TheStream(stream)->strm_buff_in_endindex);
  loop {
    if (index < endindex) # still something in the current String?
      break;
    # String-Ende reached
    # call fun:
    funcall(TheStream(stream)->strm_buff_in_fun,0);
    if (!stringp(value1))
      return eof_value; # EOF reached
    # fetch new String and check ranges:
    pushSTACK(value1); # String
    pushSTACK(mv_count >= 2 ? value2 : unbound); # start
    pushSTACK(mv_count >= 3 ? value3 : unbound); # end
    subr_self = L(read_char);
    var stringarg val;
    var object string = test_string_limits_ro(&val);
    stream = *stream_;
    index = val.index;
    endindex = index+val.len;
    TheStream(stream)->strm_buff_in_string = string;
    TheStream(stream)->strm_buff_in_index = fixnum(index);
    TheStream(stream)->strm_buff_in_endindex = fixnum(endindex);
  }
  # index < endvalid
  var uintL len;
  var uintL offset;
  var object string = unpack_string_ro(TheStream(stream)->strm_buff_in_string,&len,&offset);
  if (index >= len) { # Index too big ?
    pushSTACK(stream); # STREAM-ERROR slot STREAM
    pushSTACK(TheStream(stream)->strm_buff_in_string);
    pushSTACK(stream);
    fehler(stream_error,GETTEXT("~ is beyond the end because the string ~ has been adjusted"));
  }
  /* fetch character from String */
  var object ch = code_char(schar(string,offset+index));
  # increase Index:
  TheStream(stream)->strm_buff_in_index = fixnum_inc(TheStream(stream)->strm_buff_in_index,1);
  return ch;
}

# Closes a Buffered-Input-Stream.
# close_buff_in(stream);
# > stream : Buffered-Input-Stream
local void close_buff_in (object stream) {
  TheStream(stream)->strm_buff_in_fun = NIL; # Function := NIL
  TheStream(stream)->strm_buff_in_mode = NIL; # Mode := NIL
  TheStream(stream)->strm_buff_in_string = NIL; # String := NIL
}

# Determines, if a character is available on a Buffered-Input-Stream.
# listen_char_buff_in(stream)
# > stream : Buffered-Input-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
# can trigger GC
local signean listen_char_buff_in (object stream) {
  var uintL index = posfixnum_to_L(TheStream(stream)->strm_buff_in_index);
  var uintL endindex = posfixnum_to_L(TheStream(stream)->strm_buff_in_endindex);
  if (index < endindex)
    return ls_avail;
  var object mode = TheStream(stream)->strm_buff_in_mode;
  if (eq(mode,S(nil))) {
    pushSTACK(stream);
    mode = peek_char(&STACK_0); # peek_char makes read_char, calls fun
    skipSTACK(1);
    if (eq(mode,eof_value))
      return ls_eof; # EOF reached
    else
      return ls_avail;
  } else if (eq(mode,S(t))) {
    return ls_avail;
  } else {
    funcall(mode,0); # call mode
    if (nullp(value1)) # no more Strings to be expected?
      return ls_eof; # yes -> EOF reached
    else
      return ls_avail;
  }
}

# UP: Deletes already entered interactive Input from a Buffered-Input-Stream.
# clear_input_buff_in(stream)
# > stream: Buffered-Input-Stream
# < result: true if Input was deleted
# can trigger GC
local bool clear_input_buff_in (object stream) {
  # end processing of the current String:
  var object index = TheStream(stream)->strm_buff_in_index;
  var object endindex = TheStream(stream)->strm_buff_in_endindex;
  TheStream(stream)->strm_buff_in_index = endindex; # index := endindex
  if (eq(index,endindex))
    return false;
  else
    return true;
}

# (MAKE-BUFFERED-INPUT-STREAM fun mode)
LISPFUNN(make_buffered_input_stream,2) {
  var object stream = # new Stream, only READ-CHAR allowed
    allocate_stream(strmflags_rd_ch_B,strmtype_buff_in,strm_len+5,0);
  stream_dummy_fill(stream);
  TheStream(stream)->strm_rd_ch = P(rd_ch_buff_in);
  TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_dummy);
  TheStream(stream)->strm_buff_in_mode = popSTACK();
  TheStream(stream)->strm_buff_in_fun = popSTACK();
  TheStream(stream)->strm_buff_in_string = O(empty_string); # String := ""
  TheStream(stream)->strm_buff_in_index = Fixnum_0; # Index := 0
  TheStream(stream)->strm_buff_in_endindex = Fixnum_0; # Endindex := 0
  VALUES1(stream); /* return stream */
}

# (SYS::BUFFERED-INPUT-STREAM-INDEX buffered-input-stream) returns the Index
LISPFUNN(buffered_input_stream_index,1) {
  var object stream = popSTACK(); # Argument
  # must be a Buffered-Input-Stream:
  if (!(builtin_stream_p(stream) &&
        (TheStream(stream)->strmtype == strmtype_buff_in))) {
    pushSTACK(stream);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~: ~ is not a buffered input stream"));
  }
  var object index = TheStream(stream)->strm_buff_in_index;
  # if a Character was pushed back with UNREAD-CHAR,
  # use (1- index), a Fixnum >=0, as value:
  if (TheStream(stream)->strmflags & strmflags_unread_B)
    index = fixnum_inc(index,-1);
  VALUES1(index);
}


# Buffered-Output-Stream
# ======================

# Element-Type: character
# Directions: only output
# (make-buffered-output-stream fun) returns a Buffered-Output-Stream.
#   fun is a Function expecting one Argument, a Simple-String.
#   Functionality: (write-char ...) gathers the written characters in
#   a String, until a #\Newline or a FORCE-/FINISH-OUTPUT-
#   request arrives. Then it calls fun with a Simple-String as Argument,
#   that contains the so far collected stuff.
#   (clear-output ...) dicards the so far collected characters.

# Additional Components:
  # define strm_buff_out_fun    strm_other[0]  # Output-Function
  #define strm_buff_out_string  strm_other[1]  # Semi-Simple-String for Output

# UP: Moves the pending Output of a Buffered-Output-Stream to the destination.
# finish_output_buff_out(stream);
# > stream: Buffered-Output-Stream
# can trigger GC
local void finish_output_buff_out (object stream) {
  pushSTACK(stream);
  var object string = TheStream(stream)->strm_buff_out_string; # String
  string = coerce_ss(string); # convert to Simple-String (enforces copying)
  stream = STACK_0; STACK_0 = string;
# empty String by Fill-Pointer:=0 :
  TheIarray(TheStream(stream)->strm_buff_out_string)->dims[1] = 0;
  funcall(TheStream(stream)->strm_buff_out_fun,1); # call Function
}

# UP: Moves the pending Output of a Buffered-Output-Stream to the destination.
# force_output_buff_out(stream);
# > stream: Buffered-Output-Stream
# can trigger GC
  #define force_output_buff_out  finish_output_buff_out

# UP: Deletes the pending Output of a Buffered-Output-Stream.
# clear_output_buff_out(stream);
# > stream: Buffered-Output-Stream
# can trigger GC
local void clear_output_buff_out (object stream) {
  # empty String by Fill-Pointer:=0 :
  TheIarray(TheStream(stream)->strm_buff_out_string)->dims[1] = 0;
  # leave Line-Position unchanged??
}

# WRITE-CHAR - Pseudo-Function for Buffered-Output-Streams:
local void wr_ch_buff_out (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # obj must be a character
    fehler_wr_char(stream,ch);
  # push Character in the String:
  ssstring_push_extend(TheStream(stream)->strm_buff_out_string,char_code(ch));
  # After #\Newline pass on Buffer:
  if (chareq(char_code(ch),ascii(NL)))
    force_output_buff_out(*stream_);
}

# Closes a Buffered-Output-Stream.
# close_buff_out(stream);
# > stream : Buffered-Output-Stream
# can trigger GC
local void close_buff_out (object stream) {
  pushSTACK(stream); # save stream
  finish_output_buff_out(stream);
  stream = popSTACK(); # restore stream
  TheStream(stream)->strm_buff_out_fun = NIL; # Function := NIL
  TheStream(stream)->strm_buff_out_string = NIL; # String := NIL
}

# (MAKE-BUFFERED-OUTPUT-STREAM fun [line-position])
LISPFUN(make_buffered_output_stream,1,1,norest,nokey,0,NIL) {
  # check line-position:
  if (!boundp(STACK_0)) {
    STACK_0 = Fixnum_0; # default value 0
  } else { # line-position specified, should be a Fixnum >=0 :
    if (!posfixnump(STACK_0))
      fehler_posfixnum(STACK_0);
  }
  # allocate small Semi-Simple-String of Length 50 :
  pushSTACK(make_ssstring(SEMI_SIMPLE_DEFAULT_SIZE));
  var object stream = # new Stream, only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_buff_out,strm_len+2,0);
  stream_dummy_fill(stream);
  TheStream(stream)->strm_wr_ch = P(wr_ch_buff_out);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_dummy);
  TheStream(stream)->strm_buff_out_string = popSTACK(); # enter String
  TheStream(stream)->strm_wr_ch_lpos = popSTACK(); # enter Line Position
  TheStream(stream)->strm_buff_out_fun = popSTACK(); # enter Function
  VALUES1(stream); /* return stream */
}


#ifdef GENERIC_STREAMS

# Generic Streams
# ===============

  # Contains a "controller object".
  # define strm_controller_object  strm_other[0]  # see lispbibl.d

  # The function GENERIC-STREAM-CONTROLLER will return some
  # object c associated with the stream s.

  #   (GENERIC-STREAM-READ-CHAR c)                      --> character or NIL
  #   (GENERIC-STREAM-PEEK-CHAR c)                      --> character or NIL
  #   (GENERIC-STREAM-READ-CHAR-WILL-HANG-P c)          --> {T,NIL}
  #   (GENERIC-STREAM-CLEAR-INPUT c)                    --> {T,NIL}
  #   (GENERIC-STREAM-WRITE-CHAR c ch)                  -->
  #   (GENERIC-STREAM-WRITE-STRING c string start len)  -->
  #   (GENERIC-STREAM-FINISH-OUTPUT c)                  -->
  #   (GENERIC-STREAM-FORCE-OUTPUT c)                   -->
  #   (GENERIC-STREAM-CLEAR-OUTPUT c)                   -->
  #   (GENERIC-STREAM-READ-BYTE c)                      --> integer or NIL
  #   (GENERIC-STREAM-WRITE-BYTE c i)                   -->
  #   (GENERIC-STREAM-CLOSE c)                          -->

# (READ-CHAR s) ==
# (GENERIC-STREAM-READ-CHAR c)
local object rd_ch_generic (const object* stream_) {
  pushSTACK(*stream_); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_rdch),1);
  return nullp(value1) ? eof_value : value1;
}

# (PEEK-CHAR s) ==
# (GENERIC-STREAM-PEEK-CHAR c)
local object pk_ch_generic (const object* stream_) {
  pushSTACK(*stream_); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_pkch),1);
  if (nullp(value1))
    value1 = eof_value;
  if ((mv_count >= 2) && !nullp(value2)) {
    # READ-CHAR already executed -> must execute an implicit UNREAD-CHAR
    # (i.e. save the result for the next READ-CHAR/PEEK-CHAR).
    TheStream(*stream_)->strm_rd_ch_last = value1;
    if (!eq(value1,eof_value))
      TheStream(*stream_)->strmflags |= strmflags_unread_B;
  }
  return value1;
}

# (LISTEN s) ==
# (IF (GENERIC-STREAM-READ-CHAR-WILL-HANG-P c)
#   :WAIT
#   (IF (GENERIC-STREAM-PEEK-CHAR c)
#     :INPUT-AVAILABLE
#     :EOF
# ) )
local signean listen_char_generic (object stream) {
  pushSTACK(stream);
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_read_char_will_hang_p),1);
  if (!nullp(value1)) {
    skipSTACK(1); return ls_wait;
  }
  var object nextchar = pk_ch_generic(&STACK_0);
  skipSTACK(1);
  if (eq(nextchar,eof_value))
    return ls_eof;
  else
    return ls_avail;
}

# (CLEAR-INPUT s) ==
# (GENERIC-STREAM-CLEAR-INPUT c)
local bool clear_input_generic (object stream) {
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_clear_input),1);
  return !nullp(value1);
}

# (WRITE-CHAR ch s) ==
# (GENERIC-STREAM-WRITE-CHAR c ch)
local void wr_ch_generic (const object* stream_, object ch) {
  # ch is a character, need not save it
  pushSTACK(*stream_); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); pushSTACK(ch); funcall(S(generic_stream_wrch),2);
}

# (WRITE-CHAR-ARRAY s string start len) ==
# (GENERIC-STREAM-WRITE-STRING c string start len)
local void wr_ch_array_generic (const object* stream_,
                                const object* chararray_,
                                uintL start, uintL len) {
  pushSTACK(*stream_); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); pushSTACK(*chararray_);
  pushSTACK(UL_to_I(start)); pushSTACK(UL_to_I(len));
  funcall(S(generic_stream_wrss),4);
  var const chart* charptr;
  unpack_sstring_alloca(*chararray_,len,start, charptr=);
  wr_ss_lpos(*stream_,&charptr[len],len);
}

# (FINISH-OUTPUT s) ==
# (GENERIC-STREAM-FINISH-OUTPUT c)
local void finish_output_generic (object stream) {
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_finish_output),1);
}

# (FORCE-OUTPUT s) ==
# (GENERIC-STREAM-FORCE-OUTPUT c)
local void force_output_generic (object stream) {
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_force_output),1);
}

# (CLEAR-OUTPUT s) ==
# (GENERIC-STREAM-CLEAR-OUTPUT c)
local void clear_output_generic (object stream) {
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_clear_output),1);
}

# (READ-BYTE s) ==
# (GENERIC-STREAM-READ-BYTE c)
local object rd_by_generic (object stream) {
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_rdby),1);
  return (nullp(value1) ? eof_value : value1);
}

# (WRITE-BYTE s i) ==
# (GENERIC-STREAM-WRITE-BYTE c i)
local void wr_by_generic (object stream, object obj) {
  pushSTACK(obj); # save obj
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  obj = STACK_0;
  STACK_0 = value1; pushSTACK(obj); funcall(S(generic_stream_wrby),2);
}

# (CLOSE s) ==
# (GENERIC-STREAM-CLOSE c)
local void close_generic (object stream) {
  pushSTACK(stream); funcall(L(generic_stream_controller),1);
  pushSTACK(value1); funcall(S(generic_stream_close),1);
}

LISPFUNN(generic_stream_controller,1) {
  var object stream = popSTACK();
  if (!(builtin_stream_p(stream)
        && eq(TheStream(stream)->strm_rd_by,P(rd_by_generic))
        && eq(TheStream(stream)->strm_wr_by,P(wr_by_generic)))) {
    if (!streamp(stream)) {
      fehler_stream(stream);
    } else {
      pushSTACK(stream);
      pushSTACK(TheSubr(subr_self)->name);
      fehler(error,GETTEXT("~: stream must be a generic-stream, not ~"));
    }
  }
  VALUES1(TheStream(stream)->strm_controller_object);
}

LISPFUNN(make_generic_stream,1) {
  var object stream =
    allocate_stream(strmflags_rdwr_B,strmtype_generic,strm_len+1,0);
  TheStream(stream)->strm_rd_by = P(rd_by_generic);
  TheStream(stream)->strm_rd_by_array = P(rd_by_array_dummy);
  TheStream(stream)->strm_wr_by = P(wr_by_generic);
  TheStream(stream)->strm_wr_by_array = P(wr_by_array_dummy);
  TheStream(stream)->strm_rd_ch = P(rd_ch_generic);
  TheStream(stream)->strm_pk_ch = P(pk_ch_generic);
  TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_dummy);
  TheStream(stream)->strm_rd_ch_last = NIL;
  TheStream(stream)->strm_wr_ch = P(wr_ch_generic);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_generic);
  TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
  TheStream(stream)->strm_controller_object = popSTACK();
  VALUES1(stream); /* return stream */
}

LISPFUNN(generic_stream_p,1) {
  var object stream = popSTACK();
  check_stream(stream);
  if (builtin_stream_p(stream)
      && eq(TheStream(stream)->strm_rd_by,P(rd_by_generic))
      && eq(TheStream(stream)->strm_wr_by,P(wr_by_generic)))
    { VALUES1(T); }
  else
    { VALUES1(NIL); }
}

#endif


# Streams communicating with the exterior world, based on bytes
# =============================================================

# They can be classified in three ways:
# According to strmtype:

#                      file  ----  strmtype_file
#                    /
#             handle
#           /        \           /  strmtype_pipe_in
#   channel            pipe  -----  strmtype_pipe_out
#           \
#             socket  -----   strmtype_x11socket
#                         \   strmtype_socket

# According to buffering:

#             unbuffered
#           /
#   channel
#           \
#             buffered

# According to element type:

#             CHARACTER or ([UN]SIGNED-BYTE n), n a multiple of 8 (setfable!)
#           /
#   channel
#           \
#             ([UN]SIGNED-BYTE n), n not a multiple of 8 (only if buffered)


# UP: Check a :BUFFERED argument.
# test_buffered_arg(arg)
# > object arg: argument
# > subr_self: calling function
# < signean buffered: +1 for T, -1 for NIL, 0 for :DEFAULT
local signean test_buffered_arg (object arg) {
  if (!boundp(arg) || eq(arg,S(Kdefault)))
    return 0;
  if (nullp(arg))
    return -1;
  if (eq(arg,T))
    return 1;
  pushSTACK(arg); pushSTACK(S(Kbuffered));
  pushSTACK(TheSubr(subr_self)->name);
  fehler(error,GETTEXT("~: illegal ~ argument ~"));
}

# Classification of possible :ELEMENT-TYPEs.
typedef enum {
  eltype_ch,    # CHARACTER
  eltype_iu,    # (UNSIGNED-BYTE n)
  eltype_is     # (SIGNED-BYTE n)
} eltype_kind;

# An analyzed :ELEMENT-TYPE argument.
typedef struct {
  eltype_kind kind;
  uintL       size; # the n in ([UN]SIGNED-BYTE n),
                    # >0, <intDsize*uintWC_max,
                    # but 0 for eltype_ch
} decoded_el_t;

# UP: Check a :ELEMENT-TYPE argument.
# test_eltype_arg(&eltype,&decoded);
# > object eltype: argument (in the STACK)
# > subr_self: calling function
# < subr_self: unchanged
# < decoded: decoded eltype
# can trigger GC
local void test_eltype_arg (object* eltype_, decoded_el_t* decoded) {
  var object arg = *eltype_;
  if (!boundp(arg) || eq(arg,S(character)) || eq(arg,S(string_char))
      || eq(arg,S(Kdefault))) { # CHARACTER, STRING-CHAR, :DEFAULT
    decoded->kind = eltype_ch; decoded->size = 0; return;
  }
  if (eq(arg,S(bit))) { # BIT
    decoded->kind = eltype_iu; decoded->size = 1; return;
  }
  if (eq(arg,S(unsigned_byte))) { # UNSIGNED-BYTE
    decoded->kind = eltype_iu; decoded->size = 8; return;
  }
  if (eq(arg,S(signed_byte))) { # SIGNED-BYTE
    decoded->kind = eltype_is; decoded->size = 8; return;
  }
  var object eltype_size;
  if (consp(arg) && mconsp(Cdr(arg)) && nullp(Cdr(Cdr(arg)))) { # two-element List
    var object h = Car(arg);
    if (eq(h,S(mod))) { # (MOD n)
      decoded->kind = eltype_iu;
      h = Car(Cdr(arg)); # n
      # must be an Integer >0 :
      if (!(integerp(h) && positivep(h) && !eq(h,Fixnum_0)))
        goto bad_eltype;
      # build eltype_size := (integer-length (1- n)) :
      pushSTACK(subr_self); # save subr_self
      pushSTACK(h); funcall(L(einsminus),1); # (1- n)
      pushSTACK(value1); funcall(L(integer_length),1); # (integer-length (1- n))
      eltype_size = value1;
      subr_self = popSTACK(); # restore subr_self
      goto eltype_integer;
    }
    if (eq(h,S(unsigned_byte))) { # (UNSIGNED-BYTE n)
      decoded->kind = eltype_iu;
      eltype_size = Car(Cdr(arg));
      goto eltype_integer;
    }
    if (eq(h,S(signed_byte))) { # (SIGNED-BYTE n)
      decoded->kind = eltype_is;
      eltype_size = Car(Cdr(arg));
      goto eltype_integer;
    }
  }
  pushSTACK(subr_self); # save subr_self
  # First of all canonicalize a little bit (therewith the different
  # SUBTYPEP will not have to do the same three times):
  pushSTACK(arg); funcall(S(canonicalize_type),1); # (SYS::CANONICALIZE-TYPE arg)
  pushSTACK(value1); # save canon-arg
  pushSTACK(STACK_0); pushSTACK(S(character)); funcall(S(subtypep),2); # (SUBTYPEP canon-arg 'CHARACTER)
  if (!nullp(value1)) {
    skipSTACK(1);
    subr_self = popSTACK();
    decoded->kind = eltype_ch; decoded->size = 0;
    return;
  }
  funcall(S(subtype_integer),1); # (SYS::SUBTYPE-INTEGER canon-arg)
  subr_self = popSTACK(); # restore subr_self
  if (!((mv_count>1) && integerp(value1) && integerp(value2)))
    goto bad_eltype;
  {
    # arg is a subtype of `(INTEGER ,low ,high) and
    # value1 = low, value2 = high.
    var uintL l;
    if (positivep(value1)) {
      l = I_integer_length(value2); # (INTEGER-LENGTH high)
      decoded->kind = eltype_iu;
    } else {
      var uintL l1 = I_integer_length(value1); # (INTEGER-LENGTH low)
      var uintL l2 = I_integer_length(value2); # (INTEGER-LENGTH high)
      l = (l1>l2 ? l1 : l2) + 1;
      decoded->kind = eltype_is;
    }
    eltype_size = fixnum(l);
  }
 eltype_integer:
  # check eltype_size:
  if (!(posfixnump(eltype_size) && !eq(eltype_size,Fixnum_0)
        && ((oint_data_len < log2_intDsize+intWCsize)
           # [when oint_data_len <= log2(intDsize)+intWCsize-1 always
           #  eltype_size < 2^oint_data_len < intDsize*(2^intWCsize-1) ]
            || (as_oint(eltype_size) <
                as_oint(fixnum(intDsize*(uintL)(bitm(intWCsize)-1)))))))
    goto bad_eltype;
  decoded->size = posfixnum_to_L(eltype_size);
  return;
 bad_eltype:
  pushSTACK(*eltype_); pushSTACK(S(Kelement_type));
  pushSTACK(TheSubr(subr_self)->name);
  fehler(error,GETTEXT("~: illegal ~ argument ~"));
}

# evaluate the appropriate forms
#define ELTYPE_DISPATCH(decoded,ch,iu,is)                       \
  switch (decoded->kind) {                                      \
    case eltype_ch: /*CHARACTER*/               ch; break;      \
    case eltype_iu: /*(UNSIGNED-BYTE bitsize)*/ iu; break;      \
    case eltype_is: /*(SIGNED-BYTE bitsize)*/   is; break;      \
    default: NOTREACHED;                                        \
  }

# UP: Returns a canonical representation for a :ELEMENT-TYPE.
# canon_eltype(&decoded)
# > decoded: decoded eltype
# < result: either CHARACTER or ([UN]SIGNED-BYTE n)
# can trigger GC
local object canon_eltype (const decoded_el_t* decoded) {
  ELTYPE_DISPATCH(decoded,{
    return S(character);
  },{
    pushSTACK(S(unsigned_byte));
    pushSTACK(fixnum(decoded->size));
    return listof(2);
  },{
    pushSTACK(S(signed_byte));
    pushSTACK(fixnum(decoded->size));
    return listof(2);
  });
}

# UP: Check an :EXTERNAL-FORMAT argument.
# test_external_format_arg(arg)
# > arg: argument
# > subr_self: calling function
# < subr_self: unchanged
# < result: an encoding
# can trigger GC
local object test_external_format_arg (object arg) {
  if (!boundp(arg) || eq(arg,S(Kdefault)))
    return O(default_file_encoding);
  if (encodingp(arg))
    return arg;
 #ifdef UNICODE
  if (symbolp(arg) && constantp(TheSymbol(arg))
      && encodingp(Symbol_value(arg)))
    return Symbol_value(arg);
  #ifdef HAVE_GOOD_ICONV
  if (stringp(arg)) {           /* (make-encoding :charset arg) */
    pushSTACK(arg);             /* :charset */
    pushSTACK(unbound);         /* :line-terminator */
    pushSTACK(unbound);         /* :input-error-action */
    pushSTACK(unbound);         /* :output-error-action */
    pushSTACK(unbound);         /* :if-does-not-exist */
    C_make_encoding();
    return value1;
  }
  #endif
 #else
  # This is a hack to get away without an error.
  if (symbolp(arg) && eq(Symbol_package(arg),O(charset_package)))
    return O(default_file_encoding);
 #endif
  if (eq(arg,S(Kunix)) || eq(arg,S(Kmac)) || eq(arg,S(Kdos))) {
    /* (make-encoding :charset default-file-encoding :line-terminator arg) */
    pushSTACK(O(default_file_encoding)); /* :charset */
    pushSTACK(arg);             /* :line-terminator */
    pushSTACK(unbound);         /* :input-error-action */
    pushSTACK(unbound);         /* :output-error-action */
    pushSTACK(unbound);         /* :if-does-not-exist */
    C_make_encoding();
    return value1;
  }
  pushSTACK(arg);                     # TYPE-ERROR slot DATUM
  pushSTACK(O(type_external_format)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(arg); pushSTACK(S(Kexternal_format));
  pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: illegal ~ argument ~"));
}

#if defined(UNIX) || defined(EMUNIX) || defined(RISCOS)

# UP: Deletes already entered interactive Input from a Handle.
  local void clear_tty_input (Handle handle);
  #if !defined(RISCOS)
  local void clear_tty_input(handle)
    var Handle handle;
    {
      # Method 1: tcflush TCIFLUSH, see TERMIOS(3V)
      # Method 2: ioctl TCFLSH TCIFLUSH, see TERMIO(4)
      # Method 3: ioctl TIOCFLUSH FREAD, see TTCOMPAT(4)
      begin_system_call();
      #ifdef UNIX_TERM_TERMIOS
      if (!( TCFLUSH(handle,TCIFLUSH) ==0)) {
        if (!((errno==ENOTTY)||(errno==EINVAL))) { # no TTY: OK
          local bool flag = false;
          # report other Error, but only once
          if (!flag) { flag = true; OS_error(); }
        }
      }
      #endif
      #ifdef UNIX_TERM_TERMIO
      #ifdef TCIFLUSH # !RISCOS
      if (!( ioctl(handle,TCFLSH,(CADDR_T)TCIFLUSH) ==0)) {
        if (!(errno==ENOTTY)) { # no TTY: OK
          local bool flag = false;
          # report other Error, but only once
          if (!flag) { flag = true; OS_error(); }
        }
      }
      #endif
      #endif
      #ifdef UNIX_TERM_SGTTY
      #ifdef FREAD # !UNIX_MINT
      {
        var int arg = FREAD;
        if (!( ioctl(handle,TIOCFLUSH,&arg) ==0)) {
          if (!(errno==ENOTTY)) { # no TTY: OK
            local bool flag = false;
            # report other Error, but only once
            if (!flag) { flag = true; OS_error(); }
          }
        }
      }
      #endif
      #endif
      #ifdef EMUNIX
      # Eberhard Mattes says, this works only, if IDEFAULT is not set. ??
      if (!( ioctl(handle,TCFLSH,0) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); } # no TTY: OK, other Error
      }
      #endif
      end_system_call();
    }
  #else
    #define clear_tty_input(handle)
  #endif

# UP: Move the pending Output of a Handle to the destination.
  local void finish_tty_output (Handle handle);
  #if !defined(RISCOS)
  local void finish_tty_output(handle)
    var Handle handle;
    {
      # Method 1: fsync, see FSYNC(2)
      # Method 2: tcdrain, see TERMIOS(3V)
      # Method 3: ioctl TCSBRK 1, see TERMIO(4)
      # poss. Method 3: ioctl TCGETS/TCSETSW, see TERMIO(4)
      # or (almost equivalent) ioctl TIOCGETP/TIOCSETP, see TTCOMPAT(4)
      begin_system_call();
      #if !(defined(UNIX) && !defined(HAVE_FSYNC))
      if (!( fsync(handle) ==0)) {
        #ifndef UNIX_BEOS # BeOS 5 apparently does not set errno
          #if defined(UNIX_IRIX) || defined(EMUNIX)
          if (!(errno==ENOSYS))
          #endif
          #ifdef UNIX_CYGWIN32 /* for win95 and xterm/rxvt */
          if ((errno != EBADF) && (errno != EACCES))
          #endif
          if (!(errno==EINVAL))
            { OS_error(); }
        #endif
      }
      #endif
      #ifdef UNIX_TERM_TERMIOS
      if (!( TCDRAIN(handle) ==0)) {
        if (!((errno==ENOTTY)||(errno==EINVAL)))
          { OS_error(); } # no TTY: OK, report other Error
      }
      #endif
      #ifdef UNIX_TERM_TERMIO
      if (!( ioctl(handle,TCSBRK,(CADDR_T)1) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); }
      }
      #endif
      #if defined(UNIX_TERM_TERMIOS) && defined(TCGETS) && defined(TCSETSW)
      {
        var struct termios term_parameters;
        if (!(   ( ioctl(handle,TCGETS,&term_parameters) ==0)
              && ( ioctl(handle,TCSETSW,&term_parameters) ==0))) {
          if (!((errno==ENOTTY)||(errno==EINVAL)))
            { OS_error(); } # no TTY: OK, report other Error
        }
      }
      #endif
      #ifdef EMUNIX
      {
        var struct termio term_parameters;
        if (!(   ( ioctl(handle,TCGETA,&term_parameters) ==0)
              && ( ioctl(handle,TCSETAW,&term_parameters) ==0))) {
          if (!(errno==ENOTTY)) { OS_error(); }
        }
      }
      #endif
      #if 0 # Caution: This should cause FINISH-OUTPUT and CLEAR-INPUT!
      {
        var struct sgttyb tty_parameters;
        if (!(   ( ioctl(handle,TIOCGETP,&tty_parameters) ==0)
              && ( ioctl(handle,TIOCSETP,&tty_parameters) ==0))) {
          if (!(errno==ENOTTY)) { OS_error(); }
        }
      }
      #endif
      end_system_call();
    }
  #else
    #define finish_tty_output(handle)
  #endif

# UP: Move the pending Output of a Handle to the destination.
  local void force_tty_output (Handle handle);
  #if !((defined(UNIX) && !defined(HAVE_FSYNC)) || defined(RISCOS))
  local void force_tty_output(handle)
    var Handle handle;
    {
      # Method: fsync, see FSYNC(2)
      begin_system_call();
      if (!( fsync(handle) ==0)) {
        #ifndef UNIX_BEOS # BeOS 5 apparently does not set errno
          #if defined(UNIX_IRIX) || defined(EMUNIX)
          if (!(errno==ENOSYS))
          #endif
          #ifdef UNIX_CYGWIN32 /* for win95 and xterm/rxvt */
          if ((errno != EBADF) && (errno != EACCES))
          #endif
          if (!(errno==EINVAL))
            { OS_error(); }
        #endif
      }
      end_system_call();
    }
  #else
    #define force_tty_output(handle)
  #endif

# UP: Deletes the pending Output of a Handle.
  local void clear_tty_output (Handle handle);
  #if !(defined(EMUNIX) || defined(RISCOS))
  local void clear_tty_output(handle)
    var Handle handle;
    {
      # Method 1: tcflush TCOFLUSH, see TERMIOS(3V)
      # Method 2: ioctl TCFLSH TCOFLUSH, see TERMIO(4)
      # Method 3: ioctl TIOCFLUSH FWRITE, see TTCOMPAT(4)
      begin_system_call();
      #ifdef UNIX_TERM_TERMIOS
      if (!( TCFLUSH(handle,TCOFLUSH) ==0)) {
        #ifdef UNIX_IRIX
        if (!(errno==ENOSYS))
        #endif
        if (!((errno==ENOTTY)||(errno==EINVAL)))
          { OS_error(); } # no TTY: OK, report other Error
      }
      #endif
      #ifdef UNIX_TERM_TERMIO
      #ifdef TCOFLUSH # !RISCOS
      if (!( ioctl(handle,TCFLSH,(CADDR_T)TCOFLUSH) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); } # no TTY: OK, report other Error
      }
      #endif
      #endif
      #ifdef UNIX_TERM_SGTTY
      #ifdef FWRITE # !UNIX_MINT
      {
        var int arg = FWRITE;
        if (!( ioctl(handle,TIOCFLUSH,&arg) ==0)) {
          if (!(errno==ENOTTY)) { OS_error(); } # no TTY: OK, report other Error
        }
      }
      #endif
      #endif
      end_system_call();
    }
  #else
    #define clear_tty_output(handle)
  #endif

#endif

#if defined(WIN32_NATIVE)

# UP: Deletes already entered interactive Input from a Handle.
local void clear_tty_input (Handle handle) {
  begin_system_call();
  # Maybe it's a serial communication.
  if (!PurgeComm(handle,PURGE_RXABORT|PURGE_RXCLEAR)) {
    if (!(GetLastError()==ERROR_INVALID_HANDLE
          || GetLastError()==ERROR_INVALID_FUNCTION))
      { OS_error(); }
  }
  # Maybe it's a console.
  if (!FlushConsoleInputBuffer(handle)) {
    if (!(GetLastError()==ERROR_INVALID_HANDLE))
      { OS_error(); }
  }
  end_system_call();
}

# UP: Move the pending Output of a Handle to the destination.
  local void finish_tty_output (Handle handle);
  # Maybe call WaitCommEvent with argument EV_TXEMPTY ?
  #define finish_tty_output(handle)

# UP: Move the pending Output of a Handle to the destination.
  local void force_tty_output (Handle handle);
  #define force_tty_output(handle)  finish_tty_output(handle)

# UP: Deletes the pending Output of a Handle.
local void clear_tty_output (Handle handle) {
  begin_system_call();
  # Maybe it's a serial communication.
  if (!PurgeComm(handle,PURGE_TXABORT|PURGE_TXCLEAR)) {
    if (!(GetLastError()==ERROR_INVALID_HANDLE
          || GetLastError()==ERROR_INVALID_FUNCTION))
      { OS_error(); }
  }
  end_system_call();
}

#endif

#if defined(AMIGAOS)

# UP: Deletes already entered interactive Input from a Handle.
  local void clear_tty_input (Handle handle);
  #define clear_tty_input(handle)

# UP: Move the pending Output of a Handle to the destination.
  local void finish_tty_output (Handle handle);
  # We cannot do anything, because we are not allowed to close the handle and
  # we do not have fsync().
  #define finish_tty_output(handle)

# UP: Move the pending Output of a Handle to the destination.
  local void force_tty_output (Handle handle);
  #define force_tty_output(handle)  finish_tty_output(handle)

# UP: Deletes the pending Output of a Handle.
  local void clear_tty_output (Handle handle);
  # Nothing to do.
  #define clear_tty_output(handle)

#endif

# UP: Determines, if a Handle refers to a (static) File.
# regular_handle_p(handle)
# > handle: Handle of the opened File
# < result: true if it is a (static) File
local bool regular_handle_p (Handle handle) {
 #if defined(UNIX)
  var struct stat statbuf;
  begin_system_call();
  if (!( fstat(handle,&statbuf) ==0)) { OS_error(); }
  end_system_call();
  return (S_ISREG(statbuf.st_mode) || S_ISBLK(statbuf.st_mode) ? true : false);
 #endif
 #if defined(MSDOS) || defined(RISCOS)
  var struct stat statbuf;
  begin_system_call();
  if (!( fstat(handle,&statbuf) ==0)) { OS_error(); }
  end_system_call();
  return (S_ISREG(statbuf.st_mode) ? true : false);
 #endif
 #ifdef AMIGAOS
  var LONG not_regular_p;
  begin_system_call();
  not_regular_p = IsInteractive(handle); # treatment of non-interactive, non-regular Files??
  end_system_call();
  return !not_regular_p;
 #endif
 #ifdef WIN32_NATIVE
  var DWORD filetype;
  begin_system_call();
  filetype = GetFileType(handle);
  end_system_call();
  return (filetype == FILE_TYPE_DISK);
 #endif
}


# Channel-Streams
# ===============

# Channel streams are a common framework which perform their input/output
# via a channel from the operating system. Encompasses: terminal stream,
# file stream, pipe stream, socket stream.

# Because the input side has some non-GCed fields, all channel streams must
# have the same number of GCed fields.

# Fields used for both the input side and the output side:

  # define strm_eltype   strm_other[0] # CHARACTER or ([UN]SIGNED-BYTE n)

  # define strm_encoding strm_other[1] # an Encoding
                                       # (used if eltype = CHARACTER only)

  #define strm_bitbuffer strm_other[2] # (used if eltype /= CHARACTER only)

  #define strm_buffer    strm_other[3] # (used by buffered streams only)

# Fields used for the input side only:

  #define strm_isatty    strm_other[3] # /=NIL or NIL, depending on whether
                                       # the input channel is a tty handle and
                                       # therefore needs special treatment in
                                       # the low_listen function on some OSes
                                       # (used by unbuffered streams only)
  #define strm_ichannel  strm_other[4] # the input channel,
                                       # an encapsulated handle, or, on
                                       # WIN32_NATIVE, an encapsulated SOCKET

# Fields used for the output side only:

  #define strm_ochannel  strm_other[5] # the output channel,
                                       # an encapsulated handle, or, on
                                       # WIN32_NATIVE, an encapsulated SOCKET

# Fields reserved for the specialized stream:

  #define strm_field1    strm_other[6]
  #define strm_field2    strm_other[7]

# Binary fields start here.
  #define strm_channel_extrafields  strm_other[8]
#define strm_channel_len  (strm_len+8)

# Additional binary (not GCed) fields:
typedef struct strm_channel_extrafields_t {
  bool buffered;                       # false for unbuffered streams,
                                       # true for buffered streams
  uintL bitsize;                       # If the element-type is ([UN]SIGNED-BYTE n):
                                       #   n = number of bits per unit,
                                       #   >0, <intDsize*uintWC_max.
                                       # If the element-type is CHARACTER: 0.
  void (* low_close) (object stream, object handle);
  # Fields used if the element-type is CHARACTER:
  uintL lineno;                        # line number during read, >0
  #if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
  iconv_t iconvdesc;                   # input conversion descriptor and state
  iconv_t oconvdesc;                   # output conversion descriptor and state
  #endif
} strm_channel_extrafields_t;

# Accessors.
#define ChannelStream_eltype(stream)  TheStream(stream)->strm_eltype
#define ChannelStream_isatty(stream)  TheStream(stream)->strm_isatty
#define ChannelStream_ichannel(stream)  TheStream(stream)->strm_ichannel
#define ChannelStream_ochannel(stream)  TheStream(stream)->strm_ochannel
#define ChannelStream_buffered(stream)   ((strm_channel_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->buffered
#define ChannelStream_bitsize(stream)   ((strm_channel_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->bitsize
#define ChannelStreamLow_close(stream)   ((strm_channel_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_close
#define ChannelStream_lineno(stream)   ((strm_channel_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->lineno
#if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
#define ChannelStream_iconvdesc(stream)   ((strm_channel_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->iconvdesc
#define ChannelStream_oconvdesc(stream)   ((strm_channel_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->oconvdesc
#endif

# Additional binary (not GCed) fields, used by unbuffered streams only:
typedef struct strm_unbuffered_extrafields_t {
  strm_channel_extrafields_t _parent;
  # The low_... operations operate on bytes only, and independently of the
  # stream's element type. They cannot cause GC.
  # Fields used for the input side only:
  sintL        (* low_read)        (object stream);
  signean      (* low_listen)      (object stream);
  bool         (* low_clear_input) (object stream);
  uintB*       (* low_read_array)  (object stream, uintB* byteptr, uintL len);
  sintL status;                        # -1 means EOF reached
                                       #  0 means unknown, bytebuf invalid
                                       # >0 means the number of valid bytes in
                                       #    bytebuf, to be consumed
  uintB bytebuf[max_bytes_per_chart];  # the last bytes read
                                       # but not yet consumed
  #ifdef AMIGAOS
  LONG rawp;                           # current mode: 0 = CON, 1 = RAW
  #endif
   # For general interoperability with Win32 systems, we recognize all possible
   # line-terminators: LF, CR/LF and CR, independently of strm_encoding. This
   # is because, when confronted to Unix-style text files (eol = LF), some
   # Microsoft editors insert new lines with eol = CR/LF, while other Microsoft
   # editors insert new lines with eol = CR. Java learned the lesson and
   # understands all three line-terminators. So do we.
  bool ignore_next_LF : 8;             # true after reading a CR
  # Fields used for the output side only:
  void         (* low_write)         (object stream, uintB b);
  const uintB* (* low_write_array)   (object stream, const uintB* byteptr, uintL len);
  void         (* low_finish_output) (object stream);
  void         (* low_force_output)  (object stream);
  void         (* low_clear_output)  (object stream);
} strm_unbuffered_extrafields_t;

# Accessors.
#define UnbufferedStreamLow_read(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_read
#define UnbufferedStreamLow_listen(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_listen
#define UnbufferedStreamLow_clear_input(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_clear_input
#define UnbufferedStreamLow_read_array(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_read_array
#define UnbufferedStream_status(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->status
#define UnbufferedStream_bytebuf(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->bytebuf
#ifdef AMIGAOS
#define UnbufferedStream_rawp(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->rawp
#endif
#define UnbufferedStream_ignore_next_LF(stream)   ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->ignore_next_LF
#define UnbufferedStreamLow_write(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_write
#define UnbufferedStreamLow_write_array(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_write_array
#define UnbufferedStreamLow_finish_output(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_finish_output
#define UnbufferedStreamLow_force_output(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_force_output
#define UnbufferedStreamLow_clear_output(stream)  ((strm_unbuffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_clear_output

# Error message after user interrupt.
# fehler_interrupt();
# > subr_self: calling function
nonreturning_function(local, fehler_interrupt, (void)) {
  pushSTACK(TheSubr(subr_self)->name);
  fehler(interrupt_condition,GETTEXT("~: Ctrl-C: User break"));
}

# General Subroutines
# ===================

# saving_errno(statement) -- execute a statement, but save the errno during it
# OS_error_saving_errno(statement) -- ... then signal the error
#ifdef WIN32
  #define saving_errno(statement)  \
    do { var int _olderrno = GetLastError(); statement; SetLastError(_olderrno); } while(0)
  #define OS_error_saving_errno(statement)  \
    do { var int _olderrno = GetLastError(); statement; SetLastError(_olderrno); OS_error(); } while(0)
#else
  #define saving_errno(statement)  \
    do { var int _olderrno = errno; statement; errno = _olderrno; } while(0)
  #define OS_error_saving_errno(statement)  \
    do { var int _olderrno = errno; statement; errno = _olderrno; OS_error(); } while(0)
#endif

# iconv-based encodings
# ---------------------

# Here enc_charset is a simple-string, not a symbol. The system decides
# which encodings are available, and there is no API for getting them all.

#if defined(UNICODE) && defined(HAVE_GOOD_ICONV)

# Our internal encoding is UCS-4 with platform dependent endianness.
#ifdef GNU_LIBICONV
  #define CLISP_INTERNAL_CHARSET  "UCS-4-INTERNAL"
#else
  #if (__GLIBC__ > 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ >= 2))
    # glibc >= 2.2 also has UCS-4BE, UCS-4LE but WCHAR_T is more efficient.
    #define CLISP_INTERNAL_CHARSET  "WCHAR_T"
  #elif defined(UNIX_HPUX) && BIG_ENDIAN_P
    #define CLISP_INTERNAL_CHARSET  "ucs4"
  #else
    #if BIG_ENDIAN_P
      #define CLISP_INTERNAL_CHARSET  "UCS-4"
    #else
      #define CLISP_INTERNAL_CHARSET  "UCS-4"  # FIXME: This is probably wrong
    #endif
  #endif
#endif

# min. bytes per character = 1
# max. bytes per character unknown, assume it's <= max_bytes_per_chart

global uintL iconv_mblen (object encoding, const uintB* src, const uintB* srcend);
global void iconv_mbstowcs (object encoding, object stream, const uintB* *srcp, const uintB* srcend, chart* *destp, chart* destend);
global uintL iconv_wcslen (object encoding, const chart* src, const chart* srcend);
global void iconv_wcstombs (object encoding, object stream, const chart* *srcp, const chart* srcend, uintB* *destp, uintB* destend);
global object iconv_range (object encoding, uintL start, uintL end, uintL maxintervals);

# Error, when a character cannot be converted to an encoding.
# fehler_unencodable(encoding);
nonreturning_function(extern, fehler_unencodable, (object encoding, chart ch));

# Avoid annoying warning caused by a wrongly standardized iconv() prototype.
#ifdef GNU_LIBICONV
  #undef iconv
  #define iconv(cd,inbuf,inbytesleft,outbuf,outbytesleft) \
    libiconv(cd,(ICONV_CONST char **)(inbuf),inbytesleft,outbuf,outbytesleft)
#else
  #define iconv(cd,inbuf,inbytesleft,outbuf,outbytesleft) \
    (iconv)(cd,(ICONV_CONST char **)(inbuf),inbytesleft,outbuf,outbytesleft)
#endif

# open the iconv conversion and signal errors when necessary
# skip error when CHARSET is NULLOBJ
# begin_system_call() must be called before this!!!
# end_system_call() must be called after this!!!
local iconv_t open_iconv (const char * to_code, const char * from_code,
                          object charset) {
  var iconv_t cd = iconv_open(to_code,from_code);
  if ((cd == (iconv_t)(-1)) && (!eq(nullobj,charset))) {
    if (errno == EINVAL) {
      end_system_call();
      pushSTACK(charset);
      fehler(error,GETTEXT("unknown character set ~"));
    }
    OS_error();
  }
  return cd;
}

# check whether the charset is valid
# when CHARSET is NULLOBJ, return false instead of signalling an error
global bool check_charset (const char * code, object charset) {
  begin_system_call();
  var iconv_t cd = open_iconv(CLISP_INTERNAL_CHARSET,code,charset);
  if (cd == (iconv_t)(-1)) return false;
  if (iconv_close(cd) < 0) {
    if (eq(nullobj,charset)) return false;
    OS_error();
  }
  cd = open_iconv(code,CLISP_INTERNAL_CHARSET,charset);
  if (cd == (iconv_t)(-1)) return false;
  if (iconv_close(cd) < 0) {
    if (eq(nullobj,charset)) return false;
    OS_error();
  }
  end_system_call();
  return true;
}

# Bytes to characters.

global uintL iconv_mblen (object encoding, const uintB* src,
                          const uintB* srcend) {
  var uintL count = 0;
  #define tmpbufsize 4096
  var chart tmpbuf[tmpbufsize];
  with_sstring_0(TheEncoding(encoding)->enc_charset,Symbol_value(S(ascii)),
                 charset_asciz, {
    begin_system_call();
    var iconv_t cd = open_iconv(CLISP_INTERNAL_CHARSET,charset_asciz,
                                TheEncoding(encoding)->enc_charset);
    {
      var const char* inptr = (const char*)src;
      var size_t insize = srcend-src;
      while (insize > 0) {
        var char* outptr = (char*)tmpbuf;
        var size_t outsize = tmpbufsize*sizeof(chart);
        var size_t res = iconv(cd,&inptr,&insize,&outptr,&outsize);
        if (res == (size_t)(-1) && errno != E2BIG) {
          # At the end of a delimited string, we treat
          # EINVAL (incomplete input) like EILSEQ (conversion error)
          if (errno == EILSEQ || errno == EINVAL) {
            ASSERT(insize > 0);
            var object action = TheEncoding(encoding)->enc_towcs_error;
            if (eq(action,S(Kignore))) {
              inptr++; insize--;
            } else if (eq(action,S(Kerror))) {
              iconv_close(cd); errno = EILSEQ; OS_error();
            } else {
              outptr += sizeof(chart);
              inptr++; insize--;
            }
          } else
            OS_error_saving_errno({ iconv_close(cd); });
        }
        count += (outptr-(char*)tmpbuf);
      }
    }
    if (iconv_close(cd) < 0) { OS_error(); }
    end_system_call();
  });
  #undef tmpbufsize
  return count/sizeof(chart);
}

global void iconv_mbstowcs (object encoding, object stream,
                            const uintB* *srcp, const uintB* srcend,
                            chart* *destp, chart* destend) {
  var const char* inptr = (const char*)*srcp;
  var size_t insize = srcend-*srcp;
  var char* outptr = (char*)*destp;
  var size_t outsize = (char*)destend-(char*)*destp;
  if (eq(stream,nullobj)) {
    # Standalone call, must be consistent with iconv_mblen:
    with_sstring_0(TheEncoding(encoding)->enc_charset,Symbol_value(S(ascii)),
                   charset_asciz, {
      begin_system_call();
      var iconv_t cd = open_iconv(CLISP_INTERNAL_CHARSET,charset_asciz,
                                  TheEncoding(encoding)->enc_charset);
      while (insize > 0 && outsize > 0) {
        var size_t res = iconv(cd,&inptr,&insize,&outptr,&outsize);
        if (res == (size_t)(-1)) {
          # At the end of a delimited string, we treat
          # EINVAL (incomplete input) like EILSEQ (conversion error)
          if (errno == EILSEQ || errno == EINVAL) {
            ASSERT(insize > 0);
            var object action = TheEncoding(encoding)->enc_towcs_error;
            if (eq(action,S(Kignore))) {
              inptr++; insize--;
            } else if (eq(action,S(Kerror))) {
              iconv_close(cd); errno = EILSEQ; OS_error();
            } else {
              if (outsize < sizeof(chart))
                break;
              *(chart*)outptr = char_code(action);
              outptr += sizeof(chart); outsize -= sizeof(chart);
              inptr++; insize--;
            }
          } else
            OS_error_saving_errno({ iconv_close(cd); });
        }
      }
      if (iconv_close(cd) < 0) { OS_error(); }
      end_system_call();
      ASSERT(insize == 0 && outsize == 0);
    });
  } else {
    # Called from a channel-stream.
    var iconv_t cd = ChannelStream_iconvdesc(stream);
    begin_system_call();
    while (insize > 0) {
      var size_t res = iconv(cd,&inptr,&insize,&outptr,&outsize);
      if (res == (size_t)(-1)) {
        if (errno == EINVAL) # incomplete input?
          break;
        else if (errno == E2BIG) # output buffer full?
          break;
        else if (errno == EILSEQ) {
          ASSERT(insize > 0);
          var object action = TheEncoding(encoding)->enc_towcs_error;
          if (eq(action,S(Kignore))) {
            inptr++; insize--;
          } else if (eq(action,S(Kerror))) {
            if (inptr > (const char*)*srcp)
              break;
            OS_error();
          } else {
            if (outsize < sizeof(chart))
              break;
            *(chart*)outptr = char_code(action);
            outptr += sizeof(chart); outsize -= sizeof(chart);
            inptr++; insize--;
          }
        } else {
          OS_error();
        }
      }
    }
    end_system_call();
  }
  *srcp = (const uintB*)inptr;
  *destp = (chart*)outptr;
}

# Characters to bytes.

global uintL iconv_wcslen (object encoding, const chart* src,
                           const chart* srcend) {
  var uintL count = 0;
  #define tmpbufsize 4096
  var uintB tmpbuf[tmpbufsize];
  with_sstring_0(TheEncoding(encoding)->enc_charset,Symbol_value(S(ascii)),
                 charset_asciz, {
    begin_system_call();
    var iconv_t cd = open_iconv(charset_asciz,CLISP_INTERNAL_CHARSET,
                                TheEncoding(encoding)->enc_charset);
    {
      var const char* inptr = (const char*)src;
      var size_t insize = (char*)srcend-(char*)src;
      while (insize > 0) {
        var char* outptr = (char*)tmpbuf;
        var size_t outsize = tmpbufsize;
        var size_t res = iconv(cd,&inptr,&insize,&outptr,&outsize);
        if (res == (size_t)(-1) && errno != E2BIG) {
          if (errno == EILSEQ) { # invalid input?
            ASSERT(insize >= sizeof(chart));
            var object action = TheEncoding(encoding)->enc_tombs_error;
            if (eq(action,S(Kignore))) {
              inptr += sizeof(chart); insize -= sizeof(chart);
            } else if (uint8_p(action)) {
              outptr++; outsize--;
              inptr += sizeof(chart); insize -= sizeof(chart);
            } else if (!eq(action,S(Kerror))) {
              var chart c = char_code(action);
              var const char* inptr1 = (const char*)&c;
              var size_t insize1 = sizeof(c);
              if (iconv(cd,&inptr1,&insize1,&outptr,&outsize)
                  != (size_t)(-1)) {
                inptr += sizeof(chart); insize -= sizeof(chart);
              } else {
                if (errno != EILSEQ) {
                  OS_error();
                } else {
                  end_system_call();
                  fehler_unencodable(encoding,*(const chart*)inptr);
                }
              }
            } else {
              end_system_call();
              fehler_unencodable(encoding,*(const chart*)inptr);
            }
          } else if (errno == EINVAL) { # incomplete input?
            NOTREACHED;
          } else
            OS_error_saving_errno({ iconv_close(cd); });
        }
        count += (outptr-(char*)tmpbuf);
      }
    }
    {
      var char* outptr = (char*)tmpbuf;
      var size_t outsize = tmpbufsize;
      var size_t res = iconv(cd,NULL,NULL,&outptr,&outsize);
      if (res == (size_t)(-1)) {
        if (errno == E2BIG) { # output buffer too small?
          NOTREACHED;
        } else
          OS_error_saving_errno({ iconv_close(cd); });
      }
      count += (outptr-(char*)tmpbuf);
    }
    if (iconv_close(cd) < 0) { OS_error(); }
    end_system_call();
  });
  #undef tmpbufsize
  return count;
}

global void iconv_wcstombs (object encoding, object stream,
                            const chart* *srcp,const chart* srcend,
                            uintB* *destp, uintB* destend) {
  var const char* inptr = (char*)*srcp;
  var size_t insize = (char*)srcend-(char*)*srcp;
  var char* outptr = (char*)*destp;
  var size_t outsize = destend-*destp;
  if (eq(stream,nullobj)) {
    # Standalone call, must be consistent with iconv_wcslen:
    with_sstring_0(TheEncoding(encoding)->enc_charset,Symbol_value(S(ascii)),
                   charset_asciz, {
      begin_system_call();
      var iconv_t cd = open_iconv(charset_asciz,CLISP_INTERNAL_CHARSET,
                                  TheEncoding(encoding)->enc_charset);
      while (insize > 0) {
        var size_t res = iconv(cd,&inptr,&insize,&outptr,&outsize);
        if (res == (size_t)(-1)) {
          if (errno == EILSEQ) { # invalid input?
            ASSERT(insize >= sizeof(chart));
            var object action = TheEncoding(encoding)->enc_tombs_error;
            if (eq(action,S(Kignore))) {
              inptr += sizeof(chart); insize -= sizeof(chart);
            } else if (uint8_p(action)) {
              *outptr++ = I_to_uint8(action); outsize--;
              inptr += sizeof(chart); insize -= sizeof(chart);
            } else if (!eq(action,S(Kerror))) {
              var chart c = char_code(action);
              var const char* inptr1 = (const char*)&c;
              var size_t insize1 = sizeof(c);
              if (iconv(cd,&inptr1,&insize1,&outptr,&outsize)
                  != (size_t)(-1)) {
                inptr += sizeof(chart); insize -= sizeof(chart);
              } else {
                if (errno != EILSEQ) {
                  OS_error();
                } else {
                  end_system_call();
                  fehler_unencodable(encoding,*(const chart*)inptr);
                }
              }
            } else {
              end_system_call();
              fehler_unencodable(encoding,*(const chart*)inptr);
            }
          } else if (errno == EINVAL) { # incomplete input?
            NOTREACHED;
          } else if (errno == E2BIG) { # output buffer too small?
            NOTREACHED;
          } else
            OS_error_saving_errno({ iconv_close(cd); });
        }
      }
      {
        var size_t res = iconv(cd,NULL,NULL,&outptr,&outsize);
        if (res == (size_t)(-1)) {
          if (errno == E2BIG) { # output buffer too small?
            NOTREACHED;
          } else
            OS_error_saving_errno({ iconv_close(cd); });
        }
      }
      if (iconv_close(cd) < 0) { OS_error(); }
      end_system_call();
      # Now insize == 0, and if iconv_wcslen has been used to determine
      # the destination size, then also outsize == 0.
    });
  } else {
    # Called from a channel-stream.
    var iconv_t cd = ChannelStream_oconvdesc(stream);
    begin_system_call();
    while (insize > 0) {
      var size_t res = iconv(cd,&inptr,&insize,&outptr,&outsize);
      if (res == (size_t)(-1)) {
        if (errno == EILSEQ) { # invalid input?
          ASSERT(insize >= sizeof(chart));
          var object action = TheEncoding(encoding)->enc_tombs_error;
          if (eq(action,S(Kignore))) {
            inptr += sizeof(chart); insize -= sizeof(chart);
          } else if (uint8_p(action)) {
            if (outsize == 0)
              break;
            *outptr++ = I_to_uint8(action); outsize--;
            inptr += sizeof(chart); insize -= sizeof(chart);
          } else if (!eq(action,S(Kerror))) {
            var chart c = char_code(action);
            var const char* inptr1 = (const char*)&c;
            var size_t insize1 = sizeof(c);
            if (iconv(cd,&inptr1,&insize1,&outptr,&outsize) != (size_t)(-1)) {
              inptr += sizeof(chart); insize -= sizeof(chart);
            } else {
              if (errno == E2BIG)
                break;
              else if (errno != EILSEQ) {
                OS_error();
              } else {
                if (inptr > (char*)*srcp)
                  break;
                end_system_call();
                fehler_unencodable(encoding,*(const chart*)inptr);
              }
            }
          } else {
            if (inptr > (char*)*srcp)
              break;
            end_system_call();
            fehler_unencodable(encoding,*(const chart*)inptr);
          }
        } else if (errno == EINVAL) { # incomplete input?
          NOTREACHED;
        } else if (errno == E2BIG) { # output buffer full?
          break;
        } else {
          OS_error();
        }
      }
    }
    end_system_call();
  }
  *srcp = (const chart*)inptr;
  *destp = (uintB*)outptr;
}

# Determining the range of encodable characters.
global object iconv_range (object encoding, uintL start, uintL end, uintL maxintervals) {
  var uintL count = 0; # number of intervals already on the STACK
  if (maxintervals > 0) {
    with_sstring_0(TheEncoding(encoding)->enc_charset,Symbol_value(S(ascii)),
                   charset_asciz, {
      begin_system_call();
      var iconv_t cd = open_iconv(charset_asciz,CLISP_INTERNAL_CHARSET,
                                  TheEncoding(encoding)->enc_charset);
      end_system_call();
      {
        var uintL i1;
        var uintL i2;
        var bool have_i1_i2 = false; # [i1,i2] = interval being built
        var uintL i;
        for (i = start;;) {
          # Here count < maxintervals.
          var chart ch = as_chart(i);
          var uintB buf[max_bytes_per_chart];
          var const char* inptr = (const char*)&ch;
          var size_t insize = sizeof(chart);
          var char* outptr = (char*)&buf[0];
          var size_t outsize = max_bytes_per_chart;
          begin_system_call();
          {
            var size_t res = iconv(cd,&inptr,&insize,&outptr,&outsize);
            if (res == (size_t)(-1)) {
              if (errno == EILSEQ) { # invalid input?
                end_system_call();
                # ch not encodable -> finish the interval
                if (have_i1_i2) {
                  pushSTACK(code_char(as_chart(i1)));
                  pushSTACK(code_char(as_chart(i2)));
                  check_STACK(); count++;
                  have_i1_i2 = false;
                  # If we have already produced the maximum number of intervals
                  # requested by the caller, it's of no use to search further.
                  if (count == maxintervals)
                    break;
                }
              } else if (errno == EINVAL) { # incomplete input?
                NOTREACHED;
              } else if (errno == E2BIG) { # output buffer too small?
                NOTREACHED;
              } else
                OS_error_saving_errno({ iconv_close(cd); });
            } else {
              end_system_call();
              # ch encodable -> extend the interval
              if (!have_i1_i2) {
                have_i1_i2 = true;
                i1 = i;
              }
              i2 = i;
            }
          }
          if (i == end)
            break;
          i++;
        }
        if (have_i1_i2) {
          pushSTACK(code_char(as_chart(i1)));
          pushSTACK(code_char(as_chart(i2)));
          check_STACK(); count++;
        }
      }
      begin_system_call();
      if (iconv_close(cd) < 0) { OS_error(); }
      end_system_call();
    });
  }
  return stringof(2*count);
}

#endif # UNICODE && HAVE_GOOD_ICONV

# Initializes some ChannelStream fields.
# ChannelStream_init(stream);
# > stream: channel-stream with encoding
#if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
local void ChannelStream_init (object stream) {
  var object encoding = TheStream(stream)->strm_encoding;
  if (simple_string_p(TheEncoding(encoding)->enc_charset)) {
    with_sstring_0(TheEncoding(encoding)->enc_charset,Symbol_value(S(ascii)),
                   charset_asciz, {
      var uintB flags = TheStream(stream)->strmflags;
      if (flags & strmflags_rd_B) {
        begin_system_call();
        ChannelStream_iconvdesc(stream) =
          open_iconv(CLISP_INTERNAL_CHARSET,charset_asciz,
                     TheEncoding(encoding)->enc_charset);
        end_system_call();
      } else {
        ChannelStream_iconvdesc(stream) = (iconv_t)0;
      }
      if (flags & strmflags_wr_B) {
        begin_system_call();
        ChannelStream_oconvdesc(stream) =
          open_iconv(charset_asciz,CLISP_INTERNAL_CHARSET,
                     TheEncoding(encoding)->enc_charset);
        end_system_call();
      } else {
        ChannelStream_oconvdesc(stream) = (iconv_t)0;
      }
    });
  } else {
    ChannelStream_iconvdesc(stream) = (iconv_t)0;
    ChannelStream_oconvdesc(stream) = (iconv_t)0;
  }
}
#else
  #define ChannelStream_init(stream)
#endif

# Cleans up some ChannelStream fields.
# ChannelStream_fini(stream);
#if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
local void ChannelStream_fini (object stream) {
  if (ChannelStream_iconvdesc(stream) != (iconv_t)0) {
    begin_system_call();
    if (iconv_close(ChannelStream_iconvdesc(stream)) < 0) { OS_error(); }
    end_system_call();
    ChannelStream_iconvdesc(stream) = (iconv_t)0;
  }
  if (ChannelStream_oconvdesc(stream) != (iconv_t)0) {
    begin_system_call();
    if (iconv_close(ChannelStream_oconvdesc(stream)) < 0) { OS_error(); }
    end_system_call();
    ChannelStream_oconvdesc(stream) = (iconv_t)0;
  }
}
#else
  #define ChannelStream_fini(stream)
#endif

# Closes a handle.
local void low_close_handle (object stream, object handle) {
  begin_system_call();
 #if defined(UNIX) || defined(MSDOS) || defined(AMIGAOS) || defined(RISCOS)
  if (!( CLOSE(TheHandle(handle)) ==0))
    { end_system_call(); OS_filestream_error(stream); }
 #endif
 #ifdef WIN32_NATIVE
  if (!CloseHandle(TheHandle(handle)))
    { end_system_call(); OS_filestream_error(stream); }
 #endif
  end_system_call();
}

# Subroutines for Integer-Streams
# ===============================

# For file streams with element type INTEGER ("byte files") every integer
# uses the same amount of bits. The bits and bytes are stored in little-endian
# order, because big-endian order would lead to madness. So the bit number i
# of element number j is = bit number (i+j*bitsize) of the entire bit stream
# = bit number ((i+j*bitsize) mod 8) in byte number floor((i+j*bitsize)/8).

# strm_bitbuffer is a simple-bit-vector with ceiling(bitsize/8)*8 bits,
# filled in little-endian order.

# All subroutines below get passed as arguments: bitsize (size per unit, it is
# also stored in the stream), bytesize = ceiling(bitsize/8) = number of bytes
# the bitbuffer can hold.

# Note that unbuffered file-streams cannot be of type ib or ic (too
# complicated for the moment), only type ia is supported for them.

# Subroutines for the Input side
# ------------------------------

local object bitbuff_iu_I (object bitbuffer, uintL bitsize, uintL bytesize) {
  # normalize number in bitbuffer:
  var uintB* bitbufferptr = &TheSbvector(bitbuffer)->data[bytesize-1];
  *bitbufferptr &= (bit(((bitsize-1)%8)+1)-1); # mask High byte
  var uintL count = bytesize;
  while ((!(count==0)) && (*bitbufferptr==0)) { count--; bitbufferptr--; }
  # make number:
  if # at most oint_data_len Bits ?
    ((count <= floor(oint_data_len,8))
     || ((count == floor(oint_data_len,8)+1)
         && (*bitbufferptr < bit(oint_data_len%8)))) {
    # yes -> build Fixnum >=0 :
    var uintL wert = 0;
    until (count==0) { wert = (wert<<8) | *bitbufferptr--; count--; }
    return fixnum(wert);
  }
  # no -> build Bignum >0 :
  pushSTACK(bitbuffer);
  var uintL digitcount = floor(count,(intDsize/8));
  if (((count%(intDsize/8)) > 0) || (*bitbufferptr & bit(7)))
    digitcount++;
  # As bitsize < intDsize*uintWC_max,
  # digitcount <= ceiling((bitsize+1)/intDsize) <= uintWC_max .
  var object big = allocate_bignum(digitcount,0); # new Bignum >0
  TheBignum(big)->data[0] = 0; # set highest Digit to 0
  # fill remaining Digits from right to left,
  # thereby translate sequence of Bytes into sequence of uintD:
  bitbuffer = popSTACK();
  bitbufferptr = &TheSbvector(bitbuffer)->data[0];
  #if BIG_ENDIAN_P
  {
    var uintB* bigptr = (uintB*)(&TheBignum(big)->data[digitcount]);
    dotimespL(count,count, { *--bigptr = *bitbufferptr++; } );
  }
  #else
  {
    var uintD* bigptr = &TheBignum(big)->data[digitcount];
    var uintL count2;
#define GET_NEXT_BYTE(i)  digit |= ((uintD)(*bitbufferptr++) << (8*i));
    dotimespL(count2,floor(count,intDsize/8), {
      var uintD digit = 0;
      DOCONSTTIMES(intDsize/8,GET_NEXT_BYTE); # GET_NEXT_BYTE(0..intDsize/8-1)
      *--bigptr = digit;
    });
#undef GET_NEXT_BYTE
    count2 = count % (intDsize/8);
    if (count2>0) {
      var uintL shiftcount = 0;
      var uintD digit = (uintD)(*bitbufferptr++);
      dotimesL(count2,count2-1, {
        shiftcount += 8;
        digit |= ((uintD)(*bitbufferptr++) << shiftcount);
      });
      *--bigptr = digit;
    }
  }
  #endif
  # since (intDsize/8)*(digitcount-1) <= count <= (intDsize/8)*digitcount
  # everything is filled.
  return big;
}

# UP for READ-BYTE on File-Streams of Integers, Type u :
# Returns the bytesize Bytes contained in the Bitbuffer as Integer >=0.
# can trigger GC
local object rd_by_iu_I (object stream, uintL bitsize, uintL bytesize) {
  return bitbuff_iu_I(TheStream(stream)->strm_bitbuffer,bitsize,bytesize);
}

local object bitbuff_is_I (object bitbuffer, uintL bitsize, uintL bytesize) {
  # normalize number in bitbuffer:
  var uintB* bitbufferptr = &TheSbvector(bitbuffer)->data[bytesize-1];
  var sintD sign;
  var uintL signbitnr = (bitsize-1)%8;
  var uintL count = bytesize;
  if (!(*bitbufferptr & bit(signbitnr))) {
    sign = 0;
    *bitbufferptr &= (bitm(signbitnr+1)-1); # sign-extend High byte
    # normalize, highest Bit must remain 0:
    while ((count>=2) && (*bitbufferptr==0)
           && !(*(bitbufferptr-1) & bit(7))) {
      count--; bitbufferptr--;
    }
    # build number:
    if # at most oint_data_len+1 Bits, count <2^oint_data_len ?
      ((count <= floor(oint_data_len,8))
       || ((count == floor(oint_data_len,8)+1)
           && (*bitbufferptr < bit(oint_data_len%8)))) {
      # yes -> build Fixnum >=0:
      var uintL wert = 0;
      until (count==0) { wert = (wert<<8) | *bitbufferptr--; count--; }
      return posfixnum(wert);
    }
  } else {
    sign = -1;
    *bitbufferptr |= minus_bitm(signbitnr+1); # sign-extend High byte
    # normalize, highest Bit must remain 1:
    while ((count>=2) && (*bitbufferptr==(uintB)(-1))
           && (*(bitbufferptr-1) & bit(7))) {
      count--; bitbufferptr--;
    }
    # make number:
    if # at most oint_data_len+1 Bits, count >=-2^oint_data_len ?
      ((count <= floor(oint_data_len,8))
       || ((count == floor(oint_data_len,8)+1)
           && (*bitbufferptr >= (uintB)(-bit(oint_data_len%8))))) {
      # yes -> build Fixnum <0:
      var uintL wert = (uintL)(-1);
      until (count==0) { wert = (wert<<8) | *bitbufferptr--; count--; }
      return negfixnum(-wbitm(intLsize)+(oint)wert);
    }
  }
  # make bignum:
  pushSTACK(bitbuffer);
  var uintL digitcount = ceiling(count,(intDsize/8));
  # As bitsize < intDsize*uintWC_max,
  # digitcount <= ceiling(bitsize/intDsize) <= uintWC_max .
  var object big = allocate_bignum(digitcount,(sintB)sign);
  TheBignum(big)->data[0] = sign; # set highest Word to sign
  # fill the remaining Digits from right to left,
  # thereby translate sequence of Bytes into sequence of uintD:
  bitbuffer = popSTACK();
  bitbufferptr = &TheSbvector(bitbuffer)->data[0];
  #if BIG_ENDIAN_P
  {
    var uintB* bigptr = (uintB*)(TheBignum(big)->data+digitcount);
    dotimespL(count,count, { *--bigptr = *bitbufferptr++; } );
  }
  #else
  {
    var uintD* bigptr = TheBignum(big)->data+digitcount;
    var uintL count2;
#define GET_NEXT_BYTE(i) digit |= ((uintD)(*bitbufferptr++) << (8*i));
    dotimespL(count2,floor(count,intDsize/8), {
      var uintD digit = 0;
      DOCONSTTIMES(intDsize/8,GET_NEXT_BYTE); # GET_NEXT_BYTE(0..intDsize/8-1)
      *--bigptr = digit;
    });
#undef GET_NEXT_BYTE
    count2 = count % (intDsize/8);
    if (count2>0) {
      var uintL shiftcount = 0;
      var uintD digit = (uintD)(*bitbufferptr++);
      dotimesL(count2,count2-1, {
        shiftcount += 8;
        digit |= ((uintD)(*bitbufferptr++) << shiftcount);
      });
      *--bigptr = digit ^ (sign << (shiftcount+8));
    }
  }
  #endif
  # since (intDsize/8)*(digitcount-1) < count <= (intDsize/8)*digitcount
  # everything is filled.
  return big;
}

# UP for READ-BYTE on File-Streams of Integers, Type s :
# Returns the bytesize Bytes contained in the Bitbuffer as Integer.
# can trigger GC
local object rd_by_is_I (object stream, uintL bitsize, uintL bytesize) {
  return bitbuff_is_I(TheStream(stream)->strm_bitbuffer,bitsize,bytesize);
}

# Typ rd_by_ix_I: one of these two Subroutines:
typedef object rd_by_ix_I (object stream, uintL bitsize, uintL bytesize);

# Subroutines for the Output side
# -------------------------------

# Function type of a subroutine which writes the bitbuffer contents to the
# stream.
typedef void wr_by_aux_ix (object stream, uintL bitsize, uintL bytesize);

local void bitbuff_ixu_sub (object stream, object bitbuffer,
                            uintL bitsize, uintL bytesize, object obj) {
  check_wr_int(stream,obj);
  if (!positivep(obj))
    fehler_bad_integer(stream,obj);
  # obj is an integer >=0
  # transfer obj into the bitbuffer:
  {
    var uintB* bitbufferptr = TheSbvector(bitbuffer)->data;
    var uintL count = bytesize;
    if (posfixnump(obj)) { # obj is a Fixnum >=0
      var uintL wert = posfixnum_to_L(obj);
      # check wert < 2^bitsize:
      if (!((bitsize>=oint_data_len) || (wert < bit(bitsize))))
        fehler_bad_integer(stream,obj);
      # store wert in Bitbuffer:
      until (wert==0) {
        *bitbufferptr++ = (uint8)wert; wert = wert>>8; count--;
      }
    } else { # obj is a Bignum >0
      var uintL len = (uintL)Bignum_length(obj);
      # check obj < 2^bitsize:
      if (!((floor(bitsize,intDsize) >= len)
            || ((floor(bitsize,intDsize) == len-1)
                && (TheBignum(obj)->data[0] < bit(bitsize%intDsize)))))
        fehler_bad_integer(stream,obj);
      #if BIG_ENDIAN_P
      {
        var uintB* ptr = (uintB*)&TheBignum(obj)->data[len];
        # convert Digit-Length in Byte-Length:
        len = (intDsize/8)*len;
#define CHECK_NEXT_BYTE(i)  \
   if (((uintB*)(&TheBignum(obj)->data[0]))[i] != 0) goto len_ok; len--;
        DOCONSTTIMES(intDsize/8,CHECK_NEXT_BYTE); # CHECK_NEXT_BYTE(0..intDsize/8-1)
#undef CHECK_NEXT_BYTE
      len_ok:
        # store obj in Bitbuffer:
        count = count - len;
        dotimespL(len,len, { *bitbufferptr++ = *--ptr; } );
      }
      #else
      {
        var uintD* ptr = &TheBignum(obj)->data[len];
        len--;
        count -= (intDsize/8)*len;
        dotimesL(len,len, {
          var uintD digit = *--ptr;
          doconsttimes(intDsize/8, {
            *bitbufferptr++ = (uintB)digit; digit = digit >> 8;
          });
        });
        var uintD digit = *--ptr;
        doconsttimes(intDsize/8, {
          if (digit==0) goto ok;
          *bitbufferptr++ = (uintB)digit; digit = digit >> 8;
          count--;
        });
      ok: ;
      }
    #endif
    }
    memset(bitbufferptr,0,count);
  }
}

# UP for WRITE-BYTE on File-Streams of Integers, Type u :
# Store the Object (an Integer >=0) as bytesize Bytes in the Bitbuffer.
# > stream : File-Stream for Integers, Type u
# > obj : Object to be written
# > finisher : Routine for Finalization
local void wr_by_ixu_sub (object stream, object obj, wr_by_aux_ix* finisher) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  var uintL bytesize = ceiling(bitsize,8);
  bitbuff_ixu_sub(stream,TheStream(stream)->strm_bitbuffer,
                  bitsize,bytesize,obj);
  (*finisher)(stream,bitsize,bytesize);
}

local void bitbuff_ixs_sub (object stream, object bitbuffer,
                            uintL bitsize, uintL bytesize, object obj) {
  check_wr_int(stream,obj);
  # obj is an integer
  # transfer obj into the bitbuffer:
  {
    var uintB* bitbufferptr =
      TheSbvector(TheStream(stream)->strm_bitbuffer)->data;
    var uintL count = bytesize;
    var uintL sign = (sintL)R_sign(obj);
    if (fixnump(obj)) {
      # obj is a Fixnum
      var uintL wert = fixnum_to_L(obj); # >=0 or <0, according to sign
      # check 0 <= wert < 2^(bitsize-1) resp. -2^(bitsize-1) <= wert < 0:
      wert = wert^sign;
      if (!((bitsize>oint_data_len) || (wert < bit(bitsize-1))))
        fehler_bad_integer(stream,obj);
      # store wert^sign in Bitbuffer:
      until (wert == 0) {
        *bitbufferptr++ = (uint8)(wert^sign); wert = wert>>8; count--;
      }
      memset(bitbufferptr,(uint8)sign,count);
    } else {
      # obj is a Bignum
      var uintL len = (uintL)Bignum_length(obj);
      # check -2^(bitsize-1) <= obj < 2^(bitsize-1):
      if (!((floor(bitsize,intDsize) >= len)
            || ((bitsize > intDsize*(len-1))
                && ((TheBignum(obj)->data[0] ^ (uintD)sign) <
                    bit((bitsize%intDsize)-1)))))
        fehler_bad_integer(stream,obj);
      #if BIG_ENDIAN_P
      {
        var uintB* ptr = (uintB*)&TheBignum(obj)->data[len];
        # convert Digit-Length in Byte-Length:
        len = (intDsize/8)*len;
#define CHECK_NEXT_BYTE(i)  \
   if (((uintB*)(&TheBignum(obj)->data[0]))[i] != (uintB)sign) goto len_ok; \
   len--;
        DOCONSTTIMES(intDsize/8,CHECK_NEXT_BYTE); # CHECK_NEXT_BYTE(0..intDsize/8-1)
#undef CHECK_NEXT_BYTE
      len_ok:
        # store obj in Bitbuffer:
        count = count - len;
        dotimespL(len,len, { *bitbufferptr++ = *--ptr; } );
      }
      #else
      {
        var uintD* ptr = &TheBignum(obj)->data[len];
        len--;
        count -= (intDsize/8)*len;
        dotimesL(len,len, {
          var uintD digit = *--ptr;
          doconsttimes(intDsize/8, {
            *bitbufferptr++ = (uintB)digit; digit = digit >> 8;
          });
        });
        var sintD digit = *--ptr;
        doconsttimes(intDsize/8, {
          if (digit == (sintD)sign) goto ok;
          *bitbufferptr++ = (uintB)digit; digit = digit >> 8;
          count--;
        });
      ok: ;
      }
      #endif
      memset(bitbufferptr,(uintB)sign,count);
    }
  }
}

# UP for WRITE-BYTE on File-Streams of Integers, Type s :
# Stores the Object (an Integer) as bytesize Bytes in the Bitbuffer.
# > stream : File-Stream for Integers, Type s
# > obj : Object to be written
# > finisher : Routine for Finalization
local void wr_by_ixs_sub (object stream, object obj, wr_by_aux_ix* finisher) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  var uintL bytesize = ceiling(bitsize,8);
  bitbuff_ixs_sub(stream,TheStream(stream)->strm_bitbuffer,
                  bitsize,bytesize,obj);
  (*finisher)(stream,bitsize,bytesize);
}

# Handle-Streams, Input side
# ==========================

# Low-level
# ---------

# Push a byte into bytebuf.
# UnbufferedStreamLow_push_byte(stream,b);
# Assumes 0 <= UnbufferedStream_status(stream) < max_bytes_per_chart.
#if (max_bytes_per_chart > 1) # i.e. defined(UNICODE)
  #define UnbufferedStreamLow_push_byte(stream,b)  \
     ASSERT((uintL)UnbufferedStream_status(stream) < max_bytes_per_chart);    \
     UnbufferedStream_bytebuf(stream)[UnbufferedStream_status(stream)++] = b;
#else
  #define UnbufferedStreamLow_push_byte(stream,b)  \
     UnbufferedStream_bytebuf(stream)[0] = b; \
     UnbufferedStream_status(stream) = 1;
#endif

# Push a byte to the front of bytebuf.
# UnbufferedStreamLow_pushfront_byte(stream,b);
# Assumes 0 <= UnbufferedStream_status(stream) < max_bytes_per_chart.
#if (max_bytes_per_chart > 1) # i.e. defined(UNICODE)
  #define UnbufferedStreamLow_pushfront_byte(stream,b)  \
      ASSERT((uintL)UnbufferedStream_status(stream) < max_bytes_per_chart); \
      { var uintL _count = UnbufferedStream_status(stream)++;               \
        var uintB* _ptr = &UnbufferedStream_bytebuf(stream)[_count];        \
        if (_count > 0)                                                     \
          { do { _ptr[0] = _ptr[-1]; _ptr--; } while (--_count > 0); }      \
        _ptr[0] = b;                                                        \
      }
#else
  #define UnbufferedStreamLow_pushfront_byte(stream,b)  \
      UnbufferedStream_bytebuf(stream)[0] = b; \
      UnbufferedStream_status(stream) = 1;
#endif

#ifdef UNICODE
# Push a number of bytes to the front of bytebuf.
# UnbufferedStreamLow_pushfront_bytes(stream,byteptr,bytecount);
#define UnbufferedStreamLow_pushfront_bytes(stream,byteptr,bytecount)        \
  { var uintL _push = (bytecount);                                           \
    if (_push > 0) {                                                         \
      var uintL _count = UnbufferedStream_status(stream);                    \
      ASSERT(_push + _count <= max_bytes_per_chart);                         \
      UnbufferedStream_status(stream) = _push + _count;                      \
      { var const uintB* _ptr1 = (byteptr);                                  \
        var uintB* _ptr2 = &UnbufferedStream_bytebuf(stream)[_count];        \
        if (_count > 0)                                                      \
          { do { _ptr2--; _ptr2[_push] = _ptr2[0]; } while (--_count > 0); } \
        do { *_ptr2++ = *_ptr1++; } while (--_push > 0);                     \
      }}                                                                     \
  }
#endif

# Pop a byte from bytebuf.
# UnbufferedStreamLow_pop_byte(stream,b);
# declares and assigns a value to b.
# Assumes UnbufferedStream_status(stream) > 0.
#if (max_bytes_per_chart > 1) # i.e. defined(UNICODE)
  #define UnbufferedStreamLow_pop_byte(stream,b)  \
      var uintB b = UnbufferedStream_bytebuf(stream)[0];            \
      { var uintL _count = --UnbufferedStream_status(stream);       \
        if (_count > 0)                                             \
          { var uintB* _ptr = &UnbufferedStream_bytebuf(stream)[0]; \
            do { _ptr[0] = _ptr[1]; _ptr++; } while (--_count > 0); \
      }   }
#else
  #define UnbufferedStreamLow_pop_byte(stream,b)  \
      var uintB b;                             \
      UnbufferedStream_status(stream) = 0;     \
      b = UnbufferedStream_bytebuf(stream)[0];
#endif

local sintL low_read_unbuffered_handle (object stream) {
  if (UnbufferedStream_status(stream) < 0) { # already EOF?
    return -1;
  }
  if (UnbufferedStream_status(stream) > 0) { # bytebuf contains valid bytes?
    UnbufferedStreamLow_pop_byte(stream,b); return b;
  }
  var Handle handle = TheHandle(TheStream(stream)->strm_ichannel);
  var uintB b;
 restart_it:
  #if defined(AMIGAOS)
  interruptp({ fehler_interrupt(); });
  #endif
  run_time_stop(); # hold run time clock
  begin_system_call();
  var int result = read(handle,&b,1); # try to read a byte
  end_system_call();
  run_time_restart(); # resume run time clock
  if (result<0) {
    #if !(defined(AMIGAOS) || defined(WIN32_NATIVE))
    begin_system_call();
    if (errno==EINTR) { # Interrupt (poss. by Ctrl-C) ?
      end_system_call();
      interruptp({ fehler_interrupt(); });
      goto restart_it;
    }
    #endif
    #ifdef WIN32_NATIVE
    begin_system_call();
    if (GetLastError()==ERROR_SIGINT) { # Interrupt by Ctrl-C ?
      end_system_call();
      fehler_interrupt();
    }
    #endif
    OS_error();
  }
  if (result==0) { # no byte available -> must be EOF
    UnbufferedStream_status(stream) = -1; return -1;
  } else {
    #if defined(AMIGAOS)
    # Ctrl-C is usually detected during the Read()-Call, and
    # Read() then returns "innocently" a character. We treat
    # the Ctrl-C now. Therewith the Byte is not lost, it is
    # put back to bytebuf.
    interruptp({
      UnbufferedStreamLow_push_byte(stream,b);
      fehler_interrupt();
    });
    #endif
    return b;
  }
}

local signean low_listen_unbuffered_handle (object stream) {
  if (UnbufferedStream_status(stream) < 0) # already EOF?
    return ls_eof;
  if (UnbufferedStream_status(stream) > 0) # bytebuf contains valid bytes?
    return ls_avail;
  # Method 1: select, see SELECT(2)
  # Method 2: ioctl FIONREAD, see FILIO(4)
  # Method 3: switch temporarily to non-blocking I/O and try read(),
  #           see READ(2V), FILIO(4), or
  #           see READ(2V), FCNTL(2V), FCNTL(5)
  var Handle handle = TheHandle(TheStream(stream)->strm_ichannel);
  #if defined(EMUNIX)
  {
    var struct termio oldtermio;
    var struct termio newtermio;
    begin_system_call();
    if (!( ioctl(handle,TCGETA,&oldtermio) ==0)) {
      if (!((errno==ENOTTY)||(errno==EINVAL))) {
        OS_error();
      }
    }
    newtermio = oldtermio;
    newtermio.c_lflag &= ~IDEFAULT & ~ICANON;
    if (!( ioctl(handle,TCSETA,&newtermio) ==0)) {
      if (!((errno==ENOTTY)||(errno==EINVAL))) {
        OS_error();
      }
    }
    var unsigned long bytes_ready = 0;
    var int result = ioctl(handle,FIONREAD,&bytes_ready); # enquire
    # (Starting with emx 0.8f this could also be done using select().)
    if (!( ioctl(handle,TCSETA,&oldtermio) ==0)) {
      if (!((errno==ENOTTY)||(errno==EINVAL))) {
        OS_error();
      }
    }
    end_system_call();
    if (result == 0) { # Enquiry succeeded.
      if (bytes_ready > 0)
        return ls_avail;
    }
    begin_system_call();
    if (!isatty(handle)) {
      result = eof(handle);
      if (result<0) {
        if (!(errno==ESPIPE)) { OS_error(); } # "Illegal seek error" is OK
      } else {
        end_system_call();
        if (result>0) # EOF reached?
          return ls_eof;
        else
          return ls_avail;
      }
    }
    end_system_call();
    return ls_wait;
  }
  #elif !(defined(AMIGAOS) || defined(WIN32_NATIVE))
  #if defined(HAVE_SELECT) && !defined(UNIX_BEOS)
  {
    # Use select() with readfds = singleton set {handle}
    # and timeout = zero interval.
    var fd_set handle_menge; # set of handles := {handle}
    var struct timeval zero_time; # time interval := 0
    begin_system_call();
    FD_ZERO(&handle_menge); FD_SET(handle,&handle_menge);
  restart_select:
    zero_time.tv_sec = 0; zero_time.tv_usec = 0;
    var int result = select(FD_SETSIZE,&handle_menge,NULL,NULL,&zero_time);
    if (result<0) {
      if (errno==EINTR)
        goto restart_select;
      if (!(errno==EBADF)) { OS_error(); } # UNIX_LINUX returns EBADF for files!
      end_system_call();
    } else {
      end_system_call();
      # result = number of handles in handle_menge for which read() would
      # return without blocking.
      if (result==0)
        return ls_wait;
      # result=1
      # When read() returns a result without blocking, this can also be
      # EOF! (Example: Linux and pipes.) We therefore refrain from simply
      # doing  { return ls_avail; }  and instead try methods 2 and 3.
    }
  }
  #endif
  begin_system_call();
  #ifdef HAVE_FIONREAD
  # Try to enquire the number of available bytes:
  {
    var unsigned long bytes_ready;
    if ( ioctl(handle,FIONREAD,&bytes_ready) <0) {
      # Enquiry failed, probably wasn't a file
      if (!((errno == ENOTTY)
            || (errno == EINVAL)
#ifdef ENOSYS # for UNIX_IRIX
            || (errno == ENOSYS)
#endif
            ) ) {
        OS_error();
      }
    } else {
      # Enquiry succeeded, so it was a file
      end_system_call();
      if (bytes_ready > 0)
        return ls_avail;
      #ifdef HAVE_RELIABLE_FIONREAD
      # else we have reached the file's EOF:
      UnbufferedStream_status(stream) = -1; return ls_eof;
      #endif
    }
  }
  #endif
  #if !(defined(HAVE_SELECT) && !defined(UNIX_BEOS))
  if (!nullp(TheStream(stream)->strm_isatty)) { # Terminal
    # switch to non-blocking mode, then try read():
    var uintB b;
    var int result;
  restart_read_tty:
    #ifdef FIONBIO # non-blocking I/O a la BSD 4.2
    {
      var int non_blocking_io;
      non_blocking_io = 1;
      if (!( ioctl(handle,FIONBIO,&non_blocking_io) ==0)) {
        OS_error();
      }
      result = read(handle,&b,1);
      non_blocking_io = 0;
      if (!( ioctl(handle,FIONBIO,&non_blocking_io) ==0)) {
        OS_error();
      }
    }
    #else # non-blocking I/O a la SYSV
    {
      var int fcntl_flags;
      if (( fcntl_flags = fcntl(handle,F_GETFL,0) )<0) {
        OS_error();
      }
      #ifdef O_NONBLOCK
      if ( fcntl(handle,F_SETFL,fcntl_flags|O_NONBLOCK) <0) {
        OS_error();
      }
      #else # older Unices called it O_NDELAY
      if ( fcntl(handle,F_SETFL,fcntl_flags|O_NDELAY) <0) {
        OS_error();
      }
      #endif
      result = read(handle,&b,1);
      if ( fcntl(handle,F_SETFL,fcntl_flags) <0) {
        OS_error();
      }
    }
    #endif
    if (result < 0) {
      if (errno==EINTR)
        goto restart_read_tty;
      if
       #ifdef FIONBIO
        (errno==EWOULDBLOCK) # BSD 4.2 Error-Code
       #else
        ((errno==EAGAIN) # Posix Error-Code
        #ifdef EWOULDBLOCK
         || (errno==EWOULDBLOCK)
         #endif
         )
       #endif
          return ls_wait;
      OS_error();
    }
    end_system_call();
    if (result==0) {
      return ls_wait;
    } else {
      # Stuff the read byte into the buffer, for next low_read call.
      UnbufferedStreamLow_push_byte(stream,b);
      return ls_avail;
    }
    # If this doesn't work, should use a timer 0.1 sec ??
  } else
    #endif
    # file (or pipe)
    {
      # try to read a byte:
    restart_read_other:
      var uintB b;
      var int result = read(handle,&b,1);
      if (result<0) {
        if (errno==EINTR)
          goto restart_read_other;
        OS_error();
      }
      end_system_call();
      if (result==0) {
        UnbufferedStream_status(stream) = -1; return ls_eof;
      } else {
        # Stuff the read byte into the buffer, for next low_read call.
        UnbufferedStreamLow_push_byte(stream,b);
        return ls_avail;
      }
    }
  #elif defined(AMIGAOS)
  begin_system_call();
  if (!nullp(TheStream(stream)->strm_isatty)) { # interactive
    if (WaitForChar(handle,0)) { # wait 0 usec for a byte
      end_system_call(); return ls_avail;
    } else {
      end_system_call(); return ls_wait;
    }
  } else { # not interactive
    # try to read a byte:
    var uintB b;
    var long result = Read(handle,&b,1);
    end_system_call();
    if (result<0) {
      OS_error();
    }
    if (result==0) {
      UnbufferedStream_status(stream) = -1; return ls_eof;
    } else {
      # Stuff the read byte into the buffer, for next low_read call.
      UnbufferedStreamLow_push_byte(stream,b);
      return ls_avail;
    }
  }
  #elif defined(WIN32_NATIVE)
  # This is pretty complex. To test this, create a file "listen.lisp"
  # containing the code
  #   (tagbody 1 (prin1 (listen *terminal-io*)) (sys::%sleep 0 500) (go 1))
  # and execute "lisp.exe -q -i listen.lisp" with redirected standard input.
  begin_system_call();
  switch (GetFileType(handle)) {
    case FILE_TYPE_CHAR: {
      var DWORD nevents;
      if (GetNumberOfConsoleInputEvents(handle,&nevents)) { # It's a console.
        if (nevents==0) {
          end_system_call(); return ls_wait;
        }
        var INPUT_RECORD* events =
          (INPUT_RECORD*)alloca(nevents*sizeof(INPUT_RECORD));
        var DWORD nevents_read;
        var DWORD mode;
        if (!PeekConsoleInput(handle,events,nevents,&nevents_read)) {
          OS_error();
        }
        if (nevents_read==0) {
          end_system_call(); return ls_wait;
        }
        if (!GetConsoleMode(handle,&mode)) {
          OS_error();
        }
        if (mode & ENABLE_LINE_INPUT) {
          # Look out for a Key-Down event corresponding to CR/LF.
          var DWORD i;
          for (i = 0; i < nevents_read; i++) {
            if (events[i].EventType == KEY_EVENT
                && events[i].Event.KeyEvent.bKeyDown
                && events[i].Event.KeyEvent.uAsciiChar == CR)
              # probably a byte available (except if it is Ctrl-Z)
              goto peek_one;
          }
        } else { # Look out for any Key-Down event.
          var DWORD i;
          for (i = 0; i < nevents_read; i++) {
            if (events[i].EventType == KEY_EVENT
                && events[i].Event.KeyEvent.bKeyDown
                && events[i].Event.KeyEvent.uAsciiChar != 0)
              # probably a byte available (except if it is Ctrl-Z)
              goto peek_one;
          }
        }
        end_system_call(); return ls_wait;
      } else if (!(GetLastError()==ERROR_INVALID_HANDLE)) {
        OS_error();
      }
    }
      # Not a console.
      switch (WaitForSingleObject(handle,0)) {
        case WAIT_OBJECT_0: # a byte is available, or EOF
          break;
        case WAIT_TIMEOUT:
          end_system_call(); return ls_wait;
        default:
          OS_error();
      }
      /*FALLTHROUGH*/
    case FILE_TYPE_DISK:
    default: # It's a file (or something unknown).
  peek_one: {
      # try to read a byte
      var uintB b;
      var int result = read(handle,&b,1);
      if (result<0) {
          OS_error();
      }
      end_system_call();
      if (result==0) {
        UnbufferedStream_status(stream) = -1; return ls_eof;
      } else {
        # Stuff the read byte into the buffer, for next low_read call.
        UnbufferedStreamLow_push_byte(stream,b);
        return ls_avail;
      }
    }
    case FILE_TYPE_PIPE: {
      var DWORD nbytes;
      if (PeekNamedPipe(handle,NULL,0,NULL,&nbytes,NULL)) { # input pipe
        end_system_call();
        if (nbytes > 0)
          return ls_avail;
        else
          return ls_wait;
      } else if (GetLastError()==ERROR_BROKEN_PIPE) { # EOF reached
        end_system_call();
        UnbufferedStream_status(stream) = -1;
        return ls_eof;
      } else if (GetLastError()==ERROR_ACCESS_DENIED) { # output pipe
        # => fake EOF.
        end_system_call();
        UnbufferedStream_status(stream) = -1;
        return ls_eof;
      } else { # What about sockets??
        OS_error();
      }
    }
  }
  #endif
}

local bool low_clear_input_unbuffered_handle (object stream) {
  if (nullp(TheStream(stream)->strm_isatty))
    return false; # it's a file -> nothing to do
  UnbufferedStream_status(stream) = 0; # forget about past EOF
  # Terminal (interactive on AMIGAOS)
  clear_tty_input(TheHandle(TheStream(stream)->strm_ichannel));
  # In case this didn't work, and as a general method for platforms on
  # which clear_tty_input() does nothing: read a byte, as long as listen
  # says that a byte is available.
  while (ls_avail_p(low_listen_unbuffered_handle(stream))) {
    #ifdef WIN32_NATIVE
    # Our low_listen_unbuffered_handle function, when applied to a WinNT
    # console, cannot tell when there is an LF pending after the
    # preceding CR has been eaten. Therefore be careful to set
    # UnbufferedStream_ignore_next_LF to true when we read a LF.
    var uintL c = low_read_unbuffered_handle(stream);
    if (c >= 0)
      UnbufferedStream_ignore_next_LF(stream) = (c == CR);
    #else
    low_read_unbuffered_handle(stream);
    #endif
  }
  return true;
}

local uintB* low_read_array_unbuffered_handle (object stream, uintB* byteptr,
                                               uintL len) {
  if (UnbufferedStream_status(stream) < 0) # already EOF?
    return byteptr;
  while (UnbufferedStream_status(stream) > 0) { # bytebuf contains valid bytes?
    UnbufferedStreamLow_pop_byte(stream,b);
    *byteptr++ = b;
    len--;
    if (len == 0)
      return byteptr;
  }
  var Handle handle = TheHandle(TheStream(stream)->strm_ichannel);
  run_time_stop(); # hold run time clock
  begin_system_call();
  var sintL result = full_read(handle,byteptr,len);
  end_system_call();
  run_time_restart(); # resume run time clock
  if (result<0) {
    #if !(defined(AMIGAOS) || defined(WIN32_NATIVE))
    begin_system_call();
    if (errno==EINTR) # Interrupt (poss. by Ctrl-C) ?
      interruptp({ end_system_call(); fehler_interrupt(); });
    #endif
    #ifdef WIN32_NATIVE
    begin_system_call();
    if (GetLastError()==ERROR_SIGINT) { # Interrupt by Ctrl-C ?
      end_system_call(); fehler_interrupt();
    }
    #endif
    OS_error();
  }
  byteptr += result;
  return byteptr;
}

# Integer streams
# ---------------

# UP for READ-BYTE on File-Streams of Integers, Type a :
# Fills the Bitbuffer with the next bitsize Bits.
# > stream : File-Stream for Integers, Type a
# > finisher : Routine for Finalization
# < result : read Integer or eof_value
local object rd_by_aux_iax_unbuffered (object stream, rd_by_ix_I* finisher) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  var uintL bytesize = bitsize/8;
  # transfer sufficiently many bytes into the bitbuffer
  var uintB* bitbufferptr =
    &TheSbvector(TheStream(stream)->strm_bitbuffer)->data[0];
  if (UnbufferedStreamLow_read_array(stream)(stream,bitbufferptr,bytesize)
      != bitbufferptr+bytesize)
    goto eof;
  # convert to number:
  return (*finisher)(stream,bitsize,bytesize);
 eof: # EOF reached
  return eof_value;
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type au :
local object rd_by_iau_unbuffered (object stream) {
  return rd_by_aux_iax_unbuffered(stream,&rd_by_iu_I);
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type as :
local object rd_by_ias_unbuffered (object stream) {
  return rd_by_aux_iax_unbuffered(stream,&rd_by_is_I);
}

# READ-BYTE - Pseudo-Function for Handle-Streams, Type au, bitsize = 8 :
local object rd_by_iau8_unbuffered (object stream) {
  var sintL b = UnbufferedStreamLow_read(stream)(stream);
  if (b < 0)
    return eof_value;
  return fixnum((uintB)b);
}

# READ-BYTE-ARRAY - Pseudo-Function for Handle-Streams, Type au, bitsize = 8 :
local uintL rd_by_array_iau8_unbuffered (const object* stream_,
                                         const object* bytearray_,
                                         uintL start, uintL len) {
  var object stream = *stream_;
  var uintB* startptr = &TheSbvector(*bytearray_)->data[start];
  var uintB* endptr =
    UnbufferedStreamLow_read_array(stream)(stream,startptr,len);
  return endptr-startptr;
}

# Determines, if  a Byte is available on an Unbuffered-Channel-Stream.
# listen_byte_ia8_unbuffered(stream)
# > stream: Unbuffered-Channel-Stream, Type a, bitsize = 8
# < result:   ls_avail if a byte is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no byte is available, but not because of EOF
local signean listen_byte_ia8_unbuffered (object stream) {
  return UnbufferedStreamLow_listen(stream)(stream);
}

# Character streams
# -----------------

# READ-CHAR - Pseudo-Function for Unbuffered-Channel-Streams:
local object rd_ch_unbuffered (const object* stream_) {
  var object stream = *stream_;
  if (eq(TheStream(stream)->strm_rd_ch_last,eof_value)) # already EOF?
    return eof_value;
 retry:
  var chart c;
  #ifdef UNICODE
  var object encoding = TheStream(stream)->strm_encoding;
  var uintB buf[max_bytes_per_chart];
  var uintL buflen = 0;
  loop {
    var sintL b = UnbufferedStreamLow_read(stream)(stream);
    if (b < 0)
      return eof_value;
    ASSERT(buflen < max_bytes_per_chart);
    buf[buflen++] = (uintB)b;
    var const uintB* bptr = &buf[0];
    var chart* cptr = &c;
    Encoding_mbstowcs(encoding)
      (encoding,stream,&bptr,&buf[buflen],&cptr,cptr+1);
    if (cptr == &c) {
      # Not a complete character.
      # Shift the buffer
      if (!(bptr == &buf[0])) {
        var const uintB* ptr1 = bptr;
        var uintB* ptr2 = &buf[0];
        until (ptr1 == &buf[buflen]) { *ptr2++ = *ptr1++; }
        buflen = ptr2 - &buf[0];
      }
    } else {
      # Read a complete character.
      # Move the remainder of the buffer into bytebuf.
      UnbufferedStreamLow_pushfront_bytes(stream,bptr,&buf[buflen]-bptr);
      break;
    }
  }
  #else
  {
    var sintL b = UnbufferedStreamLow_read(stream)(stream);
    if (b < 0)
      return eof_value;
    c = as_chart((uintB)b);
  }
  #endif
  if (chareq(c,ascii(NL))) {
    if (UnbufferedStream_ignore_next_LF(stream)) {
      UnbufferedStream_ignore_next_LF(stream) = false;
      goto retry;
    }
    # increment lineno:
    ChannelStream_lineno(stream) += 1;
  } else if (chareq(c,ascii(CR))) {
    UnbufferedStream_ignore_next_LF(stream) = true;
    c = ascii(NL);
    # increment lineno:
    ChannelStream_lineno(stream) += 1;
  } else {
    UnbufferedStream_ignore_next_LF(stream) = false;
  }
  return code_char(c);
}

# Determines, if a character is available on an Unbuffered-Channel-Stream.
# listen_char_unbuffered(stream)
# > stream: Unbuffered-Channel-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
local signean listen_char_unbuffered (object stream) {
  if (eq(TheStream(stream)->strm_rd_ch_last,eof_value)) # already EOF ?
    return ls_eof;
  var signean result;
  #ifdef UNICODE
  var chart c;
  var object encoding = TheStream(stream)->strm_encoding;
  var uintB buf[max_bytes_per_chart];
  var uintL buflen = 0;
  loop {
    result = UnbufferedStreamLow_listen(stream)(stream);
    if (ls_eof_p(result))
      break;
    if (!ls_avail_p(result)) {
      # Stop reading.
      # Move the buffer into bytebuf.
      UnbufferedStreamLow_pushfront_bytes(stream,&buf[0],buflen);
      break;
    }
    var sintL b = UnbufferedStreamLow_read(stream)(stream);
    if (b < 0) {
      result = ls_eof; break;
    }
    ASSERT(buflen < max_bytes_per_chart);
    buf[buflen++] = (uintB)b;
    var const uintB* bptr = &buf[0];
    var chart* cptr = &c;
    Encoding_mbstowcs(encoding)
      (encoding,stream,&bptr,&buf[buflen],&cptr,cptr+1);
    if (cptr == &c) {
      # Not a complete character.
      # Shift the buffer
      if (!(bptr == &buf[0])) {
        var const uintB* ptr1 = bptr;
        var uintB* ptr2 = &buf[0];
        until (ptr1 == &buf[buflen]) { *ptr2++ = *ptr1++; }
        buflen = ptr2 - &buf[0];
      }
    } else {
      # Read a complete character.
      if (UnbufferedStream_ignore_next_LF(stream) && chareq(c,ascii(NL))) {
        # Move the remainder of the buffer into bytebuf.
        UnbufferedStreamLow_pushfront_bytes(stream,bptr,&buf[buflen]-bptr);
        UnbufferedStream_ignore_next_LF(stream) = false;
      } else {
        # Move the buffer into bytebuf.
        UnbufferedStreamLow_pushfront_bytes(stream,&buf[0],buflen);
        UnbufferedStream_ignore_next_LF(stream) = false;
        result = ls_avail;
        break;
      }
    }
  }
  #else
 retry:
  result = UnbufferedStreamLow_listen(stream)(stream);
  if (ls_avail_p(result) && UnbufferedStream_ignore_next_LF(stream)) {
    var sintL b = UnbufferedStreamLow_read(stream)(stream);
    if (b < 0)
      return ls_eof;
    UnbufferedStream_ignore_next_LF(stream) = false;
    if (b == NL)
      goto retry;
    UnbufferedStreamLow_pushfront_byte(stream,b);
  }
  #endif
  return result;
}

# UP: Deletes already entered interactive Input from a
# Unbuffered-Channel-Stream.
# clear_input_unbuffered(stream);
# > stream: Unbuffered-Channel-Stream
# < result: true if Input was deleted, else false
local bool clear_input_unbuffered (object stream) {
  if (nullp(TheStream(stream)->strm_isatty))
    return false; # it's a file -> nothing to do
  TheStream(stream)->strm_rd_ch_last = NIL; # forget about past EOF
  #ifdef WIN32_NATIVE
  # Our low_listen_unbuffered_handle function, when applied to a WinNT
  # console, cannot tell when there is an LF pending after the
  # preceding CR has been eaten. Therefore be careful not to reset
  # UnbufferedStream_ignore_next_LF.
  #else
  UnbufferedStream_ignore_next_LF(stream) = false;
  #endif
  UnbufferedStreamLow_clear_input(stream)(stream);
  return true;
}

# READ-CHAR-ARRAY - Pseudo-Function for Unbuffered-Channel-Streams:
local uintL rd_ch_array_unbuffered (const object* stream_,
                                    const object* chararray_,
                                    uintL start, uintL len) {
  # Need a temporary buffer for CR/LF->NL translation.
  #define tmpbufsize 4096
  var chart tmpbuf[tmpbufsize];
  var object stream = *stream_;
  var uintL end = start+len;
  var uintL currindex = start;
  loop {
    var uintL remaining = end - currindex;
    if (remaining == 0)
      break;
    if (remaining > tmpbufsize)
      remaining = tmpbufsize;
    var uintL count;
    #ifdef UNICODE
    # In order to read n characters, we read n bytes. (Fewer than n bytes
    # will not suffice.) If these aren't enough bytes, the next round
    # will provide them.
    # FIXME: Could use TheEncoding(encoding)->min_bytes_per_char here.
    {
      var object encoding = TheStream(stream)->strm_encoding;
      var uintB tmptmpbuf[tmpbufsize];
      var uintB* tmptmpendptr =
        UnbufferedStreamLow_read_array(stream)(stream,tmptmpbuf,remaining);
      var const uintB* tmptmpptr = &tmptmpbuf[0];
      var chart* tmpptr = &tmpbuf[0];
      Encoding_mbstowcs(encoding)
        (encoding,stream,&tmptmpptr,tmptmpendptr,&tmpptr,&tmpbuf[tmpbufsize]);
      count = tmpptr - &tmpbuf[0];
      ASSERT(tmptmpendptr-tmptmpptr < max_bytes_per_chart);
      # Move the remainder of tmptmpbuf into bytebuf.
      UnbufferedStreamLow_pushfront_bytes(stream,tmptmpptr,tmptmpendptr-tmptmpptr);
    }
    if (count == 0) {
      # Filling the last few characters must be done one by one, in
      # order not to overrun the goal.
      pushSTACK(stream);
      do {
        var object ch = rd_ch_unbuffered(&STACK_0);
        if (eq(ch,eof_value))
          break;
        tmpbuf[count++] = char_code(ch);
        remaining--;
      } while (remaining > 0);
      skipSTACK(1);
    }
    #else
    count = UnbufferedStreamLow_read_array(stream)(stream,tmpbuf,remaining) - &tmpbuf[0];
    #endif
    if (count == 0)
      break;
    var const chart* tmpptr = &tmpbuf[0];
    do {
      var chart c = *tmpptr++;
      count--;
      if (chareq(c,ascii(NL))) {
        if (UnbufferedStream_ignore_next_LF(stream)) {
          UnbufferedStream_ignore_next_LF(stream) = false;
        } else {
          ChannelStream_lineno(stream) += 1;
          sstring_store(*chararray_,currindex++,ascii(NL));
        }
      } else if (chareq(c,ascii(CR))) {
        if (count > 0) {
          if (chareq(*tmpptr,ascii(NL))) {
            tmpptr++; count--;
          }
          UnbufferedStream_ignore_next_LF(stream) = false;
        } else {
          UnbufferedStream_ignore_next_LF(stream) = true;
        }
        ChannelStream_lineno(stream) += 1;
        sstring_store(*chararray_,currindex++,ascii(NL));
      } else {
        UnbufferedStream_ignore_next_LF(stream) = false;
        sstring_store(*chararray_,currindex++,c);
      }
    } while (count > 0);
  }
  return currindex - start;
  #undef tmpbufsize
}

# Initializes the input side fields of an unbuffered stream.
# UnbufferedHandleStream_input_init(stream);
#define UnbufferedHandleStream_input_init(stream)                       \
 { UnbufferedStreamLow_read(stream) = &low_read_unbuffered_handle;      \
   UnbufferedStreamLow_listen(stream) = &low_listen_unbuffered_handle;  \
   UnbufferedStreamLow_clear_input(stream) =                            \
     &low_clear_input_unbuffered_handle;                                \
   UnbufferedStreamLow_read_array(stream) =                             \
     &low_read_array_unbuffered_handle;                                 \
   UnbufferedHandleStream_input_init_data(stream);                      \
 }
#define UnbufferedHandleStream_input_init_data(stream)  \
    UnbufferedStream_status(stream) = 0;                \
    UnbufferedHandleStream_input_init_amiga(stream);
#ifdef AMIGAOS
  #define UnbufferedHandleStream_input_init_amiga(stream) \
    UnbufferedStream_rawp(stream) = 0;
#else
  #define UnbufferedHandleStream_input_init_amiga(stream)
#endif

# Closes a Channel-Stream.
# close_ichannel(stream);
# > stream : Channel-Stream
local void close_ichannel (object stream) {
  ChannelStreamLow_close(stream)(stream,TheStream(stream)->strm_ichannel);
  ChannelStream_fini(stream);
  if (ChannelStream_bitsize(stream) > 0) {
    ChannelStream_bitsize(stream) = 0; # delete bitsize
    TheStream(stream)->strm_bitbuffer = NIL; # free Bitbuffer
  }
}

# Handle-Streams, Output side
# ===========================

# Low-level
# ---------

local void low_write_unbuffered_handle (object stream, uintB b) {
  var Handle handle = TheHandle(TheStream(stream)->strm_ochannel);
 restart_it:
  begin_system_call();
  # Try to output the byte.
  #if !defined(AMIGAOS)
  var int result = write(handle,&b,1);
  if (result<0) {
    #if !defined(WIN32_NATIVE)
    if (errno==EINTR) { # Interrupt (poss. by Ctrl-C) ?
      end_system_call();
      interruptp({ fehler_interrupt(); });
      goto restart_it;
    }
    #endif
    OS_error();
  }
  end_system_call();
  #else # defined(AMIGAOS)
  var long result = Write(handle,&b,1);
  end_system_call();
  if (result<0) { OS_error(); }
  interruptp({ fehler_interrupt(); }); # Ctrl-C -> call Break-Loop
  #endif
  if (result==0) # not successful?
    fehler_unwritable(TheSubr(subr_self)->name,stream);
}

local const uintB* low_write_array_unbuffered_handle (object stream,
                                                      const uintB* byteptr,
                                                      uintL len) {
  var Handle handle = TheHandle(TheStream(stream)->strm_ochannel);
  begin_system_call();
  var sintL result = full_write(handle,byteptr,len);
  if (result<0) { OS_error(); }
  end_system_call();
  if (!(result==(sintL)len)) # not successful?
    fehler_unwritable(TheSubr(subr_self)->name,stream);
  return byteptr+result;
}

local void low_finish_output_unbuffered_handle (object stream) {
  finish_tty_output(TheHandle(TheStream(stream)->strm_ochannel));
}

local void low_force_output_unbuffered_handle (object stream) {
  force_tty_output(TheHandle(TheStream(stream)->strm_ochannel));
}

local void low_clear_output_unbuffered_handle (object stream) {
  clear_tty_output(TheHandle(TheStream(stream)->strm_ochannel));
}

# Integer streams
# ---------------

# UP for WRITE-BYTE on File-Streams of Integers, Type a :
# Writes the Bitbuffer-Content to the File.
local void wr_by_aux_ia_unbuffered (object stream, uintL bitsize,
                                    uintL bytesize) {
  uintB* bitbufferptr = TheSbvector(TheStream(stream)->strm_bitbuffer)->data;
  UnbufferedStreamLow_write_array(stream)(stream,bitbufferptr,bytesize);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type au :
local void wr_by_iau_unbuffered (object stream, object obj) {
  wr_by_ixu_sub(stream,obj,&wr_by_aux_ia_unbuffered);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type as :
local void wr_by_ias_unbuffered (object stream, object obj) {
  wr_by_ixs_sub(stream,obj,&wr_by_aux_ia_unbuffered);
}

# WRITE-BYTE - Pseudo-Function for Handle-Streams, Type au, bitsize = 8 :
local void wr_by_iau8_unbuffered (object stream, object obj) {
  check_wr_int(stream,obj);
  if (!(posfixnump(obj) && (posfixnum_to_L(obj) < bit(8))))
    fehler_bad_integer(stream,obj);
  UnbufferedStreamLow_write(stream)(stream,(uintB)posfixnum_to_L(obj));
}

# WRITE-BYTE-ARRAY - Pseudo-Function for Handle-Streams, Type au, bitsize = 8 :
local void wr_by_array_iau8_unbuffered (const object* stream_,
                                        const object* bytearray_,
                                        uintL start, uintL len) {
  var object stream = *stream_;
  UnbufferedStreamLow_write_array(stream)
    (stream,&TheSbvector(*bytearray_)->data[start],len);
}

# Character streams
# -----------------

# Three versions, one for each kind of line-terminator: :unix, :mac, :dos.

# WRITE-CHAR - Pseudo-Function for Unbuffered-Channel-Streams:
local void wr_ch_unbuffered_unix (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(stream,ch);
  var chart c = char_code(ch); # Code of the character
  #ifdef UNICODE
  var uintB buf[max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var const chart* cptr = &c;
  var uintB* bptr = &buf[0];
  Encoding_wcstombs(encoding)
    (encoding,stream,&cptr,cptr+1,&bptr,&buf[max_bytes_per_chart]);
  ASSERT(cptr == &c+1);
  UnbufferedStreamLow_write_array(stream)(stream,&buf[0],bptr-&buf[0]);
  #else
  UnbufferedStreamLow_write(stream)(stream,as_cint(c));
  #endif
}

# WRITE-CHAR-ARRAY - Pseudo-Function for Unbuffered-Channel-Streams:
local void wr_ch_array_unbuffered_unix (const object* stream_,
                                        const object* chararray_,
                                        uintL start, uintL len) {
  var object stream = *stream_;
  var const chart* charptr;
  unpack_sstring_alloca(*chararray_,len,start, charptr=);
  #ifdef UNICODE
  #define tmpbufsize 4096
  var const chart* endptr = charptr + len;
  var uintB tmptmpbuf[tmpbufsize*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  do {
    var uintB* bptr = &tmptmpbuf[0];
    Encoding_wcstombs(encoding)(encoding,stream,&charptr,endptr,&bptr,&tmptmpbuf[tmpbufsize*max_bytes_per_chart]);
    UnbufferedStreamLow_write_array(stream)(stream,&tmptmpbuf[0],bptr-&tmptmpbuf[0]);
  } until (charptr == endptr);
  #undef tmpbufsize
  #else
  var const chart* endptr = UnbufferedStreamLow_write_array(stream)(stream,charptr,len);
  #endif
  wr_ss_lpos(stream,endptr,len); # update Line-Position
}

# WRITE-CHAR - Pseudo-Function for Unbuffered-Channel-Streams:
local void wr_ch_unbuffered_mac (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(stream,ch);
  var chart c = char_code(ch); # Code of the character
  if (chareq(c,ascii(NL)))
    c = ascii(CR);
  #ifdef UNICODE
  var uintB buf[max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var const chart* cptr = &c;
  var uintB* bptr = &buf[0];
  Encoding_wcstombs(encoding)(encoding,stream,&cptr,cptr+1,&bptr,&buf[max_bytes_per_chart]);
  ASSERT(cptr == &c+1);
  UnbufferedStreamLow_write_array(stream)(stream,&buf[0],bptr-&buf[0]);
  #else
  UnbufferedStreamLow_write(stream)(stream,as_cint(c));
  #endif
}

# WRITE-CHAR-ARRAY - Pseudo-Function for Unbuffered-Channel-Streams:
local void wr_ch_array_unbuffered_mac (const object* stream_,
                                       const object* chararray_,
                                       uintL start, uintL len) {
  var object stream = *stream_;
  var const chart* charptr;
  unpack_sstring_alloca(*chararray_,len,start, charptr=);
  # Need a temporary buffer for NL->CR translation.
  #define tmpbufsize 4096
  var chart tmpbuf[tmpbufsize];
  #ifdef UNICODE
  var uintB tmptmpbuf[tmpbufsize*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  #endif
  var uintL remaining = len;
  do {
    var uintL n = remaining;
    if (n > tmpbufsize)
      n = tmpbufsize;
    {
      var chart* tmpptr = &tmpbuf[0];
      var uintL count;
      dotimespL(count,n, {
        var chart c = *charptr++;
        if (chareq(c,ascii(NL)))
          c = ascii(CR);
        *tmpptr++ = c;
      });
      #ifdef UNICODE
      var const chart* cptr = tmpbuf;
      var uintB* bptr = &tmptmpbuf[0];
      Encoding_wcstombs(encoding)(encoding,stream,&cptr,tmpptr,&bptr,&tmptmpbuf[tmpbufsize*max_bytes_per_chart]);
      ASSERT(cptr == tmpptr);
      UnbufferedStreamLow_write_array(stream)(stream,&tmptmpbuf[0],bptr-&tmptmpbuf[0]);
      #else
      UnbufferedStreamLow_write_array(stream)(stream,tmpbuf,n);
      #endif
    }
    remaining -= n;
  } while (remaining > 0);
  #undef tmpbufsize
  wr_ss_lpos(stream,charptr,len); # update Line-Position
}

# WRITE-CHAR - Pseudo-Function for Unbuffered-Channel-Streams:
local void wr_ch_unbuffered_dos (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(stream,ch);
  var chart c = char_code(ch); # Code of the character
  static chart const crlf[2] = { ascii(CR), ascii(LF) };
  #ifdef UNICODE
  var uintB buf[2*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var const chart* cp;
  var uintL n;
  if (chareq(c,ascii(NL))) {
    cp = crlf; n = 2;
  } else {
    cp = &c; n = 1;
  }
  var const chart* cptr = cp;
  var uintB* bptr = &buf[0];
  Encoding_wcstombs(encoding)(encoding,stream,&cptr,cp+n,&bptr,&buf[2*max_bytes_per_chart]);
  ASSERT(cptr == cp+n);
  UnbufferedStreamLow_write_array(stream)(stream,&buf[0],bptr-&buf[0]);
  #else
  if (chareq(c,ascii(NL))) {
    UnbufferedStreamLow_write_array(stream)(stream,crlf,2);
  } else {
    UnbufferedStreamLow_write(stream)(stream,as_cint(c));
  }
  #endif
}

# WRITE-CHAR-ARRAY - Pseudo-Function for Unbuffered-Channel-Streams:
local void wr_ch_array_unbuffered_dos (const object* stream_,
                                       const object* chararray_,
                                       uintL start, uintL len) {
  var object stream = *stream_;
  var const chart* charptr;
  unpack_sstring_alloca(*chararray_,len,start, charptr=);
  # Need a temporary buffer for NL->CR/LF translation.
  #define tmpbufsize 4096
  var chart tmpbuf[2*tmpbufsize];
  #ifdef UNICODE
  var uintB tmptmpbuf[2*tmpbufsize*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  #endif
  var uintL remaining = len;
  do {
    var uintL n = remaining;
    if (n > tmpbufsize)
      n = tmpbufsize;
    {
      var chart* tmpptr = &tmpbuf[0];
      var uintL count;
      dotimespL(count,n, {
        var chart c = *charptr++;
        if (chareq(c,ascii(NL))) {
          *tmpptr++ = ascii(CR); *tmpptr++ = ascii(LF);
        } else {
          *tmpptr++ = c;
        }
      });
      #ifdef UNICODE
      var const chart* cptr = tmpbuf;
      var uintB* bptr = &tmptmpbuf[0];
      Encoding_wcstombs(encoding)(encoding,stream,&cptr,tmpptr,&bptr,&tmptmpbuf[2*tmpbufsize*max_bytes_per_chart]);
      ASSERT(cptr == tmpptr);
      UnbufferedStreamLow_write_array(stream)(stream,&tmptmpbuf[0],bptr-&tmptmpbuf[0]);
      #else
      UnbufferedStreamLow_write_array(stream)(stream,tmpbuf,tmpptr-&tmpbuf[0]);
      #endif
    }
    remaining -= n;
  } while (remaining > 0);
  #undef tmpbufsize
  wr_ss_lpos(stream,charptr,len); # update Line-Position
}

# Macro: Emits a shift sequence to let the output conversion descriptor of an
# Unbuffered-Channel-Stream return to the initial state.
# oconv_unshift_output_unbuffered(stream);
# > stream: Unbuffered-Channel-Stream
#if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
  #define oconv_unshift_output_unbuffered(stream)               \
      if (ChannelStream_oconvdesc(stream) != (iconv_t)0) {      \
        oconv_unshift_output_unbuffered_(stream);               \
      }
  local void oconv_unshift_output_unbuffered_ (object stream) {
    #define tmpbufsize 4096
    var uintB tmpbuf[tmpbufsize];
    var char* outptr = (char*)tmpbuf;
    var size_t outsize = tmpbufsize;
    begin_system_call();
    var size_t res =
      iconv(ChannelStream_oconvdesc(stream),NULL,NULL,&outptr,&outsize);
    if (res == (size_t)(-1)) {
      if (errno == E2BIG) { # output buffer too small?
        NOTREACHED;
      } else {
        OS_error();
      }
    }
    end_system_call();
    var uintL outcount = outptr-(char*)tmpbuf;
    if (outcount > 0) {
      UnbufferedStreamLow_write_array(stream)(stream,&tmpbuf[0],outcount);
    }
    #undef tmpbufsize
  }
#else
  #define oconv_unshift_output_unbuffered(stream)
#endif

# UP: Move the pending Output of a Unbuffered-Channel-Stream to the destination.
# finish_output_unbuffered(stream);
# > stream: Handle-Stream
# can trigger GC
local void finish_output_unbuffered (object stream) {
  oconv_unshift_output_unbuffered(stream);
  UnbufferedStreamLow_finish_output(stream)(stream);
}

# UP: Move the pending Output of a Unbuffered-Channel-Stream to the destination.
# force_output_unbuffered(stream);
# > stream: Handle-Stream
# can trigger GC
local void force_output_unbuffered (object stream) {
  oconv_unshift_output_unbuffered(stream);
  UnbufferedStreamLow_force_output(stream)(stream);
}

# UP: Delete the pending Output of a Unbuffered-Channel-Stream.
# clear_output_unbuffered(stream);
# > stream: Handle-Stream
# can trigger GC
local void clear_output_unbuffered (object stream) {
  UnbufferedStreamLow_clear_output(stream)(stream);
}

# Initializes the output side fields of an unbuffered handle stream.
# UnbufferedHandleStream_output_init(stream);
#define UnbufferedHandleStream_output_init(stream)                      \
    { UnbufferedStreamLow_write(stream) = &low_write_unbuffered_handle; \
      UnbufferedStreamLow_write_array(stream) =                         \
        &low_write_array_unbuffered_handle;                             \
      UnbufferedStreamLow_finish_output(stream) =                       \
        &low_finish_output_unbuffered_handle;                           \
      UnbufferedStreamLow_force_output(stream) =                        \
        &low_force_output_unbuffered_handle;                            \
      UnbufferedStreamLow_clear_output(stream) =                        \
        &low_clear_output_unbuffered_handle;                            \
    }

# Closes a Channel-Stream.
# close_ochannel(stream);
# > stream : Channel-Stream
local void close_ochannel (object stream) {
  oconv_unshift_output_unbuffered(stream);
  ChannelStreamLow_close(stream)(stream,TheStream(stream)->strm_ochannel);
  ChannelStream_fini(stream);
  if (ChannelStream_bitsize(stream) > 0) {
    ChannelStream_bitsize(stream) = 0; # delete bitsize
    TheStream(stream)->strm_bitbuffer = NIL; # free Bitbuffer
  }
}


# Unbuffered File-Stream
# ======================

# UP: Checks an Element-Type for an Unbuffered-Stream
# check_unbuffered_eltype(&eltype);
# > eltype: Element-Type in decoded form
local void check_unbuffered_eltype (const decoded_el_t* eltype) {
  if (!((eltype->kind == eltype_ch) || ((eltype->size % 8) == 0))) {
    pushSTACK(canon_eltype(eltype));
    pushSTACK(S(Kelement_type));
    fehler(error,GETTEXT("Unbuffered streams need an ~ with a bit size being a multiple of 8, not ~"));
  }
}

# UP: Fills in the pseudofunctions for an unbuffered stream.
# fill_pseudofuns_unbuffered(stream,&eltype);
# > stream: stream being built up, with correct strmflags and encoding
# > eltype: Element-Type in decoded form
local void fill_pseudofuns_unbuffered (object stream,
                                       const decoded_el_t* eltype) {
  var uintB flags = TheStream(stream)->strmflags;
  stream_dummy_fill(stream);
  if (flags & strmflags_rd_B) {
    if (eltype->kind==eltype_ch) {
      TheStream(stream)->strm_rd_ch = P(rd_ch_unbuffered);
      TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_unbuffered);
    } else {
      TheStream(stream)->strm_rd_by =
        (eltype->kind == eltype_iu
         ? (eltype->size == 8
            ? P(rd_by_iau8_unbuffered)
            : P(rd_by_iau_unbuffered))
         : P(rd_by_ias_unbuffered));
      TheStream(stream)->strm_rd_by_array =
        ((eltype->kind == eltype_iu) && (eltype->size == 8)
         ? P(rd_by_array_iau8_unbuffered)
         : P(rd_by_array_dummy));
    }
  }
  if (flags & strmflags_wr_B) {
    if (eltype->kind == eltype_ch) {
      var object eol = TheEncoding(TheStream(stream)->strm_encoding)->enc_eol;
      if (eq(eol,S(Kunix))) {
        TheStream(stream)->strm_wr_ch = P(wr_ch_unbuffered_unix);
        TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_unbuffered_unix);
      } else if (eq(eol,S(Kmac))) {
        TheStream(stream)->strm_wr_ch = P(wr_ch_unbuffered_mac);
        TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_unbuffered_mac);
      } else if (eq(eol,S(Kdos))) {
        TheStream(stream)->strm_wr_ch = P(wr_ch_unbuffered_dos);
        TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_unbuffered_dos);
      } else
        NOTREACHED;
    } else {
      TheStream(stream)->strm_wr_by =
        (eltype->kind == eltype_iu
         ? (eltype->size == 8
            ? P(wr_by_iau8_unbuffered)
            : P(wr_by_iau_unbuffered))
         : P(wr_by_ias_unbuffered));
      TheStream(stream)->strm_wr_by_array =
        ((eltype->kind == eltype_iu) && (eltype->size == 8)
         ? P(wr_by_array_iau8_unbuffered)
         : P(wr_by_array_dummy));
      TheStream(stream)->strm_wr_ch = P(wr_ch_error);
      TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_error);
    }
  }
}

#define READ_P(dir)  ((dir) & bit(0)) /* readable */
#define RO_P(dir)    ((dir) & bit(1)) /* immutable */
#define WRITE_P(dir) ((dir) & bit(2)) /* writable */
#define DIRECTION_FLAGS(dir)                                                \
   (READ_P(dir) ? strmflags_rd_B : 0)  /* permits READ-CHAR, READ-BYTE */   \
 | (WRITE_P(dir) ? strmflags_wr_B : 0) /* permits WRITE-CHAR, WRITE-BYTE */ \
 | (RO_P(dir) ? strmflags_immut_B : 0) /* immutable object */

# UP: creates an Unbuffered-Channel-Stream
# make_unbuffered_stream(type,direction,&eltype,handle_tty)
# > STACK_2: Encoding
# > STACK_1: Element-Type
# > STACK_0: Handle of the opened File
# > type: stream type
# > direction: direction_t (see lispbibl.d)
# > eltype: Element-Type in decoded form
# > handle_tty: if the Handle is a tty (only necessary if direction & bit(0))
# < result: File-Handle-Stream, Handle_{input,output}_init still needs to be called
# < STACK: cleaned up
# can trigger GC
local object make_unbuffered_stream (uintB type, direction_t direction,
                                     const decoded_el_t* eltype,
                                     bool handle_tty) {
  # Flags:
  var uintB flags = DIRECTION_FLAGS(direction);
  if (eltype->kind == eltype_ch)
    flags &= strmflags_ch_B | strmflags_immut_B;
  else
    flags &= strmflags_by_B | strmflags_immut_B;
  # allocate Stream:
  var object stream = allocate_stream(flags,type,strm_channel_len,
                                      sizeof(strm_unbuffered_extrafields_t));
  # and fill:
  TheStream(stream)->strm_encoding = STACK_2;
  fill_pseudofuns_unbuffered(stream,eltype);
  UnbufferedStream_ignore_next_LF(stream) = false;
  TheStream(stream)->strm_wr_ch_lpos = Fixnum_0; # Line Position := 0
  {
    var object handle = popSTACK();
    if (READ_P(direction))
      TheStream(stream)->strm_ichannel = handle; # enter Handle
    if (WRITE_P(direction))
      TheStream(stream)->strm_ochannel = handle; # enter Handle
    if (type == strmtype_file)
      TheStream(stream)->strm_buffered_channel = handle; # enter Handle
  }
  # enter Flag isatty = (handle_tty ? T : NIL) :
  TheStream(stream)->strm_isatty = (handle_tty ? T : NIL);
  TheStream(stream)->strm_eltype = popSTACK();
  ChannelStream_buffered(stream) = false;
  ChannelStream_init(stream);
  # element-type dependent initializations:
  ChannelStream_bitsize(stream) = eltype->size;
  ChannelStream_lineno(stream) = 1; # initialize always (cf. set-stream-element-type)
  if (!(eltype->kind == eltype_ch)) {
  # File-Stream for Integers
  # allocate Bitbuffer:
    pushSTACK(stream);
    var object bitbuffer = allocate_bit_vector(Atype_Bit,eltype->size);
    stream = popSTACK();
    TheStream(stream)->strm_bitbuffer = bitbuffer;
  }
  skipSTACK(1);
  return stream;
}


# File-Stream
# ===========

# In order to not have to bestir the UNIX/AMIGADOS for each Character,
# our own Buffer is maintained.
# (This caused e.g. for the Consumption of a 408 KByte- File on an Atari
# an acceleration by a Factor of 2.7 from 500 sec to 180 sec.)

# Additional fields:
  # define strm_file_name        strm_field1   # Filename, a pathname or NIL
  # define strm_file_truename    strm_field2   # Truename, a non-logical pathname or NIL
  # define strm_buffered_channel strm_ochannel # a wrapped Handle
  # define strm_buffered_bufflen 4096 # buffer length, a power of 2, <2^16
  #define strm_buffered_buffer   strm_buffer   # our own buffer, a simple-bit-vector
                                               # with strm_buffered_bufflen bytes

# Additional binary (not GCed) fields:
typedef struct strm_buffered_extrafields_t {
  strm_channel_extrafields_t _parent;
  uintL (* low_fill)  (object stream);
  void  (* low_flush) (object stream, uintL bufflen);
  uintL buffstart;     # start position of buffer
  uintL endvalid;      # index up to which the data is known to be valid
  uintL index;         # index into buffer (>=0, <=endvalid)
  bool have_eof_p : 8; # indicates that eof is right after endvalid
  bool modified : 8;   # true if the buffer contains modified data, else false
  bool regular : 8;    # whether the handle refers to a regular file
  bool blockpositioning : 8; # whether the handle refers to a regular file
                        # and permits to position the buffer at
                        # buffstart = (sector number) * strm_buffered_bufflen
  # endvalid always indicates how much of the buffer contains data
  # have_eof_p = true indicates that the EOF is known to be at the
  #    endvalid position.  It could be there without have_eof_p being true,
  #    but it will be discovered by the next buffered_nextbyte() then
  # buffstart = (sector number) * strm_buffered_bufflen,
  #             if blockpositioning permitted.
  # The position of handle, known to the OS, set via lseek, is normally
  # (but not always!) the end of the current buffer.  More importantly,
  # before flushing the buffer to disk, the handle is lseek()ed to
  # buffstart, which ensures data is written where it should be.  This
  # then leaves the position at the correct point for subsequent reads.
# Up to now a file is considered built from bytes of 8 bits.
# Logically, it is built up from other units:
  uintL position;               # position in logical units
} strm_buffered_extrafields_t;

# More fields in file streams with element type INTEGER, type ib or ic.
typedef struct strm_i_buffered_extrafields_t {
  strm_buffered_extrafields_t _parent;
  # If bitsize is not a multiple of 8:
  uintL bitindex;               # index in the current byte, >=0, <=8
  # The buffer contains 8*index+bitindex bits. The bits are ordered in the
  # order bit0,....,bit7. If bitsize<8, the length of the file (measured in
  # bits) is stored in the first 4 bytes of the files [in little-endian order]
  # when the file is closed. The actual data then begins in the 5th byte.
  uintL eofposition;            # position of logical EOF
} strm_i_buffered_extrafields_t;

# In closed file streams only the fields `name' and `truename' are relevant.

# Accessors.
#define FileStream_name(stream)  TheStream(stream)->strm_file_name
#define FileStream_truename(stream)  TheStream(stream)->strm_file_truename
#define BufferedStream_channel(stream) TheStream(stream)->strm_buffered_channel
#define BufferedStream_buffer(stream)  TheStream(stream)->strm_buffered_buffer
#define BufferedStream_buffer_address(stream,shift) \
  (&TheSbvector(BufferedStream_buffer(stream))->data[shift])
#define BufferedStreamLow_fill(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_fill
#define BufferedStreamLow_flush(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->low_flush
#define BufferedStream_buffstart(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->buffstart
#define BufferedStream_endvalid(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->endvalid
#define BufferedStream_index(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->index
#define BufferedStream_have_eof_p(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->have_eof_p
#define BufferedStream_modified(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->modified
#define BufferedStream_regular(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->regular
#define BufferedStream_blockpositioning(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->blockpositioning
#define BufferedStream_position(stream)  \
  ((strm_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->position
#define BufferedStream_bitindex(stream)  \
  ((strm_i_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->bitindex
#define BufferedStream_eofposition(stream)  \
  ((strm_i_buffered_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)->eofposition

#define Truename_or_Self(stream)                                \
 (nullp(TheStream(stream)->strm_file_truename) ? stream :       \
  TheStream(stream)->strm_file_truename)

#define ChannelStream_ihandle(obj)                                      \
  TheHandle(ChannelStream_buffered(obj) ? BufferedStream_channel(obj)   \
            : ChannelStream_ichannel(obj))
#define ChannelStream_ohandle(obj)                                      \
  TheHandle(ChannelStream_buffered(obj) ? BufferedStream_channel(obj)   \
            : ChannelStream_ochannel(obj))

# File-Stream in general
# ======================

#if defined(UNIX) || defined(EMUNIX) || defined(RISCOS)
# Assumption: All File-Descriptors delivered by OPEN(2)  (called Handles
# here) fit in an uintW.
# Substantiation: as is generally known: 0 <= fd < getdtablesize() .
#endif

# Note about regular and non-regular files:
# - For regular files that were opened with O_RDONLY or O_RDWR but not O_WRONLY,
#   we assume that it makes sense to read a block, modify it, reposition the
#   handle back to the beginning of the block and write it back.
# - For regular files opened with O_WRONLY, we use a simple output buffer.
# - For non-regular files, we don't call handle_lseek. Therefore mixed I/O is
#   not possible. Only input-only and output-only modes are possible.

# position the Handle:
# handle_lseek(stream,handle,offset,mode,result_assignment);
# > mode: Positioning-Mode:
#         SEEK_SET  "absolute"
#         SEEK_CUR  "relative"
#         SEEK_END  "at the end"
# < result: new Position
#if defined(UNIX) || defined(EMUNIX) || defined(RISCOS)
  #define handle_lseek(stream,handle,offset,mode,result_assignment)     \
    { var sintL result = lseek(TheHandle(handle),offset,mode);          \
      if (result<0) /* error occurred? */                               \
        { end_system_call(); OS_filestream_error(stream); }             \
      unused (result_assignment result);                                \
    }
#endif
#ifdef AMIGAOS
  #define handle_lseek(stream,handle,offset,mode,result_assignment)           \
    { var uintL _offset = (offset);                                           \
      var sintL result = Seek(TheHandle(handle),_offset,mode);                \
      if (result<0) /* error occurred? */                                     \
        { end_system_call(); OS_filestream_error(stream); }                   \
      if (mode==SEEK_SET) { unused (result_assignment _offset); }             \
      else if (mode==SEEK_CUR) { unused (result_assignment result+_offset); } \
      else { /* mode==SEEK_END */                                             \
        result = Seek(TheHandle(handle),0,SEEK_CUR);                          \
        if (result<0) /* error occurred? */                                   \
          { end_system_call(); OS_filestream_error(stream); }                 \
        unused (result_assignment result);                                    \
    }}
  #define SEEK_SET  OFFSET_BEGINNING
  #define SEEK_CUR  OFFSET_CURRENT
  #define SEEK_END  OFFSET_END
#endif
#ifdef WIN32_NATIVE
  #define handle_lseek(stream,handle,offset,mode,result_assignment)           \
    { var DWORD result = SetFilePointer(TheHandle(handle),offset, NULL,mode); \
      if (result == (DWORD)(-1))                                              \
        { end_system_call(); OS_filestream_error(stream); }                   \
      unused (result_assignment result);                                      \
    }
#endif

# UP: Fills the buffer, up to strm_buffered_bufflen bytes.
# low_fill_buffered_handle(stream)
# > stream: (open) byte-based file stream
# < result: number of bytes read
local uintL low_fill_buffered_handle (object stream) {
  begin_system_call();
  var sintL result = # fill Buffer
    safe_read(TheHandle(BufferedStream_channel(stream)),
              BufferedStream_buffer_address(stream,0),
              strm_buffered_bufflen);
  end_system_call();
  if (result<0) # error occurred?
    OS_filestream_error(stream);
  return result;
}

# Functions for writing the buffer.
# low_flush_buffered_handle(stream,bufflen);
# buffered_flush(stream);
# These are called only if the buffer is modified.
# Of course, the buffer is modified only by the WRITE-BYTE/WRITE-CHAR
# operations.

# UP: Finishes the Writing-Back of the Buffers.
# low_flush_buffered_handle(stream,bufflen);
# > stream : (open) Byte-based File-Stream.
# > bufflen : Number of Bytes to be written
# < modified_flag of stream : deleted
# changed in stream: index
local void low_flush_buffered_handle (object stream, uintL bufflen) {
  begin_system_call();
  var sintL result = # write Buffer
    full_write(TheHandle(BufferedStream_channel(stream)),
               BufferedStream_buffer_address(stream,0),
               bufflen);
  if (result==bufflen) { # everything written correctly
    end_system_call(); BufferedStream_modified(stream) = false;
  } else { # not everything written
    #if defined(UNIX) || defined(EMUNIX) || defined(RISCOS)
    if (result<0) # error occurred?
      #ifdef ENOSPC
      if (!(errno == ENOSPC))
      #endif
        #ifdef EDQUOT
        if (!(errno == EDQUOT))
        #endif
          { end_system_call(); OS_filestream_error(stream); }
    #endif
    #if defined(AMIGAOS) || defined(WIN32_NATIVE)
    if (result<0) { # error occurred?
      end_system_call(); OS_filestream_error(stream);
    }
    #endif
    end_system_call();
    # Not everything was written, probably because of full disk.
    # In order to avoid inconsistencies, must close the file.
    BufferedStream_modified(stream) = false; # data is lost!
    pushSTACK(stream);
    builtin_stream_close(&STACK_0); # file close
    clr_break_sem_4(); # no more UNIX operations are active
    # Report the error.
    pushSTACK(Truename_or_Self(STACK_0)); # FILE-ERROR slot PATHNAME
    pushSTACK(STACK_(0+1)); # stream
    fehler(file_error,GETTEXT("Closed ~ because disk is full."));
  }
}

#define BufferedHandleStream_init(stream)  \
  { BufferedStreamLow_fill(stream) = &low_fill_buffered_handle;   \
    BufferedStreamLow_flush(stream) = &low_flush_buffered_handle; \
  }

# UP: Writes the modified Buffer back.
# buffered_flush(stream);
# > stream : (open) Byte-based File-Stream.
# < modified_flag of stream : deleted
# changed in stream: index
local void buffered_flush (object stream) {
  if (BufferedStream_blockpositioning(stream)) {
    begin_system_call();
    handle_lseek(stream,BufferedStream_channel(stream),
                 BufferedStream_buffstart(stream),SEEK_SET,); # positioning back
    end_system_call();
  }
  BufferedStreamLow_flush(stream)(stream,BufferedStream_endvalid(stream));
}

# UP: Positions a Byte-based File-Stream, so the next Byte can be
# read or overwritten.
# buffered_nextbyte(stream)
# > stream : (open) Byte-based File-Stream.
# < result : NULL if EOF else: Pointer to the next Byte
# changed in stream: index, endvalid, have_eof_p, buffstart
local uintB* buffered_nextbyte (object stream) {
  var sintL endvalid = BufferedStream_endvalid(stream);
  var uintL index = BufferedStream_index(stream);
  if ((endvalid == index) && !BufferedStream_have_eof_p (stream)) {
    # Buffer must be newly filled.
    if (BufferedStream_modified(stream))
      # Beforehand the Buffer must be flushed out:
      buffered_flush(stream);
    BufferedStream_buffstart(stream) += endvalid;
    var uintL result;
    if (BufferedStream_blockpositioning(stream)
        || (TheStream(stream)->strmflags & strmflags_rd_B))
      result = BufferedStreamLow_fill(stream)(stream);
    else
      result = 0;
    BufferedStream_index(stream) = index = 0;
    BufferedStream_modified(stream) = false;
    BufferedStream_endvalid(stream) = endvalid = result;
    if (result == 0)
      BufferedStream_have_eof_p(stream) = true;
  }
  if (index < endvalid)
    return BufferedStream_buffer_address(stream,index);
  else if (BufferedStream_have_eof_p(stream))
    return (uintB*)NULL; # EOF reached
  else
    NOTREACHED;
}

# UP: Prepares the writing of a Byte at EOF.
# buffered_eofbyte(stream);
# > stream : (open) Byte-based File-Stream, for which
#            currently  buffered_nextbyte(stream)==NULL  is true.
# < result : Pointer to the next (free) Byte
# changed in stream: index, endvalid, buffstart
local uintB* buffered_eofbyte (object stream) {
  # EOF.  endvalid=index.
  ASSERT(BufferedStream_have_eof_p(stream));
  if (BufferedStream_endvalid(stream) == strm_buffered_bufflen) {
    # Buffer must be filled newly. Because after that EOF will occur anyway,
    # it is sufficient, to flush the Buffer out:
    if (BufferedStream_modified(stream))
      buffered_flush(stream);
    BufferedStream_buffstart(stream) += strm_buffered_bufflen;
    BufferedStream_endvalid(stream) = 0;
    BufferedStream_index(stream) = 0; # index := 0
    BufferedStream_modified(stream) = false; # unmodified
  }
  # increase endvalid:
  BufferedStream_endvalid(stream) += 1;
  return BufferedStream_buffer_address(stream,BufferedStream_index(stream));
}

# UP: Writes a Byte to a Byte-based File-Stream.
# buffered_writebyte(stream,b);
# > stream : (open) Byteblock-based File-Stream.
# > b : Byte to be written
# changed in stream: index, endvalid, buffstart
local void buffered_writebyte (object stream, uintB b) {
  var uintB* ptr = buffered_nextbyte(stream);
  if (!(ptr == (uintB*)NULL)) {
    if (*ptr == b) # no real Modification?
      goto no_modification;
  } else {
    ptr = buffered_eofbyte(stream); # EOF -> make room for 1 Byte
  }
  # write next Byte in the Buffer:
  *ptr = b; BufferedStream_modified(stream) = true;
 no_modification:
  # increment index
  BufferedStream_index(stream) += 1;
}

# File-Stream, Byte-based (b_file)
# ===========  ==========

# error-message because of positioning behind EOF.
# fehler_position_beyond_EOF(stream);
nonreturning_function(local, fehler_position_beyond_EOF, (object stream)) {
  pushSTACK(Truename_or_Self(stream)); # FILE-ERROR slot PATHNAME
  pushSTACK(stream);
  fehler(file_error,GETTEXT("cannot position ~ beyond EOF"));
}

# UP: Positions an (open) Byte-based File-Stream to a
# specified Position.
# position_file_buffered(stream,position);
# > stream : (open) Byte-based File-Stream.
# > position : new Position
# changed in stream: index, endvalid, buffstart
local void position_file_buffered (object stream, uintL position) {
  # Is the new Position in the same Sector?
  {
    var uintL endvalid = BufferedStream_endvalid(stream);
    var uintL newindex = position - BufferedStream_buffstart(stream);
    if (newindex <= endvalid) { # yes -> only index has to be changed:
      BufferedStream_index(stream) = newindex;
      return;
    }
  }
  # poss. flush Buffer:
  if (BufferedStream_modified(stream))
    buffered_flush(stream);
  # Now modified_flag is deleted.
  if (!BufferedStream_blockpositioning(stream)) { # Positioning:
    begin_system_call();
    handle_lseek(stream,BufferedStream_channel(stream),position,SEEK_SET,);
    end_system_call();
    BufferedStream_buffstart(stream) = position;
    BufferedStream_endvalid(stream) = 0;
    BufferedStream_index(stream) = 0; # index := 0
    BufferedStream_modified(stream) = false; # unmodified
    BufferedStream_have_eof_p(stream) = false;
  } else {
    var uintL oldposition = BufferedStream_buffstart(stream) + BufferedStream_index(stream);
    # Positioning:
    {
      var uintL newposition;
      begin_system_call();
      handle_lseek(stream,BufferedStream_channel(stream),
                   floor(position,strm_buffered_bufflen)*strm_buffered_bufflen,SEEK_SET,newposition=);
      end_system_call();
      BufferedStream_buffstart(stream) = newposition;
    }
    # read Sector:
    BufferedStream_endvalid(stream) = 0;
    BufferedStream_index(stream) = 0; # index := 0
    BufferedStream_modified(stream) = false; # unmodified
    BufferedStream_have_eof_p(stream) = false;
    var uintL newindex = position % strm_buffered_bufflen; # desired Index in the Sector
    if (newindex!=0) { # Position between Sectors -> nothing needs to be read
      buffered_nextbyte(stream);
      # Now index=0.
      # set index to (position mod bufflen) , but check beforehand:
      var uintL endvalid = BufferedStream_endvalid(stream);
      # newindex must be in the valid range
      if (newindex > endvalid) {
        # Error. But first position back to the old Position:
        check_SP();
        position_file_buffered(stream,oldposition); # position back
        fehler_position_beyond_EOF(stream);
      }
      BufferedStream_index(stream) = newindex;
    }
  }
}

# UP: Reads an Array of Bytes from an (open) Byte-based
# File-Stream.
# read_byte_array_buffered(stream,byteptr,len)
# > stream : (open) Byte-based File-Stream.
# > byteptr[0..len-1] : place
# > len : > 0
# < byteptr[0..count-1] : read Bytes.
# < result: &byteptr[count] (with count = len, or count < len if EOF reached)
# changed in stream: index, endvalid, buffstart
local uintB* read_byte_array_buffered (object stream, uintB* byteptr,
                                       uintL len) {
  do {
    var uintB* ptr = buffered_nextbyte(stream);
    if (ptr == (uintB*)NULL)
      break;
    var uintL endvalid = BufferedStream_endvalid(stream);
    var uintL available = endvalid - BufferedStream_index(stream);
    if (available > len)
      available = len;
    # copy all available bytes:
    copy_mem_b(byteptr,ptr,available);
    byteptr += available;
    # increment index:
    BufferedStream_index(stream) += available;
    len -= available;
  } while (len > 0);
  return byteptr;
}

# UP: Writes an Array of Bytes to an (open) Byte-based
# File-Stream.
# write_byte_array_buffered(stream,byteptr,len)
# > stream : (open) Byte-based File-Stream.
# > byteptr[0..len-1] : Bytes to be written.
# > len : > 0
# < result: &byteptr[len]
# changed in stream: index, endvalid, buffstart
local const uintB* write_byte_array_buffered (object stream,
                                              const uintB* byteptr,
                                              uintL len) {
  var uintL remaining = len;
  var uintB* ptr;
  do { # still remaining>0 Bytes to be filed.
    ptr = buffered_nextbyte(stream);
    if (ptr == (uintB*)NULL)
      goto eof_reached;
    var uintL endvalid = BufferedStream_endvalid(stream);
    var uintL next = # as many as still fit in the Buffer or until EOF
      endvalid - BufferedStream_index(stream); # > 0 !
    if (next > remaining)
      next = remaining;
    { # copy next Bytes in the Buffer:
      var uintL count;
      dotimespL(count,next, {
        var uintB b = *byteptr++; # next Byte
        if (!(*ptr == b)) {
          *ptr = b; BufferedStream_modified(stream) = true; # in the Buffer
        }
        ptr++;
      });
    }
    remaining = remaining - next;
    # increment index
    BufferedStream_index(stream) += next;
  } while (remaining != 0);
  if (false) {
  eof_reached: # Write at EOF, endvalid = index
    do { # Still remaining>0 Bytes to file.
      var uintL next = # as many as there is still room in the Buffer
        strm_buffered_bufflen - BufferedStream_index(stream);
      if (next==0) {
        # Buffer must be filled newly. After that, EOF arrives anyway,
        # so it is sufficient to flush the buffer:
        if (BufferedStream_modified(stream))
          buffered_flush(stream);
        BufferedStream_buffstart(stream) += strm_buffered_bufflen;
        BufferedStream_endvalid(stream) = 0;
        BufferedStream_index(stream) = 0; # index := 0
        BufferedStream_modified(stream) = false; # unmodified
        # Then try again:
        next = strm_buffered_bufflen;
      }
      if (next > remaining)
        next = remaining;
      # copy the next bytes in the buffer:
      copy_mem_b(BufferedStream_buffer_address
                 (stream,BufferedStream_index(stream)),
                 byteptr,next);
      byteptr += next;
      BufferedStream_modified(stream) = true;
      remaining = remaining - next;
      # increment index and endvalid
      BufferedStream_index(stream) += next;
      BufferedStream_endvalid(stream) += next;
    } while (remaining != 0);
  }
  return byteptr;
}

# File-Stream of Characters
# ==========================

# Input side
# ----------

# READ-CHAR - Pseudo-Function for File-Streams of Characters
local object rd_ch_buffered (const object* stream_) {
  var object stream = *stream_;
  var uintB* bufferptr = buffered_nextbyte(stream);
  if (bufferptr == (uintB*)NULL) # EOF ?
    return eof_value;
  # fetch next character:
  var chart c;
  #ifdef UNICODE
  var object encoding = TheStream(stream)->strm_encoding;
  { # Does the buffer contain a complete character?
    var uintL endvalid = BufferedStream_endvalid(stream);
    var uintL available = endvalid - BufferedStream_index(stream);
    var const uintB* bptr = bufferptr;
    var chart* cptr = &c;
    Encoding_mbstowcs(encoding)
      (encoding,stream,&bptr,bufferptr+available,&cptr,&c+1);
    if (cptr == &c+1) {
      var uintL n = bptr-bufferptr;
      # increment index and position
      BufferedStream_index(stream) += n;
      BufferedStream_position(stream) += n;
    } else {
      var uintB buf[max_bytes_per_chart];
      var uintL buflen = 0;
      loop {
        ASSERT(buflen < max_bytes_per_chart);
        buf[buflen++] = *bufferptr;
        # increment index and position
        BufferedStream_index(stream) += 1;
        BufferedStream_position(stream) += 1;
        var const uintB* bptr = &buf[0];
        var chart* cptr = &c;
        Encoding_mbstowcs(encoding)(encoding,stream,&bptr,&buf[buflen],&cptr,cptr+1);
        if (cptr == &c) {
          # Not a complete character.
          # Shift the buffer
          if (!(bptr == &buf[0])) {
            var const uintB* ptr1 = bptr;
            var uintB* ptr2 = &buf[0];
            until (ptr1 == &buf[buflen]) { *ptr2++ = *ptr1++; }
            buflen = ptr2 - &buf[0];
          }
        } else {
          # Read a complete character.
          if (!(bptr == &buf[buflen])) {
            # At most one lookahead byte. Make it unread.
            ASSERT(bptr == &buf[buflen-1]);
            # decrement index and position again:
            BufferedStream_index(stream) -= 1;
            BufferedStream_position(stream) -= 1;
          }
          break;
        }
        bufferptr = buffered_nextbyte(stream);
        if (bufferptr == (uintB*)NULL)
          return eof_value;
      }
    }
  }
  #else
  c = as_chart(*bufferptr); # Character from the Buffer
  # increment index and position
  BufferedStream_index(stream) += 1;
  BufferedStream_position(stream) += 1;
  #endif
  if (chareq(c,ascii(NL))) {
    ChannelStream_lineno(stream) += 1;
  } else if (chareq(c,ascii(CR))) {
    # check next character for LF
    bufferptr = buffered_nextbyte(stream);
    # FIXME: This is wrong. It assumes an ASCII compatible encoding.
    if ((bufferptr != NULL) && chareq(as_chart(*bufferptr),ascii(LF))) {
      # increment index and position
      BufferedStream_index(stream) += 1;
      BufferedStream_position(stream) += 1;
    }
    c = ascii(NL);
    ChannelStream_lineno(stream) += 1;
  }
  return code_char(c);
}

# Determines, if a character is available on a File-Stream.
# listen_char_buffered(stream)
# > stream: File-Stream of Characters
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
local signean listen_char_buffered (object stream) {
  if (buffered_nextbyte(stream) == (uintB*)NULL)
    return ls_eof; # EOF
  # In case of UNICODE, the presence of a byte does not guarantee the
  # presence of a multi-byte character. Returning ls_avail here is
  # therefore not correct. But this doesn't matter since programs seeing
  # ls_avail will call read-char, and this will do the right thing anyway.
  return ls_avail;
}

# READ-CHAR-ARRAY - Pseudo-Function for File-Streams of Characters:
local uintL rd_ch_array_buffered (const object* stream_,
                                  const object* chararray_,
                                  uintL start, uintL len) {
  var object stream = *stream_;
  #ifdef UNICODE
  #define tmpbufsize 4096
  var uintL end = start+len;
  var uintL currindex = start;
  var object encoding = TheStream(stream)->strm_encoding;
  loop {
    var uintL startindex = currindex;
    var uintB* bufferptr = buffered_nextbyte(stream);
    if (bufferptr == (uintB*)NULL) # EOF -> finished
      break;
    { # Read as many complete characters from the buffer as possible.
      var uintL endvalid = BufferedStream_endvalid(stream);
      var uintL available = endvalid - BufferedStream_index(stream);
      var const uintB* bptr = bufferptr;
      var chart tmpbuf[tmpbufsize];
      var chart* cptr = &tmpbuf[0];
      Encoding_mbstowcs(encoding)
        (encoding,stream,&bptr,bufferptr+available,&cptr,
         &tmpbuf[end-currindex < tmpbufsize ? end-currindex : tmpbufsize]);
      if (!(cptr == &tmpbuf[0])) {
        var uintL n = bptr-bufferptr;
        # increment index and position
        BufferedStream_index(stream) += n;
        BufferedStream_position(stream) += n;
        # store the read characters
        sstring_store_array(*chararray_,currindex,tmpbuf,cptr-&tmpbuf[0]);
        currindex += cptr-&tmpbuf[0];
        stream = *stream_;
      } else {
        var uintB buf[max_bytes_per_chart];
        var uintL buflen = 0;
        loop {
          ASSERT(buflen < max_bytes_per_chart);
          buf[buflen++] = *bufferptr;
          # increment index and position
          BufferedStream_index(stream) += 1;
          BufferedStream_position(stream) += 1;
          var const uintB* bptr = &buf[0];
          var chart* cptr = &tmpbuf[0];
          Encoding_mbstowcs(encoding)(encoding,stream,&bptr,&buf[buflen],&cptr,cptr+1);
          if (cptr == &tmpbuf[0]) { # Not a complete character.
            # Shift the buffer
            if (!(bptr == &buf[0])) {
              var const uintB* ptr1 = bptr;
              var uintB* ptr2 = &buf[0];
              until (ptr1 == &buf[buflen]) { *ptr2++ = *ptr1++; }
              buflen = ptr2 - &buf[0];
            }
          } else { # Read a complete character.
            if (!(bptr == &buf[buflen])) {
              # At most one lookahead byte. Make it unread.
              ASSERT(bptr == &buf[buflen-1]);
              # decrement index and position again:
              BufferedStream_index(stream) -= 1;
              BufferedStream_position(stream) -= 1;
            }
            # store the read character
            sstring_store(*chararray_,currindex++,tmpbuf[0]);
            stream = *stream_;
            break;
          }
          bufferptr = buffered_nextbyte(stream);
          if (bufferptr == (uintB*)NULL) # EOF -> finished
            break;
        }
        if (currindex == startindex) # EOF -> finished
          break;
      }
    }
    # Now apply CR/LF->NL and CR->NL conversion to the characters
    # [startindex..currindex).
    {
      var object chararray = *chararray_;
      simple_array_to_storage(chararray);
      SstringDispatch(chararray,X, {
        var cintX* startptr = &((SstringX)TheVarobject(chararray))->data[startindex];
        var cintX* currptr = &((SstringX)TheVarobject(chararray))->data[currindex];
        const cintX* ptr1 = startptr;
        cintX* ptr2 = startptr;
        do {
          cintX c = *ptr1++;
          if (chareq(as_chart(c),ascii(NL))) {
            ChannelStream_lineno(stream) += 1;
          } else if (chareq(as_chart(c),ascii(CR))) {
            # check next character for LF
            if (ptr1 == currptr) {
              var uintB* bufferptr = buffered_nextbyte(stream);
              if ((bufferptr != NULL)
                  # FIXME: This is wrong. It assumes an ASCII compatible encoding.
                  && chareq(as_chart(*bufferptr),ascii(LF))) {
                # increment index and position
                BufferedStream_index(stream) += 1;
                BufferedStream_position(stream) += 1;
              }
            } else {
              if (chareq(as_chart(*ptr1),ascii(LF)))
                ptr1++;
            }
            c = NL;
            ChannelStream_lineno(stream) += 1;
          }
          *ptr2++ = c;
        } until (ptr1 == currptr);
        currindex = ptr2 - &((SstringX)TheVarobject(chararray))->data[0];
      });
    }
    if (currindex == end)
      break;
  }
  return currindex - start;
  #else
  var chart* startptr = &TheSstring(*chararray_)->data[start];
  var chart* charptr = startptr;
  do {
    var uintB* ptr = buffered_nextbyte(stream);
    if (ptr == (uintB*)NULL) # EOF -> finished
      break;
    var chart ch = as_chart(*ptr);
    # increment index and position
    BufferedStream_index(stream) += 1;
    BufferedStream_position(stream) += 1;
    if (chareq(ch,ascii(NL))) {
      ChannelStream_lineno(stream) += 1;
    } else if (chareq(ch,ascii(CR))) {
      # check next character for LF
      ptr = buffered_nextbyte(stream);
      if (!(ptr == (uintB*)NULL) && chareq(as_chart(*ptr),ascii(LF))) {
        # increment index and position
        BufferedStream_index(stream) += 1;
        BufferedStream_position(stream) += 1;
      }
      ch = ascii(NL);
      ChannelStream_lineno(stream) += 1;
    }
    *charptr++ = ch; len--;
  } while (len > 0);
  return charptr - startptr;
  #endif
}

# Output side
# -----------

# UP: Writes a Byte to a Byte-based File-Stream.
# write_byte_buffered(stream,b);
# > stream : (open) Byte-based File-Stream.
# > b : Byte to be written
# changed in stream: index, endvalid, buffstart, position
local void write_byte_buffered (object stream, uintB b) {
  buffered_writebyte(stream,b);
  # increment position
  BufferedStream_position(stream) += 1;
}

# WRITE-CHAR - Pseudo-Function for File-Streams of Characters
local void wr_ch_buffered_unix (const object* stream_, object obj) {
  var object stream = *stream_;
  if (!charp(obj)) # obj must be a character
    fehler_wr_char(stream,obj);
  var chart c = char_code(obj);
 #ifdef UNICODE
  var uintB buf[max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var const chart* cptr = &c;
  var uintB* bptr = &buf[0];
  Encoding_wcstombs(encoding)(encoding,stream,&cptr,cptr+1,&bptr,&buf[max_bytes_per_chart]);
  ASSERT(cptr == &c+1);
  var uintL buflen = bptr-&buf[0];
  write_byte_array_buffered(stream,&buf[0],buflen);
  # increment position
  BufferedStream_position(stream) += buflen;
 #else
  write_byte_buffered(stream,as_cint(c)); # write unchanged
 #endif
}

# WRITE-CHAR-ARRAY - Pseudo-Function for File-Streams of Characters:
local void wr_ch_array_buffered_unix (const object* stream_,
                                      const object* chararray_,
                                      uintL start, uintL len) {
  var object stream = *stream_;
  var const chart* charptr;
  unpack_sstring_alloca(*chararray_,len,start, charptr=);
  var const chart* endptr = charptr + len;
 #ifdef UNICODE
  #define tmpbufsize 4096
  var uintB tmptmpbuf[tmpbufsize*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  do {
    var uintB* bptr = &tmptmpbuf[0];
    Encoding_wcstombs(encoding)(encoding,stream,&charptr,endptr,&bptr,&tmptmpbuf[tmpbufsize*max_bytes_per_chart]);
    var uintL tmptmpbuflen = bptr-&tmptmpbuf[0];
    write_byte_array_buffered(stream,&tmptmpbuf[0],tmptmpbuflen);
    # increment position
    BufferedStream_position(stream) += tmptmpbuflen;
  } until (charptr == endptr);
  #undef tmpbufsize
 #else
  write_byte_array_buffered(stream,charptr,len);
  # increment position
  BufferedStream_position(stream) += len;
 #endif
  wr_ss_lpos(stream,endptr,len); # update Line-Position
}

# WRITE-CHAR - Pseudo-Function for File-Streams of Characters
local void wr_ch_buffered_mac (const object* stream_, object obj) {
  var object stream = *stream_;
  if (!charp(obj)) # obj must be a character
    fehler_wr_char(stream,obj);
  var chart c = char_code(obj);
  if (chareq(c,ascii(NL)))
    c = ascii(CR);
 #ifdef UNICODE
  var uintB buf[max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var const chart* cptr = &c;
  var uintB* bptr = &buf[0];
  Encoding_wcstombs(encoding)(encoding,stream,&cptr,cptr+1,&bptr,&buf[max_bytes_per_chart]);
  ASSERT(cptr == &c+1);
  var uintL buflen = bptr-&buf[0];
  write_byte_array_buffered(stream,&buf[0],buflen);
  # increment position
  BufferedStream_position(stream) += buflen;
 #else
  write_byte_buffered(stream,as_cint(c));
 #endif
}

# WRITE-CHAR-ARRAY - Pseudo-Function for File-Streams of Characters:
local void wr_ch_array_buffered_mac (const object* stream_,
                                     const object* chararray_,
                                     uintL start, uintL len) {
  var object stream = *stream_;
  var const chart* charptr;
  unpack_sstring_alloca(*chararray_,len,start, charptr=);
 #ifdef UNICODE
  # Need a temporary buffer for NL->CR translation.
  #define tmpbufsize 4096
  var chart tmpbuf[tmpbufsize];
  var uintB tmptmpbuf[tmpbufsize*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var uintL remaining = len;
  do {
    var uintL n = remaining;
    if (n > tmpbufsize)
      n = tmpbufsize;
    {
      var chart* tmpptr = &tmpbuf[0];
      var uintL count;
      dotimespL(count,n, {
        var chart c = *charptr++;
        if (chareq(c,ascii(NL)))
          c = ascii(CR);
        *tmpptr++ = c;
      });
      var const chart* cptr = tmpbuf;
      var uintB* bptr = &tmptmpbuf[0];
      Encoding_wcstombs(encoding)(encoding,stream,&cptr,tmpptr,&bptr,&tmptmpbuf[tmpbufsize*max_bytes_per_chart]);
      ASSERT(cptr == tmpptr);
      var uintL tmptmpbuflen = bptr-&tmptmpbuf[0];
      write_byte_array_buffered(stream,&tmptmpbuf[0],tmptmpbuflen);
      # increment position
      BufferedStream_position(stream) += tmptmpbuflen;
    }
    remaining -= n;
  } while (remaining > 0);
  #undef tmpbufsize
 #else
  var uintL remaining = len;
  do {
    var chart c = *charptr++;
    if (chareq(c,ascii(NL)))
      c = ascii(CR);
    write_byte_buffered(stream,as_cint(c));
    remaining--;
  } until (remaining == 0);
 #endif
  wr_ss_lpos(stream,charptr,len); # update Line-Position
}

# WRITE-CHAR - Pseudo-Function for File-Streams of Characters
local void wr_ch_buffered_dos (const object* stream_, object obj) {
  var object stream = *stream_;
  if (!charp(obj)) # obj must be a character
    fehler_wr_char(stream,obj);
  var chart c = char_code(obj);
#ifdef UNICODE
  static chart const crlf[2] = { ascii(CR), ascii(LF) };
  var uintB buf[2*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var const chart* cp;
  var uintL n;
  if (chareq(c,ascii(NL))) {
    cp = crlf; n = 2;
  } else {
    cp = &c; n = 1;
  }
  var const chart* cptr = cp;
  var uintB* bptr = &buf[0];
  Encoding_wcstombs(encoding)(encoding,stream,&cptr,cp+n,&bptr,&buf[2*max_bytes_per_chart]);
  ASSERT(cptr == cp+n);
  var uintL buflen = bptr-&buf[0];
  write_byte_array_buffered(stream,&buf[0],buflen);
  # increment position
  BufferedStream_position(stream) += buflen;
 #else
  if (chareq(c,ascii(NL))) {
    write_byte_buffered(stream,CR); write_byte_buffered(stream,LF);
  } else {
    write_byte_buffered(stream,as_cint(c));
  }
 #endif
}

# WRITE-CHAR-ARRAY - Pseudo-Function for File-Streams of Characters:
local void wr_ch_array_buffered_dos (const object* stream_,
                                     const object* chararray_,
                                     uintL start, uintL len) {
  var object stream = *stream_;
  var const chart* charptr;
  unpack_sstring_alloca(*chararray_,len,start, charptr=);
 #ifdef UNICODE
  # Need a temporary buffer for NL->CR translation.
  #define tmpbufsize 4096
  var chart tmpbuf[2*tmpbufsize];
  var uintB tmptmpbuf[2*tmpbufsize*max_bytes_per_chart];
  var object encoding = TheStream(stream)->strm_encoding;
  var uintL remaining = len;
  do {
    var uintL n = remaining;
    if (n > tmpbufsize)
      n = tmpbufsize;
    {
      var chart* tmpptr = &tmpbuf[0];
      var uintL count;
      dotimespL(count,n, {
        var chart c = *charptr++;
        if (chareq(c,ascii(NL))) {
          *tmpptr++ = ascii(CR); *tmpptr++ = ascii(LF);
        } else {
          *tmpptr++ = c;
        }
      });
      var const chart* cptr = tmpbuf;
      var uintB* bptr = &tmptmpbuf[0];
      Encoding_wcstombs(encoding)(encoding,stream,&cptr,tmpptr,&bptr,&tmptmpbuf[2*tmpbufsize*max_bytes_per_chart]);
      ASSERT(cptr == tmpptr);
      var uintL tmptmpbuflen = bptr-&tmptmpbuf[0];
      write_byte_array_buffered(stream,&tmptmpbuf[0],tmptmpbuflen);
      # increment position
      BufferedStream_position(stream) += tmptmpbuflen;
    }
    remaining -= n;
  } while (remaining > 0);
  #undef tmpbufsize
 #else
  var uintL remaining = len;
  do {
    var chart c = *charptr++;
    if (chareq(c,ascii(NL))) {
      write_byte_buffered(stream,CR); write_byte_buffered(stream,LF);
    } else {
      write_byte_buffered(stream,as_cint(c));
    }
    remaining--;
  } until (remaining == 0);
 #endif
  wr_ss_lpos(stream,charptr,len); # update Line-Position
}

# Macro: Emits a shift sequence to let the output conversion descriptor of an
# Buffered-Channel-Stream return to the initial state.
# oconv_unshift_output_buffered(stream);
# > stream: Buffered-Channel-Stream
#if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
 #define oconv_unshift_output_buffered(stream)  \
      if (ChannelStream_oconvdesc(stream) != (iconv_t)0) { \
        oconv_unshift_output_buffered_(stream);            \
      }
 local void oconv_unshift_output_buffered_ (object stream) {
   #define tmpbufsize 4096
   var uintB tmpbuf[tmpbufsize];
   var char* outptr = (char*)tmpbuf;
   var size_t outsize = tmpbufsize;
   begin_system_call();
   var size_t res =
     iconv(ChannelStream_oconvdesc(stream),NULL,NULL,&outptr,&outsize);
   if (res == (size_t)(-1)) {
     if (errno == E2BIG) { # output buffer too small?
       NOTREACHED;
     } else {
       OS_error();
     }
   }
   end_system_call();
   var uintL outcount = outptr-(char*)tmpbuf;
   if (outcount > 0) {
     write_byte_array_buffered(stream,&tmpbuf[0],outcount);
     # increment position
     BufferedStream_position(stream) += outcount;
   }
 #undef tmpbufsize
 }
#else
 #define oconv_unshift_output_buffered(stream)
#endif

# File-Stream, Bit-based
# ========================

# There are 6 types, altogether:
# Three Cases
#   a - bitsize divisible by 8,
#   b - bitsize < 8,
#   c - bitsize not divisible by 8 and >= 8,
# distinguished by
#   s - Element-Type (signed-byte bitsize),
#       including signed-byte = (signed-byte 8)
#   u - Element-Type (unsigned-byte bitsize),
#       including unsigned-byte = (unsigned-byte 8)
#       and bit = (unsigned-byte 1)
#       and (mod n) = (unsigned-byte (integer-length n))

# UP: Positions an (open) Bit-based File-Stream to a
# specified Position.
# position_file_i_buffered(stream,position);
# > stream : (open) Byte-based File-Stream.
# > position : new (logical) Position
# changed in stream: index, endvalid, buffstart, bitindex
local void position_file_i_buffered (object stream, uintL position) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  var uintL position_bits = position * bitsize;
  if (bitsize < 8)
    position_bits += sizeof(uintL)*8; # consider Header
  # position at Bit Number position_bits.
  position_file_buffered(stream,floor(position_bits,8)); # position to the Byte
  if ((bitsize % 8) == 0) # For Type a that's all.
    return;
  if (# Is the addressed position situated in the first byte after EOF ?
      ((!((position_bits%8)==0))
       && (buffered_nextbyte(stream) == (uintB*)NULL))
       # Is the addressed position situated in the last byte too far?
      || ((bitsize < 8)
          && (position > BufferedStream_eofposition(stream)))) {
    # Error. But first position back to the old Position:
    var uintL oldposition = BufferedStream_position(stream);
    check_SP();
    position_file_i_buffered(stream,oldposition); # positioning back
    fehler_position_beyond_EOF(stream);
  }
  BufferedStream_bitindex(stream) = position_bits%8;
}

# Input side
# ----------

# UP for READ-BYTE on File-Streams of Integers, Type a :
# Fills the Bitbuffer with the next bitsize Bits.
# > stream : File-Stream of Integers, Type a
# > finisher : Routine for Finalization
# < result : read Integer or eof_value
local object rd_by_aux_iax_buffered (object stream, rd_by_ix_I* finisher) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  var uintL bytesize = bitsize/8;
  # transfer sufficiently many bytes into the bitbuffer
  var uintB* bitbufferptr =
    &TheSbvector(TheStream(stream)->strm_bitbuffer)->data[0];
  #if 0 # equivalent, but slower
  var uintL count;
  dotimespL(count,bytesize, {
    var uintB* ptr = buffered_nextbyte(stream);
    if (ptr == (uintB*)NULL)
      goto eof;
    # fetch next Byte:
    *bitbufferptr++ = *ptr;
    # increment index
    BufferedStream_index(stream) += 1;
  });
  #else
  if (read_byte_array_buffered(stream,bitbufferptr,bytesize)
      != bitbufferptr+bytesize)
    goto eof;
  #endif
  # increment position
  BufferedStream_position(stream) += 1;
  # convert to number:
  return (*finisher)(stream,bitsize,bytesize);
  eof: # EOF reached
  position_file_buffered(stream,BufferedStream_position(stream)*bytesize);
  return eof_value;
}

# UP for READ-BYTE on File-Streams of Integers, Type b :
# Fills the Bitbuffer with the next bitsize Bits.
# > stream : File-Stream of Integers, Type b
# > finisher : Routine for Finalization
# < result : read Integer or eof_value
local object rd_by_aux_ibx_buffered (object stream, rd_by_ix_I* finisher) {
  # Only for position < eofposition there's something to read:
  if (BufferedStream_position(stream) == BufferedStream_eofposition(stream))
    goto eof;
  {
    var uintL bitsize = ChannelStream_bitsize(stream); # bitsize (>0, <8)
    # transfer sufficient many bits into the bitbuffer
    var uintL bitindex = BufferedStream_bitindex(stream);
    var uintL count = bitindex + bitsize;
    var uint8 bit_akku;
    var uintB* ptr = buffered_nextbyte(stream);
    if (ptr == (uintB*)NULL)
      goto eof;
    # Get first partial byte:
    bit_akku = (*ptr)>>bitindex;
    # bitshift := 8-bitindex
    # For bit_akku the Bits (bitshift-1)..0 are valid.
    if (count > 8) {
      # increment index, because *ptr is processed:
      BufferedStream_index(stream) += 1;
      count -= 8; # still count (>0) Bits to fetch.
      var uintB* ptr = buffered_nextbyte(stream);
      if (ptr == (uintB*)NULL)
        goto eof1;
      # fetch next Byte:
      # (8-bitindex < 8, because else count = 0+bitsize < 8 !)
      bit_akku |= (*ptr)<<(8-bitindex);
    }
    # For bit_akku all 8 Bits are valid.
    # save 8 Bits:
    TheSbvector(TheStream(stream)->strm_bitbuffer)->data[0] = bit_akku;
    BufferedStream_bitindex(stream) = count;
    # increment position
    BufferedStream_position(stream) += 1;
    # convert to number:
    return (*finisher)(stream,bitsize,1);
  eof1:
    # position back again:
    position_file_i_buffered(stream,BufferedStream_position(stream));
  }
 eof: # EOF was reached
  return eof_value;
}

# UP for READ-BYTE on File-Streams of Integers, Type c :
# Fills the Bitbuffer with the next bitsize Bits.
# > stream : File-Stream of Integers, Type c
# > finisher : Routine for Finalization
# < result : read Integer or eof_value
local object rd_by_aux_icx_buffered (object stream, rd_by_ix_I* finisher) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  var uintL bytesize = ceiling(bitsize,8);
  # transfer sufficiently many bits into the bitbuffer
  var uintB* bitbufferptr =
    &TheSbvector(TheStream(stream)->strm_bitbuffer)->data[0];
  var uintL count = bitsize;
  var uintL bitshift = BufferedStream_bitindex(stream);
  var uintB* ptr = buffered_nextbyte(stream);
  if (ptr != (uintB*)NULL) {
    # start getting bytes:
    var uint16 bit_akku = (*ptr)>>bitshift;
    bitshift = 8-bitshift; # bitshift := 8-bitindex
    count -= bitshift;
    loop {
      BufferedStream_index(stream) += 1;
      # bit_akku: bits (bitshift-1)..0 are valid.
      # have to get count (>0) bits.
      {
        var uintB* ptr = buffered_nextbyte(stream);
        if (ptr == (uintB*)NULL)
          goto eof;
        # get next byte:
        bit_akku |= (uint16)(*ptr)<<bitshift;
      }
      # bit_akku: bits (7+bitshift)..0 are valid.
      *bitbufferptr++ = (uint8)bit_akku; # store 8 Bit
      bit_akku >>= 8;
      if (count<=8) # are count bits finished?
        break;
      count -= 8;
    }
    # count > 0 -- the number of bits to get
    ptr = buffered_nextbyte(stream);
    if (ptr == (uintB*)NULL) # EOF ?
      bit_akku = *buffered_eofbyte(stream);
    *bitbufferptr = (uint8)(bit_akku & (uint8)(bit(count)-1));
    BufferedStream_bitindex(stream) = count;
    BufferedStream_position(stream) += 1; # increment position
    return (*finisher)(stream,bitsize,bytesize); # convert to a number
  }
 eof:
  position_file_i_buffered(stream,BufferedStream_position(stream));
  return eof_value;
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type au :
local object rd_by_iau_buffered (object stream) {
  return rd_by_aux_iax_buffered(stream,&rd_by_iu_I);
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type as :
local object rd_by_ias_buffered (object stream) {
  return rd_by_aux_iax_buffered(stream,&rd_by_is_I);
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type bu :
local object rd_by_ibu_buffered (object stream) {
  return rd_by_aux_ibx_buffered(stream,&rd_by_iu_I);
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type bs :
local object rd_by_ibs_buffered (object stream) {
  return rd_by_aux_ibx_buffered(stream,&rd_by_is_I);
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type cu :
local object rd_by_icu_buffered (object stream) {
  return rd_by_aux_icx_buffered(stream,&rd_by_iu_I);
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type cs :
local object rd_by_ics_buffered (object stream) {
  return rd_by_aux_icx_buffered(stream,&rd_by_is_I);
}

# READ-BYTE - Pseudo-Function for File-Streams of Integers, Type au, bitsize = 8 :
local object rd_by_iau8_buffered (object stream) {
  var uintB* ptr = buffered_nextbyte(stream);
  if (!(ptr == (uintB*)NULL)) {
    var object obj = fixnum(*ptr);
    # increment index and position
    BufferedStream_index(stream) += 1;
    BufferedStream_position(stream) += 1;
    return obj;
  } else {
    return eof_value;
  }
}

# READ-BYTE-SEQUENCE for File-Streams of Integers, Type au, bitsize = 8 :
local uintL rd_by_array_iau8_buffered (const object* stream_,
                                       const object* bytearray_,
                                       uintL start, uintL len) {
  var uintB* startptr = &TheSbvector(*bytearray_)->data[start];
  var uintB* endptr = read_byte_array_buffered(*stream_,startptr,len);
  var uintL result = endptr-startptr;
  # increment position:
  BufferedStream_position(*stream_) += result;
  return result;
}

# Determines, if a Byte is available on a File-Stream.
# listen_byte_ia8_buffered(stream)
# > stream: File-Stream of Integers, Type a, bitsize = 8
# < result:   ls_avail if a byte is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no byte is available, but not because of EOF
local signean listen_byte_ia8_buffered (object stream) {
  if (buffered_nextbyte(stream) == (uintB*)NULL)
    return ls_eof; # EOF
  return ls_avail;
}

# Output side
# -----------

# UP for WRITE-BYTE on File-Streams of Integers, Type a :
# Writes the Bitbuffer-Content to the File.
local void wr_by_aux_ia_buffered (object stream, uintL bitsize, uintL bytesize) {
  var uintB* bitbufferptr = &TheSbvector(TheStream(stream)->strm_bitbuffer)->data[0];
  #if 0 # equivalent, but slow
  var uintL count;
  dotimespL(count,bytesize, {
    buffered_writebyte(stream,*bitbufferptr++);
  });
  #else
  write_byte_array_buffered(stream,bitbufferptr,bytesize);
  #endif
  # increment position:
  BufferedStream_position(stream) += 1;
}

# write last byte (count bits):
#define WRITE_LAST_BYTE                                                 \
 if (!(count==0)) {                                                     \
   ptr = buffered_nextbyte(stream);                                     \
   if (ptr == (uintB*)NULL) { /* EOF */                                 \
     ptr = buffered_eofbyte(stream); /* 1 Byte */                       \
     *ptr = (uint8)bit_akku; /* write byte */                           \
   } else { /* overwrite the last byte only partially: */               \
     var uint8 diff = (*ptr ^ (uint8)bit_akku) & (uint8)(bit(count)-1); \
     if (diff == 0)                                                     \
       goto no_modification;                                            \
     *ptr ^= diff;                                                      \
   }                                                                    \
   BufferedStream_modified(stream) = true;                              \
 no_modification: ;                                                     \
 }

# UP for WRITE-BYTE on File-Streams of Integers, Type b :
# Writes the Bitbuffer-Content to the File.
local void wr_by_aux_ib_buffered (object stream, uintL bitsize, uintL bytesize) {
  var uintL bitshift = BufferedStream_bitindex(stream);
  var uint16 bit_akku = (uint16)(TheSbvector(TheStream(stream)->strm_bitbuffer)->data[0])<<bitshift;
  var uintL count = bitsize;
  var uintB* ptr = buffered_nextbyte(stream);
  # start getting bytes:
  if (!(ptr == (uintB*)NULL))
    bit_akku |= (*ptr)&(bit(bitshift)-1);
  count += bitshift;
  # poss. write single Byte:
  if (count>=8) {
    buffered_writebyte(stream,(uint8)bit_akku);
    bit_akku = bit_akku>>8;
    count -= 8;
  }
  WRITE_LAST_BYTE;
  BufferedStream_bitindex(stream) = count;
  # increment position and poss. eofposition:
  if (BufferedStream_eofposition(stream) == BufferedStream_position(stream))
    BufferedStream_eofposition(stream) += 1;
  BufferedStream_position(stream) += 1;
}

# UP for WRITE-BYTE on File-Streams of Integers, Type c :
# Writes the Bitbuffer-Content to the File.
local void wr_by_aux_ic_buffered (object stream, uintL bitsize, uintL bytesize) {
  var uintB* bitbufferptr=TheSbvector(TheStream(stream)->strm_bitbuffer)->data;
  var uintL bitshift = BufferedStream_bitindex(stream);
  var uintL count = bitsize;
  var uint16 bit_akku;
  var uintB* ptr = buffered_nextbyte(stream);
  # start getting bytes:
  bit_akku = (ptr==(uintB*)NULL ? 0 : (*ptr)&(bit(bitshift)-1) );
  count += bitshift;
  # write individual bytes:
  loop {
    bit_akku |= (uint16)(*bitbufferptr++)<<bitshift;
    if (count<8)
      break;
    buffered_writebyte(stream,(uint8)bit_akku);
    bit_akku = bit_akku>>8;
    count -= 8;
    if (count<=bitshift)
      break;
  }
  WRITE_LAST_BYTE;
  BufferedStream_bitindex(stream) = count;
  BufferedStream_position(stream) += 1;
}
#undef WRITE_LAST_BYTE

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type au :
local void wr_by_iau_buffered (object stream, object obj) {
  wr_by_ixu_sub(stream,obj,&wr_by_aux_ia_buffered);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type as :
local void wr_by_ias_buffered (object stream, object obj) {
  wr_by_ixs_sub(stream,obj,&wr_by_aux_ia_buffered);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type bu :
local void wr_by_ibu_buffered (object stream, object obj) {
  wr_by_ixu_sub(stream,obj,&wr_by_aux_ib_buffered);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type bs :
local void wr_by_ibs_buffered (object stream, object obj) {
  wr_by_ixs_sub(stream,obj,&wr_by_aux_ib_buffered);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type cu :
local void wr_by_icu_buffered (object stream, object obj) {
  wr_by_ixu_sub(stream,obj,&wr_by_aux_ic_buffered);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type cs :
local void wr_by_ics_buffered (object stream, object obj) {
  wr_by_ixs_sub(stream,obj,&wr_by_aux_ic_buffered);
}

# WRITE-BYTE - Pseudo-Function for File-Streams of Integers, Type au, bitsize = 8 :
local void wr_by_iau8_buffered (object stream, object obj) {
  check_wr_int(stream,obj);
  if (!(posfixnump(obj) && (posfixnum_to_L(obj) < bit(8))))
    fehler_bad_integer(stream,obj);
  write_byte_buffered(stream,(uintB)posfixnum_to_L(obj));
}

# WRITE-BYTE-SEQUENCE for File-Streams of Integers, Type au, bitsize = 8 :
local void wr_by_array_iau8_buffered (const object* stream_,
                                      const object* bytearray_,
                                      uintL start, uintL len) {
  write_byte_array_buffered(*stream_,TheSbvector(*bytearray_)->data+start,len);
  # increment position:
  BufferedStream_position(*stream_) += len;
}

# File-Stream in general
# ======================

# UP: Positions an (open) File-Stream to the start.
# logical_position_file_start(stream);
# > stream : (open) File-Stream.
# changed in stream: index, endvalid, buffstart, ..., position, rd_ch_last
local void logical_position_file_start (object stream) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  position_file_buffered
    (stream,
     bitsize > 0 && bitsize < 8 # Integer-Stream of Type b ?
     ? sizeof(uintL) : 0); # yes -> Position 4, else Position 0
  if (!((bitsize % 8) == 0))
    # Integer-Stream of Type b,c
    BufferedStream_bitindex(stream) = 0; # bitindex := 0
  BufferedStream_position(stream) = 0; # position := 0
  TheStream(stream)->strm_rd_ch_last = NIL; # Lastchar := NIL
  TheStream(stream)->strmflags &= ~strmflags_unread_B;
}

# UP: Positions an (open) File-Stream to a given Position.
# logical_position_file(stream,position);
# > stream : (open) File-Stream.
# > position : new (logical) Position
# changed in stream: index, endvalid, buffstart, ..., position, rd_ch_last
local void logical_position_file (object stream, uintL position) {
  var uintL bitsize = ChannelStream_bitsize(stream);
  if (bitsize > 0) { # Integer-Stream ?
    if ((bitsize % 8) == 0) { # Type a
      position_file_buffered(stream,position*(bitsize/8));
    } else { # Type b,c
      position_file_i_buffered(stream,position);
    }
  } else { # Character-Stream
    position_file_buffered(stream,position);
    TheStream(stream)->strm_rd_ch_last = NIL; # Lastchar := NIL
    TheStream(stream)->strmflags &= ~strmflags_unread_B;
  }
  BufferedStream_position(stream) = position;
}

# UP: Positions an (open) File-Stream to the end.
# logical_position_file_end(stream);
# > stream : (open) File-Stream.
# changed in stream: index, endvalid, buffstart, ..., position, rd_ch_last
local void logical_position_file_end (object stream) {
  # poss. flush Buffer:
  if (BufferedStream_modified(stream))
    buffered_flush(stream);
  var uintL eofbytes; # EOF-Position, measured in Bytes
  # position to the End:
  begin_system_call();
  handle_lseek(stream,BufferedStream_channel(stream),0,SEEK_END,eofbytes=);
  end_system_call();
  # calculate logical Position and correct eofbytes:
  var uintL position; # logical Position
  var uintL eofbits = 0; # Bit-Complement for eofbytes
  var uintL bitsize = ChannelStream_bitsize(stream);
  if (bitsize > 0) { # Integer-Stream ?
    if ((bitsize % 8) == 0) { # Type a
      var uintL bytesize = bitsize/8;
      position = floor(eofbytes,bytesize);
      eofbytes = position*bytesize;
    } else if (bitsize < 8) { # Type b
      eofbytes -= sizeof(uintL); # consider Header
      # Is the memorized EOF-Position plausible?
      position = BufferedStream_eofposition(stream);
      if (!(ceiling(position*bitsize,8)==eofbytes)) # yes -> use it
        position = floor(eofbytes*8,bitsize); # no -> recalculate it
      # recalculate eofbytes and eofbits:
      eofbytes = floor(position*bitsize,8);
      eofbits = (position*bitsize)%8;
      eofbytes += sizeof(uintL); # consider Header
    } else { # Type c
      position = floor(eofbytes*8,bitsize);
      eofbytes = floor(position*bitsize,8);
      eofbits = (position*bitsize)%8;
    }
  } else { # Character-Stream
    position = eofbytes;
  }
  if (!BufferedStream_blockpositioning(stream)) {
    # Now position at the End:
    BufferedStream_buffstart(stream) = eofbytes;
    BufferedStream_endvalid(stream) = 0;
    BufferedStream_index(stream) = 0; # index := 0
    BufferedStream_modified(stream) = false; # unmodified
    BufferedStream_have_eof_p(stream) = true;
  } else { # position to the start of the last Sector:
    {
      var uintL buffstart;
      begin_system_call();
      handle_lseek(stream,BufferedStream_channel(stream),
                   floor(eofbytes,strm_buffered_bufflen)*strm_buffered_bufflen,
                   SEEK_SET,buffstart=);
      end_system_call();
      BufferedStream_buffstart(stream) = buffstart;
    }
    # read Sector:
    BufferedStream_endvalid(stream) = 0;
    BufferedStream_index(stream) = 0; # index := 0
    BufferedStream_modified(stream) = false; # unmodified
    BufferedStream_have_eof_p(stream) = false;
    var uintL endvalid = eofbytes % strm_buffered_bufflen;
    if (!((endvalid==0) && (eofbits==0))) {
      # EOF at end of Sector -> nothing to read
      buffered_nextbyte(stream);
      # Now index=0. set index and endvalid:
      BufferedStream_index(stream) = endvalid;
      if (eofbits != 0)
        endvalid += 1;
      BufferedStream_endvalid(stream) = endvalid;
    }
  }
  if (!((bitsize % 8) == 0)) { # Integer-Stream of type b,c
    BufferedStream_bitindex(stream) = eofbits;
  }
  # set position:
  BufferedStream_position(stream) = position;
  TheStream(stream)->strm_rd_ch_last = NIL; # Lastchar := NIL
  TheStream(stream)->strmflags &= ~strmflags_unread_B;
}

# UP: Fills in the pseudofunctions for a buffered stream.
# fill_pseudofuns_buffered(stream,&eltype);
# > stream: stream being built up, with correct strmflags and encoding
# > eltype: Element-Type in decoded form
local void fill_pseudofuns_buffered (object stream,
                                     const decoded_el_t* eltype) {
  var uintB flags = TheStream(stream)->strmflags;
  stream_dummy_fill(stream);
  if (flags & strmflags_rd_by_B) {
    ELTYPE_DISPATCH(eltype,{},{
      TheStream(stream)->strm_rd_by =
        ((eltype->size % 8) == 0
         ? (eltype->size == 8 ? P(rd_by_iau8_buffered) : P(rd_by_iau_buffered))
         : eltype->size < 8 ? P(rd_by_ibu_buffered) : P(rd_by_icu_buffered));
      TheStream(stream)->strm_rd_by_array =
        (eltype->size == 8
         ? P(rd_by_array_iau8_buffered) : P(rd_by_array_dummy));
    },{
      TheStream(stream)->strm_rd_by =
        ((eltype->size % 8) == 0 ? P(rd_by_ias_buffered) :
         eltype->size < 8 ? P(rd_by_ibs_buffered) : P(rd_by_ics_buffered));
      TheStream(stream)->strm_rd_by_array = P(rd_by_array_dummy);
    });
  }
  if (flags & strmflags_wr_by_B) {
    ELTYPE_DISPATCH(eltype,{},{
      TheStream(stream)->strm_wr_by =
        ((eltype->size % 8) == 0
         ? (eltype->size == 8 ? P(wr_by_iau8_buffered) : P(wr_by_iau_buffered))
         : eltype->size < 8 ? P(wr_by_ibu_buffered) : P(wr_by_icu_buffered));
      TheStream(stream)->strm_wr_by_array =
        (eltype->size == 8
         ? P(wr_by_array_iau8_buffered) : P(wr_by_array_dummy));
    },{
      TheStream(stream)->strm_wr_by =
        ((eltype->size % 8) == 0 ? P(wr_by_ias_buffered) :
         eltype->size < 8 ? P(wr_by_ibs_buffered) : P(wr_by_ics_buffered));
      TheStream(stream)->strm_wr_by_array = P(wr_by_array_dummy);
    });
  }
  if (eltype->kind == eltype_ch) {
    if (flags & strmflags_rd_ch_B) {
      TheStream(stream)->strm_rd_ch = P(rd_ch_buffered);
      TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_buffered);
    }
    if (flags & strmflags_wr_ch_B) {
      var object eol=TheEncoding(TheStream(stream)->strm_encoding)->enc_eol;
      if (eq(eol,S(Kunix))) {
        TheStream(stream)->strm_wr_ch = P(wr_ch_buffered_unix);
        TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_buffered_unix);
      } else if (eq(eol,S(Kmac))) {
        TheStream(stream)->strm_wr_ch = P(wr_ch_buffered_mac);
        TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_buffered_mac);
      } else if (eq(eol,S(Kdos))) {
        TheStream(stream)->strm_wr_ch = P(wr_ch_buffered_dos);
        TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_buffered_dos);
      } else
        NOTREACHED;
    }
  }
}


# UP: creates a buffered file stream
# make_buffered_stream(type,direction,&eltype,handle_regular,handle_blockpositioning)
# > STACK_2: Encoding
# > STACK_1: Element-Type
# > STACK_0: open file handle
# > type: stream type
# > direction: direction_t (see lispbibl.d)
# > eltype: Element-Type in decoded form
# > handle_regular: whether the handle refers to a regular file
# > handle_blockpositioning: whether the handle refers to a regular file which
#                            can be positioned at n*strm_buffered_bufflen
# If direction==DIRECTION_IO(5), handle_blockpositioning must be true.
# < result: buffered file stream, Handle_{input,output}_init still to be called,
#           for eltype.size<8 also eofposition still to be to determined
# < STACK: cleaned up
# can trigger GC
local object make_buffered_stream (uintB type, direction_t direction,
                                   const decoded_el_t* eltype,
                                   bool handle_regular,
                                   bool handle_blockpositioning) {
  var uintB flags = DIRECTION_FLAGS(direction);
  var uintC xlen = sizeof(strm_buffered_extrafields_t); # all File-Streams have that
  if (eltype->kind == eltype_ch) {
    flags &= strmflags_ch_B | strmflags_immut_B;
  } else {
    flags &= strmflags_by_B | strmflags_immut_B;
    if ((eltype->size % 8) == 0) { # Type a
    } else {
      xlen = sizeof(strm_i_buffered_extrafields_t); # File-Streams have that for Integers at most
    }
  }
  # allocate Stream:
  var object stream = allocate_stream(flags,type,strm_channel_len,xlen);
  # and fill:
  TheStream(stream)->strm_encoding = STACK_2;
  fill_pseudofuns_buffered(stream,eltype);
  TheStream(stream)->strm_rd_ch_last = NIL; # Lastchar := NIL
  TheStream(stream)->strm_wr_ch_lpos = Fixnum_0; # Line Position := 0
  # Components of File-Streams:
  {
    var object handle = popSTACK(); # restore Handle
    TheStream(stream)->strm_eltype = popSTACK(); # enter Element-Type
    ChannelStream_buffered(stream) = true;
    ChannelStream_init(stream);
    if (!nullp(handle)) { # Handle=NIL -> Rest already initialized with NIL, finished
      BufferedStream_channel(stream) = handle; # enter Handle
      BufferedStream_regular(stream) = handle_regular;
      BufferedStream_blockpositioning(stream) = handle_blockpositioning;
      BufferedStream_buffstart(stream) = 0; # buffstart := 0
      # allocate Buffer:
      pushSTACK(stream);
      {
        var object buffer =
          allocate_bit_vector(Atype_8Bit,strm_buffered_bufflen);
        stream = popSTACK();
        BufferedStream_buffer(stream) = buffer;
      }
      BufferedStream_endvalid(stream) = 0;
      BufferedStream_index(stream) = 0; # index := 0
      BufferedStream_modified(stream) = false; # Buffer unmodified
      BufferedStream_have_eof_p(stream) = false;
      BufferedStream_position(stream) = 0; # position := 0
      ChannelStream_bitsize(stream) = eltype->size;
      ChannelStream_lineno(stream) = 1; # initialize always (cf. set-stream-element-type)
      if (!(eltype->kind == eltype_ch)) {
        # File-Stream of Integers
        # allocate Bitbuffer:
        pushSTACK(stream);
        {
          var object bitbuffer =
            allocate_bit_vector(Atype_Bit,ceiling(eltype->size,8)*8);
          stream = popSTACK();
          TheStream(stream)->strm_bitbuffer = bitbuffer;
        }
        if (!((eltype->size % 8) == 0)) { # Types b,c
          BufferedStream_bitindex(stream) = 0; # bitindex := 0
        }
      }
    }
  }
  skipSTACK(1);
  return stream;
}

# UP: add a stream to the list of open streams O(open_files)
# add_to_open_streams()
# <> stream
# can trigger GC
local object add_to_open_streams (object stream) {
  pushSTACK(stream);
  var object new_cons = allocate_cons();
  Car(new_cons) = stream = popSTACK();
  Cdr(new_cons) = O(open_files);
  O(open_files) = new_cons;
  return stream;
}

# UP: creates a File-Stream
# make_file_stream(direction,append_flag,handle_fresh)
# > STACK_5: Filename, a Pathname or NIL
# > STACK_4: Truename, a Pathname or NIL
# > STACK_3: :BUFFERED argument
# > STACK_2: :EXTERNAL-FORMAT argument
# > STACK_1: :ELEMENT-TYPE argument
# > STACK_0: Handle of the opened File
# > direction: direction_t (see lispbibl.d)
# > append_flag: true if the Stream is to be positioned to the End at the
#         first go, else false
# > handle_fresh: whether the handle is freshly created.
#                 This means 1. that it is currently positioned at position 0,
#                 2. if (direction & bit(2)), it is opened for read/write, not
#                 only for write.
#                 If the handle refers to a regular file, this together means
#                 that it supports handle_lseek, reading/repositioning/writing
#                 and close/reopen.
# > subr_self: calling function
# If direction==DIRECTION_IO(5), handle_fresh must be true.
# < result: File-Stream (or poss. File-Handle-Stream)
# < STACK: cleaned up
# can trigger GC
global object make_file_stream (direction_t direction, bool append_flag,
                                bool handle_fresh) {
  var decoded_el_t eltype;
  var signean buffered;
  # Check and canonicalize the :ELEMENT-TYPE argument:
  test_eltype_arg(&STACK_1,&eltype);
  STACK_1 = canon_eltype(&eltype);
  # Check and canonicalize the :EXTERNAL-FORMAT argument:
  STACK_2 = test_external_format_arg(STACK_2);
  # Stack Layout: filename, truename, buffered, encoding, eltype, handle.
  var object stream;
  var object handle = STACK_0;
  var bool handle_regular = true;
  if (!nullp(handle))
    handle_regular = regular_handle_p(TheHandle(handle));
  # Check and canonicalize the :BUFFERED argument:
  # Default is T for regular files, NIL for non-regular files because they
  # probably don't support lseek().
  buffered = test_buffered_arg(STACK_3);
 #if defined(UNIX) || defined(RISCOS)
  # /proc files are unbuffered by default
  if ((buffered == 0) && !nullp(STACK_4)) { # truename
    var object dir = ThePathname(STACK_4)->pathname_directory;
    if (consp(dir) && consp(Cdr(dir)))
      with_sstring_0(Car(Cdr(dir)),O(pathname_encoding),top_dir,
                     { if (asciz_equal(top_dir,"proc")) buffered = -1; });
  }
 #endif
  if (buffered == 0)
    buffered = (handle_regular ? 1 : -1);
  if (buffered < 0) {
    if (!(eltype.kind == eltype_ch) && !((eltype.size % 8) == 0)) {
      pushSTACK(STACK_4); # Truename, FILE-ERROR slot PATHNAME
      pushSTACK(STACK_0);
      pushSTACK(STACK_(1+2));
      pushSTACK(S(Kelement_type));
      pushSTACK(TheSubr(subr_self)->name);
      fehler(file_error,GETTEXT("~: argument ~ ~ was specified, but ~ is not a regular file."));
    }
    var bool handle_tty = false;
    if (READ_P(direction)) # only needed for input handles
      if (!handle_regular) { # regular files are certainly not ttys
        begin_system_call();
        handle_tty = isatty(TheHandle(handle));
        end_system_call();
      }
    stream=make_unbuffered_stream(strmtype_file,direction,&eltype,handle_tty);
    # file-handle-streams are treated for pathname purposes as file-streams
    # thus (wrt file_write_date) strm_buffered_channel == strm_ochannel,
    # and we have pathnames now:
    TheStream(stream)->strm_file_truename = STACK_1; # truename
    TheStream(stream)->strm_file_name = STACK_2; # filename
    if (READ_P(direction)) {
      UnbufferedHandleStream_input_init(stream);
    }
    if (WRITE_P(direction)) {
      UnbufferedHandleStream_output_init(stream);
    }
    ChannelStreamLow_close(stream) = &low_close_handle;
  } else {
    if (direction==DIRECTION_IO && !handle_regular) {
      # FIXME: Instead of signalling an error, we could return some kind
      # of two-way-stream (cf. make_socket_stream).
      pushSTACK(STACK_4); # Truename, FILE-ERROR slot PATHNAME
      pushSTACK(STACK_0);
      pushSTACK(T);
      pushSTACK(S(Kbuffered));
      pushSTACK(S(Kio));
      pushSTACK(S(Kdirection));
      pushSTACK(TheSubr(subr_self)->name);
      fehler(file_error,GETTEXT("~: arguments ~ ~ and ~ ~ were specified, but ~ is not a regular file."));
    }
    # Positioning the buffer on block boundaries is possible only if
    # 1. the handle refers to a regular file (otherwise read() and
    #    write() on the handle may be unrelated),
    # 2. if write access is requested, the handle is known to have
    #    read access as well (O_RDWR vs. O_WRONLY).
    var bool handle_blockpositioning =
      (handle_regular && (WRITE_P(direction) ? handle_fresh : true));
    # Now, if direction==DIRECTION_IO(5), handle_blockpositioning is true.
    # allocate stream:
    stream = make_buffered_stream(strmtype_file,direction,&eltype,
                                  handle_regular,handle_blockpositioning);
    TheStream(stream)->strm_file_truename = STACK_1; # truename
    TheStream(stream)->strm_file_name = STACK_2; # filename
    BufferedHandleStream_init(stream);
    ChannelStreamLow_close(stream) = &low_close_handle;
    if (handle_regular && !handle_fresh) {
      var uintL position;
      begin_system_call();
      handle_lseek(stream,BufferedStream_channel(stream),0,SEEK_CUR,position=);
      end_system_call();
      position_file_buffered(stream,position);
    }
    if (!nullp(BufferedStream_channel(stream))
        && !(eltype.kind == eltype_ch) && (eltype.size < 8)) {
      # Type b
      # read eofposition:
      var uintL eofposition = 0;
      var uintC count;
      for (count=0; count < 8*sizeof(uintL); count += 8 ) {
        var uintB* ptr = buffered_nextbyte(stream);
        if (ptr == (uintB*)NULL)
          goto too_short;
        eofposition |= ((*ptr) << count);
        # increment index, because *ptr is processed:
        BufferedStream_index(stream) += 1;
      }
      if (false) {
       too_short:
        # File too short (< sizeof(uintL) Bytes)
        if ((TheStream(stream)->strmflags & strmflags_wr_by_B) == 0) # Read-Only-Stream?
          goto bad_eofposition;
        # File Read/Write -> set eofposition := 0
        eofposition = 0;
        position_file_buffered(stream,0); # move to position 0
        var uintC count; # and write eofposition = 0
        dotimespC(count,sizeof(uintL), { buffered_writebyte(stream,0); } );
      } else if (eofposition > (uintL)(bitm(oint_data_len)-1)) {
       bad_eofposition:
        # No valid EOF-Position.
        # close File and report Error:
        TheStream(stream)->strmflags &= ~strmflags_wr_by_B; # make Stream Read-Only
        pushSTACK(stream);
        builtin_stream_close(&STACK_0);
        pushSTACK(Truename_or_Self(STACK_0)); # STREAM-ERROR slot STREAM
        fehler(stream_error,GETTEXT("file ~ is not an integer file"));
      }
      # We rely on the read EOF-Position now!
      BufferedStream_eofposition(stream) = eofposition;
    }
  }
  skipSTACK(3);
  # extend List of open File-Streams by stream:
  stream = add_to_open_streams(stream);
  # treat Mode :APPEND:
  # CLHS says that :APPEND implies that "the file pointer is _initially_
  # positioned at the end of the file". Note that this is different from
  # the Unix O_APPEND semantics.
  if (append_flag) {
    if (buffered < 0) {
      # position to the End:
      begin_system_call();
      handle_lseek(stream,TheStream(stream)->strm_ochannel,0,SEEK_END,);
      end_system_call();
    } else {
      logical_position_file_end(stream);
    }
  }
  return stream;
}

# UP: Prepares the Closing of a File-Stream.
# Thereby the Buffer and poss. eofposition is flushed.
# buffered_flush_everything(stream);
# > stream : (open) File-Stream.
# changed in stream: index, endvalid, buffstart, ...
local void buffered_flush_everything (object stream) {
  # For Integer-Streams (Type b) save eofposition:
  if (ChannelStream_bitsize(stream) > 0 && ChannelStream_bitsize(stream) < 8)
    if (TheStream(stream)->strmflags & strmflags_wr_by_B) { # only if not read-only
      position_file_buffered(stream,0); # move to position 0
      var uintL eofposition = BufferedStream_eofposition(stream);
      var uintC count;
      dotimespC(count,sizeof(uintL), {
        buffered_writebyte(stream,(uintB)eofposition);
        eofposition = eofposition>>8;
      });
    }
  if (BufferedStream_modified(stream))
    buffered_flush(stream);
  # Now the modified_flag is deleted.
}

# UP: Moves the pending Output of a File-Stream to the destination.
# Writes the Buffer of the File-Stream (also physically) to the File.
# finish_output_buffered(stream);
# > stream : File-Stream.
# changed in stream: handle, index, endvalid, buffstart, ..., rd_ch_last
# can trigger GC
local void finish_output_buffered (object stream) {
  # Handle=NIL (Stream already closed) -> finished:
  if (nullp(BufferedStream_channel(stream)))
    return;
  # no File with write-access -> nothing to do:
  if (!(TheStream(stream)->strmflags & strmflags_wr_B))
    return;
  # flush pending Output in the iconv-Descriptor:
  oconv_unshift_output_buffered(stream);
  # poss. flush Buffer and eofposition:
  buffered_flush_everything(stream);
  # Now the modified_flag is deleted.
  if (BufferedStream_regular(stream)) {
   #ifdef UNIX
    #ifdef HAVE_FSYNC
    begin_system_call();
    if (fsync(TheHandle(BufferedStream_channel(stream)))) {
      end_system_call(); OS_filestream_error(stream);
    }
    end_system_call();
    #endif
   #else
    if (!nullp(TheStream(stream)->strm_file_truename)) { # avoid closing stdout_handle
    #ifdef MSDOS
     # duplicate File-Handle and close:
      var uintW handle = TheHandle(BufferedStream_channel(stream));
      begin_system_call();
      var sintW handle2 = dup(handle);
      if (handle2 < 0) { end_system_call(); OS_filestream_error(stream); }
      if (CLOSE(handle2)<0) { end_system_call(); OS_filestream_error(stream); }
      end_system_call();
    #endif
    #ifdef RISCOS # || MSDOS, if we hadn't something better already
     # close File (DOS writes physically):
      begin_system_call();
      if ( CLOSE(TheHandle(BufferedStream_channel(stream))) <0) {
        end_system_call(); OS_filestream_error(stream);
      }
      end_system_call();
      # reopen File:
      pushSTACK(stream); # save stream
      pushSTACK(TheStream(stream)->strm_file_truename); # Filename
      # Directory alrady exists:
      var object namestring = assume_dir_exists(); # Filename as ASCIZ-String
      var sintW handle;
      with_sstring_0(namestring,O(pathname_encoding),namestring_asciz, {
        begin_system_call();
        handle = OPEN(namestring_asciz,O_RDWR); # reopen file
        if (handle < 0) { end_system_call(); OS_filestream_error(STACK_1); }
        end_system_call();
      });
     #ifdef MSDOS
      begin_system_call();
      setmode(handle,O_BINARY);
      end_system_call();
     #endif
      # Now handle contains the Handle of the opened File.
      var object handlobj = allocate_handle(handle);
      skipSTACK(1);
      stream = popSTACK(); # restore stream
      # enter new Handle:
      BufferedStream_channel(stream) = handlobj;
    #endif
    #ifdef AMIGAOS
     #if 0 # Some Devices don't tolerate, if opened Files are
           # closed and reopened. E.g. this has a special meaning
           # for Pipes.
      begin_system_call();
      var Handle handle = TheHandle(BufferedStream_channel(stream));
      if (!IsInteractive(handle)) {
        # close File (OS writes physically):
        Close(handle);
        end_system_call();
        # reopen File:
        pushSTACK(stream); # save stream
        pushSTACK(TheStream(stream)->strm_file_truename); # Filename
        # Directory already exists, reopen file:
        var object namestring = assume_dir_exists(); # Filename as ASCIZ-String
        with_sstring_0(namestring,O(pathname_encoding),namestring_asciz, {
          begin_system_call();
          handle = Open(namestring_asciz,MODE_OLDFILE);
          end_system_call();
        });
        if (handle==NULL) { OS_filestream_error(STACK_1); }
        skipSTACK(1);
        stream = popSTACK(); # restore stream
        # enter new Handle:
        TheHandle(BufferedStream_channel(stream)) = handle;
      } else {
        end_system_call();
      }
     #endif
    #endif
    }
   #endif
  }
  # and reposition:
  var uintL position = BufferedStream_buffstart(stream) + BufferedStream_index(stream);
  BufferedStream_index(stream) = 0; # index := 0
  BufferedStream_endvalid(stream) = 0;
  if (!BufferedStream_blockpositioning(stream)) {
    BufferedStream_buffstart(stream) = position;
  } else {
    BufferedStream_buffstart(stream) = 0; # buffstart := 0
    position_file_buffered(stream,position);
  }
  # Components position, ..., lastchar remain unchanged
}

# UP: Moves the pending Output of a File-Stream to the destination.
# Writes the Buffer of the File-Stream (also physically) to the File.
# force_output_buffered(stream);
# > stream : File-Stream.
# changed in stream: handle, index, endvalid, buffstart, ..., rd_ch_last
# can trigger GC
  #define force_output_buffered  finish_output_buffered

# UP: Declares a File-Stream as closed.
# closed_buffered(stream);
# > stream : (open) File-Stream.
# changed in stream: all Components except name and truename
local void closed_buffered (object stream) {
  BufferedStream_channel(stream) = NIL; # Handle becomes invalid
  BufferedStream_buffer(stream) = NIL; # free Buffer
  BufferedStream_buffstart(stream) = 0; # delete buffstart (unnecessary)
  BufferedStream_endvalid(stream) = 0; # delete endvalid (unnecessary)
  BufferedStream_index(stream) = 0; # delete index (unnecessary)
  BufferedStream_modified(stream) = false; # delete modified_flag (unnecessary)
  BufferedStream_position(stream) = 0; # delete position (unnecessary)
  BufferedStream_have_eof_p(stream) = false; # delete have_eof_p (unnecessary)
  if (ChannelStream_bitsize(stream) > 0) {
    ChannelStream_bitsize(stream) = 0; # delete bitsize
    TheStream(stream)->strm_bitbuffer = NIL; # free Bitbuffer
  }
  #if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
  ChannelStream_iconvdesc(stream) = (iconv_t)0; # delete iconvdesc
  ChannelStream_oconvdesc(stream) = (iconv_t)0; # delete oconvdesc
  #endif
}

# UP: Closes a File-Stream.
# close_buffered(stream);
# > stream : File-Stream.
# changed in stream: all Components except name and truename
local void close_buffered (object stream) {
  # Handle=NIL (Stream already closed) -> finished:
  if (nullp(BufferedStream_channel(stream)))
    return;
  # Flush pending Output in the iconv-Descriptor:
  oconv_unshift_output_buffered(stream);
  # poss. flush Buffer and eofposition:
  buffered_flush_everything(stream);
  # Now the modified_flag is deleted.
  # close File:
  ChannelStreamLow_close(stream)(stream,BufferedStream_channel(stream));
  ChannelStream_fini(stream);
  # make Components invalid (close_dummys comes later):
  closed_buffered(stream);
  # remove stream from the List of all open File-Streams:
  O(open_files) = deleteq(O(open_files),stream);
}

# (SYS::FILE-STREAM-P stream) == (TYPEP stream 'FILE-STREAM)
LISPFUNN(file_stream_p,1) {
  var object arg = popSTACK();
  VALUES_IF(builtin_stream_p(arg) && (TheStream(arg)->strmtype == strmtype_file));
}


#ifdef KEYBOARD

# Keyboard-Stream
# ===============

# Functionality:
# Reads a character from the keyboard.
# Returns a Character with Font=0 and following Bits:
#   HYPER      if special key.
#              Among the special keys are the Non-Standard-Tasten.
#              MSDOS:
#                Function keys, Cursor blocks, number block.
#   CHAR-CODE  For normal keys the Ascii-Code,
#              for special keys:
#              MSDOS:
#                F1 -> #\F1, ..., F10 -> #\F10, F11 -> #\F11, F12 -> #\F12,
#                Insert -> #\Insert, Delete -> #\Delete,
#                Home -> #\Home, End -> #\End, PgUp -> #\PgUp, PgDn -> #\PgDn,
#                Arrow keys -> #\Up, #\Down, #\Left, #\Right.
#   SUPER      if pressed with Shift-Key(s) and another Code had been the result
#                without Shift,
#   CONTROL    if pressed with Control-Key,
#   META       if pressed with Alternate-Key.

#if (defined(UNIX) && !defined(NEXTAPP)) || defined(RISCOS)
  # Additional Components:
  #define strm_keyboard_isatty  strm_isatty   # Flag, if stdin is a Terminal
  #define strm_keyboard_handle  strm_ichannel # Handle for listen_char_unbuffered()
  #define strm_keyboard_buffer  strm_field1   # List of still to be delivered characters
  #define strm_keyboard_keytab  strm_field2   # List of all key bindings
                                              # always (char1 ... charn . result)
  #define strm_keyboard_len  strm_channel_len
  #define strm_keyboard_xlen  sizeof(strm_unbuffered_extrafields_t)
#elif defined(WIN32_NATIVE)
  # Additional Components:
  #define strm_keyboard_isatty  strm_isatty   # Flag, if stdin is a Terminal
  #define strm_keyboard_handle  strm_ichannel # Handle for listen_char_unbuffered()
  #define strm_keyboard_len  strm_channel_len
  #define strm_keyboard_xlen  sizeof(strm_unbuffered_extrafields_t)
#else
  # No Additional Components:
  #define strm_keyboard_len  strm_len
  #define strm_keyboard_xlen  0
#endif

# The keyboard events are instances of INPUT-CHARACTER. We create them by
# calling MAKE-INPUT-CHARACTER or MAKE-CHAR. The following structure describes
# the arguments to MAKE-INPUT-CHARACTER.
typedef struct {
  const char * key;
  chart code;
  uintB bits;
} key_event;

# Initializers for the two most common kinds of keyboard events.
  #define key_ascii(asc)  { NULL, ascii(asc), 0 }
  #define key_special(name)  { name, ascii(0), char_hyper_c }

# Creates a keyboard event.
local object make_key_event (const key_event* event) {
  if ((event->key == NULL) && (event->bits == 0)) {
    pushSTACK(S(Kchar)); pushSTACK(code_char(event->code));
    funcall(S(make_input_character),2);
  } else {
    pushSTACK(S(Kkey));
    if (event->key == NULL)
      pushSTACK(code_char(event->code));
    else
      pushSTACK(intern_keyword(ascii_to_string(event->key)));
    pushSTACK(S(Kbits)); pushSTACK(fixnum(event->bits));
    funcall(S(make_input_character),4);
  }
  return value1;
}

# Values for the bits, must agree with xcharin.lisp.
  #define char_control_c  1
  #define char_meta_c     2
  #define char_super_c    4
  #define char_hyper_c    8

#ifdef MSDOS

# For keyboard request on DOS:

# INT 16 documentation:
#   INT 16,00 - Wait for keystroke and read
#   INT 16,01 - Get keystroke status
#   INT 16,02 - Get shift status
#   INT 16,03 - Set keyboard typematic rate (AT+)
#   INT 16,04 - Keyboard click adjustment (AT+)
#   INT 16,05 - Keyboard buffer write  (AT,PS/2 enhanced keyboards)
#   INT 16,10 - Wait for keystroke and read  (AT,PS/2 enhanced keyboards)
#   INT 16,11 - Get keystroke status  (AT,PS/2 enhanced keyboards)
#   INT 16,12 - Get shift status  (AT,PS/2 enhanced keyboards)
#
# INT 16,00 - Wait for Keypress and Read Character
#     AH = 00
#     on return:
#     AH = keyboard scan code
#     AL = ASCII character or zero if special function key
#     - halts program until key with a scancode is pressed
#     - see  SCAN CODES

# INT 16,01 - Get Keyboard Status
#     AH = 01
#     on return:
#     ZF = 0 if a key pressed (even Ctrl-Break)
#     AX = 0 if no scan code is available
#     AH = scan code
#     AL = ASCII character or zero if special function key
#     - data code is not removed from buffer
#     - Ctrl-Break places a zero word in the keyboard buffer but does
#       register a keypress.

# INT 16,10 - Extended Wait for Keypress and Read Character  (AT+)
#     AH = 10h
#     on return:
#     AH = scan code
#     AL = ASCII character or zero if special function key
#     - available on AT and PS/2 machines with extended keyboard support
#     - similar to INT 16,00

# INT 16,11 - Extended Get Keyboard Status  (AT+)
#       AH = 11h
#       on return:
#       ZF = 0 if key pressed (data waiting)
#       AX = 0 if no scan code is available
#       AH = scan code
#       AL = ASCII character or zero if special function key
#       - available on AT and PS/2 machines with extended keyboard support
#       - data is not removed from buffer
#       - similar to INT 16,01


#ifdef EMUNIX

  # On DOS:
  #   Until emx 0.8e  INT 16,10 is obviously obstructed for us.
  #   We do not receive any Extended-Keystrokes, but we can distinguish
  #   the Return-Key from the Enter-Key, after all.
  # On OS/2:
  #   INT 16 does not work. Instead _read_kbd() works more precise than on DOS.

  # Returns on DOS the next keystroke incl. Scan-Code:
  # high byte = Scan-Code or 0, low byte = Ascii-Code or 0 or 0xE0.
  # (Note: Must push/pop %ebx because this is the STACK_register.)
  local bool kbhit()
    {
      var bool result;
      __asm__ __volatile__ ("pushl %%ebx ; "
                            "movb $0x11,%%ah ; .byte 0xcd ; .byte 0x16 ; "
                            "movl $0,%%eax ; jz 1f ; incl %%eax ; 1: "
                            "popl %%ebx"
                            : "=a" /* %eax */ (result) /* OUT */
                            :                          /* IN */
                            : "cx","dx","si","di" /* %ecx,%edx,%esi,%edi */ /* CLOBBER */
                           );
      return result;
    }
  local uintW getch()
    {
      var uintW ch;
      __asm__ __volatile__ ("pushl %%ebx ; "
                            "movb $0x10,%%ah ; .byte 0xcd ; .byte 0x16 ; "
                            "popl %%ebx"
                            : "=a" /* %ax */ (ch)      /* OUT */
                            :                          /* IN */
                            : "cx","dx","si","di" /* %ecx,%edx,%esi,%edi */ /* CLOBBER */
                           );
      return ch;
    }

#endif

  # Table of Characters, that correspond to the Scan-Codes 0..166
  #  (as special keys):
  local const key_event scancode_table [167] = {
    { NULL, 0, 0, },
    { NULL, ESC, char_meta_c }, # 1 -> Alt-Escape
    { NULL, '1', char_control_c }, # [2 = Ctrl-1 -> #\CONTROL-1]
    { NULL, '2', char_control_c }, # 3 = Ctrl-2 -> #\CONTROL-2
    { NULL, '3', char_control_c }, # [4 = Ctrl-3 -> #\CONTROL-3]
    { NULL, '4', char_control_c }, # [5 = Ctrl-4 -> #\CONTROL-4]
    { NULL, '5', char_control_c }, # [6 = Ctrl-5 -> #\CONTROL-5]
    { NULL, '6', char_control_c }, # 7 = Ctrl-6 -> #\CONTROL-6
    { NULL, '7', char_control_c }, # [8 = Ctrl-7 -> #\CONTROL-7]
    { NULL, '8', char_control_c }, # [9 = Ctrl-8 -> #\CONTROL-8]
    { NULL, '9', char_control_c }, # [10 = Ctrl-9 -> #\CONTROL-9]
    { NULL, '0', char_control_c }, # [11 = Ctrl-0 -> #\CONTROL-0]
    { NULL, '-', char_meta_c }, # [12 = Ctrl-- -> #\CONTROL-- # not internationally portable]
    { NULL, '=', char_meta_c }, # [13 = Ctrl-= -> #\CONTROL-= # not internationally portable]
    { NULL,  BS, char_meta_c }, # 14 -> Alt-Backspace
    { NULL,   9, char_super_c }, # 15 -> Shift-Tab
    { NULL, 'Q', char_meta_c }, # 16 -> Alt-Q
    { NULL, 'W', char_meta_c }, # 17 -> Alt-W
    { NULL, 'E', char_meta_c }, # 18 -> Alt-E
    { NULL, 'R', char_meta_c }, # 19 -> Alt-R
    { NULL, 'T', char_meta_c }, # 20 -> Alt-T
    { NULL, 'Y', char_meta_c }, # 21 -> Alt-Y
    { NULL, 'U', char_meta_c }, # 22 -> Alt-U
    { NULL, 'I', char_meta_c }, # 23 -> Alt-I
    { NULL, 'O', char_meta_c }, # 24 -> Alt-O
    { NULL, 'P', char_meta_c }, # 25 -> Alt-P
    { NULL, '[', char_meta_c }, # 26 -> Alt-[ # not internationally portable
    { NULL, ']', char_meta_c }, # 27 -> Alt-] # not internationally portable
    { NULL,  CR, char_meta_c }, # 28 = Alt-Return -> #\META-Return
    { NULL, 0, 0 },
    { NULL, 'A', char_meta_c }, # 30 -> Alt-A
    { NULL, 'S', char_meta_c }, # 31 -> Alt-S
    { NULL, 'D', char_meta_c }, # 32 -> Alt-D
    { NULL, 'F', char_meta_c }, # 33 -> Alt-F
    { NULL, 'G', char_meta_c }, # 34 -> Alt-G
    { NULL, 'H', char_meta_c }, # 35 -> Alt-H
    { NULL, 'J', char_meta_c }, # 36 -> Alt-J
    { NULL, 'K', char_meta_c }, # 37 -> Alt-K
    { NULL, 'L', char_meta_c }, # 38 -> Alt-L or Alt-\ ??
    { NULL, ';', char_meta_c }, # 39 -> Alt-; # not internationally portable
    { NULL, '\'', char_meta_c }, # 40 -> Alt-' # not internationally portable
    { NULL, '`', char_meta_c }, # 41 -> Alt-` # not internationally portable
    { NULL, 0, 0 },
    { NULL, '\\', char_meta_c }, # 43 -> Alt-\ # not internationally portable
    { NULL, 'Z', char_meta_c }, # 44 -> Alt-Z
    { NULL, 'X', char_meta_c }, # 45 -> Alt-X
    { NULL, 'C', char_meta_c }, # 46 -> Alt-C
    { NULL, 'V', char_meta_c }, # 47 -> Alt-V
    { NULL, 'B', char_meta_c }, # 48 -> Alt-B
    { NULL, 'N', char_meta_c }, # 49 -> Alt-N
    { NULL, 'M', char_meta_c }, # 50 -> Alt-M
    { NULL, ',', char_meta_c }, # 51 = Alt-, -> #\META-',' # not internationally portable
    { NULL, '.', char_meta_c }, # 52 = Alt-. -> #\META-'.' # not internationally portable
    { NULL, '/', char_meta_c }, # 53 = Alt-/ -> #\META-'/' # not internationally portable
    { NULL, 0, 0 },
    { NULL, '*', char_meta_c | char_hyper_c }, # 55 = Alt-* -> #\META-HYPER-'*'
    { NULL, 0, 0 },
    { NULL, ' ', char_meta_c }, # 57 = Alt-Space -> #\META-Space
    { NULL, 0, 0 },
    { "F1", 0, char_hyper_c }, #  59 = F1 -> #\F1
    { "F2", 0, char_hyper_c }, #  60 = F2 -> #\F2
    { "F3", 0, char_hyper_c }, #  61 = F3 -> #\F3
    { "F4", 0, char_hyper_c }, #  62 = F4 -> #\F4
    { "F5", 0, char_hyper_c }, #  63 = F5 -> #\F5
    { "F6", 0, char_hyper_c }, #  64 = F6 -> #\F6
    { "F7", 0, char_hyper_c }, #  65 = F7 -> #\F7
    { "F8", 0, char_hyper_c }, #  66 = F8 -> #\F8
    { "F9", 0, char_hyper_c }, #  67 = F9 -> #\F9
    { "F10", 0, char_hyper_c }, #  68 = F10 -> #\F10
    { "F11", 0, char_hyper_c }, # [69 = F11 -> #\F11
    { "F12", 0, char_hyper_c }, # [70 = F12 -> #\F12
    { "HOME", 0, char_hyper_c }, #  71 = Home -> #\Home
    { "UP", 0, char_hyper_c }, #  72 = Up -> #\Up
    { "PGUP", 0, char_hyper_c }, #  73 = PgUp -> #\PgUp
    { NULL, '-', char_meta_c | char_hyper_c }, #  74 = Alt-- -> #\META-HYPER--
    { "LEFT", 0, char_hyper_c }, #  75 = Left -> #\Left
    { "CENTER", 0, char_hyper_c }, # [76 -> #\HYPER-Code21]
    { "RIGHT", 0, char_hyper_c }, #  77 = Right -> #\Right
    { NULL, '+', char_meta_c | char_hyper_c }, #  78 = Alt-+ -> #\META-HYPER-+
    { "END", 0, char_hyper_c }, #  79 = End -> #\End
    { "DOWN", 0, char_hyper_c }, #  80 = Down -> #\Down
    { "PGDN", 0, char_hyper_c }, #  81 = PgDn -> #\PgDn
    { "INSERT", 0, char_hyper_c }, #  82 = Insert -> #\Insert
    { "DELETE", 0, char_hyper_c }, #  83 = Delete -> #\Delete
    { "F1", 0, char_super_c | char_hyper_c }, #  84 = Shift-F1 -> #\S-F1
    { "F2", 0, char_super_c | char_hyper_c }, #  85 = Shift-F2 -> #\S-F2
    { "F3", 0, char_super_c | char_hyper_c }, #  86 = Shift-F3 -> #\S-F3
    { "F4", 0, char_super_c | char_hyper_c }, #  87 = Shift-F4 -> #\S-F4
    { "F5", 0, char_super_c | char_hyper_c }, #  88 = Shift-F5 -> #\S-F5
    { "F6", 0, char_super_c | char_hyper_c }, #  89 = Shift-F6 -> #\S-F6
    { "F7", 0, char_super_c | char_hyper_c }, #  90 = Shift-F7 -> #\S-F7
    { "F8", 0, char_super_c | char_hyper_c }, #  91 = Shift-F8 -> #\S-F8
    { "F9", 0, char_super_c | char_hyper_c }, #  92 = Shift-F9 -> #\S-F9
    { "F10", 0, char_super_c | char_hyper_c }, #  93 = Shift-F10 -> #\S-F10
    { "F1", 0, char_control_c | char_hyper_c }, #  94 = Control-F1 -> #\C-F1
    { "F2", 0, char_control_c | char_hyper_c }, #  95 = Control-F2 -> #\C-F2
    { "F3", 0, char_control_c | char_hyper_c }, #  96 = Control-F3 -> #\C-F3
    { "F4", 0, char_control_c | char_hyper_c }, #  97 = Control-F4 -> #\C-F4
    { "F5", 0, char_control_c | char_hyper_c }, #  98 = Control-F5 -> #\C-F5
    { "F6", 0, char_control_c | char_hyper_c }, #  99 = Control-F6 -> #\C-F6
    { "F7", 0, char_control_c | char_hyper_c }, #  100 = Control-F7 -> #\C-F7
    { "F8", 0, char_control_c | char_hyper_c }, #  101 = Control-F8 -> #\C-F8
    { "F9", 0, char_control_c | char_hyper_c }, #  102 = Control-F9 -> #\C-F9
    { "F10", 0, char_control_c | char_hyper_c }, #  103 = Control-F10 -> #\C-F10
    { "F1", 0, char_meta_c | char_hyper_c }, #  104 = Alt-F1 -> #\M-F1
    { "F2", 0, char_meta_c | char_hyper_c }, #  105 = Alt-F2 -> #\M-F2
    { "F3", 0, char_meta_c | char_hyper_c }, #  106 = Alt-F3 -> #\M-F3
    { "F4", 0, char_meta_c | char_hyper_c }, #  107 = Alt-F4 -> #\M-F4
    { "F5", 0, char_meta_c | char_hyper_c }, #  108 = Alt-F5 -> #\M-F5
    { "F6", 0, char_meta_c | char_hyper_c }, #  109 = Alt-F6 -> #\M-F6
    { "F7", 0, char_meta_c | char_hyper_c }, #  110 = Alt-F7 -> #\M-F7
    { "F8", 0, char_meta_c | char_hyper_c }, #  111 = Alt-F8 -> #\M-F8
    { "F9", 0, char_meta_c | char_hyper_c }, #  112 = Alt-F9 -> #\M-F9
    { "F10", 0, char_meta_c | char_hyper_c }, #  113 = Alt-F10 -> #\M-F10
    { "PRTSCR", 0, char_control_c | char_hyper_c }, # 114 = Control-PrtScr -> #\C-PrtScr
    { "LEFT", 0, char_control_c | char_hyper_c }, # 115 = Control-Left -> #\C-Left
    { "RIGHT", 0, char_control_c | char_hyper_c }, # 116 = Control-Right -> #\C-Right
    { "END", 0, char_control_c | char_hyper_c }, # 117 = Control-End -> #\C-End
    { "PGDN", 0, char_control_c | char_hyper_c }, # 118 = Control-PgDn -> #\C-PgDn
    { "HOME", 0, char_control_c | char_hyper_c }, # 119 = Control-Home -> #\C-Home
    { NULL, '1', char_meta_c }, #  120 = Alt-1 -> #\META-1
    { NULL, '2', char_meta_c }, #  121 = Alt-2 -> #\META-2
    { NULL, '3', char_meta_c }, #  122 = Alt-3 -> #\META-3
    { NULL, '4', char_meta_c }, #  123 = Alt-4 -> #\META-4
    { NULL, '5', char_meta_c }, #  124 = Alt-5 -> #\META-5
    { NULL, '6', char_meta_c }, #  125 = Alt-6 -> #\META-6
    { NULL, '7', char_meta_c }, #  126 = Alt-7 -> #\META-7
    { NULL, '8', char_meta_c }, #  127 = Alt-8 -> #\META-8
    { NULL, '9', char_meta_c }, #  128 = Alt-9 -> #\META-9
    { NULL, '0', char_meta_c }, #  129 = Alt-0 -> #\META-0
    { NULL, '-', char_meta_c }, #  130 = Alt-- -> #\META-- # not internationally portable
    { NULL, '=', char_meta_c }, #  131 = Alt-= -> #\META-= # not internationally portable
    { "PGUP", 0, char_control_c | char_hyper_c }, # 132 = Control-PgUp -> #\C-PgUp
    { "F11", 0, char_hyper_c }, #  133 = F11 -> #\F11
    { "F12", 0, char_hyper_c }, #  134 = F12 -> #\F12
    { "F11", 0, char_super_c | char_hyper_c }, #  135 = Shift-F11 -> #\S-F11
    { "F12", 0, char_super_c | char_hyper_c }, #  136 = Shift-F12 -> #\S-F12
    { "F11", 0, char_control_c | char_hyper_c }, #  137 = Control-F11 -> #\C-F11
    { "F12", 0, char_control_c | char_hyper_c }, #  138 = Control-F12 -> #\C-F12
    { "F11", 0, char_meta_c | char_hyper_c }, #  139 = Alt-F1 -> #\M-F11
    { "F12", 0, char_meta_c | char_hyper_c }, #  140 = Alt-F2 -> #\M-F12
    { "UP", 0, char_control_c | char_hyper_c }, # 141 = Control-Up -> #\C-Up
    { NULL, '-', char_control_c | char_hyper_c }, # 142 = Control-- -> #\CONTROL-HYPER--
    { "CENTER", 0, char_control_c | char_hyper_c }, # 143 = Control-Keypad5 -> #\C-Center
    { NULL, '+', char_control_c | char_hyper_c }, # 142 = Control-+ -> #\CONTROL-HYPER-+
    { "DOWN", 0, char_control_c | char_hyper_c }, # 145 = Control-Down -> #\C-Down
    { "INSERT", 0, char_control_c | char_hyper_c }, # 146 = Control-Insert -> #\C-Insert
    { "DELETE", 0, char_control_c | char_hyper_c }, # 147 = Control-Delete -> #\C-Delete
    { NULL,   9, char_control_c }, # 148 = Control-Tab -> #\CONTROL-Tab
    { NULL, '/', char_control_c | char_hyper_c }, # 149 = Control-/ -> #\CONTROL-HYPER-'/'
    { NULL, '*', char_control_c | char_hyper_c }, # 150 = Control-* -> #\CONTROL-HYPER-'*'
    { "HOME", 0, char_meta_c | char_hyper_c }, # 151 = Alt-Home -> #\M-Home
    { "UP", 0, char_meta_c | char_hyper_c }, # 152 = Alt-Up -> #\M-Up
    { "PGUP", 0, char_meta_c | char_hyper_c }, # 153 = Alt-PgUp -> #\M-PgUp
    { NULL, 0, 0 },
    { "LEFT", 0, char_meta_c | char_hyper_c }, # 155 = Alt-Left -> #\M-Left
    { "CENTER", 0, char_meta_c | char_hyper_c }, # [156 -> #\META-Center]
    { "RIGHT", 0, char_meta_c | char_hyper_c }, # 157 = Alt-Right -> #\M-Right
    { NULL, 0, 0 },
    { "END", 0, char_meta_c | char_hyper_c }, # 159 = Alt-End -> #\M-End
    { "DOWN", 0, char_meta_c | char_hyper_c }, # 160 = Alt-Down -> #\M-Down
    { "PGDN", 0, char_meta_c | char_hyper_c }, # 161 = Alt-PgDn -> #\M-PgDn
    { "INSERT", 0, char_meta_c | char_hyper_c }, # 162 = Alt-Insert -> #\M-Insert
    { "DELETE", 0, char_meta_c | char_hyper_c }, # 163 = Alt-Delete -> #\M-Delete
    { NULL, '/', char_meta_c | char_hyper_c }, # 164 = Alt-/ -> #\META-HYPER-'/'
    { NULL,   9, char_meta_c }, # 165 = Alt-Tab -> #\META-Tab
    { NULL,  CR, char_meta_c | char_hyper_c }, # 166 = Alt-Enter -> #\META-HYPER-Return
    };

#ifdef EMUNIX

# We have, in order to remain portable, only the Function _read_kbd at our disposal.
# On DOS this function recognizes only few special keys: only the ones with
# Scan-Codes 3, 7, 15-25, 30-38, 44-50, 59-131 (approximately).
# In particular F11, F12, Ctrl-Up, Ctrl-Down are missing, and one cannot
# distinguish Enter from Return, Tab from Ctrl-I, Backspace from Ctrl-H.
# Anyhow!
# As INT 16,10 on DOS finally works satisfactory since emx 0.8f,
# we use it. At runtime _osmode is checked.

#endif # EMUNIX

#endif # MSDOS

# Determines, if a Character is available on the Keyboard-Stream.
# listen_char_keyboard(stream)
# > stream: Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
#ifdef EMUNIX
local signean listen_char_keyboard (object stream) {
  if (_osmode != DOS_MODE) { # OS/2
    var int ch = _read_kbd(false,false,false);
    if (ch < 0)
      return ls_wait; # no
    pushSTACK(stream);
    var object c;
    if (ch==0) {
      c = make_key_event(&scancode_table[(uintB)_read_kbd(false,true,false)]);
    } else if ((ch <= 26) && !(ch == BS) && !(ch == CR) && !(ch == TAB)) {
      # from Ctrl-A to Ctrl-Z -> make a letter with CONTROL-Bit out of it:
      var key_event event;
      event.key = NULL;
      event.code = ascii(ch==LF ? CR : (ch | bit(6)));
      event.bits = char_control_c;
      c = make_key_event(&event);
    } else {
      pushSTACK(code_char(ch)); funcall(S(make_char),1); c = value1;
    }
    stream = popSTACK();
    TheStream(stream)->strm_rd_ch_last = c;
    TheStream(stream)->strmflags |= strmflags_unread_B;
    return ls_avail;
  } else { # DOS
    if (kbhit()) { # key pressed in the meantime?
      return ls_avail; # yes
    } else {
      return ls_wait; # no
    }
  }
}
#endif
#ifdef WIN32_NATIVE
local signean listen_char_keyboard (object stream) {
  var Handle handle = TheHandle(TheStream(stream)->strm_keyboard_handle);
  # See the implementation of listen_char_unbuffered() for consoles.
  var DWORD nevents;
  begin_system_call();
  if (!GetNumberOfConsoleInputEvents(handle,&nevents)) {
    OS_error();
  }
  # It's a console.
  if (nevents==0) { # no character available
    end_system_call(); return ls_wait;
  }
  var INPUT_RECORD* events = (INPUT_RECORD*)alloca(nevents*sizeof(INPUT_RECORD));
  var DWORD nevents_read;
  if (!PeekConsoleInput(handle,events,nevents,&nevents_read)) {
    OS_error();
  }
  if (nevents_read==0) { # no character available
    end_system_call(); return ls_wait;
  }
  { # Look out for any Key-Down event.
    var DWORD i;
    for (i = 0; i < nevents_read; i++) {
      if (events[i].EventType == KEY_EVENT
          && events[i].Event.KeyEvent.bKeyDown
          && events[i].Event.KeyEvent.uAsciiChar != 0) {
        # character available
        end_system_call(); return ls_avail;
      }
    }
  }
  # no character available
  end_system_call(); return ls_wait;
}
#endif
#if (defined(UNIX) && !defined(NEXTAPP)) || defined(RISCOS)
  #define listen_char_keyboard  listen_char_unbuffered
#endif
#if defined(NEXTAPP)
  #define listen_char_keyboard(stream)  (stream, ls_eof)
#endif

# UP: Deletes already entered interactive Input from a Keyboard-Stream.
# clear_input_keyboard(stream);
# > stream: Stream
# < result: true if Input was deleted, else false
local bool clear_input_keyboard (object stream) {
 #ifdef EMUNIX
  if (_osmode != DOS_MODE) { # OS/2
    while (listen_char_keyboard(stream)) {
      # the character has already been fetched!
    }
  } else { # DOS
    while (kbhit()) { getch(); }
  }
 #endif
 #ifdef WIN32_NATIVE
  clear_tty_input(TheHandle(TheStream(stream)->strm_keyboard_handle));
  pushSTACK(stream);
  while (ls_avail_p(listen_char_keyboard(STACK_0))) {
    read_char(&STACK_0);
  }
  skipSTACK(1);
 #endif
 #if (defined(UNIX) && !defined(NEXTAPP)) || defined(RISCOS)
  if (nullp(TheStream(stream)->strm_keyboard_isatty)) # File -> do nothing
    return false;
  # Terminal
  TheStream(stream)->strm_rd_ch_last = NIL; # EOF forgotten
  clear_tty_input(stdin_handle);
  pushSTACK(stream);
  while (ls_avail_p(listen_char_keyboard(STACK_0))) {
    read_char(&STACK_0);
  }
  skipSTACK(1);
 #endif
  return true;
}

# Read a character from Keyboard:
#ifdef EMUNIX
local object rd_ch_keyboard (const object* stream_) {
  if (_osmode != DOS_MODE) { # OS/2
    run_time_stop(); # hold run time clock
    var object c;
    var int ch = _read_kbd(false,true,false);
    if (ch==0) {
      c = make_key_event(&scancode_table[(uintB)_read_kbd(false,true,false)]);
    } else if ((ch <= 26) && !(ch == BS) && !(ch == CR) && !(ch == TAB)) {
      # from Ctrl-A to Ctrl-Z -> make a letter with CONTROL-Bit out of it:
      var key_event event;
      event.key = NULL;
      event.code = ascii(ch==LF ? CR : (ch | bit(6)));
      event.bits = char_control_c;
      c = make_key_event(&event);
    } else {
      pushSTACK(code_char(ch)); funcall(S(make_char),1); c = value1;
    }
    # still to handle: ??
    # Ctrl-2 -> #\Control-2, Ctrl-6 -> #\Code30, Ctrl-ß -> #\Code28,
    # Ctrl-+ -> #\Code29, Ctrl-ü -> #\Code27 = #\Escape
    run_time_restart(); # resume run time clock
    return c;
  } else { # DOS
    var object c;
    run_time_stop(); # hold run time clock
    {
      # wait for keystroke, no output:
      var uintW erg = getch();
      var uintB code = (uintB)erg; # Ascii-Code
      var uintB scancode = (uintB)(erg>>8); # Scan-Code
      if (scancode == 0) {
        # Multikey-Event, e.g. accent+space or Alt xyz
        # FIXME: This should take into account the encoding.
        pushSTACK(code_char(as_chart(code))); funcall(S(make_char),1);
        c = value1;
      } else {
        if ((code == 0) || (code == 0xE0)) {
          # special key
          if (scancode < 167) {
            c = make_key_event(&scancode_table[scancode]);
          } else {
            var key_event event = { NULL, 0, 0 };
            c = make_key_event(&event);
          }
        } else {
          if (((scancode >= 71) && (scancode < 84)) || (scancode == 55)
              || ((scancode == 0xE0) && (code >= 32))) {
            # key on the numerical pad except Enter (also excluding F1 to F12!)
            var key_event event;
            event.key = NULL;
            event.code = as_chart(code);
            event.bits = char_hyper_c;
            c = make_key_event(&event);
          } else if ((scancode == 14) || (scancode == 28)
                     || ((scancode == 0xE0) && (code < 32))) {
            # Backspace-Key, Return-Key, Enter-Key
            var uintB defaultcode = (scancode==14 ? BS : CR);
            var key_event event;
            event.key = NULL;
            event.code = as_chart(defaultcode);
            event.bits = (scancode == 0xE0 ? char_hyper_c : 0)
              | (!(code == defaultcode) ? char_control_c : 0);
            c = make_key_event(&event);
          } else {
            if ((code < 32) && ((scancode >= 16) && (scancode <= 53))) {
              # from Ctrl-A to Ctrl-Z -> make letter with CONTROL-Bit out of it
              var key_event event;
              event.key = NULL;
              event.code = ascii(code | bit(6));
              event.bits = char_control_c;
              c = make_key_event(&event);
            } else {
              # normal character
              # FIXME: This should take into account the encoding.
              pushSTACK(code_char(as_chart(code))); funcall(S(make_char),1); c = value1;
            }
          }
        }
      }
      # still to handle: ??
      # Ctrl-2          0300
      # Ctrl-6          071E
      # Ctrl-ß          0C1C
      # Ctrl--          0C1F
    }
    run_time_restart(); # resume run time clock
    return c;
  }
}
#endif

#ifdef WIN32_NATIVE
local object rd_ch_keyboard (const object* stream_) {
  var INPUT_RECORD event;
  var DWORD nevents_read;
  var Handle handle;
 restart_it:
  handle = TheHandle(TheStream(*stream_)->strm_keyboard_handle);
  begin_system_call();
  loop {
    if (!ReadConsoleInput1(handle,&event,&nevents_read)) {
      if (GetLastError()==ERROR_SIGINT) { # Break by Ctrl-C ?
        end_system_call();
        pushSTACK(S(read_char)); tast_break(); # call Break-Loop
        goto restart_it;
      }
      OS_error();
    }
    ASSERT(nevents_read==1);
    if (event.EventType == KEY_EVENT && event.Event.KeyEvent.bKeyDown) {
      var key_event ev;
      if (event.Event.KeyEvent.wRepeatCount > 1) {
        var DWORD nevents_written;
        event.Event.KeyEvent.wRepeatCount--;
        if (!WriteConsoleInput(handle,&event,1,&nevents_written)) {
          OS_error();
        }
      }
      if ((uintB)event.Event.KeyEvent.uAsciiChar <= ' ') {
        # Translate Virtual Keycode.
        local struct { WORD vkcode; key_event myevent; } vktable[] = {
          VK_BACK,    { NULL,  BS, 0 },               # #\Backspace
          VK_TAB,     { NULL, TAB, 0 },               # #\Tab
          VK_RETURN,  { NULL,  CR, 0 },               # #\Return
          VK_ESCAPE,  { NULL, ESC, 0 },               # #\Escape
          VK_LEFT,    { "LEFT", 0, char_hyper_c },    # #\Left
          VK_RIGHT,   { "RIGHT", 0, char_hyper_c },   # #\Right
          VK_UP,      { "UP", 0, char_hyper_c },      # #\Up
          VK_DOWN,    { "DOWN", 0, char_hyper_c },    # #\Down
          VK_PRIOR,   { "PGUP", 0, char_hyper_c },    # #\PgUp
          VK_NEXT,    { "PGDN", 0, char_hyper_c },    # #\PgDn
          VK_HOME,    { "HOME", 0, char_hyper_c },    # #\Home
          VK_END,     { "END", 0, char_hyper_c },     # #\End
          VK_INSERT,  { "INSERT", 0, char_hyper_c },  # #\Insert
          VK_DELETE,  { "DELETE", 0, char_hyper_c },  # #\Delete
          12,         { "CENTER", 0, char_hyper_c },  # #\Center
          VK_F1,      { "F1", 0, char_hyper_c },      # #\F1
          VK_F2,      { "F2", 0, char_hyper_c },      # #\F2
          VK_F3,      { "F3", 0, char_hyper_c },      # #\F3
          VK_F4,      { "F4", 0, char_hyper_c },      # #\F4
          VK_F5,      { "F5", 0, char_hyper_c },      # #\F5
          VK_F6,      { "F6", 0, char_hyper_c },      # #\F6
          VK_F7,      { "F7", 0, char_hyper_c },      # #\F7
          VK_F8,      { "F8", 0, char_hyper_c },      # #\F8
          VK_F9,      { "F9", 0, char_hyper_c },      # #\F9
          VK_F10,     { "F10", 0, char_hyper_c },     # #\F10
          VK_F11,     { "F11", 0, char_hyper_c },     # #\F11
          VK_F12,     { "F12", 0, char_hyper_c },     # #\F12
          VK_LWIN,    { "WIN", 0, char_hyper_c },     # Win key
          VK_RWIN,    { "WIN", 0, char_hyper_c },     # Same
          ' ',        { NULL, ' ', 0 },               # #\Space
          '0',        { NULL, '0', 0 },               # #\0
          '1',        { NULL, '1', 0 },               # #\1
          '2',        { NULL, '2', 0 },               # #\2
          '3',        { NULL, '3', 0 },               # #\3
          '4',        { NULL, '4', 0 },               # #\4
          '5',        { NULL, '5', 0 },               # #\5
          '6',        { NULL, '6', 0 },               # #\6
          '7',        { NULL, '7', 0 },               # #\7
          '8',        { NULL, '8', 0 },               # #\8
          '9',        { NULL, '9', 0 },               # #\9
          'A',        { NULL, 'A', 0 },               # #\A
          'B',        { NULL, 'B', 0 },               # #\B
          'C',        { NULL, 'C', 0 },               # #\C
          'D',        { NULL, 'D', 0 },               # #\D
          'E',        { NULL, 'E', 0 },               # #\E
          'F',        { NULL, 'F', 0 },               # #\F
          'G',        { NULL, 'G', 0 },               # #\G
          'H',        { NULL, 'H', 0 },               # #\H
          'I',        { NULL, 'I', 0 },               # #\I
          'J',        { NULL, 'J', 0 },               # #\J
          'K',        { NULL, 'K', 0 },               # #\K
          'L',        { NULL, 'L', 0 },               # #\L
          'M',        { NULL, 'M', 0 },               # #\M
          'N',        { NULL, 'N', 0 },               # #\N
          'O',        { NULL, 'O', 0 },               # #\O
          'P',        { NULL, 'P', 0 },               # #\P
          'Q',        { NULL, 'Q', 0 },               # #\Q
          'R',        { NULL, 'R', 0 },               # #\R
          'S',        { NULL, 'S', 0 },               # #\S
          'T',        { NULL, 'T', 0 },               # #\T
          'U',        { NULL, 'U', 0 },               # #\U
          'V',        { NULL, 'V', 0 },               # #\V
          'W',        { NULL, 'W', 0 },               # #\W
          'X',        { NULL, 'X', 0 },               # #\X
          'Y',        { NULL, 'Y', 0 },               # #\Y
          'Z',        { NULL, 'Z', 0 },               # #\Z
          107,        { NULL, '+', char_hyper_c },    # #\HYPER-+
          109,        { NULL, '-', char_hyper_c },    # #\HYPER--
          106,        { NULL, '*', char_hyper_c },    # #\HYPER-*
          111,        { NULL, '/', char_hyper_c },    # #\HYPER-/
          186,        { NULL, ';', 0 },               # #\;
          187,        { NULL, '=', 0 },               # #\=
          188,        { NULL, ',', 0 },               # #\,
          189,        { NULL, '-', 0 },               # #\-
          190,        { NULL, '.', 0 },               # #\.
          191,        { NULL, '/', 0 },               # #\/
          192,        { NULL, '`', 0 },               # #\`
          219,        { NULL, '[', 0 },               # #\[
          220,        { NULL, '\\', 0 },              # #\\
          221,        { NULL, ']', 0 },               # #\]
          222,        { NULL, '\'', 0 },              # #\'
        };
        var int i;
        for (i = 0; i < sizeof(vktable)/sizeof(vktable[0]); i++) {
          if (event.Event.KeyEvent.wVirtualKeyCode == vktable[i].vkcode) {
            ev = vktable[i].myevent; goto found_keycode;
          }
        }
        switch (event.Event.KeyEvent.wVirtualKeyCode) {
          case VK_SHIFT:
          case VK_CONTROL:
          case 18: case 20:
            break;
          default:
            asciz_out_3("Unknown keyboard event, VKeyCode = %d, VScanCode = %d, AsciiChar = %d\n",event.Event.KeyEvent.wVirtualKeyCode,event.Event.KeyEvent.wVirtualScanCode,event.Event.KeyEvent.uAsciiChar);
        }
        continue;
      found_keycode:
        if (event.Event.KeyEvent.dwControlKeyState & SHIFT_PRESSED)
          ev.bits |= char_super_c;
        if (event.Event.KeyEvent.dwControlKeyState
            & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED))
          ev.bits |= char_control_c;
        if (event.Event.KeyEvent.dwControlKeyState
            & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED))
          ev.bits |= char_meta_c;
      } else {
       #ifdef UNICODE
        var object encoding = TheStream(*stream_)->strm_encoding;
        var chart c = as_chart(0);
        var uintB buf[max_bytes_per_chart];
        var chart* cptr  = &c;
        var char* bptr   = buf;
        memset(buf,0,max_bytes_per_chart);
        buf[0] = (uintB) event.Event.KeyEvent.uAsciiChar;
        Encoding_mbstowcs(encoding)
          (encoding,*stream_,&bptr,bptr+max_bytes_per_chart,&cptr,cptr+1);
       #else
        var chart c = event.Event.KeyEvent.uAsciiChar;
        var cint ci = as_cint(c);
        OemToCharBuff((char *)&ci,(char *)&ci,1);
        c = as_chart(ci);
       #endif
        ev.key = NULL;
        ev.code = c;
        ev.bits = 0;
        if (event.Event.KeyEvent.dwControlKeyState &
            (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) {
          # c = 'a'..'z' -> translate to 'A'..'Z'
          # c = 'A'..'Z' -> add "Shift"
          # c = '<','>' etc. -> don't add "Shift"
          ev.code = up_case(ev.code);
          if (!chareq(ev.code,down_case(ev.code))) {
            if (event.Event.KeyEvent.dwControlKeyState & SHIFT_PRESSED)
              ev.bits |= char_super_c;
          }
          ev.bits |= char_meta_c;
        }
      }
      end_system_call();
      return make_key_event(&ev);
    }
    # Other events are silently thrown away.
  }
}
#endif

#if (defined(UNIX) && !defined(NEXTAPP)) || defined(RISCOS)
# cf. rd_ch_unbuffered() :
local object rd_ch_keyboard (const object* stream_) {
 restart_it:
  var object stream = *stream_;
  if (eq(TheStream(stream)->strm_rd_ch_last,eof_value)) # EOF already?
    return eof_value;
  # Still something in the Buffer?
  if (mconsp(TheStream(stream)->strm_keyboard_buffer))
    goto empty_buffer;
  # read a character:
  {
    var uintB c;
  read_next_char:
    {
      run_time_stop(); # hold run time clock
      begin_system_call();
      var int result = read(stdin_handle,&c,1); # try to read a byte
      end_system_call();
      run_time_restart(); # resume run time clock
      if (result<0) {
        begin_system_call();
        if (errno==EINTR) { # break (poss. by Ctrl-C) ?
          end_system_call();
          interruptp({ pushSTACK(S(read_char)); tast_break(); }); # call Break-Loop
          goto restart_it;
        }
        OS_error();
      }
      if (result==0) {
        # no character available -> recognize EOF
        TheStream(stream)->strm_rd_ch_last = eof_value; return eof_value;
      }
    }
  next_char_is_read:
    # It increases the Buffer:
    {
      var object new_cons = allocate_cons();
      Car(new_cons) = code_char(as_chart(c)); # FIXME: This should take into account the encoding.
      stream = *stream_;
      var object* last_ = &TheStream(stream)->strm_keyboard_buffer;
      while (mconsp(*last_)) { last_ = &Cdr(*last_); }
      *last_ = new_cons;
    }
    # Is the buffer a complete sequence of characters for a key,
    # so we will return this key. Is the buffer a genuine starting piece
    # of a sequence of characters for a key, so we will wait a little bit.
    # Otherwise we start to empty the buffer character for character.
    {
      var object keytab = TheStream(stream)->strm_keyboard_keytab;
      while (consp(keytab)) {
        var object L1 = Car(keytab);
        keytab = Cdr(keytab);
        var object L2 = TheStream(stream)->strm_keyboard_buffer;
        while (consp(L1) && consp(L2) && eq(Car(L1),Car(L2))) {
          L1 = Cdr(L1); L2 = Cdr(L2);
        }
        if (atomp(L2)) {
          if (atomp(L1)) {
            # complete sequence of characters
            TheStream(stream)->strm_keyboard_buffer = NIL;
            return L1;
          }
        }
      }
    }
    {
      var object keytab = TheStream(stream)->strm_keyboard_keytab;
      while (consp(keytab)) {
        var object L1 = Car(keytab);
        keytab = Cdr(keytab);
        var object L2 = TheStream(stream)->strm_keyboard_buffer;
        while (consp(L1) && consp(L2) && eq(Car(L1),Car(L2))) {
          L1 = Cdr(L1); L2 = Cdr(L2);
        }
        if (atomp(L2))
          # As consp(L1), the starting piece of a sequence of characters is there.
          goto wait_for_another;
      }
    }
    goto empty_buffer;
  wait_for_another:
  #if defined(HAVE_SELECT) && !defined(UNIX_BEOS)
    {
      # Use select with readfds = one-element set {stdin_handle}
      # and timeout = small time-interval.
      var fd_set handle_menge; # set of handles := {stdin_handle}
      var struct timeval small_time; # time-interval := 0
      FD_ZERO(&handle_menge); FD_SET(stdin_handle,&handle_menge);
    restart_select:
      small_time.tv_sec = 0; small_time.tv_usec = 1000000/10; # 1/10 sec
      run_time_stop(); # hold run time clock
      begin_system_call();
      var int result;
      result = select(FD_SETSIZE,&handle_menge,NULL,NULL,&small_time);
      end_system_call();
      run_time_restart(); # resume run time clock
      if (result<0) {
        begin_system_call();
        if (errno==EINTR) {
          end_system_call(); goto restart_select;
        }
        if (!(errno == EBADF)) {
          OS_error();
        }
        end_system_call();
      } else {
        # result = number of Handles in handle_menge, for which read
        # would return a result immediately.
        if (result==0)
          goto empty_buffer; # no character available
        # result=1 -> character available
      }
    }
  #else
   #if defined(UNIX_TERM_TERMIOS) || defined(UNIX_TERM_TERMIO)
    {
      # Use the Termio-Elements VMIN and VTIME.
     #ifdef UNIX_TERM_TERMIOS
      var struct termios oldtermio;
      var struct termios newtermio;
     #else # UNIX_TERM_TERMIO
      var struct termio oldtermio;
      var struct termio newtermio;
     #endif
      run_time_stop(); # hold run time clock
      begin_system_call();
     #ifdef UNIX_TERM_TERMIOS
      if (!( tcgetattr(stdin_handle,&oldtermio) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); }
      }
     #else
      if (!( ioctl(stdin_handle,TCGETA,&oldtermio) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); }
      }
     #endif
      # We assume now, that oldtermio is now identical with the newtermio
      # from term_raw() (see below). This is ensured, if
      # 1. (SYS::TERMINAL-RAW T) was called and
      # 2. stdin_handle and stdout_handle both are the same Terminal. ??
      newtermio = oldtermio;
      newtermio.c_cc[VMIN] = 0;
      newtermio.c_cc[VTIME] = 1; # 1/10 second timeout
     #ifdef UNIX_TERM_TERMIOS
      if (!( TCSETATTR(stdin_handle,TCSANOW,&newtermio) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); }
      }
     #else
      if (!( ioctl(stdin_handle,TCSETA,&newtermio) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); }
      }
     #endif
      var int result = read(stdin_handle,&c,1); # try to read a byte, with timeout
     #ifdef UNIX_TERM_TERMIOS
      if (!( TCSETATTR(stdin_handle,TCSANOW,&oldtermio) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); }
      }
     #else
      if (!( ioctl(stdin_handle,TCSETA,&oldtermio) ==0)) {
        if (!(errno==ENOTTY)) { OS_error(); }
      }
     #endif
      end_system_call();
      run_time_restart(); # resume run time clock
      if (result<0) {
        begin_system_call();
        if (errno==EINTR) { # break (poss. by Ctrl-C) ?
          end_system_call();
          interruptp({ pushSTACK(S(read_char)); tast_break(); }); # call Break-Loop
          goto restart_it;
        }
        OS_error();
      }
      if (result==0)
        goto empty_buffer; # no character available
      goto next_char_is_read; # result=1 -> character available
    }
   #else
    # One could use fcntl(stdin_handle,F_SETFL,...|FASYNC) here
    # and wait for the Signal SIGIO. But this works only on so
    # few Systems (see Emacs), that it does not pay off.
   #endif
  #endif
    goto read_next_char;
  }
  # return buffer character for character:
 empty_buffer:
  {
    var object l = TheStream(stream)->strm_keyboard_buffer;
    TheStream(stream)->strm_keyboard_buffer = Cdr(l);
    var cint c = as_cint(char_code(Car(l)));
    if ((c >= ' ') || (c == ESC) || (c == TAB) || (c == CR) || (c == BS)) {
      # FIXME: This should take into account the encoding.
      pushSTACK(code_char(as_chart(c))); funcall(S(make_char),1);
      return value1;
    } else {
      # key presumably pressed with Ctrl
      var key_event event;
      event.key = NULL;
      event.code = ascii(c == 0 ? ' ' : (c | bit(6)));
      event.bits = char_control_c;
      return make_key_event(&event);
    }
  }
}

# UP: extends the List STACK_0 by one key-assignment.
# can trigger GC
local void add_keybinding (const char* cap, const key_event* event) {
  var const uintB* ptr = (const uintB*)cap;
  if (*ptr=='\0') # avoid empty key-sequence
    return;
  # FIXME: This should take into account the encoding.
  pushSTACK(allocate_cons());
  # create List (char1 ... charn . key) :
  {
    var uintC count = 0;
    do {
      pushSTACK(code_char(as_chart(*ptr))); ptr++; count++;
    } until (*ptr=='\0');
    pushSTACK(make_key_event(event)); count++;
    funcall(L(liststern),count);
  }
  # and push on STACK_0:
  {
    var object l = popSTACK();
    Car(l) = value1; Cdr(l) = STACK_0; STACK_0 = l;
  }
}
#define keybinding(cap,initializer)  \
  do { key_event event = initializer; add_keybinding(cap,&event); } while(0)
#endif

#ifdef NEXTAPP
  #define rd_ch_keyboard  rd_ch_error
#endif

# returns a Keyboard-Stream.
# make_keyboard_stream()
# can trigger GC
local object make_keyboard_stream (void) {
 #if (defined(UNIX) && !defined(NEXTAPP)) || defined(RISCOS)
  {
    # build Table of all assignments character-sequence -> Key :
    pushSTACK(NIL);
    # query Terminal-Type:
    begin_system_call();
    var const char* s = getenv("TERM");
    if (s==NULL) {
      end_system_call();
    } else {
      var char tbuf[4096]; # internal Buffer for the Termcap-Routines
      if (!(tgetent(tbuf,s)==1)) {
        end_system_call();
      } else {
        var char tentry[4096]; # Buffer for the Capabilities that I need
        var char* tp = &tentry[0];
        var const char* cap;
        end_system_call();
        # Backspace:
        begin_system_call(); cap = tgetstr("kb",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_ascii(BS)); # #\Backspace
        # Insert, Delete:
        begin_system_call(); cap = tgetstr("kI",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("INSERT")); # #\Insert
        begin_system_call(); cap = tgetstr("kD",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("DELETE")); # #\Delete
        # arrow keys:
        begin_system_call(); cap = tgetstr("ku",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("UP")); # #\Up
        if (cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'A') && (cap[3] == '\0'))
          keybinding(ESCstring"[A", key_special("UP")); # #\Up
        begin_system_call(); cap = tgetstr("kd",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("DOWN")); # #\Down
        if (cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'B') && (cap[3] == '\0'))
          keybinding(ESCstring"[B", key_special("DOWN")); # #\Down
        begin_system_call(); cap = tgetstr("kr",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("RIGHT")); # #\Right
        if (cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'C') && (cap[3] == '\0'))
          keybinding(ESCstring"[C", key_special("RIGHT")); # #\Right
        begin_system_call(); cap = tgetstr("kl",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("LEFT")); # #\Left
        if (cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'D') && (cap[3] == '\0'))
          keybinding(ESCstring"[D", key_special("LEFT")); # #\Left
        # other cursorblock-keys:
        begin_system_call(); cap = tgetstr("kh",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("HOME")); # #\Home
        begin_system_call(); cap = tgetstr("K1",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("HOME")); # #\Home
        begin_system_call(); cap = tgetstr("KH",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("END")); # #\End
        begin_system_call(); cap = tgetstr("K4",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("END")); # #\End
        begin_system_call(); cap = tgetstr("kP",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("PGUP")); # #\PgUp
        begin_system_call(); cap = tgetstr("K3",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("PGUP")); # #\PgUp
        begin_system_call(); cap = tgetstr("kN",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("PGDN")); # #\PgDn
        begin_system_call(); cap = tgetstr("K5",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("PGDN")); # #\PgDn
        begin_system_call(); cap = tgetstr("K2",&tp); end_system_call();
        if (cap)
          keybinding(cap, key_special("CENTER")); # #\Center
        # Function Keys:
        {
          typedef struct { const char* capname; key_event key; } funkey;
          local var const funkey funkey_tab[] = {
            { "k1", key_special("F1") }, # #\F1
            { "k2", key_special("F2") }, # #\F2
            { "k3", key_special("F3") }, # #\F3
            { "k4", key_special("F4") }, # #\F4
            { "k5", key_special("F5") }, # #\F5
            { "k6", key_special("F6") }, # #\F6
            { "k7", key_special("F7") }, # #\F7
            { "k8", key_special("F8") }, # #\F8
            { "k9", key_special("F9") }, # #\F9
            { "k0", key_special("F10") }, # #\F10
            { "k;", key_special("F10") }, # #\F10
            { "F1", key_special("F11") }, # #\F11
            { "F2", key_special("F12") }, # #\F12
          };
          var uintL i;
          for (i=0; i < sizeof(funkey_tab)/sizeof(funkey); i++) {
            begin_system_call();
            cap = tgetstr(funkey_tab[i].capname,&tp);
            end_system_call();
            if (cap)
              add_keybinding(cap,&funkey_tab[i].key);
          }
        }
        # Special Linux console handling:
        begin_system_call();
        cap = tgetstr("kh",&tp); # Home
        if (!(cap && (cap[0] == ESC) && (cap[1] == '[') && (cap[2] == '1') && (cap[3] == '~') && (cap[4] == '\0')))
          goto not_linux;
        cap = tgetstr("kI",&tp); # Insert
        if (!(cap && (cap[0] == ESC) && (cap[1] == '[') && (cap[2] == '2') && (cap[3] == '~') && (cap[4] == '\0')))
          goto not_linux;
        cap = tgetstr("kD",&tp); # Delete
        if (!(cap && (cap[0] == ESC) && (cap[1] == '[') && (cap[2] == '3') && (cap[3] == '~') && (cap[4] == '\0')))
          goto not_linux;
        end_system_call();
        keybinding(ESCstring"[4~", key_special("END")); # #\End
        if (false) {
        not_linux:
          end_system_call();
        }
        # Special xterm handling:
        begin_system_call();
        cap = tgetstr("ku",&tp);
        if (!(cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'A') && (cap[3] == '\0')))
          goto not_xterm;
        cap = tgetstr("kd",&tp);
        if (!(cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'B') && (cap[3] == '\0')))
          goto not_xterm;
        cap = tgetstr("kr",&tp);
        if (!(cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'C') && (cap[3] == '\0')))
          goto not_xterm;
        cap = tgetstr("kl",&tp);
        if (!(cap && (cap[0] == ESC) && (cap[1] == 'O') && (cap[2] == 'D') && (cap[3] == '\0')))
          goto not_xterm;
        end_system_call();
        # Insert, Delete:
        keybinding(ESCstring"[2~", key_special("INSERT")); # #\Insert
        keybinding(ESCstring"[3~", key_special("DELETE")); # #\Delete
        {
          # Application Keypad: ESC O M -> Return,
          # ESC O k -> +, ESC O m -> -, ESC O j -> *, ESC O o -> /
          # (without Hyper-Bit, because that is too terminal-specific)
          # ESC O x -> Up, ESC O r -> Down,
          # ESC O v -> Right, ESC O t -> Left,
          # ESC O p -> Insert, ESC O l -> Delete.
          var char cap[4];
          cap[0] = ESC; cap[1] = 'O'; cap[3] = '\0';
          cap[2] = 'M'; keybinding(&!cap, key_ascii('M'-64));
          cap[2] = '+'+64; keybinding(&!cap, key_ascii('+'));
          cap[2] = '-'+64; keybinding(&!cap, key_ascii('-'));
          cap[2] = '*'+64; keybinding(&!cap, key_ascii('*'));
          cap[2] = '/'+64; keybinding(&!cap, key_ascii('/'));
          cap[2] = '8'+64; keybinding(&!cap, key_special("UP")); # #\Up
          cap[2] = '2'+64; keybinding(&!cap, key_special("DOWN")); # #\Down
          cap[2] = '6'+64; keybinding(&!cap, key_special("RIGHT")); # #\Right
          cap[2] = '4'+64; keybinding(&!cap, key_special("LEFT")); # #\Left
          cap[2] = '0'+64; keybinding(&!cap, key_special("INSERT")); # #\Insert
          cap[2] = '.'+64; keybinding(&!cap, key_special("DELETE")); # #\Delete
          cap[2] = ','+64; keybinding(&!cap, key_special("DELETE")); # #\Delete
          # "7" -> #\Home, "1" -> #\End, "9" -> #\PgUp, "3" -> #\PgDn,
          # "5" -> #\Center are already handled above.
        }
      xterm:
        # arrow keys (see above)
        # other cursorblock-keys:
        keybinding(ESCstring"[5~", key_special("PGUP")); # #\PgUp
        keybinding(ESCstring"[6~", key_special("PGDN")); # #\PgDn
        keybinding(ESCstring"[7~", key_special("HOME")); # #\Home
        keybinding(ESCstring"[8~", key_special("END")); # #\End
        keybinding(ESCstring"OH", key_special("HOME")); # #\Home
        keybinding(ESCstring"[H", key_special("HOME")); # #\Home
        keybinding(ESCstring"OF", key_special("END")); # #\End
        keybinding(ESCstring"[F", key_special("END")); # #\End
        # function-keys:
        keybinding(ESCstring"[11~", key_special("F1")); # #\F1
        keybinding(ESCstring"[12~", key_special("F2")); # #\F2
        keybinding(ESCstring"[13~", key_special("F3")); # #\F3
        keybinding(ESCstring"[14~", key_special("F4")); # #\F4
        keybinding(ESCstring"[15~", key_special("F5")); # #\F5
        keybinding(ESCstring"[17~", key_special("F6")); # #\F6
        keybinding(ESCstring"[18~", key_special("F7")); # #\F7
        keybinding(ESCstring"[19~", key_special("F8")); # #\F8
        keybinding(ESCstring"[20~", key_special("F9")); # #\F9
        keybinding(ESCstring"[21~", key_special("F10")); # #\F10
        keybinding(ESCstring"[23~", key_special("F11")); # #\F11
        keybinding(ESCstring"[24~", key_special("F12")); # #\F12
        if (false) {
        not_xterm:
          end_system_call();
        }
      }
    }
  }
  pushSTACK(allocate_handle(stdin_handle));
 #endif
 #ifdef WIN32_NATIVE
  # build Console-Handle:
  # Maybe use CREATE_ALWAYS ?? Maybe use AllocConsole() ??
  {
    var Handle handle = CreateFile("CONIN$", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (handle==INVALID_HANDLE_VALUE) {
      OS_error();
    }
    end_system_call();
    pushSTACK(allocate_handle(handle));
  }
 #endif
  # allocate new Stream:
  var object stream = # Flags: only READ-CHAR allowed
    allocate_stream(strmflags_rd_ch_B,strmtype_keyboard,strm_keyboard_len,strm_keyboard_xlen);
  # and fill:
  stream_dummy_fill(stream);
  var Stream s = TheStream(stream);
 #ifdef UNICODE
  s->strm_encoding = O(terminal_encoding);
 #endif
  s->strm_rd_ch = P(rd_ch_keyboard); # READ-CHAR-Pseudofunction
  s->strm_rd_ch_array = P(rd_ch_array_dummy); # READ-CHAR-SEQUENCE-Pseudofunction
 #if (defined(UNIX) && !defined(NEXTAPP)) || defined(RISCOS)
  # determine Flag isatty = (stdin_tty ? T : NIL) :
  begin_system_call();
  s->strm_keyboard_isatty = (isatty(stdin_handle) ? T : NIL);
  end_system_call();
  s->strm_keyboard_handle = popSTACK();
  s->strm_keyboard_buffer = NIL;
  s->strm_keyboard_keytab = popSTACK();
  ChannelStream_buffered(stream) = false;
  ChannelStream_init(stream);
  UnbufferedHandleStream_input_init(stream);
 #endif
 #ifdef WIN32_NATIVE
  s->strm_keyboard_isatty = T;
  s->strm_keyboard_handle = popSTACK();
  ChannelStream_buffered(stream) = false;
  ChannelStream_init(stream);
  UnbufferedHandleStream_input_init(stream);
 #endif
  return stream;
}

# (SYSTEM::MAKE-KEYBOARD-STREAM) creates a new keyboard stream.
# Should be called once only, and the result assigned to *KEYBOARD-INPUT*.
LISPFUNN(make_keyboard_stream,0) {
  VALUES1(make_keyboard_stream());
}

#endif # KEYBOARD


# Interactive Terminal Stream
# ===========================

#if defined(GNU_READLINE) || defined(NEXTAPP)
# Function to ignore unconvertible symbols.
local void lisp_completion_ignore (void* sp, object* frame, object label,
                                   object condition) {
  # (THROW 'SYS::CONVERSION-FAILURE NIL):
  VALUES1(NIL);
  throw_to(S(conversion_failure));
}
# Completion of Lisp-Symbols
global char** lisp_completion (char* text, int start, int end) {
  # text[0..end-start-1] = the_line[start..end-1]
  # This is a Callback-Function, we must set the Stack correctly again:
  begin_callback();
  # call (SYS::COMPLETION text start end) :
  pushSTACK(asciz_to_string(text,O(terminal_encoding)));
  pushSTACK(fixnum((uintL)start));
  pushSTACK(fixnum((uintL)end));
  funcall(S(completion),3);
  var object mlist = value1; # List of the possibilities
  # reconstruct List of Simple-Strings in malloc-ed Array from malloc-ed
  # Asciz-Strings:
  if (nullp(mlist)) {
    end_callback();
    return NULL;
  } else if (eq(mlist,Fixnum_0)) { # complete called describe => redraw
    rl_refresh_line(0,0);
    end_callback();
    return NULL;
  } else if (!consp(mlist)) {
    # This error message is self-defense against people who fiddle
    # around with sys::completion.
    pushSTACK(mlist);   # slot DATUM of TYPE-ERROR
    pushSTACK(S(list)); # slot EXPECTED-TYPE of TYPE-ERROR
    pushSTACK(S(list));
    pushSTACK(S(completion));
    pushSTACK(mlist);
    fehler(type_error,GETTEXT("Return value ~ of call to ~ is not a ~."));
  }
  begin_system_call();
  var char** array = (char**) malloc((llength(mlist)+1)*sizeof(char*));
  end_system_call();
  if (array==NULL) {
    end_callback();
    return NULL;
  }
  {
    var char** ptr = array;
    pushSTACK(mlist);
    while (mconsp(STACK_0)) {
      var object m = Car(STACK_0);
      if (!simple_string_p(m)) {
        end_callback();
        pushSTACK(m);                # slot DATUM of TYPE-ERROR
        pushSTACK(S(simple_string)); # slot EXPECTED-TYPE of TYPE-ERROR
        pushSTACK(S(simple_string));
        pushSTACK(m);
        pushSTACK(S(completion));
        pushSTACK(mlist);
        fehler(type_error,GETTEXT("Return value ~ of call to ~ contains ~ which is not a ~."));
      }
      simple_array_to_storage(m);
      var uintL charcount = Sstring_length(m);
      var const chart* ptr1;
      unpack_sstring_alloca(m,charcount,0, ptr1=);
      { /* (CATCH 'SYS::CONVERSION-FAILURE ...) */
        var object* top_of_frame = STACK;
        pushSTACK(S(conversion_failure));
        var sp_jmp_buf returner;
        finish_entry_frame(CATCH,&!returner,, goto catch_return; );
      }
      # Upon charset_type_error, call lisp_completion_ignore.
      make_HANDLER_frame(O(handler_for_charset_type_error),
                         &lisp_completion_ignore,NULL);
      # Convert ptr1 to *TERMINAL-ENCODING*:
      var uintL bytecount = cslen(O(terminal_encoding),ptr1,charcount);
      begin_system_call();
      var char* ptr2 = (char*) malloc((bytecount+1)*sizeof(char));
      if (ptr2==NULL) { # malloc fails -> return everything
        until (ptr==array) { free(*--ptr); }
        free(array);
        end_system_call();
        unwind_HANDLER_frame();
        skipSTACK(3+1); # unwind CATCH frame, pop mlist
        end_callback();
        return NULL;
      }
      end_system_call();
      cstombs(O(terminal_encoding),ptr1,charcount,(uintB*)ptr2,bytecount);
      ptr2[bytecount] = '\0';
      *ptr++ = ptr2;
      unwind_HANDLER_frame();
    catch_return:
      skipSTACK(3); # unwind CATCH frame
      STACK_0 = Cdr(STACK_0);
    }
    skipSTACK(1); # pop mlist
    *ptr = NULL;
  }
  if (*array == NULL) {
    begin_system_call();
    free(array);
    end_system_call();
    array = NULL;
  }
  end_callback();
  return array;
}
#endif

#ifdef NEXTAPP

# Use the interface provided by nxterminal.m, see unix.d.

# UP: Read a character from a Terminal-Stream.
# rd_ch_terminal(&stream)
# > stream: Terminal-Stream
# < object ch: entered character
local object rd_ch_terminal (const object* stream_) {
  var int linepos;
  var uintB ch;
  begin_call();
  ch = nxterminal_read_char(&linepos);
  end_call();
  TheStream(*stream_)->strm_wr_ch_lpos = fixnum(linepos);
  return code_char(as_chart(ch)); # FIXME: This should take into account the encoding.
}

# Determines, if a character is available on a Terminal-Stream.
# listen_char_terminal(stream)
# > stream: Terminal-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
local signean listen_char_terminal (object stream) {
  var signean result;
  begin_call();
  result = (nxterminal_listen() ? ls_avail : ls_wait);
  end_call();
  return result;
}

# UP: Deletes already entered interactive Input from a Terminal-Stream.
# clear_input_terminal(stream);
# > stream: Terminal-Stream
# < result: true if Input was deleted, else false
local bool clear_input_terminal (object stream) {
  # We do not want to delete anything in the input window.
  return false;
}

# UP: write a character to a Terminal-Stream.
# wr_ch_terminal(&stream,ch);
# > stream: Terminal-Stream
# > ch: character to be written
local void wr_ch_terminal (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(stream,ch);
  begin_call();
  nxterminal_write_char(char_code(ch));
  end_call();
}

# UP: Moves the pending Output of a Terminal-Stream to the destination.
# finish_output_terminal(stream);
# > stream: Terminal-Stream
# can trigger GC
local void finish_output_terminal (object stream) {
  begin_call();
  nxterminal_send_output();
  end_call();
}

# UP: Moves the pending Output of a Terminal-Stream to the destination.
# force_output_terminal(stream);
# > stream: Terminal-Stream
# can trigger GC
#define force_output_terminal(stream)  finish_output_terminal(stream)

# Returns an interactive Terminal-Stream.
# can trigger GC
local object make_terminal_stream_ (void) {
  # allocate a new Stream:
  var object stream = # Flags: only READ-CHAR and WRITE-CHAR allowed
    allocate_stream(strmflags_ch_B,strmtype_terminal,strm_len+0,0);
  # and fill:
  stream_dummy_fill(stream);
  var Stream s = TheStream(stream);
  s->strm_rd_ch = P(rd_ch_terminal); # READ-CHAR-Pseudofunction
  s->strm_rd_ch_array = P(rd_ch_array_dummy); # READ-CHAR-SEQUENCE-Pseudofunction
  s->strm_wr_ch = P(wr_ch_terminal); # WRITE-CHAR-Pseudofunction
  s->strm_wr_ch_array = P(wr_ch_array_dummy); # WRITE-CHAR-SEQUENCE-Pseudofunction
  return stream;
}

#endif # NEXTAPP

#if (defined(UNIX) && !defined(NEXTAPP)) || defined(MSDOS) || defined(AMIGAOS) || defined(RISCOS) || defined(WIN32_NATIVE)

# Functionality:
# Standard-Input anf Standard-Output are accessed.
# Because of the possibility of Redirection some Functions have to determine, if
# Standard-Input is a Terminal or not.
# If Standard-Output is a Terminal or not, is irrelevant in this context.
# However, it is relevant, if Standard-Input and Standard-Output are the same
# Terminal; in this case we assume, that after completion of an input line
# (by NL) of Standard-Input the Cursor of Standard-Output is situated in
# column 0, and in this case we can also use the
# GNU readline()-Library.

# There are three possible Variants of the Terminal-Streams:
# When Standard-Input and Standard-Output are not the same Terminal:
#   * terminal1 normally,
#   * terminal2 with per-line-buffering of the input,
# When Standard-Input and Standard-Output are the same Terminal:
#   * terminal3 uses the readline()-Library, with per-line-buffering of
#     Input and Output.

#define HAVE_TERMINAL1
  # define TERMINAL_LINEBUFFERED  0
  # define TERMINAL_OUTBUFFERED   0

#ifdef MSDOS
  # On input of a line by keyboard, the <Enter> is written at the end of the
  # line as CR/LF. However: The CR is written immediately, the LF later, when the
  # <Enter> is read with read() - Sometimes this occurs with a long delay.
  # [The guy that has programmed this idiocy - presumably in DOS -
  # should be subjected to martial law! :-(]
  # Due to this reason we have to buffer the Terminal-Stream line-by-line
  # on the Input-Side.
#define HAVE_TERMINAL2
  # define TERMINAL_LINEBUFFERED  1
  # define TERMINAL_OUTBUFFERED   0
#endif

#ifdef GNU_READLINE
  # We use the GNU Readline-Library. It returns the Input line-by-line,
  # with possibility for editing, completion and History. unfortunately we
  # have to save the Output intermediately line-by-line in order to be able to
  # use the last commenced line as "Prompt".
#define HAVE_TERMINAL3
  # define TERMINAL_LINEBUFFERED  1
  # define TERMINAL_OUTBUFFERED   1
#endif

# Additional Components:
  # ISATTY : Flag, if stdin is a TTY and if stdin and stdout are identical:
  #          NIL: stdin is a File or similar.
  #          T, EQUAL: stdin is a Terminal
  #          EQUAL: stdin and stdout are the same Terminal
  #define strm_terminal_isatty   strm_isatty
  #define strm_terminal_ihandle  strm_ichannel
  #define strm_terminal_ohandle  strm_ochannel
#if defined(HAVE_TERMINAL2) || defined(HAVE_TERMINAL3)
  # Components because of TERMINAL_LINEBUFFERED:
  # INBUFF : input-buffer, a Semi-Simple-String
  #define strm_terminal_inbuff  strm_field1
  # COUNT = its Fill-Pointer : number of characters in the input-buffer
  # INDEX : number of already consumed characters
  #define strm_terminal_index   strm_other[2]  # FIXME: this is ugly
#endif
#ifdef HAVE_TERMINAL3
  # Components because of TERMINAL_OUTBUFFERED:
  # OUTBUFF : output-buffer, a Semi-Simple-String
  #define strm_terminal_outbuff strm_field2
#endif
#define strm_terminal_len  strm_channel_len

# distinction according to type of Terminal-Streams:
# terminalcase(stream, statement1,statement2,statement3);
#if defined(HAVE_TERMINAL2) && defined(HAVE_TERMINAL3)
  #define terminalcase(stream,statement1,statement2,statement3) \
    if (nullp(TheStream(stream)->strm_field2)) {                \
      if (nullp(TheStream(stream)->strm_field1)) { statement1 } \
      else { statement2 }                                       \
    } else { statement3 }
#elif defined(HAVE_TERMINAL2)
  #define terminalcase(stream,statement1,statement2,statement3) \
    if (nullp(TheStream(stream)->strm_field1)) { statement1 }   \
    else { statement2 }
#elif defined(HAVE_TERMINAL3)
  #define terminalcase(stream,statement1,statement2,statement3) \
    if (nullp(TheStream(stream)->strm_field2)) { statement1 }   \
    else { statement3 }
#else
  #define terminalcase(stream,statement1,statement2,statement3) statement1
#endif

#ifdef EMUNIX

  # get_handle_info(handle)
  # > handle
  # < result: Handle-Info (INT 21,44,00)
    #define get_handle_info(handle)  __ioctl1(handle,0x00)

#endif

#ifdef HAVE_TERMINAL1

# read a character from a terminal-stream.
local object rd_ch_terminal1 (const object* stream_) {
  var object ch = rd_ch_unbuffered(stream_);
  # If both stdin and stdout are the same Terminal,
  # and we read a NL, we can assume, that afterwards
  # the cursor is situated in column 0.
  if (eq(ch,ascii_char(NL))) {
    var object stream = *stream_;
    if (eq(TheStream(stream)->strm_terminal_isatty,S(equal)))
      TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
  }
  return ch;
}

# Determines, if a character is available on a Terminal-Stream.
# listen_char_terminal1(stream)
# > stream: Terminal-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
#define listen_char_terminal1  listen_char_unbuffered

# UP: Deletes already entered interactive Input from a Terminal-Stream.
# clear_input_terminal1(stream);
# > stream: Terminal-Stream
# < result: true if Input was deleted, else false
#define clear_input_terminal1  clear_input_unbuffered

# UP: write a character to a Terminal-Stream.
# wr_ch_terminal1(&stream,ch);
# > stream: Terminal-Stream
# > ch: character to be written
#if !defined(AMIGAOS)
  #define wr_ch_terminal1  wr_ch_unbuffered_unix
#else # defined(AMIGAOS)
local void wr_ch_terminal1 (const object* stream_, object ch) {
  # ch should be a Character with font at most, but without Bits:
  #error "FIXME character fonts don't exist in this form any more"
  if (!((as_oint(ch) & ~(((oint)char_code_mask_c|(oint)char_font_mask_c)<<oint_data_shift)) == as_oint(type_data_object(char_type,0)))) {
    pushSTACK(*stream_); # STREAM-ERROR slot STREAM
    pushSTACK(*stream_);
    pushSTACK(ch);
    fehler(stream_error,GETTEXT("character ~ contains bits, cannot be output onto ~"));
  }
  #if (!(char_font_len_c == 4))
  #error "readjust char_font_len_c or rewrite wr_ch_terminal()!"
  #endif
  var uintB outbuffer[14];
  var uintB* ptr = &outbuffer[0];
  var uintL count = 1;
  var uintB f = (char_int(ch) & char_font_mask_c) >> char_font_shift_c; # Font of the character
  var uintB c = char_code(ch); # Code of the character
  if (f==0) {
    *ptr++ = c;
  } else {
    *ptr++ = CSI; # Control-Sequence for switching to the right Font:
    if (f & bit(0)) {
      *ptr++ = ';'; *ptr++ = '1'; count += 2; # bold activated
    }
    if (f & bit(1)) {
      *ptr++ = ';'; *ptr++ = '3'; count += 2; # italics activated
    }
    if (f & bit(2)) {
      *ptr++ = ';'; *ptr++ = '4'; count += 2; # underline activated
    }
    if (f & bit(3)) {
      *ptr++ = ';'; *ptr++ = '7'; count += 2; # Reverse activated
    }
    *ptr++ = 0x6D;
    *ptr++ = c; # then write the character
    *ptr++ = CSI; *ptr++ = '0'; *ptr++ = 0x6D; # again normal font
    count += 5;
  }
  begin_system_call();
  var long result = Write(stdout_handle,&outbuffer[0],count); # try to write character
  end_system_call();
  if (result<0) { OS_error(); }
  if (result<count) # not successful?
    fehler_unwritable(S(write_char),*stream_);
}
#endif

# UP: write several characters on a Terminal-Stream.
# wr_ch_array_terminal1(&stream,&chararray,start,len);
# > stream: Terminal-Stream
# > chararray: Simple-String
# > start: Startindex
# > len: number of characters to be written
#define wr_ch_array_terminal1  wr_ch_array_unbuffered_unix

# UP: Deletes the pending Output of a Terminal-Stream.
# clear_output_terminal1(stream);
# > stream: Terminal-Stream
# can trigger GC
#define clear_output_terminal1  clear_output_unbuffered

#endif # HAVE_TERMINAL1

#ifdef HAVE_TERMINAL2

#define TERMINAL_LINEBUFFERED  true

# read a character from a terminal-stream.
local object rd_ch_terminal2 (const object* stream_) {
  var object stream = *stream_;
  if (eq(TheStream(stream)->strm_rd_ch_last,eof_value)) # EOF already?
    return eof_value;
  if (!(posfixnum_to_L(TheStream(stream)->strm_terminal_index)
        < TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1])) {
    # index=count -> must read a whole line from the keyboard:
    TheStream(stream)->strm_terminal_index = Fixnum_0; # index := 0
    TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1] = 0; # count := 0
    loop {
      var object ch = rd_ch_unbuffered(stream_);
      if (eq(ch,eof_value)) {
        if (TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1] > 0)
          break; # deliver character of the Buffer, only then return eof_value
        else
          return eof_value;
      }
      # add character ch to the input-line, poss. enlarge the line:
      ssstring_push_extend(TheStream(stream)->strm_terminal_inbuff,char_code(ch));
      stream = *stream_;
      # If both stdin and stdout are the same Terminal,
      # and we read a NL, we can assume, that afterwards the
      # Cursor is situated in column 0.
      if (chareq(char_code(ch),ascii(NL))) {
        if (eq(TheStream(stream)->strm_terminal_isatty,S(equal)))
          TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
        break; # deliver character of the Buffer
      }
    }
    ASSERT(posfixnum_to_L(TheStream(stream)->strm_terminal_index)
           < TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1]);
  }
  # index<count -> there are still characters in the buffer
  var uintL index =
    posfixnum_to_L(TheStream(stream)->strm_terminal_index); # Index
  TheStream(stream)->strm_terminal_index =
    fixnum_inc(TheStream(stream)->strm_terminal_index,1); # increase Index
  return code_char(TheSstring(TheIarray(TheStream(stream)->strm_terminal_inbuff)->data)->data[index]); # next Character
}

# Determines, if a character is available on a Terminal-Stream.
# listen_char_terminal2(stream)
# > stream: Terminal-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
local signean listen_char_terminal2 (object stream) {
  if (eq(TheStream(stream)->strm_rd_ch_last,eof_value)) # EOF already?
    return ls_eof;
  if (posfixnum_to_L(TheStream(stream)->strm_terminal_index)
      < TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1])
    # index<count -> there are still characters in the buffer
    return ls_avail;
  return listen_char_unbuffered(stream);
}

# UP: Deletes already entered interactive Input from a Terminal-Stream.
# clear_input_terminal2(stream);
# > stream: Terminal-Stream
# < result: true if Input was deleted, else false
local bool clear_input_terminal2 (object stream) {
  if (nullp(TheStream(stream)->strm_terminal_isatty)) # File -> do nothing
    return false;
  # Terminal
  clear_input_unbuffered(stream); # forget about past EOF, call clear_tty_input
 #if TERMINAL_LINEBUFFERED
  TheStream(stream)->strm_terminal_index = Fixnum_0; # index := 0
  TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1] = 0; # count := 0
 #endif
  pushSTACK(stream);
  while (ls_avail_p(listen_char_terminal2(STACK_0))) {
    read_char(&STACK_0);
  }
  skipSTACK(1);
  return true;
}

# UP: Write a character to a Terminal-Stream.
# wr_ch_terminal2(&stream,ch);
# > stream: Terminal-Stream
# > ch: character to be written
#define wr_ch_terminal2  wr_ch_unbuffered_dos

# UP: Write several characters to a Terminal-Stream.
# wr_ch_array_terminal2(&stream,&chararray,start,len);
# > stream: Terminal-Stream
# > chararray: Simple-String
# > start: Startindex
# > len: number of characters to be written
#define wr_ch_array_terminal2  wr_ch_array_unbuffered_dos

# UP: Deletes the pending Output of a Terminal-Stream.
# clear_output_terminal2(stream);
# > stream: Terminal-Stream
# can trigger GC
#define clear_output_terminal2  clear_output_unbuffered

#endif # HAVE_TERMINAL2

#ifdef HAVE_TERMINAL3

#define TERMINAL_LINEBUFFERED  true
#define TERMINAL_OUTBUFFERED   true

extern_C char *READLINE_FILE_COMPLETE (READLINE_CONST char *, int);
local bool want_filename_completion;
local char** lisp_completion_matches (READLINE_CONST char* text, int start, int end) {
  # text[0..end-start-1] = the_line[start..end-1]
  if (((start>=2)
       && (rl_line_buffer[start-2]=='#')
       && (rl_line_buffer[start-1]== '\"'))
      || ((start>=3)
          && (rl_line_buffer[start-3]=='#')
          && (rl_line_buffer[start-2]=='P' || rl_line_buffer[start-2]=='p')
          && (rl_line_buffer[start-1]== '\"'))) {
    # Completion after #" or #P" relates to file names:
    want_filename_completion = true; return NULL;
  }
  var char** result = lisp_completion(rl_line_buffer,start,end);
  want_filename_completion = false;
  return result;
}

# If the function above returns NULL (no Matches), the following
# function is called until it returns NULL on its part.
local char* lisp_completion_more (READLINE_CONST char* text, int state) {
  if (want_filename_completion)
    return READLINE_FILE_COMPLETE(text,state);
  else
    return NULL;
}

# Strip trailing '\r' from the end of STRING.
# Returns STRING.
# Borrowed from BASH 2.05
# we do not strip the initial whitespace
# since it is needed for indentation.
# we do not strip the trailing whitespace since this would break
# READ-LINE on terminal streams: it must not strip whitespace.
local char * strip_white (char *string) {
  char *end, *beg=string;
  if (beg == NULL) return NULL;
  # while (ch_blank_p(*beg)) beg++;
  if (*beg == 0) return beg;
  for (end = beg + strlen (beg) - 1; end > beg && (*end == '\r'); end--);
  *++end = '\0';
  return beg;
}

#ifdef GNU_READLINE
# prototype here for rd_ch_terminal3()
# cannot have the whole thing here since they need rl_memory_abort()
# which calls make_terminal_stream() which is not yet defined
local char* xmalloc (int count);
local char* xrealloc (void* ptr, int count);
#endif

# In the implementation of rd_ch_terminal3 and listen_char_terminal3, we
# should not use the corresponding rd_ch_unbuffered and listen_char_unbuffered
# functions, because they store intermediately read bytes in
# UnbufferedStream_bytebuf(stream), where readline() will not see them.
# As a workaround, we use rl_stuff_char() before calling readline().

# However, there is a deeper problem with the rd_ch_terminal3/
# listen_char_terminal3 implementation: readline() terminates when `rl_done'
# gets set to 1, whereas listen_char_unbuffered normally returns ls_avail when
# the user has entered a line of characters followed by #\Newline. Normally
# this is the same condition, but if the user modifies his readline key
# bindings so that newline does not always cause `rl_done' to become 1, then
# rd_ch_terminal3() might block although listen_char_terminal3() returned
# ls_avail. One possible fix would be to use the READLINE_CALLBACK functions,
# see readline.dvi p. 29, but in order to get this right, RUN-PROGRAM and
# MAKE-PIPE-INPUT-STREAM might need to be modified to temporarily turn off
# readline.

# read a character from a terminal-stream.
# cp. rd_ch_unbuffered() :
local object rd_ch_terminal3 (const object* stream_) {
  var object stream = *stream_;
  if (eq(TheStream(stream)->strm_rd_ch_last,eof_value)) # EOF already?
    return eof_value;
  if (!(posfixnum_to_L(TheStream(stream)->strm_terminal_index)
        < TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1])) {
    # index=count -> must read a whole line from the keyboard:
    TheStream(stream)->strm_terminal_index = Fixnum_0; # index := 0
    TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1] = 0; # count := 0
    # Pass bytes that we have already read down into readline's buffer.
    while (UnbufferedStream_status(stream) > 0) {
      UnbufferedStreamLow_pop_byte(stream,b);
      begin_system_call(); rl_stuff_char(b); end_system_call();
    }
    {
      var char* prompt; # Prompt: last output line
      {
        var object lastline = string_to_asciz(TheStream(stream)->strm_terminal_outbuff,TheStream(stream)->strm_encoding);
        begin_system_call();
        prompt = (char*) malloc(Sbvector_length(lastline)+1);
        if (prompt!=NULL)
          strcpy(prompt,TheAsciz(lastline));
        end_system_call();
      }
      # lexema-separating characters: with syntax code whsp,tmac,nmac
      # (see IO.D, actually depends on the current *READTABLE*):
      rl_basic_word_break_characters = "\t" NLstring " \"#'(),;`";
      rl_basic_quote_characters = "\"|";
      rl_completer_quote_characters = "\\|";
      run_time_stop(); # hold run time clock
      begin_call();
      rl_already_prompted = true;
      var uintB* line = strip_white(readline(prompt==NULL ? "" : prompt));
      end_call();
      run_time_restart(); # resume run time clock
      if (!(prompt==NULL)) {
        begin_system_call(); free(prompt); end_system_call();
      }
      if (line==NULL)
        # detect EOF (at the start of line)
        return eof_value;
      # add read line to the input line:
     #ifdef UNICODE
      {
        var object inbuff = TheStream(*stream_)->strm_terminal_inbuff;
        var object encoding = TheStream(*stream_)->strm_encoding;
        var const uintB* bptr = line;
        var const uintB* bendptr = bptr + asciz_length((const char*)bptr);
        var uintL clen = Encoding_mblen(encoding)(encoding,bptr,bendptr);
        ssstring_extend(inbuff,TheIarray(inbuff)->dims[1]+clen);
        inbuff = TheStream(*stream_)->strm_terminal_inbuff;
        encoding = TheStream(*stream_)->strm_encoding;
        var chart* cptr = &TheSstring(TheIarray(inbuff)->data)->data[TheIarray(inbuff)->dims[1]];
        var chart* cendptr = cptr+clen;
        Encoding_mbstowcs(encoding)(encoding,nullobj,&bptr,bendptr,&cptr,cendptr);
        ASSERT(cptr == cendptr);
        TheIarray(inbuff)->dims[1] += clen;
      }
     #else
      {
        var const uintB* ptr = line;
        until (*ptr == '\0') {
          ssstring_push_extend(TheStream(*stream_)->strm_terminal_inbuff,
                               as_chart(*ptr++));
        }
      }
     #endif
      ssstring_push_extend(TheStream(*stream_)->strm_terminal_inbuff,
                           ascii(NL));
      # put into the history if non-empty
      if (line[0] != '\0') {
        HIST_ENTRY *prev = previous_history();
        if ((prev==NULL)
            || !boundp(Symbol_value(S(terminal_read_open_object)))) {
          begin_system_call(); add_history((char*)line); end_system_call();
        } else { # append this line to the previous history entry
          begin_system_call();
          var int offset = where_history();
          var HIST_ENTRY *old;
          var char *new_line = (char*)xmalloc(2+strlen(line)+
                                              strlen(prev->line));
          # strcpy(new_line,prev->line[0]=='\n' ? "" : "\n");
          strcpy(new_line,prev->line);
          strcat(new_line,"\n");
          strcat(new_line,line);
          old = replace_history_entry(offset,new_line,prev->data);
          if (old) {
            free(old->line);
            free(old);
          }
          end_system_call();
        }
      }
      # must release the original line
      begin_system_call(); free(line); end_system_call();
    }
    stream = *stream_;
    # If both stdin and stdout are the same Terminal, we can assume,
    # that the Cursor is situated in column 0.
    if (eq(TheStream(stream)->strm_terminal_isatty,S(equal))) {
      TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
      TheIarray(TheStream(stream)->strm_terminal_outbuff)->dims[1] = 0; # Fill-Pointer := 0
    }
    ASSERT(posfixnum_to_L(TheStream(stream)->strm_terminal_index)
           < TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1]);
  }
  # index<count -> there are still characters in the buffer
  var uintL index =
    posfixnum_to_L(TheStream(stream)->strm_terminal_index); # Index
  TheStream(stream)->strm_terminal_index =
    fixnum_inc(TheStream(stream)->strm_terminal_index,1); # increase Index
  return code_char(TheSstring(TheIarray(TheStream(stream)->strm_terminal_inbuff)->data)->data[index]); # next Character
}

# Determines, if a character is available on a Terminal-Stream.
# listen_char_terminal3(stream)
# > stream: Terminal-Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
local signean listen_char_terminal3 (object stream) {
  if (eq(TheStream(stream)->strm_rd_ch_last,eof_value)) # EOF already?
    return ls_eof;
  if (posfixnum_to_L(TheStream(stream)->strm_terminal_index)
      < TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1])
    # index<count -> there are still characters in the buffer
    return ls_avail;
  return listen_char_unbuffered(stream);
}

# UP: Deletes already entered interactive Input from a Terminal-Stream.
# clear_input_terminal3(stream);
# > stream: Terminal-Stream
# < result: true if Input was deleted, else false
local bool clear_input_terminal3 (object stream) {
  if (nullp(TheStream(stream)->strm_terminal_isatty)) # File -> do nothing
    return false;
  # Terminal
  clear_input_unbuffered(stream); # forget about past EOF, call clear_tty_input
 #if TERMINAL_LINEBUFFERED
  TheStream(stream)->strm_terminal_index = Fixnum_0; # index := 0
  TheIarray(TheStream(stream)->strm_terminal_inbuff)->dims[1] = 0; # count := 0
 #endif
  pushSTACK(stream);
  while (ls_avail_p(listen_char_terminal3(STACK_0))) {
    read_char(&STACK_0);
  }
  skipSTACK(1);
  return true;
}

# UP: Write a character to a Terminal-Stream.
# wr_ch_terminal3(&stream,ch);
# > stream: Terminal-Stream
# > ch: character to be written
local void wr_ch_terminal3 (const object* stream_, object ch) {
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(*stream_,ch);
 #if TERMINAL_OUTBUFFERED
  {
    var chart c = char_code(ch); # Code of the character
    if (chareq(c,ascii(NL)))
      TheIarray(TheStream(*stream_)->strm_terminal_outbuff)->dims[1] = 0; # Fill-Pointer := 0
    else
      ssstring_push_extend(TheStream(*stream_)->strm_terminal_outbuff,c);
  }
 #endif
  wr_ch_unbuffered_unix(stream_,ch);
}

# UP: Write several characters to a Terminal-Stream.
# wr_ch_array_terminal3(&stream,&chararray,start,len);
# > stream: Terminal-Stream
# > chararray: Simple-String
# > start: Startindex
# > len: number of characters to be written
local void wr_ch_array_terminal3 (const object* stream_,
                                  const object* chararray_,
                                  uintL start, uintL len) {
  wr_ch_array_unbuffered_unix(stream_,chararray_,start,len);
 #if TERMINAL_OUTBUFFERED
  {
    var object string = *chararray_;
    var const chart* ptr;
    unpack_sstring_alloca(string,len,start, ptr =);
    # characters since the last NL in the Buffer:
    var uintL pos = 0; # count the number of characters since the last NL
    var uintL count;
    ptr += len;
    dotimespL(count,len, {
      if (chareq(*--ptr,ascii(NL)))
        goto found_NL;
      pos++;
    });
    if (false) {
    found_NL: # pos characters since the last NL
      ptr++;
      TheIarray(TheStream(*stream_)->strm_terminal_outbuff)->dims[1] = 0; # Fill-Pointer := 0
    }
    if (pos > 0) {
      SstringCase(string, {
        # ptr points into the stack, not the string, so it's GC-safe.
        dotimespL(count,pos, {
          ssstring_push_extend(TheStream(*stream_)->strm_terminal_outbuff,
                               *ptr++);
        });
      },{
        # ptr points into the stack, not the string, so it's GC-safe.
        dotimespL(count,pos, {
          ssstring_push_extend(TheStream(*stream_)->strm_terminal_outbuff,
                               *ptr++);
        });
      },{
        # ptr points into the string, not GC-safe.
        var uintL index = start + len - pos;
        dotimespL(count,pos, {
          ssstring_push_extend(TheStream(*stream_)->strm_terminal_outbuff,
                               TheSstring(*chararray_)->data[index]);
          index++;
        });
      });
    }
  }
 #endif
}

# UP: Deletes the pending Output of a Terminal-Stream.
# clear_output_terminal3(stream);
# > stream: Terminal-Stream
# can trigger GC
local void clear_output_terminal3 (object stream) {
  clear_output_unbuffered(stream);
 #if TERMINAL_OUTBUFFERED
  TheIarray(TheStream(stream)->strm_terminal_outbuff)->dims[1] = 0; # Fill-Pointer := 0
 #endif
}

#endif # HAVE_TERMINAL3

# UP: Moves the pending Output of a Terminal-Stream to the destination.
# finish_output_terminal(stream);
# > stream: Terminal-Stream
# can trigger GC
#define finish_output_terminal  finish_output_unbuffered

# UP: Moves the pending Output of a Terminal-Stream to the destination.
# force_output_terminal(stream);
# > stream: Terminal-Stream
# can trigger GC
#define force_output_terminal  force_output_unbuffered

# Returns an interactive Terminal-Stream.
# can trigger GC
local object make_terminal_stream_ (void) {
 #ifdef AMIGAOS
  # only HAVE_TERMINAL1
  {
    pushSTACK(allocate_handle(stdout_handle));
    pushSTACK(allocate_handle(stdin_handle));
    var object stream = # Flags: only READ-CHAR and WRITE-CHAR allowed
      allocate_stream(strmflags_ch_B,strmtype_terminal,strm_terminal_len,
                      sizeof(strm_unbuffered_extrafields_t));
    # and fill:
    stream_dummy_fill(stream);
    var Stream s = TheStream(stream);
   #ifdef UNICODE
    s->strm_encoding = O(terminal_encoding);
   #endif
    s->strm_rd_ch = P(rd_ch_terminal1); # READ-CHAR-Pseudofunction
    s->strm_rd_ch_array = P(rd_ch_array_dummy); # READ-CHAR-SEQUENCE-Pseudofunction
    s->strm_wr_ch = P(wr_ch_terminal1); # WRITE-CHAR-Pseudofunction
    s->strm_wr_ch_array = P(wr_ch_array_terminal1); # WRITE-CHAR-SEQUENCE-Pseudofunction
    begin_system_call();
    s->strm_terminal_isatty =
      (IsInteractive(stdin_handle)
       ? (IsInteractive(stdout_handle)
          ? S(equal) # input and output terminals -> probably the same
          : T)
       : NIL);
    end_system_call();
    s->strm_terminal_ihandle = popSTACK();
    s->strm_terminal_ohandle = popSTACK();
    ChannelStream_buffered(stream) = false;
    ChannelStream_init(stream);
    UnbufferedHandleStream_input_init(stream);
    UnbufferedHandleStream_output_init(stream);
    return stream;
  }
 #else
  {
    var int stdin_tty;
    var int stdout_tty;
    var int same_tty;
    begin_system_call();
    stdin_tty = isatty(stdin_handle); # stdin a Terminal?
    stdout_tty = isatty(stdout_handle); # stdout a Terminal?
    same_tty = false; # temporary
    if (stdin_tty && stdout_tty) { # stdin and stdout Terminals.
    #if defined(UNIX) || defined(RISCOS)
     #if 0
      var const char* result;
      var object filename;
      result = ttyname(stdin_handle); # fetch Filename from stdin
      if (!(result==NULL)) {
        end_system_call();
        filename = asciz_to_string(result,O(pathname_encoding));
        begin_system_call();
        result = ttyname(stdout_handle); # fetch Filename from stdout
        if (!(result==NULL)) {
          end_system_call();
          pushSTACK(filename);
          filename = asciz_to_string(result,O(pathname_encoding));
          if (string_gleich(popSTACK(),filename)) # Filenames equal?
            same_tty = true;
        }
      }
     #else # ttyname() is rather slow, fstat() is faster.
      struct stat stdin_stat;
      struct stat stdout_stat;
      if ((fstat(stdin_handle,&stdin_stat) >= 0)
          && (fstat(stdout_handle,&stdout_stat) >= 0))
        if ((stdin_stat.st_dev == stdout_stat.st_dev)
           #ifdef UNIX_CYGWIN32
            /* st_ino does not make sense on Cygwin: they are based on
               filenames, and stdin is CONIN$ while stdout is CONOUT$ */
            && (strcmp("/dev/conin", ttyname(stdin_handle))  == 0)
            && (strcmp("/dev/conout",ttyname(stdout_handle)) == 0)
           #else
            && (stdin_stat.st_ino == stdout_stat.st_ino)
           #endif
            )
          same_tty = true;
     #endif
    #endif
    #ifdef MSDOS
      if (   ((get_handle_info(stdin_handle) & (bit(7)|bit(0))) == (bit(7)|bit(0))) # stdin == console_input ?
             && ((get_handle_info(stdout_handle) & (bit(7)|bit(1))) == (bit(7)|bit(1)))) # stdout == console_output ?
        same_tty = true;
    #endif
    #ifdef WIN32_NATIVE
      var DWORD console_mode;
      if (   GetConsoleMode(stdin_handle,&console_mode)
             && GetConsoleMode(stdout_handle,&console_mode))
        same_tty = true;
    #endif
    }
    end_system_call();
   #ifdef HAVE_TERMINAL3
    if (rl_gnu_readline_p && same_tty) { # Build a TERMINAL3-Stream:
      pushSTACK(make_ssstring(80)); # allocate line-buffer
      pushSTACK(make_ssstring(80)); # allocate line-buffer
      pushSTACK(allocate_handle(stdout_handle));
      pushSTACK(allocate_handle(stdin_handle));
      # allocate new Stream:
      var object stream = # Flags: only READ-CHAR and WRITE-CHAR allowed
        allocate_stream(strmflags_ch_B,strmtype_terminal,strm_terminal_len,
                        sizeof(strm_unbuffered_extrafields_t));
      # and fill:
      stream_dummy_fill(stream);
      var Stream s = TheStream(stream);
     #ifdef UNICODE
      s->strm_encoding = O(terminal_encoding);
     #endif
      s->strm_rd_ch = P(rd_ch_terminal3); # READ-CHAR-Pseudofunction
      s->strm_rd_ch_array = P(rd_ch_array_dummy); # READ-CHAR-SEQUENCE-Pseudofunction
      s->strm_wr_ch = P(wr_ch_terminal3); # WRITE-CHAR-Pseudofunction
      s->strm_wr_ch_array = P(wr_ch_array_terminal3); # WRITE-CHAR-SEQUENCE-Pseudofunction
      s->strm_terminal_isatty = S(equal); # stdout=stdin
      s->strm_terminal_ihandle = popSTACK(); # Handle for listen_char_unbuffered()
      s->strm_terminal_ohandle = popSTACK(); # Handle for Output
     #if 1 # TERMINAL_LINEBUFFERED
      s->strm_terminal_inbuff = popSTACK(); # register line buffer, count := 0
      s->strm_terminal_index = Fixnum_0; # index := 0
     #endif
     #if 1 # TERMINAL_OUTBUFFERED
      s->strm_terminal_outbuff = popSTACK(); # register line buffer
     #endif
      ChannelStream_buffered(stream) = false;
      ChannelStream_init(stream);
      UnbufferedHandleStream_input_init(stream);
      UnbufferedHandleStream_output_init(stream);
      return stream;
    }
   #endif
   #ifdef HAVE_TERMINAL2
    if (stdin_tty) { # Build a TERMINAL2-Stream:
      pushSTACK(make_ssstring(80)); # allocate line-buffer
      pushSTACK(allocate_handle(stdout_handle));
      pushSTACK(allocate_handle(stdin_handle));
      # allocate new Stream:
      var object stream = # Flags: only READ-CHAR and WRITE-CHAR allowed
        allocate_stream(strmflags_ch_B,strmtype_terminal,strm_terminal_len,
                        sizeof(strm_unbuffered_extrafields_t));
      # and fill:
      stream_dummy_fill(stream);
      var Stream s = TheStream(stream);
#ifdef UNICODE
      s->strm_encoding = O(terminal_encoding);
#endif
      s->strm_rd_ch = P(rd_ch_terminal2); # READ-CHAR-Pseudofunction
      s->strm_rd_ch_array = P(rd_ch_array_dummy); # READ-CHAR-SEQUENCE-Pseudofunction
      s->strm_wr_ch = P(wr_ch_terminal2); # WRITE-CHAR-Pseudofunction
      s->strm_wr_ch_array = P(wr_ch_array_terminal2); # WRITE-CHAR-SEQUENCE-Pseudofunction
      s->strm_terminal_isatty = (stdin_tty ? (same_tty ? S(equal) : T) : NIL);
      s->strm_terminal_ihandle = popSTACK(); # Handle for listen_char_unbuffered()
      s->strm_terminal_ohandle = popSTACK(); # Handle for Output
     #if 1 # TERMINAL_LINEBUFFERED
      s->strm_terminal_inbuff = popSTACK(); # register line buffer, count := 0
      s->strm_terminal_index = Fixnum_0; # index := 0
     #endif
      ChannelStream_buffered(stream) = false;
      ChannelStream_init(stream);
      UnbufferedHandleStream_input_init(stream);
      UnbufferedHandleStream_output_init(stream);
      return stream;
    }
   #endif
    # Build a TERMINAL1-Stream:
    {
      pushSTACK(allocate_handle(stdout_handle));
      pushSTACK(allocate_handle(stdin_handle));
      # allocate new Stream:
      var object stream = # Flags: only READ-CHAR and WRITE-CHAR allowed
        allocate_stream(strmflags_ch_B,strmtype_terminal,strm_terminal_len,
                        sizeof(strm_unbuffered_extrafields_t));
      # and fill:
      stream_dummy_fill(stream);
      var Stream s = TheStream(stream);
     #ifdef UNICODE
      s->strm_encoding = O(terminal_encoding);
     #endif
      s->strm_rd_ch = P(rd_ch_terminal1); # READ-CHAR-Pseudofunction
      s->strm_rd_ch_array = P(rd_ch_array_dummy); # READ-CHAR-SEQUENCE-Pseudofunction
      s->strm_wr_ch = P(wr_ch_terminal1); # WRITE-CHAR-Pseudofunction
      s->strm_wr_ch_array = P(wr_ch_array_terminal1); # WRITE-CHAR-SEQUENCE-Pseudofunction
      s->strm_terminal_isatty = (stdin_tty ? (same_tty ? S(equal) : T) : NIL);
      s->strm_terminal_ihandle = popSTACK(); # Handle for listen_char_unbuffered()
      s->strm_terminal_ohandle = popSTACK(); # Handle for Output
      ChannelStream_buffered(stream) = false;
      ChannelStream_init(stream);
      UnbufferedHandleStream_input_init(stream);
      UnbufferedHandleStream_output_init(stream);
      return stream;
    }
  }
 #endif
}

#ifdef AMIGAOS

# error, if TERMINAL-RAW does not work.
nonreturning_function(local, fehler_terminal_raw, (object stream)) {
  pushSTACK(stream);
  fehler(error,GETTEXT("RAW mode not supported on ~"));
}

#endif

#if defined(UNIX) || defined(AMIGAOS) || defined(RISCOS)

# (SYS::TERMINAL-RAW *terminal-io* flag [errorp])
# flag /= NIL: sets the Terminal in cbreak/noecho-Mode,
# flag = NIL: sets the Terminal back in nocbreak/echo-Mode.
# If it is not possible and errorp is specified and is /= NIL, Error is reported.
# Returns the old Mode.

# (SYS::TERMINAL-RAW *terminal-io* t) is essentially
# (progn
#   ; no possibilities for editing, no Echo, no CR<-->NL-conversions:
#   (shell "stty -icanon -echo -icrnl -inlcr")
#   ; don't catch anything:
#   ;              C-S   C-Q      Del     C-U       C-W      C-R      C-O      C-V     C-Y     C-C     C-\      C-Q     C-S    C-D
#   (shell "stty -ixon -ixoff erase ^- kill ^- werase ^- rprnt ^- flush ^- lnext ^- susp ^- intr ^- quit ^- start ^- stop ^- eof ^-")
#   ; demand 1 character at a time (not 4!):
#   (shell "stty min 1") ; this has to come at the end, paradoxically...
# )
# (SYS::TERMINAL-RAW *terminal-io* nil) is essentially
# (shell "stty sane")

#if defined(UNIX) || defined(RISCOS)

local void term_raw (void);
local void term_unraw (void);

local bool oldterm_initialized = false;

#if defined(UNIX_TERM_TERMIOS)
  local struct termios oldtermio; # original TTY-Mode
local void term_raw() {
  if (!oldterm_initialized) {
    if (!( tcgetattr(stdout_handle,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
    oldterm_initialized = true;
  }
  var struct termios newtermio;
  newtermio = oldtermio;
  newtermio.c_iflag &= ( /* IXON|IXOFF|IXANY| */ ISTRIP|IGNBRK);
  /* newtermio.c_oflag &= ~OPOST; */ # Curses is deranged by this!
  newtermio.c_lflag &= ISIG;
  {
    var uintC i;
    for (i=0; i<NCCS; i++)
      newtermio.c_cc[i] = 0;
  }
  newtermio.c_cc[VMIN] = 1;
  newtermio.c_cc[VTIME] = 0;
  if (!( TCSETATTR(stdout_handle,TCSAFLUSH,&newtermio) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
}
local void term_unraw() {
  if (oldterm_initialized) {
    if (!( TCSETATTR(stdout_handle,TCSAFLUSH,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
}
# Some do it like this:
# define crmode()    (_tty.c_lflag &=~ICANON,_tty.c_cc[VMIN]=1,tcsetattr(_tty_ch, TCSAFLUSH, &_tty))
# define nocrmode()  (_tty.c_lflag |= ICANON,_tty.c_cc[VEOF] = CEOF,tcsetattr(_tty_ch, TCSAFLUSH,&_tty))
# define echo()      (_tty.c_lflag |= ECHO, tcsetattr(_tty_ch, TCSAFLUSH, &_tty))
# define noecho()    (_tty.c_lflag &=~ECHO, tcsetattr(_tty_ch, TCSAFLUSH, &_tty))
# define nl()        (_tty.c_iflag |= ICRNL,_tty.c_oflag |= ONLCR,tcsetattr(_tty_ch, TCSAFLUSH, &_tty))
# define nonl()      (_tty.c_iflag &=~ICRNL,_tty.c_oflag &=~ONLCR,tcsetattr(_tty_ch, TCSAFLUSH, &_tty))
# define savetty()   (tcgetattr(_tty_ch, &_oldtty),tcgetattr(_tty_ch, &_tty))
# define resetty()   (tcsetattr(_tty_ch, TCSAFLUSH, &_oldtty))
#elif defined(UNIX_TERM_TERMIO) || defined(EMUNIX)
  local struct termio oldtermio; # original TTY-Mode
local void term_raw() {
  if (!oldterm_initialized) {
    if (!( ioctl(stdout_handle,TCGETA,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
    oldterm_initialized = true;
  }
  var struct termio newtermio;
  newtermio = oldtermio;
  newtermio.c_iflag &= ( /* IXON|IXOFF|IXANY| */ ISTRIP|IGNBRK);
  /* newtermio.c_oflag &= ~OPOST; */ # Curses is deranged by this!
  newtermio.c_lflag &= ISIG;
  {
    var uintC i;
    for (i=0; i<NCCS; i++)
      newtermio.c_cc[i] = 0;
  }
  newtermio.c_cc[VMIN] = 1;
  newtermio.c_cc[VTIME] = 0;
  if (!( ioctl(stdout_handle,TCSETAF,&newtermio) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
}
local void term_unraw() {
  if (oldterm_initialized) {
    if (!( ioctl(stdout_handle,TCSETAF,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
}
# Some do it like this:
# define crmode()    (_tty.c_lflag &=~ICANON,_tty.c_cc[VMIN] = 1,ioctl(_tty_ch,TCSETAF,&_tty))
# define nocrmode()  (_tty.c_lflag |= ICANON,_tty.c_cc[VEOF] = CEOF,stty(_tty_ch,&_tty))
# define echo()      (_tty.c_lflag |= ECHO, ioctl(_tty_ch, TCSETA, &_tty))
# define noecho()    (_tty.c_lflag &=~ECHO, ioctl(_tty_ch, TCSETA, &_tty))
# define nl()        (_tty.c_iflag |= ICRNL,_tty.c_oflag |= ONLCR,ioctl(_tty_ch, TCSETAW, &_tty))
# define nonl()      (_tty.c_iflag &=~ICRNL,_tty.c_oflag &=~ONLCR,ioctl(_tty_ch, TCSETAW, &_tty))
#elif defined(UNIX_TERM_SGTTY)
  local struct sgttyb oldsgttyb; # original TTY-Mode
  local struct tchars oldtchars; # original control-character
 #ifdef TIOCSLTC
  local struct ltchars oldltchars; # original editing-character
 #endif
local void term_raw() {
  if (!oldterm_initialized) {
    if (!( ioctl(stdout_handle,TIOCGETP,&oldsgttyb) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
    if (!( ioctl(stdout_handle,TIOCGETC,&oldtchars) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
   #ifdef TIOCSLTC
    if (!( ioctl(stdout_handle,TIOCGLTC,&oldltchars) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
   #endif
    oldterm_initialized = true;
  }
  {
    var struct sgttyb newsgttyb;
    newsgttyb = oldsgttyb;
    newsgttyb.sg_flags |= CBREAK;
    newsgttyb.sg_flags &= ~(CRMOD|ECHO|XTABS);
    if (!( ioctl(stdout_handle,TIOCSETP,&newsgttyb) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
  {
    var struct tchars newtchars;
    var local union {
      char a [sizeof(struct tchars)];
      struct tchars b;
    } zero_tchars = {{0,}};
    newtchars = zero_tchars.b;
    if (!( ioctl(stdout_handle,TIOCSETC,&newtchars) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
 #ifdef TIOCSLTC
  {
    var struct ltchars newltchars;
    var local union {
      char a [sizeof(struct ltchars)];
      struct ltchars b;
    } zero_ltchars = {{0,}};
    newltchars = zero_ltchars.b;
    if (!( ioctl(stdout_handle,TIOCSLTC,&newltchars) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
 #endif
}
local void term_unraw() {
  if (oldterm_initialized) {
    if (!( ioctl(stdout_handle,TIOCSETP,&oldsgttyb) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
    if (!( ioctl(stdout_handle,TIOCSETC,&oldtchars) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
   #ifdef TIOCSLTC
    if (!( ioctl(stdout_handle,TIOCSLTC,&oldltchars) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
   #endif
  }
}
# Some do it like this:
# define raw()       (_tty.sg_flags|=RAW, stty(_tty_ch,&_tty))
# define noraw()     (_tty.sg_flags&=~RAW,stty(_tty_ch,&_tty))
# define crmode()    (_tty.sg_flags |= CBREAK, stty(_tty_ch,&_tty))
# define nocrmode()  (_tty.sg_flags &= ~CBREAK,stty(_tty_ch,&_tty))
# define echo()      (_tty.sg_flags |= ECHO, stty(_tty_ch, &_tty))
# define noecho()    (_tty.sg_flags &= ~ECHO, stty(_tty_ch, &_tty))
# define nl()        (_tty.sg_flags |= CRMOD,stty(_tty_ch, &_tty))
# define nonl()      (_tty.sg_flags &= ~CRMOD, stty(_tty_ch, &_tty))
# define savetty()   (gtty(_tty_ch, &_tty), _res_flg = _tty.sg_flags)
# define resetty()   (_tty.sg_flags = _res_flg, stty(_tty_ch, &_tty))
#endif

# We store, if term_raw() or term_unraw() was executed lastly,
# therewith we can switch back on program-exit.
local bool terminal_raw = false;

global void terminal_sane (void) {
  if (terminal_raw) {
    term_unraw();
    terminal_raw = false;
  }
}

LISPFUN(terminal_raw,2,1,norest,nokey,0,NIL) {
  var object errorp = popSTACK();
  var object flag = popSTACK();
  var object stream = popSTACK();
  check_stream(stream);
  stream = resolve_synonym_stream(stream);
  value1 = NIL;
  if (builtin_stream_p(stream)
      && TheStream(stream)->strmtype == strmtype_terminal) { # Terminal-Stream
    if (!nullp(TheStream(stream)->strm_terminal_isatty)) { # Terminal
      value1 = (terminal_raw ? T : NIL);
      begin_system_call();
      if (!nullp(flag)) { # switch to cbreak/noecho-Mode:
        term_raw(); terminal_raw = true;
      } else { # switch to nocbreak/echo-Mode:
        term_unraw(); terminal_raw = false;
      }
      end_system_call();
    }
  }
  mv_count=1;
}

#endif # UNIX || RISCOS

#ifdef AMIGAOS

# We can switch arbitrary interactive Handle-Streams
# (other text-windows) to Raw-Mode like the Terminal-Stream.

# For Terminal-Streams we store the current state (in order
# to switch as little as possible). For Handle-Streams this
# is done by screen.lisp.
local LONG terminal_mode = 0; # 0 = CON, 1 = RAW

global void terminal_sane (void);
global void terminal_sane()
  {
    if (!(terminal_mode == 0)) {
      begin_system_call(); SetMode(stdin_handle,0); end_system_call();
      terminal_mode = 0;
    }
  }

LISPFUN(terminal_raw,2,1,norest,nokey,0,NIL) {
  var object errorp = popSTACK();
  var object flag = popSTACK();
  var object stream = popSTACK();
  check_stream(stream);
  stream = resolve_synonym_stream(stream);
  if (!(builtin_stream_p(stream)
        && (TheStream(stream)->strmflags & strmflags_open_B))) # Stream closed?
    fehler_illegal_streamop(S(terminal_raw),stream);
  VALUES1(NIL);
  var LONG new_mode = (nullp(flag) ? 0 : 1);
  var LONG success;
  if (builtin_stream_p(stream)
      && ((TheStream(stream)->strmtype == strmtype_terminal) # the Terminal-Stream
          || (TheStream(stream)->strmtype == strmtype_file # an unbuffered File-Stream
              && !ChannelStream_buffered(stream)))) {
    if (!nullp(TheStream(stream)->strm_isatty)) {
      if (TheStream(stream)->strmtype == strmtype_terminal) { # Terminal
        VALUES_IF(terminal_mode);
        if (new_mode == terminal_mode) {
          success = true;
        } else {
          begin_system_call();
          success = SetMode(stdin_handle,new_mode);
          end_system_call();
          terminal_mode = new_mode;
        }
      } else { # unbuffered File-Stream
        VALUES_IF(UnbufferedStream_rawp(stream));
        if (new_mode == UnbufferedStream_rawp(stream)) {
          success = true;
        } else {
          begin_system_call();
          success = SetMode(TheHandle(TheStream(stream)->strm_ichannel),new_mode);
          end_system_call();
          UnbufferedStream_rawp(stream) = new_mode;
        }
      }
    } else {
      success = true;
    }
  } else {
    success = false;
  }
  if (!success && !missingp(errorp))
    fehler_terminal_raw(stream);
}

#endif # AMIGAOS

#endif # UNIX || AMIGAOS || RISCOS

#endif # (UNIX && !NEXTAPP) || MSDOS || AMIGAOS || RISCOS || WIN32_NATIVE

#if !((defined(UNIX) && !defined(NEXTAPP)) || defined(AMIGAOS) || defined(RISCOS))

LISPFUN(terminal_raw,2,1,norest,nokey,0,NIL) {
  VALUES1(NIL); skipSTACK(3); /* do nothing */
}

#endif

# Returns an interactive Terminal-Stream.
# can trigger GC
local object make_terminal_stream (void) {
  return add_to_open_streams(make_terminal_stream_());
}


# Window-Stream
# =============

#ifdef SCREEN

# Editor-Support:
# MSDOS: via BIOS.
# OS/2: With the Video-Library by Eberhard Mattes.
# CURSES: A Window-Stream is essentially a Curses-WINDOW.

# (SCREEN:MAKE-WINDOW)
#   returns a Window-Stream. Until it is closed again,
#   the Terminal is in cbreak-noecho-Mode; further In-/Output via
#   *terminal-io* should not happen during this period of time.

# (SCREEN:WINDOW-SIZE window-stream)
#   returns the size of the Window,
#   as 2 values: Height (= Ymax+1), Width (= Xmax+1).

# (SCREEN:WINDOW-CURSOR-POSITION window-stream)
#   returns the Position of the Cursor in the Window
#   as 2 values: row (>=0, <=Ymax, 0=oben), column (>=0, <=Xmax, 0=links).

# (SCREEN:SET-WINDOW-CURSOR-POSITION window-stream line column)
#   sets the Position of the Cursor in the Window.

# (SCREEN:CLEAR-WINDOW window-stream)
#   deletes the content of the Window and
#   positions the Cursor to the upper left corner

# (SCREEN:CLEAR-WINDOW-TO-EOT window-stream)
#   deletes the content of the Window from Cursor-Position to end of screen

# (SCREEN:CLEAR-WINDOW-TO-EOL window-stream)
#   deletes the content of the Window from Cursor-Position to end of line

# (SCREEN:DELETE-WINDOW-LINE window-stream)
#   deletes the cursor-line, shifts the lines below up one row
#   and deletes the last line of the screen.

# (SCREEN:INSERT-WINDOW-LINE window-stream)
#   inserts a new line at the line of the cursor and thereby shifts down
#   all lines starting at the cursor by 1.

# (SCREEN:HIGHLIGHT-ON window-stream)
#   switches on "highlighted" output.

# (SCREEN:HIGHLIGHT-OFF window-stream)
#   switches off "highlighted" output again.

# (SCREEN:WINDOW-CURSOR-ON window-stream)
#   turns the Cursor(block) visible.

# (SCREEN:WINDOW-CURSOR-OFF window-stream)
#   turns the Cursor(block) invisible again.

# check that the argument is a window-stream.
local object check_window_stream (object stream) {
  if (!(builtin_stream_p(stream)
        && (TheStream(stream)->strmtype == strmtype_window))) {
    pushSTACK(stream);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~: argument ~ should be a window stream"));
  }
  return stream;
}

#ifdef EMUNIX

# Use the Video-Library by Eberhard Mattes.
# Advantages:
# - simple interface,
# - On OS/2 it calls the Vio-Functions, on DOS the screen-memory
#   is addressed directly (fast!), if one of the Standard-Textmodes
#   is used, else the BIOS is used (portable!).

local uintL screentype; # 0 = monochrome, 1 = color

local uintB attr_table[2][5] = {
  # monochrome:
  { /* no standout   */  BW_NORMAL,
    /* standout      */  BW_REVERSE,
    /* visible bell  */  BW_NORMAL | INTENSITY,
    /* underline     */  BW_UNDERLINE,
    /* alt. char set */  BW_NORMAL | INTENSITY,
  },
  # color:
  { /* no standout   */  B_BLUE | F_WHITE | INTENSITY,
    /* standout      */  B_BLUE | F_MAGENTA | INTENSITY,
    /* visible bell  */  B_BLUE | F_BROWN | INTENSITY,
    /* underline     */  B_BLUE | F_GREEN | INTENSITY,
    /* alt. char set */  B_BLUE | F_RED | INTENSITY,
  },
};

local int cursor_scanlines_start;
local int cursor_scanlines_end;

local int LINES; # number of lines
local int COLS;  # number of columns, number of characters per line

# UP: write a character to a Window-Stream.
# wr_ch_window(&stream,ch);
# > stream: Window-Stream
# > ch: character to be written
local void wr_ch_window (const object* stream_, object ch) {
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(*stream_,ch);
  var uintB c = as_cint(char_code(ch)); # FIXME: This should take into account the encoding.
  # write Code c via the Video-Library to the screen:
  if (c==NL) {
    v_putc(c);
  } else {
    var int current_x;
    var int current_y;
    v_getxy(&current_x,&current_y); # get current cursor position
    if ((current_x==COLS-1) && (current_y==LINES-1))
      v_putn(c,1); # do not scroll at right bottom corner!!
    else
      v_putc(c);
  }
}

LISPFUNN(make_window,0) {
  var object stream = # Flags: only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_window,strm_len+0,0);
  # and fill:
  stream_dummy_fill(stream);
  var Stream s = TheStream(stream);
  s->strm_wr_ch = P(wr_ch_window); # WRITE-CHAR-Pseudofunction
  s->strm_wr_ch_array = P(wr_ch_array_dummy); # WRITE-CHAR-SEQUENCE-Pseudofunction
  v_init(); # initialize
 #if 1
  screentype = (v_hardware()==V_MONOCHROME ? 0 : 1); # query screen-type
 #else
  videomode abfragen wie in vinit.c, dann
    screentype = (((videomode==0) || (videomode==7))
                  ? 0   # monochrome
                  : 1); # color
 #endif
  v_dimen(&COLS,&LINES); # query screen-size
  v_getctype(&cursor_scanlines_start,&cursor_scanlines_end); # query cursor-shape
  v_attrib(attr_table[screentype][0]); # Highlight off
  v_ctype(cursor_scanlines_end-1,cursor_scanlines_end); # cursor small
  VALUES1(stream);
}

# Closes a Window-Stream.
local void close_window (object stream) {
  v_gotoxy(0,0); # Cursor home
  v_attrib(screentype==0 ? BW_NORMAL : (B_BLACK | F_WHITE));
  v_putn(' ',LINES*COLS); # delete screen
  v_ctype(cursor_scanlines_start,cursor_scanlines_end); # restore cursor-shape
}

LISPFUNN(window_size,1) {
  check_window_stream(popSTACK());
  VALUES2(fixnum((uintW)LINES),
          fixnum((uintW)COLS));
}

LISPFUNN(window_cursor_position,1) {
  check_window_stream(popSTACK());
  var int current_x;
  var int current_y;
  v_getxy(&current_x,&current_y); # get current cursor position
  VALUES2(fixnum((uintW)current_y),
          fixnum((uintW)current_x));
}

LISPFUNN(set_window_cursor_position,3) {
  check_window_stream(STACK_2);
  var uintL line = posfixnum_to_L(STACK_1);
  var uintL column = posfixnum_to_L(STACK_0);
  if ((line < (uintL)LINES) && (column < (uintL)COLS))
    v_gotoxy((int)column,(int)line);
  VALUES2(STACK_1,STACK_0); skipSTACK(3);
}

LISPFUNN(clear_window,1) {
  check_window_stream(popSTACK());
  v_gotoxy(0,0);
  v_clear();
  VALUES0;
}

LISPFUNN(clear_window_to_eot,1) {
  check_window_stream(popSTACK());
  var int current_x;
  var int current_y;
  v_getxy(&current_x,&current_y); # get current cursor position
  v_putn(' ',COLS*(LINES-current_y)-current_x);
  VALUES0;
}

LISPFUNN(clear_window_to_eol,1) {
  check_window_stream(popSTACK());
  v_clreol();
  VALUES0;
}

LISPFUNN(delete_window_line,1) {
  check_window_stream(popSTACK());
  v_delline(1);
  VALUES0;
}

LISPFUNN(insert_window_line,1) {
  check_window_stream(popSTACK());
  v_insline(1);
  VALUES0;
}

LISPFUNN(highlight_on,1) {
  check_window_stream(popSTACK());
  v_attrib(attr_table[screentype][1]);
  VALUES0;
}

LISPFUNN(highlight_off,1) {
  check_window_stream(popSTACK());
  v_attrib(attr_table[screentype][0]);
  VALUES0;
}

LISPFUNN(window_cursor_on,1) {
  check_window_stream(popSTACK());
  # cursor big: set begin scan to end scan - 4
  v_ctype(cursor_scanlines_end-4,cursor_scanlines_end);
  VALUES0;
}

LISPFUNN(window_cursor_off,1) {
  check_window_stream(popSTACK());
  # cursor small: set begin scan to end scan - 1
  v_ctype(cursor_scanlines_end-1,cursor_scanlines_end);
  VALUES0;
}

#endif # EMUNIX

#ifdef WIN32_NATIVE

# Implementation on top of the Win32 console.
# Contributed by Arseny Slobodjuck <ampy@crosswinds.net>, 2001-02-14
# modified on 2001-07-31

# The API is documented at
# http://www.msdn.microsoft.com/library/psdk/winbase/conchar_4svm.htm
# (Platform SDK documentation -> Base Services -> Files and I/O ->
#  Consoles and Character-Mode Support -> About Character Mode Support ->
#  Consoles)

# console is a kind of channel stream

# accessor that can be used at the Right Side
#define ConsoleHandleR(stream) TheHandle(TheStream(stream)->strm_ochannel)

typedef struct win32_console_extrafields_t {
  strm_channel_extrafields_t channel_fields;
  COORD cursor_position;
  COORD console_size;
  WORD  attribute;
  bool  handle_reused;
} win32_console_extrafields_t;

#define ConsoleData(stream) ((win32_console_extrafields_t*)&TheStream(stream)->strm_channel_extrafields)

# The following attribute constants are defined in the <wincon.h> header file:
# FOREGROUND_BLUE
# FOREGROUND_GREEN
# FOREGROUND_RED
# FOREGROUND_INTENSITY
# BACKGROUND_BLUE
# BACKGROUND_GREEN
# BACKGROUND_RED
# BACKGROUND_INTENSITY

local WORD attr_table[5] = {
  /* no standout   */
  BACKGROUND_BLUE
  | FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED,
  /* standout      */
  BACKGROUND_BLUE
  | FOREGROUND_INTENSITY | FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED,
  /* visible bell  */
  BACKGROUND_BLUE
  | FOREGROUND_INTENSITY | FOREGROUND_RED,
  /* underline     */
  BACKGROUND_BLUE
  | FOREGROUND_INTENSITY | FOREGROUND_GREEN,
  /* alt. char set */
  BACKGROUND_BLUE
  | FOREGROUND_INTENSITY | FOREGROUND_GREEN | FOREGROUND_RED
};

local void move_ccp_by(COORD *pos,COORD sz,int by) {
  int linear_ccp = pos->Y * sz.X + pos->X;
  int new_linear = linear_ccp + by;
  pos->X = new_linear % sz.X;
  pos->Y = ( new_linear % ( sz.X * sz.Y )) / sz.X;
}

local void v_move(HANDLE handle,uintW y,uintW x) {
  # set cursor
  var COORD pos;
  pos.X = x; pos.Y = y;
  SetConsoleCursorPosition(handle,pos);
}

local void v_emit_spaces(HANDLE handle,COORD *pos,int nspaces,uintW attr) {
  DWORD i;
  FillConsoleOutputAttribute(handle,attr,nspaces,*pos,&i);
  FillConsoleOutputCharacter(handle,' ',nspaces,*pos,&i);
}

local void v_cb (HANDLE handle) {
  # cursor have 50 percent fill and visibility
  CONSOLE_CURSOR_INFO ci = { 50, 1 };
  SetConsoleCursorInfo(handle,&ci);
}

local void v_cs (HANDLE handle) {
  # cursor have 10 percent fill and 0 visibility
  CONSOLE_CURSOR_INFO ci = { 10, 0 };
  SetConsoleCursorInfo(handle,&ci);
}

local void v_ce (HANDLE handle,COORD *pos,COORD sz,uintW attr) {
  # clear to end: get cursor position and emit the appropriate number
  # of spaces, without moving cursor. attr of spaces set to default.
  int nspaces = sz.X - pos->X;
  v_emit_spaces(handle,pos,nspaces,attr);
}

local void v_cl (HANDLE handle,COORD *pos,COORD sz,uintW attr) {
  int nspaces = sz.X * sz.Y;
  v_emit_spaces(handle,pos,nspaces,attr);
  v_move(handle,0,0);
}

local void v_cd (HANDLE handle,COORD *pos,COORD sz,uintW attr) {
  # clear to bottom: get position, clear to eol, clear next line to end
  int nspaces = (sz.Y - pos->Y) * sz.X - pos->X;
  v_emit_spaces(handle,pos,nspaces,attr);
}

local void v_scroll (HANDLE handle,int ax,int ay,int bx,int by,
                     int n,uintW attr) {
  CHAR_INFO c;
  SMALL_RECT r1;
  SMALL_RECT r2;
  COORD p;
  c.Char.AsciiChar = ' '; c.Attributes = attr;
  r1.Left = ax; r1.Top = ay; r1.Right = bx; r1.Bottom = by;
  r2 = r1;
  p.X = ax; p.Y = ay + n;
  ScrollConsoleScreenBuffer(handle,&r1,&r2,p,&c);
}

local void v_al (HANDLE handle,COORD *pos,COORD sz,uintW attr) {
  # add line: scroll rest of screen down
  v_scroll(handle,0,pos->Y+1,sz.X-1,sz.Y-1,1,attr);
}

local void v_dl (HANDLE handle,COORD *pos,COORD sz,uintW attr) {
  # delete line: scroll rest up
  v_scroll(handle,0,pos->Y,sz.X-1,sz.Y-1,-1,attr);
}

local void v_su (HANDLE handle,COORD *pos,COORD sz,uintW attr) {
  # not used. why is it here ?
  # scroll up: scroll whole screen
  v_scroll(handle,0,0,sz.X-1,sz.Y-1,-1,attr);
}

local uintW v_put(HANDLE handle,uintW ch,COORD *pos,COORD sz,uintW attr) {
  # put character:
  # put attribute and char (no scroll!), then update cursor position.
  ch &= 0xff;
  if (ch==NL) {
    pos->Y += 1;
    pos->Y %= sz.Y;
    pos->X = 0;
  } else {
    CHAR_INFO c;
    SMALL_RECT rto;
    COORD p0;
    COORD p1;
    c.Char.AsciiChar = ch;
    c.Attributes = attr;
    rto.Left = pos->X; rto.Top = pos->Y;
    rto.Right = pos->X+1; rto.Bottom = pos->Y+1;
    p0.X = 0; p0.Y = 0;
    p1.X = 1; p1.Y = 1;
    WriteConsoleOutput(handle,&c,p1,p0,&rto);
    move_ccp_by(pos,sz,1);
  }
  return ch;
}

local void v_puts(HANDLE handle,char *s,COORD *pos,COORD sz,uintW attr) {
  var char * cp    = s;           # cp = current position
  var char * start = s;           # start of current piece of string
  var char terminator = 0;        # judgement day
  do {
    # move cp to end of line or newline char or right screen border
    # set terminator accordingly
    while (1) {
      if (!(*cp) || *cp == NL) {
        terminator = *cp;
        break;              }
      cp++;
      if ((cp - start) >= (sz.X - pos->X)) {
        terminator = CR;
        break;                                  }
    }
    if (cp > start) {
      CHAR_INFO * ac = (CHAR_INFO *)malloc((cp - start) * sizeof(CHAR_INFO));
      SMALL_RECT rto;
      COORD zp;
      COORD p;
      int i;
      zp.X = 0; zp.Y = 0;
      if (!ac) return;
      for (i=0;i<(cp - start);i++) {
        ac[i].Char.AsciiChar = start[i];
        ac[i].Attributes = attr;
      }
      rto.Left = pos->X;
      rto.Top = pos->Y;
      rto.Right = pos->X + (cp - start) - 1;
      rto.Bottom = pos->Y;
      p.X = cp - start;
      p.Y = 1;
      WriteConsoleOutput(handle,ac,p,zp,&rto);
      pos->X+=cp - start;
      if (terminator == NL || terminator == CR) {
        pos->X = 0;
        if (pos->Y >= sz.Y - 1)
          pos->Y = 0;
        else pos->Y++;
      }
      free(ac);
    }
    if (terminator == NL) cp++;
    start = cp;
  } while (terminator == NL || terminator == CR);
}

# Lisp functions:

local void wr_ch_array_window (const object* stream_,const object* chararray_,
                               uintL start,uintL len) {
  var Handle handle = ConsoleHandleR(*stream_);
  var COORD  pos    = ConsoleData(*stream_)->cursor_position;
  var COORD  sz     = ConsoleData(*stream_)->console_size;
  var uintW  attr   = attr_table[ConsoleData(*stream_)->attribute];
  var uintL end = start + len;
  var uintL index = start;
  var uintL strindex = 0;
  var uintL mbpos = 0;
  var chart * chart_str = (chart *)malloc((len + 1)*sizeof(chart));
  var char  * char_str = (char *)chart_str;
  if (!chart_str) return;
  SstringDispatch(*chararray_,X, {
    do {
      chart_str[strindex] = as_chart(((SstringX)TheVarobject(*chararray_))->data[index]);
      index++; strindex++;
    } while (index < end);
    chart_str[strindex] = as_chart(0);
  });
 #ifdef UNICODE
  var char *mb_str = (char*)malloc((len + 1)*sizeof(char)*max_bytes_per_chart);
  if (mb_str) {
    var object encoding = TheStream(*stream_)->strm_encoding;
    var const chart* cptr = chart_str;
    var char * bptr       = mb_str;
    memset(mb_str, 0, (len + 1)*sizeof(char)*max_bytes_per_chart);
    Encoding_wcstombs(encoding)
      (encoding,*stream_,&cptr,chart_str+strindex,
       &bptr,mb_str + len * max_bytes_per_chart);
    v_puts(handle,mb_str,&pos,sz,attr); # will work only when multi == 1 in multibytes
    free(mb_str);
  }
 #else
  for (mbpos=0;chart_str[mbpos];mbpos++)
    char_str[mbpos] = chart_str[mbpos];
  char_str[mbpos] = 0;
  CharToOem(char_str,char_str);
  v_puts(handle,char_str,&pos,sz,attr);
 #endif
  free(chart_str);
  SetConsoleCursorPosition(handle,pos);
  ConsoleData(*stream_)->cursor_position = pos;
}

# UP: write a character to a Window-Stream.
# wr_ch_window(&stream,ch);
# > stream: Window-Stream
# > ch: character to be written
local void wr_ch_window (const object* stream_, object ch) {
  var Handle handle = ConsoleHandleR(*stream_);
  var COORD  pos    = ConsoleData(*stream_)->cursor_position;
  var COORD  sz     = ConsoleData(*stream_)->console_size;
  var uintW  attr   = attr_table[ConsoleData(*stream_)->attribute];
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(*stream_,ch);
  var chart c = char_code(ch);
 #ifdef UNICODE
  var uintB buf[max_bytes_per_chart];
  var object encoding = TheStream(*stream_)->strm_encoding;
  var const chart* cptr = &c;
  var uintB* bptr = buf;
  Encoding_wcstombs(encoding)
    (encoding,*stream_,&cptr,cptr+1,&bptr,buf+max_bytes_per_chart);
  c = as_chart((uintB)*buf);
 #else
  CharToOemBuff((char *)&c,(char *)&c,1);
 #endif
  v_put(handle,as_cint(c),&pos,sz,attr);
  SetConsoleCursorPosition(handle,pos);
  ConsoleData(*stream_)->cursor_position = pos;
}

local void low_close_console (object stream, object handle) {
  if (!ConsoleData(stream)->handle_reused) {
    begin_system_call();
    if (!CloseHandle(TheHandle(handle)))
      { end_system_call(); OS_filestream_error(stream); }
    end_system_call();
  }
}

LISPFUNN(make_window,0) {
  var object stream =
    allocate_stream(strmflags_wr_ch_B,strmtype_window,strm_channel_len,
                    sizeof(win32_console_extrafields_t));
  # try to reuse handle on win 95/98
  # make new handle on NT
  var int nt_systemp = 0;
  var bool handle_reused = 1;
  var OSVERSIONINFO osvers;
  osvers.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
  if (GetVersionEx(&osvers) && osvers.dwPlatformId == VER_PLATFORM_WIN32_NT)
    nt_systemp = 1;

  var HANDLE handle = (nt_systemp ? INVALID_HANDLE_VALUE
                       : GetStdHandle(STD_OUTPUT_HANDLE));
  if (handle==INVALID_HANDLE_VALUE) {
    handle = CreateConsoleScreenBuffer(GENERIC_READ|GENERIC_WRITE,
                                       0,
                                       NULL,
                                       CONSOLE_TEXTMODE_BUFFER,
                                       NULL);
    if (handle == INVALID_HANDLE_VALUE)
      fehler_unwritable(S(make_window),stream);
    SetConsoleActiveScreenBuffer(handle);
    handle_reused = 0;
  }
  var COORD console_size;
  var COORD console_pos;
  var CONSOLE_SCREEN_BUFFER_INFO info;
  if (GetConsoleScreenBufferInfo(handle,&info))
    console_size = info.dwSize;
  else {
    console_size.X = 80; console_size.Y = 25;
  }
  console_pos.X = 0;console_pos.Y = 0;

  stream_dummy_fill(stream);
  var Stream s = TheStream(stream);
  s->strm_wr_ch       = P(wr_ch_window);       # WRITE-CHAR Pseudofunction
  s->strm_wr_ch_array = P(wr_ch_array_window); # WRITE-CHAR-SEQUENCE Pseudofunction
 #ifdef UNICODE
  s->strm_encoding    = O(terminal_encoding);
 #else
  s->strm_encoding    = NIL;
 #endif
  s->strm_isatty      = NIL;
  s->strm_ichannel    = NIL;
  TheStream(stream)->strm_ochannel = allocate_handle(handle);
  # non GC-ed fields
  ConsoleData(stream)->console_size = console_size;
  ConsoleData(stream)->cursor_position = console_pos;
  ConsoleData(stream)->attribute = 0;
  ConsoleData(stream)->handle_reused = handle_reused;
  ChannelStream_init(stream);  # iconv extrafields init
  ChannelStream_lineno(stream) = 1;
  ChannelStream_buffered(stream) = false;
  ChannelStream_bitsize(stream) = 0;
  ChannelStreamLow_close(stream) = &low_close_console;
  v_move(handle,0,0);
  v_cl(handle,&console_pos,console_size,attr_table[0]);
  v_cs(handle);
  VALUES1(stream);
}

# close a window stream.
local void close_window (object stream) {
  close_ochannel(stream);
}

LISPFUNN(window_size,1) {
  var object stream = check_window_stream(popSTACK());
  var COORD  sz     = ConsoleData(stream)->console_size;
  VALUES2(fixnum(sz.Y),
          fixnum(sz.X));
}

LISPFUNN(window_cursor_position,1) {
  var object stream = check_window_stream(popSTACK());
  var COORD  pos    = ConsoleData(stream)->cursor_position;
  VALUES2(fixnum(pos.Y),
          fixnum(pos.X));
}

LISPFUNN(set_window_cursor_position,3) {
  var object stream = check_window_stream(STACK_2);
  var Handle handle = ConsoleHandleR(stream);
  var COORD  sz     = ConsoleData(stream)->console_size;
  var COORD pos;
  pos.Y = posfixnum_to_L(STACK_1);
  pos.X = posfixnum_to_L(STACK_0);
  if ((pos.Y < sz.Y) && (pos.X < sz.X)
      && (pos.Y >= 0) && (pos.X >= 0)) {
    v_move(handle,pos.Y,pos.X);
    ConsoleData(stream)->cursor_position = pos;
  }
  VALUES2(STACK_1, STACK_0); skipSTACK(3);
}

LISPFUNN(clear_window,1) {
  var object stream = check_window_stream(popSTACK());
  var Handle handle = ConsoleHandleR(stream);
  var COORD  pos    = ConsoleData(stream)->cursor_position;
  var COORD  sz     = ConsoleData(stream)->console_size;
  var uintW  attr   = attr_table[ConsoleData(stream)->attribute];
  v_cl(handle,&pos,sz,attr);
  ConsoleData(stream)->cursor_position = pos;
  VALUES0;
}

LISPFUNN(clear_window_to_eot,1) {
  var object stream = check_window_stream(popSTACK());
  var Handle handle = ConsoleHandleR(stream);
  var COORD  pos    = ConsoleData(stream)->cursor_position;
  var COORD  sz     = ConsoleData(stream)->console_size;
  var uintW  attr   = attr_table[ConsoleData(stream)->attribute];
  v_cd(handle,&pos,sz,attr);
  VALUES0;
}

LISPFUNN(clear_window_to_eol,1) {
  var object stream = check_window_stream(popSTACK());
  var Handle handle = ConsoleHandleR(stream);
  var COORD  pos    = ConsoleData(stream)->cursor_position;
  var COORD  sz     = ConsoleData(stream)->console_size;
  var uintW  attr   = attr_table[ConsoleData(stream)->attribute];
  v_ce(handle,&pos,sz,attr);
  VALUES0;
}

LISPFUNN(delete_window_line,1) {
  var object stream = check_window_stream(popSTACK());
  var Handle handle = ConsoleHandleR(stream);
  var COORD  pos    = ConsoleData(stream)->cursor_position;
  var COORD  sz     = ConsoleData(stream)->console_size;
  var uintW  attr   = attr_table[ConsoleData(stream)->attribute];
  v_dl(handle,&pos,sz,attr);
  VALUES0;
}

LISPFUNN(insert_window_line,1) {
  var object stream = check_window_stream(popSTACK());
  var Handle handle = ConsoleHandleR(stream);
  var COORD  pos    = ConsoleData(stream)->cursor_position;
  var COORD  sz     = ConsoleData(stream)->console_size;
  var uintW  attr   = attr_table[ConsoleData(stream)->attribute];
  v_al(handle,&pos,sz,attr);
  VALUES0;
}

LISPFUNN(highlight_on,1) {
  var object stream = check_window_stream(popSTACK());
  ConsoleData(stream)->attribute = 1;
  VALUES0;
}

LISPFUNN(highlight_off,1) {
  var object stream = check_window_stream(popSTACK());
  ConsoleData(stream)->attribute = 0;
  VALUES0;
}

LISPFUNN(window_cursor_on,1) {
  var object stream = check_window_stream(popSTACK());
  v_cb(ConsoleHandleR(stream));
  VALUES0;
}

LISPFUNN(window_cursor_off,1) {
  var object stream = check_window_stream(popSTACK());
  v_cs(ConsoleHandleR(stream));
  VALUES0;
}


#endif # WIN32_NATIVE

#if (defined(UNIX) && !defined(NEXTAPP)) || defined(RISCOS)

# -----------------------------------------------------------------------------

# Routines for the Emulation of all VT100-Features on normal Terminals.
# Idea: Oliver Laumann 1987

# Uses the TERMCAP-Library:
  # Gets the Capability-Informations for Terminal-Type name.
  # result: 1 if OK, 0 if name unknown, -1 on other error.
    extern_C int tgetent (const char* bp, const char* name);
  # gets the value of a numerical Capability (-1 if not available).
    extern_C int tgetnum (const char* id);
  # gets the value of a boolean Capability (1 if available, else 0).
    extern_C int tgetflag (const char* id);
  # gets the value of a String-significant Capability and (if area/=NULL)
  # copies it to *area and further advances *area.
    extern_C const char* tgetstr (const char* id, char** area);
  # gets the String, that causes a Cursor-Positioning to (destcol,destline).
  # (Necessary, because tgetstr("cm") has a special Format!)
    extern_C const char* tgoto (const char* cm, int destcol, int destline);
  # Performs a String-Capability. Thereto the output-function *outcharfun
  # is called for each Character. (Necessary, because String-Capabilities
  # can contain Padding-Commands!)
    #ifdef __cplusplus
      typedef void (*outcharfun_t) (...);
    #else
      typedef void (*outcharfun_t) ();
    #endif
    extern_C const char* tputs (const char* cp, int affcnt, outcharfun_t outcharfun);

# Adjustable settings:
  #define WANT_INSERT  false  # Insert-Mode
  #define WANT_SAVE    false  # Save/Restore for the Cursor-Position
  #define WANT_ATTR    true   # Attributes (bold, reverse etc.)
  #define WANT_CHARSET false  # Fonts = Charsets
  # Functions to be defined:
  #define WANT_CURSOR_MOVE         false
  #define WANT_CURSOR_BACKSPACE    false
  #define WANT_CURSOR_RETURN       true
  #define WANT_CURSOR_LINEFEED     true
  #define WANT_CURSOR_REVLINEFEED  false
  #define WANT_CLEAR_SCREEN        true
  #define WANT_CLEAR_FROM_BOS      false
  #define WANT_CLEAR_TO_EOS        true
  #define WANT_CLEAR_LINE          false
  #define WANT_CLEAR_FROM_BOL      false
  #define WANT_CLEAR_TO_EOL        true
  #define WANT_INSERT_1CHAR        false
  #define WANT_INSERT_CHAR         false
  #define WANT_INSERT_LINE         true
  #define WANT_DELETE_CHAR         false
  #define WANT_DELETE_LINE         true
  #define WANT_OUTPUT_1CHAR        true
  # small corrections:
  #define WANT_CLEAR_SCREEN        true
  #if WANT_OUTPUT_1CHAR && WANT_INSERT
  #define WANT_INSERT_1CHAR        true
  #endif

# output of a character, directly.
local void out_char (uintB c) {
 restart_it:
  var int result = write(stdout_handle,&c,1); # try to write character
  if (result<0) {
    if (errno==EINTR)
      goto restart_it;
    OS_error();
  }
  if (result==0) { # not successful?
    pushSTACK(var_stream(S(terminal_io),0)); # FILE-ERROR slot PATHNAME
    fehler(file_error,GETTEXT("cannot output to standard output"));
  }
}

# output of a Capability-String.
local void out_capstring (const char* s) {
  if (!(s==NULL)) # protection against non-existing Capability
    tputs(s,1,(outcharfun_t) &out_char);
}

# output of a Capability-String with an Argument.
local void out_cap1string (const char* s, int arg) {
  if (!(s==NULL)) # protection against non-existing Capability
    tputs(tgoto(s,0,arg),1,(outcharfun_t) &out_char);
}

# costs of execution of a Capability:
  #define EXPENSIVE 1000
  local uintC cost_counter; # counter
# Function, that does not write, but only counts:
local void count_char (char c) { cost_counter++; }

# calculates the costs of the writing of a Capability:
local uintC cap_cost (const char* s) {
  if (s==NULL) {
    return EXPENSIVE; # Capability non-existing
  } else {
    cost_counter = 0;
    tputs(s,1,(outcharfun_t) &count_char);
    return cost_counter;
  }
}

# Buffer for Capabilities that I need and Pointer to it:
  local char tentry[4096];
  local char* tp = &tentry[0];
# some chosen Capabilities (NULL or Pointer into tentry):
  # Insert-Mode:
  local const char* IMcap; # Enter Insert Mode
  local uintC IMcost;
  local const char* EIcap; # End Insert Mode
  local uintC EIcost;
  #if WANT_ATTR
  # Attributes:
  local const char* SOcap; # Enter standout mode
  local const char* SEcap; # End standout mode
  local const char* UScap; # Enter underline mode
  local const char* UEcap; # End underline mode
  local const char* MBcap; # Turn on blinking
  local const char* MDcap; # Turn on bold (extra-bright) mode
  local const char* MHcap; # Turn on half-bright mode
  local const char* MRcap; # Turn on reverse mode
  local const char* MEcap; # Turn off all attributes
  #endif
  #if WANT_CHARSET
  # charsets:
  local bool ISO2022; # if charset change according to ISO2022 is supported
  #endif
  # Cursor-Motion:
  local const char* CMcap; # Cursor motion, common Cursor-Positioning
  local const char* TIcap; # Initialize mode where CM is usable
  local const char* TEcap; # Exit mode where CM is usable
  local const char* BCcap; # Backspace Cursor
  local uintC BCcost;
  local const char* NDcap; # cursor right
  local uintC NDcost;
  local const char* DOcap; # cursor down
  local uintC DOcost;
  local const char* UPcap; # cursor up
  local uintC UPcost;
  local const char* NLcap; # Newline
  local const char* CRcap; # Carriage Return
  local uintC CRcost;
  # Scrolling:
  local const char* CScap; # change scroll region
  #if WANT_DELETE_LINE
  local const char* SFcap; # Scroll (text up)
  #endif
  #if WANT_CURSOR_REVLINEFEED || WANT_INSERT_LINE
  local const char* SRcap; # Scroll reverse (text down)
  #endif
  # Others:
  local const char* IScap; # Terminal Initialization 2
#  local const char* BLcap; # Bell
#  local const char* VBcap; # Visible Bell (Flash)
  local const char* CLcap; # clear screen, cursor home
  #if WANT_CLEAR_FROM_BOS || WANT_CLEAR_TO_EOS || WANT_CLEAR_LINE || WANT_CLEAR_FROM_BOL || WANT_CLEAR_TO_EOL
  local const char* CEcap; # clear to end of line
  #endif
  #if WANT_CLEAR_TO_EOS
  local const char* CDcap; # clear to end of screen
  #endif
  #if WANT_CURSOR_REVLINEFEED || WANT_INSERT_LINE
  local const char* ALcap; # add new blank line
  #endif
  #if WANT_DELETE_LINE
  local const char* DLcap; # delete line
  #endif
  #if WANT_DELETE_CHAR
  local const char* DCcap; # delete character
  #endif
  #if WANT_INSERT_1CHAR || WANT_INSERT_CHAR
  local const char* ICcap; # insert character
  #endif
  #if WANT_INSERT_CHAR
  local const char* CICcap; # insert count characters
  #endif
  #if WANT_INSERT_LINE
  local const char* CALcap; # add count blank lines
  #endif
  #if WANT_DELETE_CHAR
  local const char* CDCcap; # delete count chars
  #endif
  #if WANT_DELETE_LINE
  local const char* CDLcap; # delete count lines
  #endif
  local bool AM; # automatic margins, if scrolling on right bottom corner (??)
  local int rows; # number of rows of the screen, >0
  local int cols; # number of columns of the screen, >0
  # top row is row 0, bottom row is row rows-1.
  # left-most column is column 0, right-most column is column cols-1.
  #if WANT_ATTR || WANT_CHARSET
  local uintB* null; # Pointer to cols Zeros
  #endif
  local uintB* blank; # Pointer to cols Blanks

# Description of a Terminal-Output-Unit:
typedef struct {
  uintB** image; # image[y][x] is the character at Position (x,y)
  #if WANT_ATTR
  uintB** attr;  # attr[y][x] is its Attribute
  uintB curr_attr; # which Attribut is now the current one
  #endif
  #if WANT_CHARSET
  uintB** font;  # font[y][x] is its Font (Charset)
  #define charset_count 4
  uintB charsets[charset_count]; # Table of charsets
  uintC curr_charset; # which of the charsets is the current one
                      # (>=0, <charset_count)
  #endif
  int x; # Cursorposition (>=0, <=cols)
  int y; # Cursorposition (>=0, <rows)
         # (At x=cols the Cursor is displayed in column cols-1.)
  int top, bot; # Scroll-Region = rows y with top <= y <= bot,
                # It applies: 0 <= top <= bot <= rows-1.
  #if WANT_INSERT
  bool insert; # if the Output-Unit works in Insert-Mode
                  # (then the Terminal is mostly in Insert-Mode)
  #endif
  #if WANT_SAVE
  bool saved;
  #if WANT_ATTR
  uintB saved_curr_attr;
  #endif
  #if WANT_CHARSET
  uintB saved_charsets[charset_count];
  uintC saved_curr_charset;
  #endif
  int saved_x, saved_y;
  #endif
} win;

# current Output-Unit:
  local win currwin; # there is only one!
  #define curr (&currwin)

#if WANT_INSERT

# switch on/of Insert-Mode:
# Flag, if the Terminal is in Insert-Mode (if there is one):
local bool insert;
local void set_insert_mode (bool flag) {
  if (flag) { # switch on
    if (!insert)
      out_capstring(IMcap);
  } else { # switch off
    if (insert)
      out_capstring(EIcap);
  }
  insert = flag;
}

#endif

#if WANT_ATTR

# toggle the Output-Attributes of the Terminal:
  local uintB term_attr; # current Attributes of the Terminal
  # possible Attributes are on ODER off:
    #define A_SO    bit(0)  # Standout mode
    #define A_US    bit(1)  # Underscore mode
    #define A_BL    bit(2)  # Blinking
    #define A_BD    bit(3)  # Bold mode
    #define A_DI    bit(4)  # Dim mode
    #define A_RV    bit(5)  # Reverse mode
local void change_attr (uintB new_attr) {
  var uintB old_attr = term_attr;
  if (old_attr == new_attr)
    return;
  if (   ((old_attr & A_SO) && !(new_attr & A_SO))
         || ((old_attr & A_US) && !(new_attr & A_US))
         || ((old_attr & A_BL) && !(new_attr & A_BL))
         || ((old_attr & A_BD) && !(new_attr & A_BD))
         || ((old_attr & A_DI) && !(new_attr & A_DI))
         || ((old_attr & A_RV) && !(new_attr & A_RV))) {
    # Must switch of Attributes.
    out_capstring(UEcap); # all are off
    out_capstring(SEcap);
    out_capstring(MEcap);
    if (new_attr & A_SO) out_capstring(SOcap); # and switch on selectively
    if (new_attr & A_US) out_capstring(UScap);
    if (new_attr & A_BL) out_capstring(MBcap);
    if (new_attr & A_BD) out_capstring(MDcap);
    if (new_attr & A_DI) out_capstring(MHcap);
    if (new_attr & A_RV) out_capstring(MRcap);
  } else {
    # switch on selectively:
    if ((new_attr & A_SO) && !(old_attr & A_SO)) out_capstring(SOcap);
    if ((new_attr & A_US) && !(old_attr & A_US)) out_capstring(UScap);
    if ((new_attr & A_BL) && !(old_attr & A_BL)) out_capstring(MBcap);
    if ((new_attr & A_BD) && !(old_attr & A_BD)) out_capstring(MDcap);
    if ((new_attr & A_DI) && !(old_attr & A_DI)) out_capstring(MHcap);
    if ((new_attr & A_RV) && !(old_attr & A_RV)) out_capstring(MRcap);
  }
  term_attr = new_attr;
}

#endif

#if WANT_CHARSET

# change Output-Charset of the Terminal:
  local uintB term_charset; # current charset of the Terminal
                            # = curr->charsets[curr->curr_charset]
  #define ASCII 0  # abbreviation for the charset 'B'
local void change_charset (uintB new) {
  if (term_charset==new)
    return;
  if (ISO2022) {
    out_char(ESC); out_char('('); out_char(new==ASCII ? 'B' : new);
  }
  term_charset = new;
}
# change Charset Nr. n to c:
local void choose_charset (uintB c, uintC n) {
  if (c=='B')
    c = ASCII;
  if (curr->charsets[n] == c)
    return;
  curr->charsets[n] = c;
  if (curr->curr_charset == n) # the current one?
    change_charset(c);
}
# make Charset Nr. n the current one:
local void set_curr_charset (uintC n) {
  if (curr->curr_charset == n)
    return;
  curr->curr_charset = n;
  change_charset(curr->charsets[n]);
}

#endif

# calculate the costs of Redisplay of row y, characters x1..x2-1:
# (0 <= y < rows, 0 <= x1 <= x2 <= cols)
local uintC rewrite_cost (int y, int x1, int x2) {
  if (AM && (y==rows-1) && (x2==cols)) # right bottom corner can scroll?
    return EXPENSIVE;
  var int dx = x2-x1;
  if (dx==0)
    return 0;
 #if WANT_ATTR
  {
    var uintB* p = &curr->attr[y][x1];
    var uintC count;
    dotimespC(count,dx, {
      if (!(*p++ == term_attr)) # Attribut-Change necessary?
        return EXPENSIVE;
    });
  }
 #endif
 #if WANT_CHARSET
  {
    var uintB* p = &curr->font[y][x1];
    var uintC count;
    dotimespC(count,dx, {
      if (!(*p++ == term_charset)) # Font-Change necessary?
        return EXPENSIVE;
    });
  }
 #endif
  var uintC cost = dx;
 #if WANT_INSERT
  if (curr->insert)
    cost += EIcost + IMcost;
 #endif
  return cost;
}

# Moves the Cursor from Position (y1,x1) to Position (y2,x2).
# (x1,y1) = (-1,-1) if the current Position is unknown.
local void gofromto (int y1, int x1, int y2, int x2) {
  if (x2==cols) { # Cursor to the right border?
    x2--; out_capstring(tgoto(CMcap,x2,y2)); return; # remains in last column
  }
  if (x1==cols) { # Cursor is at the right border?
    out_capstring(tgoto(CMcap,x2,y2)); return; # address in absolute coords
  }
  var int dy = y2-y1;
  var int dx = x2-x1;
  if ((dy==0) && (dx==0))
    return;
  if ((y1==-1) || (x1==-1) || (y2 > curr->bot) || (y2 < curr->top)) {
    out_capstring(tgoto(CMcap,x2,y2)); return;
  }
  var enum { MX_NONE, MX_LE, MX_RI, MX_RW, MX_CR } mx = MX_NONE;
  var enum { MY_NONE, MY_UP, MY_DO } my = MY_NONE;
  # Option 1: with CMcap
  var uintC CMcost = cap_cost(tgoto(CMcap,x2,y2));
  # Option 2: with separate x- and y-movements:
  var uintC xycost = 0;
  if (dx > 0) {
    var uintC cost1 = rewrite_cost(y1,x1,x2);
    var uintC cost2 = dx * NDcost;
    if (cost1 < cost2) {
      mx = MX_RW; xycost += cost1;
    } else {
      mx = MX_RI; xycost += cost2;
    }
  } else if (dx < 0) {
    mx = MX_LE; xycost += (-dx) * BCcost;
  }
  if (!(dx==0)) {
    var uintC cost1 = CRcost + rewrite_cost(y1,0,x2);
    if (cost1 < xycost) {
      mx = MX_CR; xycost = cost1;
    }
  }
  if (dy > 0) {
    my = MY_DO; xycost += dy * DOcost;
  } else if (dy < 0) {
    my = MY_UP; xycost += (-dy) * UPcost;
  }
  if (xycost >= CMcost) {
    out_capstring(tgoto(CMcap,x2,y2)); return;
  }
  if (!(mx==MX_NONE)) {
    if ((mx==MX_LE) || (mx==MX_RI)) {
      var const char* s;
      if (mx==MX_LE) {
        dx = -dx; s = BCcap;
      } else {
        s = NDcap;
      }
      do {
        out_capstring(s);
      } until (--dx == 0);
    } else {
      if (mx==MX_CR) {
        out_capstring(CRcap); x1=0;
      }
      # hereof the costs were calculated with rewrite_cost:
      if (x1<x2) {
       #if WANT_INSERT
        if (curr->insert)
          set_insert_mode(false);
       #endif
        {
          var uintB* ptr = &curr->image[y1][x1];
          var uintC count;
          dotimespC(count,x2-x1, { out_char(*ptr++); });
        }
       #if WANT_INSERT
        if (curr->insert)
          set_insert_mode(true);
       #endif
      }
    }
  }
  if (!(my==MY_NONE)) {
    var const char* s;
    if (my==MY_UP) {
      dy = -dy; s = UPcap;
    } else {
      s = DOcap;
    }
    do {
      out_capstring(s);
    } until (--dy == 0);
  }
}

# Redisplay
# local Variables:
local int last_x;
local int last_y;
# Redisplay a line, that might have changed:
# pass only Parameters that are really needed:
#if WANT_ATTR && WANT_CHARSET
  #define RHargs(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,oap,ofp,nsp,nap,nfp,y,x1,x2)
  #define RHparms(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,oap,ofp,nsp,nap,nfp,y,x1,x2)
#endif
#if !WANT_ATTR && WANT_CHARSET
  #define RHargs(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,ofp,nsp,nfp,y,x1,x2)
  #define RHparms(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,ofp,nsp,nfp,y,x1,x2,oap,nap)
#endif
#if WANT_ATTR && !WANT_CHARSET
  #define RHargs(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,oap,nsp,nap,y,x1,x2)
  #define RHparms(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,oap,nsp,nap,y,x1,x2,ofp,nfp)
#endif
#if !WANT_ATTR && !WANT_CHARSET
  #define RHargs(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,nsp,y,x1,x2)
  #define RHparms(osp,oap,ofp,nsp,nap,nfp,y,x1,x2) (osp,nsp,y,x1,x2,oap,ofp,nap,nfp)
#endif
#undef RHparms
#define RHparms  RHargs  # declare correctly
local void redisplay_help RHparms (uintB* osp, uintB* oap, uintB* ofp, # old
                                   uintB* nsp, uintB* nap, uintB* nfp, # new
                                   # line y, from x1 to x2-1
                                   int y, int x1, int x2) {
  if (AM && (y == rows-1) && (x2 == cols))
    x2--;
 #if WANT_ATTR
  var uintB a = term_attr; # last Attribute
 #endif
 #if WANT_CHARSET
  var uintB f = term_charset; # last Font
 #endif
  var int x = x1;
  osp = &osp[x1]; nsp = &nsp[x1];
 #if WANT_ATTR
  oap = &oap[x1]; nap = &nap[x1];
 #endif
 #if WANT_CHARSET
  ofp = &ofp[x1]; nfp = &nfp[x1];
 #endif
  while (x < x2) {
    if (!((*nsp==*osp)
        #if WANT_ATTR
          && (*nap==*oap) && (*nap==a)
        #endif
        #if WANT_CHARSET
          && (*nfp==*nap) && (*nfp==f)
        #endif
          )) {
      gofromto(last_y,last_x,y,x);
     #if WANT_ATTR
      a = *nap;
      if (!(a==term_attr))
        change_attr(a);
     #endif
     #if WANT_CHARSET
      f = *nfp;
      if (!(f==term_charset))
        change_charset(f);
     #endif
      out_char(*nsp);
      last_y = y; last_x = x+1;
    }
    x++;
    osp++; nsp++;
   #if WANT_ATTR
    oap++; nap++;
   #endif
   #if WANT_CHARSET
    ofp++; nfp++;
   #endif
  }
}
#if WANT_INSERT_1CHAR || WANT_INSERT_CHAR || WANT_DELETE_CHAR
# Redisplay a line:
# pass only Parameters that are really needed:
#if WANT_ATTR && WANT_CHARSET
  #define RLargs(osp,oap,ofp,y,x1,x2) (osp,oap,ofp,y,x1,x2)
  #define RLparms(osp,oap,ofp,y,x1,x2) (osp,oap,ofp,y,x1,x2)
#endif
#if !WANT_ATTR && WANT_CHARSET
  #define RLargs(osp,oap,ofp,y,x1,x2) (osp,ofp,y,x1,x2)
  #define RLparms(osp,oap,ofp,y,x1,x2) (osp,ofp,y,x1,x2,oap)
#endif
#if WANT_ATTR && !WANT_CHARSET
  #define RLargs(osp,oap,ofp,y,x1,x2) (osp,oap,y,x1,x2)
  #define RLparms(osp,oap,ofp,y,x1,x2) (osp,oap,y,x1,x2,ofp)
#endif
#if !WANT_ATTR && !WANT_CHARSET
  #define RLargs(osp,oap,ofp,y,x1,x2) (osp,y,x1,x2)
  #define RLparms(osp,oap,ofp,y,x1,x2) (osp,y,x1,x2,oap,ofp)
#endif
#undef RHparms
#define RHparms  RHargs  # declare correctly
local void redisplay_line RLparms (uintB* osp, uintB* oap, uintB* ofp, # old
                                   # line y, from x1 to x2-1
                                   int y, int x1, int x2) {
 #if WANT_INSERT
  if (curr->insert)
    set_insert_mode(false);
 #endif
 #if WANT_ATTR
  var uintB saved_attr = term_attr;
  change_attr(0);
 #endif
 #if WANT_CHARSET
  var uintB saved_charset = term_charset;
  change_charset(ASCII);
 #endif
  last_y = y; last_x = x1;
  redisplay_help RHargs(osp,           oap,          ofp,
                        curr->image[y],curr->attr[y],curr->font[y],
                        y, x1,x2);
 #if WANT_CHARSET
  change_charset(saved_charset);
 #endif
 #if WANT_ATTR
  change_attr(saved_attr);
 #endif
 #if WANT_INSERT
  if (curr->insert)
    set_insert_mode(true);
 #endif
}
#endif
# Redisplay the whole screen:
local void redisplay (void) {
 #if WANT_INSERT
  set_insert_mode(false);
 #endif
 #if WANT_ATTR
  var uintB saved_attr = term_attr;
  change_attr(0);
 #endif
 #if WANT_CHARSET
  var uintB saved_charset = term_charset;
  change_charset(ASCII);
 #endif
  out_capstring(CLcap); last_x = 0; last_y = 0;
  {
    var uintC y = 0;
    while (y<rows) {
      redisplay_help
        RHargs(blank,         null,         null,          # old
               curr->image[y],curr->attr[y],curr->font[y], # new
               y,                                          # line y
               0,cols);                                    # all columns
      y++;
    }
  }
 #if WANT_CHARSET
  change_charset(saved_charset);
 #endif
 #if WANT_ATTR
  change_attr(saved_attr);
 #endif
 #if WANT_INSERT
  if (curr->insert)
    set_insert_mode(true);
 #endif
  gofromto(last_y,last_x,curr->y,curr->x);
}

# Further Cursor-Movements:
#if WANT_CURSOR_MOVE

local void cursor_right (int n) {
  var int x = curr->x;
  if (x==cols)
    return;
  var int new_x = x + n;
  if (new_x > cols)
    new_x = cols;
  gofromto(curr->y,x,curr->y,curr->x = new_x);
}

local void cursor_left (int n) {
  var int x = curr->x;
  var int new_x = x - n;
  if (new_x < 0)
    new_x = 0;
  gofromto(curr->y,x,curr->y,curr->x = new_x);
}

local void cursor_up (int n) {
  var int y = curr->y;
  var int new_y = y - n;
  if (new_y < 0)
    new_y = 0;
  gofromto(y,curr->x,curr->y = new_y,curr->x);
}

local void cursor_down (int n) {
  var int y = curr->y;
  var int new_y = y + n;
  if (new_y >= rows)
    new_y = rows-1;
  gofromto(y,curr->x,curr->y = new_y,curr->x);
}

#endif

# Backspace (Cursor to the left by 1, within a line)
#if WANT_CURSOR_BACKSPACE
local void cursor_backspace (void) {
  if (curr->x > 0) {
    if (curr->x < cols) {
      if (BCcap)
        out_capstring(BCcap);
      else
        gofromto(curr->y,curr->x,curr->y,curr->x - 1);
    }
    curr->x = curr->x - 1;
  }
}
#endif

# Return (Cursor to the beginning of a line)
#if WANT_CURSOR_RETURN
local void cursor_return (void) {
  if (curr->x > 0) {
    out_capstring(CRcap); curr->x = 0;
  }
}
#endif

# auxiliary routines for scrolling:
#if WANT_CURSOR_LINEFEED || WANT_DELETE_LINE
local void scroll_up_help (uintB** pp, uintB filler) {
  # shift pp[top..bot] by one to the left,
  # take out pp[top], delete and insert again as pp[bot]:
  pp = &pp[curr->top];
  var uintC count;
  var uintB* tmp = *pp;
  dotimesC(count,curr->bot - curr->top, { pp[0] = pp[1]; pp++; } );
  memset(tmp,filler,cols);
  *pp = tmp;
}
local void scroll_up (void) {
  scroll_up_help(curr->image,' ');
 #if WANT_ATTR
  scroll_up_help(curr->attr,0);
 #endif
 #if WANT_CHARSET
  scroll_up_help(curr->font,0);
 #endif
}
#endif
#if WANT_CURSOR_REVLINEFEED || WANT_INSERT_LINE
local void scroll_down_help (uintB** pp, uintB filler) {
  # shift pp[top..bot] by one to the right,
  # take out pp[top], delete and insert again as pp[bot]:
  pp = &pp[curr->bot];
  var uintC count;
  var uintB* tmp = *pp;
  dotimesC(count,curr->bot - curr->top, { pp[0] = pp[-1]; pp--; } );
  memset(tmp,filler,cols);
  *pp = tmp;
}
local void scroll_down (void) {
  scroll_down_help(curr->image,' ');
 #if WANT_ATTR
  scroll_down_help(curr->attr,0);
 #endif
 #if WANT_CHARSET
  scroll_down_help(curr->font,0);
 #endif
}
#endif

# Linefeed (Cursor down by 1):
#if WANT_CURSOR_LINEFEED
local void cursor_linefeed (void) {
  if (curr->y == curr->bot)
    scroll_up();
  else if (curr->y < rows-1)
    curr->y++;
  out_capstring(NLcap);
}
#endif

# Reverse Linefeed (Cursor up by 1):
#if WANT_CURSOR_REVLINEFEED
local void cursor_revlinefeed (void) {
  if (curr->y == curr->top) {
    scroll_down();
    if (SRcap) {
      out_capstring(SRcap);
    } else if (ALcap) {
      gofromto(curr->top,curr->x,curr->top,0); # Cursor to the left
      out_capstring(ALcap);
      gofromto(curr->top,0,curr->top,curr->x); # Cursor back again
    } else {
      redisplay();
    }
  } else if (curr->y > 0) {
    cursor_up(1);
  }
}
#endif

# Deletion-Operations:

# delete part of a line:
#if WANT_CLEAR_SCREEN || WANT_CLEAR_FROM_BOS
local void cleared_linepart (int y, int x1, int x2) {
  var int n = x2-x1;
  if (n>0) {
    memset(&curr->image[y][x1],' ',n);
   #if WANT_ATTR
    memset(&curr->attr[y][x1],0,n);
   #endif
   #if WANT_CHARSET
    memset(&curr->font[y][x1],0,n);
   #endif
  }
}
#endif

# delete screen:
#if WANT_CLEAR_SCREEN
local void clear_screen (void) {
  out_capstring(CLcap);
  var uintC y = 0;
  while (y<rows) { cleared_linepart(y,0,cols); y++; }
}
#endif

# delete part of a line:
#if WANT_CLEAR_FROM_BOS || WANT_CLEAR_TO_EOS || WANT_CLEAR_LINE || WANT_CLEAR_FROM_BOL || WANT_CLEAR_TO_EOL
local void clear_linepart (int y, int x1, int x2) {
  var int n = x2-x1;
  if (n>0) {
    memset(&curr->image[y][x1],' ',n);
   #if WANT_ATTR
    memset(&curr->attr[y][x1],0,n);
   #endif
   #if WANT_CHARSET
    memset(&curr->font[y][x1],0,n);
   #endif
    if ((x2==cols) && CEcap) {
      gofromto(curr->y,curr->x,y,x1); curr->y = y; curr->x = x1;
      out_capstring(CEcap);
    } else {
      if ((x2==cols) && (y==rows-1) && AM)
        n--;
      if (n>0) {
       #if WANT_ATTR
        var uintB saved_attr = term_attr;
        change_attr(0);
       #endif
       #if WANT_CHARSET
        var uintB saved_charset = term_charset;
        change_charset(ASCII);
       #endif
       #if WANT_INSERT
        if (curr->insert)
          set_insert_mode(false);
          #endif
        gofromto(curr->y,curr->x,y,x1);
        {
          var uintC count;
          dotimespC(count,n, { out_char(' '); } );
        }
        curr->y = y; curr->x = x1+n;
       #if WANT_CHARSET
        change_charset(saved_charset);
       #endif
       #if WANT_ATTR
        change_attr(saved_attr);
       #endif
       #if WANT_INSERT
        if (curr->insert)
          set_insert_mode(true);
       #endif
      }
    }
  }
}
#endif

# delete screen up to the Cursor (exclusive):
#if WANT_CLEAR_FROM_BOS
local void clear_from_BOS (void) {
  var int y0 = curr->y;
  var int x0 = curr->x;
  var int y = 0;
  while (y<y0) { clear_linepart(y,0,cols); y++; }
  clear_linepart(y0,0,x0);
  gofromto(curr->y,curr->x,y0,x0); curr->y = y0; curr->x = x0;
}
#endif

# delete screen starting at cursor (inclusive):
#if WANT_CLEAR_TO_EOS
local void clear_to_EOS (void) {
  var int y0 = curr->y;
  var int x0 = curr->x;
  if (CDcap) {
    out_capstring(CDcap);
    cleared_linepart(y0,x0,cols);
    var int y = y0;
    while (++y < rows) { cleared_linepart(y,0,cols); }
  } else {
    clear_linepart(y0,x0,cols);
    var int y = y0;
    while (++y < rows) { clear_linepart(y,0,cols); }
  }
  gofromto(curr->y,curr->x,y0,x0); curr->y = y0; curr->x = x0;
}
#endif

# delete cursor-line:
#if WANT_CLEAR_LINE
local void clear_line (void) {
  var int y0 = curr->y;
  var int x0 = curr->x;
  clear_linepart(y0,0,cols);
  gofromto(curr->y,curr->x,y0,x0); curr->y = y0; curr->x = x0;
}
#endif

# delete cursor-line up to cursor (exclusive):
#if WANT_CLEAR_FROM_BOL
local void clear_from_BOL (void) {
  var int y0 = curr->y;
  var int x0 = curr->x;
  clear_linepart(y0,0,x0);
  gofromto(curr->y,curr->x,y0,x0); curr->y = y0; curr->x = x0;
}
#endif

# delete cursor-line starting at cursor (inclusive):
#if WANT_CLEAR_TO_EOL
local void clear_to_EOL (void) {
  var int y0 = curr->y;
  var int x0 = curr->x;
  clear_linepart(y0,x0,cols);
  gofromto(curr->y,curr->x,y0,x0); curr->y = y0; curr->x = x0;
}
#endif

# Insertion-Operations:

# old content of line:
#if WANT_INSERT_1CHAR || WANT_INSERT_CHAR || WANT_DELETE_CHAR
  local uintB* old_image_y;
  #if WANT_ATTR
  local uintB* old_attr_y;
  #endif
  #if WANT_CHARSET
  local uintB* old_font_y;
  #endif
local void save_line_old (int y) {
  if (cols > 0) {
    memcpy(&old_image_y[0],&curr->image[y][0],cols);
   #if WANT_ATTR
    memcpy(&old_attr_y[0],&curr->attr[y][0],cols);
   #endif
   #if WANT_CHARSET
    memcpy(&old_font_y[0],&curr->font[y][0],cols);
   #endif
  }
}
#endif

# insert a character:
#if WANT_INSERT_1CHAR
local void insert_1char (uintB c) {
  var int y = curr->y;
  var int x = curr->x;
  if (x==cols)
    x--; # do not write beyond right border!
  if (ICcap || IMcap) {
    curr->image[y][x] = c;
   #if WANT_ATTR
    curr->attr[y][x] = curr->curr_attr;
   #endif
   #if WANT_CHARSET
    curr->font[y][x] = curr->charsets[curr->curr_charset]; # = term_charset
   #endif
   #if WANT_INSERT
    if (!curr->insert)
   #endif
      set_insert_mode(true);
    out_capstring(ICcap); out_char(c);
   #if WANT_INSERT
    if (!curr->insert)
   #endif
      set_insert_mode(false);
    curr->x = x+1;
  } else {
    # save old line-content:
    save_line_old(y);
    # build new line-content:
    {
      var uintB* p1 = &curr->image[y][x];
      *p1++ = c;
      memcpy(p1,&old_image[x],cols-1-x);
    }
   #if WANT_ATTR
    {
      var uintB* p1 = &curr->attr[y][x];
      *p1++ = curr->curr_attr;
      memcpy(p1,&old_attr[x],cols-1-x);
    }
   #endif
   #if WANT_CHARSET
    {
      var uintB* p1 = &curr->font[y][x];
      *p1++ = term_charset; # = curr->charsets[curr->curr_charset]
      memcpy(p1,&old_font[x],cols-1-x);
    }
   #endif
    # display line:
    redisplay_line RLargs(old_image,old_attr,old_font,y,x,cols);
    x++;
    gofromto(last_y,last_x,y,x); curr->x = x;
  }
}
#endif

# create room for n characters:
#if WANT_INSERT_CHAR
local void insert_char (uintC n) {
  var int y = curr->y;
  var int x = curr->x;
  if (n > cols-x)
    n = cols-x;
  if (n==0)
    return;
  # save old line-content:
  save_line_old(y);
  # build new line-content:
  {
    var uintB* p1 = &curr->image[y][x];
    memset(p1,' ',n);
    memcpy(p1+n,&old_image[x],cols-x-n);
  }
 #if WANT_ATTR
  {
    var uintB* p1 = &curr->attr[y][x];
    memset(p1,0,n);
    memcpy(p1+n,&old_attr[x],cols-x-n);
  }
 #endif
 #if WANT_CHARSET
  {
    var uintB* p1 = &curr->font[y][x];
    memset(p1,0,n);
    memcpy(p1+n,&old_font[x],cols-x-n);
  }
 #endif
  if (CICcap && (n > 1)) {
   #if WANT_INSERT
    if (curr->insert)
      set_insert_mode(false);
   #endif
    out_cap1string(CICcap,n);
    {
      var uintC count;
      dotimespC(count,n, { out_char(' '); } );
    }
   #if WANT_INSERT
    if (curr->insert)
      set_insert_mode(true);
   #endif
    gofromto(y,x+n,y,x);
  } else if (ICcap || IMcap) {
   #if WANT_INSERT
    if (!curr->insert)
   #endif
      set_insert_mode(true);
    {
      var uintC count;
      dotimespC(count,n, { out_capstring(ICcap); out_char(' '); } );
    }
   #if WANT_INSERT
    if (!curr->insert)
   #endif
      set_insert_mode(false);
    gofromto(y,x+n,y,x);
  } else {
    redisplay_line RLargs(old_image,old_attr,old_font,y,x,cols);
    gofromto(last_y,last_x,y,x);
  }
}
#endif

# insert lines:
#if WANT_INSERT_LINE
local void insert_line (uintC n) {
  if (n > curr->bot - curr->y + 1)
    n = curr->bot - curr->y + 1;
  if (n==0)
    return;
  var int oldtop = curr->top;
  curr->top = curr->y;
  {
    var uintC count;
    dotimespC(count,n, { scroll_down(); } );
  }
  if (ALcap || CALcap) {
    gofromto(curr->y,curr->x,curr->y,0); # to the beginning of the line
    if ((CALcap && (n>1)) || !ALcap) {
      out_cap1string(CALcap,n);
    } else {
      var uintC count;
      dotimespC(count,n, { out_capstring(ALcap); } );
    }
    gofromto(curr->y,0,curr->y,curr->x);
  } else if (CScap && SRcap) {
    out_capstring(tgoto(CScap,curr->bot,curr->top));
    gofromto(-1,-1,curr->top,0);
    {
      var uintC count;
      dotimespC(count,n, { out_capstring(SRcap); } );
    }
    out_capstring(tgoto(CScap,curr->bot,oldtop));
    gofromto(-1,-1,curr->y,curr->x);
  } else {
    redisplay();
  }
  curr->top = oldtop;
}
#endif

# Deletion-Operations:

# delete Characters:
#if WANT_DELETE_CHAR
local void delete_char (uintC n) {
  var int y = curr->y;
  var int x = curr->x;
  if (n > cols-x)
    n = cols-x;
  if (n==0)
    return;
  # save old line-content:
  save_line_old(y);
  # build new line-content:
  {
    var uintB* p1 = &curr->image[y][x];
    memcpy(p1,&old_image[x],cols-x-n);
    memset(p1+cols-x-n,' ',n);
  }
 #if WANT_ATTR
  {
    var uintB* p1 = &curr->attr[y][x];
    memcpy(p1,&old_attr[x],cols-x-n);
    memset(p1+cols-x-n,0,n);
  }
 #endif
 #if WANT_CHARSET
  {
    var uintB* p1 = &curr->font[y][x];
    memcpy(p1,&old_font[x],cols-x-n);
    memset(p1+cols-x-n,0,n);
  }
 #endif
  if (CDCcap && ((n>1) || !DCcap)) {
    out_cap1string(CDCcap,n);
  } else if (DCcap) {
    var uintC count;
    dotimespC(count,n, { out_capstring(DCcap); } );
  } else {
    redisplay_line RLargs(old_image,old_attr,old_font,y,x,cols);
    gofromto(last_y,last_x,y,x);
  }
}

#endif

# delete lines:
#if WANT_DELETE_LINE
local void delete_line (uintC n) {
  if (n > curr->bot - curr->y + 1)
    n = curr->bot - curr->y + 1;
  if (n==0)
    return;
  var int oldtop = curr->top;
  curr->top = curr->y;
  {
    var uintC count;
    dotimespC(count,n, { scroll_up(); } );
  }
  if (DLcap || CDLcap) {
    gofromto(curr->y,curr->x,curr->y,0); # to the beginning of the line
    if ((CDLcap && (n>1)) || !DLcap) {
      out_cap1string(CDLcap,n);
    } else {
      var uintC count;
      dotimespC(count,n, { out_capstring(DLcap); } );
    }
    gofromto(curr->y,0,curr->y,curr->x);
  } else if (CScap) {
    out_capstring(tgoto(CScap,curr->bot,curr->top));
    gofromto(-1,-1,curr->bot,0);
    {
      var uintC count;
      dotimespC(count,n, { out_capstring(SFcap); } );
    }
    out_capstring(tgoto(CScap,curr->bot,oldtop));
    gofromto(-1,-1,curr->y,curr->x);
  } else {
    redisplay();
  }
  curr->top = oldtop;
}
#endif

# write a character:
#if WANT_OUTPUT_1CHAR
local void output_1char (uintB c) {
 #if WANT_INSERT
  if (curr->insert) {
    insert_1char(c);
    return;
  }
 #endif
  var int y = curr->y;
  var int x = curr->x;
  if (x==cols)
    x--; # do not write beyond right border!
  curr->image[y][x] = c;
 #if WANT_ATTR
  curr->attr[y][x] = curr->curr_attr;
 #endif
 #if WANT_CHARSET
  curr->font[y][x] = curr->charsets[curr->curr_charset]; # = term_charset
 #endif
  x++;
  if (!(AM && (x==cols) && (curr->y==curr->bot))) # poss. spare right lower corner
    out_char(c); # write character
  curr->x = x; # Cursor is advanced by one
  if (x==cols) # except it was already located rightmost
    gofromto(-1,-1,curr->y,curr->x);
}
#endif

#if WANT_SAVE

# stored Cursor-Position:
local void save_cursor (void) {
  curr->saved_x = curr->x;
  curr->saved_y = curr->y;
 #if WANT_ATTR
  curr->saved_curr_attr = curr->curr_attr;
 #endif
 #if WANT_CHARSET
  curr->saved_curr_charset = curr->curr_charset;
  {
    var uintC i = 0;
    while (i<charset_count)
      { curr->saved_charsets[i] = curr->charsets[i]; i++; }
  }
 #endif
  curr->saved = true;
}
local void restore_cursor (void) {
  if (curr->saved) {
    gofromto(curr->y,curr->x,curr->saved_y,curr->saved_x);
    curr->y = curr->saved_y; curr->x = curr->saved_x;
   #if WANT_ATTR
    curr->curr_attr = curr->saved_curr_attr;
    change_attr(curr->curr_attr);
   #endif
   #if WANT_CHARSET
    curr->curr_charset = curr->saved_curr_charset;
    {
      var uintC i = 0;
      while (i<charset_count)
        { curr->charsets[i] = curr->saved_charsets[i]; i++; }
    }
    change_charset(curr->charsets[curr->curr_charset]);
   #endif
  }
}

#endif

# Initializes the Terminal.
# Returns NULL if OK, else returns an error-string.
local bool term_initialized = false;
local const char * init_term (void) {
  var char tbuf[4096]; # internal Buffer for the Termcap-Routines
  if (term_initialized)
    return NULL; # already initialized -> OK
  # query Terminal-Type:
  begin_system_call();
  {
    var const char* s = getenv("TERM");
    if (s==NULL) {
      end_system_call();
      return GETTEXT("environment has no TERM variable");
    }
    if (!(tgetent(tbuf,s)==1)) {
      end_system_call();
      pushSTACK(asciz_to_string(s,O(misc_encoding)));
      return GETTEXT("terminal type ~ unknown to termcap");
    }
  }
  {
    var int i = tgetnum("co");
    cols = (i>0 ? i : 80);
  }
  {
    var int i = tgetnum("li");
    rows = (i>0 ? i : 24);
  }
 #ifdef EMUNIX
  # Although this is actually unclean, we fetch the current
  # screen-size with _scrsize().
  {
    var int scrsize[2];
    _scrsize(&!scrsize);
    if (scrsize[0] > 0)
      cols = scrsize[0];
    if (scrsize[1] > 0)
      rows = scrsize[1];
  }
 #endif
  if (tgetflag("hc")) {
    end_system_call();
    return GETTEXT("insufficient terminal: hardcopy terminal");
  }
  if (tgetflag("os")) {
    end_system_call();
    return GETTEXT("insufficient terminal: overstrikes, cannot clear output");
  }
  if (tgetflag("ns")) {
    end_system_call();
    return GETTEXT("insufficient terminal: cannot scroll");
  }
  if (!(CLcap = tgetstr("cl",&tp))) {
    # Could use CLcap = "\n\n\n\n"; as Default ('weird HPs')
    end_system_call();
    return GETTEXT("insufficient terminal: cannot clear screen");
  }
  if (!(CMcap = tgetstr("cm",&tp))) {
    end_system_call();
    return GETTEXT("insufficient terminal: cannot position cursor randomly");
  }
  # initialize Capabilities:
  AM = tgetflag("am"); if (tgetflag("LP")) AM = false;
  TIcap = tgetstr("ti",&tp);
  TEcap = tgetstr("te",&tp);
  # BLcap = tgetstr("bl",&tp); if (!BLcap) BLcap = "\007";
  # VBcap = tgetstr("vb",&tp);
  BCcap = tgetstr("bc",&tp); if (!BCcap) BCcap = (tgetflag("bs") ? "\b" : tgetstr("le",&tp));
  CRcap = tgetstr("cr",&tp); if (!CRcap) CRcap = "\r";
  NLcap = tgetstr("nl",&tp); if (!NLcap) NLcap = "\n";
  DOcap = tgetstr("do",&tp); if (!DOcap) DOcap = NLcap;
  UPcap = tgetstr("up",&tp);
  NDcap = tgetstr("nd",&tp);
  IScap = tgetstr("is",&tp);
 #if WANT_ATTR
  if ((tgetnum("sg") > 0) || (tgetnum("ug") > 0)) {
    # switching to Standout-Mode or switching to
    # Underline-Mode yields blankspace -> unusable!
    SOcap = NULL; SEcap = NULL; UScap = NULL; UEcap = NULL;
    MBcap = NULL; MDcap = NULL; MHcap = NULL; MRcap = NULL; MEcap = NULL;
  } else {
    SOcap = tgetstr("so",&tp);
    SEcap = tgetstr("se",&tp);
    UScap = tgetstr("us",&tp);
    UEcap = tgetstr("ue",&tp);
    if (!UScap && !UEcap) { # no Underline?
      UScap = SOcap; UEcap = SEcap; # use Standout as replacement
    }
    MBcap = tgetstr("mb",&tp);
    MDcap = tgetstr("md",&tp);
    MHcap = tgetstr("mh",&tp);
    MRcap = tgetstr("mr",&tp);
    MEcap = tgetstr("me",&tp);
    # Does ME also reverse the effect of SO and/or US?  This is not
    # clearly specified by the termcap manual.
    # Anyway, we should at least look whether ME/SE/UE are equal:
    if (UEcap && SEcap && asciz_equal(UEcap,SEcap)) UEcap = NULL;
    if (UEcap && MEcap && asciz_equal(UEcap,MEcap)) UEcap = NULL;
    if (SEcap && MEcap && asciz_equal(SEcap,MEcap)) SEcap = NULL;
    # tgetstr("uc",&tp) returns an underline-character. Then execute
    # backspace() and out_capstring(UCcap) at a time in redisplay_help()
    # and output_1char() after out_char().
    # For which Terminals is this worthwhile??
  }
 #endif
 #if WANT_CHARSET
  ISO2022 = tgetflag("G0");
 #endif
  CScap = tgetstr("cs",&tp);
 #if WANT_DELETE_LINE
  SFcap = tgetstr("sf",&tp); if (!SFcap) SFcap = NLcap;
 #endif
 #if WANT_CURSOR_REVLINEFEED || WANT_INSERT_LINE
  SRcap = tgetstr("sr",&tp);
 #endif
 #if WANT_CLEAR_FROM_BOS || WANT_CLEAR_TO_EOS || WANT_CLEAR_LINE || WANT_CLEAR_FROM_BOL || WANT_CLEAR_TO_EOL
  CEcap = tgetstr("ce",&tp);
 #endif
 #if WANT_CLEAR_TO_EOS
  CDcap = tgetstr("cd",&tp);
 #endif
 #if WANT_CURSOR_REVLINEFEED || WANT_INSERT_LINE
  ALcap = tgetstr("al",&tp);
 #endif
 #if WANT_DELETE_LINE
  DLcap = tgetstr("dl",&tp);
 #endif
 #if WANT_DELETE_CHAR
  DCcap = tgetstr("dc",&tp);
 #endif
 #if WANT_INSERT_1CHAR || WANT_INSERT_CHAR
  ICcap = tgetstr("ic",&tp);
 #endif
 #if WANT_INSERT_CHAR
  CICcap = tgetstr("IC",&tp);
 #endif
 #if WANT_INSERT_LINE
  CALcap = tgetstr("AL",&tp);
 #endif
 #if WANT_DELETE_CHAR
  CDCcap = tgetstr("DC",&tp);
 #endif
 #if WANT_DELETE_LINE
  CDLcap = tgetstr("DL",&tp);
 #endif
  IMcap = tgetstr("im",&tp);
  EIcap = tgetstr("ei",&tp);
  if (tgetflag ("in")) { # Insert-Mode unusable?
    IMcap = NULL; EIcap = NULL;
   #if WANT_INSERT_1CHAR || WANT_INSERT_CHAR
    ICcap = NULL;
   #endif
   #if WANT_INSERT_CHAR
    CICcap = NULL;
   #endif
  }
  if (IMcap && (IMcap[0]==0)) IMcap = NULL; # IMcap empty?
  if (EIcap && (EIcap[0]==0)) EIcap = NULL; # EIcap empty?
 #if WANT_INSERT_1CHAR || WANT_INSERT_CHAR
  if (ICcap && (ICcap[0]==0)) ICcap = NULL; # ICcap empty?
 #endif
  # calculate the costs of the Capabilities:
  IMcost = cap_cost(IMcap);
  EIcost = cap_cost(EIcap);
  BCcost = cap_cost(BCcap);
  NDcost = cap_cost(NDcap);
  DOcost = cap_cost(DOcap);
 #ifndef NL_HACK
  # If DOcap writes a LF, it is not sure, if this arrives
  # at the Terminal as such (and not as CR/LF). In this case we
  # declare DOcap as unusable. This spares us the NL_HACK.
  if (DOcap[0]=='\n')
    DOcost = EXPENSIVE;
 #endif
  UPcost = cap_cost(UPcap);
  CRcost = cap_cost(CRcap);
  # provide Auxiliary-Data-Structures:
  blank = (uintB*) malloc(cols*sizeof(uintB));
   memset(blank,' ',cols);
#if WANT_ATTR || WANT_CHARSET
  {
    var uintB* ptr = (uintB*) malloc(cols*sizeof(uintB));
    null = ptr;
    memset(ptr,0,cols);
  }
 #endif
 #if WANT_INSERT_1CHAR || WANT_INSERT_CHAR || WANT_DELETE_CHAR
  old_image_y = (uintB*) malloc(cols*sizeof(uintB));
 #if WANT_ATTR
  old_attr_y = (uintB*) malloc(cols*sizeof(uintB));
 #endif
 #if WANT_CHARSET
  old_font_y = (uintB*) malloc(cols*sizeof(uintB));
 #endif
 #endif
  end_system_call();
  term_initialized = true;
  return NULL;
}


#ifdef NL_HACK

# If NLcap = "\n" , we must execute an "stty -onlcr", because otherwise
# the NL is converted to CR by the Terminal-Driver, before it
# arrives at the Terminal.
  local void term_nlraw (void);
  local void term_nlunraw (void);
#if defined(UNIX_TERM_TERMIOS)
  static unsigned long old_c_oflag = 0;
local void term_nlraw() {
  var struct termios oldtermio;
  if (!( tcgetattr(stdout_handle,&oldtermio) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
  old_c_oflag = oldtermio.c_oflag;
  oldtermio.c_oflag &= ~ONLCR;
  if (!( TCSETATTR(stdout_handle,TCSAFLUSH,&oldtermio) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
}
local void term_nlunraw() {
  if (old_c_oflag & ONLCR) {
    var struct termios oldtermio;
    if (!( tcgetattr(stdout_handle,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
    oldtermio.c_oflag |= ONLCR;
    if (!( TCSETATTR(stdout_handle,TCSAFLUSH,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
}
#elif defined(UNIX_TERM_TERMIO) || defined(EMUNIX)
  static unsigned long old_c_oflag = 0;
local void term_nlraw() {
  var struct termio oldtermio;
  if (!( ioctl(stdout_handle,TCGETA,&oldtermio) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
  old_c_oflag = oldtermio.c_oflag;
  oldtermio.c_oflag &= ~ONLCR;
  if (!( ioctl(stdout_handle,TCSETAF,&oldtermio) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
}
local void term_nlunraw() {
  if (old_c_oflag & ONLCR) {
    var struct termio oldtermio;
    if (!( ioctl(stdout_handle,TCGETA,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
    oldtermio.c_oflag |= ONLCR;
    if (!( ioctl(stdout_handle,TCSETAF,&oldtermio) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
}
#elif defined(UNIX_TERM_SGTTY)
  static unsigned long old_sg_flags = 0;
local void term_nlraw() {
  var struct sgttyb oldsgttyb;
  if (!( ioctl(stdout_handle,TIOCGETP,&oldsgttyb) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
  old_sg_flags = oldsgttyb.sg_flags;
  oldsgttyb.sg_flags &= ~CRMOD;
  if (!( ioctl(stdout_handle,TIOCSETP,&oldsgttyb) ==0)) {
    if (!(errno==ENOTTY)) { OS_error(); }
  }
}
local void term_nlunraw() {
  if (old_sg_flags & CRMOD) {
    var struct sgttyb oldsgttyb;
    if (!( ioctl(stdout_handle,TIOCGETP,&oldsgttyb) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
    oldsgttyb.sg_flags |= CRMOD;
    if (!( ioctl(stdout_handle,TIOCSETP,&oldsgttyb) ==0)) {
      if (!(errno==ENOTTY)) { OS_error(); }
    }
  }
}
#endif

#endif # NL_HACK

# Begin of Processing this Packet:
local void start_term (void) {
 #ifdef NL_HACK
  if (NLcap[0] == '\n')
    term_nlraw();
 #endif
  out_capstring (IScap);
  out_capstring (TIcap);
}

# End of Processing this Packet:
local void end_term (void) {
  out_capstring (TEcap);
  out_capstring (IScap);
 #ifdef MSDOS # how to test for Color-ANSI-Terminal??
  # On ANSI-Terminals with several colors: TEcap resets the colors.
  out_capstring(CLcap); # delete screen, this time with the normal color
 #endif
 #ifdef NL_HACK
  if (NLcap[0] == '\n')
    term_nlunraw();
 #endif
}

# Initializes the Window curr.
local void init_curr (void) {
  {
    var uintB** ptr = (uintB**) malloc(rows*sizeof(uintB*));
    var uintC count;
    curr->image = ptr;
    dotimespC(count,rows, { *ptr++ = (uintB*) malloc(cols*sizeof(uintB)); } );
  }
 #if WANT_ATTR
  {
    var uintB** ptr = (uintB**) malloc(rows*sizeof(uintB*));
    var uintC count;
    curr->attr = ptr;
    dotimespC(count,rows, { *ptr++ = (uintB*) malloc(cols*sizeof(uintB)); } );
  }
  # deactivate Attribute:
  out_capstring(UEcap); # all deactivated
  out_capstring(SEcap);
  out_capstring(MEcap);
  term_attr = curr->curr_attr = 0;
 #endif
 #if WANT_CHARSET
  {
    var uintB** ptr = (uintB**) malloc(rows*sizeof(uintB*));
    var uintC count;
    curr->font = ptr;
    dotimespC(count,rows, { *ptr++ = (uintB*) malloc(cols*sizeof(uintB)); } );
  }
  {
    var uintC i = 0;
    while (i<charset_count) { curr->charsets[i] = ASCII; i++; }
  }
  curr->curr_charset = 0;
  if (ISO2022) {
    out_char(ESC); out_char('('); out_char('B'); /*)*/
  }
  term_charset = ASCII;
 #endif
  curr->x = 0; curr->y = 0;
  curr->top = 0; curr->bot = rows-1;
 #if WANT_INSERT
  curr->insert = false;
 #endif
 #if WANT_SAVE
  curr->saved = false;
 #endif
  if (CScap)
    out_capstring(tgoto(CScap,curr->bot,curr->top));
  clear_screen();
}

# -----------------------------------------------------------------------------

# UP: Write character to a Window-Stream.
# wr_ch_window(&stream,ch);
# > stream: Window-Stream
# > ch: character to be written
local void wr_ch_window (const object* stream_, object ch) {
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(*stream_,ch);
  var uintB c = as_cint(char_code(ch)); # FIXME: This should take into account the encoding.
  begin_system_call();
  if (graphic_char_p(as_chart(c))) {
    if (curr->x == cols) {
      cursor_return(); cursor_linefeed(); # Wrap!
    }
    output_1char(c);
  } else if (c == NL) {
    cursor_return(); cursor_linefeed();
  } else if (c == BS) {
    var int x0 = curr->x;
    if (x0>0) {
      var int y0 = curr->y;
      clear_linepart(y0,x0-1,x0);
      gofromto(curr->y,curr->x,y0,x0-1); curr->y = y0; curr->x = x0-1;
    }
  }
  end_system_call();
}

LISPFUNN(make_window,0) {
  var object stream = # Flags: only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_window,strm_len+1,0);
  # and fill:
  stream_dummy_fill(stream);
  var Stream s = TheStream(stream);
  s->strm_wr_ch = P(wr_ch_window); # WRITE-CHAR-Pseudofunction
  s->strm_wr_ch_array = P(wr_ch_array_dummy); # WRITE-CHAR-SEQUENCE-Pseudofunction
  # Initialize:
  begin_system_call();
  {
    var const char * result = init_term();
    if (!(result==NULL))
      fehler(error,result);
  }
  start_term();
  init_curr();
  end_system_call();
  VALUES1(stream);
}

# Closes a Window-Stream.
local void close_window (object stream) {
  begin_system_call();
  end_term();
  end_system_call();
}

LISPFUNN(window_size,1) {
  check_window_stream(popSTACK());
  VALUES2(fixnum(rows), # query Variables rows,cols
          fixnum(cols));
}

LISPFUNN(window_cursor_position,1) {
  check_window_stream(popSTACK());
  VALUES2(fixnum(curr->y),
          fixnum(curr->x));
}

LISPFUNN(set_window_cursor_position,3) {
  check_window_stream(STACK_2);
  var uintL line = posfixnum_to_L(STACK_1);
  var uintL column = posfixnum_to_L(STACK_0);
  if ((line < rows) && (column < cols)) {
    begin_system_call();
    gofromto(curr->y,curr->x,line,column); # position Cursor
    curr->y = line; curr->x = column;
    end_system_call();
  }
  VALUES2(STACK_1, STACK_0); skipSTACK(3);
}

LISPFUNN(clear_window,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  clear_screen();
  end_system_call();
  VALUES0;
}

LISPFUNN(clear_window_to_eot,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  clear_to_EOS();
  end_system_call();
  VALUES0;
}

LISPFUNN(clear_window_to_eol,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  clear_to_EOL();
  end_system_call();
  VALUES0;
}

LISPFUNN(delete_window_line,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  delete_line(1);
  end_system_call();
  VALUES0;
}

LISPFUNN(insert_window_line,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  insert_line(1);
  end_system_call();
  VALUES0;
}

LISPFUNN(highlight_on,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  change_attr(curr->curr_attr |= A_US);
  end_system_call();
  VALUES0;
}

LISPFUNN(highlight_off,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  change_attr(curr->curr_attr &= ~A_US);
  end_system_call();
  VALUES0;
}

LISPFUNN(window_cursor_on,1) {
  check_window_stream(popSTACK());
  # Cursor is permanently activated!
  VALUES0;
}

LISPFUNN(window_cursor_off,1) {
  check_window_stream(popSTACK());
  # not possible, because Cursor is activated permanently!
  VALUES0;
}

#endif # (UNIX && !NEXTAPP) || RISCOS

#if defined(MAYBE_NEXTAPP) && defined(NEXTAPP)

# Everything unimplemented.

# error-message.
nonreturning_function(local, fehler_screen, (void)) {
  pushSTACK(TheSubr(subr_self)->name);
  fehler(error,GETTEXT("~: package SCREEN is not implemented"));
}

LISPFUNN(make_window,0) {
  fehler_screen();
}

#define close_window(stream)  fehler_screen()

LISPFUNN(window_size,1) {
  fehler_screen();
}

LISPFUNN(window_cursor_position,1) {
  fehler_screen();
}

LISPFUNN(set_window_cursor_position,3) {
  fehler_screen();
}

LISPFUNN(clear_window,1) {
  fehler_screen();
}

LISPFUNN(clear_window_to_eot,1) {
  fehler_screen();
}

LISPFUNN(clear_window_to_eol,1) {
  fehler_screen();
}

LISPFUNN(delete_window_line,1) {
  fehler_screen();
}

LISPFUNN(insert_window_line,1) {
  fehler_screen();
}

LISPFUNN(highlight_on,1) {
  fehler_screen();
}

LISPFUNN(highlight_off,1) {
  fehler_screen();
}

LISPFUNN(window_cursor_on,1) {
  fehler_screen();
}

LISPFUNN(window_cursor_off,1) {
  fehler_screen();
}

#endif # NEXTAPP

#if defined(UNIX) && 0

# Normal CURSES-Package, we use only stdscr.

#undef BS
#undef CR
#undef NL
#include <curses.h>
#undef OK
#define CR  13
#define NL  10

# UP: Write character to Window-Stream.
# wr_ch_window(&stream,ch);
# > stream: Window-Stream
# > ch: character to be written
local void wr_ch_window (const object* stream_, object ch) {
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(*stream_,ch);
  var uintB c = as_cint(char_code(ch)); # FIXME: This should take into account the encoding.
  begin_system_call();
  if (graphic_char_p(as_chart(c))) { # let only printable characters pass to the screen
    addch(c);
  } else if (c == NL) { # convert NL to CR/LF
    addch(CR); addch(LF);
  } else { # write something, for the Cursor-Position to be correct
    addch('?');
  }
  end_system_call();
}

LISPFUNN(make_window,0) {
  var object stream = # Flags: only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_window,strm_len+1,0);
  # and fill:
  stream_dummy_fill(stream);
  var Stream s = TheStream(stream);
  s->strm_wr_ch = P(wr_ch_window); # WRITE-CHAR-Pseudofunction
  s->strm_wr_ch_array = P(wr_ch_array_dummy); # WRITE-CHAR-SEQUENCE-Pseudofunction
  begin_system_call();
  initscr(); # initialize Curses # What, if this crashes?? use newterm()??
  cbreak(); noecho(); # Input not line-buffered, without Echo
 #if defined(SUN3) || defined(SUN4)
  keypad(stdscr,true); # activate Function-Key-Detection
 #endif
  end_system_call();
  VALUES1(stream);
}

# Closes a Window-Stream.
local void close_window (object stream) {
  begin_system_call();
  nocbreak(); echo(); # Input is line-buffered again, with Echo
 #if defined(SUN3) || defined(SUN4)
  keypad(stdscr,false); # deactivate Function-Key-Detection again
 #endif
  endwin(); # deactivate Curses
  end_system_call();
}

LISPFUNN(window_size,1) {
  check_window_stream(popSTACK());
  VALUES2(fixnum(LINES), /* query Curses-Variables LINES, COLS */
          fixnum(COLS));
}

LISPFUNN(window_cursor_position,1) {
  check_window_stream(popSTACK());
  var int y;
  var int x;
  begin_system_call();
  getyx(stdscr,y,x); # (y,x) := cursor position
  end_system_call();
  VALUES2(fixnum(y),
          fixnum(x));
}

LISPFUNN(set_window_cursor_position,3) {
  check_window_stream(STACK_2);
  var uintL line = posfixnum_to_L(STACK_1);
  var uintL column = posfixnum_to_L(STACK_0);
  if ((line < LINES) && (column < COLS)) {
    begin_system_call();
    move(line,column); refresh(); # position Cursor
    end_system_call();
  }
  VALUES2(STACK_1, STACK_0); skipSTACK(3);
}

LISPFUNN(clear_window,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  clear(); refresh();
  end_system_call();
  VALUES0;
}

LISPFUNN(clear_window_to_eot,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  clrtobot(); refresh();
  end_system_call();
  VALUES0;
}

LISPFUNN(clear_window_to_eol,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  clrtoeol(); refresh();
  end_system_call();
  VALUES0;
}

LISPFUNN(delete_window_line,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  deleteln(); refresh();
  end_system_call();
  VALUES0;
}

LISPFUNN(insert_window_line,1) {
  check_window_stream(popSTACK());
  begin_system_call();
  insertln(); refresh();
  end_system_call();
  VALUES0;
}

LISPFUNN(highlight_on,1) {
  check_window_stream(popSTACK());
#ifdef A_STANDOUT # only works, if Curses manages the Attributes
  begin_system_call();
  attron(A_STANDOUT); # add Attribut A_STANDOUT with OR at addch()
  end_system_call();
#endif
  VALUES0;
}

LISPFUNN(highlight_off,1) {
  check_window_stream(popSTACK());
 #ifdef A_STANDOUT # only works, if Curses manages the Attributes
  begin_system_call();
  attroff(A_STANDOUT); # don't add Attribute with OR at addch()
  end_system_call();
 #endif
  VALUES0;
}

LISPFUNN(window_cursor_on,1) {
  check_window_stream(popSTACK());
  # Cursor is permanently activated!
  VALUES0;
}

LISPFUNN(window_cursor_off,1) {
  check_window_stream(popSTACK());
  # not possible, because Cursor is activated permanently!
  VALUES0;
}

#endif # UNIX

#ifdef AMIGAOS

# Terminal-Emulation: ANSI-Control-Characters, see console.doc

# UP: Output of several characters on the screen
local void wr_window (const uintB* outbuffer, uintL count) {
  set_break_sem_1();
  begin_system_call();
  var long result = Write(stdout_handle,outbuffer,count);
  end_system_call();
  if (result<0) { OS_error(); }
  if (result<count) # not successful?
    { ?? }
  clr_break_sem_1();
}

#define WR_WINDOW(characters)  \
  { local var uintB outbuffer[] = characters; \
     wr_window(&outbuffer,sizeof(outbuffer)); \
  }

# UP: Write a character to a Window-Stream.
# wr_ch_window(&stream,ch);
# > stream: Window-Stream
# > ch: character to be written
local void wr_ch_window (const object* stream_, object ch) {
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(*stream_,ch);
  var uintB c = as_cint(char_code(ch)); # FIXME: This should take into account the encoding.
  ??
}

LISPFUNN(make_window,0) {
  finish_output_terminal(var_stream(S(terminal_io),strmflags_wr_ch_B)); # write poss. pending NL now
  var object stream = # Flags: only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_window,strm_len+0,0);
  # and fill:
  stream_dummy_fill(stream);
  var Stream s = TheStream(stream);
  s->strm_wr_ch = P(wr_ch_window); # WRITE-CHAR-Pseudofunction
  s->strm_wr_ch_array = P(wr_ch_array_dummy); # WRITE-CHAR-SEQUENCE-Pseudofunction
  # size: aWSR? aWBR??
  # Wrap off ?? ASM? AWM?
  WR_WINDOW({CSI,'0',0x6D}); # Set Graphics Rendition Normal
  VALUES1(stream);
}

# Closes a Window-Stream.
local void close_window (object stream) {
  # Wrap on ?? ASM? AWM?
  WR_WINDOW({CSI,'0',0x6D}); # Set Graphics Rendition Normal
}

LISPFUNN(window_size,1) {
  check_window_stream(popSTACK());
  value1 = fixnum(window_size.y); ??
    value2 = fixnum(window_size.x); ??
      mv_count=2;
}

LISPFUNN(window_cursor_position,1) {
  check_window_stream(popSTACK());
  # aWSR? CPR??
  value1 = fixnum(_y); ??
    value2 = fixnum(_x); ??
      mv_count=2;
}

LISPFUNN(set_window_cursor_position,3) {
  check_window_stream(STACK_2);
  var uintL line = posfixnum_to_L(STACK_1);
  var uintL column = posfixnum_to_L(STACK_0);
  if ((line < (uintL)window_size.y) && (column < (uintL)window_size.x)) {
    var uintB outbuffer[23]; # Buffer for  CSI <line> ; <column> H
    var uintB* ptr = &outbuffer[sizeof(outbuffer)];
    var uintL count = 0;
    count++; *--ptr = 'H';
    do {
      count++; *--ptr = '0'+(column%10); column = floor(column,10);
    } until (column==0);
    count++; *--ptr = ';';
    do {
      count++; *--ptr = '0'+(line%10); line = floor(line,10);
    } until (line==0);
    count++; *--ptr = CSI;
    wr_window(ptr,count);
  }
  VALUES2(STACK_1, STACK_0); skipSTACK(3);
}

LISPFUNN(clear_window,1) {
  check_window_stream(popSTACK());
  WR_WINDOW({CSI,'0',';','0','H',CSI,'J'});
  VALUES0;
}

LISPFUNN(clear_window_to_eot,1) {
  check_window_stream(popSTACK());
  WR_WINDOW({CSI,'J'});
  VALUES0;
}

LISPFUNN(clear_window_to_eol,1) {
  check_window_stream(popSTACK());
  WR_WINDOW({CSI,'K'});
  VALUES0;
}

LISPFUNN(delete_window_line,1) {
  check_window_stream(popSTACK());
  WR_WINDOW({CSI,'M'});
  VALUES0;
}

LISPFUNN(insert_window_line,1) {
  check_window_stream(popSTACK());
  WR_WINDOW({CSI,'L'});
  VALUES0;
}

LISPFUNN(highlight_on,1) {
  check_window_stream(popSTACK());
  WR_WINDOW({CSI,'1',0x6D}); # Set Graphics Rendition Bold
  VALUES0;
}

LISPFUNN(highlight_off,1) {
  check_window_stream(popSTACK());
  WR_WINDOW({CSI,'0',0x6D}); # Set Graphics Rendition Normal
  VALUES0;
}

LISPFUNN(window_cursor_on,1) {
  check_window_stream(popSTACK());
  # aSCR ??
  VALUES0;
}

LISPFUNN(window_cursor_off,1) {
  check_window_stream(popSTACK());
  # aSCR ??
  VALUES0;
}

#endif # AMIGAOS

#endif # SCREEN


#ifdef PRINTER_AMIGAOS

# Printer-Stream
# ==============

# Additional Components:
  #define strm_printer_handle  strm_other[0]  # Handle of "PRT:"

# FIXME: Should be based on an encoding.

# WRITE-CHAR - Pseudo-Function for Printer-Streams:
local void wr_ch_printer (const object* stream_, object ch) {
  var object stream = *stream_;
  if (!charp(ch)) # ch must be a character
    fehler_wr_char(stream,ch);
  begin_system_call();
  var uintB c = as_cint(char_code(ch)); # FIXME: This should take into account the encoding.
  var long result = # try to write character
    Write(TheHandle(TheStream(stream)->strm_printer_handle),&c,1L);
  end_system_call();
  if (result<0) { OS_error(); }
  # result = number of written characters (0 or 1)
  if (result==0) # not successful?
    fehler_unwritable(S(write_char),stream);
}

# close a printer-stream.
local void close_printer (object stream) {
  begin_system_call();
  Close(TheHandle(TheStream(stream)->strm_printer_handle));
  end_system_call();
}

# UP: Returns a Printer-Stream.
# can trigger GC
local object make_printer_stream (void) {
  pushSTACK(allocate_handle(Handle_NULL)); # Handle-Wrapping
  var object stream = # new Stream, only WRITE-CHAR allowed
    allocate_stream(strmflags_wr_ch_B,strmtype_printer,strm_len+1,0);
  set_break_sem_4();
  begin_system_call();
  {
    var Handle handle = Open("PRT:",MODE_NEWFILE);
    if (handle==Handle_NULL) { OS_error(); }
    end_system_call();
    TheHandle(STACK_0) = handle; # wrap Handle
  }
  stream_dummy_fill(stream);
  TheStream(stream)->strm_wr_ch = P(wr_ch_printer);
  TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_dummy);
  TheStream(stream)->strm_printer_handle = popSTACK();
  # extend List of open Streams by stream:
  stream = add_to_open_streams(stream);
  clr_break_sem_4();
  return stream;
}

# (SYSTEM::MAKE-PRINTER-STREAM) returns a Printer-Stream.
# For the Escape-Sequences that are understood see PRINTER.DOC.
LISPFUNN(make_printer_stream,0) {
  VALUES1(make_printer_stream()); return;
}

#endif # PRINTER_AMIGAOS


#ifdef PIPES

# Pipe-Input-Stream, Pipe-Output-Stream
# =====================================

# Additional Components:
  # define strm_pipe_pid  strm_field1   # Process-Id, a Fixnum >=0
#if defined(EMUNIX) && defined(PIPES2)
  #define strm_pipe_other strm_field2   # Pipe-Stream in opposite direction
#endif

#ifdef EMUNIX
local void low_close_pipe (object stream, object handlobj) {
  var Handle handle = TheHandle(handlobj);
 #ifdef PIPES2
  if (builtin_stream_p(TheStream(stream)->strm_pipe_other)) {
    # The other Pipe-Stream is still open. We must not call
    # pclose(), because it executes waitpid().
    TheStream(TheStream(stream)->strm_pipe_other)->strm_pipe_other = NIL;
    TheStream(stream)->strm_pipe_other = NIL;
    begin_system_call();
    if ( fclose(&_streamv[handle]) != 0) { OS_error(); }
    end_system_call();
    # The pipes are now separated. On closing the other
    # pipe, pclose() will be executed.
    return;
  }
 #endif
  begin_system_call();
  if ( pclose(&_streamv[handle]) == -1) { OS_error(); }
  end_system_call();
}
#endif
#if defined(UNIX) || defined(WIN32_NATIVE)
  #define low_close_pipe  low_close_handle
#endif

#if defined(HAVE_SIGNALS) && defined(SIGPIPE)

# Be careful to disable SIGPIPE during write() to a subprocess.

local void low_flush_buffered_pipe (object stream, uintL bufflen) {
  begin_system_call();
  writing_to_subprocess = true;
  var sintL result = # flush Buffer
    full_write(TheHandle(BufferedStream_channel(stream)),
               BufferedStream_buffer_address(stream,0),
               bufflen);
  writing_to_subprocess = false;
  if (result == bufflen) { # everything was written correctly
    end_system_call(); BufferedStream_modified(stream) = false;
  } else { # not everything was written
    if (result<0) { # Error?
      end_system_call(); OS_filestream_error(stream);
    }
    end_system_call();
    fehler_unwritable(TheSubr(subr_self)->name,stream);
  }
}

#else

  #define low_flush_buffered_pipe  low_flush_buffered_handle

#endif

#define BufferedPipeStream_init(stream)  \
  { BufferedStreamLow_fill(stream) = &low_fill_buffered_handle; \
    BufferedStreamLow_flush(stream) = &low_flush_buffered_pipe; \
  }

# Pipe-Input-Stream
# =================

# Low-level.

  #define UnbufferedPipeStream_input_init(stream)  UnbufferedHandleStream_input_init(stream)

local inline void create_input_pipe (const char* command) {
  var int child;
 #ifdef EMUNIX
  var int handles[2];
  {
    begin_system_call();
    var FILE* f = popen(command,"r");
    if (f==NULL) { OS_error(); }
    child = f->_pid;
    handles[0] = fileno(f);
    end_system_call();
  }
 #endif
 #ifdef UNIX
  var int handles[2]; # two Handles for the pipe
  {
    # As shell we always use the Command-Shell.
    # copy command to Stack:
    var uintL command_length = asciz_length(command)+1;
    var DYNAMIC_ARRAY(command_data,char,command_length);
    begin_system_call();
    memcpy(command_data,command,command_length);
    # build pipe:
    if (!( pipe(handles) ==0)) {
      FREE_DYNAMIC_ARRAY(command_data); OS_error();
    }
    # Everything, that is stuffed in handles[1], resurfaces at handles[0]
    # again. We will utilize this as follows:
    #       write            system            read
    # child  ->   handles[1]   ->   handles[0]  ->  parent
    # start a new process:
    if ((child = vfork()) ==0) {
      # this piece of code is executed by the child-process:
      if ( dup2(handles[1],stdout_handle) >=0) # redirect standard-output
        if ( CLOSE(handles[1]) ==0) # we want to write only via stdout_handle
          if ( CLOSE(handles[0]) ==0) { # we do not want to read from the pipe
            # (I have to tell this the operating system. Then - if the Child
            # has filled the pipe - the parent-process is called
            # in order to empty the pipe (and not the child-process).)
            # turn child-process into a background process:
            SETSID(); # it receives its own process group
            execl(SHELL,            # call shell
                  SHELL,            # =: argv[0]
                  "-c",             # =: argv[1]
                  &command_data[0], # =: argv[2]
                  NULL);
          }
      _exit(-1); # if this fails, finish child-process
    }
    # This piece of code is again executed by the caller:
    if (child==-1)
      # Something failed, either on vfork or on execl.
      # In both cases errno was set.
      OS_error_saving_errno({
        CLOSE(handles[1]); CLOSE(handles[0]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # We only want to read from the pipe, not write:
    if (!( CLOSE(handles[1]) ==0))
      OS_error_saving_errno({
        CLOSE(handles[0]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # (I have to tell this the operating system. Then - if the parent-process
    # has emptied the pipe - the child-process is called in order to fill the
    # pipe again (and not the parent-process).)
    end_system_call();
    FREE_DYNAMIC_ARRAY(command_data);
  }
 #endif
 #ifdef WIN32_NATIVE
  var Handle handles[2]; # two Handles for the pipe
  {
    begin_system_call();
    var Handle child_write_handle;
    # Create a pipe and make one of the two handles inheritable.
    if (!CreatePipe(&handles[0],&handles[1],NULL,0)) { OS_error(); }
    if (!DuplicateHandle(GetCurrentProcess(),handles[1],
                         GetCurrentProcess(),&child_write_handle,
                         0, true, DUPLICATE_SAME_ACCESS)) {
      OS_error();
    }
    if (!CloseHandle(handles[1])) { OS_error(); }
    var HANDLE stdinput;
    var PROCESS_INFORMATION pinfo;
    stdinput = GetStdHandle(STD_INPUT_HANDLE);
    if (stdinput == INVALID_HANDLE_VALUE) { OS_error(); }
    if (!MyCreateProcess(command,stdinput,child_write_handle,&pinfo)) {
      OS_error();
    }
    # Close our copy of the child's handle, so that the OS knows
    # that we won't write on it.
    if (!CloseHandle(child_write_handle)) { OS_error(); }
    if (!CloseHandle(pinfo.hThread)) { OS_error(); }
    if (!CloseHandle(pinfo.hProcess)) { OS_error(); }
    child = pinfo.dwProcessId;
    end_system_call();
  }
 #endif
  pushSTACK(UL_to_I(child));
  pushSTACK(STACK_(1+1));
  pushSTACK(STACK_(2+2));
  pushSTACK(allocate_handle(handles[0]));
}

# (MAKE-PIPE-INPUT-STREAM command [:element-type] [:external-format] [:buffered])
# calls a shell, that executes command, whereby its Standard-Output
# is directed into our pipe.
LISPFUN(make_pipe_input_stream,1,0,norest,key,3,
        (kw(element_type),kw(external_format),kw(buffered)) ) {
  var decoded_el_t eltype;
  var signean buffered;
  # check command:
  pushSTACK(STACK_3); funcall(L(string),1); # (STRING command)
  STACK_3 = value1;
  # Check and canonicalize the :BUFFERED argument:
  buffered = test_buffered_arg(STACK_0); # default is NIL
  # Check and canonicalize the :ELEMENT-TYPE argument:
  test_eltype_arg(&STACK_2,&eltype);
  STACK_2 = canon_eltype(&eltype);
  if (buffered <= 0) { check_unbuffered_eltype(&eltype); }
  # Check and canonicalize the :EXTERNAL-FORMAT argument:
  STACK_1 = test_external_format_arg(STACK_1);
  # Now create the pipe.
  with_string_0(STACK_3,O(misc_encoding),command_asciz, {
    create_input_pipe(command_asciz);
  });
  # allocate Stream:
  var object stream;
  if (!eq(STACK_(0+4),T)) { # (buffered <= 0) ?
    stream = make_unbuffered_stream(strmtype_pipe_in,DIRECTION_INPUT,
                                    &eltype,false);
    UnbufferedPipeStream_input_init(stream);
  } else {
    stream = make_buffered_stream(strmtype_pipe_in,DIRECTION_INPUT,
                                  &eltype,false,false);
    BufferedPipeStream_init(stream);
  }
  ChannelStreamLow_close(stream) = &low_close_pipe;
  TheStream(stream)->strm_pipe_pid = popSTACK(); # Child-Pid
  skipSTACK(4);
  VALUES1(add_to_open_streams(stream)); /* return stream */
}


# Pipe-Output-Stream
# ==================

# Low-level.

#if defined(HAVE_SIGNALS) && defined(SIGPIPE)

  # Be careful to disable SIGPIPE during write() to a subprocess.

local void low_write_unbuffered_pipe (object stream, uintB b) {
  var Handle handle = TheHandle(TheStream(stream)->strm_ochannel);
 restart_it:
  begin_system_call();
  # Try to output the byte.
  writing_to_subprocess = true;
  var int result = write(handle,&b,1);
  writing_to_subprocess = false;
  if (result<0) {
    if (errno==EINTR) { # Break (poss. by Ctrl-C) ?
      end_system_call();
      interruptp({ fehler_interrupt(); });
      goto restart_it;
    }
    OS_error();
  }
  end_system_call();
  if (result==0) # not successful?
    fehler_unwritable(TheSubr(subr_self)->name,stream);
}

local const uintB* low_write_array_unbuffered_pipe (object stream, const uintB* byteptr, uintL len) {
  var Handle handle = TheHandle(TheStream(stream)->strm_ochannel);
  begin_system_call();
  writing_to_subprocess = true;
  var sintL result = full_write(handle,byteptr,len);
  writing_to_subprocess = false;
  if (result<0) { OS_error(); }
  end_system_call();
  if (!(result==(sintL)len)) # not successful?
    fehler_unwritable(TheSubr(subr_self)->name,stream);
  return byteptr+result;
}

#else

  #define low_write_unbuffered_pipe  low_write_unbuffered_handle
  #define low_write_array_unbuffered_pipe  low_write_array_unbuffered_handle

#endif

local void low_finish_output_unbuffered_pipe (object stream) {}; # do nothing
local void low_force_output_unbuffered_pipe (object stream) {}; # do nothing
local void low_clear_output_unbuffered_pipe (object stream) {}; # do nothing

#define UnbufferedPipeStream_output_init(stream)                        \
  { UnbufferedStreamLow_write(stream) = &low_write_unbuffered_pipe;     \
    UnbufferedStreamLow_write_array(stream) =                           \
      &low_write_array_unbuffered_pipe;                                 \
    UnbufferedStreamLow_finish_output(stream) =                         \
      &low_finish_output_unbuffered_pipe;                               \
    UnbufferedStreamLow_force_output(stream) =                          \
      &low_force_output_unbuffered_pipe;                                \
    UnbufferedStreamLow_clear_output(stream) =                          \
      &low_clear_output_unbuffered_pipe;                                \
  }

local inline void create_output_pipe (const char* command) {
  var int child;
 #ifdef EMUNIX
  var int handles[2];
  {
    begin_system_call();
    var FILE* f = popen(command,"w");
    if (f==NULL) { OS_error(); }
    child = f->_pid;
    handles[1] = fileno(f);
    end_system_call();
  }
 #endif
 #ifdef UNIX
  var int handles[2]; # two Handles for the pipe
  {
    # As shell we always use the Command-Shell.
    # copy command to Stack:
    var uintL command_length = asciz_length(command)+1;
    var DYNAMIC_ARRAY(command_data,char,command_length);
    begin_system_call();
    memcpy(command_data,command,command_length);
    if (!( pipe(handles) ==0)) {
      FREE_DYNAMIC_ARRAY(command_data); OS_error();
    }
    # Everything, that is stuffed in handles[1], resurfaces at handles[0]
    # again. We will utilize this as follows:
    #        write            system            read
    # parent  ->   handles[1]   ->   handles[0]  ->  child
    # start a new process:
    if ((child = vfork()) ==0) {
      # this piece of code is executed by the child-process:
      if ( dup2(handles[0],stdin_handle) >=0) # redirect standard-input
        if ( CLOSE(handles[0]) ==0) # we want to read only via stdin_handle
          if ( CLOSE(handles[1]) ==0) { # we do not want to write to the pipe
            # (I have to tell this the operating system, so that - when the
            # Child has emptied the pipe - the parent-process and not the
            # child-process is called, in order to fill the pipe again.)
            # turn child-process into a background process:
            SETSID(); # it receives its own process group
            execl(SHELL,            # call shell
                  SHELL,            # =: argv[0]
                  "-c",             # =: argv[1]
                  &command_data[0], # =: argv[2]
                  NULL);
          }
      _exit(-1); # if this fails, finish child-process
    }
    # This piece of code is again executed by the caller:
    if (child==-1)
      # Something failed, either on vfork or on execl.
      # In both cases errno was set.
      OS_error_saving_errno({
        CLOSE(handles[1]); CLOSE(handles[0]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # We only want to write to the pipe, not read:
    if (!( CLOSE(handles[0]) ==0))
      OS_error_saving_errno({
        CLOSE(handles[1]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # (I have to tell this the operating system, so that - when the
    # parent-process has filled the pipe - the child-process and not the
    # parent-process is called, in order to empty the pipe again.)
    end_system_call();
    FREE_DYNAMIC_ARRAY(command_data);
  }
 #endif
 #ifdef WIN32_NATIVE
  var Handle handles[2]; # two Handles for the Pipe
  {
    begin_system_call();
    var Handle child_read_handle;
    # Create a pipe and make one of the two handles inheritable.
    if (!CreatePipe(&handles[0],&handles[1],NULL,0)) { OS_error(); }
    if (!DuplicateHandle(GetCurrentProcess(),handles[0],
                         GetCurrentProcess(),&child_read_handle,
                         0, true, DUPLICATE_SAME_ACCESS)) {
      OS_error();
    }
    if (!CloseHandle(handles[0])) { OS_error(); }
    var HANDLE stdoutput;
    var PROCESS_INFORMATION pinfo;
    stdoutput = GetStdHandle(STD_OUTPUT_HANDLE);
    if (stdoutput == INVALID_HANDLE_VALUE) { OS_error(); }
    if (!MyCreateProcess(command,child_read_handle,stdoutput,&pinfo)) {
      OS_error();
    }
    # Close our copy of the child's handle, so that the OS knows
    # that we won't read from it.
    if (!CloseHandle(child_read_handle)) { OS_error(); }
    if (!CloseHandle(pinfo.hThread)) { OS_error(); }
    if (!CloseHandle(pinfo.hProcess)) { OS_error(); }
    child = pinfo.dwProcessId;
    end_system_call();
  }
 #endif
  pushSTACK(UL_to_I(child));
  pushSTACK(STACK_(1+1));
  pushSTACK(STACK_(2+2));
  pushSTACK(allocate_handle(handles[1]));
}


# (MAKE-PIPE-OUTPUT-STREAM command [:element-type] [:external-format] [:buffered])
# calls a shell, that executes command, whereby our Pipe is redirected
# into the standard-input of the command.
LISPFUN(make_pipe_output_stream,1,0,norest,key,3,
        (kw(element_type),kw(external_format),kw(buffered)) ) {
  var decoded_el_t eltype;
  var signean buffered;
  # check command:
  pushSTACK(STACK_3); funcall(L(string),1); # (STRING command)
  STACK_3 = value1;
  # Check and canonicalize the :BUFFERED argument:
  buffered = test_buffered_arg(STACK_0); # default is NIL
  # Check and canonicalize the :ELEMENT-TYPE argument:
  test_eltype_arg(&STACK_2,&eltype);
  STACK_2 = canon_eltype(&eltype);
  if (buffered <= 0) { check_unbuffered_eltype(&eltype); }
  # Check and canonicalize the :EXTERNAL-FORMAT argument:
  STACK_1 = test_external_format_arg(STACK_1);
  # Now create the pipe.
  with_string_0(STACK_3,O(misc_encoding),command_asciz, {
    create_output_pipe(command_asciz);
  });
  # allocate Stream:
  var object stream;
  if (!eq(STACK_(0+4),T)) { # (buffered <= 0) ?
    stream = make_unbuffered_stream(strmtype_pipe_out,DIRECTION_OUTPUT,
                                    &eltype,false);
    UnbufferedPipeStream_output_init(stream);
  } else {
    stream = make_buffered_stream(strmtype_pipe_out,DIRECTION_OUTPUT,
                                  &eltype,false,false);
    BufferedPipeStream_init(stream);
  }
  ChannelStreamLow_close(stream) = &low_close_pipe;
  TheStream(stream)->strm_pipe_pid = popSTACK(); # Child-Pid
  skipSTACK(4);
  VALUES1(add_to_open_streams(stream)); /* return stream */
}

#ifdef PIPES2

# Bidirectional Pipes
# ====================

local inline void create_io_pipe (const char* command) {
  var int child;
 #ifdef EMUNIX
  var int in_handles[2];
  var int out_handles[2];
  { # stack layout: command.
    var FILE* f_in;
    var FILE* f_out;
    begin_system_call();
    if (popenrw(command,&f_in,&f_out) <0) { OS_error(); }
    child = f_in->_pid; # = f_out->_pid;
    in_handles[0] = fileno(f_in);
    out_handles[1] = fileno(f_out);
  }
 #endif
 #ifdef UNIX
  var int in_handles[2]; # two Handles for the Pipe to the Input-Stream
  var int out_handles[2]; # two Handles for the Pipe to the Output-Stream
  {
    # As shell we always use the Command-Shell.
    # copy command to Stack:
    var uintL command_length = asciz_length(command)+1;
    var DYNAMIC_ARRAY(command_data,char,command_length);
    begin_system_call();
    memcpy(command_data,command,command_length);
    # build Pipes:
    if (!( pipe(in_handles) ==0)) {
      FREE_DYNAMIC_ARRAY(command_data); OS_error();
    }
    if (!( pipe(out_handles) ==0))
      OS_error_saving_errno({
        CLOSE(in_handles[1]); CLOSE(in_handles[0]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # Everything, that is stuffed in handles[1], resurfaces at handles[0]
    # again. We will utilize this as follows:
    #        write                system                read
    # parent  ->   out_handles[1]   ->   out_handles[0]  ->   child
    # parent  <-   in_handles[0]    <-   in_handles[1]   <-   child
    #        read                 system                write
    # start a new process:
    if ((child = vfork()) ==0) {
      # this piece of code is executed by the child-process:
      if ( dup2(out_handles[0],stdin_handle) >=0) # redirect Standard-Input
        if ( dup2(in_handles[1],stdout_handle) >=0) # redirect Standard-Output
          if ( CLOSE(out_handles[0]) ==0) # read only via stdin_handle
            if ( CLOSE(in_handles[1]) ==0) # write only via stdout_handle
              if ( CLOSE(out_handles[1]) ==0) # do not write to the pipe
                # (I have to tell this the operating system, so that -
                # when the child-process has emptied the pipe -
                # the parent-process and not the child-process is called,
                # in order to fill the pipe again.)
                if ( CLOSE(in_handles[0]) ==0) { # do not to read from the pipe
                  # (I have to tell this the operating system, so that -
                  # when the child-process has filled the pipe -
                  # the parent-process and not the child-process is called,
                  # in order to empty the pipe.)
                  # turn child-process into a background process:
                  SETSID(); # it receives its own process group
                  execl(SHELL,            # call shell
                        SHELL,            # =: argv[0]
                        "-c",             # =: argv[1]
                        &command_data[0], # =: argv[2]
                        NULL);
                }
      _exit(-1); # if this fails, finish child-process
    }
    # This piece of code is again executed by the caller:
    if (child==-1)
      # Something failed, either on vfork or on execl.
      # In both cases errno was set.
      OS_error_saving_errno({
        CLOSE(in_handles[1]); CLOSE(in_handles[0]);
        CLOSE(out_handles[1]); CLOSE(out_handles[0]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # We only want to write to the pipe, not read:
    if (!( CLOSE(out_handles[0]) ==0))
      OS_error_saving_errno({
        CLOSE(in_handles[1]); CLOSE(in_handles[0]);
        CLOSE(out_handles[1]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # (I have to tell this the operating system, so that - when the
    # parent-process has filled the pipe - the child-process and not the
    # parent-process is called, in order to empty the pipe again.)
    # We only want to read from the pipe, not write:
    if (!( CLOSE(in_handles[1]) ==0))
      OS_error_saving_errno({
        CLOSE(in_handles[0]); CLOSE(out_handles[1]);
        FREE_DYNAMIC_ARRAY(command_data);
      });
    # (I have to tell this the operating system, so that - when the
    # parent-process has emptied the pipe - the child-process and not the
    # parent-process is called, in order to fill the pipe again.)
    end_system_call();
    FREE_DYNAMIC_ARRAY(command_data);
  }
 #endif
 #ifdef WIN32_NATIVE
  var Handle in_handles[2]; # two Handles for the Pipe to the Input-Stream
  var Handle out_handles[2]; # two Handles for the Pipe to the Output-Stream
  {
    begin_system_call();
    var Handle child_read_handle;
    var Handle child_write_handle;
    # Create two pipes and make two of the four handles inheritable.
    if (!CreatePipe(&in_handles[0],&in_handles[1],NULL,0)) { OS_error(); }
    if (!DuplicateHandle(GetCurrentProcess(),in_handles[1],
                         GetCurrentProcess(),&child_write_handle,
                         0, true, DUPLICATE_SAME_ACCESS))
      { OS_error(); }
    if (!CloseHandle(in_handles[1])) { OS_error(); }
    if (!CreatePipe(&out_handles[0],&out_handles[1],NULL,0)) { OS_error(); }
    if (!DuplicateHandle(GetCurrentProcess(),out_handles[0],
                         GetCurrentProcess(),&child_read_handle,
                         0, true, DUPLICATE_SAME_ACCESS))
      { OS_error(); }
    if (!CloseHandle(out_handles[0])) { OS_error(); }
    var PROCESS_INFORMATION pinfo;
    if (!MyCreateProcess(command,child_read_handle,child_write_handle,&pinfo))
      { OS_error(); }
    # Close our copies of the child's handles, so that the OS knows
    # that we won't use them.
    if (!CloseHandle(child_read_handle)) { OS_error(); }
    if (!CloseHandle(child_write_handle)) { OS_error(); }
    if (!CloseHandle(pinfo.hThread)) { OS_error(); }
    if (!CloseHandle(pinfo.hProcess)) { OS_error(); }
    child = pinfo.dwProcessId;
    end_system_call();
  }
 #endif
  pushSTACK(UL_to_I(child));
  pushSTACK(allocate_handle(in_handles[0]));
  pushSTACK(allocate_handle(out_handles[1]));
}

# (MAKE-PIPE-IO-STREAM command [:element-type] [:external-format] [:buffered])
# calls a shell, that executes command, whereby the output of our pipe
# is redirected into the standard-input of command and its standard-output
# is redirected into our pipe.
LISPFUN(make_pipe_io_stream,1,0,norest,key,3,
        (kw(element_type),kw(external_format),kw(buffered)) ) {
  var decoded_el_t eltype;
  var signean buffered;
  # check command:
  pushSTACK(STACK_3); funcall(L(string),1); # (STRING command)
  STACK_3 = value1;
  # Check and canonicalize the :BUFFERED argument:
  buffered = test_buffered_arg(STACK_0); # default is NIL
  # Check and canonicalize the :ELEMENT-TYPE argument:
  test_eltype_arg(&STACK_2,&eltype);
  STACK_2 = canon_eltype(&eltype);
  if (buffered <= 0) { check_unbuffered_eltype(&eltype); }
  # Check and canonicalize the :EXTERNAL-FORMAT argument:
  STACK_1 = test_external_format_arg(STACK_1);
  # Now create the pipe.
  with_string_0(STACK_3,O(misc_encoding),command_asciz, {
    create_io_pipe(command_asciz);
  });
  # allocate Input-Stream:
  {
    pushSTACK(STACK_(1+3)); # encoding
    pushSTACK(STACK_(2+3+1)); # eltype
    pushSTACK(STACK_(1+2));
    var object stream;
    if (!eq(STACK_(0+6),T)) { # (buffered <= 0) ?
      stream = make_unbuffered_stream(strmtype_pipe_in,DIRECTION_INPUT,&eltype,false);
      UnbufferedPipeStream_input_init(stream);
    } else {
      stream = make_buffered_stream(strmtype_pipe_in,DIRECTION_INPUT,&eltype,false,false);
      BufferedPipeStream_init(stream);
    }
    ChannelStreamLow_close(stream) = &low_close_pipe;
    TheStream(stream)->strm_pipe_pid = STACK_2; # Child-Pid
    STACK_1 = add_to_open_streams(stream);
  }
  # allocate Output-Stream:
  {
    pushSTACK(STACK_(1+3)); # encoding
    pushSTACK(STACK_(2+3+1)); # eltype
    pushSTACK(STACK_(0+2));
    var object stream;
    if (!eq(STACK_(0+6),T)) { # (buffered <= 0) ?
      stream = make_unbuffered_stream(strmtype_pipe_out,DIRECTION_OUTPUT,
                                      &eltype,false);
      UnbufferedPipeStream_output_init(stream);
    } else {
      stream = make_buffered_stream(strmtype_pipe_out,DIRECTION_OUTPUT,
                                    &eltype,false,false);
      BufferedPipeStream_init(stream);
    }
    ChannelStreamLow_close(stream) = &low_close_pipe;
    TheStream(stream)->strm_pipe_pid = STACK_2; # Child-Pid
    STACK_0 = add_to_open_streams(stream);
  }
 #ifdef EMUNIX
  # combine both pipes, for frictionless close:
  TheStream(STACK_1)->strm_pipe_other = STACK_0;
  TheStream(STACK_0)->strm_pipe_other = STACK_1;
 #endif
  # 3 values:
  # (make-two-way-stream input-stream output-stream), input-stream, output-stream.
  STACK_2 = make_twoway_stream(STACK_1,STACK_0);
  funcall(L(values),3);
  skipSTACK(4);
}

#endif # PIPES2

#endif # PIPES


#if defined(X11SOCKETS) || defined(SOCKET_STREAMS)

# X11-Socket-Stream, Socket-Stream
# ================================

# Socket streams are just like handle streams (unbuffered file streams),
# except that on UNIX_BEOS and WIN32_NATIVE, the low-level functions are
# different.

# Both sides
# ----------

# Closes a socket handle.
#if defined(UNIX_BEOS) || defined(WIN32_NATIVE)
local void low_close_socket (object stream, object handle) {
  begin_system_call();
  if (!( closesocket(TheSocket(handle)) ==0)) { SOCK_error(); }
  end_system_call();
}
#else
  #define low_close_socket  low_close_handle
#endif

# Input side
# ----------

#if defined(UNIX_BEOS) || defined(WIN32_NATIVE)

#ifdef WIN32_NATIVE
  #define CHECK_INTERRUPT                                        \
    if (WSAGetLastError()==WSAEINTR) /* Break by Ctrl-C ?*/      \
      { end_system_call(); fehler_interrupt(); }
#else
  #define CHECK_INTERRUPT
#endif

#define SYSCALL(res,call)                               \
  do { begin_system_call(); res = call;                 \
       if (result<0) { CHECK_INTERRUPT; SOCK_error(); } \
       end_system_call(); } while(0)

local sintL low_read_unbuffered_socket (object stream) {
  if (UnbufferedStream_status(stream) < 0) # already EOF?
    return -1;
  if (UnbufferedStream_status(stream) > 0) { # bytebuf contains valid bytes?
    UnbufferedStreamLow_pop_byte(stream,b); return b;
  }
  var SOCKET handle = TheSocket(TheStream(stream)->strm_ichannel);
  var uintB b;
  var int result; SYSCALL(result,sock_read(handle,&b,1)); # try to read a byte
  if (result==0) {
    # no byte available -> must be EOF
    UnbufferedStream_status(stream) = -1; return -1;
  } else {
    return b;
  }
}

local signean low_listen_unbuffered_socket (object stream) {
  if (UnbufferedStream_status(stream) < 0) # already EOF?
    return ls_eof;
  if (UnbufferedStream_status(stream) > 0) # bytebuf contains valid bytes?
    return ls_avail;
  var SOCKET handle = TheSocket(TheStream(stream)->strm_ichannel);
  # Use select() with readfds = singleton set {handle}
  # and timeout = zero interval.
  var fd_set handle_menge; # set of handles := {handle}
  var struct timeval zero_time; # time interval := 0
  begin_system_call();
  FD_ZERO(&handle_menge); FD_SET(handle,&handle_menge);
 restart_select:
  zero_time.tv_sec = 0; zero_time.tv_usec = 0;
  var int result;
  result = select(FD_SETSIZE,&handle_menge,NULL,NULL,&zero_time);
  if (result<0) {
    CHECK_INTERRUPT;
   #ifdef UNIX_BEOS
    if (errno==EINTR)
      goto restart_select;
   #endif
    SOCK_error();
  } else {
    # result = number of handles in handle_menge for which read() would
    # return without blocking.
    if (result==0) {
      end_system_call(); return ls_wait;
    }
    # result=1
    # When read() returns a result without blocking, this can also be EOF!
    # try to read a byte:
    var uintB b;
    var int result = sock_read(handle,&b,1);
    if (result<0) {
      CHECK_INTERRUPT;
      SOCK_error();
    }
    end_system_call();
    if (result==0) {
      UnbufferedStream_status(stream) = -1; return ls_eof;
    } else {
      # Stuff the read byte into the buffer, for next low_read call.
      UnbufferedStreamLow_push_byte(stream,b);
      return ls_avail;
    }
  }
}

local bool low_clear_input_unbuffered_socket (object stream) {
  # This is not called anyway, because TheStream(stream)->strm_isatty = NIL.
  return false; # Not sure whether this is the correct behaviour??
}

local uintB* low_read_array_unbuffered_socket (object stream, uintB* byteptr,
                                               uintL len) {
  if (UnbufferedStream_status(stream) < 0) # already EOF?
    return byteptr;
  while (UnbufferedStream_status(stream) > 0) { # bytebuf contains valid bytes?
    UnbufferedStreamLow_pop_byte(stream,b);
    *byteptr++ = b;
    len--;
    if (len == 0)
      return byteptr;
  }
  var SOCKET handle = TheSocket(TheStream(stream)->strm_ichannel);
  var int result; SYSCALL(result,sock_read(handle,byteptr,len));
  byteptr += result;
  return byteptr;
}

# Initializes the input side fields of a socket stream.
# UnbufferedSocketStream_input_init(stream);
#define UnbufferedSocketStream_input_init(stream)                       \
  { UnbufferedStreamLow_read(stream) = &low_read_unbuffered_socket;     \
    UnbufferedStreamLow_listen(stream) = &low_listen_unbuffered_socket; \
    UnbufferedStreamLow_clear_input(stream) =                           \
      &low_clear_input_unbuffered_socket;                               \
    UnbufferedStreamLow_read_array(stream) =                            \
      &low_read_array_unbuffered_socket;                                \
    UnbufferedHandleStream_input_init_data(stream);                     \
  }

#else

  #define UnbufferedSocketStream_input_init(stream)  \
    UnbufferedHandleStream_input_init(stream)

#endif # UNIX_BEOS || WIN32_NATIVE

# Output side
# -----------

#if defined(UNIX_BEOS) || defined(WIN32_NATIVE)

local void low_write_unbuffered_socket (object stream, uintB b) {
  var SOCKET handle = TheSocket(TheStream(stream)->strm_ochannel);
  var int result;
  SYSCALL(result,sock_write(handle,&b,1)); # Try to output the byte.
  if (result==0) # not successful?
    fehler_unwritable(TheSubr(subr_self)->name,stream);
}

local const uintB* low_write_array_unbuffered_socket (object stream, const uintB* byteptr, uintL len) {
  var SOCKET handle = TheSocket(TheStream(stream)->strm_ochannel);
  var int result; SYSCALL(result,sock_write(handle,byteptr,len));
  if (result != (sintL)len) # not successful?
    fehler_unwritable(TheSubr(subr_self)->name,stream);
  return byteptr+result;
}

#endif # UNIX_BEOS || WIN32_NATIVE

# Initializes the output side fields of a socket stream.
# UnbufferedSocketStream_output_init(stream);
#if defined(UNIX_BEOS) || defined(WIN32_NATIVE)
  #define UnbufferedSocketStream_output_init(stream)                    \
    { UnbufferedStreamLow_write(stream) = &low_write_unbuffered_socket; \
      UnbufferedStreamLow_write_array(stream) =                         \
        &low_write_array_unbuffered_socket;                             \
      UnbufferedStreamLow_finish_output(stream) =                       \
        &low_finish_output_unbuffered_pipe;                             \
      UnbufferedStreamLow_force_output(stream) =                        \
        &low_force_output_unbuffered_pipe;                              \
      UnbufferedStreamLow_clear_output(stream) =                        \
        &low_clear_output_unbuffered_pipe;                              \
    }
#else
# Use low_write_unbuffered_pipe, not low_write_unbuffered_handle, here because
# writing to a closed socket generates a SIGPIPE signal, just like for pipes.
  #define UnbufferedSocketStream_output_init(stream)  \
    { UnbufferedStreamLow_write(stream) = &low_write_unbuffered_pipe;   \
      UnbufferedStreamLow_write_array(stream) =                         \
        &low_write_array_unbuffered_pipe;                               \
      UnbufferedStreamLow_finish_output(stream) =                       \
        &low_finish_output_unbuffered_pipe;                             \
      UnbufferedStreamLow_force_output(stream) =                        \
        &low_force_output_unbuffered_pipe;                              \
      UnbufferedStreamLow_clear_output(stream) =                        \
        &low_clear_output_unbuffered_pipe;                              \
    }
#endif # UNIX_BEOS || WIN32_NATIVE

#endif # X11SOCKETS || SOCKET_STREAMS


#ifdef X11SOCKETS

# X11-Socket-Stream
# =================

# usage: for X-Windows.

# Additional Components:
  # define strm_x11socket_connect strm_field1 # List (host display)

extern SOCKET connect_to_x_server (const char* host, int display); # a piece X-Source...

# (SYS::MAKE-SOCKET-STREAM host display)
# returns an X11-Socket-Stream for X-Windows or NIL.
LISPFUNN(make_x11socket_stream,2) {
  if (!stringp(STACK_1)) {
    pushSTACK(STACK_1);   # TYPE-ERROR slot DATUM
    pushSTACK(S(string)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(STACK_(1+2));
    fehler(type_error,GETTEXT("host should be string, not ~"));
  }
  if (!posfixnump(STACK_0)) {
    pushSTACK(STACK_0);           # TYPE-ERROR slot DATUM
    pushSTACK(O(type_posfixnum)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(STACK_(0+2));
    fehler(type_error,
           GETTEXT("display should be a nonnegative fixnum, not ~"));
  }
  var const char* host = TheAsciz(string_to_asciz(STACK_1,O(misc_encoding)));
  var SOCKET handle;
  begin_system_call();
  handle = connect_to_x_server(host,posfixnum_to_L(STACK_0));
  end_system_call();
  if (handle == INVALID_SOCKET) { SOCK_error(); }
  # build list:
  { var object list = listof(2); pushSTACK(list); }
  pushSTACK(test_external_format_arg(S(Kunix)));
  pushSTACK(O(strmtype_ubyte8));
  pushSTACK(allocate_socket(handle));
  # allocate Stream:
  var decoded_el_t eltype = { eltype_iu, 8 };
  var object stream = make_unbuffered_stream(strmtype_x11socket,DIRECTION_IO,&eltype,false);
  UnbufferedSocketStream_input_init(stream);
  UnbufferedSocketStream_output_init(stream);
  ChannelStreamLow_close(stream) = &low_close_socket;
  TheStream(stream)->strm_x11socket_connect = popSTACK(); # two-element list
  VALUES1(add_to_open_streams(stream)); /* return stream */
}

# The two following functions should
# 1. not only work for Handle- and Socket-Streams, but also for Synonym-
#    and Concatenated-Streams, ideally for File-Streams, too.
# 2. also accept non-simple Byte-Vectors.
# For CLX this implementation is sufficient.

# (SYS::READ-N-BYTES stream vector start count)
# reads n Bytes at once.
# Source:
#   stream: Handle- or Socket-Stream
# Destination: (aref vector start), ..., (aref vector (+ start (- count 1))),
#  whereby
#   vector: semi-simple 8Bit-Byte-Vector
#   start: Start-Index in the Vector
#   count: Number of bytes

# (SYS::WRITE-N-BYTES stream vector start count)
# writes n Bytes at once.
# Source: (aref vector start), ..., (aref vector (+ start (- count 1))),
#  whereby
#   vector: semi-simple 8Bit-Byte-Vector
#   start: Start-Index in the Vector
#   count: Number of Bytes
# Destination:
#   stream: Handle- or Socket-Stream

# Argument-Checks:
# Returns the Index in *index_, the count in *count_, the data-vector in the
# Stack instead of the vector, and cleans up the Stack by 2.
local void test_n_bytes_args (uintL* index_, uintL* count_) {
  {
    var object stream = STACK_3;
    if (!(builtin_stream_p(stream)
          && eq(TheStream(stream)->strm_rd_by,P(rd_by_iau8_unbuffered))
          && eq(TheStream(stream)->strm_wr_by,P(wr_by_iau8_unbuffered)))) {
      if (!streamp(stream)) {
        fehler_stream(stream);
      } else {
        pushSTACK(stream);
        pushSTACK(TheSubr(subr_self)->name);
        fehler(error,GETTEXT("~: stream must be a socket-stream, not ~"));
      }
    }
  }
  {
    var object vector = STACK_2;
    if (!bit_vector_p(Atype_8Bit,vector)) {
      pushSTACK(vector);               # TYPE-ERROR slot DATUM
      pushSTACK(O(type_uint8_vector)); # TYPE-ERROR slot EXPECTED-TYPE
      pushSTACK(vector);
      pushSTACK(TheSubr(subr_self)->name);
      fehler(type_error,GETTEXT("~: argument ~ should be a vector of type (ARRAY (UNSIGNED-BYTE 8) (*))"));
    }
    if (!posfixnump(STACK_0))
      fehler_posfixnum(STACK_0);
    *count_ = posfixnum_to_L(popSTACK());
    if (!posfixnump(STACK_0))
      fehler_posfixnum(STACK_0);
    *index_ = posfixnum_to_L(popSTACK());
    STACK_0 = array_displace_check(vector,*count_,index_);
  }
}

LISPFUNN(read_n_bytes,4) {
  var uintL startindex;
  var uintL totalcount;
  test_n_bytes_args(&startindex,&totalcount);
  if (!(totalcount==0)) {
    if (read_byte_array(&STACK_1,&STACK_0,startindex,totalcount)
        != totalcount) {
      pushSTACK(STACK_1); # STREAM-ERROR slot STREAM
      pushSTACK(STACK_(1+1)); # Stream
      pushSTACK(S(read_n_bytes));
      fehler(end_of_file,GETTEXT("~: input stream ~ has reached its end"));
    }
  }
  skipSTACK(2);
  VALUES1(T);
}

LISPFUNN(write_n_bytes,4) {
  var uintL startindex;
  var uintL totalcount;
  test_n_bytes_args(&startindex,&totalcount);
  if (!(totalcount==0)) {
    write_byte_array(&STACK_1,&STACK_0,startindex,totalcount);
  }
  skipSTACK(2);
  VALUES1(T);
}

#endif # X11SOCKETS


#ifdef SOCKET_STREAMS

# Socket-Streams
# ==============

  # define strm_socket_port strm_field1 # port, a fixnum >=0
  # define strm_socket_host strm_field2 # host, NIL or a string

#define SocketChannel(stream)                                              \
 TheSocket(ChannelStream_buffered(stream) ? BufferedStream_channel(stream) \
           : ChannelStream_ichannel(stream))

# Low-level functions for buffered socket streams.

#if defined(UNIX_BEOS) || defined(WIN32_NATIVE)

# UP: Fills the buffer, up to strm_buffered_bufflen bytes.
# low_fill_buffered_socket(stream)
# > stream: (open) byte-based socket stream
# < result: number of bytes read
local uintL low_fill_buffered_socket (object stream) {
  var sintL result;
  SYSCALL(result,
    sock_read(TheSocket(BufferedStream_channel(stream)),
              BufferedStream_buffer_address(stream,0),
              strm_buffered_bufflen));
  return result;
}

# UP: Finshes the Write-Back of the Buffer.
# low_flush_buffered_socket(stream,bufflen);
# > stream : (open) Byte-based File-Stream.
# > bufflen : number of bytes to be written
# < modified_flag von stream : deleted
# changed in stream: index
local void low_flush_buffered_socket (object stream, uintL bufflen) {
  begin_system_call();
 #if defined(HAVE_SIGNALS) && defined(SIGPIPE)
  writing_to_subprocess = true;
 #endif
  var sintL result = # flush Buffer
    sock_write(TheSocket(BufferedStream_channel(stream)),
               BufferedStream_buffer_address(stream,0),
               bufflen);
 #if defined(HAVE_SIGNALS) && defined(SIGPIPE)
  writing_to_subprocess = false;
 #endif
  if (result==bufflen) {
    # everything written correctly
    end_system_call(); BufferedStream_modified(stream) = false;
  } else { # not everything written
    if (result<0) {
      CHECK_INTERRUPT;
      SOCK_error();
    }
    end_system_call();
    fehler_unwritable(TheSubr(subr_self)->name,stream);
  }
}

#undef SYSCALL
#undef CHECK_INTERRUPT

#else

# Use low_flush_buffered_pipe, not low_flush_buffered_handle, here because
# writing to a closed socket generates a SIGPIPE signal, just like for pipes.
  #define low_fill_buffered_socket  low_fill_buffered_handle
  #define low_flush_buffered_socket  low_flush_buffered_pipe

#endif

#define BufferedSocketStream_init(stream)  \
  { BufferedStreamLow_fill(stream) = &low_fill_buffered_socket;   \
    BufferedStreamLow_flush(stream) = &low_flush_buffered_socket; \
  }

# Twoway-Socket-Streams are twoway streams with both input and output side
# being socket streams. (They are needed because the input and output side
# need different buffers. Sockets are not regular files.)
  # define strm_twoway_socket_input  strm_twoway_input  # input side, a socket stream
  #define strm_twoway_socket_output  strm_twoway_output # output side, a socket stream

# Hack for avoiding that the handle is closed twice.
local void low_close_socket_nop (object stream, object handle) {}

# Creates a socket stream.
# > STACK_2: element-type
# > STACK_1: encoding
local object make_socket_stream (SOCKET handle, decoded_el_t* eltype,
                                 signean buffered, object host, object port) {
  pushSTACK(host);
  pushSTACK(STACK_(1+1)); # encoding
  pushSTACK(STACK_(2+2)); # eltype
  pushSTACK(allocate_socket(handle));
  # allocate stream:
  var object stream;
  if (buffered <= 0) {
    stream = make_unbuffered_stream(strmtype_socket,DIRECTION_IO,eltype,false);
    UnbufferedSocketStream_input_init(stream);
    UnbufferedSocketStream_output_init(stream);
    ChannelStreamLow_close(stream) = &low_close_socket;
    TheStream(stream)->strm_socket_port = port;
    TheStream(stream)->strm_socket_host = popSTACK();
  } else {
    # allocate Input-Stream:
    pushSTACK(STACK_2); pushSTACK(STACK_(1+1)); pushSTACK(STACK_(0+2));
    stream = make_buffered_stream(strmtype_socket,DIRECTION_INPUT,
                                  eltype,false,false);
    BufferedSocketStream_init(stream);
    ChannelStreamLow_close(stream) = &low_close_socket;
    TheStream(stream)->strm_socket_port = port;
    TheStream(stream)->strm_socket_host = STACK_3;
    pushSTACK(stream);
    # allocate Output-Stream:
    pushSTACK(STACK_(2+1)); pushSTACK(STACK_(1+2)); pushSTACK(STACK_(0+3));
    stream = make_buffered_stream(strmtype_socket,DIRECTION_OUTPUT,
                                  eltype,false,false);
    BufferedSocketStream_init(stream);
    ChannelStreamLow_close(stream) = &low_close_socket;
    TheStream(stream)->strm_socket_port = port;
    TheStream(stream)->strm_socket_host = STACK_(3+1);
    pushSTACK(stream);
    # Allocate a Two-Way-Socket-Stream:
    stream = allocate_stream(strmflags_rdwr_B,strmtype_twoway_socket,
                             strm_len+2,0);
    TheStream(stream)->strm_rd_by = P(rd_by_twoway);
    TheStream(stream)->strm_rd_by_array = P(rd_by_array_twoway);
    TheStream(stream)->strm_wr_by = P(wr_by_twoway);
    TheStream(stream)->strm_wr_by_array = P(wr_by_array_twoway);
    TheStream(stream)->strm_rd_ch = P(rd_ch_twoway);
    TheStream(stream)->strm_pk_ch = P(pk_ch_twoway);
    TheStream(stream)->strm_rd_ch_array = P(rd_ch_array_twoway);
    TheStream(stream)->strm_rd_ch_last = NIL;
    TheStream(stream)->strm_wr_ch = P(wr_ch_twoway);
    TheStream(stream)->strm_wr_ch_array = P(wr_ch_array_twoway);
    TheStream(stream)->strm_wr_ch_lpos = Fixnum_0;
    TheStream(stream)->strm_twoway_socket_input = STACK_1;
    TheStream(stream)->strm_twoway_socket_output = STACK_0;
    skipSTACK(6);
  }
  return stream;
}

local void test_socket_server (object obj, bool check_open) {
  if (!socket_server_p(obj)) {
    pushSTACK(obj);
    pushSTACK(S(socket_server));
    pushSTACK(obj);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(type_error,GETTEXT("~: ~ is not a SOCKET-SERVER"));
  }
  if (check_open && nullp(TheSocketServer(obj)->socket_handle)) {
    pushSTACK(obj);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~ on ~ is illegal"));
  }
}

# Called when some socket server dies.
LISPFUNN(socket_server_close,1) {
  test_socket_server(STACK_0,false);
  var object ss = popSTACK();
  if (!nullp(TheSocketServer(ss)->socket_handle)) {
    var SOCKET s = TheSocket(TheSocketServer(ss)->socket_handle);
    begin_system_call();
    loop {
      if (closesocket(s) < 0) {
        if (!sock_errno_is(EINTR)) { SOCK_error(); }
      } else
        break;
    }
    end_system_call();
    TheSocketServer(ss)->socket_handle = NIL;
  }
  VALUES1(NIL);
}

extern SOCKET create_server_socket (host_data_t *hd, SOCKET sock,
                                    unsigned int port);

# (SOCKET-SERVER [port-or-sock])
LISPFUN(socket_server,0,1,norest,nokey,0,NIL) {
  var SOCKET sock;        # a hint for create_server_socket
  var unsigned int port;  # another hint for create_server_socket

  if (missingp(STACK_0)) {
    sock = INVALID_SOCKET; port = 0; goto doit;
  }
  if (posfixnump(STACK_0)) {
    sock = INVALID_SOCKET; port = posfixnum_to_L(STACK_0); goto doit;
  }
  if (builtin_stream_p(STACK_0)) {
    var object stream = STACK_0;
    switch (TheStream(stream)->strmtype) {
      case strmtype_twoway_socket:
        stream = TheStream(stream)->strm_twoway_socket_input;
        /*FALLTHROUGH*/
      case strmtype_socket:
        if (TheStream(stream)->strmflags & strmflags_open_B) {
          sock = SocketChannel(stream);
          port = 0; goto doit;
        }
        break;
      default:
        break;
    }
  }
  pushSTACK(STACK_0);   # TYPE-ERROR slot DATUM
  pushSTACK(S(stream)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(STACK_(0+2));
  pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: argument ~ is neither an open SOCKET-STREAM nor a positive FIXNUM"));

 doit:
  var SOCKET sk;
  var host_data_t myname;
  begin_system_call();
  sk = create_server_socket(&myname, sock, port);
  end_system_call();
  if (sk == INVALID_SOCKET) { SOCK_error(); }

  pushSTACK(allocate_socket(sk));
  pushSTACK(allocate_socket_server());
  TheSocketServer(STACK_0)->socket_handle = STACK_1;
  TheSocketServer(STACK_0)->port = fixnum(myname.port);
  {
    var object host = asciz_to_string(myname.hostname,O(misc_encoding)); # for GC-safety
    TheSocketServer(STACK_0)->host = host;
  }
  pushSTACK(STACK_0);
  pushSTACK(L(socket_server_close));
  funcall(L(finalize),2); # (FINALIZE socket-server #'socket-server-close)
  VALUES1(popSTACK());
  skipSTACK(2);
}

# (SOCKET-SERVER-PORT socket-server)
LISPFUNN(socket_server_port,1) {
  test_socket_server(STACK_0,false);
  VALUES1(TheSocketServer(STACK_0)->port);
  skipSTACK(1);
}

# (SOCKET-SERVER-HOST socket-server)
LISPFUNN(socket_server_host,1) {
  test_socket_server(STACK_0,false);
  VALUES1(TheSocketServer(STACK_0)->host);
  skipSTACK(1);
}

# parse timeout argument
# sec = posfixnum or (SEC . USEC) or (SEC USEC) or float or ratio
#       or nil/unbound
# usec = posfixnum or nil/unbound
# can trigger GC
local struct timeval * sec_usec (object sec, object usec, struct timeval *tv) {
  if (missingp(sec)) {
    return NULL;
  } else if (consp(sec)) {
    if (!nullp(Cdr(sec)) && !boundp(usec))
      usec = (consp(Cdr(sec)) ? Car(Cdr(sec)) : Cdr(sec));
    sec = Car(sec);
  } else if (floatp(sec) || ratiop(sec)) { # sec = sec mod 1
    pushSTACK(sec); funcall(L(floor),1);
    sec = value1;
    if (!boundp(usec)) { /* usec = round(sec*1000000) */
      pushSTACK(subr_self); # save subr_self
      pushSTACK(value2); pushSTACK(fixnum(1000000)); funcall(L(mal),2);
      pushSTACK(value1); funcall(L(round),1);
      subr_self = popSTACK(); # restore subr_self
      usec = value1;
    }
  }
  if (!posfixnump(sec))
    fehler_posfixnum(sec);
  tv->tv_sec = posfixnum_to_L(sec);
  if (missingp(usec)) {
    tv->tv_usec = 0;
  } else {
    if (!posfixnump(usec))
      fehler_posfixnum(usec);
    tv->tv_usec = posfixnum_to_L(usec);
  }
  return tv;
}

#if defined(HAVE_SELECT) || defined(WIN32_NATIVE)
# wait for the socket server to have a connection ready
# returns true iff socket_accept will return immediately
local bool socket_server_wait (object sose, struct timeval *tvp) {
  var SOCKET handle = TheSocket(TheSocketServer(sose)->socket_handle);
 #if defined(WIN32_NATIVE)
  return interruptible_socket_wait(handle,socket_wait_read,tvp);
 #else
 restart_select:
  begin_system_call();
  var int ret;
  var fd_set handle_set;
  FD_ZERO(&handle_set); FD_SET(handle,&handle_set);
  ret = select(FD_SETSIZE,&handle_set,NULL,NULL,tvp);
  if (ret < 0) {
    if (sock_errno_is(EINTR)) {
      end_system_call(); goto restart_select;
    }
    SOCK_error();
  }
  end_system_call();
  return (ret != 0);
 #endif # WIN32_NATIVE
}
#endif

extern SOCKET accept_connection (SOCKET socket_handle);

# (SOCKET-ACCEPT socket-server [:element-type] [:external-format] [:buffered]
#                [:timeout])
LISPFUN(socket_accept,1,0,norest,key,4,
        (kw(element_type),kw(external_format),kw(buffered),kw(timeout)) ) {
  var SOCKET sock;
  var decoded_el_t eltype;
  var signean buffered;
  var SOCKET handle;
  var struct timeval tv;
  var struct timeval *tvp = sec_usec(popSTACK(),unbound,&tv);

  test_socket_server(STACK_3,true);

  # Check and canonicalize the :BUFFERED argument:
  buffered = test_buffered_arg(STACK_0); # default is NIL

  # Check and canonicalize the :ELEMENT-TYPE argument:
  test_eltype_arg(&STACK_2,&eltype);
  STACK_2 = canon_eltype(&eltype);
  if (buffered <= 0) { check_unbuffered_eltype(&eltype); }

  # Check and canonicalize the :EXTERNAL-FORMAT argument:
  STACK_1 = test_external_format_arg(STACK_1);

 #if defined(HAVE_SELECT) || defined(WIN32_NATIVE)
  if (tvp && !socket_server_wait(STACK_3,tvp)) { # handle :TIMEOUT
    skipSTACK(4); sock_set_errno(ETIMEDOUT); OS_error();
  }
 #endif

  sock = TheSocket(TheSocketServer(STACK_3)->socket_handle);
  begin_system_call();
  handle = accept_connection (sock);
  end_system_call();
  if (handle == INVALID_SOCKET) { SOCK_error(); }
  value1 = make_socket_stream(handle,&eltype,buffered,
                              TheSocketServer(STACK_3)->host,
                              TheSocketServer(STACK_3)->port);
  VALUES1(add_to_open_streams(value1));
  skipSTACK(4);
}

# (SOCKET-WAIT socket-server [seconds [microseconds]])
LISPFUN(socket_wait,1,2,norest,nokey,0,NIL) {
  test_socket_server(STACK_2,true);
 #if defined(HAVE_SELECT) || defined(WIN32_NATIVE)
  var struct timeval timeout;
  var struct timeval * timeout_ptr = sec_usec(STACK_1,STACK_0,&timeout);
  VALUES_IF(socket_server_wait(STACK_2,timeout_ptr));
 #else
  VALUES1(NIL);
 #endif
  skipSTACK(3);
}

extern SOCKET create_client_socket (const char* host, unsigned int port,
                                    void* timeout);

# (SOCKET-CONNECT port [host] [:element-type] [:external-format] [:buffered]
#                 [:timeout])
LISPFUN(socket_connect,1,1,norest,key,4,
        (kw(element_type),kw(external_format),kw(buffered),kw(timeout)) ) {
  var char *hostname;
  var decoded_el_t eltype;
  var signean buffered;
  var SOCKET handle;
  var struct timeval tv;
  var struct timeval *tvp = sec_usec(popSTACK(),unbound,&tv);

  if (!posfixnump(STACK_4))
    fehler_posfixnum(STACK_4);

  # Check and canonicalize the :BUFFERED argument:
  buffered = test_buffered_arg(STACK_0); # default is NIL

  # Check and canonicalize the :ELEMENT-TYPE argument:
  test_eltype_arg(&STACK_2,&eltype);
  STACK_2 = canon_eltype(&eltype);
  if (buffered <= 0) { check_unbuffered_eltype(&eltype); }

  # Check and canonicalize the :EXTERNAL-FORMAT argument:
  STACK_1 = test_external_format_arg(STACK_1);

  if (missingp(STACK_3))
    hostname = "localhost";
  else if (stringp(STACK_3))
    hostname = TheAsciz(string_to_asciz(STACK_3,O(misc_encoding)));
  else
    fehler_string(STACK_3);

  begin_system_call();
  handle = create_client_socket(hostname,posfixnum_to_L(STACK_4),tvp);
  if (handle == INVALID_SOCKET) { SOCK_error(); }
  end_system_call();
  value1 = make_socket_stream(handle,&eltype,buffered,
                              asciz_to_string(hostname,O(misc_encoding)),
                              STACK_4);
  VALUES1(add_to_open_streams(value1));
  skipSTACK(5);
}

local object test_socket_stream (object obj, bool check_open) {
  if (builtin_stream_p(obj)) {
    switch (TheStream(obj)->strmtype) {
      case strmtype_twoway_socket:
        obj = TheStream(obj)->strm_twoway_socket_input;
        /*FALLTHROUGH*/
      case strmtype_socket:
        if (check_open
            && ((TheStream(obj)->strmflags & strmflags_open_B) == 0)) {
          pushSTACK(obj);       # TYPE-ERROR slot DATUM
          pushSTACK(S(stream)); # TYPE-ERROR slot EXPECTED-TYPE
          pushSTACK(obj);
          pushSTACK(TheSubr(subr_self)->name);
          fehler(type_error,
                 GETTEXT("~: argument ~ is not an open SOCKET-STREAM"));
        }
        return obj;
      default:
        break;
    }
  }
  pushSTACK(obj);       # TYPE-ERROR slot DATUM
  pushSTACK(S(stream)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(obj);
  pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: argument ~ is not a SOCKET-STREAM"));
}

# check whether the object is a handle stream or a socket-server
# and return its socket-like handle(s)
local void stream_handles (object obj, bool check_open, bool* char_p,
                           SOCKET* in_sock, SOCKET* out_sock) {
  if (socket_server_p(obj)) {
    if (check_open) test_socket_server(obj,true);
    if (in_sock) *in_sock = TheSocket(TheSocketServer(obj)->socket_handle);
    return;
  }
  check_stream(obj);
  if (!(TheStream(obj)->strmflags & strmflags_open_B)) {
    pushSTACK(obj);       # TYPE-ERROR slot DATUM
    pushSTACK(S(stream)); # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(S(stream));
    pushSTACK(obj);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(type_error,GETTEXT("~: argument ~ is not an open ~"));
  }
  switch (TheStream(obj)->strmtype) {
    case strmtype_terminal:
      if (in_sock)  *in_sock  = (SOCKET)stdin_handle;
      if (out_sock) *out_sock = (SOCKET)stdout_handle;
      if (char_p) *char_p = true;
      return;
    case strmtype_twoway_socket:
      obj = TheStream(obj)->strm_twoway_socket_input;
      if (in_sock)  *in_sock  = SocketChannel(obj);
      if (out_sock) *out_sock = SocketChannel(obj);
      if (char_p) *char_p = eq(TheStream(obj)->strm_eltype,S(character));
      return;
    case strmtype_socket:
      if (in_sock  && input_stream_p(obj))  *in_sock  = SocketChannel(obj);
      if (out_sock && output_stream_p(obj)) *out_sock = SocketChannel(obj);
      if (char_p) *char_p = eq(TheStream(obj)->strm_eltype,S(character));
      return;
    case strmtype_echo:
    case strmtype_twoway:
      stream_handles(TheStream(obj)->strm_twoway_input,
                     check_open,char_p,in_sock,NULL);
      stream_handles(TheStream(obj)->strm_twoway_output,
                     check_open,NULL,NULL,out_sock);
      return;
   #ifdef PIPES
    case strmtype_pipe_in:
      if (in_sock) *in_sock  = (SOCKET)ChannelStream_ihandle(obj);
      if (char_p) *char_p = eq(TheStream(obj)->strm_eltype,S(character));
      return;
    case strmtype_pipe_out:
      if (out_sock) *out_sock = (SOCKET)ChannelStream_ohandle(obj);
      return;
   #endif
    case strmtype_file: {
      var Handle handle = ChannelStream_ihandle(obj);
      if (in_sock  && input_stream_p(obj))  *in_sock  = (SOCKET)handle;
      if (out_sock && output_stream_p(obj)) *out_sock = (SOCKET)handle;
      if (char_p) *char_p = eq(TheStream(obj)->strm_eltype,S(character));
      return;
    }
    default: fehler_illegal_streamop(TheSubr(subr_self)->name,obj);
  }
}

# set the appropriate fd_sets for the socket,
# either a socket-server, a socket-stream or a (socket . direction)
# see socket_status() for details
# return the number of handles set
local uintL handle_set (object socket, fd_set *readfds, fd_set *writefds,
                        fd_set *errorfds) {
  object sock = (consp(socket) ? Car(socket) : socket);
  direction_t dir = (consp(socket)?check_direction(Cdr(socket)):DIRECTION_IO);
  SOCKET in_sock = INVALID_SOCKET, out_sock = INVALID_SOCKET;
  uintL ret = 0;
  stream_handles(sock,true,NULL,
                 READ_P(dir)  ? &in_sock  : NULL,
                 WRITE_P(dir) ? &out_sock : NULL);
  if (in_sock != INVALID_SOCKET) {
    ret++;
    FD_SET(in_sock,errorfds);
    FD_SET(in_sock,readfds);
  }
  if (out_sock != INVALID_SOCKET) {
    ret++;
    FD_SET(out_sock,errorfds);
    FD_SET(out_sock,writefds);
  }
  return ret;
}

# check the appropriate fd_sets for the socket,
# either a socket-server, a socket-stream or a (socket . direction)
# see socket_status() for details
# can trigger GC
local object handle_isset (object socket, fd_set *readfds, fd_set *writefds,
                           fd_set *errorfds) {
  object sock = (consp(socket) ? Car(socket) : socket);
  direction_t dir = (consp(socket)?check_direction(Cdr(socket)):DIRECTION_IO);
  SOCKET in_sock = INVALID_SOCKET, out_sock = INVALID_SOCKET;
  bool char_p = true, rd = false, wr = false;
  stream_handles(sock,true,&char_p,
                 READ_P(dir)  ? &in_sock  : NULL,
                 WRITE_P(dir) ? &out_sock : NULL);
  if (in_sock != INVALID_SOCKET) {
    if (FD_ISSET(in_sock,errorfds)) return S(Kerror);
    if (socket_server_p(sock))
      return FD_ISSET(in_sock,readfds) ? T : NIL;
    rd = FD_ISSET(in_sock,readfds)
      && (ls_avail_p(char_p ? listen_char(sock) : listen_byte(sock)));
  }
  if (out_sock != INVALID_SOCKET) {
    if (FD_ISSET(out_sock,errorfds)) return S(Kerror);
    wr = FD_ISSET(out_sock,writefds);
  }
  if      ( rd && !wr) return S(Kinput);
  else if (!rd &&  wr) return S(Koutput);
  else if ( rd &&  wr) return S(Kio);
  else                 return NIL;
}
#undef READ_P
#undef WRITE_P

# (SOCKET-STATUS socket-or-list [seconds [microseconds]])
# socket-or-list should be either
#   -- socket [socket-stream or socket-server]
#   -- (socket . direction) [direction is :input or :output or :io (default)]
#   -- list of the above
# returns either a single symbol :ERROR/:INPUT/:OUTPUT/:IO (for streams)
#         or T/NIL (for socket-servers) - when a single object was given -
#      or a list of such symbols.
# will cons the list (and thus can trigger GC) in the latter case.
LISPFUN(socket_status,1,2,norest,nokey,0,NIL) {
 #if defined(HAVE_SELECT) || defined(WIN32_NATIVE)
  var struct timeval timeout;
  var struct timeval * timeout_ptr = sec_usec(STACK_1,STACK_0,&timeout);

 restart_select:
  begin_system_call();
  { var fd_set readfds, writefds, errorfds;
    var object all = STACK_2;
    FD_ZERO(&readfds); FD_ZERO(&writefds); FD_ZERO(&errorfds);
    var bool many_sockets_p =
      (consp(all) && !(symbolp(Cdr(all)) && keywordp(Cdr(all))));
    if (many_sockets_p) {
      var object list = all;
      var int index = 0;
      for(; !nullp(list); list = Cdr(list)) {
        if (!listp(list)) fehler_list(list);
        index += handle_set(Car(list),&readfds,&writefds,&errorfds);
        if (index > FD_SETSIZE) {
          pushSTACK(fixnum(FD_SETSIZE));
          pushSTACK(all);
          pushSTACK(S(socket_status));
          fehler(error,GETTEXT("~: list ~ is too long (~ maximum)"));
        }
      }
    } else
      handle_set(all,&readfds,&writefds,&errorfds);
    if (select(FD_SETSIZE,&readfds,&writefds,&errorfds,timeout_ptr) < 0) {
      if (sock_errno_is(EINTR)) { end_system_call(); goto restart_select; }
      if (!sock_errno_is(EBADF)) { SOCK_error(); }
    }
    if (many_sockets_p) {
      var object list = all;
      var int index = 0;
      while(!nullp(list)) {
        index++; pushSTACK(list); # save list
        var object tmp = handle_isset(Car(list),&readfds,&writefds,&errorfds);
        list = Cdr(STACK_0); # (POP list)
        STACK_0 = tmp;
      }
      VALUES1(listof(index));
    } else
      VALUES1(handle_isset(all,&readfds,&writefds,&errorfds));
    end_system_call();
  }
 #else
  VALUES1(NIL);
 #endif
  skipSTACK(3);
}

/* the next three functions handle getsockopt()/setsockopt() calls
   for boolean, integer and timeval options respectively.
   both push one result on STACK */
local void sock_opt_bool (SOCKET handle, int option, object value)
{
  var int val;
  var uint len = sizeof(val);
  if (-1 == getsockopt(handle,SOL_SOCKET,option,&val,&len)) OS_error();
  pushSTACK(val ? T : NIL);
  if (!(eq(value,nullobj))) {
    val = !nullp(value);
    if (-1 == setsockopt(handle,SOL_SOCKET,option,&val,len)) OS_error();
  }
}

local void sock_opt_int (SOCKET handle, int option, object value)
{
  var uintL val;
  var uint len = sizeof(val);
  if (-1 == getsockopt(handle,SOL_SOCKET,option,&val,&len)) OS_error();
  pushSTACK(fixnum(val));
  if (!(eq(value,nullobj))) {
    if (!posfixnump(value)) fehler_posfixnum(value);
    val = posfixnum_to_L(value);
    if (-1 == setsockopt(handle,SOL_SOCKET,option,&val,len)) OS_error();
  }
}

local void sock_opt_time (SOCKET handle, int option, object value)
{ /* may trigger GC */
  var struct timeval val;
  var uint len = sizeof(val);
  if (-1 == getsockopt(handle,SOL_SOCKET,option,&val,&len)) OS_error();
  if (val.tv_usec) {
    double x = val.tv_sec + val.tv_sec*0.000001;
    dfloatjanus t = *(dfloatjanus*)&x;
    pushSTACK(c_double_to_DF(&t));
  } else pushSTACK(fixnum(val.tv_sec));
  if (!(eq(value,nullobj))) {
    sec_usec(value,unbound,&val);
    if (-1 == setsockopt(handle,SOL_SOCKET,option,&val,len)) OS_error();
  }
}


/* (SOCKET-OPTIONS socket-stream &rest options)
   queries and setf socket options.
   returns the old value for each option:
   (SOCKET-OPTIONS s :so-keepalive :so-rcvlowat 10)
   will set :so-rcvlowat to 10 and return the current
   value of :so-keepalive and the old value of :so-rcvlowat */
LISPFUN(socket_options,1,0,rest,nokey,0,NIL) {
  var object socket = *(rest_args_pointer STACKop 1);
  var object *arg_p = rest_args_pointer;
  var int count = argcount, retval_count = argcount;
  var SOCKET handle;
  stream_handles(socket,true,NULL,&handle,NULL);
  while (count-->0) {
    var object kwd = NEXT(arg_p);
    var object arg = Next(arg_p);
    if (count && !(symbolp(arg) && keywordp(arg))) {
      NEXT(arg_p);
      count--; retval_count--;
    } else arg = nullobj;
    begin_system_call();
    if (eq(kwd,S(Kso_keepalive))) {
      sock_opt_bool(handle,SO_KEEPALIVE,arg);
    } else if (eq(kwd,S(Kso_error))) {
      sock_opt_bool(handle,SO_ERROR,arg);
    } else if (eq(kwd,S(Kso_linger))) {
      struct linger val;
      var uint len = sizeof(val);
      if (-1 == getsockopt(handle,SOL_SOCKET,SO_LINGER,&val,&len)) OS_error();
      if (val.l_onoff) pushSTACK(fixnum(val.l_linger));
      else pushSTACK(NIL);
      if (!(eq(arg,nullobj))) { /* arg points to STACK so it is safe */
        if (posfixnump(arg)) {
          val.l_onoff = 1;
          val.l_linger = posfixnum_to_L(arg);
        } else if (eq(T,arg)) {
          val.l_onoff = 1;
        } else if (nullp(arg)) {
          val.l_onoff = 0;
        } else fehler_posfixnum(arg);
        if (-1 == setsockopt(handle,SOL_SOCKET,SO_LINGER,&val,len)) OS_error();
      }
    } else if (eq(kwd,S(Kso_oobinline))) {
      sock_opt_bool(handle,SO_OOBINLINE,arg);
    } else if (eq(kwd,S(Kso_type))) {
      sock_opt_bool(handle,SO_TYPE,arg);
    } else if (eq(kwd,S(Kso_rcvbuf))) {
      sock_opt_int(handle,SO_RCVBUF,arg);
    } else if (eq(kwd,S(Kso_sndbuf))) {
      sock_opt_int(handle,SO_SNDBUF,arg);
    } else if (eq(kwd,S(Kso_rcvlowat))) {
      sock_opt_int(handle,SO_RCVLOWAT,arg);
    } else if (eq(kwd,S(Kso_sndlowat))) {
      sock_opt_int(handle,SO_SNDLOWAT,arg);
    } else if (eq(kwd,S(Kso_rcvtimeo))) {
      sock_opt_time(handle,SO_RCVTIMEO,arg);
    } else if (eq(kwd,S(Kso_sndtimeo))) {
      sock_opt_time(handle,SO_SNDTIMEO,arg);
    } else {
      pushSTACK(kwd);                   /* TYPE-ERROR slot DATUM */
      pushSTACK(O(type_socket_option)); /* TYPE-ERROR slot EXPECTED-TYPE */
      pushSTACK(O(type_socket_option));
      pushSTACK(kwd); pushSTACK(S(socket_options));
      fehler(type_error,GETTEXT("~: argument ~ should be ~."));
    }
    end_system_call();
  }
  STACK_to_mv(retval_count);
  skipSTACK(argcount+1);
}

# (SOCKET-STREAM-PORT socket-stream)
LISPFUNN(socket_stream_port,1) {
  var object stream = test_socket_stream(STACK_0,false);
  VALUES1(TheStream(stream)->strm_socket_port);
  skipSTACK(1);
}

# (SOCKET-STREAM-HOST socket-stream)
LISPFUNN(socket_stream_host,1) {
  var object stream = test_socket_stream(STACK_0,false);
  VALUES1(TheStream(stream)->strm_socket_host);
  skipSTACK(1);
}

typedef host_data_t * host_data_fetcher_t (SOCKET, host_data_t *, bool);
extern host_data_fetcher_t socket_getpeername, socket_getlocalname;

local void publish_host_data (host_data_fetcher_t* func) {
  var bool resolve_p = missingp(STACK_0);
  skipSTACK(1);
  var object stream = test_socket_stream(popSTACK(),true);
  var SOCKET sk = SocketChannel(stream);
  var host_data_t hd;
  var object hostname;
    begin_system_call();
    if ((*func)(sk,&hd,resolve_p) == NULL) { SOCK_error(); }
    end_system_call();
    if (hd.truename[0] == '\0') {
      hostname = asciz_to_string(hd.hostname,O(misc_encoding));
    } else {
      var DYNAMIC_ARRAY(tmp_str,char,strlen(hd.truename)+2+strlen(hd.hostname)+1+1);
      strcpy(tmp_str, hd.hostname);
      strcat(tmp_str, " (");
      strcat(tmp_str, hd.truename);
      strcat(tmp_str, ")");
      hostname = asciz_to_string(tmp_str,O(misc_encoding));
      FREE_DYNAMIC_ARRAY(tmp_str);
    }
    VALUES2(hostname, fixnum(hd.port));
  }

# (SOCKET-STREAM-PEER socket-stream [do-not-resolve-p])
LISPFUN(socket_stream_peer,1,1,norest,nokey,0,NIL) {
  publish_host_data (&socket_getpeername);
}

# (SOCKET-STREAM-LOCAL socket-stream [do-not-resolve-p])
LISPFUN(socket_stream_local,1,1,norest,nokey,0,NIL) {
  publish_host_data (&socket_getlocalname);
}

#ifndef WIN32_NATIVE

# (SOCKET-STREAM-HANDLE socket-stream)
LISPFUNN(socket_stream_handle,1) {
  var object stream = test_socket_stream(STACK_0,true);
  VALUES1(fixnum(SocketChannel(stream)));
  skipSTACK(1);
}

#endif

#ifdef HAVE_SHUTDOWN

# close a socket stream using shutdown(2)
# if DIRECTION is not :IO, CLOSE is also required!
# (SOCKET-STREAM-SHUTDOWN socket direction)
LISPFUNN(socket_stream_shutdown,2) {
  var direction_t dir = check_direction(popSTACK());
  var object socket = test_socket_stream(STACK_0,false);
  var int shutdown_how = -1;
  var bool rd_p = ((TheStream(STACK_0)->strmflags & strmflags_rd_B) != 0);
  var bool wr_p = ((TheStream(STACK_0)->strmflags & strmflags_wr_B) != 0);
  switch (dir) {
    case DIRECTION_PROBE: # INPUT/OUTPUT/IO
      if (rd_p) {
        if (wr_p) value1 = S(Kio);
        else value1 = S(Kinput);
      } else {
        if (wr_p) value1 = S(Koutput);
        else value1 = NIL;
      }
      goto done;
    case DIRECTION_INPUT_IMMUTABLE: case DIRECTION_INPUT:
      if (!wr_p) { # already not writable => CLOSE
        TheStream(STACK_0)->strmflags ^= strmflags_wr_B; # restore :IO
        funcall(L(built_in_stream_close),1); return;
      } else if (!rd_p) { # not readable => done
        value1 = NIL; goto done;
      } else {
        shutdown_how = SHUT_RD;
        TheStream(STACK_0)->strmflags &= ~strmflags_rd_B;
      }
      break;
    case DIRECTION_OUTPUT:
      if (!rd_p) { # already not readable => CLOSE
        TheStream(STACK_0)->strmflags ^= strmflags_rd_B; # restore :IO
        funcall(L(built_in_stream_close),1); return;
      } else if (!wr_p) { # not writable => done
        value1 = NIL; goto done;
      } else {
        shutdown_how = SHUT_WR;
        TheStream(STACK_0)->strmflags &= ~strmflags_wr_B;
      }
      break;
    case DIRECTION_IO: funcall(L(built_in_stream_close),1); return;
  }
  # still open in both directions
  switch (TheStream(STACK_0)->strmtype) {
    case strmtype_twoway_socket:
      if (dir == DIRECTION_OUTPUT) {
        STACK_0 = TheStream(STACK_0)->strm_twoway_socket_output;
        TheStream(STACK_0)->strmflags &= ~strmflags_wr_B;
      } else { # DIRECTION_INPUT || DIRECTION_INPUT_IMMUTABLE
        STACK_0 = TheStream(STACK_0)->strm_twoway_socket_input;
        TheStream(STACK_0)->strmflags &= ~strmflags_rd_B;
      } /*FALLTHROUGH*/
    case strmtype_socket:
      if (ChannelStream_buffered(STACK_0))
        buffered_flush_everything(STACK_0);
      begin_system_call();
      if (shutdown((SOCKET)(ChannelStream_ihandle(STACK_0)),shutdown_how))
        { SOCK_error(); }
      end_system_call();
      break;
    default: NOTREACHED;
  }
 done:
  skipSTACK(1);
  mv_count = 1;
}
#endif

#endif # SOCKET_STREAMS


# Streams in general
# ==================

# UP: Return the default value for *terminal-io*.
# can trigger GC
local object make_terminal_io (void) {
  # If stdin or stdout is a file, use a buffered stream instead of an
  # unbuffered terminal stream. For the ud2cd program used as filter,
  # this reduces the runtime on Solaris from 165 sec to 47 sec.
  var bool stdin_file = regular_handle_p(stdin_handle);
  var bool stdout_file = regular_handle_p(stdout_handle);
  if (stdin_file || stdout_file) {
    var object stream;
    # Allocate stream for stdin:
    if (stdin_file) {
     #ifdef UNIX
      pushSTACK(ascii_to_string("/dev/fd/0")); funcall(L(pathname),1);
      pushSTACK(value1);
     #else
      pushSTACK(NIL);
     #endif
      pushSTACK(NIL);
      pushSTACK(S(Kdefault));
      pushSTACK(S(Kdefault)); # not O(terminal-encoding), since it's a file
      pushSTACK(S(character));
      pushSTACK(allocate_handle(stdin_handle));
      stream = make_file_stream(DIRECTION_INPUT,false,false);
    } else {
      stream = make_terminal_stream();
    }
    pushSTACK(stream);
    # Allocate stream for stdout:
    if (stdout_file) {
     #ifdef UNIX
      pushSTACK(ascii_to_string("/dev/fd/1")); funcall(L(pathname),1);
      pushSTACK(value1);
     #else
      pushSTACK(NIL);
     #endif
      pushSTACK(NIL);
      pushSTACK(S(Kdefault));
      pushSTACK(S(Kdefault)); # not O(terminal-encoding), since it's a file
      pushSTACK(S(character));
      pushSTACK(allocate_handle(stdout_handle));
      stream = make_file_stream(DIRECTION_OUTPUT,false,false);
    } else {
      stream = make_terminal_stream();
    }
    # Build a two-way-stream:
    return make_twoway_stream(popSTACK(),stream);
  }
  return make_terminal_stream();
}

#ifdef GNU_READLINE
local int next_line_virtual(int,int);
local int previous_line_virtual(int,int);
local int get_col() {
  int col=rl_point;
  while(col && rl_line_buffer[col]!='\n') col--;
  return rl_point - col;
}
local int next_line_virtual (int count, int key) {
  if (count > 0) {
    int col = get_col(),len=strlen(rl_line_buffer);
    while (count--) {
      while(rl_point<len && rl_line_buffer[rl_point]!='\n') rl_point++;
      if (rl_point<len) rl_point++;
    }
    rl_point += col-1;
    if (rl_point>=len) rl_point = len-1;
  } else if (count < 0)
    return previous_line_virtual(-count,key);
  # else rl_variable_dumper(1);
  return 0;
}
local int previous_line_virtual (int count, int key) {
  if (count > 0) {
    int col = get_col();
    do {
      while(rl_point && rl_line_buffer[rl_point]!='\n') rl_point--;
      if (rl_point) rl_point--;
      else return 0;
    } while (count--);
    rl_point += col+1;
  } else if (count < 0)
    return next_line_virtual(-count,key);
  # else rl_variable_dumper(1);
  return 0;
}
#endif

# init *STANDARD-INPUT* & *STANDARD-OUTPUT* from *TERMINAL-IO*
# can trigger GC
#define init_standard_io(direction)                                     \
  local object init_standard_##direction (object syn_str) {             \
    var object tio_s = Symbol_value(S(terminal_io));                    \
    define_variable(S(standard_##direction),                            \
                    (stream_twoway_p(tio_s)                             \
                     && !terminal_stream_p                              \
                           (TheStream(tio_s)->strm_twoway_##direction)) \
                    ? TheStream(tio_s)->strm_twoway_##direction         \
                    : !nullp(syn_str) ? syn_str                         \
                    : make_synonym_stream(S(terminal_io)));             \
    return Symbol_value(S(standard_##direction));                       \
  }

init_standard_io(input)
init_standard_io(output)
#undef init_standard_io

# UP: Initializes the Stream-Variables.
# init_streamvars(unixyp);
# > unixyp: Flag, if *error-output* shall be initialized
#            the Unix-Way (differing from the Standard)
# can trigger GC
global void init_streamvars (bool unixyp) {
  #ifdef GNU_READLINE
  begin_call();
  # rl_readline_name = "CLisp";
  if (ilisp_mode) {
    # Simulate the following instruction in .inputrc:
    #   Control-i: self-insert
    rl_bind_key(CTRL('I'),rl_named_function("self-insert"));
  }
  rl_attempted_completion_function = &lisp_completion_matches;
  rl_completion_entry_function = &lisp_completion_more;
  rl_variable_bind("comment-begin",";");
  rl_variable_bind("blink-matching-paren","on");
  # rl_set_paren_blink_timeout(1000000); # = 1 sec [default 0.5 sec]
  rl_add_defun("next-line-virtual",&next_line_virtual,META('n'));
  rl_add_defun("previous-line-virtual",&previous_line_virtual,META('p'));
  end_call();
  #endif
  {
    var object stream = make_terminal_io();
    define_variable(S(terminal_io),stream);  # *TERMINAL-IO*
  }
  {
    var object stream = make_synonym_stream(S(terminal_io));
    define_variable(S(query_io),stream);         # *QUERY-IO*
    define_variable(S(debug_io),stream);         # *DEBUG-IO*
    define_variable(S(trace_output),stream);     # *TRACE-OUTPUT*
    init_standard_input(stream);                 # *STANDARD-INPUT*
    init_standard_output(stream);                # *STANDARD-OUTPUT*
    #ifdef UNIX
    if (unixyp) {
      # Use another Stream for *ERROR-OUTPUT* . The file-name
      # does not matter, /dev/fd/2 does not exist everywhere, either.
      pushSTACK(ascii_to_string("/dev/fd/2")); funcall(L(pathname),1);
      pushSTACK(value1);
      pushSTACK(test_external_format_arg(S(Kunix)));
      pushSTACK(S(character));
      pushSTACK(allocate_handle(2));
      var decoded_el_t eltype = { eltype_ch, 0 };
      stream = make_unbuffered_stream(strmtype_file,DIRECTION_OUTPUT,
                                      &eltype,false);
      UnbufferedHandleStream_output_init(stream);
      ChannelStreamLow_close(stream) = &low_close_handle;
      TheStream(stream)->strm_file_name =
        TheStream(stream)->strm_file_truename = popSTACK();
    } else
    #endif
      stream = Symbol_value(S(standard_output));
    define_variable(S(error_output),stream);     # *ERROR-OUTPUT*
  }
  #ifdef KEYBOARD
  # Initialize the *KEYBOARD-INPUT* stream. This can fail in some cases,
  # therefore we do it after the standard streams are in place, so that
  # the user will get a reasonable error message.
  #if defined(UNIX) || defined(RISCOS)
  # Building the keyboard stream is a costly operation. Delay it
  # until we really need it.
  define_variable(S(keyboard_input),NIL);     # *KEYBOARD-INPUT*
  #else
  {
    var object stream = make_keyboard_stream();
    define_variable(S(keyboard_input),stream); # *KEYBOARD-INPUT*
  }
  #endif
  #endif
}

# Returns error-message, if the value of the symbol sym is not a stream.
local void fehler_value_stream (object sym) {
  # Possibly repair before the error-message
  # (initialized as in init_streamvars resp. init_pathnames):
  var object stream;
  pushSTACK(sym); # save sym
  #ifdef KEYBOARD
  if (eq(sym,S(keyboard_input))) { # Keyboard-Stream as Default
    stream = make_keyboard_stream();
  } else
  #endif
  if (eq(sym,S(terminal_io))) {
    # Terminal-Stream as Default
    # (Use make_terminal_stream() here, not make_terminal_io(), because
    # that might have been a file stream and got closed when the disk
    # became full.)
    stream = make_terminal_stream();
  } else if (eq(sym,S(query_io)) || eq(sym,S(debug_io))
             || eq(sym,S(error_output)) || eq(sym,S(trace_output))) {
    # Synonym-Stream to *TERMINAL-IO* as Default
    stream = make_synonym_stream(S(terminal_io));
  } else if (eq(sym,S(standard_input))) {
    stream = init_standard_input(NIL);
  } else if (eq(sym,S(standard_output))) {
    stream = init_standard_output(NIL);
  # } else if (eq(sym,S(error_output))) {
  #   stream = init_error_output(NIL);
  } else {
    # other Symbol, not fixable -> instant error-message:
    pushSTACK(Symbol_value(sym)); # TYPE-ERROR slot DATUM
    pushSTACK(S(stream));         # TYPE-ERROR slot EXPECTED-TYPE
    pushSTACK(Symbol_value(sym)); # variable value
    pushSTACK(sym); # variable
    if (!streamp(Symbol_value(sym))) {
      fehler(type_error,GETTEXT("The value of ~ is not a stream: ~"));
    } else {
      fehler(type_error,GETTEXT("The value of ~ is not an appropriate stream: ~"));
    }
  }
  sym = popSTACK();
  # repair finished: stream is the new value of sym.
  var object oldvalue = Symbol_value(sym);
  Symbol_value(sym) = stream;
  pushSTACK(oldvalue);  # TYPE-ERROR slot DATUM
  pushSTACK(S(stream)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(stream); # new variable value
  pushSTACK(oldvalue); # old variable value
  pushSTACK(sym); # Variable
  fehler(type_error,GETTEXT("The value of ~ was not an open stream: ~. It has been changed to ~."));
}

#ifdef GNU_READLINE
# Auxiliary functions for the GNU ReadLine Library:
nonreturning_function(local, rl_memory_abort, (void)) {
  # when there is no more memory for the ReadLine
  # drop it and replace the *TERMINAL-IO* with another
  # terminal-stream without ReadLine
  rl_deprep_terminal(); # cancel all ioctl()s
  begin_callback(); # reset STACK to a reasonable value
  rl_gnu_readline_p = false;
  Symbol_value(S(terminal_io)) = make_terminal_stream();
  fehler(storage_condition,GETTEXT("readline library: out of memory."));
}

local char* xmalloc (int count) {
  char* tmp = (char*)malloc(count);
  if (tmp) return tmp;
  else     rl_memory_abort();
}

local char* xrealloc (void* ptr, int count) {
  char* tmp = (ptr==NULL ? (char*)malloc(count) :
               (char*)realloc((char*)ptr,count));
  if (tmp) return tmp;
  else     rl_memory_abort();
}
#endif

# (SYS::BUILT-IN-STREAM-OPEN-P stream)
LISPFUNN(built_in_stream_open_p,1) {
  var object stream = popSTACK();
  check_builtin_stream(stream);
  if (TheStream(stream)->strmflags & strmflags_open_B) { # Stream open?
    VALUES1(T);
  } else {
    VALUES1(NIL);
  }
}

# (INPUT-STREAM-P stream), CLTL p. 332, CLtL2 p. 505
LISPFUNN(input_stream_p,1) {
  var object stream = popSTACK();
  check_stream(stream);
  if (input_stream_p(stream)) {
    VALUES1(T);
  } else {
    VALUES1(NIL);
  }
}

# (OUTPUT-STREAM-P stream), CLTL p. 332, CLtL2 p. 505
LISPFUNN(output_stream_p,1) {
  var object stream = popSTACK();
  check_stream(stream);
  if (output_stream_p(stream)) {
    VALUES1(T);
  } else {
    VALUES1(NIL);
  }
}

# (SYS::STREAM-ELEMENT-TYPE-EQ T0 T1)
# this function is used for `stream-element-type' type merging
# it does not handle types not seen as stream element types
# it should be reasonably fast, so we are not using `canonicalize-type'
# (defun stream-element-type-eq (t0 t1)
#   (or (eq t0 t1)
#       (and (consp t0) (consp t1)
#            (eq (car t0) (car t1))
#            (member (car t0) '(unsigned-byte signed-byte))
#            (eql (cadr t0) (cadr t1)))))
LISPFUNN(stream_element_type_eq,2) {
  object t0 = popSTACK();
  object t1 = popSTACK();
  if (eq(t0,t1)
      || (consp(t0) && consp(t1) && eq(Car(t0),Car(t1))
          && (eq(Car(t0),S(unsigned_byte)) || eq(Car(t0),S(signed_byte)))
          && consp(Cdr(t0)) && consp(Cdr(t1))
          && eql(Car(Cdr(t0)),Car(Cdr(t1))))) {
    VALUES1(T);
  } else {
    VALUES1(NIL);
  }
}

# (SYS::BUILT-IN-STREAM-ELEMENT-TYPE stream)
# returns CHARACTER or INTEGER or T
# or (more specific) (UNSIGNED-BYTE n) or (SIGNED-BYTE n).
LISPFUNN(built_in_stream_element_type,1) {
  var object stream = popSTACK();
  check_builtin_stream(stream);
  var object eltype;
 start:
  switch (TheStream(stream)->strmtype) {
    case strmtype_synonym: # Synonym-Stream: follow further
      resolve_as_synonym(stream);
      if (builtin_stream_p(stream))
        goto start;
      else { # Call (STREAM-ELEMENT-TYPE stream):
        pushSTACK(stream); funcall(S(stream_element_type),1);
      }
      break;
    # first the stream-types with restricted element-types:
    case strmtype_str_in:
    case strmtype_str_out:
    case strmtype_str_push:
    case strmtype_pphelp:
    case strmtype_buff_in:
    case strmtype_buff_out:
      # CHARACTER
      eltype = S(character); break;
   #ifdef KEYBOARD
    case strmtype_keyboard:
      eltype = T;
      break;
   #endif
    case strmtype_terminal:
   #ifdef SCREEN
    case strmtype_window:
   #endif
   #ifdef PRINTER
    case strmtype_printer:
   #endif
      # CHARACTER
      eltype = S(character); break;
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
   #endif
      # CHARACTER or ([UN]SIGNED-BYTE n)
      eltype = TheStream(stream)->strm_eltype; break;
   #ifdef SOCKET_STREAMS
    case strmtype_twoway_socket:
      # CHARACTER or ([UN]SIGNED-BYTE n)
      stream = TheStream(stream)->strm_twoway_socket_input;
      eltype = TheStream(stream)->strm_eltype; break;
   #endif
    case strmtype_twoway:
    case strmtype_echo:
      # (let ((itype (stream-element-type (two-way-input-stream stream)))
      #       (otype (stream-element-type (two-way-output-stream stream))))
      #   ; Simplify `(OR ,itype ,otype)
      #   (cond ((eq itype 'NIL) otype)
      #         ((eq otype 'NIL) itype)
      #         ((eq itype otype) itype)
      #         (t
      #           (cons 'OR
      #             (remove-duplicates
      #               (append
      #                 (if (and (consp itype) (eq (car itype) 'OR))
      #                   (cdr itype)
      #                   (list itype)
      #                 )
      #                 (if (and (consp otype) (eq (car otype) 'OR))
      #                   (cdr otype)
      #                   (list otype)
      #                 ))
      # ) )     ) ) ) )
      {
        pushSTACK(TheStream(stream)->strm_twoway_input);
        pushSTACK(TheStream(stream)->strm_twoway_output);
        pushSTACK(STACK_1); funcall(S(stream_element_type),1);
        STACK_1 = value1; funcall(S(stream_element_type),1);
        pushSTACK(value1);
        var object itype = STACK_1;
        var object otype = STACK_0;
        if (nullp(itype)) {
          eltype = otype;
          skipSTACK(2);
        } else if (nullp(otype) || eq(itype,otype)) {
          eltype = itype;
          skipSTACK(2);
        } else {
          var object tmp;
          if (consp(itype) && eq(Car(itype),S(or)))
            tmp = Cdr(itype);
          else {
            tmp = allocate_cons();
            Car(tmp) = STACK_1;
            otype = STACK_0;
          }
          STACK_1 = tmp;
          if (consp(otype) && eq(Car(otype),S(or)))
            tmp = Cdr(otype);
          else {
            tmp = allocate_cons();
            Car(tmp) = STACK_0;
          }
          STACK_0 = tmp;
          funcall(L(append),2);
          pushSTACK(value1); pushSTACK(S(Ktest));
          pushSTACK(S(stream_element_type_eq));
          funcall(L(remove_duplicates),3);
          pushSTACK(value1);
          eltype = allocate_cons();
          Car(eltype) = S(or); Cdr(eltype) = popSTACK();
        }
      }
      break;
      # then the general streams:
   #ifdef GENERIC_STREAMS
    case strmtype_generic:
   #endif
    default: {
      var uintB flags = TheStream(stream)->strmflags;
      if (flags & strmflags_by_B) {
        if (flags & strmflags_ch_B) { # (OR CHARACTER INTEGER)
          pushSTACK(S(or)); pushSTACK(S(character)); pushSTACK(S(integer));
          eltype = listof(3);
        } else eltype = S(integer);
      } else
        if (flags & strmflags_ch_B) eltype = S(character);
        else eltype = NIL;
    }
      break;
  }
  VALUES1(eltype);
}

# UP: reset the stream for the eltype and flush out the missing LF.
# IF the stream is unbuffered, AND ignore_next_LF is true, THEN
# this can block (we will try to read the next LF) and trigger GC
# The stream must be a "basic" (non-composite) stream: no two-way &c
# can trigger GC
local object stream_reset_eltype (object stream, decoded_el_t* eltype_) {
  if (ChannelStream_buffered(stream)) {
    fill_pseudofuns_buffered(stream,eltype_);
  } else {
    if (UnbufferedStream_ignore_next_LF(stream)
        && eq(TheStream(stream)->strm_eltype,S(character))) {
      pushSTACK(stream);
      UnbufferedStream_ignore_next_LF(stream) = false; # do not skip LF!
      var object ch = read_char(&STACK_0);
      if (!eq(ch,eof_value) && !chareq(char_code(ch),ascii(LF)))
        unread_char(&STACK_0,ch);
      stream = popSTACK();
    }
    fill_pseudofuns_unbuffered(stream,eltype_);
  }
  return stream;
}

# (SYSTEM::BUILT-IN-STREAM-SET-ELEMENT-TYPE stream element-type)
LISPFUNN(built_in_stream_set_element_type,2) {
  var object stream = STACK_1;
  check_builtin_stream(stream);
  var decoded_el_t eltype;
  test_eltype_arg(&STACK_0,&eltype);
  pushSTACK(canon_eltype(&eltype));
  # Stack contents: stream, element-type, canon-element-type.
  stream = STACK_2;
 start:
  switch (TheStream(stream)->strmtype) {
    case strmtype_synonym: # Synonym-Stream: follow further
      resolve_as_synonym(stream);
      if (builtin_stream_p(stream))
        goto start;
      else { # Call ((SETF STREAM-ELEMENT-TYPE) element-type stream):
        pushSTACK(STACK_1); pushSTACK(stream);
        funcall(O(setf_stream_element_type),2);
      }
      break;
    case strmtype_file:
   #ifdef PIPES
    case strmtype_pipe_in:
    case strmtype_pipe_out:
   #endif
   #ifdef SOCKET_STREAMS
    case strmtype_socket:
   #endif
      if (!equal(STACK_0,TheStream(stream)->strm_eltype)) {# nothing to change?
        # Check eltype.
        if (!ChannelStream_buffered(stream))
          check_unbuffered_eltype(&eltype);
        # The FILE-POSITION return value is constrained by CLHS to
        #   - be an integer,
        #   - represent a position into the file (and therefore be
        #     independent of the stream's current element type),
        #   - increment by 1 when READ-BYTE or WRITE-BYTE is called.
        # In order to achieve these constraints altogether, we allow
        # switching only (UNSIGNED-BYTE n) and (SIGNED-BYTE n) with
        # the same n, and between ([UN]SIGNED-BYTE 8) and CHARACTER.
        # Reading (UNSIGNED-BYTE 8) and (UNSIGNED-BYTE 16) and
        # (UNSIGNED-BYTE 32) values from the same stream in succession
        # can be achieved through READ-INTEGER and WRITE-INTEGER.
        if ((ChannelStream_bitsize(stream) > 0 ?
             ChannelStream_bitsize(stream) : 8)
            != (eltype.size > 0 ? eltype.size : 8)) {
          # canon-element-type in STACK_0.
          pushSTACK(TheStream(stream)->strm_eltype);
          pushSTACK(stream);
          pushSTACK(S(Kelement_type));
          pushSTACK(O(setf_stream_element_type));
          fehler(error,
                 GETTEXT("~: The ~ of ~ cannot be changed from ~ to ~."));
        }
        # Transform the lastchar back, if possible.
        if (TheStream(stream)->strmflags & strmflags_open_B) # stream open?
          if (eltype.size > 0)
            # New element type is an integer type.
            if (ChannelStream_bitsize(stream) == 0) {
              # Old element type was CHARACTER.
              # Transform the lastchar back to bytes.
              if (charp(TheStream(stream)->strm_rd_ch_last)
                  && (TheStream(stream)->strmflags & strmflags_unread_B)) {
                # FIXME: This should take into account the encoding.
                var uintB b = as_cint(char_code(TheStream(stream)->strm_rd_ch_last));
                if (ChannelStream_buffered(stream)) {
                  if ((BufferedStream_index(stream) > 0)
                      && (BufferedStream_position(stream) > 0)
                      && (*BufferedStream_buffer_address
                          (stream,BufferedStream_index(stream)-1) == b)) {
                    # decrement index and position:
                    BufferedStream_index(stream) -= 1;
                    BufferedStream_position(stream) -= 1;
                    TheStream(stream)->strm_rd_ch_last = NIL;
                    TheStream(stream)->strmflags &= ~strmflags_unread_B;
                  }
                } else {
                  if (UnbufferedStream_status(stream) == 0) {
                    UnbufferedStreamLow_push_byte(stream,b);
                    UnbufferedStream_ignore_next_LF(stream) = false;
                    TheStream(stream)->strm_rd_ch_last = NIL;
                    TheStream(stream)->strmflags &= ~strmflags_unread_B;
                  }
                }
              }
            }
        { # Actually change the stream's element type.
          var uintB flags = TheStream(stream)->strmflags;
          flags = (flags & ~strmflags_rdwr_B)
            | (flags & strmflags_rd_B ? strmflags_rd_B : 0)
            | (flags & strmflags_wr_B ? strmflags_wr_B : 0);
          ChannelStream_bitsize(stream) = eltype.size;
          if (eltype.kind == eltype_ch) {
            # New element type is CHARACTER.
            flags &= ~(strmflags_rdwr_B & ~strmflags_ch_B);
          } else {
            # New element type is an integer type.
            # allocate Bitbuffer:
            pushSTACK(stream);
            var object bitbuffer = allocate_bit_vector(Atype_Bit,eltype.size);
            stream = popSTACK();
            TheStream(stream)->strm_bitbuffer = bitbuffer;
            flags &= ~(strmflags_rdwr_B & ~strmflags_by_B);
          }
          TheStream(stream)->strmflags = flags;
        }
        stream = stream_reset_eltype(stream,&eltype);
        TheStream(stream)->strm_eltype = STACK_0;
      }
      break;
   #ifdef SOCKET_STREAMS
    case strmtype_twoway_socket:
      # Apply to the input and output side individually.
      pushSTACK(TheStream(STACK_2)->strm_twoway_socket_input); # stream
      pushSTACK(STACK_(0+1));
      funcall(L(built_in_stream_set_element_type),2);
      pushSTACK(TheStream(STACK_2)->strm_twoway_socket_output); # stream
      pushSTACK(STACK_(0+1));
      funcall(L(built_in_stream_set_element_type),2);
      break;
   #endif
    default:
      fehler_illegal_streamop(O(setf_stream_element_type),stream);
  }
  VALUES1(STACK_1);
  skipSTACK(3);
}

# (STREAM-EXTERNAL-FORMAT stream)
LISPFUNN(stream_external_format,1) {
  var object stream = popSTACK();
  check_stream(stream);
 start:
  if (builtin_stream_p(stream))
    switch (TheStream(stream)->strmtype) {
      case strmtype_synonym: # Synonym-Stream: follow further
        resolve_as_synonym(stream);
        goto start;
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
     #endif
        VALUES1(TheStream(stream)->strm_encoding); break;
      default:
        VALUES1(S(Kdefault)); break;
    }
  else
    VALUES1(S(Kdefault));
}

# (SYSTEM::SET-STREAM-EXTERNAL-FORMAT stream external-format [direction])
# direction can be :INPUT or :OUTPUT or NIL.
# If no direction is given, the operation is nonrecursive.
LISPFUN(set_stream_external_format,2,1,norest,nokey,0,NIL) {
  var object stream = check_stream(STACK_2);
  var object encoding = test_external_format_arg(STACK_1);
  var object direction = STACK_0;
 start:
  if (builtin_stream_p(stream))
    switch (TheStream(stream)->strmtype) {
      case strmtype_synonym: # Synonym-Stream: follow further
        resolve_as_synonym(stream);
        goto start;
      case strmtype_broad:
        if (eq(direction,S(Kinput)))
          goto done;
        if (eq(direction,S(Koutput))) { # Recurse.
          check_SP(); check_STACK();
          pushSTACK(TheStream(stream)->strm_broad_list);
          while (consp(STACK_0)) {
            pushSTACK(Car(STACK_0)); pushSTACK(STACK_(1+2));
            pushSTACK(STACK_(0+3)); C_set_stream_external_format();
            STACK_0 = Cdr(STACK_0);
          }
          skipSTACK(1);
          encoding = STACK_1;
          goto done;
        }
        goto unchangeable_external_format;
      case strmtype_concat:
        if (eq(direction,S(Kinput))) { # Recurse.
          check_SP(); check_STACK();
          pushSTACK(TheStream(stream)->strm_concat_totallist);
          while (consp(STACK_0)) {
            pushSTACK(Car(STACK_0)); pushSTACK(STACK_(1+2));
            pushSTACK(STACK_(0+3)); C_set_stream_external_format();
            STACK_0 = Cdr(STACK_0);
          }
          skipSTACK(1);
          encoding = STACK_1;
          goto done;
        }
        if (eq(direction,S(Koutput)))
          goto done;
        goto unchangeable_external_format;
      case strmtype_twoway:
      case strmtype_echo:
        if (eq(direction,S(Kinput))) { # Recurse.
          stream = TheStream(stream)->strm_twoway_input; goto start;
        }
        if (eq(direction,S(Koutput))) { # Recurse.
          stream = TheStream(stream)->strm_twoway_output; goto start;
        }
        goto unchangeable_external_format;
      case strmtype_str_in:
      case strmtype_str_out:
      case strmtype_str_push:
      case strmtype_pphelp:
      case strmtype_buff_in:
      case strmtype_buff_out:
     #ifdef GENERIC_STREAMS
      case strmtype_generic:
     #endif
        if (eq(direction,S(Kinput)) || eq(direction,S(Koutput)))
          goto done;
        goto unchangeable_external_format;
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
     #endif
        {
          var decoded_el_t eltype;
          test_eltype_arg(&TheStream(stream)->strm_eltype,&eltype); # no GC here!
          ChannelStream_fini(stream);
          stream = stream_reset_eltype(stream,&eltype);
          value1 = TheStream(stream)->strm_encoding = encoding;
          ChannelStream_init(stream);
        }
        break;
     #ifdef SOCKET_STREAMS
      case strmtype_twoway_socket:
        if (eq(direction,S(Kinput))) { # Recurse.
          stream = TheStream(stream)->strm_twoway_input; goto start;
        }
        if (eq(direction,S(Koutput))) { # Recurse.
          stream = TheStream(stream)->strm_twoway_output; goto start;
        }
        # Recurse twice.
        pushSTACK(TheStream(stream)->strm_twoway_output);
        pushSTACK(STACK_(1+1)); pushSTACK(STACK_(0+2));
        pushSTACK(TheStream(stream)->strm_twoway_input);
        pushSTACK(STACK_(1+4)); pushSTACK(STACK_(0+5));
        C_set_stream_external_format();
        C_set_stream_external_format();
        encoding = STACK_1;
        goto done;
     #endif
      default:
        if (eq(direction,S(Kinput)))
          if ((TheStream(stream)->strmflags & strmflags_rd_B) == 0)
            goto done;
        if (eq(direction,S(Koutput)))
          if ((TheStream(stream)->strmflags & strmflags_wr_B) == 0)
            goto done;
    unchangeable_external_format:
        if (!eq(encoding,S(Kdefault)))
          fehler_illegal_streamop(S(set_stream_external_format),stream);
    done:
        VALUES1(encoding); break;
    }
  else {
    if (eq(direction,S(Kinput)))
      if (!instanceof(stream,O(class_fundamental_input_stream)))
        goto done2;
    if (eq(direction,S(Koutput)))
      if (!instanceof(stream,O(class_fundamental_output_stream)))
        goto done2;
    if (!eq(encoding,S(Kdefault)))
      fehler_illegal_streamop(S(set_stream_external_format),stream);
  done2:
    VALUES1(encoding);
  }
  skipSTACK(3);
}

#ifdef UNICODE

# Changes a terminal stream's external format.
# > stream: a stream
# > encoding: an encoding
# can trigger GC
global void set_terminalstream_external_format (object stream,
                                                object encoding) {
  if (builtin_stream_p(stream)
      && TheStream(stream)->strmtype == strmtype_terminal
      && eq(TheStream(stream)->strm_encoding,O(terminal_encoding))) {
    # This is the only place which is allowed to modify the terminal
    # stream's encoding.
    # The terminal stream's end-of-line coding is hardwired, therefore we
    # don't need to do the equivalent of fill_pseudofuns_unbuffered here.
    ChannelStream_fini(stream);
    TheStream(stream)->strm_encoding = encoding;
    ChannelStream_init(stream);
  } else {
    pushSTACK(stream); pushSTACK(encoding);
    funcall(L(set_stream_external_format),2);
  }
}

#endif

# UP: Determines, if a Stream is "interactive", i.e. if Input of Stream
# will presumably depend on a previously printed prompt.
# interactive_stream_p(stream)
# > stream: Stream
# NB: Relation between clear_input, listen, interactive_stream_p:
#   If ls_wait_p(listen_char(stream)) is true after clear_input(stream)
#   (i.e. no more character available and no EOF), then
#   interactive_stream_p(stream) is true.
#   (Because then stream is effectively a Keyboard-Stream, Terminal-Stream,
#   Handle-Stream with !regular_handle_p(ihandle), Pipe-Input-Stream,
#   X11-Socket-Stream, Socket-Stream or Generic-Stream.)
#   (For a Concatenated-Stream, which is at the end of a non-interactive
#   Sub-Stream and where the next Sub-Stream is non-interactive, this is
#   possibly not valid. But this can be caught by inserting a
#   listen_char(stream) before the query.)
#   But not vice-versa: For Streams of type strmtype_pipe_in,
#   strmtype_x11socket, strmtype_socket (that comply with
#   interactive_stream_p(stream)) clear_input(stream) does nothing,
#   and listen_char(stream) can return ls_avail.
global bool interactive_stream_p (object stream) {
 start:
  if (!builtin_stream_p(stream)) # Assume the worst.
    return true;
  if ((TheStream(stream)->strmflags & strmflags_rd_B) == 0)
    # Stream is closed for Input
    return false;
  # Stream open
  switch (TheStream(stream)->strmtype) {
    case strmtype_synonym: # Synonym-Stream: follow further
      resolve_as_synonym(stream);
      goto start;
    case strmtype_concat:
      # Here one could call listen_char(stream) in order to ignore Streams,
      # that arrived at EOF. But it is no good for
      # interactive_stream_p to do system-calls and I/O.??
      # Query the first of the streams:
      {
        var object streamlist = TheStream(stream)->strm_concat_list;
        if (consp(streamlist)) {
          stream = Car(streamlist);
          goto start;
        } else
          return false;
      }
    case strmtype_twoway:
    case strmtype_echo:
      # Two-Way-Stream or Echo-Stream: look at Input-Stream
      stream = TheStream(stream)->strm_twoway_input;
      goto start;
    case strmtype_str_in:
      return false;
    case strmtype_buff_in:
    #ifdef GENERIC_STREAMS
    case strmtype_generic:
    #endif
      return true;
    #if !defined(NEXTAPP)
    case strmtype_terminal:
    #endif
    case strmtype_file:
      if (ChannelStream_buffered(stream))
        # Buffered file streams are not considered to be interactive.
        return false;
      if (nullp(TheStream(stream)->strm_isatty))
        # regular files are for sure not interactive.
        if (regular_handle_p(TheHandle(TheStream(stream)->strm_ichannel)))
          return false;
    #ifdef KEYBOARD
    case strmtype_keyboard:
    #endif
    #if defined(NEXTAPP)
    case strmtype_terminal:
    #endif
    #ifdef PIPES
    case strmtype_pipe_in:
    #endif
    #ifdef X11SOCKETS
    case strmtype_x11socket:
    #endif
    #ifdef SOCKET_STREAMS
    case strmtype_socket:
    case strmtype_twoway_socket:
    #endif
      return true;
    default:
      return false;
  }
}

# (INTERACTIVE-STREAM-P stream), CLTL2 p. 507/508
# determines, if stream is interactive.
LISPFUNN(interactive_stream_p,1) {
  var object arg = popSTACK();
  check_stream(arg);
  VALUES_IF(interactive_stream_p(arg));
}

# UP: Closes a Stream.
# builtin_stream_close(&stream);
# > stream: Builtin-Stream
# < stream: Builtin-Stream
# can trigger GC
global void builtin_stream_close (const object* stream_) {
  var object stream = *stream_;
  if ((TheStream(stream)->strmflags & strmflags_open_B) == 0) # Stream already closed?
    return;
  # call type-specific routine (may trigger GC):
  switch (TheStream(stream)->strmtype) {
    case strmtype_synonym:
      close_synonym(stream); break; # X3J13_014 says: non-recursive
    case strmtype_broad:  break; # non-recursive
    case strmtype_concat: break; # non-recursive
    case strmtype_twoway: break; # non-recursive
    case strmtype_echo:   break; # non-recursive
    case strmtype_str_in:  close_str_in(stream); break;
    case strmtype_str_out:  break;
    case strmtype_str_push: break;
    case strmtype_pphelp:   break;
    case strmtype_buff_in:  close_buff_in(stream);  break;
    case strmtype_buff_out: close_buff_out(stream); break;
    #ifdef GENERIC_STREAMS
    case strmtype_generic: close_generic(stream); break;
    #endif
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
    #endif
      if (ChannelStream_buffered(stream)) {
        close_buffered(stream);
      } else {
        if (TheStream(stream)->strmflags & strmflags_wr_B)
          close_ochannel(stream);
        else
          close_ichannel(stream);
        # remove stream from the List of all open File-Streams:
        O(open_files) = deleteq(O(open_files),stream);
      }
      break;
    #ifdef SOCKET_STREAMS
    case strmtype_twoway_socket:
      # Close the two substreams, but close the handle once only.
      ChannelStreamLow_close(TheStream(stream)->strm_twoway_socket_input) =
        &low_close_socket_nop;
      pushSTACK(TheStream(stream)->strm_twoway_socket_input);
      pushSTACK(TheStream(stream)->strm_twoway_socket_output);
      builtin_stream_close(&STACK_1);
      builtin_stream_close(&STACK_0);
      skipSTACK(2);
      break;
    #endif
    #ifdef KEYBOARD
    case strmtype_keyboard: break;
    #endif
    case strmtype_terminal: break;
    #ifdef SCREEN
    case strmtype_window: close_window(stream); break;
    #endif
    #ifdef PRINTER_AMIGAOS
    case strmtype_printer: close_printer(stream); break;
    #endif
    default: NOTREACHED;
  }
  # enter dummys:
  close_dummys(*stream_);
}

# UP: Closes a list of open files.
# close_some_files(list);
# > list: list of open Builtin-Streams
# can trigger GC
global void close_some_files (object list) {
  pushSTACK(NIL); # dummy
  pushSTACK(list); # list
  while (mconsp(STACK_0)) {
    var object streamlist = STACK_0;
    STACK_0 = Cdr(streamlist); # remaining streams
    STACK_1 = Car(streamlist); # a stream from the list
    builtin_stream_close(&STACK_1); # close
  }
  skipSTACK(2);
}

# UP: Closes all open files.
# close_all_files();
# can trigger GC
global void close_all_files (void) {
  close_some_files(O(open_files)); # list of all open File-Streams
}

# UP: Declares all open File-Streams as closed.
# closed_all_files();
global void closed_all_files (void) {
  var object streamlist = O(open_files); # list of all open File-Streams
  while (consp(streamlist)) {
    var object stream = Car(streamlist); # a Stream from the list
    if (TheStream(stream)->strmtype == strmtype_file) { # File-Stream ?
      if (!nullp(BufferedStream_channel(stream))) # with Handle /= NIL ?
        # yes: Stream still open
        closed_buffered(stream);
    }
    close_dummys(stream);
    streamlist = Cdr(streamlist); # remaining Streams
  }
  O(open_files) = NIL; # no more open Files
}

# (SYS::BUILT-IN-STREAM-CLOSE stream :abort)
LISPFUN(built_in_stream_close,1,0,norest,key,1, (kw(abort)) ) {
  skipSTACK(1); # ignore the :ABORT argument
  var object stream = STACK_0; # Argument
  check_builtin_stream(stream); # must be a Stream
  builtin_stream_close(&STACK_0);
  skipSTACK(1);
  VALUES1(T); # T as result
}

# Reads a line of characters from a stream.
# read_line(&stream,&buffer)
# > stream: stream
# > buffer: a semi-simple string
# < stream: stream
# < buffer: contains the read characters, excluding the terminating #\Newline
# < result: true if EOF was seen before newline, else false
# can trigger GC
global bool read_line (const object* stream_, const object* buffer_) {
  var object stream = *stream_;
  if (builtin_stream_p(stream)) {
    if (TheStream(stream)->strmflags & strmflags_unread_B) { # Char after UNREAD ?
      # yes -> delete Flagbit and fetch last character:
      TheStream(stream)->strmflags &= ~strmflags_unread_B;
      var object ch = TheStream(stream)->strm_rd_ch_last;
      if (!charp(ch)) {
        subr_self = L(read_line); fehler_char(ch);
      }
      if (eq(ch,ascii_char(NL)))
        return false;
      ssstring_push_extend(*buffer_,char_code(ch));
      stream = *stream_;
    }
    var uintL oldfillptr = TheIarray(*buffer_)->dims[1];
    var bool eofp;
    switch (TheStream(stream)->strmtype) {
      case strmtype_synonym:
        eofp = read_line_synonym(stream,buffer_);
        break;
      case strmtype_twoway:
       #ifdef SOCKET_STREAMS
      case strmtype_twoway_socket:
      #endif
        eofp = read_line_twoway(stream,buffer_);
        break;
        # No special-casing of strmtype_echo, because the echo-stream may
        # be interactive, and delaying the echo in this case is undesirable.
      default:
        loop {
          var object ch = rd_ch(*stream_)(stream_); # read next character
          if (eq(ch,eof_value)) { # EOF ?
            eofp = true; break;
          }
          # else check for Character:
          if (!charp(ch)) {
            subr_self = L(read_line); fehler_char(ch);
          }
          if (eq(ch,ascii_char(NL))) { # NL -> End of Line
            eofp = false; break;
          }
          # write other Character in the Buffer:
          ssstring_push_extend(*buffer_,char_code(ch));
        }
        break;
    }
    stream = *stream_;
    TheStream(stream)->strm_rd_ch_last = (eofp ? eof_value : ascii_char(NL));
    TheStream(stream)->strmflags &= ~strmflags_unread_B;
    return eofp;
  } else {
    # Call the generic function (STREAM-READ-LINE stream):
    pushSTACK(stream); funcall(S(stream_read_line),1);
    if (!stringp(value1)) {
      pushSTACK(value1);    # TYPE-ERROR slot DATUM
      pushSTACK(S(string)); # TYPE-ERROR slot EXPECTED-TYPE
      pushSTACK(S(string));
      pushSTACK(S(stream_read_line));
      pushSTACK(value1);
      fehler(type_error,GETTEXT("Return value ~ of call to ~ is not a ~."));
    }
    var bool eofp = (mv_count >= 2 && !nullp(value2));
    # Add the line to the buffer:
    var uintL len;
    var uintL offset;
    var object srcstring = unpack_string_ro(value1,&len,&offset);
    ssstring_append_extend(*buffer_,srcstring,offset,len);
    return eofp;
  }
}

# UP: Determines, if a character is instantly available in the Stream stream.
# listen_char(stream)
# > stream: Stream
# < result:   ls_avail if a character is available,
#             ls_eof   if EOF is reached,
#             ls_wait  if no character is available, but not because of EOF
# can trigger GC
global signean listen_char (object stream) {
  if (builtin_stream_p(stream)) {
    check_SP(); check_STACK();
    if (TheStream(stream)->strmflags & strmflags_unread_B) { # Char after UNREAD ?
      return ls_avail; # yes -> available
    } else {
      # else branch according to Streamtype.
      # Each single routine may trigger GC. Except for Keyboard-Stream
      # or Terminal-Stream this is a pure EOF-Test.
      switch (TheStream(stream)->strmtype) {
        case strmtype_synonym:  return listen_char_synonym(stream);
        case strmtype_broad:    return ls_eof; # no READ-CHAR
        case strmtype_concat:   return listen_char_concat(stream);
        case strmtype_twoway:
        case strmtype_echo:
        #ifdef SOCKET_STREAMS
        case strmtype_twoway_socket:
        #endif
          return listen_char_twoway(stream);
        case strmtype_str_in:   return listen_char_str_in(stream);
        case strmtype_str_out:  return ls_eof; # no READ-CHAR
        case strmtype_str_push: return ls_eof; # no READ-CHAR
        case strmtype_pphelp:   return ls_eof; # no READ-CHAR
        case strmtype_buff_in:  return listen_char_buff_in(stream);
        case strmtype_buff_out: return ls_eof; # no READ-CHAR
        #ifdef GENERIC_STREAMS
        case strmtype_generic:  return listen_char_generic(stream);
        #endif
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
        #endif
          if (TheStream(stream)->strmflags & strmflags_rd_ch_B) {
            if (ChannelStream_buffered(stream))
              return listen_char_buffered(stream);
            else
              return listen_char_unbuffered(stream);
          } else {
            return ls_eof; # no READ-CHAR
          }
        #ifdef KEYBOARD
        case strmtype_keyboard: return listen_char_keyboard(stream);
        #endif
        case strmtype_terminal:
        #if defined(NEXTAPP)
          return listen_char_terminal(stream);
        #endif
        #if (defined(UNIX) && !defined(NEXTAPP)) || defined(MSDOS) || defined(AMIGAOS) || defined(RISCOS) || defined(WIN32_NATIVE)
          terminalcase(stream,
          { return listen_char_terminal1(stream); },
          { return listen_char_terminal2(stream); },
          { return listen_char_terminal3(stream); });
        #endif
          NOTREACHED;
        #ifdef SCREEN
        case strmtype_window:   return ls_eof; # no READ-CHAR
        #endif
        #ifdef PRINTER
        case strmtype_printer:  return ls_eof; # no READ-CHAR
        #endif
        default: # in general: query only for EOF
          if (TheStream(stream)->strmflags & strmflags_rd_ch_B) {
            pushSTACK(stream);
            var object nextchar = peek_char(&STACK_0);
            skipSTACK(1);
            if (eq(nextchar,eof_value))
              return ls_eof; # EOF reached
            else
              return ls_avail;
          } else {
            return ls_eof; # no READ-CHAR
          }
      }
    }
  } else {
    # Call the generic function (STREAM-READ-CHAR-WILL-HANG-P stream),
    # then call (PEEK-CHAR NIL STREAM):
    pushSTACK(stream);
    pushSTACK(stream); funcall(S(stream_read_char_will_hang_p),1);
    if (!nullp(value1)) {
      skipSTACK(1); return ls_wait;
    }
    var object nextchar = peek_char(&STACK_0);
    skipSTACK(1);
    if (eq(nextchar,eof_value))
      return ls_eof;
    else
      return ls_avail;
  }
}

# UP: Deletes already entered interactive Input from a Stream stream.
# clear_input(stream)
# > stream: Stream
# < result: true if Input was deleted
# can trigger GC
global bool clear_input (object stream) {
  check_SP(); check_STACK();
  pushSTACK(stream); # save Stream
  # call type-specific Routine (may trigger GC).
  if (builtin_stream_p(stream)) {
    # Only for Keyboard-Stream and Terminal-Stream something is done.
    var bool result;
    switch (TheStream(stream)->strmtype) {
      case strmtype_synonym:
        result = clear_input_synonym(stream); break;
      case strmtype_concat:
        result = clear_input_concat(stream); break;
      case strmtype_twoway:
      case strmtype_echo:
      #ifdef SOCKET_STREAMS
      case strmtype_twoway_socket:
      #endif
        result = clear_input_twoway(stream); break;
      case strmtype_buff_in:
        result = clear_input_buff_in(stream); break;
      #ifdef GENERIC_STREAMS
      case strmtype_generic:
        result = clear_input_generic(stream); break;
      #endif
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
      #endif
        if (TheStream(stream)->strmflags & strmflags_rd_ch_B
            && !ChannelStream_buffered(stream))
          result = clear_input_unbuffered(stream);
        else
          result = false;
        break;
      #ifdef KEYBOARD
      case strmtype_keyboard:
        result = clear_input_keyboard(stream); break;
      #endif
      case strmtype_terminal:
      #if defined(NEXTAPP)
        result = clear_input_terminal(stream);
      #endif
      #if (defined(UNIX) && !defined(NEXTAPP)) || defined(MSDOS) || defined(AMIGAOS) || defined(RISCOS) || defined(WIN32_NATIVE)
        terminalcase(stream,
        { result = clear_input_terminal1(stream); },
        { result = clear_input_terminal2(stream); },
        { result = clear_input_terminal3(stream); });
      #endif
        break;
      default:
        result = false; break;
    }
    stream = popSTACK();
    if (result) {
      # Input was deleted -> also the Lastchar has to be deleted.
      # An already seen EOF will be forgotten thereby.
      TheStream(stream)->strm_rd_ch_last = NIL;
      TheStream(stream)->strmflags &= ~strmflags_unread_B;
    }
    return result;
  } else {
    # Call the generic function (STREAM-CLEAR-INPUT stream):
    funcall(S(stream_clear_input),1);
    return !nullp(value1);
  }
}

# UP: Determines whether a stream has a byte immediately available.
# listen_byte(stream)
# > stream: a stream with element-type ([UN]SIGNED-BYTE 8)
# < result: ls_avail if a byte is available,
#           ls_eof   if EOF is reached,
#           ls_wait  if no byte is available, but not because of EOF
# can trigger GC
global signean listen_byte (object stream) {
  if (builtin_stream_p(stream)) {
    if (TheStream(stream)->strmflags & strmflags_rd_B) { # Input-Stream?
      check_SP(); check_STACK();
      # branch according to Streamtype.
      # Each single routine may trigger GC. Except for Sockets
      # this is a pure EOF-Test.
      switch (TheStream(stream)->strmtype) {
        case strmtype_synonym:  return listen_byte_synonym(stream);
        case strmtype_broad:    return ls_eof; # no READ-BYTE
        case strmtype_concat:   return listen_byte_concat(stream);
        case strmtype_twoway:
        case strmtype_echo:
        #ifdef SOCKET_STREAMS
        case strmtype_twoway_socket:
        #endif
          return listen_byte_twoway(stream);
        case strmtype_str_in:   return ls_eof; # no READ-BYTE
        case strmtype_str_out:  return ls_eof; # no READ-BYTE
        case strmtype_str_push: return ls_eof; # no READ-BYTE
        case strmtype_pphelp:   return ls_eof; # no READ-BYTE
        case strmtype_buff_in:  return ls_eof; # no READ-BYTE
        case strmtype_buff_out: return ls_eof; # no READ-BYTE
        #ifdef GENERIC_STREAMS
        case strmtype_generic:  return ls_eof; # unsupported functionality
        #endif
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
        #endif
          if (TheStream(stream)->strmflags & strmflags_rd_by_B) {
            # Only 8-bit element types. A general LISTEN-BYTE function
            # would be hairy (at least the case where you want to know
            # whether a multibyte integer is pending, and the stream is
            # unbuffered). For CLX and most applications, it is sufficient
            # to deal with a socket stream with 8-bit element types.
            if (ChannelStream_buffered(stream))
              return listen_byte_ia8_buffered(stream);
            else
              return listen_byte_ia8_unbuffered(stream);
          } else {
            return ls_eof; # no READ-BYTE
          }
        #ifdef KEYBOARD
        case strmtype_keyboard: return ls_eof; # no READ-BYTE
        #endif
        case strmtype_terminal: return ls_eof; # no READ-BYTE
        #ifdef SCREEN
        case strmtype_window:   return ls_eof; # no READ-BYTE
        #endif
        #ifdef PRINTER
        case strmtype_printer:  return ls_eof; # no READ-BYTE
        #endif
        default: NOTREACHED;
      }
    } else {
      return ls_eof; # no READ-BYTE
    }
  } else { # Call the generic function (STREAM-READ-BYTE-LOOKAHEAD stream):
    pushSTACK(stream); funcall(S(stream_read_byte_lookahead),1);
    if (nullp(value1))
      return ls_wait;
    else if (eq(value1,S(Keof)))
      return ls_eof;
    else
      return ls_avail;
  }
}

# UP: Move the pending Output of a Stream to the destination.
# finish_output(stream);
# > stream: Stream
# can trigger GC
global void finish_output (object stream) {
  if (builtin_stream_p(stream)) {
    if (TheStream(stream)->strmflags & strmflags_wr_B) { # Output-Stream?
      # no -> finished, yes -> branch according to Stream-Type:
      switch (TheStream(stream)->strmtype) {
        case strmtype_synonym:
          finish_output_synonym(stream); break;
        case strmtype_broad:
          finish_output_broad(stream); break;
        case strmtype_twoway:
        case strmtype_echo:
        #ifdef SOCKET_STREAMS
        case strmtype_twoway_socket:
        #endif
          finish_output_twoway(stream); break;
        case strmtype_buff_out:
          finish_output_buff_out(stream); break;
        #ifdef GENERIC_STREAMS
        case strmtype_generic:
          finish_output_generic(stream); break;
        #endif
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
        #endif
          if (ChannelStream_buffered(stream))
            finish_output_buffered(stream);
          else
            finish_output_unbuffered(stream);
          break;
        case strmtype_terminal:
          finish_output_terminal(stream); break;
        #ifdef PRINTER_AMIGAOS
        case strmtype_printer: # Printer:
        # Closing and Reopening would presumably cause a
        # formfeed, which is scarcely desired.
          break; # Hence do nothing.
        #endif
        default: # do nothing
          break;
      }
    }
  } else { # Call the generic function (STREAM-FINISH-OUTPUT stream):
    pushSTACK(stream); funcall(S(stream_finish_output),1);
  }
}

# UP: Move the pending Output of a Stream to the destination.
# force_output(stream);
# > stream: Stream
# can trigger GC
global void force_output (object stream) {
  if (builtin_stream_p(stream)) {
    if (TheStream(stream)->strmflags & strmflags_wr_B) { # Output-Stream?
      # no -> finished, yes -> branch according to Stream-Type:
      switch (TheStream(stream)->strmtype) {
        case strmtype_synonym:
          force_output_synonym(stream); break;
        case strmtype_broad:
          force_output_broad(stream); break;
        case strmtype_twoway:
        case strmtype_echo:
        #ifdef SOCKET_STREAMS
        case strmtype_twoway_socket:
        #endif
          force_output_twoway(stream); break;
        case strmtype_buff_out:
          force_output_buff_out(stream); break;
        #ifdef GENERIC_STREAMS
        case strmtype_generic:
          force_output_generic(stream); break;
        #endif
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
        #endif
          if (ChannelStream_buffered(stream))
            force_output_buffered(stream);
          else
            force_output_unbuffered(stream);
          break;
        case strmtype_terminal:
          force_output_terminal(stream); break;
        #ifdef PRINTER_AMIGAOS
        case strmtype_printer: # Printer:
          # Closing and Reopening would presumably cause a
          # formfeed, which is scarcely desired.
          break; # Hence do nothing.
        #endif
        default: # do nothing
          break;
      }
    }
  } else { # Call the generic function (STREAM-FORCE-OUTPUT stream):
    pushSTACK(stream); funcall(S(stream_force_output),1);
  }
}

# UP: Delete pending Output of a Stream.
# clear_output(stream);
# > stream: Stream
# can trigger GC
global void clear_output (object stream) {
  # On DOS nothing actually has to be done for File- or Terminal-Streams,
  # but we cannot take advantage of that, because clear_output on
  # Buffered-Output-Streams always works.
  if (builtin_stream_p(stream)) {
    if (TheStream(stream)->strmflags & strmflags_wr_B) { # Output-Stream?
      # no -> finished, yes -> branch according to Stream-Type:
      switch (TheStream(stream)->strmtype) {
        case strmtype_synonym:
          clear_output_synonym(stream); break;
        case strmtype_broad:
          clear_output_broad(stream); break;
        case strmtype_twoway:
        case strmtype_echo:
        #ifdef SOCKET_STREAMS
        case strmtype_twoway_socket:
        #endif
          clear_output_twoway(stream); break;
        case strmtype_buff_out:
          clear_output_buff_out(stream); break;
        #ifdef GENERIC_STREAMS
        case strmtype_generic:
          clear_output_generic(stream); break;
        #endif
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
        #endif
          if (ChannelStream_buffered(stream)) {
            # File: do nothing (would disturb the File-Management)
          } else {
            clear_output_unbuffered(stream);
          }
          break;
        case strmtype_terminal:
          #if (defined(UNIX) && !defined(NEXTAPP)) || defined(MSDOS) || defined(AMIGAOS) || defined(RISCOS) || defined(WIN32_NATIVE)
          terminalcase(stream,
          { clear_output_terminal1(stream); },
          { clear_output_terminal2(stream); },
          { clear_output_terminal3(stream); });
          #endif
          break;
        #ifdef PRINTER_AMIGAOS
        case strmtype_printer: # Printer: unbuffered, so nothing to do
          break;
        #endif
        default: # do nothing
          break;
      }
    }
  } else { # Call the generic function (STREAM-CLEAR-OUTPUT stream):
    pushSTACK(stream); funcall(S(stream_clear_output),1);
  }
}

# UP: Returns the Line-Position of a Stream.
# get_line_position(stream)
# > stream: Stream
# < result: Line-Position (Fixnum >=0 or NIL)
# can trigger GC
global object get_line_position (object stream) {
  check_SP();
 start:
  if (builtin_stream_p(stream))
    switch (TheStream(stream)->strmtype) {
      case strmtype_synonym: # Synonym-Stream: follow further
        resolve_as_synonym(stream);
        goto start;
      case strmtype_broad: # Broadcast-Stream:
        # Maximum of Line-Positions of the single Streams
        {
          pushSTACK(TheStream(stream)->strm_broad_list);
          var uintL maximum = 0; # previous Maximum := 0
          while (consp(STACK_0)) {
            var object next = # Line-Position of the next substream
              get_line_position(Car(STACK_0));
            if (nullp(next)) {
              skipSTACK(1); return NIL;
            }
            if (posfixnum_to_L(next) > maximum)
              maximum = posfixnum_to_L(next); # take Maximum
            STACK_0 = Cdr(STACK_0);
          }
          skipSTACK(1); return fixnum(maximum); # Maximum as result
        }
      case strmtype_twoway:
      case strmtype_echo:
      #ifdef SOCKET_STREAMS
      case strmtype_twoway_socket:
      #endif
        # Two-Way-Stream or Echo-Stream: look at Output-Stream
        stream = TheStream(stream)->strm_twoway_output;
        /* return get_line_position(stream); */ # without recursion:
        goto start;
      default: # normal Stream
        return TheStream(stream)->strm_wr_ch_lpos;
    }
  else { # Call the generic function (STREAM-LINE-COLUMN stream):
    pushSTACK(stream); funcall(S(stream_line_column),1);
    if (!(posfixnump(value1) || nullp(value1))) {
      pushSTACK(S(stream_line_column));
      pushSTACK(value1);
      fehler(error,GETTEXT("Return value ~ of call to ~ is not a fixnum >= 0 or NIL."));
    }
    return value1;
  }
}

# UP: Check an element-type for READ-INTEGER/WRITE-INTEGER.
# check_multiple8_eltype(&eltype);
# > eltype: Element-Type in decoded form
local void check_multiple8_eltype (const decoded_el_t* eltype) {
  if (!((eltype->size > 0) && ((eltype->size % 8) == 0))) {
    pushSTACK(canon_eltype(eltype));
    pushSTACK(S(Kelement_type));
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~ needs an ~ with a bit size being a multiple of 8, not ~"));
  }
}

# UP: Check an element-type for READ-FLOAT/WRITE-FLOAT.
# check_float_eltype(&eltype)
# > object eltype: argument (in the STACK)
# > subr_self: calling function
# < subr_self: unchanged
# < result: sizeof(ffloatjanus) or sizeof(dfloatjanus)
local uintL check_float_eltype (object* eltype_) {
  var object arg = *eltype_;
  if (eq(arg,S(single_float)))
    return sizeof(ffloatjanus);
  if (eq(arg,S(double_float)))
    return sizeof(dfloatjanus);
  var bool is_ffloat_subtype;
  var bool is_dfloat_subtype;
  pushSTACK(subr_self); # save subr_self
  # First of all, make it a little more canonical (so then the different
  # SUBTYPEP do not have to do the same thing twice):
  pushSTACK(arg); funcall(S(canonicalize_type),1); # (SYS::CANONICALIZE-TYPE arg)
  pushSTACK(value1); # save canon-arg
  pushSTACK(STACK_0); pushSTACK(S(single_float)); funcall(S(subtypep),2); # (SUBTYPEP canon-arg 'SINGLE-FLOAT)
  is_ffloat_subtype = !nullp(value1);
  pushSTACK(S(double_float)); funcall(S(subtypep),2); # (SUBTYPEP canon-arg 'DOUBLE-FLOAT)
  is_dfloat_subtype = !nullp(value1);
  subr_self = popSTACK(); # restore subr_self
  if (is_ffloat_subtype) {
    if (!is_dfloat_subtype)
      return sizeof(ffloatjanus);
  } else {
    if (is_dfloat_subtype)
      return sizeof(dfloatjanus);
  }
  pushSTACK(*eltype_); pushSTACK(S(Kelement_type));
  pushSTACK(TheSubr(subr_self)->name);
  fehler(error,GETTEXT("~: illegal ~ argument ~"));
}

# UP: Check an endianness argument.
# test_endianness_arg(arg)
# > arg: the argument
# > subr_self: calling function
# < bool result: endianness (BIG = true, LITTLE = false)
local bool test_endianness_arg (object arg) {
  if (!boundp(arg) || eq(arg,S(Klittle)) || eq(arg,S(Kdefault)))
    return false;
  if (eq(arg,S(Kbig)))
    return true;
  pushSTACK(arg);                # TYPE-ERROR slot DATUM
  pushSTACK(O(type_endianness)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(arg); pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: illegal endianness argument ~"));
}

# (READ-BYTE stream [eof-error-p [eof-value]]), CLTL p. 382
LISPFUN(read_byte,1,2,norest,nokey,0,NIL) {
  var object stream = check_stream(STACK_2);
  # read Integer:
  var object obj = read_byte(stream);
  if (eq(obj,eof_value)) { # EOF-treatment
    if (!nullp(STACK_1)) { # eof-error-p /= NIL (e.g. = #<UNBOUND>) ?
      # report error:
      pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
      pushSTACK(STACK_(2+1)); # Stream
      pushSTACK(S(read_byte));
      fehler(end_of_file,GETTEXT("~: input stream ~ has reached its end"));
    } else { # handle EOF:
      var object eofval = STACK_0;
      if (!boundp(eofval))
        eofval = NIL; # Default is NIL
      VALUES1(eofval); skipSTACK(3); /* return eofval */
    }
  } else {
    VALUES1(obj); skipSTACK(3); /* return obj */
  }
}

# (READ-BYTE-LOOKAHEAD stream)
LISPFUNN(read_byte_lookahead,1) {
  var object stream = popSTACK();
  check_stream(stream);
  # Query the status:
  var signean status = listen_byte(stream);
  if (ls_wait_p(status))
    value1 = NIL;
  else if (ls_eof_p(status))
    value1 = S(Keof);
  else # ls_avail_p(status)
    value1 = T;
  mv_count=1;
}

# (READ-BYTE-WILL-HANG-P stream)
LISPFUNN(read_byte_will_hang_p,1) {
  var object stream = popSTACK();
  check_stream(stream);
  # Query the status:
  var signean status = listen_byte(stream);
  VALUES_IF(ls_wait_p(status));
}

# (READ-BYTE-NO-HANG stream [eof-error-p [eof-value]])
LISPFUN(read_byte_no_hang,1,2,norest,nokey,0,NIL) {
  var object stream = check_stream(STACK_2);
  # Query the status:
  var signean status = listen_byte(stream);
  if (ls_wait_p(status)) {
    # Return NIL.
    VALUES1(NIL); skipSTACK(3);
    return;
  } else if (!ls_eof_p(status)) {
    # Read a byte:
    var object obj = read_byte(stream);
    if (!eq(obj,eof_value)) {
      # Return the read integer.
      VALUES1(obj); skipSTACK(3);
      return;
    }
  }
  # EOF handling.
  if (!nullp(STACK_1)) { # eof-error-p /= NIL (e.g. = #<UNBOUND>) ?
    # report error:
    pushSTACK(STACK_2); # STREAM-ERROR slot STREAM
    pushSTACK(STACK_(2+1)); # Stream
    pushSTACK(S(read_byte_no_hang));
    fehler(end_of_file,GETTEXT("~: input stream ~ has reached its end"));
  } else {
    # handle EOF:
    var object eofval = STACK_0;
    if (!boundp(eofval))
      eofval = NIL; # Default is NIL
    VALUES1(eofval); skipSTACK(3); /* return eofval */
  }
}

# (READ-INTEGER stream element-type [endianness [eof-error-p [eof-value]]])
# is a generalized READ-BYTE.
LISPFUN(read_integer,2,3,norest,nokey,0,NIL) {
  var object stream = check_stream(STACK_4);
  # check Element-Type:
  var decoded_el_t eltype;
  test_eltype_arg(&STACK_3,&eltype);
  check_multiple8_eltype(&eltype);
  # check Endianness:
  var bool endianness = test_endianness_arg(STACK_2);
  var uintL bitsize = eltype.size;
  var uintL bytesize = bitsize/8;
  var DYNAMIC_BIT_VECTOR(bitbuffer,bitsize);
  pushSTACK(bitbuffer);
  # Stack layout: stream, element-type, endianness, eof-error-p, eof-value, bitbuffer.
  # Read the data.
  if (!(read_byte_array(&STACK_5,&STACK_0,0,bytesize) == bytesize))
    goto eof;
  bitbuffer = STACK_0;
  if (endianness) # Byte-Swap the data.
    elt_nreverse(bitbuffer,0,bytesize);
  { # The data is now in little-endian order. Convert it to an integer.
    var object result;
    switch (eltype.kind) {
      case eltype_iu:
        result = bitbuff_iu_I(bitbuffer,bitsize,bytesize);
        break;
      case eltype_is:
        result = bitbuff_is_I(bitbuffer,bitsize,bytesize);
        break;
      default: NOTREACHED;
    }
    FREE_DYNAMIC_BIT_VECTOR(STACK_0);
    VALUES1(result);
    skipSTACK(6);
    return;
  }
  # EOF-Treatment
 eof:
  if (!nullp(STACK_2)) { # eof-error-p /= NIL (e.g. = #<UNBOUND>) ?
    # report error:
    pushSTACK(STACK_5); # STREAM-ERROR slot STREAM
    pushSTACK(STACK_(5+1)); # Stream
    pushSTACK(S(read_integer));
    fehler(end_of_file,GETTEXT("~: input stream ~ has reached its end"));
  } else { # handle EOF:
    var object eofval = STACK_1;
    if (!boundp(eofval))
      eofval = NIL; # Default is NIL
    VALUES1(eofval); skipSTACK(6); /* return eofval */
  }
}

# (READ-FLOAT stream element-type [endianness [eof-error-p [eof-value]]])
# reads a float in IEEE binary representation.
LISPFUN(read_float,2,3,norest,nokey,0,NIL) {
  var object stream = check_stream(STACK_4);
  # check Element-Type:
  var uintL bytesize = check_float_eltype(&STACK_3);
  # check Endianness:
  var bool endianness = test_endianness_arg(STACK_2);
  var DYNAMIC_BIT_VECTOR(bitbuffer,bytesize*8);
  pushSTACK(bitbuffer);
  # Stack layout: stream, element-type, endianness, eof-error-p, eof-value, bitbuffer.
  # Read the data.
  if (!(read_byte_array(&STACK_5,&STACK_0,0,bytesize) == bytesize))
    goto eof;
  bitbuffer = STACK_0;
  if (BIG_ENDIAN_P ? !endianness : endianness) # Byte-Swap the data.
    elt_nreverse(bitbuffer,0,bytesize);
  # The data is now in machine-dependent order. Convert it to a float.
  switch (bytesize) {
    case sizeof(ffloatjanus):
      if (((varobject_alignment % alignof(ffloatjanus)) == 0)
          && ((offsetofa(sbvector_,data) % alignof(ffloatjanus)) == 0)) {
        value1 = c_float_to_FF((ffloatjanus*)&TheSbvector(bitbuffer)->data[0]);
      } else {
        var ffloatjanus tmp;
        copy_mem_b(&tmp,&TheSbvector(bitbuffer)->data[0],sizeof(ffloatjanus));
        value1 = c_float_to_FF(&tmp);
      }
      break;
    case sizeof(dfloatjanus):
      if (((varobject_alignment % alignof(dfloatjanus)) == 0)
          && ((offsetofa(sbvector_,data) % alignof(dfloatjanus)) == 0)) {
        value1 = c_double_to_DF((dfloatjanus*)&TheSbvector(bitbuffer)->data[0]);
      } else {
        var dfloatjanus tmp;
        copy_mem_b(&tmp,&TheSbvector(bitbuffer)->data[0],sizeof(dfloatjanus));
        value1 = c_double_to_DF(&tmp);
      }
      break;
    default: NOTREACHED;
  }
  FREE_DYNAMIC_BIT_VECTOR(STACK_0);
  mv_count=1;
  skipSTACK(6);
  return;
  # EOF-Treatment
 eof:
  if (!nullp(STACK_2)) { # eof-error-p /= NIL (e.g. = #<UNBOUND>) ?
    # report error:
    pushSTACK(STACK_5); # STREAM-ERROR slot STREAM
    pushSTACK(STACK_(5+1)); # Stream
    pushSTACK(S(read_float));
    fehler(end_of_file,GETTEXT("~: input stream ~ has reached its end"));
  } else {
    # handle EOF:
    var object eofval = STACK_1;
    if (!boundp(eofval))
      eofval = NIL; # Default is NIL
    VALUES1(eofval); skipSTACK(6); /* return eofval */
  }
}

# (WRITE-BYTE integer stream), CLTL p. 385
LISPFUNN(write_byte,2) {
  var object stream = check_stream(STACK_0);
  var object obj = check_wr_int(stream,STACK_1);
  # write Integer:
  write_byte(stream,obj);
  VALUES1(STACK_1); skipSTACK(2); /* return obj */
}

# (WRITE-INTEGER integer stream element-type [endianness])
# is a generalized WRITE-BYTE.
LISPFUN(write_integer,3,1,norest,nokey,0,NIL) {
  var object stream = check_stream(STACK_2);
  # check Element-Type:
  var decoded_el_t eltype;
  test_eltype_arg(&STACK_1,&eltype);
  check_multiple8_eltype(&eltype);
  # check Endianness:
  var bool endianness = test_endianness_arg(STACK_0);
  # check Integer:
  var object obj = check_wr_int(stream,STACK_3);
  var uintL bitsize = eltype.size;
  var uintL bytesize = bitsize/8;
  var DYNAMIC_BIT_VECTOR(bitbuffer,bitsize);
  pushSTACK(bitbuffer);
  # Stack layout: obj, stream, element-type, endianness, bitbuffer.
  obj = STACK_4;
  # Copy the integer's data into the buffer.
  switch (eltype.kind) {
    case eltype_iu:
      bitbuff_ixu_sub(STACK_3,bitbuffer,bitsize,bytesize,obj);
      break;
    case eltype_is:
      bitbuff_ixs_sub(STACK_3,bitbuffer,bitsize,bytesize,obj);
      break;
    default: NOTREACHED;
  }
  # The data is now in little-endian order.
  if (endianness) # Byte-Swap the data.
    elt_nreverse(bitbuffer,0,bytesize);
  # Write the data.
  write_byte_array(&STACK_3,&STACK_0,0,bytesize);
  FREE_DYNAMIC_BIT_VECTOR(STACK_0);
  VALUES1(STACK_4); /* return obj */
  skipSTACK(5);
}

# (WRITE-FLOAT float stream element-type [endianness])
# writes a float in IEEE binary representation.
LISPFUN(write_float,3,1,norest,nokey,0,NIL) {
  var object stream = check_stream(STACK_2);
  # check Element-Type:
  var uintL bytesize = check_float_eltype(&STACK_1);
  # check Endianness:
  var bool endianness = test_endianness_arg(STACK_0);
  # check Float:
  var object obj = STACK_3;
  switch (bytesize) {
    case sizeof(ffloatjanus):
      if (!single_float_p(obj)) {
        pushSTACK(obj);             # TYPE-ERROR slot DATUM
        pushSTACK(S(single_float)); # TYPE-ERROR slot EXPECTED-TYPE
        pushSTACK(STACK_(2+2));
        pushSTACK(S(single_float));
        pushSTACK(obj);
        fehler(type_error,GETTEXT("~ is not a ~, cannot be output onto ~"));
      }
      break;
    case sizeof(dfloatjanus):
      if (!double_float_p(obj)) {
        pushSTACK(obj);             # TYPE-ERROR slot DATUM
        pushSTACK(S(double_float)); # TYPE-ERROR slot EXPECTED-TYPE
        pushSTACK(STACK_(2+2));
        pushSTACK(S(double_float));
        pushSTACK(obj);
        fehler(type_error,GETTEXT("~ is not a ~, cannot be output onto ~"));
      }
      break;
    default: NOTREACHED;
  }
  var DYNAMIC_BIT_VECTOR(bitbuffer,bytesize*8);
  pushSTACK(bitbuffer);
  # Stack layout: obj, stream, element-type, endianness, bitbuffer.
  obj = STACK_4;
  # Copy the float's data into the buffer.
  switch (bytesize) {
    case sizeof(ffloatjanus):
      if (((varobject_alignment % alignof(ffloatjanus)) == 0)
          && ((offsetofa(sbvector_,data) % alignof(ffloatjanus)) == 0)) {
        FF_to_c_float(obj,(ffloatjanus*)&TheSbvector(bitbuffer)->data[0]);
      } else {
        var ffloatjanus tmp;
        FF_to_c_float(obj,&tmp);
        memcpy(&TheSbvector(bitbuffer)->data[0],&tmp,sizeof(ffloatjanus));
      }
      break;
    case sizeof(dfloatjanus):
      if (((varobject_alignment % alignof(dfloatjanus)) == 0)
          && ((offsetofa(sbvector_,data) % alignof(dfloatjanus)) == 0)) {
        DF_to_c_double(obj,(dfloatjanus*)&TheSbvector(bitbuffer)->data[0]);
      } else {
        var dfloatjanus tmp;
        DF_to_c_double(obj,&tmp);
        copy_mem_b(&TheSbvector(bitbuffer)->data[0],&tmp,sizeof(dfloatjanus));
      }
      break;
    default: NOTREACHED;
  }
  # The data is now in machine-dependent order.
  if (BIG_ENDIAN_P ? !endianness : endianness) # Byte-Swap the data.
    elt_nreverse(bitbuffer,0,bytesize);
  # Write the data.
  write_byte_array(&STACK_3,&STACK_0,0,bytesize);
  FREE_DYNAMIC_BIT_VECTOR(STACK_0);
  VALUES1(STACK_4); /* return obj */
  skipSTACK(5);
}

# UP: Checks, if an Argument is an open File-Stream.
# check_open_file_stream(obj);
# > obj: Argument
# > subr_self: Caller (a SUBR)
# < result: open File-Stream
local object check_open_file_stream (object obj) {
  obj = resolve_synonym_stream(obj);
  if (!builtin_stream_p(obj)) # Stream ?
    goto fehler_bad_obj;
  if (!(TheStream(obj)->strmtype == strmtype_file)) # Streamtyp File-Stream ?
    goto fehler_bad_obj;
  if ((TheStream(obj)->strmflags & strmflags_open_B) == 0) # Stream open ?
    goto fehler_bad_obj;
  if (nullp(BufferedStream_channel(obj))) # and Handle /= NIL ?
    goto fehler_bad_obj;
  return obj; # yes -> OK
 fehler_bad_obj:
  pushSTACK(obj);                      # TYPE-ERROR slot DATUM
  pushSTACK(O(type_open_file_stream)); # TYPE-ERROR slot EXPECTED-TYPE
  pushSTACK(S(file_stream));
  pushSTACK(obj);
  pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: argument ~ is not an open ~"));
}

# (FILE-POSITION file-stream [position]), CLTL p. 425
LISPFUN(file_position,1,1,norest,nokey,0,NIL) {
  var object position = popSTACK();
  var object stream = popSTACK();
  stream = check_open_file_stream(stream); # check stream
  if (!ChannelStream_buffered(stream)) {
    # Don't know how to deal with the file position on unbuffered streams.
    VALUES1(NIL);
  } else {
    if (!boundp(position)) {
      # position not specified -> Position as value:
      VALUES1(UL_to_I(BufferedStream_position(stream)));
    } else {
      if (eq(position,S(Kstart))) {
        # :START -> set position to start:
        logical_position_file_start(stream);
      } else if (eq(position,S(Kend))) {
        # :END -> set position to end:
        logical_position_file_end(stream);
      } else if (uint32_p(position)) {
        # set position to specified Position:
        logical_position_file(stream,I_to_UL(position));
      } else {
        # illegal Position-Argument
        pushSTACK(position);         # TYPE-ERROR slot DATUM
        pushSTACK(O(type_position)); # TYPE-ERROR slot EXPECTED-TYPE
        pushSTACK(position); pushSTACK(S(Kend)); pushSTACK(S(Kstart));
        pushSTACK(TheSubr(subr_self)->name);
        fehler(type_error,GETTEXT("~: position argument should be ~ or ~ or a nonnegative integer, not ~"));
      }
      VALUES1(T);
    }
  }
}

# (FILE-LENGTH file-stream), CLTL p. 425
LISPFUNN(file_length,1) {
  var object stream = popSTACK();
  stream = check_open_file_stream(stream); # check stream
  if (!ChannelStream_buffered(stream)) {
    # Don't know how to deal with the file position on unbuffered streams.
    VALUES1(NIL);
  } else {
    # memorize Position:
    var uintL position = BufferedStream_position(stream);
    # set position to end:
    logical_position_file_end(stream);
    # memorize End-Position:
    var uintL endposition = BufferedStream_position(stream);
    # set back to old position:
    logical_position_file(stream,position);
    VALUES1(UL_to_I(endposition)); /* return End-Position */
  }
}

# (FILE-STRING-LENGTH stream object)
LISPFUNN(file_string_length,2) {
  var object stream = check_open_file_stream(STACK_1); # check stream
  var object obj = STACK_0;
  skipSTACK(2);
  if (!(TheStream(stream)->strmflags & strmflags_wr_ch_B))
    fehler_illegal_streamop(S(file_string_length),stream);
  var object encoding = TheStream(stream)->strm_encoding;
 #if defined(UNICODE) && defined(HAVE_GOOD_ICONV)
  if (simple_string_p(TheEncoding(encoding)->enc_charset)) {
    # iconv-based encodings have state. Since we cannot duplicate an iconv_t
    # we have no way to know for sure how many bytes the string will span.
    if (stringp(obj)) {
      VALUES1(vector_length(obj) == 0 ? Fixnum_0 : NIL);
    } else if (charp(obj)) {
      VALUES1(NIL);
    } else {
      fehler_wr_char(stream,obj);
    }
    return;
  }
 #endif
 #ifdef UNICODE
  if (TheEncoding(encoding)->min_bytes_per_char !=
      TheEncoding(encoding)->max_bytes_per_char) {
    # Have to look at each character individually.
    var const chart* charptr;
    var uintL len;
    var chart auxch;
    if (stringp(obj)) {
      var uintL offset;
      var object string = unpack_string_ro(obj,&len,&offset);
      unpack_sstring_alloca(string,len,offset, charptr=);
    } else if (charp(obj)) {
      auxch = char_code(obj); charptr = &auxch; len = 1;
    } else {
      fehler_wr_char(stream,obj);
    }
    if (eq(TheEncoding(encoding)->enc_eol,S(Kunix))) {
      # Treat all the characters all at once.
      var uintL result = cslen(encoding,charptr,len);
      VALUES1(UL_to_I(result)); return;
    } else {
      # Treat line-by-line.
      var const chart* eol_charptr;
      var uintL eol_len;
      if (eq(TheEncoding(encoding)->enc_eol,S(Kmac))) {
        static const chart eol_mac[1] = { ascii(CR) };
        eol_charptr = &eol_mac[0]; eol_len = 1;
      } else if (eq(TheEncoding(encoding)->enc_eol,S(Kdos))) {
        static const chart eol_dos[2] = { ascii(CR), ascii(LF) };
        eol_charptr = &eol_dos[0]; eol_len = 2;
      } else {
        NOTREACHED;
      }
      var const chart* endptr = charptr+len;
      var uintL result = 0;
      while (charptr < endptr) {
        # Search the next NL.
        var const chart* ptr = charptr;
        while (!chareq(*ptr,ascii(NL))) {
          ptr++;
          if (ptr == endptr)
            break;
        }
        # Count the bytes needed for the characters before the NL.
        if (!(ptr == charptr))
          result += cslen(encoding,charptr,ptr-charptr);
        charptr = ptr;
        # Count the bytes needed for the NL.
        if (charptr < endptr) {
          # *charptr is ascii(NL).
          result += cslen(encoding,eol_charptr,eol_len);
          charptr++;
        }
      }
      VALUES1(UL_to_I(result)); return;
    }
  }
  # Now the easy case: a fixed number of bytes per character.
  var uintL bytes_per_char = TheEncoding(encoding)->min_bytes_per_char;
 #else
  #define bytes_per_char  1
 #endif
  if (eq(TheEncoding(encoding)->enc_eol,S(Kunix))
      || eq(TheEncoding(encoding)->enc_eol,S(Kmac))) {
    if (stringp(obj)) {
      var uintL result = vector_length(obj);
      VALUES1(UL_to_I(result*bytes_per_char)); return;
    } else if (charp(obj)) {
      VALUES1(fixnum(bytes_per_char)); return;
    } else {
      fehler_wr_char(stream,obj);
    }
  }
  if (eq(TheEncoding(encoding)->enc_eol,S(Kdos))) {
    # Take into account the NL -> CR/LF translation.
    if (stringp(obj)) {
      var uintL len;
      var uintL offset;
      var object string = unpack_string_ro(obj,&len,&offset);
      var uintL result = len;
      if (len > 0) {
        SstringDispatch(string,X, {
          var const cintX* charptr = &((SstringX)TheVarobject(string))->data[offset];
          var uintL count;
          dotimespL(count,len, {
            if (chareq(as_chart(*charptr++),ascii(NL)))
              result++;
          });
        });
      }
      VALUES1(UL_to_I(result*bytes_per_char)); return;
    } else if (charp(obj)) {
      var uintL result = 1;
      if (chareq(char_code(obj),ascii(NL)))
        result++;
      VALUES1(fixnum(result*bytes_per_char)); return;
    } else {
      fehler_wr_char(stream,obj);
    }
  }
  NOTREACHED;
  #undef bytes_per_char
}

# UP: Tells whether a stream is buffered.
# stream_isbuffered(stream)
# > stream: a channel or socket stream
# < result: true if stream is buffered, else false
global bool stream_isbuffered (object stream) {
  switch (TheStream(stream)->strmtype) {
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
    #endif
      return ChannelStream_buffered(stream);
    #ifdef SOCKET_STREAMS
    case strmtype_twoway_socket:
      return true;
    #endif
    default:
      return false;
  }
}

# UP: Returns the current line number of a stream.
# stream_line_number(stream)
# > stream: a stream
# < result: an integer or NIL
# can trigger GC
global object stream_line_number (object stream) {
  return (builtin_stream_p(stream)
          && TheStream(stream)->strmtype == strmtype_file
          && eq(TheStream(stream)->strm_eltype,S(character))
          ? UL_to_I(ChannelStream_lineno(stream)) # current line-number
          : NIL);                                 # NIL if unknown
}

# (SYS::LINE-NUMBER stream) returns the current line-number (if stream
# is a Character-File-Input-Stream, which was only used for reading).
LISPFUNN(line_number,1) {
  var object stream = popSTACK();
  check_stream(stream);
  VALUES1(stream_line_number(stream));
}

# Function: Returns true if a stream allows read-eval.
# stream_get_read_eval(stream)
# > stream: a stream
# < result: true if read-eval is allowed from the stream, else false
global bool stream_get_read_eval (object stream) {
  if (builtin_stream_p(stream)) {
    return ((TheStream(stream)->strmflags & strmflags_reval_B) != 0);
  } else { # (SLOT-VALUE stream '$reval):
    object clas = TheInstance(stream)->inst_class;
    object slotinfo = gethash(S(reval),TheClass(clas)->slot_location_table);
    object value = TheSrecord(stream)->recdata[posfixnum_to_L(slotinfo)];
    return !nullp(value);
  }
}

# Function: Changes the read-eval state of a stream.
# stream_set_read_eval(stream,value);
# > stream: a stream
# > value: true if read-eval shall be allowed from the stream, else false
global void stream_set_read_eval (object stream, bool value) {
  if (builtin_stream_p(stream)) {
    if (value)
      TheStream(stream)->strmflags |= strmflags_reval_B;
    else
      TheStream(stream)->strmflags &= ~strmflags_reval_B;
  } else { # (SETF (SLOT-VALUE stream '$reval) value):
    object clas = TheInstance(stream)->inst_class;
    object slotinfo = gethash(S(reval),TheClass(clas)->slot_location_table);
    TheSrecord(stream)->recdata[posfixnum_to_L(slotinfo)] = (value ? T : NIL);
  }
}

# (SYS::ALLOW-READ-EVAL stream) returns the stream's READ-EVAL flag.
# (SYS::ALLOW-READ-EVAL stream flag) sets the stream's READ-EVAL flag.
# T means #. is allowed regardless of the value of *READ-EVAL*, NIL
# (the default) means that *READ-EVAL* is respected.
LISPFUN(allow_read_eval,1,1,norest,nokey,0,NIL) {
  var object flag = popSTACK();
  var object stream = popSTACK();
  check_stream(stream);
  if (eq(flag,unbound)) {
    value1 = (stream_get_read_eval(stream) ? T : NIL);
  } else {
    if (nullp(flag)) {
      stream_set_read_eval(stream,false); value1 = NIL;
    } else {
      stream_set_read_eval(stream,true); value1 = T;
    }
  }
  mv_count=1;
}

# (SYS::%DEFGRAY fundamental-stream-classes)
# Initializes O(class_fundamental*_stream).
LISPFUNN(defgray,1) {
  copy_mem_o(&O(class_fundamental_stream),&TheSvector(STACK_0)->data[0],
             Svector_length(STACK_0));
  VALUES0; skipSTACK(1);
}

# =============================================================================

#ifdef EXPORT_SYSCALLS
#ifdef UNIX
global object stream_fd (object stream) {
  stream = check_open_file_stream(stream);
  return UL_to_I(TheHandle(TheStream(stream)->strm_ochannel));
}
#endif # UNIX

#ifdef HAVE_FLOCK

#ifdef HAVE_SYS_FILE_H
#include <sys/file.h>
#endif

# the interface to flock(2)
# (STREAM-LOCK stream lock-p &key (block T) (shared NIL))
LISPFUN(stream_lock,2,0,norest,key,2, (kw(shared),kw(block)) ) {
  var int fd = -1;
  var object stream = nullobj;
  if (posfixnump(STACK_3)) fd = posfixnum_to_L(STACK_3) ;
  else {
    stream = check_open_file_stream(STACK_3);
    fd = TheHandle(TheStream(stream)->strm_ochannel);
  }
  var bool lock_p = !nullp(STACK_2);
  var int operation = !lock_p ? LOCK_UN
    : (nullp(STACK_1) || eq(unbound,STACK_1) ? LOCK_EX : LOCK_SH);
  if (nullp(STACK_0)) operation |= LOCK_NB;
  begin_system_call();
  var bool failed_p = flock(fd,operation);
  end_system_call();
  if (failed_p) {
    if (eq(stream,nullobj)) OS_error();
    else OS_filestream_error(stream);
  }
  skipSTACK(4);
  VALUES_IF(lock_p);
}

#endif

#endif # EXPORT_SYSCALLS

# =============================================================================

# achieve binary compatibility between .mem-Files with and without NEXTAPP:
  #ifdef MAYBE_NEXTAPP
    #ifndef NEXTAPP
      #define wr_ch_terminal  wr_ch_error
      #define rd_ch_terminal  rd_ch_error
    #else
      #define wr_ch_terminal1  wr_ch_error
      #define rd_ch_terminal1  rd_ch_error
      #define wr_ch_array_terminal1  wr_ch_array_dummy
    #endif
    #ifndef GNU_READLINE
      #define wr_ch_terminal3  wr_ch_error
      #define rd_ch_terminal3  rd_ch_error
      #define wr_ch_array_terminal3  wr_ch_array_dummy
    #endif
    #ifdef NEXTAPP
      #define wr_ch_window  wr_ch_error
    #endif
  #endif

# table of all pseudo-functions
#define PSEUDO  PSEUDO_C
#include "pseudofun.c"
#undef PSEUDO
global struct pseudocode_tab_ pseudocode_tab = {
  #define PSEUDO  PSEUDO_D
  #include "pseudofun.c"
  #undef PSEUDO
};
global struct pseudodata_tab_ pseudodata_tab = {
  #define PSEUDO  PSEUDO_E
  #include "pseudofun.c"
  #undef PSEUDO
  #if defined(MICROSOFT) && !defined(UNICODE)
   (Pseudofun) NULL
  #endif
};

# =============================================================================

#ifdef EMUNIX

# An auxiliary function for bidirectional Pipes: popenrw()
#undef stdin_handle
#undef stdout_handle
#include "../os2/popenrw.c"

#endif

# =============================================================================

# protect filestatus/if_file_exists, file_datetime by break_sem_4??
# Signal-Handling on EXECUTE, SHELL, MAKE-PIPE-INPUT-STREAM, MAKE-PIPE-OUTPUT-STREAM, MAKE-PIPE-IO-STREAM ??
# naming of file/handle/buffered/b_file/unbuffered stuff
# do not access strm_file_truename on pipe and socket streams
# implement FILE-POSITION for unbuffered file-streams (regular handle, direction != 5)
# LISTEN on unbuffered (non-regular) file and socket streams can cause the process to block
