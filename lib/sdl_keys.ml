(* (*
  sdl_keys.ml — extended mapping for Mortal Kombat controls
  ----------------------------------------------------------
  Maps SDL keys to simple label strings used by your FSM.
*)

let label_of_key (k : Sdlkey.t) : string option =
  match k with
  (* basic directions *)
  | Sdlkey.KEY_LEFT   -> Some "left"
  | Sdlkey.KEY_RIGHT  -> Some "right"
  | Sdlkey.KEY_UP     -> Some "up"
  | Sdlkey.KEY_DOWN   -> Some "down"

  (* attack buttons *)
  | Sdlkey.KEY_a      -> Some "bp"        (* Back Punch *)
  | Sdlkey.KEY_s      -> Some "fp"        (* Front Punch *)
  | Sdlkey.KEY_d      -> Some "fk"        (* Front Kick *)
  | Sdlkey.KEY_f      -> Some "bk"        (* Back Kick *)

  (* block + special controls *)
  | Sdlkey.KEY_LSHIFT
  | Sdlkey.KEY_RSHIFT -> Some "block"
  | Sdlkey.KEY_t      -> Some "tag"
  | Sdlkey.KEY_SPACE  -> Some "flipstance"

  | _ -> None *)
(*
  lib/sdl_keys.ml
  Maps SDL keys (Sdlkey.t) to simple lowercase labels used by the FSM.
  This version matches *only* the controls that exist in your current fsm.ml.
*)

let label_of_key (k : Sdlkey.t) : string option =
  match k with
  (* directions *)
  | Sdlkey.KEY_LEFT   -> Some "left"
  | Sdlkey.KEY_RIGHT  -> Some "right"
  (* attacks *)
  | Sdlkey.KEY_s      -> Some "fp"   (* Front Punch *)
  | Sdlkey.KEY_d      -> Some "fk"   (* Front Kick *)
  | Sdlkey.KEY_a      -> Some "bp"   (* Back Punch *)
  (* block *)
  | Sdlkey.KEY_LSHIFT
  | Sdlkey.KEY_RSHIFT -> Some "block"
  | _ -> None
