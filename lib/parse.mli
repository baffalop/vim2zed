type mode = All | Normal | Visual | Insert | Operator | Visual_block | Select | Command | Lang | Terminal

type map_type = Map | Noremap

type mapping = {
  mode: mode;
  map_type: map_type;
  trigger: string;
  target: string;
}

val mode_to_string : mode -> string
val map_type_to_string : map_type -> string
val parse_file : string -> mapping list
