# Liste aller SUBRs mit Keywords
# Bruno Haible 1990-2000

v(7, (kw(adjustable),kw(element_type),kw(initial_element),
      kw(initial_contents),kw(fill_pointer),
      kw(displaced_to),kw(displaced_index_offset)) )
s(make_array)
v(6, (kw(element_type),kw(initial_element),
      kw(initial_contents),kw(fill_pointer),
      kw(displaced_to),kw(displaced_index_offset)) )
s(adjust_array)
v(4, (kw(start1),kw(end1),kw(start2),kw(end2)) )
s(string_gleich)
s(string_ungleich)
s(string_kleiner)
s(string_groesser)
s(string_klgleich)
s(string_grgleich)
s(string_equal)
s(string_not_equal)
s(string_lessp)
s(string_greaterp)
s(string_not_greaterp)
s(string_not_lessp)
s(search_string_gleich)
s(search_string_equal)
s(replace)
v(1, (kw(initial_element)) )
s(make_list)
v(2, (kw(initial_element),kw(element_type)) )
s(make_string)
v(2, (kw(start),kw(end)) )
s(string_width)
s(nstring_upcase)
s(string_upcase)
s(nstring_downcase)
s(string_downcase)
s(nstring_capitalize)
s(string_capitalize)
s(write_string)
s(write_line)
s(coerced_subseq)
s(fill)
s(read_char_sequence)
s(write_char_sequence)
s(read_byte_sequence)
s(write_byte_sequence)
s(convert_string_from_bytes)
s(convert_string_to_bytes)
v(4, (kw(charset),kw(line_terminator),kw(input_error_action),kw(output_error_action)) )
s(make_encoding)
v(6, (kw(weak),kw(initial_contents),
      kw(test),kw(size),kw(rehash_size),kw(rehash_threshold)) )
s(make_hash_table)
v(3, (kw(preserve_whitespace),kw(start),kw(end)) )
s(read_from_string)
v(4, (kw(start),kw(end),kw(radix),kw(junk_allowed)) )
s(parse_integer)
v(17, (kw(case),kw(level),kw(length),kw(gensym),kw(escape),kw(radix),
       kw(base),kw(array),kw(circle),kw(pretty),kw(closure),kw(readably),
       kw(lines),kw(miser_width),kw(pprint_dispatch),
       kw(right_margin),kw(stream)))
s(write)
v(16, (kw(case),kw(level),kw(length),kw(gensym),kw(escape),kw(radix),
       kw(base),kw(array),kw(circle),kw(pretty),kw(closure),kw(readably),
       kw(lines),kw(miser_width),kw(pprint_dispatch),kw(right_margin)))
s(write_to_string)
v(2, (kw(type),kw(identity)) )
s(write_unreadable)
v(2, (kw(test),kw(test_not)) )
s(tree_equal)
v(3, (kw(test),kw(test_not),kw(key)) )
s(subst)
s(nsubst)
s(sublis)
s(nsublis)
s(member)
s(adjoin)
s(assoc)
s(rassoc)
v(1, (kw(key)) )
s(subst_if)
s(subst_if_not)
s(nsubst_if)
s(nsubst_if_not)
s(member_if)
s(member_if_not)
s(assoc_if)
s(assoc_if_not)
s(rassoc_if)
s(rassoc_if_not)
s(merge)
v(3, (kw(nicknames),kw(use),kw(case_sensitive)) )
s(make_package)
s(pin_package)
v(2, (kw(initial_element),kw(update)) )
s(make_sequence)
v(5, (kw(from_end),kw(start),kw(end),kw(key),kw(initial_value)) )
s(reduce)
v(7, (kw(from_end),kw(start),kw(end),kw(key),kw(test),kw(test_not),kw(count)) )
s(remove)
s(delete)
s(substitute)
s(nsubstitute)
v(5, (kw(from_end),kw(start),kw(end),kw(key),kw(count)) )
s(remove_if)
s(remove_if_not)
s(delete_if)
s(delete_if_not)
s(substitute_if)
s(substitute_if_not)
s(nsubstitute_if)
s(nsubstitute_if_not)
v(6, (kw(from_end),kw(start),kw(end),kw(key),kw(test),kw(test_not)) )
s(remove_duplicates)
s(delete_duplicates)
s(find)
s(position)
s(count)
v(4, (kw(from_end),kw(start),kw(end),kw(key)) )
s(find_if)
s(find_if_not)
s(position_if)
s(position_if_not)
s(count_if)
s(count_if_not)
v(8, (kw(start1),kw(end1),kw(start2),kw(end2),kw(from_end),
      kw(key),kw(test),kw(test_not)) )
s(mismatch)
s(search)
v(3, (kw(key),kw(start),kw(end)) )
s(sort)
s(stable_sort)
v(3, (kw(start),kw(end),kw(junk_allowed)) )
s(parse_namestring)
v(1, (kw(case)) )
s(pathnamehost)
s(pathnamedevice)
s(pathnamedirectory)
s(pathnamename)
s(pathnametype)
#ifdef LOGICAL_PATHNAMES
v(0,_EMA_)
s(translate_logical_pathname)
#endif
v(1, (kw(wild)) )
s(merge_pathnames)
v(8, (kw(defaults),kw(case),kw(host),kw(device),kw(directory),kw(name),kw(type),kw(version)) )
s(make_pathname)
#ifdef LOGICAL_PATHNAMES
s(make_logical_pathname)
#endif
v(2, (kw(all),kw(merge)) )
s(translate_pathname)
v(6, (kw(direction),kw(element_type),kw(if_exists),kw(if_does_not_exist),kw(external_format),kw(buffered)) )
s(open)
v(2, (kw(circle),kw(full)) )
s(directory)
v(2, (kw(element_type),kw(line_position)) )
s(make_string_output_stream)
#ifdef PIPES
v(3, (kw(element_type),kw(external_format),kw(buffered)) )
s(make_pipe_input_stream)
s(make_pipe_output_stream)
#ifdef PIPES2
s(make_pipe_io_stream)
#endif
#endif
#ifdef SOCKET_STREAMS
v(4, (kw(element_type),kw(external_format),kw(buffered),kw(timeout)) )
s(socket_accept)
s(socket_connect)
#endif
v(1, (kw(abort)) )
s(built_in_stream_close)
#ifdef REXX
v(5, (kw(result),kw(string),kw(token),kw(host),kw(io)) )
s(rexx_put)
#endif
v(1, (kw(verbose)))
s(ensure_directories_exist)
#ifdef DIR_KEY
v(2, (kw(direction),kw(if_does_not_exist)))
s(dir_key_open)
#endif
#if defined(EXPORT_SYSCALLS) && defined(HAVE_FLOCK)
v(2, (kw(shared),kw(block)))
s(stream_lock)
#endif
