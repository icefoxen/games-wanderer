(* gameobj.ml

   Simon Heath
*)

open Vector
open Quaternion


let maxVel = 1.0
and accel = 0.01;;

class gameobj p m =
object (self)
  val mutable mass = 0.
  val mutable pos : vector = p
  val mutable vel = 0.0
  val mutable facing = new quaternion 1. 0. 0. 0.

  val mutable alive = true

  val mutable mesh : Mesh.mesh = m

  method mass = mass
  method pos = pos
  method vel = vel
  method facing = facing

  method setMass m = mass <- m
  method setPos p = pos <- p
  method setVel v = vel <- v

  method accel =
    if vel < maxVel then
      vel <- vel +. accel

  method decel =
    vel <- max 0. (vel -. accel)

  method mesh = mesh
  method setMesh m = mesh <- m

  method rotate x y z =
    let q = new quaternion 1. 0. 0. 0. in
      q#fromAxis (-1.0) x y z;
      q#normalize;
      facing#setQ (facing#mul q);
      facing#normalize;

  method distanceFrom (m : gameobj) =
    let distvec = pos#sub m#pos in
      distvec#magnitude

  method isColliding (m : gameobj) =
    false

  method calc (t : float) =
    let _, _, fz = facing#toMatrix in
    let vz = fz#mul vel in
      pos <- pos#add vz

  method moveTo v =
    pos <- v

  method isAlive = alive

  method setAlive s =
    alive <- s

  method impact (m : gameobj) =
    ()

  method velocity = 
    vel

(*
  method accelForward n =
    let _, _, fz = facing#toMatrix in
    let vz = fz#mul n in
      self#addAccelV vz;
*)

  method toString =
    Printf.sprintf "Pos: %s, Vel: %f" pos#toString vel;

(*
  method copy =
  new mass mass pos#copy vel#copy
*)

end;;
