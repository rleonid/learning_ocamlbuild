(** Examples transformation rules! *)
(******************************)
rule "Transform mlt into ml."
  ~prod:"%.ml"
  ~dep:"%.mlt"
    begin fun env _build ->
      cp (env "%.mlt") (env "%.ml")   (* Also works with mv *)
    end

(******************************)
rule "Transform mlt into ml, explicitly."
  ~prod:"%.ml"
  ~dep:"%.mlt"
    begin fun env _build ->
      Cmd (S[A"cp"; P (env "%.mlt"); P (env "%.ml")])
    end


(******************************)
let lib_dir pkg =
  let ic = Unix.open_process_in ("ocamlfind query " ^ pkg) in
  let line = input_line ic in
  close_in ic;
  line

let bsdir = Printf.sprintf "%s/%s" (lib_dir "bisect") in
let do_work = "foorbo" in
  flag ["pp"; do_work] (S [A"camlp4o"; A"str.cma"; A (bsdir "bisect_pp.cmo")]);
  flag ["compile"; ] (S [A"-I"; A (bsdir "")]);
  flag ["link"; "byte"; "program"; ] (S [A"-I"; A (bsdir ""); A"bisect.cmo"]);
  flag ["link"; "native"; "program"; ] (S [A"-I"; A (bsdir ""); A"bisect.cmx"]);
  rule "Transform mlt into ml AND pre processing result!."
    ~prod:"%.ml"
    ~dep:"%.mlt"
    begin fun env _build ->
      let mlt = env "%.mlt" and ml = env "%.ml" in
      tag_file ml [do_work];
      cp mlt ml
    end;

(*** You cal also move the flags inside ala: ************)
let do_work = "foorbo" in
rule "Transform mlt into ml AND pre processing result!."
  ~prod:"%.ml"
  ~dep:"%.mlt"
  begin fun env _build ->
    let mlt = env "%.mlt" and ml = env "%.ml" in
    tag_file ml [do_work];
    flag ["pp"; do_work] (S [A"camlp4o"; A"str.cma"; A (bsdir "bisect_pp.cmo")]);
    flag ["compile"; ] (S [A"-I"; A (bsdir "")]);
    flag ["link"; "byte"; "program"; ] (S [A"-I"; A (bsdir ""); A"bisect.cmo"]);
    flag ["link"; "native"; "program"; ] (S [A"-I"; A (bsdir ""); A"bisect.cmx"]);
    cp mlt ml
  end;

(************* Full coverage example: ****************)
rule "Create a covered target."
  ~prod:"%.covered"
  ~dep:"%.native"
  begin fun env _build ->
    let covered = env "%.covered" and native = env "%.native" in
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
  ()

(********************** test targets. ******************)
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
