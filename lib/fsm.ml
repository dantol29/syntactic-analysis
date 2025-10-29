type control =  BackPunch | FrontPunch |  FrontKick | Block | Left | Right
type action = string
type rule = control list * action

type transition = control * int
type state  = {
  transitions : (control * int) list;
  outputs : string list option;
}

let get_control_type token =
  match token with
  | "[BP]" -> Some(BackPunch)
  | "[FP]" -> Some(FrontPunch)
  | "[FK]" -> Some(FrontKick)
  | "[BLOCK]" -> Some(Block)
  | "[LEFT]" -> Some(Left)
  | "[RIGHT]" -> Some(Right)
  | _ -> None

let parse_control (line: string): control list = 
  let trimmed_line = String.trim line in
  let parts = String.split_on_char ' ' trimmed_line in
  List.filter_map (get_control_type) parts

let rec parse_file (channel : in_channel) (rules : rule list) : rule list =
  try
    let line = input_line channel in
    match String.split_on_char '=' line with
    | [control; action] ->
        (match parse_control control with
        | [] ->
            print_endline "Invalid controls";
            parse_file channel rules
        | r ->
            parse_file channel ((r, action) :: rules))
    | _ ->
        print_endline "No delimiter";
        parse_file channel rules
  with End_of_file ->
    close_in channel;
    rules

let create_states (rules: rule list) : state list =
  let states = ref [{transitions = []; outputs = None}] in

  let get_transition ctrl state_idx =
    try Some (List.assoc ctrl (List.nth !states state_idx).transitions)
    with Not_found -> None
  in

  let add_transition from_state ctrl to_state =
    let st = List.nth !states from_state in
    let new_transitions = (ctrl, to_state) :: st.transitions in
    let updated = {st with transitions = new_transitions} in
    states := List.mapi (fun i s -> if i = from_state then updated else s) !states
  in

  let set_outputs state_idx outputs =
    let st = List.nth !states state_idx in
    let updated = {st with outputs = outputs} in
    states := List.mapi (fun i s -> if i = state_idx then updated else s) !states
  in

  let process_rule (controls, output) =
    let current = ref 0 in
    List.iter (fun ctrl ->
      match get_transition ctrl !current with
      | Some next -> current := next
      | None ->
          let new_idx = List.length !states in
          add_transition !current ctrl new_idx;
          states := !states @ [{transitions = []; outputs = None}];
          current := new_idx
    ) controls;
  
    let old_outputs = (List.nth !states !current).outputs in
    let new_outputs = 
      match old_outputs with
      | None -> Some [output]
      | Some outputs_list -> Some (outputs_list @ [output])
    in
    set_outputs !current new_outputs
  in

  List.iter process_rule rules;
  !states


(* PRINTS FOR DEBUG *)

let print_control = function
| BackPunch -> print_string "[BP] "
| FrontPunch -> print_string "[FP] "
| FrontKick -> print_string "[FK] "
| Block -> print_string "[BLOCK] "
| Left -> print_string "[LEFT] "
| Right -> print_string "[RIGHT] "

let print_rule ((c, a): rule) =
  List.iter print_control c;
  print_string a;
  print_newline ()

let print_rules (rules: rule list) = 
  List.iter print_rule rules;
  print_newline ()

let print_transition ((c, i): transition) = 
  print_control c;
  print_string " -> ";
  print_int i;
  print_newline ()

let print_state (index: int) (state: state) = 
  print_string "=======State ";
  print_int index;
  print_endline "=======";

  List.iter print_transition state.transitions;

  (match state.outputs with
  | Some s -> (List.iter print_endline s; print_newline ())
  | None -> ());

  print_endline "======================\n\n\n"
