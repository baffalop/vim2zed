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

(** The high level block of bindings for a given context *)
type context_block = {
  context: string;
  bindings: binding list [@to_yojson bindings_to_yojson] [@of_yojson bindings_of_yojson];
  use_key_equivalents: bool [@default false];
} [@@deriving yojson]

type keymap = context_block list [@@deriving yojson]

let to_json (keymap : keymap) : Yojson.Safe.t =
  (* using derived yojson *)
  keymap_to_yojson keymap

module Print = struct
  let cmd : cmd -> string = function
  | Cmd name -> name
  | CmdArgs (name, arg) -> Printf.sprintf "%s(%s)" name (Yojson.Safe.to_string arg)
  | Null -> "null"

  let binding (b : binding) : string =
    Printf.sprintf "%s -> %s" b.key (cmd b.cmd)

  let context_block (block : context_block) : string =
    Printf.sprintf "Context: %s%s\nBindings:\n  %s" block.context
      (if block.use_key_equivalents then " [useKeyEquivalents]" else "")
      (String.concat "\n  " (List.map binding block.bindings))

  let keymap (k : keymap) : string =
    String.concat "\n\n" @@ List.map context_block k
end

module Parse : sig
  val load_keymap_from_file : string -> keymap
  val parse_keymap : Yojson.Safe.t -> keymap

  val debug_print : keymap -> unit
end = struct
  open Yojson.Safe

  (** Parse keymap using generated function with better error handling *)
  let parse_keymap (json : Yojson.Safe.t) : keymap =
    match keymap_of_yojson json with
    | Ok keymap -> keymap
    | Error msg -> failwith @@ Printf.sprintf "Failed to parse keymap: %s" msg

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
      Printf.printf "  Use key equivalents: %s\n" (string_of_bool block.use_key_equivalents);

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
