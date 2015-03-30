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
