let () = 
  try
    let channel = open_in "grammar/first.grm" in
    Grammar.create_grammar channel
  with Sys_error error -> 
    print_string "ERROR: ";
    print_endline error
