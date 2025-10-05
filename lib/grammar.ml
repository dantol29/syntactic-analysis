type controls =  BackPunch | FrontPunch

let pp_control = function
  | BackPunch -> print_string "[BP] "
  | FrontPunch -> print_string "[FP] "

let print_controls_iter lst =
  List.iter pp_control lst;
  print_newline ()

let get_control_type token =
  match token with
  | "[BP]" -> Some(BackPunch)
  | "[FP]" -> Some(FrontPunch)
  | _ -> None

let parse_control (line: string): controls list = 
  let trimmed_line = String.trim line in
  let parts = String.split_on_char ' ' trimmed_line in
  List.filter_map (get_control_type) parts

let rec create_grammar (channel: in_channel) : unit = 
  try
    let line = input_line channel in 
    
    (match String.split_on_char '=' line with
      | [control ; _action] -> 
          (match parse_control control with 
          | [] -> print_endline "incorrect control"
          | l -> print_controls_iter l)
      | _ -> print_endline "could not split");

    create_grammar channel;
  with End_of_file -> close_in channel
