(*
  ======================================================================
  A TINY, WELL-COMMENTED FINITE-STATE MACHINE (DFA) IN OCAML
  ======================================================================

  What you will learn in this file
  --------------------------------
  • How to *model* a deterministic finite automaton (DFA) as plain data.
  • How to take a single step on an input token, and how to read outputs.
  • How the math (Q, Σ, δ, q0, F) maps 1:1 to simple OCaml types.
  • Several small, concrete examples you can run and tweak.

  Audience
  --------
  Absolute beginners in OCaml and functional programming. All code is
  side-effect free (pure): functions consume an input and return a value,
  without mutating global state.

  ───────────────────────────────────────────────────────────────────────
  MATHEMATICAL BACKGROUND (short and friendly)
  ───────────────────────────────────────────────────────────────────────
  A deterministic finite automaton (DFA) consists of:

    • Q:     a *finite* set of states
    • Σ:     an input alphabet (here: our token type)
    • δ:     a transition function δ : Q × Σ → Q
    • q0:    a start state q0 ∈ Q
    • F:     a set of accepting (final) states F ⊆ Q

  In our *programmer-friendly* version:
    - Q is "states-as-integers" (type `state = int`).
    - Σ is a closed variant type `token` (the legal button names).
    - δ is a list of edges; we look them up with a small helper.
    - q0 is a single integer id (the "start_state").
    - F is a list of records that attach a list of move names to states.

  Because we are building a *pattern* recognizer for fighting-game inputs,
  each accepting state (∈ F) carries a list of "outputs" = move names.
  Multiple different rules can end in the *same* state (think: duplicate
  LHS with different move names) → that’s why we store `string list`.
*)

(*
  ───────────────────────────────────────────────────────────────────────
  1) The input alphabet Σ: our tokens (buttons/directions)
  ───────────────────────────────────────────────────────────────────────
  A *closed* algebraic data type (ADT) declares all allowed tokens.
  The compiler can then check "exhaustiveness" in pattern matches.
*)
type token =
  | LEFT | RIGHT | UP | DOWN
  | BLOCK | TAG | FLIPSTANCE
  | BP | FP | FK | BK | THROW

let string_of_token = function
  | LEFT -> "[LEFT]" | RIGHT -> "[RIGHT]" | UP -> "[UP]" | DOWN -> "[DOWN]"
  | BLOCK -> "[BLOCK]" | TAG -> "[TAG]" | FLIPSTANCE -> "[FLIPSTANCE]"
  | BP -> "[BP]" | FP -> "[FP]" | FK -> "[FK]" | BK -> "[BK]" | THROW -> "[THROW]"

(*
  ───────────────────────────────────────────────────────────────────────
  2) The state set Q and the DFA "shape"
  ───────────────────────────────────────────────────────────────────────
  We keep the DFA deliberately minimal: states are integers; the DFA is just
  a record of start state, transitions, and finals.
*)

(* A state is just a numeric id. *)
type state = int

(* One deterministic edge: from state `from_state`, on input `on_token`,
   the machine moves to `to_state`. *)
type transition = {
  from_state : state;
  on_token   : token;
  to_state   : state;
}

(* An accepting (final) state with the moves we emit when we *reach* it. *)
type final = {
  at_state : state;
  moves    : string list;  (* possibly more than one *)
}

(* The complete DFA value. *)
type automaton = {
  start_state : state;
  transitions : transition list;  (* δ as a lookup table *)
  finals      : final list;       (* F with attached output labels *)
}

(*
  ───────────────────────────────────────────────────────────────────────
  3) Tiny runner functions (pure, beginner-friendly)
  ───────────────────────────────────────────────────────────────────────
  • `find_edge` implements a tiny partial function δ : Q × Σ ⇀ Q.
    (It returns `None` if there is no outgoing edge for (s, tok).)

  • `step` chooses a *policy* for "no edge found". There are two common
    textbook choices to make δ *total* (always defined):

      (A) add a dedicated SINK state that eats everything and never accepts;
      (B) jump back to the start state (what we do here to keep things tiny).

    Both choices are fine; for learning, (B) is simpler.

  • `emits` checks if the current state is accepting and returns its labels.
*)

let find_edge (a : automaton) (s : state) (tok : token) : state option =
  let rec loop = function
    | [] -> None
    | {from_state; on_token; to_state} :: xs ->
        if from_state = s && on_token = tok then Some to_state else loop xs
  in
  loop a.transitions

