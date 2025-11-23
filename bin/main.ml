let () =
  match Array.to_list Sys.argv with
  | [_; filename] ->
      let open Zvim.Parse in
      let mappings = parse_file filename in
      List.iter (fun (mapping : mapping) ->
        Printf.printf "Type: %s, Trigger: %s, Target: %s\n"
          mapping.map_type
          mapping.trigger
          mapping.target
      ) mappings
  | _ ->
      Printf.eprintf "Usage: %s <vim_file>\n" Sys.argv.(0);
      exit 1
