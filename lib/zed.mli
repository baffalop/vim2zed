(** Types for representing Zed keymap structure *)

module Keymap : sig
  type t

  val empty : t
end

val to_json : Keymap.t -> Yojson.Safe.t
val from_json : Yojson.Safe.t -> (Keymap.t, string) result

(** Load keymap from a JSON file *)
val load_keymap_from_file : string -> Keymap.t

module Print : sig
  val keymap : Keymap.t -> string
end
