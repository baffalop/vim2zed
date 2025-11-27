let mode_context (mode: Vim.mode) : string =
  match mode with
  | All -> "VimControll"
  | Normal -> "vim_mode == normal"
  | Insert -> "vim_mode == insert"
  | Visual -> "vim_mode == visual"
  | Select -> "vim_mode == select"
  | Visual_x -> "(vim_mode == visual || vim_mode == select)"
  | Command -> "vim_mode == command"
  | Operator -> "vim_mode == operator"
  | Lang -> "vim_mode == lang"
  | Terminal -> "vim_mode == terminal"

let keymap_of_vim (mappings: Vim.mapping list) : Zed.Keymap.t =
  List.fold_right (fun mapping ->
    let open Vim in
    let ctx = (mode_context mapping.mode) ^ " && !menu" in
    let keystrokes = [] in
    let cmd = Zed.CmdArgs ("editor::SendKeystrokes", `String (string_of_keystrokes keystrokes)) in
    Zed.Keymap.add_binding_in_context ~ctx ~key:(string_of_keystrokes mapping.trigger) ~cmd
  ) mappings Zed.Keymap.empty
