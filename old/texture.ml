(* texture.ml
   Banana hammock.
   Basically, we use the SDL loader, and turn it into an OpenGL RAW
   format.
*)

open Sdlvideo;;

let hardwiredTexture () = 
  let iSize = 64 in
  let image = GlPix.create `ubyte ~height: iSize ~width: iSize ~format: `rgb in
  let raw = GlPix.to_raw image in
    for i = 0 to iSize - 1 do
      for j = 0 to iSize - 1 do
	let itm = if Random.int 100 < 10 then [|0;0;0|]
	  else [|128;0;0|] in
	  Raw.sets raw ~pos: (3*(i*iSize+j)) itm;
      done;
      done;

      image
;;

(* The opengl stuff of this is sorta annoyingly weird, but basically,
   after loading and converting the thing, we shove the texture through the 
   pipeline to the graphics card and associate it with a texture id. 

   Even with all this, this is apparently the 1995 way of doing things.
*)
let loadTexture filename =
  Printf.printf "Loading texture %s...  " filename;
  let surf = Sdlloader.load_image filename in
  let size = surface_info surf in
  let raw = Sdlgl.to_raw surf in

  let texid = GlTex.gen_texture () in
  let pix = GlPix.of_raw raw ~format: `rgb ~height: size.h ~width: size.w in 
(*    pix; *)

    GlTex.bind_texture `texture_2d texid;
    GlTex.image2d pix; 
    Printf.printf "done.\n";
    texid

;;


let texLoader = new Resources.resourceLoader loadTexture "data/textures";;
