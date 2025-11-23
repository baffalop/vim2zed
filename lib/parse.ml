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

let map_type_to_string = function
  | Map -> "map"
  | Noremap -> "noremap"

(* Opal parsers *)

open Opal

let whitespace1 = many1 (exactly ' ' <|> exactly '\t') >> return ()

let word = many1 (alpha_num <|> exactly '_') => implode

let mode_parser =
  choice [
    token "n" >> return Normal;
    token "v" >> return Visual;
    token "i" >> return Insert;
    token "o" >> return Operator;
    token "x" >> return Visual_block;
    token "s" >> return Select;
    token "c" >> return Command;
    token "l" >> return Lang;
    token "t" >> return Terminal;
  ]

let map_type_parser =
  choice [
    token "map" >> return Map;
    token "noremap" >> return Noremap;
  ]

let keyword_parser =
  choice [
    (* Handle prefixed commands like "nnoremap", "vmap", etc. *)
    (mode_parser >>= fun mode ->
     map_type_parser >>= fun map_type ->
     return (mode, map_type));
    (* Handle plain "map" or "noremap" *)
    (map_type_parser >>= fun map_type ->
     return (All, map_type));
  ]

let rest_of_line = many (satisfy (fun c -> c <> '\n')) => implode

let mapping_parser =
  spaces >>
  keyword_parser >>= fun (mode, map_type) ->
  whitespace1 >>
  word >>= fun trigger ->
  whitespace1 >>
  rest_of_line >>= fun target ->
  return { mode; map_type; trigger; target = String.trim target }

(** Parse a mapping line into its components *)
let parse_line (line : string) : mapping option =
  parse mapping_parser (LazyStream.of_string line)

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
