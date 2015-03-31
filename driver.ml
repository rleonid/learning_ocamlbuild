
open Greeter

let () =
  Printf.printf "Running test!\n";
  Kaputt.Abbreviations.Test.launch_tests ();
  Printf.printf "Finished running linked tests!\n"
