type mapping = {
  map_type: string;
  trigger: string;
  target: string;
}

val parse_file : string -> mapping list
