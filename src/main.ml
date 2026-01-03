open Unix

module Fsm : sig
  type control
  type action
  type rule
  type transition
  type state

  val print_state : int -> state -> unit
  val print_outputs : state -> unit
  val print_rule : rule -> unit
  val create_states :  rule list -> state list
  val control_to_string : control -> string
  val parse_file : in_channel -> rule list -> rule list
  val rules_to_control : rule list -> control list
  val find_transition : control -> state -> int option
end = 
struct
  type control = BackPunch | FrontPunch | FrontKick | Block | Left | Right
  type action = string
  type rule = control list * action
  type transition = control * int
  type state  = {
    transitions : (control * int) list;
    outputs : string list option;
  }

  let dedup lst =
    List.fold_left
      (fun acc x -> if List.mem x acc then acc else x :: acc)
      [] lst
    |> List.rev

  let rules_to_control (rules : rule list) : control list =
    rules
    |> List.map fst        
    |> List.concat         
    |> dedup               

  let string_to_control token =
    match token with
    | "[BP]" -> Some(BackPunch)
    | "[FP]" -> Some(FrontPunch)
    | "[FK]" -> Some(FrontKick)
    | "[BLOCK]" -> Some(Block)
    | "[LEFT]" -> Some(Left)
    | "[RIGHT]" -> Some(Right)
    | _ -> None

  let control_to_string c =
    match c with
    | BackPunch -> "[BP] "
    | FrontPunch -> "[FP] "
    | FrontKick -> "[FK] "
    | Block -> "[BLOCK] "
    | Left -> "[LEFT] "
    | Right -> "[RIGHT] "

  let parse_control (line: string): control list =
    let parts = String.split_on_char ' ' (String.trim line) in
    List.filter_map string_to_control parts

  let rec parse_file (channel : in_channel) (rules : rule list) : rule list =
    try
      let line = input_line channel in
      match String.split_on_char '=' line with
      | [control; action] ->
          (match parse_control control with
          | [] -> Printf.printf "Invalid line: %s\n" line; exit 1
          | r -> parse_file channel ((r, String.trim action) :: rules))
      | _ -> Printf.printf "Invalid line: %s\n" line; exit 1
    with End_of_file ->
      close_in channel;
      List.rev rules

  let find_transition (control: control) (current_state: state): int option =
    List.assoc_opt control current_state.transitions

  let create_states (rules: rule list): state list =
    let rec add_rule ((controls, action) : rule) (states : state list) (state_index : int) : state list =
      match controls with
      | head :: tail -> (
          match find_transition head (List.nth states state_index) with
          | Some next_index -> add_rule (tail, action) states next_index
          | None ->
              let new_index = List.length states in
              let cur_state = List.nth states state_index in
              let cur_state_with_new_transition =
                { cur_state with transitions = (head, new_index) :: cur_state.transitions }
              in
              (* replace current state with the new one that has 1 more transition *)
              let updated_states = List.mapi 
                (fun index s -> if index = state_index then cur_state_with_new_transition else s)
                states in
              add_rule (tail, action) (updated_states @ [{ transitions = []; outputs = None }]) new_index
        )
      | [] ->
          let cur_state = List.nth states state_index in
          let cur_state_with_new_action =
            let new_outputs =
              match cur_state.outputs with
              | None -> Some [action]
              | Some actions -> Some (actions @ [action])
            in
            { cur_state with outputs = new_outputs }
          in
          let updated_states = List.mapi 
            (fun index s -> if index = state_index then cur_state_with_new_action else s)
            states in
          updated_states
    in

    let empty_state = [{ transitions = []; outputs = None }] in
    List.fold_left (fun states rule -> add_rule rule states 0) empty_state rules

  let print_rule ((c, a): rule) =
    List.iter (fun ctrl -> print_string (control_to_string ctrl)) c;
    print_endline a

  let print_state (index: int) (state: state) =
    if index == -1 then 
      print_endline "\n=======Current State======\n"
    else 
      Printf.printf "======== State %d ========\n" index;

    List.iter
      (fun (c, i) -> Printf.printf "%s -> %d\n" (control_to_string c) i)
      state.transitions;

    match state.outputs with
    | Some outs -> 
        print_endline "Outputs: ";
        List.iter print_endline outs
    | None -> ();

    print_endline "==========================\n\n\n"

  let print_outputs (state : state) =
    match state.outputs with
    | None -> ()
    | Some outs -> List.iter (fun a -> Printf.printf "ACTION: %s!\n" a) outs
end

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
  let available_keys = [ 'a'; 'd'; 'p'; 'k'; 'b'; 'A' ] in
  map_key_to_control available_keys controls []

let char_to_control keymap ch = List.assoc_opt ch keymap

let print_game_info debug rules states keymap =
  if debug then (
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

let () =
  try
    let grammar_path =
      if Array.length Sys.argv >= 2 then Sys.argv.(1) else "grammar/main.grm"
    in
    let file = open_in grammar_path in
    let rules = Fsm.parse_file file [] in
    let states = Fsm.create_states rules in
    let controls = Fsm.rules_to_control rules in
    let keymap = build_keymap controls in
    
    let debug = Array.length Sys.argv > 2 && Sys.argv.(2) = "debug" in
    print_game_info debug rules states keymap;

    let rec game state sequence =
      Fsm.print_outputs state;
      if debug then Fsm.print_state (-1) state;

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
    Printf.printf "ERROR: %s!\n" e