open Vim2zed

let () =
  match Array.to_list Sys.argv with
  | [_; filename] ->
      let mappings = Vim.parse_file filename in
      Vim.pretty_print mappings;

      print_endline "";
      print_endline "----- Default keymap -----";
      print_endline "";

      let keymap = Zed.Parse.load_keymap_from_file "data/default-keymap.json" in
      print_endline @@ Zed.Print.keymap keymap
  | _ ->
      Printf.eprintf "Usage: %s <vim_file>\n" Sys.argv.(0);
      exit 1
