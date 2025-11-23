let () =
  match Array.to_list Sys.argv with
  | [_; filename] ->
      let mappings = Zvim.Parse.parse_file filename in
      List.iter print_endline mappings
  | _ ->
      Printf.eprintf "Usage: %s <vim_file>\n" Sys.argv.(0);
      exit 1
