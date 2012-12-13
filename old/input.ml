(* input.ml
   Keybindings! 
*)

open Sdlkey;;



(* Interface keys *)
let help = ref KEY_h
and pause = ref KEY_p
and menu = ref KEY_ESCAPE

and rotpx = ref KEY_DOWN
and rotnx = ref KEY_UP
and rotpy = ref KEY_RIGHT
and rotny = ref KEY_LEFT
and rotpz = ref KEY_e
and rotnz = ref KEY_w

and accelkey = ref KEY_d
and decelkey = ref KEY_s
;;
