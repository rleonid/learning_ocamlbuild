
let greet ?person () = 
  match person with
  | None    -> print_endline "Hello Bisect Coverage (from Library)!"
  | Some p  -> print_endline (Printf.sprintf "Hello %s (from Library)!" p)
