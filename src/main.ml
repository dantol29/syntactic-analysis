open Unix

let available_keys = [ 'a'; 'd'; 'p'; 'k'; 'b'; 'A' ]

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
  let rec aux keys ctrls acc =
    match keys, ctrls with
    | k :: ks, c :: cs ->
        aux ks cs ((k, c) :: acc)
    | _, [] ->
        List.rev acc
    | [], _ :: _ ->
        failwith "Not enough keys for all controls"
  in
  aux available_keys controls []

let char_to_control keymap ch =
  List.assoc_opt ch keymap

let control_to_key (keymap : (char * Fsm.control) list) (control : Fsm.control)
  : char option =
  keymap
  |> List.find_opt (fun (_, c) -> c = control)
  |> Option.map fst

let keys_for_rule keymap (controls, action) =
  let rec aux cs acc =
    match cs with
    | [] -> Some (List.rev acc, action)
    | c :: rest ->
        (match control_to_key keymap c with
         | None -> None
         | Some k -> aux rest (k :: acc))
  in
  aux controls []

let () =
  try
    let grammar_path =
      if Array.length Sys.argv >= 2 then Sys.argv.(1) else "grammar/main.grm"
    in
    let file = open_in grammar_path in
    let rules = Fsm.parse_file file [] in
    let states = Fsm.create_states rules in

    let controls_used = Fsm.controls_from_rules rules in

    let canonical_controls =
      [ Fsm.Left;
        Fsm.Right;
        Fsm.FrontPunch;
        Fsm.FrontKick;
        Fsm.BackPunch;
        Fsm.Block;
      ]
    in

    let controls =
      List.filter (fun c -> List.mem c controls_used) canonical_controls
    in

    let keymap = build_keymap controls in

    let debug =
      Array.length Sys.argv > 2 && Sys.argv.(2) = "debug"
    in

    if debug then begin
      print_endline "Loaded Grammar: \n";
      List.iter Fsm.print_rule (List.rev rules);
      print_endline "\nFSM States: \n";
      List.iteri Fsm.print_state states;
      print_endline ""
    end;

    print_endline "Key Mappings:";
    List.iter
      (fun (k, c) ->
         Printf.printf "%c -> %s\n" k (Fsm.control_to_string c))
      keymap;

    print_endline "\nMove Combos:";
    List.rev rules
    |> List.iter (fun rule ->
           match keys_for_rule keymap rule with
           | None -> ()  
           | Some (keys, action) ->
               List.iter (fun k -> Printf.printf "%c " k) keys;
               Printf.printf "-> %s\n" action
       );

    print_endline "----------------------";

    let rec game state index =
      if debug then Fsm.print_state index state;

      let ch = read_char () in
      match char_to_control keymap ch with
      | None ->
          game state index
      | Some control ->
          Printf.printf "%s%!" (Fsm.control_to_string control);

          let next_index_opt =
            match Fsm.find_transition control state with
            | Some i -> Some i
            | None -> Fsm.find_transition control (List.nth states 0)
          in
          match next_index_opt with
          | None ->
              game (List.nth states 0) 0
          | Some next_index ->
              let next_state = List.nth states next_index in
              Fsm.print_outputs next_state;
              game next_state next_index
    in

    game (List.nth states 0) 0

  with Sys_error e ->
    Printf.printf "ERROR: %s\n!" e
