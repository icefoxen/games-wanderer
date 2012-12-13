(* drawing.ml
   OpenGL drawing stuff.
*)


open Vector
open Gameobj

let initLight () =
  let light_ambient = 0.1, 0.1, 0.1, 1.0
  and light_diffuse = 1.0, 1.0, 1.0, 1.0
  and light_specular = 1.0, 1.0, 1.0, 1.0
    (*  light_position is NOT default value	*)
  and light_position = 1.0, 0.0, 0.0, 0.0
  in
    List.iter (GlLight.light ~num:0)
      [ `ambient light_ambient; `diffuse light_diffuse;
	`specular light_specular; `position light_position ];

    Gl.enable `lighting;
    Gl.enable `light0;
    Gl.enable `depth_test;
;;

let skyboximg =  Texture.texLoader#get "neb-1a.bmp.png";;


let initGL w h =
  GlDraw.shade_model `smooth;  (* `smooth, `flat *)
  GlDraw.polygon_mode `both `fill;  (* `fill, `line, `point *)
  GlClear.color (0., 0., 0.);
  GlClear.depth 1.0;
  GlClear.clear [`color; `depth];
  Gl.enable `depth_test;
  GlFunc.depth_func `lequal;

  (* Start textures *)

  (*  let image = Texloader.loadTexture "smile.png" in*)
    GlPix.store (`unpack_alignment 1);
    List.iter (GlTex.parameter ~target:`texture_2d)
      [`wrap_s `clamp;
       `wrap_t `clamp;
       `mag_filter `linear; (* Options include `nearest, `linear *)
       `min_filter `linear];

    GlTex.env (`mode `decal); 
    (* End texture stuff *)


    GlMisc.hint `perspective_correction `nicest;

    GlDraw.viewport ~x: 0 ~y: 0 ~w: w ~h: h;
    GlMat.mode `projection;
    GlMat.load_identity ();
    (* Note: this sets the min and max z distances *)
    GluMat.perspective ~fovy: 60. ~aspect: ((float_of_int w) /. (float_of_int h)) 
      ~z: (Globals.minDist, Globals.maxDist);
    GlMat.mode `modelview;
    GlMat.load_identity ();


    initLight ();

(*
    GlLight.material ~face: `front (`specular (0.5, 0.5, 0.5, 1.));
    GlLight.material ~face: `front (`shininess 5.);
    *)

    GlLight.material ~face: `front (`specular (0., 0., 0., 0.));
    GlLight.material ~face: `front (`shininess 0.);

;;




let drawSphere x y z r =
(*  Printf.printf "Drawing sphere at %f %f %f\n" x y z;*)
  GlMat.push ();
(*  GlMat.rotate *)


  GlMat.translate ~x: x ~y: y ~z: z ();
  GluQuadric.sphere ~radius: r ~slices: 8 ~stacks: 8 ();
  GlMat.pop ();
;;

let drawParticle x y z =
  Gl.disable `lighting;
  GlMat.push ();
(*  GlMat.translate ~x: x ~y: y ~z: z (); *)
(*  GluQuadric.sphere ~radius: 0.02 ~slices: 3 ~stacks: 3 (); *)
  GlDraw.color (1., 0., 0.);
  GlDraw.begins `points;
  GlDraw.vertex ~x: x ~y: y ~z: z ();
(*  GlDraw.vertex ~x: (x +. 0.1) ~y: y ~z: z (); *)
(*  GlDraw.vertex ~x: x ~y: (y +. 0.1) ~z: z (); *)
  GlDraw.ends ();
  GlMat.pop ();
  Gl.enable `lighting;
;;

(* pv = position vector, sv = scaling vector *)
let drawSkybox pv sv =
(*  GlTex.image2d skyboximg; *)
  GlTex.bind_texture `texture_2d skyboximg;
  Gl.enable `texture_2d;
  GlMat.push ();

  GlMat.translate ~x: pv#x ~y: pv#y ~z: pv#z ();
  GlMat.scale ~x: sv#x ~y: sv#y ~z: sv#z ();

  
  let r = 1.0
  and cx = 0.0
  and cz = 1.0 in

    (* XXX: Oops, quads suck.  Make it tri's *)
    (* Common axis z --front *)
    GlDraw.begins `quads;
    GlTex.coord2 (cx, cz);
    GlDraw.vertex3 (-.r, 1.0, -.r);
    GlTex.coord2 (cx, cx);
    GlDraw.vertex3 (-.r, 1.0,   r);
    GlTex.coord2 (cz, cx);
    GlDraw.vertex3 (r,   1.0,   r);
    GlTex.coord2 (cz, cz);
    GlDraw.vertex3 (r,   1.0, -.r);
    GlDraw.ends ();  

    Gl.disable `texture_2d;
(*
    (* Back *)
    GlDraw.begins `quads;
    GlTex.coord2 (cx, cz);
    GlDraw.vertex3 (-.r, -1.0, -.r);
    GlTex.coord2 (cx, cx);
    GlDraw.vertex3 (-.r, -1.0, r);
    GlTex.coord2 (cz, cx);
    GlDraw.vertex3 (r, -1.0, r);
    GlTex.coord2 (cz, cz);
    GlDraw.vertex3 (r, -1.0, -.r);
    GlDraw.ends ();

    (* Common axis x --left *)
    GlDraw.begins `quads;
    GlTex.coord2 (cx, cz);
    GlDraw.vertex3 (-1.0, -.r, -.r);
    GlTex.coord2 (cx, cx);
    GlDraw.vertex3 (-1.0, -.r, r);
    GlTex.coord2 (cz, cx);
    GlDraw.vertex3 (-1.0, r, r);
    GlTex.coord2 (cz, cz);
    GlDraw.vertex3 (-1.0, r, -.r);
    GlDraw.ends ();

    (* Right *)
    GlDraw.begins `quads;
    GlTex.coord2 (cx, cz);
    GlDraw.vertex3 (1.0, -.r, -.r);
    GlTex.coord2 (cx, cx);
    GlDraw.vertex3 (1.0, -.r, r);
    GlTex.coord2 (cz, cx);
    GlDraw.vertex3 (1.0, r, r);
    GlTex.coord2 (cz, cz);
    GlDraw.vertex3 (1.0, r, -.r);
    GlDraw.ends ();

    (* Common axis y --top*)
    GlDraw.begins `quads;
    GlTex.coord2 (cx, cz);
    GlDraw.vertex3 (-.r, -.r, 1.0);
    GlTex.coord2 (cx, cx);
    GlDraw.vertex3 (-.r, r, 1.0);
    GlTex.coord2 (cz, cx);
    GlDraw.vertex3 (r, r, 1.0);
    GlTex.coord2 (cz, cz);
    GlDraw.vertex3 (r, -.r, 1.0);
    GlDraw.ends ();

    (* Bottom *)
    GlDraw.begins `quads;
    GlTex.coord2 (cx, cz);
    GlDraw.vertex3 (-.r, -.r, -1.0);
    GlTex.coord2 (cx, cx);
    GlDraw.vertex3 (-.r, r, -1.0);
    GlTex.coord2 (cz, cx);
    GlDraw.vertex3 (r, r, -1.0);
    GlTex.coord2 (cz, cz);
    GlDraw.vertex3 (r, -.r, -1.0);
    GlDraw.ends ();

*)
    GlMat.pop ();
    Gl.disable `texture_2d;
;;




class drawer =
object (self)
  val mutable scale = 1.0
  val mutable camera = new Camera.camera

  val mutable continue = true

  method stop = continue <- false

  initializer
  let _ = Sdlvideo.set_video_mode ~w: Globals.screenx ~h: Globals.screeny
    ~bpp: 16 [`DOUBLEBUF; `OPENGL] in
    initGL Globals.screenx Globals.screeny;

  method camera = camera

  method drawParticles p =
    let drawP (m : Particles.particle) =
      let x = (m#pos#x /. scale)
      and y = (m#pos#y /. scale)
      and z = (m#pos#z /. scale) in
	drawParticle x y z
    in
      List.iter drawP p


  method drawObjects o =
    let drawObject (m : gameobj) =
      let x = (m#pos#x /. scale)
      and y = (m#pos#y /. scale)
      and z = (m#pos#z /. scale) in
      let angle, vector = m#facing#toAxis in
	GlMat.push ();
	GlMat.translate ~x: x ~y: y ~z: z ();
	GlMat.rotate ~angle: angle ~x: vector#x ~y: vector#y ~z: vector#z ();
	m#mesh#draw;
	GlMat.pop ();
    in
      List.iter drawObject o

  method doCamera target facing =
    camera#orientCamera target facing;

    
  method draw objects particles cameratarget camerafacing =
    GlMat.push ();
    GlClear.clear [`color; `depth];

    let sbsize = Globals.maxDist *. 0.40 in
      self#doCamera cameratarget camerafacing;
      (*     Objloader.drawMesh Objloader.mesh; *)
      self#drawObjects objects;
      self#drawParticles particles; 
      drawSkybox cameratarget (new vector sbsize sbsize sbsize);

      Sdlgl.swap_buffers (); 
      GlMat.pop ();


end;;
