(** Type definitions for Zed keymap structure *)

(** Represents a command that can be bound to a key *)
type cmd =
  | Cmd of string
  | CmdArgs of string * Yojson.Safe.t
  | Null

(** Represents a key binding entry *)
type binding = {
  key: string;
  cmd: cmd;
}

(** Represents a context block with its condition and bindings *)
type context_block = {
  context: string;
  bindings: binding list;
  use_key_equivalents: bool option;
}

(** The complete keymap structure *)
type keymap = context_block list


let to_json (keymap : keymap) : Yojson.Safe.t =
  let cmd_to_json : cmd -> Yojson.Safe.t = function
    | Cmd name -> `String name
    | CmdArgs (name, arg) -> `List [`String name; arg]
    | Null -> `Null
  in
  let bindings_to_json (bindings : binding list) : Yojson.Safe.t =
    `Assoc (bindings |> List.map (fun { key; cmd } -> (key, cmd_to_json cmd)))
  in
  let context_block_to_json (block : context_block) : Yojson.Safe.t = `Assoc [
    ("context", `String block.context);
    ("bindings", bindings_to_json block.bindings);
    ("useKeyEquivalents", `Bool (Option.value block.use_key_equivalents ~default:true));
  ] in
  `List (List.map context_block_to_json keymap)


module Print = struct
  let cmd : cmd -> string = function
  | Cmd name -> name
  | CmdArgs (name, arg) -> Printf.sprintf "%s(%s)" name (Yojson.Safe.to_string arg)
  | Null -> "null"

  let binding (b : binding) : string =
    Printf.sprintf "%s -> %s" b.key (cmd b.cmd)

  let context_block (block : context_block) : string =
    let bindings_str = String.concat "\n  " (List.map binding block.bindings) in
    let use_key_equiv_str = match block.use_key_equivalents with
      | Some true -> " [useKeyEquivalents: true]"
      | Some false -> " [useKeyEquivalents: false]"
      | None -> ""
    in
    Printf.sprintf "Context: %s%s\nBindings:\n  %s"
      block.context use_key_equiv_str bindings_str

  let keymap (k : keymap) : string =
    String.concat "\n\n" @@ List.map context_block k
end


module Parse : sig
  val load_keymap_from_file : string -> keymap
  val parse_keymap : Yojson.Safe.t -> keymap

  val debug_print : keymap -> unit
end = struct
  open Yojson.Safe

  let parse_cmd ~(context : string) ~(key : string) (json : Yojson.Safe.t) : cmd =
    match json with
    | `String name -> Cmd name
    | `List [`String name; arg] -> CmdArgs (name, arg)
    | `Null -> Null
    | _ ->
        let json_str = Yojson.Safe.pretty_to_string json in
        failwith @@ Printf.sprintf "Invalid command format for key '%s' in context '%s': %s" key context json_str

  let parse_binding ~(context : string) (key : string) (json : Yojson.Safe.t) : binding =
    try
      { key; cmd = parse_cmd ~context ~key json }
    with
    | Failure msg -> failwith msg
    | exn -> failwith @@ Printf.sprintf "Failed to parse binding for key '%s' in context '%s': %s" key context (Printexc.to_string exn)

  let parse_bindings ~(context : string) (json : Yojson.Safe.t) : binding list =
    match json with
    | `Assoc bindings_list ->
        List.map (fun (key, cmd_json) -> parse_binding ~context key cmd_json) bindings_list
    | _ -> failwith @@ Printf.sprintf "Invalid bindings format in context '%s': expected object, got %s" context (Yojson.Safe.pretty_to_string json)

  let parse_context_block (json : Yojson.Safe.t) : context_block =
    match json with
    | `Assoc fields ->
        let context =
          match List.assoc_opt "context" fields with
          | Some (`String ctx) -> ctx
          | Some other -> failwith @@ Printf.sprintf "Context field must be a string, got: %s" (Yojson.Safe.pretty_to_string other)
          | None -> failwith "Missing context field in context block"
        in
        let bindings =
          match List.assoc_opt "bindings" fields with
          | Some bindings_json ->
              (try parse_bindings ~context bindings_json
              with Failure msg -> failwith msg
              | exn -> failwith @@ Printf.sprintf "Failed to parse bindings in context '%s': %s" context (Printexc.to_string exn))
          | None -> []
        in
        let use_key_equivalents =
          match List.assoc_opt "use_key_equivalents" fields with
          | Some (`Bool b) -> Some b
          | None -> None
          | Some other -> failwith @@ Printf.sprintf "use_key_equivalents field must be a boolean in context '%s', got: %s" context (Yojson.Safe.pretty_to_string other)
        in
        { context; bindings; use_key_equivalents }
    | _ -> failwith @@ Printf.sprintf "Invalid context block format: expected object, got %s" (Yojson.Safe.pretty_to_string json)

  let parse_keymap (json : Yojson.Safe.t) : keymap =
    match json with
    | `List context_blocks ->
        List.mapi (fun i block ->
          try parse_context_block block
          with
          | Failure msg -> failwith @@ Printf.sprintf "Error in context block %d: %s" i msg
          | exn -> failwith @@ Printf.sprintf "Unexpected error in context block %d: %s" i (Printexc.to_string exn)
        ) context_blocks
    | _ -> failwith @@ Printf.sprintf "Invalid keymap format: expected array of context blocks, got %s" (Yojson.Safe.pretty_to_string json)

  let load_keymap_from_file (filename : string) : keymap =
    try
      let json = from_file filename in
      parse_keymap json
    with
    | Sys_error msg -> failwith @@ Printf.sprintf "Failed to read file '%s': %s" filename msg
    | Yojson.Json_error msg -> failwith @@ Printf.sprintf "JSON parse error in file '%s': %s" filename msg
    | Failure msg -> failwith @@ Printf.sprintf "Keymap parse error in file '%s': %s" filename msg
    | exn -> failwith @@ Printf.sprintf "Unexpected error loading '%s': %s" filename (Printexc.to_string exn)

  (** Debugging functions *)

  let list_take (n : int) (lst : 'a list) : 'a list =
    let rec aux acc n = function
      | [] -> List.rev acc
      | _ when n <= 0 -> List.rev acc
      | x :: xs -> aux (x :: acc) (n - 1) xs
    in
    aux [] n lst

  (** Validate keymap structure and report any issues *)
  let validate_keymap (keymap : keymap) : string list =
    let errors = ref [] in
    List.iteri (fun i block ->
      if String.length block.context = 0 then
        errors := (Printf.sprintf "Context block %d has empty context string" i) :: !errors;
      List.iteri (fun j binding ->
        if String.length binding.key = 0 then
          errors := (Printf.sprintf "Context block %d, binding %d has empty key" i j) :: !errors;
        match binding.cmd with
        | Cmd "" ->
            errors := (Printf.sprintf "Context block %d, binding %d ('%s') has empty command" i j binding.key) :: !errors
        | CmdArgs ("", _) ->
            errors := (Printf.sprintf "Context block %d, binding %d ('%s') has empty command name" i j binding.key) :: !errors
        | _ -> ()
      ) block.bindings
    ) keymap;
    List.rev !errors

  (** Print detailed information about keymap structure for debugging *)
  let debug_print (keymap : keymap) : unit =
    Printf.printf "=== Keymap Debug Info ===\n";
    Printf.printf "Total context blocks: %d\n\n" (List.length keymap);

    List.iteri (fun i block ->
      Printf.printf "Block %d:\n" i;
      Printf.printf "  Context: '%s'\n" block.context;
      Printf.printf "  Bindings count: %d\n" (List.length block.bindings);
      Printf.printf "  Use key equivalents: %s\n"
        (match block.use_key_equivalents with
        | Some true -> "true"
        | Some false -> "false"
        | None -> "not set");

      if List.length block.bindings > 0 then (
        Printf.printf "  Sample bindings:\n";
        let sample = list_take 3 block.bindings in
        List.iter (fun binding ->
          Printf.printf "    %s\n" (Print.binding binding)
        ) sample;
        if List.length block.bindings > 3 then
          Printf.printf "    ... and %d more\n" (List.length block.bindings - 3)
      );
      Printf.printf "\n"
    ) keymap;

    let validation_errors = validate_keymap keymap in
    if validation_errors <> [] then (
      Printf.printf "=== Validation Errors ===\n";
      List.iter (Printf.printf "ERROR: %s\n") validation_errors
    ) else (
      Printf.printf "=== Validation: PASSED ===\n"
    )
end