let step (a : automaton) (s : state) (tok : token) : state =
  match find_edge a s tok with
  | Some s' -> s'
  | None -> a.start_state  (* simple policy: fall back to start *)

let emits (a : automaton) (s : state) : string list =
  let rec loop = function
    | [] -> []
    | {at_state; moves} :: xs -> if at_state = s then moves else loop xs
  in
  loop a.finals

(*
  ───────────────────────────────────────────────────────────────────────
  4) A concrete DFA for a small example (like the colleague’s drawing)
  ───────────────────────────────────────────────────────────────────────
  Rules we model here:

    [LEFT]  [RIGHT] [FP]                 = "Fireball"
    [LEFT]  [RIGHT] [FK]                 = "Shadow Kick"
    [RIGHT] [RIGHT] [RIGHT] [BP]         = "Finisher"
    [BLOCK] [FP]                         = "Low Blow"

  We create explicit node ids for clarity. You can renumber them as you like;
  the actual numbers do not matter as long as you are consistent.
*)

let s0 = 0  (* start *)
let s1 = 1
let s2 = 2
let s3 = 3
let s4 = 4
let s5 = 5
let s6 = 6
(* terminal states (the "OUTPUT" boxes) *)
let s_fireball    = 7
let s_shadow_kick = 8
let s_finisher    = 9
let s_low_blow    = 10

let fsm : automaton =
  {
    start_state = s0;

    transitions = [
      (* from start *)
      {from_state = s0; on_token = LEFT;  to_state = s1};
      {from_state = s0; on_token = RIGHT; to_state = s2};
      {from_state = s0; on_token = BLOCK; to_state = s3};

      (* left/right branch *)
      {from_state = s1; on_token = RIGHT; to_state = s4};
      {from_state = s4; on_token = FP;    to_state = s_fireball};
      {from_state = s4; on_token = FK;    to_state = s_shadow_kick};

      (* right/right/right/bp branch *)
      {from_state = s2; on_token = RIGHT; to_state = s5};
      {from_state = s5; on_token = RIGHT; to_state = s6};
      {from_state = s6; on_token = BP;    to_state = s_finisher};

      (* block/fp branch *)
      {from_state = s3; on_token = FP;    to_state = s_low_blow};
    ];

    finals = [
      {at_state = s_fireball;    moves = ["Fireball"]};
      {at_state = s_shadow_kick; moves = ["Shadow Kick"]};
      {at_state = s_finisher;    moves = ["Finisher"]};
      {at_state = s_low_blow;    moves = ["Low Blow"]};
    ];
  }

(*
  ───────────────────────────────────────────────────────────────────────
  5) Worked examples you can run (tiny "unit tests")
  ───────────────────────────────────────────────────────────────────────
  We stream tokens one by one, keeping only the *current* state in hand.
  This is the essence of DFAs: the "memory" is finite and is exactly the
  current state value. No mutation is required; we *return* a new state.
*)

let print_emits label outs =
  match outs with
  | [] -> Printf.printf "%s: (no output)\n%!" label
  | _  -> Printf.printf "%s: %s\n%!" label (String.concat ", " outs)

let () =
  (* Example 1: [LEFT][RIGHT][FP] -> Fireball *)
  let s = fsm.start_state in
  let s = step fsm s LEFT in
  let s = step fsm s RIGHT in
  let s = step fsm s FP in
  print_emits "After LEFT, RIGHT, FP" (emits fsm s);

  (* Example 2: [LEFT][RIGHT][FK] -> Shadow Kick *)
  let s = fsm.start_state |> fun s -> step fsm s LEFT |> fun s -> step fsm s RIGHT |> fun s -> step fsm s FK in
  print_emits "After LEFT, RIGHT, FK" (emits fsm s);

  (* Example 3: [RIGHT][RIGHT][RIGHT][BP] -> Finisher *)
  let s = fsm.start_state in
  let s = step fsm s RIGHT |> fun s -> step fsm s RIGHT |> fun s -> step fsm s RIGHT |> fun s -> step fsm s BP in
  print_emits "After RIGHT, RIGHT, RIGHT, BP" (emits fsm s);

  (* Example 4: [BLOCK][FP] -> Low Blow *)
  let s = fsm.start_state |> fun s -> step fsm s BLOCK |> fun s -> step fsm s FP in
  print_emits "After BLOCK, FP" (emits fsm s);

  (* Example 5: Nonexistent edge: we fall back to start *)
  let s = step fsm fsm.start_state UP in
  print_emits "After UP" (emits fsm s)
