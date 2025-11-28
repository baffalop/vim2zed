type mode =
  | All
  | Normal
  | Visual
  | Select
  | Visual_x
  | Insert
  | Operator
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

val parse_file : string -> mapping list

val string_of_mode : mode -> string
val string_of_map_type : map_type -> string
val string_of_keystroke : keystroke -> string
val string_of_keystrokes : keystroke list -> string
val pretty_print : mapping list -> unit

module ToZed : sig
  val keymap : mapping list -> Zed.Keymap.t
end
