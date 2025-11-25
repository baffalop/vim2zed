(** Type definitions for Zed keymap structure *)

(** Command that a key is mapped to *)
type cmd =
  | Cmd of string
  | CmdArgs of string * Yojson.Safe.t
  | Null

let cmd_to_yojson : cmd -> Yojson.Safe.t = function
  | Cmd name -> `String name
  | CmdArgs (name, arg) -> `List [`String name; arg]
  | Null -> `Null

let cmd_of_yojson (json : Yojson.Safe.t) : (cmd, string) result =
  match json with
  | `String name -> Ok (Cmd name)
  | `List [`String name; arg] -> Ok (CmdArgs (name, arg))
  | `Null -> Ok Null
  | _ -> Error "Invalid command format"

type binding = {
  key: string;
  cmd: cmd;
}

let bindings_to_yojson (bindings : binding list) : Yojson.Safe.t =
  `Assoc (bindings |> List.map (fun { key; cmd } -> (key, cmd_to_yojson cmd)))

let bindings_of_yojson (json : Yojson.Safe.t) : (binding list, string) result =
  match json with
  | `Assoc bindings_list ->
      let rec convert_bindings acc = function
        | [] -> Ok (List.rev acc)
        | (key, cmd_json) :: rest ->
            (match cmd_of_yojson cmd_json with
             | Ok cmd -> convert_bindings ({ key; cmd } :: acc) rest
             | Error msg -> Error (Printf.sprintf "Failed to parse command for key '%s': %s" key msg))
      in
      convert_bindings [] bindings_list
  | _ -> Error "Expected object for bindings"

type context_block = {
  context: string;
  bindings: binding list [@to_yojson bindings_to_yojson] [@of_yojson bindings_of_yojson];
} [@@deriving yojson { strict = false }]

type keymap = context_block list [@@deriving yojson]

let to_json : keymap -> Yojson.Safe.t = keymap_to_yojson
let from_json : Yojson.Safe.t -> (keymap, string) result = keymap_of_yojson

let load_keymap_from_file (filename : string) : keymap =
  try
    match from_json @@ Yojson.Safe.from_file filename with
    | Ok keymap -> keymap
    | Error msg -> failwith @@ Printf.sprintf "Keymap parse error in file '%s': %s" filename msg
  with
  | Sys_error msg -> failwith @@ Printf.sprintf "Failed to read file '%s': %s" filename msg
  | Yojson.Json_error msg -> failwith @@ Printf.sprintf "JSON parse error in file '%s': %s" filename msg
  | exn -> failwith @@ Printf.sprintf "Unexpected error loading '%s': %s" filename (Printexc.to_string exn)

module Print = struct
  let cmd : cmd -> string = function
  | Cmd name -> name
  | CmdArgs (name, arg) -> Printf.sprintf "%s(%s)" name (Yojson.Safe.to_string arg)
  | Null -> "null"

  let binding (b : binding) : string =
    Printf.sprintf "%s -> %s" b.key (cmd b.cmd)

  let context_block (block : context_block) : string =
    Printf.sprintf "Context: %s\nBindings:\n  %s" block.context
    @@ String.concat "\n  " (List.map binding block.bindings)

  let keymap (k : keymap) : string =
    String.concat "\n\n" @@ List.map context_block k
end
