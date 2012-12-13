(* Meshes, and the associated OMGWEIRDANDNASTY loader functions 
   Someday, turning it into a display list might be nice.
*)

(* OCaml array-of-float's are optimized better by the compiler than, say,
   tuples or something. 
   By a factor of two or so, it seems.  It might end up mattering.
*)
type vertex = float array;;

type vertexNormal = float array;;

(* Each face is a an array of (point, uv, normal) tuples.
   Arrays of ints don't get optimized differently, 'cause they're fast
   to begin with.  :-P
*)
type face = (int * int * int) array;;

type uv = float array;;


class mesh v n f u = 
object (self)
  val mutable vertices = v
  val mutable normals = n
  val mutable faces = f
  val mutable uvs = u
  val mutable texture : (GlTex.texture_id option) = None


  method private drawFace facenum =
    let f = faces.(facenum) in
      GlDraw.begins `triangles;
      for i = 0 to (Array.length f) - 1 do
	let fvertex, fuvmap, fnormal = f.(i) in
	let v = vertices.( fvertex - 1 )
	and n = normals.( fnormal - 1 ) in
	  GlDraw.normal ~x: n.(0) ~y: n.(1) ~z: n.(2) ();
	  GlDraw.vertex3 (v.(0), v.(1), v.(2));
      done;
      GlDraw.ends ();

  method private drawFaceWithTexture facenum =
    let f = faces.(facenum) in
      GlDraw.begins `triangles;
      for i = 0 to (Array.length f) - 1 do
	let fvertex, fuvmap, fnormal = f.(i) in
	let vert = vertices.( fvertex - 1 )
	and n = normals.( fnormal - 1 ) 
	and uv = uvs.( fuvmap - 1 )
	in
	  GlDraw.normal ~x: n.(0) ~y: n.(1) ~z: n.(2) ();
	  GlTex.coord2 (uv.(0), uv.(1));
	  GlDraw.vertex3 (vert.(0), vert.(1), vert.(2));
      done;
      GlDraw.ends ();

  method private drawMesh =
    for i = 0 to (Array.length f) - 1 do
      self#drawFace i
    done;

  method private drawMeshWithTexture =
    match texture with
	Some( t ) -> (
	    GlTex.bind_texture `texture_2d t;
	    Gl.enable `texture_2d;
	    for i = 0 to (Array.length f) - 1 do
	      self#drawFaceWithTexture i
	    done;
	    Gl.disable `texture_2d;
	  )
      | None -> (
	    Printf.printf "Tried to draw some texture where none existed!";
	    raise Not_found;
	  )

  method draw =
    if self#isTextured then
      self#drawMeshWithTexture
    else
      self#drawMesh


  method isTextured =
    match texture with
	Some( _ ) -> true
      | None -> false

  method setTexture t =
    texture <- (Some( t ))


  method removeTexture =
    texture <- None

end;;










(* A set of loader functions for Wavefront .obj files 
   Only loads triangles.
   Ignores materials and such, but does get UV's
*)

let parseVertex line =
  try
    let v = Scanf.sscanf line "v %f %f %f" 
      (fun x y z -> [|x;y;z|]) in
(*      Printf.printf "v %f %f %f\n" v.(0) v.(1) v.(2); *)
      v;
  with
      Scanf.Scan_failure _ ->
	raise (Failure ("parseVertex: scanf choked on:\n" ^ line));
;;

let parseUV line =
  try
    let v = Scanf.sscanf line "vt %f %f" 
      (fun x y -> [|x; y|]) in
(*      Printf.printf "v %f %f %f\n" v.(0) v.(1) v.(2); *)
      v;
  with
      Scanf.Scan_failure _ ->
	raise (Failure ("parseUV: scanf choked on:\n" ^ line));
;;


let parseFace line =
   let re = Str.regexp " " in
   let splitlist = Str.split re line in
   let parseNumbers str =
     try
      let re = Str.regexp "/" in
      (* Hack hack hack! *)
      let strlist = (Str.split re str) in
      let splitlist = ref 
      (List.map (fun x ->if x = "" then 0 else int_of_string x) strlist) in

      if List.length !splitlist < 2 then
         splitlist := !splitlist @ [0; 0]
      else if List.length !splitlist < 3 then
         splitlist := !splitlist @ [0]

      else if List.length !splitlist > 3 then (
	  Printf.printf "Ack!  .obj model had more than 3 vertices per face: '%s'\n" line;
	  raise (Failure( "" ));
	);

      let a = List.nth !splitlist 0
      and b = List.nth !splitlist 1
      and c = List.nth !splitlist 2 in
      (a,b,c)
     with
	 _ -> raise (Failure( "Something fucked up in objloader.ml, parseNumbers on: " ^ str));
   in
   let l = List.map parseNumbers (List.tl splitlist) in
   let a = Array.of_list l in
     a
;;




let parseNormal line =
  try
    Scanf.sscanf line "vn %f %f %f"
      (fun x y z ->
	[|x; y; z|])
  with
      Scanf.Scan_failure _ ->
	raise (Failure ("parseNormal: scanf choked on " ^ line));
;;



let loadObj filename =
  let f = open_in filename in
  let rec loop vertices normals faces uvs =
    try
      let line = input_line f in
	if line.[0] = 'v' && line.[1] = ' ' then
	  let v = parseVertex line in
	    loop (v :: vertices) normals faces uvs

	else if line.[0] = 'v' && line.[1] = 'n' then
	  let n = parseNormal line in
	    loop vertices (n :: normals) faces uvs

	else if line.[0] = 'f' && line.[1] = ' ' then
	  let f = parseFace line in
	    loop vertices normals (f :: faces) uvs

	else if line.[0] = 'v' && line.[1] = 't' then
	  let t = parseUV line in
	    loop vertices normals faces (t :: uvs)

	else
	  loop vertices normals faces uvs
    with
	End_of_file ->

	  let v = Array.of_list (List.rev vertices)
	  and n = Array.of_list (List.rev normals)
	  and f = Array.of_list (List.rev faces)
	  and u = Array.of_list (List.rev uvs) in
	    new mesh v n f u
  in
  let res = loop [] [] [] [] in
    close_in f;
    res
;;





let meshLoader = new Resources.resourceLoader loadObj "data/meshes"
