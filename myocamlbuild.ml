(* OASIS_START *)
(* OASIS_STOP *)
open Ocamlbuild_plugin
open Ocamlbuild_pack

let inspect state =
  print_bytes state;
  print_bytes "\n---------------Targets\n";
  print_bytes (String.concat " " !Options.targets);
  print_bytes "\n---------------OC\n";
  print_bytes (String.concat " " !Options.ocaml_libs);
  print_bytes "\n---------------PA\n";
  print_bytes (String.concat " " !Options.program_args);
  print_bytes "\n---------------IL\n";
  print_bytes (String.concat " " !Options.ignore_list);
  print_bytes "\n---------------\n"
 
let lib_dir pkg =
  let ic = Unix.open_process_in ("ocamlfind query " ^ pkg) in
  let line = input_line ic in
  close_in ic;
  line

let () =
  let additional_rules =
    function
      | Before_hygiene  -> ()
      | After_hygiene   -> ()
      | Before_options  -> ()
      | After_options   -> ()
      | Before_rules    -> ()
      | After_rules     ->
          rule "Create a covered target."
            ~prod:"%.covered"
            ~dep:"%.native"
            begin fun env _build ->
              let covered = env "%.covered" and native  = env "%.native" in
              Seq [ cp native covered
                  ; Cmd (S [ A"ln"
                           ; A"-sf"
                           ; P (!Options.build_dir/covered)
                           ; A Pathname.parent_dir_name])
                 (*; ln_s (env "_build/%.covered") covered  *)
             ]

            end;
          let bsdir = Printf.sprintf "%s/%s" (lib_dir "bisect") in
          try
            let covered_target = 
              List.find (fun s -> Pathname.get_extension s = "covered")
                !Options.targets in
            Log.dprintf 0 "coverage target: %s\n" covered_target;
            flag ["pp"; ] (S [A"camlp4o"; A"str.cma"; A (bsdir "bisect_pp.cmo")]);
            flag ["compile"; ] (S [A"-I"; A (bsdir "")]);
            flag ["link"; "byte"; "program"; ] (S [A"-I"; A (bsdir ""); A"bisect.cmo"]);
            flag ["link"; "native"; "program"; ] (S [A"-I"; A (bsdir ""); A"bisect.cmx"]);
          with Not_found -> 
            ();
 
  in
  dispatch additional_rules
