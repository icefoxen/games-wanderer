(* camera.ml
   A camera!
   Right now we shall just look at an object from a fixed view point.
*)

open Vector
open Quaternion


class camera =
object (self)

  val mutable distance = 10.

  val mutable theta = 0.1
  val mutable phi = 0.1

  method addDistance d =
    distance <- distance +. d

  (* XXX: Some bounds checking should go in here... maybe... someday... or something. *)
  method addTheta a =
    theta <- theta +. a;

  method addPhi a = phi <- phi +. a

  method snapToRearView =
    theta <- (-.Util.pi /. 2.);
    phi <- 0.;

  method orientCamera (target : vector) (facing : quaternion) =
    (* Hokay... first we find the position of the camera, which is
       the target + (facing * distance), more or less... *)
    let fx, fy, fz = facing#toMatrix in
    let cameratop = fy in (* This isn't quite right, but works okay. *)


    let zoff = distance *. (sin theta) *. (cos phi)
    and xoff = distance *. (sin theta) *. (sin phi)
    and yoff = distance *. (cos theta) in

    let ox, oy, oz = facing#toMatrix in
    let scalex = ox#mul xoff
    and scaley = oy#mul yoff
    and scalez = oz#mul zoff in

    let camerapos = target#copy in
      camerapos#setV (camerapos#add scalex);
      camerapos#setV (camerapos#add scaley);
      camerapos#setV (camerapos#add scalez);
      
      GluMat.look_at ~eye:(camerapos#x, camerapos#y, camerapos#z) 
	~center: (target#x, target#y, target#z)
	~up: (cameratop#x, cameratop#y, cameratop#z);


end;;
