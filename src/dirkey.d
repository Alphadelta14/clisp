/*
 * CLISP: directory key: win32 registry, LDAP, Gnome-config
 * Copyright (C) 2000-2002 by Sam Steingold
 */
#ifdef DIR_KEY

#include "lispbibl.c"

#if defined(UNIX_CYGWIN32)
 #ifdef UNICODE
  #define UNICODE_SAVED
  #undef UNICODE
 #endif
 #define WIN32_LEAN_AND_MEAN  /* avoid including junk */
 /* `unused' is used in function declarations. */
 #undef unused
 #define ULONGLONG OS_ULONGLONG
 #define ULONG OS_ULONG
 #include <windows.h>
 #undef ULONG
 #undef ULONGLONG
 #define unused (void)
#endif

#if defined(WIN32_NATIVE) || defined(UNIX_CYGWIN32)
 #include <winreg.h>
 #if !defined(__MINGW32__) && !defined(UNIX_CYGWIN32)
  #include <winldap.h>
  # define ACCESS_LDAP # not yet!
 #endif
 #define WIN32_REGISTRY 1
#elif defined(HAVE_LDAP_H)
 #include <ldap.h>
 #define ACCESS_LDAP
#endif
#ifdef HAVE_GNOME_H
 #include <gnome.h>
#endif

# as per RFC1777 and RFC2255
#ifndef LDAP_PORT
#define LDAP_PORT 389
#endif

# :SCOPE
#define SCOPE_SELF  0
#define SCOPE_KIDS  1
#define SCOPE_TREE  2

#ifdef WIN32_REGISTRY
#define SYSCALL_WIN32(call)                                            \
  do {                                                                 \
    var uintL status;                                                  \
    begin_system_call();                                               \
    status = call;                                                     \
    if (status != ERROR_SUCCESS) { SetLastError(status); OS_error(); } \
    end_system_call();                                                 \
  } while(0)
#endif

#ifdef ACCESS_LDAP
#ifdef WIN32_NATIVE
#define SYSCALL_LDAP(call) SYSCALL_WIN32(call)
#else
#define SYSCALL_LDAP(call)                                             \
  do {                                                                 \
    var uintL status;                                                  \
    begin_system_call();                                               \
    status = call;                                                     \
    if (status != LDAP_SUCCESS) { errno=status; OS_error(); }          \
    end_system_call();                                                 \
  } while(0)
#endif
#endif

/* check whether the OBJ is a DIR-KEY
 can trigger GC */
local object test_dir_key (object obj, bool check_open) {
 start:
  if (!dir_key_p(obj)) {
    pushSTACK(NIL); /* no PLACE */
    pushSTACK(obj);        /* TYPE-ERROR slot DATUM */
    pushSTACK(S(dir_key)); /* TYPE-ERROR slot EXPECTED-TYPE */
    pushSTACK(S(dir_key)); pushSTACK(obj);
    pushSTACK(TheSubr(subr_self)->name);
    check_value(type_error,GETTEXT("~: ~ is not a ~"));
    obj = value1; goto start;
  }
  if (check_open && TheDirKey(obj)->closed_p) {
    pushSTACK(obj);
    pushSTACK(TheSubr(subr_self)->name);
    check_value(error,GETTEXT("~ on ~ is illegal"));
    obj = value1; goto start;
  }
  return obj;
}

# convert an array of char to a (VECTOR (UNSIGNED-BYTE 8))
# can trigger GC
local object reg_val_to_vector (uintL size, const char* buffer) {
  var object vec = allocate_bit_vector(Atype_8Bit,size);
  var uintB* dat = TheSbvector(vec)->data;
  while(size--) *dat++ = *buffer++;
  return vec;
}

#ifdef WIN32_REGISTRY
# convert a registry value [type;size;buffer] to the appropriate Lisp object
# can trigger GC
local object registry_value_to_object (DWORD type, DWORD size,
                                       const char* buffer) {
  switch (type) {
    case REG_NONE: return NIL;
    case REG_SZ:
    case REG_EXPAND_SZ: # should we actually expand the env vars?!
      return asciz_to_string(buffer,O(misc_encoding));
    case REG_DWORD_LITTLE_ENDIAN:
      if (REG_DWORD_LITTLE_ENDIAN != REG_DWORD)
        return UL_to_I(((unsigned char)buffer[3] << 24)+
                       ((unsigned char)buffer[2] << 16)+
                       ((unsigned char)buffer[1] <<  8)+
                       ((unsigned char)buffer[0]));
      else
        return UL_to_I(*(DWORD*)buffer);
    case REG_DWORD_BIG_ENDIAN:
      if (REG_DWORD_BIG_ENDIAN != REG_DWORD)
        return UL_to_I(((unsigned char)buffer[0] << 24)+
                       ((unsigned char)buffer[1] << 16)+
                       ((unsigned char)buffer[2] <<  8)+
                       ((unsigned char)buffer[3]));
      else
        return UL_to_I(*(DWORD*)buffer);
    case REG_MULTI_SZ: {
      # multiple strings, separated by '\0'.
      pushSTACK(NIL);
      var uintL ii;
      for (ii = 0; ii < size; ) {
        var uintL jj;
        for (jj = ii; (jj < size) && buffer[jj]; jj++);
        if (jj < size-1) { # avoid last empty string
          var object new_cons = allocate_cons();
          Cdr(new_cons) = STACK_0;
          STACK_0 = new_cons;
          Car(STACK_0) = n_char_to_string(buffer+ii,jj-ii,O(misc_encoding));
        }
        ii = jj + 1;
      }
      return nreverse(popSTACK());
    }
    # case REG_RESOURCE_LIST:
    # case REG_FULL_RESOURCE_DESCRIPTOR:
    # case REG_RESOURCE_REQUIREMENTS_LIST:
    # case REG_LINK:
    # case REG_BINARY:
    default:
      return reg_val_to_vector(size,buffer);
  }
}

