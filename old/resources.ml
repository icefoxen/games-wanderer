(* Load-once resource system!
   Because they're *useful*.

*)


class ['a] resourceLoader (loaderfunc : (string -> 'a)) loaddir =
object (self)
  val mutable resources = Hashtbl.create 8;
  val mutable loadDir = loaddir
  val mutable loaderFunc = loaderfunc


  method get resourcename =
    try
      Hashtbl.find resources resourcename
    with
	Not_found ->
	  try
	    let r = loaderfunc (loadDir ^ "/" ^ resourcename) in
	      Hashtbl.add resources resourcename r;
	      r
	  with
	      x -> Printf.printf "Error loading resource: %s\n" resourcename;
		raise x;

  method clear =
    resources <- Hashtbl.create 8;

  method unload resourcename =
    Hashtbl.remove resources resourcename

end;;
