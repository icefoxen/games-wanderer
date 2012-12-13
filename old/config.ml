(* config.ml
   Config system.
   Yay!

   A config file entry has the form key=value
   There must be no keys or values with = in them, though spaces and so on
   are valid.
   A line starting with a # is a comment.
   A category is Windows .ini-style, [Category-name].  There must be at least
   one category.

   This is one of the most useful things I have EVER written.  ^_^

   Simon Heath
   5/1/2005
*)


open Printf;;

exception Config_error of string;;

type configval =
    CInt of int
  | CFloat of float
  | CBool of bool
  | CString of string
  | CList of configval list
;;


let cfg2str = function
   CString s -> s
 | _ -> raise (Config_error "cfg2str: String expected!")
;;

let cfg2bool = function
   CBool s -> s
 | _ -> raise (Config_error "cfg2bool: Boolean expected!")
;;


let cfg2float = function
   CFloat s -> s
 | _ -> raise (Config_error "cfg2float: Float expected!")
;;


let cfg2int = function
   CInt s -> s
 | _ -> raise (Config_error "cfg2int: Int expected!")
;;

let cfg2lst = function
    CList s -> s
  | _ -> raise (Config_error "cfg2lst: List expected!")


let cfg2color = function
    CList s ->
      let a = cfg2int (List.nth s 0)
      and b = cfg2int (List.nth s 1)
      and c = cfg2int (List.nth s 2) in
	(a,b,c)
  | _ -> raise (Config_error "cfg2color: List expected!")

class config str =
  let filename = str in