#endif

# (LDAP:DIR-KEY-TYPE dkey)
# return the type of the key (:win32 or :gnome or :ldap)
LISPFUNNR(dir_key_type,1) {
  var object dkey = test_dir_key(popSTACK(),false);
  VALUES1(TheDirKey(dkey)->type);
}

# (LDAP:DIR-KEY-PATH dkey)
# return the path of the key (a string)
LISPFUNNR(dir_key_path,1) {
  var object dkey = test_dir_key(popSTACK(),false);
  VALUES1(TheDirKey(dkey)->path);
}

# (LDAP:DIR-KEY-DIRECTION dkey)
# return the direction of this key - :input :output or :io
LISPFUNNR(dir_key_direction,1) {
  var object dkey = test_dir_key(popSTACK(),true);
  VALUES1(TheDirKey(dkey)->direction);
}

# (LDAP:DIR-KEY-OPEN-P dkey)
# return T if the key is open
LISPFUNNR(dir_key_open_p,1) {
  var object dkey = test_dir_key(popSTACK(),false);
  VALUES_IF(!TheDirKey(dkey)->closed_p);
}

# (LDAP:DIR-KEY-CLOSE dkey)
# close the supplied DIR-KEY
LISPFUNN(dir_key_close,1) {
  var object dkey = popSTACK();
  #ifdef WIN32_REGISTRY
  if (fpointerp(dkey)) { # an HKEY in an iterator_state
    if (TheFpointer(dkey)->fp_pointer)
      SYSCALL_WIN32(RegCloseKey((HKEY)(TheFpointer(dkey)->fp_pointer)));
  } else
  #endif
  {
    dkey = test_dir_key(dkey,false);
    if (!TheDirKey(dkey)->closed_p) {
      #ifdef WIN32_REGISTRY
      if (eq(TheDirKey(dkey)->type,S(Kwin32))) {
        SYSCALL_WIN32(RegCloseKey((HKEY)(TheDirKey(dkey)->handle)));
      } else
      #endif
      #ifdef ACCESS_LDAP
      if (eq(TheDirKey(dkey)->type,S(Kldap))) {
        SYSCALL_LDAP(ldap_unbind((struct ldap*)(TheDirKey(dkey)->handle)));
      } else
      #endif
      #ifdef GNOME
      if (eq(TheDirKey(dkey)->type,S(Kgnome))) {
        with_string_0(TheDirKey(dkey)->path,O(pathname_encoding),pathz,{
          gnome_config_drop_file(pathz);
          gnome_config_sync_file(pathz);
        });
      } else
      #endif
        { /* noop */ ; }
      TheDirKey(dkey)->closed_p = true;
    }
  }
  VALUES1(NIL);
}

#ifdef WIN32_REGISTRY
struct root {
  const char *name;
  unsigned int namelen;
  HKEY hkey;
};
#define MKKEY(key)  { #key, sizeof(#key)-1, key }
static struct root roots[] = {
 #ifdef  HKEY_CLASSES_ROOT
  MKKEY(HKEY_CLASSES_ROOT),
 #endif
 #ifdef  HKEY_CURRENT_USER
  MKKEY(HKEY_CURRENT_USER),
 #endif
 #ifdef  HKEY_LOCAL_MACHINE
  MKKEY(HKEY_LOCAL_MACHINE),
 #endif
 #ifdef  HKEY_USERS
  MKKEY(HKEY_USERS),
 #endif
 #ifdef  HKEY_PERFORMANCE_DATA
  MKKEY(HKEY_PERFORMANCE_DATA),
 #endif
 #ifdef  HKEY_CURRENT_CONFIG
  MKKEY(HKEY_CURRENT_CONFIG),
 #endif
 #ifdef  HKEY_DYN_DATA
  MKKEY(HKEY_DYN_DATA),
 #endif
};
#undef MKKEY

