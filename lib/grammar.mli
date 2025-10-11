type control =  BackPunch | FrontPunch
type action = string
type rule = control list * action

val print_rules : rule list -> unit
val create_grammar : in_channel -> rule list -> rule list