object (self)
  (* A hashtable of hashtables.  Category -> key -> value.
     (string, (string, configval) Hashtbl.t) Hashtbl.t *)
  val mutable data = Hashtbl.create 16
  val mutable count = 0
  method read_file = 
    try
      let fl = open_in filename in
	(* We create and pass a hashtable here to initialize things,
	   but the hashtable is NOT EVER actually put into the data object.
	   Anything put in it is lost!  There MUST be at least one category!
	   This could be changed to a default of course, but who cares?
	*)
      let res = self#parse_file fl 1 (Hashtbl.create 1) in
	close_in fl;
	res;
    with 
	Sys_error _ -> Util.error "config.ml: Invalid config filename: %s\n" filename
	  
	  
  (* Reloads the file, reading in the default settings. *)
  method reread = 
    data <- Hashtbl.create 16;
    self#read_file filename;
    
    
  method private parse_file fl lineno cattable =
    try
      let str = input_line fl in
	(* printf "%s\n" str; *)
	(* Ignore lines starting with # *)
	if str = "" or str.[0] = '#' then
	  self#parse_file fl (lineno + 1) cattable
	    (* Lines starting with [ are categories *)
	else if str.[0] = '[' then
	  let nd = String.index str ']' in
	  let len = nd - 1 in
	  let name = String.sub str 1 len in
	  let newtbl = (Hashtbl.create 16) in
	    (* printf "Category added: %s\n" name; *)
	    Hashtbl.add data name newtbl;
	    self#parse_file fl (lineno + 1) newtbl;
	else
	  (* printf "Parsing key and data\n"; *)
	  let m = self#parse_key str
	  and n = self#parse_val str in
	    Hashtbl.add cattable m (self#resolve_type n);
	    count <- count + 1;
	    (* printf "Key and data parsed: %s %s; doing it again\n" m n; *)
	    self#parse_file fl (lineno + 1) cattable
    with
	End_of_file -> (fun x -> printf "Config file parsed: %s\n" x)
      | Config_error s -> (Printf.eprintf "config.ml: Error parsing config file at line %i:\n%s\n" lineno s);
	  exit 1;
	  
	  
  method private parse_key str =
    try
      let n = (String.index str '=') in
	String.sub str 0 n
    with
	Not_found -> raise (Config_error "Invalid format: no = sign?")

	  
  method private parse_val str =
    try
      let n = String.rindex str '=' in
	String.sub str (n + 1) ((String.length str) - n - 1)
    with
	Not_found -> raise (Config_error "Invalid format: no = sign?")
	  
  (* Screw nested lists for now *)

  (* This does NOT WORK on nested lists! 
     Other than that, it's great though.
     Sublists might be handled by splitting them off BEFORE splitting
     commas, then running them through the parser first, then adding them
     after the rest of the items are parsed.
     {foo,{bar,bop},beep} -> "foo," "bar,bop" ",beep" -> ...?
     Oh well, leave it for now.

     Or replace it with a REAL recursive-descent parser setup.
     And add functions to operate on these lists.
  *)

  method private parse_list str =
    let rec loop str accm = 
      (* Um... bit of a kludge, but then, what else is new? *)
      if str.[0] = '{' then
	loop (Util.chop_left str 1) accm
      else if str.[0] = '}' then
	accm
      else
	(* We chop the trailing }, then split and trim the contents, then
	   parse them. *)
	let s = Util.trim str in
	let s = Util.chop_right s 1 in
	let splitre = Str.regexp "," in
	let lst = Str.split splitre s in
	let lst = List.map Util.trim lst in
	  List.map (fun x -> self#resolve_type x) lst
	    
    in
      CList( loop str [] )


  method private parse_string str =
    let send = (String.length str) - 1
    and x = ref 1
    and dun = ref false in
      while (not !dun) && (!x <= send) do
	if str.[!x] = '"' && str.[!x - 1] <> '\\' then
	  dun := true
	else
	  incr x
      done;
      if not !dun then
	raise (Config_error "Evil unclosed string somewhere!");
      let strend = !x - 1 in
	CString( (String.sub str 1 strend) )
	  
	  
	  
	  
  method private resolve_type str = 
    if str = "true" or str = "false" then
      CBool( bool_of_string str )
    else
      let i = Str.regexp "\\-?[0-9]+"
      and f = Str.regexp "\\-?[0-9]+\\.[0-9]*" in
	if Str.string_match f str 0 then
	  CFloat( float_of_string (Util.trim str) )
	else if Str.string_match i str 0 then
	  CInt( int_of_string (Util.trim str) )
	else if str.[0] = '{' then
	  self#parse_list str
            (* Strings need "" around them?  Maybe. *)
	else if str.[0] = '"' then
	  self#parse_string str
	else
	  raise (Config_error 
		   ("Invalid config value type for " ^ str ^ "!  Baka!"))
	    
  method get cat key =
    try
      let t = Hashtbl.find data cat in
	try
	  Hashtbl.find t key
	with
	    Not_found -> raise 
	      (Config_error ("config#get: key not found: " ^ key ^ " in file " ^ filename))

    with
	Not_found -> raise 
	  (Config_error ("config#get: category not found: " ^ cat ^ " in file " ^ filename))
	  
  method set str vl =
    if Hashtbl.mem data str then
      Hashtbl.replace data str vl
    else
      Hashtbl.add data str vl

  method exists cat key =
    if Hashtbl.mem data cat then
      Hashtbl.mem (Hashtbl.find data cat) key
    else
      false

  method catExists cat =
    Hashtbl.mem data cat
      
  method getInt cat str =
    cfg2int (self#get cat str)
      
  method getBool cat str =
    cfg2bool (self#get cat str)
      
  method getFloat cat str =
    cfg2float (self#get cat str)
      
  method getStr cat str =
    cfg2str (self#get cat str)

  method getList cat str =
    cfg2lst (self#get cat str)

  method getStrList cat str =
    List.map cfg2str (self#getList cat str)

  method getIntList cat str =
    List.map cfg2int (self#getList cat str)

  method iter fn =
    Hashtbl.iter fn data

  method catcount =
    count
      
  initializer
    self#read_file filename

  (* Get the raw hashtable so you can manipulate it.
     Performance hack, really...  Not that nice for OO stuff.
  *)
  method getData =
    data

  method getCategory cat =
    if self#catExists cat then
      Hashtbl.find data cat
    else
      raise 
	(Config_error ("getCategory: Category " ^ cat ^ " does not exist!"))

end;;





