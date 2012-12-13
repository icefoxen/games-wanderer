(* driver.ml
   Makes things go.
*)

open Vector
open Gameobj
open Particles
open Sdlkey
open Mesh


class driver =
object (self)

  val mutable objects : gameobj list = []
  val mutable particles : particle list = []
  val mutable continue = true

  val mutable player = new Gameobj.gameobj (new vector 100. 0. 0.) (meshLoader#get "corvette.obj")


  val mutable numFrames = 0
  val mutable lastTick = 0
  val mutable thisTick = 0
  val mutable timeScale = 1.

  method addObject m =
    objects <- m :: objects

  method addParticle p =
    particles <- p :: particles;

  method delObject m =
    objects <- List.filter (fun x -> x <> m) objects


  method doInput drawer =
    ignore (Sdlevent.poll ());
    if (is_key_pressed !Input.menu) or (is_key_pressed !Input.help) then
      self#stopGame;

    if is_key_pressed !Input.pause then
      self#pause;

    let c = drawer#camera in
      (*    let v = c#getFacing#unitVector#mul 0.1 in *)
      if is_key_pressed !Input.rotpx then
	player#rotate 0.1 0. 0.;
      if is_key_pressed !Input.rotnx then
	player#rotate (-0.1) 0. 0.;

      if is_key_pressed !Input.rotpy then
	player#rotate 0. 0.1 0.;
      if is_key_pressed !Input.rotny then
	player#rotate 0. (-0.1) 0.;

      if is_key_pressed !Input.rotpz then
	player#rotate 0. 0. 0.1;
      if is_key_pressed !Input.rotnz then
	player#rotate 0. 0. (-0.1);

      if is_key_pressed !Input.accelkey then
	player#accel
      else
	player#decel;
(*
      if is_key_pressed !Input.decelkey then
	player#setVel (player#vel#mul 0.995);
*)

      let mx, my, mbuttons= Sdlmouse.get_state ~relative: true () in
	if List.mem Sdlmouse.BUTTON_RIGHT mbuttons then (
	    let dx = float_of_int mx
	    and dy = float_of_int my in
	      c#addTheta (0.005 *. dy);
	      c#addPhi (-0.005 *. dx);
	  );

	(* Remember to put a max and min distance here someday *)
	if List.mem Sdlmouse.BUTTON_WHEELUP mbuttons then (
	    c#addDistance (-1.0);
	    print_endline "Zooming in";
	  )
	else if List.mem Sdlmouse.BUTTON_WHEELDOWN mbuttons then (
	    print_endline "Zooming out";
	    c#addDistance (1.0);
	  );

  method stopGame =
    continue <- false;

  method pause =
    print_endline "Pausing, supposedly.";


  method doCalc t =
    (*    let makeTrailParticle mass =
	  if (lastTick / 3000) < (thisTick / 3000) then
	  self#addParticle 
	  (new Particles.particle mass#pos zeroVector 1e12)
	  in
    *)
    List.iter (fun x -> x#calc t) objects; 
    List.iter (fun x -> x#calc t) particles;
    


  method doImpact =
    let rec calcImpactFor itm = function
	[] -> ()
      | hd :: tl -> if itm#isColliding hd then (itm#impact hd; hd#impact itm);
	  calcImpactFor itm tl
    in
    let rec loop = function
	[] -> ()
      | hd :: tl -> calcImpactFor hd tl; loop tl
    in
      loop objects
	
  method doDeath =
    objects <- List.filter (fun x -> x#isAlive) objects;
    particles <- List.filter (fun x -> x#isAlive) particles;
    


  method stop =
    continue <- false

  method print =
    List.iter (fun x -> print_endline x#toString) objects;


  method mainloop = 
    let d = new Drawing.drawer in
    let g0 = new Gameobj.gameobj (new vector 10. 0. 0.) (meshLoader#get "frigate.obj")
    in

(*      g0#mesh#setTexture (Texture.texLoader#get "frigate.png"); *)
      d#camera#snapToRearView;
      objects <- [player];

      while continue do
	lastTick <- thisTick;
	thisTick <- Sdltimer.get_ticks ();
	let dt = timeScale *. 
	  ((float_of_int (thisTick - lastTick)) /. 1000.) in

	  (* Order is important here *)
	  self#doInput d;
	  self#doCalc dt;
	  self#doImpact;
	  self#doDeath;

	  d#draw objects particles player#pos player#facing;
	  numFrames <- numFrames + 1;
      done; 

      let f = float_of_int numFrames
      and t = (float_of_int (Sdltimer.get_ticks ())) /. 1000. in
	Printf.printf "FPS: %f\n" (f /. t);
	

end;;
