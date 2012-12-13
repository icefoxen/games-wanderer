open Driver;;
open Drawing;;


let main () = 

  Sdl.init [`EVERYTHING];


    let driver = new driver in
      driver#mainloop;

    Sdl.quit ();

;;

let _ = main ();;
