type control =  BackPunch | FrontPunch |  FrontKick | Block | Left | Right
type action = string
type rule = control list * action

type transition = control * int
type state  = {
  transitions : (control * int) list;
  outputs : string list option;
}

let string_to_control token =
  match token with
  | "[BP]" -> Some(BackPunch)
  | "[FP]" -> Some(FrontPunch)
  | "[FK]" -> Some(FrontKick)
  | "[BLOCK]" -> Some(Block)
  | "[LEFT]" -> Some(Left)
  | "[RIGHT]" -> Some(Right)
  | _ -> None
 
let control_to_string = function
  | BackPunch -> "[BP] "
  | FrontPunch -> "[FP] "
  | FrontKick -> "[FK] "
  | Block -> "[BLOCK] "
  | Left -> "[LEFT] "
  | Right -> "[RIGHT] "

let parse_control (line: string): control list = 
  let trimmed_line = String.trim line in
  let parts = String.split_on_char ' ' trimmed_line in
  List.filter_map string_to_control parts

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

let find_transition (control: control) (current_state: state): int option =
  List.assoc_opt control current_state.transitions

let update_state (states : state list) (index : int) (new_state : state) : state list =
  List.mapi (fun i s -> if i = index then new_state else s) states

let rec add_rule ((controls, action) : rule) (states : state list) (state_index : int) : state list =
  match controls with
  | head :: tail -> (
      match find_transition head (List.nth states state_index) with
      | Some next_index ->
          add_rule (tail, action) states next_index (* follow existing transition*)
      | None ->
          let new_state = { transitions = []; outputs = None } in
          let new_index = List.length states in
          let current = List.nth states state_index in
          let updated_current =
            { current with transitions = (head, new_index) :: current.transitions }
          in
          let states = update_state states state_index updated_current in
          let states = states @ [new_state] in
          add_rule (tail, action) states new_index
    )
  | [] ->
      let current = List.nth states state_index in
      let updated_current = 
        let new_outputs = 
          match current.outputs with
            | None -> Some [action]
            | Some actions -> Some (actions @ [action])
          in
         { current with outputs = new_outputs }
      in
      update_state states state_index updated_current

let create_states (rules: rule list): state list =
  let initial_state = [{ transitions = []; outputs = None }] in
  List.fold_left (fun states rule -> add_rule rule states 0) initial_state rules

let print_rule ((c, a): rule) =
  List.iter (fun ctrl -> print_string (control_to_string ctrl)) c;
  print_endline a

let print_state (index: int) (state: state) = 
  Printf.printf "======= State %d ======\n" index;
  List.iter (fun (c, i) -> Printf.printf "%s -> %d\n" (control_to_string c) i) state.transitions;
  Option.iter (List.iter print_endline) state.outputs;
  print_endline "======================\n\n\n"
