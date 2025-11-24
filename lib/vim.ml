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

type keystroke =
  | Char of char
  | Leader
  | Return
  | Escape
  | Space
  | Tab
  | Backspace
  | Delete
  | Control of char
  | Alt of char
  | Shift of char
  | F of int
  | Arrow of [`Up | `Down | `Left | `Right]
  | Special of string
  | Plug of string

type mapping = {
  mode: mode;
  map_type: map_type;
  trigger: keystroke list;
  target: keystroke list;
}

(* pretty printing *)

let string_of_mode = function
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

let string_of_map_type = function
  | Map -> "map"
  | Noremap -> "noremap"

let string_of_keystroke = function
  | Char c -> String.make 1 c
  | Leader -> "<Leader>"
  | Return -> "<CR>"
  | Escape -> "<Esc>"
  | Space -> "<Space>"
  | Tab -> "<Tab>"
  | Backspace -> "<BS>"
  | Delete -> "<Del>"
  | Control c -> "<C-" ^ String.make 1 c ^ ">"
  | Alt c -> "<A-" ^ String.make 1 c ^ ">"
  | Shift c -> "<S-" ^ String.make 1 c ^ ">"
  | F n -> "<F" ^ string_of_int n ^ ">"
  | Arrow `Up -> "<Up>"
  | Arrow `Down -> "<Down>"
  | Arrow `Left -> "<Left>"
  | Arrow `Right -> "<Right>"
  | Special s -> "<" ^ s ^ ">"
  | Plug s -> "<Plug>(" ^ s ^ ")"

let string_of_keystrokes keystrokes =
  String.concat " " (List.map string_of_keystroke keystrokes)

let pretty_print : mapping list -> unit =
  List.iter @@ fun (mapping : mapping) ->
    Printf.printf "Mode: %s, Map Type: %s, Trigger: %s, Target: %s\n"
      (string_of_mode mapping.mode)
      (string_of_map_type mapping.map_type)
      (string_of_keystrokes mapping.trigger)
      (string_of_keystrokes mapping.target)


(* Opal parsers *)

open Opal

type 'a cparser = (char, 'a) parser

let until (end_c : char) : string cparser =
  many1 (satisfy (fun c -> c <> end_c)) => implode

let nospace : char cparser = satisfy (fun c -> c <> ' ' && c <> '\t')

let token_choice (tokens : (string * 'a) list) : 'a cparser =
  tokens
  |> List.map (fun (tok, result) -> token tok >> return result)
  |> choice

let mode_p : mode cparser = token_choice [
    ("n", Normal);
    ("v", Visual);
    ("i", Insert);
    ("o", Operator);
    ("x", Visual_block);
    ("s", Select);
    ("c", Command);
    ("l", Lang);
    ("t", Terminal);
  ]

let map_type_p : map_type cparser = token_choice [
    ("map", Map);
    ("noremap", Noremap);
  ]

let keyword_p : (mode * map_type) cparser =
    (* Handle prefixed commands like "nnoremap", "vmap", etc. *)
    (mode_p >>= fun mode ->
     map_type_p >>= fun map_type ->
     return (mode, map_type))

    (* Handle plain "map" or "noremap" *)
    <|> (map_type_p >>= fun map_type -> return (All, map_type))

let special_key : keystroke cparser =
  let simple_special : keystroke cparser = token_choice [
    ("Leader", Leader);
    ("CR", Return);
    ("Esc", Escape);
    ("Space", Space);
    ("Tab", Tab);
    ("BS", Backspace);
    ("Del", Delete);
    ("Up", Arrow `Up);
    ("Down", Arrow `Down);
    ("Left", Arrow `Left);
    ("Right", Arrow `Right);
  ] in
  let arg_special = choice [
    token "C-" >> any >>= (fun c -> return @@ Control c);
    token "A-" >> any >>= (fun c -> return @@ Alt c);
    token "S-" >> any >>= (fun c -> return @@ Shift c);
    token "F" >> many1 digit => implode >>= (fun n -> return @@ F (int_of_string n));
    until '>' >>= fun s -> return @@ Special s;
  ] in
  let plug : keystroke cparser =
    token "<Plug>(" >> until ')' >>= fun s ->
    exactly ')'
    >> return @@ Plug s
  in
  exactly '<' >> choice [
    plug;
    simple_special <|> arg_special >>= fun s -> exactly '>' >> return s;
  ]

let all_keystrokes : keystroke cparser =
  special_key <|> (any >>= fun c -> return @@ Char c)

let keystrokes_nospace : keystroke cparser =
  special_key <|> (nospace >>= fun c -> return @@ Char c)

let mapping_parser : mapping cparser =
  spaces >>
  keyword_p >>= fun (mode, map_type) ->
  space >>
  many1 keystrokes_nospace >>= fun trigger ->
  space >>
  many1 all_keystrokes >>= fun target ->
  return { mode; map_type; trigger; target }

(** Parse a mapping line into its components *)
let parse_line (line : string) : mapping option =
  parse mapping_parser @@ LazyStream.of_string line

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
