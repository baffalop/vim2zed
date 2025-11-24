(** Types for representing Zed keymap structure *)

(** Represents a command that can be bound to a key *)
type cmd =
  | Cmd of string
  | CmdArgs of string * Yojson.Safe.t
  | Null

(** Represents a key binding entry *)
type binding = {
  key: string;
  cmd: cmd;
}

(** Represents a context block with its condition and bindings *)
type context_block = {
  context: string;
  bindings: binding list;
  use_key_equivalents: bool option;
}

(** The complete keymap structure *)
type keymap = context_block list

(** {1 Pretty Printing} *)
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
