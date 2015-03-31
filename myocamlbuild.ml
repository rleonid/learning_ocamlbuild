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

let target_with_extension ext =
  List.exists (fun s -> Pathname.get_extension s = ext) !Options.targets
   
let rec copy_mlt_files path =
  Pathname.readdir path
  |> Array.iter 
    (fun p ->
      if Pathname.is_directory (path / p) then
        copy_mlt_files (path / p)
      else if Pathname.check_extension p "mlt" then
        let src = path / p in
        let dst = !Options.build_dir / path / p in
        Shell.mkdir_p (!Options.build_dir / path);
        Log.dprintf 0 "dest: %s -> %s\n " dst p;
        (*tag_file (Pathname.update_extension "ml" p) [ "pp"]; *)
        Pathname.copy src dst
      else
        ())

let () =
  let additional_rules =
    function
      | Before_hygiene  -> 
          if target_with_extension "test"
          then copy_mlt_files "src"
          else ()
      | After_hygiene   -> ()
      | Before_options  -> ()
      | After_options   -> ()
      | Before_rules    -> ()
      | After_rules     ->
          rule "Create a test target."
            ~prod:"%.test"
            ~dep:"%.native"
            begin fun env _build ->
              let test = env "%.test" and native = env "%.native" in
              Seq [ mv native test
                  ; Cmd (S [ A"ln"
                           ; A"-sf"
                           ; P (!Options.build_dir/test)
                           ; A Pathname.parent_dir_name])
             ]
            end;
          if target_with_extension "test" then 
            flag ["pp"]
              (S [A(lib_dir "kaputt" / "kaputt_pp.byte"); A"on"; A "camlp4o"])
          else
            ();
 
  in
  dispatch additional_rules
