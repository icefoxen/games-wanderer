(* util.ml
   Basic utility junk and global vars.
   And the stuff the OCaml standard library should have, and dosen't.
   
   Simon Heath
*)

open Sdlvideo;;



let print_bool = function
    true -> print_string "true"
  | false -> print_string "false"
;;

let error x y = 
  Printf.eprintf x y;
  exit 1;
;;


let pi = acos (-1.0);;
let d2r x = x *. (pi /. 180.);;
let r2d x = x *. (180. /. pi);;
let absf x =
  if x < 0. then
    -.x
  else
    x
;;

let absmod x y = 
  let n = x mod y in
    abs n
;;

let fabs x =
  if x < 0. then
    -. x
  else
    x
;;


let incf x =
  x := !x +. 1.;;

let decf x = 
  x := !x -. 1.;;

let removeNth lst n =
  let rec loop n lst = 
    if n = 0 then
      List.tl lst
    else 
      (List.hd lst) :: (loop (n - 1) (List.tl lst))
  in
    if List.length lst > n then
      raise (Failure "removeNth: list too long")
    else
      loop n lst
;;


let square x =
  x *. x
;;

(* Return true if a is equal to b within the given delta *)
let within a b delta =
  absf (a -. b) > delta
;;



(* Why can't I just chop the first or last x characters from a string,
   easily?

   Because they functions to do so are hidden away in str.cma, that's why.
   use Str.string_before, Str.string_after, etc
*)
let chop_left s i =
  let ns = String.create ((String.length s) - i) in
    for x = i to ((String.length s) - 1) do
      ns.[x - i] <- s.[x]
    done;
    ns
;;

let chop_right s i =
  String.sub s 0 ((String.length s) - i)
;;

let string2list s = 
   let l = ref [] in
   for x = 0 to (String.length s) - 1 do
      l := s.[x] :: !l
   done;
   List.rev !l
;;

let list2string l =
   let s = String.make (List.length l) 'X' in
   let rec loop lst idx =
      if lst = [] then
         ()
      else (
         s.[idx] <- List.hd lst;
         loop (List.tl lst) (idx+1)
      )
   in
   loop l 0;
   s
;;

(* Trims whitespace from the beginning and end of a string *)
let trim s =
   let r = Str.regexp "[^ \t\n\r]" in
   let start = Str.search_forward r s 0
   and stop = Str.search_backward r s ((String.length s) - 1) in
   let length = stop - start + 1 in
   String.sub s start length
;;


