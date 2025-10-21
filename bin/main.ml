(*
  bin/main.ml — clean & pretty output
  -----------------------------------
  - Loads grammar, builds FSM
  - Opens a small visible SDL window (so it can receive focus)
  - On each key press:
      * print the recognized token (e.g. [LEFT])
      * advance the FSM (try from current state, else from start)
      * if a state has outputs, print them as MATCH lines
  - No combo echo (kept minimal and clear)
*)

(* === Terminal colors (ANSI) === *)
let color_reset   = "\027[0m"
let color_input   = "\027[1;33m"   (* yellow *)
let color_match   = "\027[1;32m"   (* green *)
let color_info    = "\027[0;37m"   (* grey *)

let say fmt = Printf.printf (fmt ^^ "\n%!")

(* Map label (from Sdl_keys) -> Fsm.control *)
let control_of_label (lbl : string) : Fsm.control option =
  match String.lowercase_ascii lbl with
  | "left"   -> Some Fsm.Left
  | "right"  -> Some Fsm.Right
  | "fp"     -> Some Fsm.FrontPunch
  | "fk"     -> Some Fsm.FrontKick
  | "bp"     -> Some Fsm.BackPunch
  | "block"  -> Some Fsm.Block
  | _ -> None

(* Pretty-print grammar-style token *)
let token_of_control (c : Fsm.control) : string =
  match c with
  | Fsm.Left        -> "[LEFT]"
  | Fsm.Right       -> "[RIGHT]"
  | Fsm.Block       -> "[BLOCK]"
  | Fsm.FrontPunch  -> "[FP]"
  | Fsm.FrontKick   -> "[FK]"
  | Fsm.BackPunch   -> "[BP]"

(* Print matches for a given state (your FSM: outputs : string list option) *)
let print_outputs (st : Fsm.state) : unit =
  match st.Fsm.outputs with
  | Some lst ->
      List.iter
        (fun s -> Printf.printf "%s✨ MATCH! → %s%s\n%!" color_match s color_reset)
        lst
  | None -> ()

(* Advance FSM by control c.
   Try from current; if it fails, try from 0; otherwise stay at 0 if no path exists. *)
let advance (states : Fsm.state list) (current : int) (c : Fsm.control) : int =
  let next_from idx =
    try Some (List.assoc c (List.nth states idx).Fsm.transitions)
    with Not_found -> None
  in
  match next_from current with
  | Some nxt ->
      print_outputs (List.nth states nxt);
      nxt
  | None ->
      (match next_from 0 with
       | Some nxt0 ->
           print_outputs (List.nth states nxt0);
           nxt0
       | None -> 0)

let () =
  try
    (* 1) load grammar & build FSM *)
    let grammar_path =
      if Array.length Sys.argv >= 2 then Sys.argv.(1) else "grammar/main.grm"
    in
    let ch = open_in grammar_path in
    let rules = Fsm.parse_file ch [] in

    say "%s📜 Loaded Grammar:%s" color_info color_reset;
    let rules_rev = List.rev rules in
    Fsm.print_rules rules_rev;

    say "%s🧩 FSM States:%s" color_info color_reset;
    let states = Fsm.create_states rules_rev in
    List.iteri Fsm.print_state states;

    (* 2) visible SDL window (focusable) *)
    Sdl.init [`VIDEO];
    let screen = Sdlvideo.set_video_mode ~w:320 ~h:200 [`SWSURFACE] in

    (* Fill the whole surface black once (cosmetic) *)
    let info = Sdlvideo.surface_info screen in
    let rect = Sdlvideo.rect ~x:0 ~y:0 ~w:info.Sdlvideo.w ~h:info.Sdlvideo.h in
    let black = Int32.zero in
    Sdlvideo.fill_rect ~rect screen black;
    Sdlvideo.flip screen;

    say "\n%s🎮 SDL Ready!%s" color_info color_reset;
    say "Use: ←/→ arrows, a=BP, s=FP, d=FK, Shift=BLOCK, ESC=quit.";
    say "Click the window to focus it.\n";

    (* 3) event loop *)
    let running = ref true in
    let current = ref 0 in
    while !running do
      match Sdlevent.wait_event () with
      | Sdlevent.QUIT ->
          running := false

      | Sdlevent.KEYDOWN ks ->
          let key = ks.Sdlevent.keysym in
          if key = Sdlkey.KEY_ESCAPE then
            running := false
          else begin
            match Sdl_keys.label_of_key key with
            | None -> ()
            | Some lbl ->
                (* label -> control *)
                (match control_of_label lbl with
                 | None -> ()
                 | Some ctrl ->
                     (* pretty INPUT echo *)
                     let tok = token_of_control ctrl in
                     Printf.printf "%s⚡ INPUT:%s %s%s\n%!"
                       color_input color_reset tok color_reset;
                     (* step FSM *)
                     current := advance states !current ctrl)
          end

      | _ -> ()
    done;

    Sdl.quit ();
    say "\n%s👋 Bye!%s" color_info color_reset

  with Sys_error e ->
    Printf.printf "%sERROR:%s %s\n%!" color_match color_reset e
