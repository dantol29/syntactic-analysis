type control =  BackPunch | FrontPunch
type action = string
type rule = control list * action

type state_index = int64
type state_transition_func = control * state_index
type state = state_index * state_transition_func list
type state_table = state list

let get_control_type token =
  match token with
  | "[BP]" -> Some(BackPunch)
  | "[FP]" -> Some(FrontPunch)
  | _ -> None

let print_control = function
  | BackPunch -> print_string "[BP] "
  | FrontPunch -> print_string "[FP] "

let print_rule ((c, a): rule) =
  List.iter print_control c;
  print_string a;
  print_endline " end"

let print_rules (rules: rule list) = 
  List.iter print_rule rules

let parse_control (line: string): control list = 
  let trimmed_line = String.trim line in
  let parts = String.split_on_char ' ' trimmed_line in
  List.filter_map (get_control_type) parts

let rec create_grammar (channel : in_channel) (rules : rule list) : rule list =
  try
    let line = input_line channel in
    match String.split_on_char '=' line with
    | [control; action] ->
        (match parse_control control with
        | [] ->
            print_endline "Invalid controls";
            create_grammar channel rules
        | r ->
            create_grammar channel ((r, action) :: rules))
    | _ ->
        print_endline "No delimiter";
        create_grammar channel rules
  with End_of_file ->
    close_in channel;
    rules

let create_transitions (rules: rule list) (state_table: state_table) = 
  (* TODO *)
