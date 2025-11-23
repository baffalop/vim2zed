type mode = Normal | Visual | Insert | Operator | Visual_block | Select | Command | Lang | Terminal

type map_type = Map | Noremap

let mode_to_string = function
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

let parse_keyword (keyword : string) : mode option * map_type =
  if keyword = "map" then
    (None, Map)
  else if keyword = "noremap" then
    (None, Noremap)
  else
    (* Extract mode prefix *)
    let mode_char = String.sub keyword 0 1 in
    let rest = String.sub keyword 1 (String.length keyword - 1) in
    let mode = mode_from_string mode_char in
    let map_type = map_type_from_string rest in
    match map_type with
    | Some mt -> (mode, mt)
    | None -> (None, Map) (* fallback *)

let modes = ["n"; "v"; "i"; "o"; "x"; "s"; "c"; "l"; "t"]
let map_types = ["map"; "noremap"]

let mapping_keywords =
  let product (mapper : 'a -> 'b -> 'c) (xs : 'a list) (ys : 'b list) : 'c list =
    List.fold_left (fun acc x ->
      List.fold_left (fun acc' y ->
        mapper x y :: acc'
      ) acc ys
    ) [] xs
  in
  product (^) modes map_types

type mapping = {
  mode: mode option;
  map_type: map_type;
  trigger: string;
  target: string;
}

(** Check if line is not a comment and starts with a mapping command *)
let is_mapping_line (line : string) : bool =
  let trimmed = String.trim line in
  if String.length trimmed = 0 || trimmed.[0] = '"' then
    false
  else
    List.exists (fun keyword ->
      let prefix = keyword ^ " " in
      String.length trimmed >= String.length prefix &&
      String.sub trimmed 0 (String.length prefix) = prefix
    ) mapping_keywords

(** Parse a mapping line into its components *)
let parse_mapping_line (line : string) : mapping option =
  let trimmed = String.trim line in
  let parts = String.split_on_char ' ' trimmed in
  match parts with
  | keyword :: trigger :: target_parts when List.mem keyword mapping_keywords ->
      let target = String.concat " " target_parts in
      let (mode, map_type) = parse_keyword keyword in
      Some { mode; map_type; trigger; target }
  | _ -> None

let parse_file (filename : string) : mapping list =
  let ic = open_in filename in
  let rec read_lines (acc : mapping list) : mapping list =
    try
      let line = input_line ic in
      if is_mapping_line line then
        match parse_mapping_line line with
        | Some mapping -> read_lines (mapping :: acc)
        | None -> read_lines acc
      else
        read_lines acc
    with
    | End_of_file -> List.rev acc
  in
  let mappings = read_lines [] in
  close_in ic;
  mappings
