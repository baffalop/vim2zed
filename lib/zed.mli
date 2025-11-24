(** Types for representing Zed keymap structure *)

(** Represents a command that can be bound to a key *)
type cmd =
  | Cmd of string
  | CmdArgs of string * (string * Yojson.Safe.t) list

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

(** {1 Query Functions} *)

(** Find all bindings for a specific context *)
val find_context_bindings : keymap -> string -> binding list

(** Find all contexts that bind a specific key *)
val find_key_contexts : keymap -> string -> string list

(** Get all unique keys used across all contexts *)
val get_all_keys : keymap -> string list

(** Get all unique actions used across all contexts *)
val get_all_actions : keymap -> string list

(** Get all unique contexts *)
val get_all_contexts : keymap -> string list
(** {1 Loading and Parsing} *)

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

  (** {1 Debugging Functions} *)

  (** Validate keymap structure and return list of error messages *)
  val validate_keymap : keymap -> string list

  (** Print detailed debugging information about keymap structure *)
  val debug_print : keymap -> unit
end
