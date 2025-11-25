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
  use_key_equivalents: bool;
}

type keymap = context_block list

val to_json : keymap -> Yojson.Safe.t

module Print : sig
  val cmd : cmd -> string
  val binding : binding -> string
  val context_block : context_block -> string
  val keymap : keymap -> string
end

module Parse : sig
  (** Load keymap from a JSON file *)
  val load_keymap_from_file : string -> keymap

  (** Parse keymap from JSON *)
  val parse_keymap : Yojson.Safe.t -> keymap

  (** Print detailed debugging information about keymap structure *)
  val debug_print : keymap -> unit
end
