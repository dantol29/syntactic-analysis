(*
  ===============================================================
   Finite State Machine (FSM) for Combo Input Sequences
  ===============================================================

   ❖ Problem
   ----------
   In the original implementation, each state had only **one possible output**
   represented as `output : string option`.

   That meant if two different rules (combos) ended with the *same* input sequence,
   e.g.

       [LEFT] [RIGHT] = Fireball
       [LEFT] [RIGHT] = Shadow Kick

   only **one** of them could survive.
   The second rule would overwrite the first one,
   because the final state for [LEFT][RIGHT] already existed
   and its single `output` field was replaced.

   ❖ Why this happens
   ------------------
   The FSM is built as a trie of input sequences (`control list`),
   where each control corresponds to one edge (transition).
   When two rules share the same sequence of controls,
   they both end in the same terminal node.
   With only one `output` slot, the second rule overwrote the first.

   ❖ Solution
   -----------
   Change the type of `output` from `string option` → `string list`.

   Now, each state can hold multiple actions (moves),
   so identical control sequences can map to multiple outcomes.

   In addition:
   - The `set_output` function now *appends* new actions
     instead of overwriting.
   - The `print_state` function prints all actions in the list.
   - All original code lines are kept and commented out for clarity.

   With this change, the FSM behaves like a proper "trie" of combos:
   shared prefixes are merged, and identical sequences can have
   multiple end actions.
*)

type control =  BackPunch | FrontPunch |  FrontKick | Block | Left | Right
type action = string
type rule = control list * action

type transition = control * int

(* OLD:
type state  = {
  transitions : (control * int) list;
  output : string option;
}
*)
(* NEW: each state can have multiple possible outputs (actions).
   For example, the same input sequence could trigger several moves.
   So we use a string list instead of a single optional string. *)
type state  = {
  transitions : (control * int) list;
  output : string list;  (* multiple actions per state possible *)
}

(* Convert token strings like "[BP]" or "[LEFT]" into control values *)
let get_control_type token =
  match token with
  | "[BP]" -> Some(BackPunch)
  | "[FP]" -> Some(FrontPunch)
  | "[FK]" -> Some(FrontKick)
  | "[BLOCK]" -> Some(Block)
  | "[LEFT]" -> Some(Left)
  | "[RIGHT]" -> Some(Right)
  | _ -> None

(* Split a string line like "[LEFT] [RIGHT]" into a list of control values *)
let parse_control (line: string): control list = 
  let trimmed_line = String.trim line in
  let parts = String.split_on_char ' ' trimmed_line in
  List.filter_map (get_control_type) parts

(* Parse grammar file lines of the form "[LEFT] [RIGHT] = Fireball" *)
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

(* Build the finite state machine (FSM) from the list of parsed rules *)
let create_states (rules: rule list) : state list =
  (* OLD:
  let states = ref [{transitions = []; output = None}] in
  *)
  (* NEW: initialize with an empty output list instead of None *)
  let states = ref [{transitions = []; output = []}] in

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

  (* OLD:
  let set_output state_idx output =
    let st = List.nth !states state_idx in
    let updated = {st with output = Some output} in
    states := List.mapi (fun i s -> if i = state_idx then updated else s) !states
  in
  *)
  (* NEW: append the new output to the existing list (no overwrite).
     This allows multiple actions to be stored in the same state. *)
  let set_output state_idx output =
    let st = List.nth !states state_idx in
    (* If this action already exists, don't duplicate it. *)
    let outs = if List.mem output st.output then st.output else st.output @ [output] in
    let updated = { st with output = outs } in
    states := List.mapi (fun i s -> if i = state_idx then updated else s) !states
  in

  (* For each rule, walk or create transitions through the FSM *)
  let process_rule (controls, output) =
    let current = ref 0 in
    List.iter (fun ctrl ->
      match get_transition ctrl !current with
      | Some next -> current := next
      | None ->
          let new_idx = List.length !states in
          add_transition !current ctrl new_idx;
          (* OLD:
          states := !states @ [{transitions = []; output = None}];
          *)
          (* NEW: new state starts with an empty list of outputs *)
          states := !states @ [{transitions = []; output = []}];
          current := new_idx
    ) controls;
    (* At the end of the control sequence, attach the action to that state *)
    set_output !current output
  in

  (* Apply the rule processor to all parsed rules *)
  List.iter process_rule rules;
  !states

(* ---------- PRINT FUNCTIONS FOR DEBUGGING ---------- *)

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
  print_string "State ";
  print_int index;
  print_newline ();

  List.iter print_transition state.transitions;

  (* OLD:
  (match state.output with
  | Some s -> (print_string s; print_newline ())
  | None -> ());
  *)
  (* NEW: print all stored actions (each on its own line) *)
  (match state.output with
  | [] -> ()
  | outs -> List.iter (fun s -> print_string s; print_newline ()) outs);

  print_newline ()


(* ---------- MAIN ENTRY POINT ---------- *)
(* let () =
  let ch = open_in "../grammar/main.grm" in
  let rules = parse_file ch [] in
  print_endline "Parsed rules:";
  print_rules rules;
  let states = create_states rules in
  List.iteri print_state states *)