local HKEY parse_registry_path (const char* path, const char** base_ret) {
  var unsigned int ii;
  var unsigned int len;
  var HKEY hkey = NULL;
  var char* base;
  var char* host;
  # Path syntax HOSTNAME\\... denotes a remote registry access.
  host = NULL;
  begin_system_call();
  base = strstr(path,"\\\\");
  if (base == NULL) base = strstr(path,"//");
  if (base != NULL) {
    len = base-path;
    host = (char*)alloca(len+1);
    strncpy(host,path,len);
    host[len] = 0;
    path = base + 2;
  }
  # Now look for the topmost directory component.
  base = strchr(path,'\\');
  if (base == NULL) base = strchr(path,'/');
  if (base == NULL)
    len = strlen(path);
  else {
    len = base-path;
    base++;
  }
  # Return the remainder.
  *base_ret = base;
  # Get the key for the topmost directory component.
  for (ii = 0; ii < sizeof(roots)/sizeof(*roots); ii++)
    if (roots[ii].namelen == len && memcmp(roots[ii].name,path,len) == 0) {
      hkey = roots[ii].hkey;
      break;
    }
  end_system_call();
  if (hkey == NULL) { SetLastError(ERROR_PATH_NOT_FOUND); OS_error(); }
  if (host == NULL)
    return hkey;
  else {
    HKEY res;
    SYSCALL_WIN32(RegConnectRegistry(host,hkey,&res));
    return res;
  }
}

local void open_reg_key (HKEY hkey, char* path, direction_t dir,
                         if_does_not_exist_t if_not_exists, HKEY* p_hkey) {
  REGSAM perms;
  switch (dir) {
    case DIRECTION_OUTPUT: perms = KEY_WRITE; break;
    case DIRECTION_IO: perms = KEY_ALL_ACCESS; break;
    default: perms = KEY_READ; break;
  }
  var DWORD status;
  begin_system_call();
  status = RegOpenKeyEx(hkey,path,0,perms,p_hkey);
  if (status != ERROR_SUCCESS) {
    if ((if_not_exists == IF_DOES_NOT_EXIST_UNBOUND /*ignore*/)
        || ((status == ERROR_FILE_NOT_FOUND)
            && (if_not_exists != IF_DOES_NOT_EXIST_ERROR))) {
      switch (if_not_exists) {
        case IF_DOES_NOT_EXIST_NIL: case IF_DOES_NOT_EXIST_UNBOUND:
          *p_hkey = NULL; break;
        case IF_DOES_NOT_EXIST_CREATE:
          status = RegCreateKey(hkey,path,p_hkey);
          if (status != ERROR_SUCCESS) { SetLastError(status); OS_error(); }
          break;
        default: NOTREACHED;
      }
    } else { SetLastError(status); OS_error(); }
  }
  end_system_call();
}
#endif

#ifdef ACCESS_LDAP
nonreturning_function(local, fehler_ldap,
                      (object dk, object path, char* errmsg)) {
  end_system_call();
  pushSTACK(NIL); pushSTACK(path); pushSTACK(dk);
  pushSTACK(TheSubr(subr_self)->name);
  STACK_3 = CLSTEXT(errmsg);
  fehler(error,"~(~ ~): ~");
}
#define LDAP_ERR2STR(d,p,status) fehler_ldap(d,p,ldap_err2string(status))
#define LDAP_RES2STR(d,p,ld,res) LDAP_ERR2STR(d,p,ldap_result2error(ld,res,1))
#endif

