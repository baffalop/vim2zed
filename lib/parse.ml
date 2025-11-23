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

type mapping = {
  mode: mode;
  map_type: map_type;
  trigger: string;
  target: string;
}

let mode_to_string = function
  | All -> "all"
  | Normal -> "n"
  | Visual -> "v"
  | Insert -> "i"
  | Operator -> "o"
  | Visual_block -> "x"
  | Select -> "s"
  | Command -> "c"
  | Lang -> "l"
  | Terminal -> "t"

let mode_from_string = function
  | "n" -> Some Normal
  | "v" -> Some Visual
  | "i" -> Some Insert
  | "o" -> Some Operator
  | "x" -> Some Visual_block
  | "s" -> Some Select
  | "c" -> Some Command
  | "l" -> Some Lang
  | "t" -> Some Terminal
  | _ -> None

let map_type_to_string = function
  | Map -> "map"
  | Noremap -> "noremap"

let map_type_from_string = function
  | "map" -> Some Map
  | "noremap" -> Some Noremap
  | _ -> None

let split_at (i : int) (s : string) : string * string =
  (String.sub s 0 i, String.sub s i (String.length s - i))

let parse_keyword (keyword : string) : (mode * map_type) option =
  match map_type_from_string keyword with
  | Some map_type -> Some (All, map_type)
  | None ->
      let (prefix, suffix) = split_at 1 keyword in
      match (mode_from_string prefix, map_type_from_string suffix) with
      | (Some mode, Some map_type) -> Some (mode, map_type)
      | _ -> None

(** Parse a mapping line into its components *)
let parse_line (line : string) : mapping option =
  let parts = String.split_on_char ' ' @@ String.trim line in
  match parts with
  | keyword :: trigger :: target_parts -> (
      match parse_keyword keyword with
      | Some (mode, map_type) ->
          let target = String.concat " " target_parts in
          Some { mode; map_type; trigger; target }
      | None -> None
  )
  | _ -> None

let parse_file (filename : string) : mapping list =
  let ic = open_in filename in
  let rec read_lines (acc : mapping list) : mapping list =
    try
      let line = input_line ic in
      match parse_line line with
      | Some mapping -> read_lines (mapping :: acc)
      | None -> read_lines acc
    with
    | End_of_file -> List.rev acc
  in
  let mappings = read_lines [] in
  close_in ic;
  mappings
