open Unix

let available_keys = [ 'a'; 'd'; 'p'; 'k'; 'b'; 'A' ]
let available_controls = [ Fsm.Left; Fsm.Right; Fsm.FrontPunch; Fsm.FrontKick; Fsm.BackPunch; Fsm.Block; ]

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

let build_keymap (controls : Fsm.control list) : (char * Fsm.control) list =
  let rec map_key_to_control keys ctrls acc =
    match keys, ctrls with
    | key_head :: key_tail, ctrl_head :: ctrl_tail ->
        map_key_to_control key_tail ctrl_tail ((key_head, ctrl_head) :: acc)
    | _, [] ->
        List.rev acc
    | [], _ :: _ ->
        failwith "Not enough keys for all controls"
  in
  map_key_to_control available_keys controls []

let char_to_control keymap ch =
  List.assoc_opt ch keymap

let print_game_info debug rules states keymap =
  (
    if debug then (
      print_endline "Loaded Grammar: \n";
      List.iter Fsm.print_rule rules;
      print_endline "\nFSM States: \n";
      List.iteri Fsm.print_state states;
      print_endline ""
    );

    print_endline "Key Mappings:";
    List.iter
      (fun (k, c) -> Printf.printf "%c -> %s\n" k (Fsm.control_to_string c))
      keymap;

    print_endline "\nMove Combos:";
    List.iter Fsm.print_rule rules;

    print_endline "----------------------"
  )

let () =
  try
    let debug = Array.length Sys.argv > 2 && Sys.argv.(2) = "debug" in
    let grammar_path =
      if Array.length Sys.argv >= 2 then Sys.argv.(1) else "grammar/main.grm"
    in
    let file = open_in grammar_path in
    let rules = Fsm.parse_file file [] in
    let states = Fsm.create_states rules in
    let controls = Fsm.rules_to_control rules in
    let keymap = build_keymap controls in

    print_game_info debug rules states keymap;

    let rec game state sequence =
      Fsm.print_outputs state;
      if debug then Fsm.print_state_debug state;

      let ch = read_char () in
      match char_to_control keymap ch with
      | None -> game state sequence
      | Some control ->
          print_string "Sequence: ";
          let ctrl_str = Fsm.control_to_string control in
          match Fsm.find_transition control state with
          | Some next_index ->
              print_endline (sequence ^ ctrl_str);
              game (List.nth states next_index) (sequence ^ ctrl_str)
          | None -> 
              print_endline ctrl_str;
              match Fsm.find_transition control (List.nth states 0) with
              | None -> game (List.nth states 0) ctrl_str
              | Some next_index -> game (List.nth states next_index) ctrl_str
    in

    game (List.nth states 0) ""

  with Sys_error e ->
    Printf.printf "ERROR: %s\n!" e