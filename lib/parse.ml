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
  map_type: string;
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
  | map_type :: trigger :: target_parts when List.mem map_type mapping_keywords ->
      let target = String.concat " " target_parts in
      Some { map_type; trigger; target }
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
