let mapping_prefixes = [
  "map";
  "noremap";
  "nnoremap";
  "vnoremap";
  "nmap";
  "vmap";
  "imap";
  "inoremap";
  "onoremap";
  "xmap";
  "xnoremap";
  "smap";
  "snoremap";
  "cmap";
  "cnoremap";
  "lmap";
  "lnoremap";
  "tmap";
  "tnoremap";
]

let is_mapping_line line =
  let trimmed = String.trim line in
  (* Check if line is not a comment and starts with a mapping command *)
  if String.length trimmed = 0 || trimmed.[0] = '"' then
    false
  else
    List.exists (fun prefix ->
      String.length trimmed >= String.length prefix &&
      String.sub trimmed 0 (String.length prefix) = prefix
    ) mapping_prefixes

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
