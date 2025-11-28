(** Type definitions for Zed keymap structure *)

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
} [@@deriving yojson]

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

module SMap = Map.Make(String)

type keymap = binding list SMap.t

let keymap_to_yojson (keymap : keymap) : Yojson.Safe.t =
  `List (SMap.bindings keymap |> List.map (fun (context, bindings) ->
    context_block_to_yojson { context; bindings }))

let keymap_of_yojson (json : Yojson.Safe.t) : (keymap, string) result =
  match json with
  | `List blocks ->
      let rec parse_blocks acc = function
        | [] -> Ok acc
        | block_json :: rest ->
            (match context_block_of_yojson block_json with
             | Ok { context; bindings } -> parse_blocks (SMap.add context bindings acc) rest
             | Error msg -> Error (Printf.sprintf "Failed to parse context block: %s" msg))
      in
      parse_blocks SMap.empty blocks
  | _ -> Error "Expected array for keymap"

module Keymap = struct
  type t = keymap

  let to_json : t -> Yojson.Safe.t = keymap_to_yojson
  let from_json : Yojson.Safe.t -> (t, string) result = keymap_of_yojson

  let from_file (filename : string) : t =
    try
      match from_json @@ Yojson.Safe.from_file filename with
      | Ok keymap -> keymap
      | Error msg -> failwith @@ Printf.sprintf "Keymap parse error in file '%s': %s" filename msg
    with
    | Sys_error msg -> failwith @@ Printf.sprintf "Failed to read file '%s': %s" filename msg
    | Yojson.Json_error msg -> failwith @@ Printf.sprintf "JSON parse error in file '%s': %s" filename msg
    | exn -> failwith @@ Printf.sprintf "Unexpected error loading '%s': %s" filename (Printexc.to_string exn)

  (** Constructing a keymap *)

  let empty : keymap = SMap.empty

  let add_binding_in_context ~ctx:(context : string) ~key:(key : string) ~cmd:(cmd : cmd) (keymap : t) : keymap =
    let new_binding = { key; cmd } in
    SMap.update context (function
      | None -> Some [new_binding]
      | Some existing_bindings -> Some (new_binding :: existing_bindings)
    ) keymap

  (** Querying and manipulating contexts *)

  let get_context_bindings (context : string) (keymap : t) : binding list =
    match SMap.find_opt context keymap with
    | Some bindings -> bindings
    | None -> []

  let has_context (context : string) (keymap : t) : bool =
    SMap.mem context keymap

  let remove_context (context : string) (keymap : t) : t =
    SMap.remove context keymap

  let get_all_contexts (keymap : t) : string list =
    SMap.bindings keymap |> List.map fst

  let merge_keymaps (keymap1 : t) (keymap2 : t) : t =
    SMap.union (fun _context bindings1 bindings2 ->
      Some (bindings1 @ bindings2)) keymap1 keymap2
end

module Print = struct
  let cmd : cmd -> string = function
  | Cmd name -> name
  | CmdArgs (name, arg) -> Printf.sprintf "%s(%s)" name (Yojson.Safe.to_string arg)
  | Null -> "null"

  let binding (b : binding) : string =
    Printf.sprintf "%s -> %s" b.key (cmd b.cmd)

  let context_block (context : string) (bindings : binding list) : string =
    Printf.sprintf "Context: %s\nBindings:\n  %s" context
    @@ String.concat "\n  " (List.map binding bindings)

  let keymap (k : keymap) : string =
    String.concat "\n\n" @@ List.map (fun (context, bindings) -> context_block context bindings) (SMap.bindings k)
end
