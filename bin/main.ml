let () = 
  try
    let channel = open_in "grammar/main.grm" in
    let rules = Fsm.parse_file channel [] in 
    
    print_endline "Grammar: \n";
    let reversed_rules = List.rev rules in
    Fsm.print_rules reversed_rules;

    print_endline "States: \n";
    let states = Fsm.create_states reversed_rules in
    List.iteri Fsm.print_state states
  with Sys_error error -> 
    print_string "ERROR: ";
    print_endline error