# (LDAP:DIR-KEY-OPEN key path [:direction] [:if-does-not-exist])
# return the DIR-KEY object corresponding to the PATH under KEY
# PATH should be a string, like "HKEY_LOCAL_MACHINE\\Something"
# KEY can be either a DIR-KEY or a (MEMBER :win32 :gnome :ldap),
# in which case PATH must be absolute.
# :direction and :if-does-not-exist has the same meaning as for OPEN.
LISPFUN(dir_key_open,seclass_default,2,0,norest,key,2,
        (kw(direction),kw(if_does_not_exist))) {
  var object if_not_exists_arg = STACK_0;
  var object direction_arg = STACK_1;
  var object path = check_string(STACK_2);
  var object root = STACK_3;
  var void* ret_handle;
  var uintL status;
  if (!boundp(direction_arg)) direction_arg=S(Kinput);
  var direction_t direction = check_direction(direction_arg);
  var if_does_not_exist_t if_not_exists =
    check_if_does_not_exist(if_not_exists_arg);
  if (if_not_exists == IF_DOES_NOT_EXIST_UNBOUND)
    if_not_exists = (direction == DIRECTION_INPUT ?
                     IF_DOES_NOT_EXIST_ERROR : IF_DOES_NOT_EXIST_CREATE);
  # create the key handle
  var object type = (dir_key_p(root) ? TheDirKey(root)->type : root);
  #ifdef WIN32_REGISTRY
  if (eq(type,S(Kwin32))) {
    if (dir_key_p(root)) {
      root = test_dir_key(root,true);
      with_string_0(path,O(misc_encoding),pathz,{
        open_reg_key((HKEY)(TheDirKey(root)->handle),pathz,direction,
                     if_not_exists,(HKEY*)&ret_handle);
      });
    } else {
      with_string_0(path,O(misc_encoding),pathz,{
        var char* base;
        HKEY hkey = parse_registry_path(pathz,(const char**)&base);
        open_reg_key(hkey,base,direction,if_not_exists,(HKEY*)&ret_handle);
      });
    }
  } else
  #endif
  #ifdef ACCESS_LDAP
  if (eq(type,S(Kldap))) {
    if (dir_key_p(root)) {
      root = test_dir_key(root,true);
      begin_system_call();
      with_string_0(path,O(misc_encoding),pathz,{
        status = ldap_simple_bind_s((LDAP*)ret_handle,pathz,NULL);
      });
      if (status != LDAP_SUCCESS)
        LDAP_ERR2STR(root,path,status);
      end_system_call();
    } else { /* :LDAP */
      var struct ldap_url_desc* ldap_url = NULL;
      begin_system_call();
      with_string_0(path,O(misc_encoding),pathz,
                    { status = ldap_url_parse(pathz,&ldap_url); });
      if (status != 0) {
        end_system_call();
        pushSTACK(path);
        pushSTACK(TheSubr(subr_self)->name);
        fehler(error,GETTEXT("~: ~ is not an LDAP URL"));
      }
      ret_handle = (void*)ldap_open(ldap_url->lud_host,ldap_url->lud_port);
      if (ret_handle == NULL) OS_error();
      if ((status = ldap_simple_bind_s((LDAP*)ret_handle,ldap_url->lud_dn,
                                       NULL)) != LDAP_SUCCESS) {
        pushSTACK(path);
        var object dn = asciz_to_string(ldap_url->lud_dn,O(misc_encoding));
        path = popSTACK();
        LDAP_ERR2STR(path,dn,status);
      }
      ldap_free_urldesc(ldap_url);
      end_system_call();
    }
  } else
  #endif
  #ifdef GNOME
  if (eq(type,S(Kgnome))) {
    # do nothing - gnome-conf is stateless
  } else
  #endif
  { # invalid type
    pushSTACK(type);            # slot DATUM of         TYPE-ERROR
    pushSTACK(O(type_dir_key)); # slot EXPECTED-TYPE of TYPE-ERROR
    pushSTACK(S(dir_key));
    pushSTACK(type);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(type_error,GETTEXT("~: ~ is not a ~"));
  }
  # create the DIR-KEY
  pushSTACK(direction_arg);
  if (dir_key_p(root)) {
    pushSTACK(TheDirKey(root)->path);
    #ifdef WIN32_NATIVE
    if (eq(TheDirKey(root)->type,S(Kwin32)))
      pushSTACK(O(backslash_string));
    else
    #endif
      pushSTACK(O(slash_string));
    pushSTACK(path);
    var object totalpath = string_concat(3);
    pushSTACK(totalpath);
  } else
    pushSTACK(path);
  pushSTACK(type);
  var object dkey = allocate_dir_key();
  TheDirKey(dkey)->type = popSTACK();
  TheDirKey(dkey)->closed_p = false;
  TheDirKey(dkey)->path = popSTACK();
  TheDirKey(dkey)->direction = popSTACK();
  TheDirKey(dkey)->handle = ret_handle;
  pushSTACK(dkey);
  # Call (FINALIZE dir-key #'dir-key-close).
  pushSTACK(dkey);
  pushSTACK(L(dir_key_close));
  funcall(L(finalize),2);
  # Done.
  VALUES1(STACK_0);
  skipSTACK(5);
}

# The common code in DIR-KEY-SUBKEYS & DIR-KEY-ATTRIBUTES
#define MAKE_OBJECT_LIST(COUNT_EXPR,GET_NEXT_OBJ_EXPR)                     \
  var object dkey = test_dir_key(popSTACK(),true);                         \
  var LONG status;                                                         \
  var DWORD n_obj;                                                         \
  var DWORD maxlen;                                                        \
  var HKEY hkey = (HKEY)TheDirKey(dkey)->handle;                           \
  begin_system_call();                                                     \
  status = (COUNT_EXPR);                                                   \
  if (status != ERROR_SUCCESS) { SetLastError(status); OS_error(); }       \
  end_system_call();                                                       \
  if (n_obj > 0) {                                                         \
    var unsigned int ii;                                                   \
    var char* buf = (char*)alloca(maxlen+1); /* one extra char for '\0' */ \
    maxlen++; pushSTACK(NIL);                                              \
    for (ii = 0; ii < n_obj; ii++) {                                       \
      var DWORD len = maxlen;                                              \
      var DWORD status;                                                    \
      begin_system_call();                                                 \
      status = (GET_NEXT_OBJ_EXPR);                                        \
      if (status != ERROR_SUCCESS) { SetLastError(status); OS_error(); }   \
      end_system_call();                                                   \
      { var object new_cons = allocate_cons();                             \
        Cdr(new_cons) = STACK_0;                                           \
        STACK_0 = new_cons; }                                              \
      { var object string = asciz_to_string(buf,O(misc_encoding));         \
        Car(STACK_0) = string; }                                           \
    }                                                                      \
    value1 = nreverse(popSTACK());                                         \
  } else                                                                   \
    value1 = NIL;                                                          \
  mv_count = 1

