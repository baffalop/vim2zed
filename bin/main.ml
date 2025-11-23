let () =
  match Array.to_list Sys.argv with
  | [_; filename] ->
      let open Zvim.Parse in
      let mappings = parse_file filename in
      List.iter (fun (mapping : mapping) ->
        let mode_str = mode_to_string mapping.mode in
        let map_type_str = map_type_to_string mapping.map_type in
        Printf.printf "Mode: %s, Map Type: %s, Trigger: %s, Target: %s\n"
          mode_str
          map_type_str
          mapping.trigger
          mapping.target
      ) mappings
  | _ ->
      Printf.eprintf "Usage: %s <vim_file>\n" Sys.argv.(0);
      exit 1
