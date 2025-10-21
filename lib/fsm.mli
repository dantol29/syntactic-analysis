type control =  BackPunch | FrontPunch |  FrontKick | Block | Left | Right
type action = string
type rule = control list * action
type transition = control * int
type state  = {
    transitions : (control * int) list;
    outputs : string list option;
  }

val parse_file : in_channel -> rule list -> rule list
val create_states: rule list -> state list
val print_state: int -> state -> unit
val print_rules : rule list -> unit