# (LDAP:DIR-KEY-SUBKEYS key)
# return the list of subkey names of the given KEY
LISPFUNN(dir_key_subkeys,1) {
 #ifdef WIN32_REGISTRY
  if (eq(STACK_0,S(Kwin32))) { # top-level keys
    skipSTACK(1);
    var int ii;
    var int len = sizeof(roots)/sizeof(*roots);
    for (ii=0; ii<len; ii++)
      pushSTACK(asciz_to_string(roots[ii].name,O(misc_encoding)));
    value1 = listof(len);
    mv_count = 1;
  } else
 #endif
  {
    MAKE_OBJECT_LIST(RegQueryInfoKey(hkey,NULL,NULL,NULL,&n_obj,&maxlen,
                                     NULL,NULL,NULL,NULL,NULL,NULL),
                     RegEnumKey(hkey,ii,buf,len));
  }
}

# (LDAP:DIR-KEY-ATTRIBUTES key)
# return the list of attribute names of the given KEY
LISPFUNN(dir_key_attributes,1) {
  MAKE_OBJECT_LIST(RegQueryInfoKey(hkey,NULL,NULL,NULL,NULL,NULL,NULL,
                                   &n_obj,&maxlen,NULL,NULL,NULL),
                   RegEnumValue(hkey,ii,buf,&len,NULL,NULL,NULL,NULL));
}
#undef MAKE_OBJECT_LIST

# iteration state access
# STACK = (NODE1 NODE2 ...)
#define ITST_DKEY(state)   TheSvector(state)->data[0]
#define ITST_PATH(state)   TheSvector(state)->data[1]
#define ITST_SCOPE(state)  TheSvector(state)->data[2]
#define ITST_STACK(state)  TheSvector(state)->data[3]
#define ITST_NODE(state)   Car(ITST_STACK(state))
# node to process
#define NODE_HANDLE(node)  TheSvector(node)->data[0]
#define NODE_KEY(node)     TheSvector(node)->data[1]
#define NODE_KEY_S(node)   TheSvector(node)->data[2]
#define NODE_ATT(node)     TheSvector(node)->data[3]
#define NODE_ATT_S(node)   TheSvector(node)->data[4]
#define NODE_DAT_S(node)   TheSvector(node)->data[5]
#define NODE_NAME(node)    TheSvector(node)->data[6]

# return the current path - concatenate the NAMEs of the NODEs of the STACK
# can trigger GC
local object itst_current (object state) {
  var object stack = ITST_STACK(state);
  var uintL depth = 0;
  for (stack = nreverse(stack); !nullp(stack); stack = Cdr(stack)) {
    var object name = NODE_NAME(Car(stack));
    if (Sstring_length(name) > 0) {
      if (depth) {
        depth++;
       #ifdef WIN32_NATIVE
        pushSTACK(O(backslash_string));
       #else
        pushSTACK(O(slash_string));
       #endif
      }
      depth++;
      pushSTACK(name);
    }
  }
  ITST_STACK(state) = nreverse(ITST_STACK(state));
  return string_concat(depth);
}

local int parse_scope (object scope) {
  if (eq(scope,S(Kself)))  return SCOPE_SELF;
  if (eq(scope,S(Klevel))) return SCOPE_KIDS;
  if (eq(scope,S(Ktree)))  return SCOPE_TREE;
  pushSTACK(scope);         # slot DATUM of         TYPE-ERROR
  pushSTACK(O(type_scope)); # slot EXPECTED-TYPE of TYPE-ERROR
  pushSTACK(S(Kscope));
  pushSTACK(scope);
  pushSTACK(TheSubr(subr_self)->name);
  fehler(type_error,GETTEXT("~: ~ is not a ~"));
  return -1; # just to pacify the MSVC compiler
}

# (LDAP::DKEY-SEARCH-ITERATOR key path scope)
# return a simple vector with the iteration state
# < dkey path scope
# > #(dkey init-path scope (node ...))
LISPFUNN(dkey_search_iterator,3) {
  STACK_1 = check_string(STACK_1);
  parse_scope(STACK_0);
  pushSTACK(allocate_vector(4)); /* return value */
  ITST_DKEY(STACK_0)  = test_dir_key(STACK_3,true);
  ITST_PATH(STACK_0)  = STACK_2;
  ITST_SCOPE(STACK_0) = STACK_1;
  ITST_STACK(STACK_0) = T;
  VALUES1(STACK_0);
  skipSTACK(4);
}

