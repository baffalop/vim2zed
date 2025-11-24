type mode =
  | All
  | Normal
  | Visual
  | Insert
  | Operator
  | Visual_block
  | Select
  | Command
  | Lang
  | Terminal

type map_type = Map | Noremap

type keystroke =
  | Char of char
  | Leader
  | Return
  | Escape
  | Space
  | Tab
  | Backspace
  | Delete
  | Control of char
  | Alt of char
  | Shift of char
  | F of int
  | Arrow of [`Up | `Down | `Left | `Right]
  | Special of string
  | Plug of string

type mapping = {
  mode: mode;
  map_type: map_type;
  trigger: keystroke list;
  target: keystroke list;
}

val mode_to_string : mode -> string
val map_type_to_string : map_type -> string
val keystroke_to_string : keystroke -> string
val keystrokes_to_string : keystroke list -> string
val parse_file : string -> mapping list
