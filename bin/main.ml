open Vim2zed

let () =
  match Array.to_list Sys.argv with
  | [_; filename] ->
      (* let input_keymap = Zed.Keymap.from_file "data/default-keymap.json" in *)
      let vim_mappings = Vim.parse_file filename in
      let zed_keymap = To.keymap_of_vim vim_mappings in
      let output_json = Zed.Keymap.to_json zed_keymap in
      print_endline @@ Yojson.Safe.pretty_to_string output_json
  | _ ->
      Printf.eprintf "Usage: %s <vim_file>\n" Sys.argv.(0);
      exit 1