# open HANDLE to point to DKEY\\PATH
# compute KEY_S, ATT_S and DAT_S
# return the full current path (itst_current)
# and T/NIL indicating whether OPEN was successful
# can trigger GC
local void init_iteration_node (object state, object subkey,
                                object *new_path, object *failed_p) {
  pushSTACK(state);
  pushSTACK(subkey);
  ITST_PATH(STACK_1/*state*/) = check_string(ITST_PATH(STACK_1));
  pushSTACK(allocate_cons());         # stack
  pushSTACK(allocate_vector(7));      # node
  pushSTACK(allocate_fpointer(NULL)); # handle
  var object handle = STACK_0;
  var object node   = STACK_1;
  var object stack  = STACK_2;
  subkey = STACK_3;
  state  = STACK_4;
  var object path = ITST_PATH(state);
  # (push node stack)
  if (eq(T,ITST_STACK(state)))
    ITST_STACK(state) = NIL;
  Car(stack) = node;
  Cdr(stack) = ITST_STACK(state);
  ITST_STACK(state) = stack;
  # init node
  NODE_KEY(node) = fixnum(0);
  NODE_ATT(node) = fixnum(0);
  NODE_NAME(node) = (nullp(subkey) ? path : subkey);
  # init handle
  NODE_HANDLE(node) = handle;
  pushSTACK(handle);
  pushSTACK(L(dir_key_close));
  funcall(L(finalize),2); # (FINALIZE handle #'dir-key-close)
  *new_path = itst_current(STACK_4); # state
  test_dir_key(ITST_DKEY(STACK_4),true);
  var Dir_Key dk = TheDirKey(test_dir_key(ITST_DKEY(STACK_4),true)); # state
  var Fpointer fp = TheFpointer(STACK_0); # handle
  with_string_0(*new_path,O(misc_encoding),pathz,{
    open_reg_key((HKEY)(dk->handle),pathz,check_direction(dk->direction),
                 IF_DOES_NOT_EXIST_UNBOUND/*ignore*/,(HKEY*)&(fp->fp_pointer));
  });
  if (fp->fp_pointer) {
    var DWORD k_size;
    var DWORD a_size;
    var DWORD d_size;
    SYSCALL_WIN32(RegQueryInfoKey((HKEY)(fp->fp_pointer),NULL,NULL,NULL,NULL,
                                  &k_size,NULL,NULL,&a_size,&d_size,
                                  NULL,NULL));
    NODE_KEY_S(STACK_1) = fixnum(k_size+1); # node
    NODE_ATT_S(STACK_1) = fixnum(a_size+1); # node
    NODE_DAT_S(STACK_1) = fixnum(d_size+1); # node
    *failed_p = NIL;
  } else {
    NODE_KEY_S(STACK_1) = Fixnum_0; # node
    NODE_ATT_S(STACK_1) = Fixnum_0; # node
    NODE_DAT_S(STACK_1) = Fixnum_0; # node
    *failed_p = T;
  }
  skipSTACK(5);
}

# return the next key of the current state or NIL
# if the key is NIL, the HKEY is closed and the stack is popped
# can trigger GC
local object state_next_key (object state) {
  var object stack = ITST_STACK(state);
  if (!nullp(stack)) {
    var object node = ITST_NODE(state);
    var uintL keynum = posfixnum_to_L(NODE_KEY(node));
    var uintL keylen = posfixnum_to_L(NODE_KEY_S(node));
    var char* buffer = (char*)alloca(keylen);
    var Fpointer fp  = TheFpointer(NODE_HANDLE(node));
    if (fp->fp_pointer) {
      var DWORD status = RegEnumKey((HKEY)(fp->fp_pointer),
                                    keynum,buffer,keylen);
      if (status == ERROR_SUCCESS) {
        NODE_KEY(node) = fixnum_inc(NODE_KEY(node),1);
        return asciz_to_string(buffer,O(misc_encoding));
      } else {
        SYSCALL_WIN32(RegCloseKey((HKEY)(fp->fp_pointer)));
        fp->fp_pointer = NULL;
        ITST_STACK(state) = Cdr(stack);
        return NIL;
      }
    } else {
      ITST_STACK(state) = Cdr(stack);
      return NIL;
    }
  } else
    return NIL;
}

# (LDAP::DKEY-SEARCH-NEXT-KEY state)
# return the next key of this iteration
# and T if open failed
LISPFUNN(dkey_search_next_key,1) {
  var object state = STACK_0;
  var object dkey  = test_dir_key(ITST_DKEY(state),true);
  var int scope = parse_scope(ITST_SCOPE(state));
  var object stack = ITST_STACK(state);
  switch (scope) {
    case SCOPE_SELF:            # just the top
      if (eq(stack,T))
        init_iteration_node(state,NIL,&value1,&value2); # first call
      else
        value1 = value2 = NIL;
      break;
    case SCOPE_KIDS:            # the children
      if (eq(stack,T)) {
        init_iteration_node(state,NIL,&value1,&value2);
        if (nullp(value2))
          value1 = state_next_key(STACK_0); # STACK_0 == state
      } else {
        value1 = state_next_key(STACK_0);
        value2 = NIL;
      }
      break;
    case SCOPE_TREE:            # the whole subtree
      if (eq(stack,T))
        init_iteration_node(state,NIL,&value1,&value2); # first call
      else {                          # find the next node and return it
        pushSTACK(NIL); # STACK_0 == subkey; STACK_1 == state
        do STACK_0 = state_next_key(STACK_1); # subkey==NIL ==> stack popped
        while (nullp(STACK_0) && !nullp(ITST_STACK(STACK_1)));
        if (nullp(STACK_0)) value1 = NIL;
        else init_iteration_node(STACK_1,STACK_0,&value1,&value2);
        skipSTACK(1);
      }
      break;
    default: NOTREACHED;
  }
  skipSTACK(1);
  mv_count = 2;
}

