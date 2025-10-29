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

let read_char_no_enter () : char =
  let term = tcgetattr stdin in
  let old = { term with c_icanon = true } in
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

let advance (states : Fsm.state list) (current : int) (c : Fsm.control) : int =
  let next_from idx =
    try Some (List.assoc c (List.nth states idx).Fsm.transitions)
    with Not_found -> None
  in
  match next_from current with
  | Some nxt ->
      Fsm.print_state current (List.nth states nxt);
      nxt
  | None ->
      (match next_from 0 with
       | Some nxt0 ->
           Fsm.print_state current (List.nth states nxt0);
           nxt0
       | None -> 0)

let () =
  try
    let grammar_path =
      if Array.length Sys.argv >= 2 then Sys.argv.(1) else "grammar/main.grm"
    in
    let ch = open_in grammar_path in
    let rules = Fsm.parse_file ch [] in

    Printf.printf "📜 Loaded Grammar: \n";
    let rules_rev = List.rev rules in
    Fsm.print_rules rules_rev;

    Printf.printf "🧩 FSM States: \n";
    let states = Fsm.create_states rules_rev in
    List.iteri Fsm.print_state states;

    ignore (
     let running = ref true in
     let current = ref 0 in
      while !running do
       let c = read_char_no_enter () in
       match char_to_control c with
         | Some ctrl -> current := advance states !current ctrl
         | None -> running := false
       done
     )

  with Sys_error e ->
    Printf.printf "ERROR: %s\n!" e
