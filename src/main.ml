open Unix

let with_raw_terminal f =
  let termio = tcgetattr stdin in
  let raw = { termio with
    c_icanon = false;
    c_echo = false;
  } in
  tcsetattr stdin TCSANOW raw;
  try
    let result = f () in
    tcsetattr stdin TCSANOW termio;
    result
  with e ->
    tcsetattr stdin TCSANOW termio;
    raise e

let read_char () : char =
  let term = tcgetattr stdin in
  let raw = { term with c_icanon = false; c_echo = false } in
  tcsetattr stdin TCSANOW raw;
  let buf = Bytes.create 1 in
  let n = read stdin buf 0 1 in
  tcsetattr stdin TCSANOW term;
  if n = 1 then Bytes.get buf 0 else '\000'

let char_to_control = function
  | 'a' -> Some Fsm.Left
  | 'd' -> Some Fsm.Right
  | 'p' -> Some Fsm.FrontPunch
  | 'k' -> Some Fsm.FrontKick
  | 'b' -> Some Fsm.BackPunch
  | 'A' -> Some Fsm.Block
  | _ -> None

let () =
  try
    let grammar_path =
      if Array.length Sys.argv >= 2 then Sys.argv.(1) else "grammar/main.grm"
    in
    let ch = open_in grammar_path in
    let rules = Fsm.parse_file ch [] in

    print_endline "Loaded Grammar: \n";
    let rules_rev = List.rev rules in
    List.iter Fsm.print_rule rules_rev;

    print_endline "FSM States: \n";
    let states = Fsm.create_states rules_rev in
    List.iteri Fsm.print_state states;

    print_endline "===========START============ \n";

    let rec game (current_state : Fsm.state) (index : int) = 
      Fsm.print_state index current_state;

      let c = read_char () in
      match char_to_control c with
        | Some control ->
            (match Fsm.find_transition control current_state with
               | Some next_state -> game (List.nth states next_state) next_state
               | None -> game (List.nth states 0) 0)
        | None -> ()
    in
     

    game (List.nth states 0) 0;

    print_endline "============END============= \n";
  with Sys_error e ->
    Printf.printf "ERROR: %s\n!" e