# (LDAP::DKEY-SEARCH-NEXT-ATT state)
# return the next attribute and its value of this iteration
LISPFUNN(dkey_search_next_att,1) {
  var object state = STACK_0;
  var object stack = ITST_STACK(state);
  if (!consp(stack)) {
    pushSTACK(S(dkey_search_next_key));
    pushSTACK(state);
    pushSTACK(S(dkey_search_next_att));
    fehler(error,GETTEXT("~ from ~ without ~ before it"));
  }
  var object node = Car(stack);
  var Fpointer fp = TheFpointer(NODE_HANDLE(node));
  var uintL attnum = posfixnum_to_L(NODE_ATT(node));
  var uintL attlen = posfixnum_to_L(NODE_ATT_S(node));
  var uintL datlen = posfixnum_to_L(NODE_DAT_S(node));
  var char* att = (char*)alloca(attlen);
  var char* dat = (char*)alloca(datlen);
  var DWORD type;
  var DWORD size;
  var DWORD status = RegEnumValue((HKEY)(fp->fp_pointer),
                                  attnum,att,&attlen,NULL,
                                  &type,dat,&size);
  if (status == ERROR_SUCCESS) {
    NODE_ATT(node) = fixnum_inc(NODE_ATT(node),1);
    pushSTACK(asciz_to_string(att,O(misc_encoding)));
    pushSTACK(registry_value_to_object(type,size,dat));
  } else {
    pushSTACK(NIL);
    pushSTACK(NIL);
  }
  mv_count = 2;
  value1 = STACK_1;
  value2 = STACK_0;
  skipSTACK(3);
}

#undef ITST_DKEY
#undef ITST_PATH
#undef ITST_SCOPE
#undef ITST_STACK
#undef ITST_NODE
#undef NODE_NAME
#undef NODE_KEY
#undef NODE_KEY_S
#undef NODE_ATT
#undef NODE_ATT_S
#undef NODE_DAT_S
#undef NODE_HANDLE

# (LDAP:DIR-KEY-VALUE key name [default])
# return the value of the given NAME in the KEY
# KEY must be an open DIR-KEY, NAME - a string
# if the name does not exists, return the DEFAULT (or signal an error)
# setf-able
LISPFUN(dir_key_value,seclass_default,2,1,norest,nokey,0,NIL) {
  var object name = check_string(STACK_1);
  var object default_value = popSTACK();
  var object dkey = test_dir_key(popSTACK(),true);
  with_string_0(name,O(misc_encoding),namez,{
    var DWORD status;
    var DWORD type;
    var DWORD size;
    begin_system_call();
    status = RegQueryValueEx((HKEY)(TheDirKey(dkey)->handle),namez,
                             NULL,NULL,NULL,&size);
    if (status != ERROR_SUCCESS) {
      if ((status == ERROR_FILE_NOT_FOUND) && boundp(default_value)) {
        value1 = default_value;
        end_system_call();
        goto end;
      }
      SetLastError(status); OS_error();
    }
    ++size;                     # one extra char for `\0'
    var char* buffer = (char*)alloca(size);
    status = RegQueryValueEx((HKEY)(TheDirKey(dkey)->handle),namez,
                             NULL,&type,buffer,&size);
    if (status != ERROR_SUCCESS) { SetLastError(status); OS_error(); }
    end_system_call();
    value1 = registry_value_to_object(type,size,buffer);
  end:;
  });
  mv_count = 1;
}

# (LDAP::SET-DKEY-VALUE key name value)
# set the given NAME in the KEY to the VALUE
LISPFUNN(set_dkey_value,3) {
  STACK_1 = check_string(STACK_1);
  var object dkey = test_dir_key(STACK_2,true);
  var object name = STACK_1;
  var object value = STACK_0;
  if (!stringp(name)) fehler_string(name);
  with_string_0(name,O(misc_encoding),namez, {
    if (stringp(value)) {
      with_string_0(value,O(misc_encoding),valz, {
        SYSCALL_WIN32(RegSetValueEx((HKEY)(TheDirKey(dkey)->handle),namez,0,
                                    REG_SZ,valz,strlen(valz)));
      });
    } else if (integerp(value)) {
      var DWORD word = I_to_UL(value);
      SYSCALL_WIN32(RegSetValueEx((HKEY)(TheDirKey(dkey)->handle),namez,0,
                                  REG_DWORD,(char*)&word,sizeof(DWORD)));
    } else if (bit_vector_p(Atype_8Bit,value)) {
      var uintL idx = 0;
      var uintL len = vector_length(value);
      object arr = (array_simplep(value) ? value :
                    iarray_displace_check(value,len,&idx));
      SYSCALL_WIN32(RegSetValueEx((HKEY)(TheDirKey(dkey)->handle),namez,0,
                                  REG_BINARY,TheSbvector(arr)->data+idx,
                                  len-idx));
    } else {
      pushSTACK(value);
      pushSTACK(TheSubr(subr_self)->name);
      fehler(error,GETTEXT("~ on ~ is illegal"));
    }
  });
  VALUES1(value);
  skipSTACK(3);
}

