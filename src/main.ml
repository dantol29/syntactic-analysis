open Unix

let with_raw_terminal f =
  let termio = tcgetattr stdin in
  let raw = { termio with c_icanon = false; c_echo = false } in
  tcsetattr stdin TCSANOW raw;
  try
    let result = f () in
    tcsetattr stdin TCSANOW termio;
    result
  with e ->
    tcsetattr stdin TCSANOW termio;
    raise e

let read_char () =
  with_raw_terminal (fun () ->
    let buf = Bytes.create 1 in
    if read stdin buf 0 1 = 1 then Bytes.get buf 0 else '\000')

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
    let file = open_in grammar_path in
    let rules = Fsm.parse_file file [] in
    let states = Fsm.create_states rules in
    
    if Array.length Sys.argv > 2 && Sys.argv.(2) = "debug" then begin
      print_endline "Loaded Grammar: \n";
      List.iter Fsm.print_rule (List.rev rules);
      print_endline "\nFSM States: \n";
      List.iteri Fsm.print_state states;
    end;

    print_endline "Key Mappings:";
    (* TODO *)

    let rec game state index =
      Fsm.print_state index state;

      match char_to_control (read_char ()) with
      | None -> game state index (* invalid input -> stay at the same state *)
      | Some control ->
          let next_index_opt =
            match Fsm.find_transition control state with
            | Some i -> Some i
            | None -> Fsm.find_transition control (List.nth states 0)
          in  (* if transition in current state not found -> search in 0 state *)

          match next_index_opt with
          | None -> game (List.nth states 0) 0  (* transition not found both in current and in 0 state -> go to 0 state *)
          | Some next_index -> game (List.nth states next_index) next_index
    in

  game (List.nth states 0) 0

  with Sys_error e ->
    Printf.printf "ERROR: %s\n!" e
