let modes = ["n"; "v"; "i"; "o"; "x"; "s"; "c"; "l"; "t"]
let map_types = ["map"; "noremap"]

let mapping_keywords =
  let product mapper xs ys =
    List.fold_left (fun acc x ->
      List.fold_left (fun acc' y ->
        mapper x y :: acc'
      ) acc ys
    ) [] xs
  in
  product (^) modes map_types

(** Check if line is not a comment and starts with a mapping command *)
let is_mapping_line line =
  let trimmed = String.trim line in
  if String.length trimmed = 0 || trimmed.[0] = '"' then
    false
  else
    List.exists (fun keyword ->
      let prefix = keyword ^ " " in
      String.length trimmed >= String.length prefix &&
      String.sub trimmed 0 (String.length prefix) = prefix
    ) mapping_keywords

let parse_file filename =
  let ic = open_in filename in
  let rec read_lines acc =
    try
      let line = input_line ic in
      if is_mapping_line line then
        read_lines (line :: acc)
      else
        read_lines acc
    with
    | End_of_file -> List.rev acc
  in
  let mappings = read_lines [] in
  close_in ic;
  mappings
