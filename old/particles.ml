(* particles.ml
   A particle engine.
*)

open Gameobj

class particle pos mesh lifetime =
object (self) 
  inherit gameobj pos mesh
  val mutable life = lifetime

  method calc (t:float) =
    life <- life -. t;
    if life < 0. then 
      self#setAlive false
    else  ( 
(*	accel#set 0. 0. 0.; *)
      )
      
end
  