#define REG_KEY_DEL(call)                                       \
  STACK_0 = check_string(STACK_0);                              \
 {var object dkey = test_dir_key(STACK_1,true);                 \
  var object name = STACK_0; skipSTACK(2);                      \
  if (!stringp(name)) fehler_string(name);                      \
  with_string_0(name,O(misc_encoding),namez,{                   \
    SYSCALL_WIN32(call((HKEY)(TheDirKey(dkey)->handle),namez)); \
  });}                                                          \
  VALUES1(NIL)

# (LDAP:DIR-KEY-SUBKEY-DELETE key name)
# delete the specified subkey (and all its subkeys)
LISPFUNN(dir_key_subkey_delete,2) {
  REG_KEY_DEL(RegDeleteKey);
}
# (LDAP:DIR-KEY-VALUE-DELETE key name)
# delete the specified value
LISPFUNN(dir_key_value_delete,2) {
  REG_KEY_DEL(RegDeleteValue);
}
#undef REG_KEY_DEL

#ifdef UNIX_CYGWIN32
/* Cygwin internal in <src/winsup/cygwin/times.cc> */
/* Convert a Win32 time to "UNIX" format. */
#define FACTOR (0x19db1ded53ea710LL)
#define NSPERSEC 10000000LL
local long to_time_t_ (FILETIME * ptr) {
  /* A file time is the number of 100ns since jan 1 1601
     stuffed into two long words.
     A time_t is the number of seconds since jan 1 1970.  */
  long rem;
  long long x =
    ((long long) ptr->dwHighDateTime << 32) + ((unsigned) ptr->dwLowDateTime);
  /* pass "no time" as epoch */
  if (x == 0) return 0;
  x -= FACTOR;               /* number of 100ns between 1601 and 1970 */
  rem = x % ((long long) NSPERSEC);
  rem += (NSPERSEC/2);
  x /= (long long) NSPERSEC;	/* number of 100ns in a second */
  x += (long long) (rem/NSPERSEC);
  return x;
}
#undef FACTOR
#undef NSPERSEC
#endif

# (LDAP::DKEY-INFO key)
# return all the info about the key, as 10 values:
# class; class_length;
# num_sub_keys; max_sub_key_length; max_class_length;
# num_values; max_value_name_length; max_value_length;
# security_descriptor; write_time
# can trigger GC
LISPFUNN(dkey_info,1) {
  var object dkey = test_dir_key(popSTACK(),true);
  var HKEY hkey = (HKEY)(TheDirKey(dkey)->handle);
  var char* class_name = NULL;
  var DWORD class_length;
  var DWORD num_sub_keys;
  var DWORD max_sub_key_length;
  var DWORD max_class_length;
  var DWORD num_values;
  var DWORD max_value_name_length;
  var DWORD max_value_length;
  var DWORD security_descriptor;
  var FILETIME write_time;
  SYSCALL_WIN32(RegQueryInfoKey(hkey,NULL,&class_length,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL));
  if (class_length > 0) {
    class_length++;
    class_name = (char*)alloca(class_length);
  }
  SYSCALL_WIN32(RegQueryInfoKey(hkey,class_name,&class_length,NULL,
                                &num_sub_keys,&max_sub_key_length,
                                &max_class_length,
                                &num_values,&max_value_name_length,
                                &max_value_length,
                                &security_descriptor,
                                &write_time));
  value1 = (class_name ? asciz_to_string(class_name,O(misc_encoding)) : NIL);
  value2 = L_to_I(num_sub_keys);
  value3 = L_to_I(max_sub_key_length);
  value4 = L_to_I(max_class_length);
  value5 = L_to_I(num_values);
  value6 = L_to_I(max_value_name_length);
  value7 = L_to_I(max_value_length);
  value8 = L_to_I(security_descriptor);
 #ifdef WIN32_NATIVE
  value9 = convert_time_to_universal(&write_time);
 #else
  {
   var time_t unix_time = to_time_t_(&write_time);
   value9 = convert_time_to_universal(&unix_time);
  }
 #endif
  mv_count = 9;
}

#undef SYSCALL_WIN32
#undef SYSCALL_LDAP

/* see win32.d */
#ifdef UNICODE_SAVED
  #define UNICODE
#endif

#endif # DIR_KEY
