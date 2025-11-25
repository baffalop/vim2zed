(** Types for representing Zed keymap structure *)

(** Command that a key is mapped to *)
type cmd =
  | Cmd of string
  | CmdArgs of string * Yojson.Safe.t
  | Null

type binding = {
  key: string;
  cmd: cmd;
}

type context_block = {
  context: string;
  bindings: binding list;
}

type keymap = context_block list

val to_json : keymap -> Yojson.Safe.t
val from_json : Yojson.Safe.t -> (keymap, string) result

(** Load keymap from a JSON file *)
val load_keymap_from_file : string -> keymap

module Print : sig
  val cmd : cmd -> string
  val binding : binding -> string
  val context_block : context_block -> string
  val keymap : keymap -> string
end
