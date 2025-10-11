let () = 
  try
    let channel = open_in "grammar/first.grm" in
    let rules = Grammar.create_grammar channel [] in 
    Grammar.print_rules rules
  with Sys_error error -> 
    print_string "ERROR: ";
    print_endline error
