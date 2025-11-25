(lang dune 3.20)

(name vim2zed)

(generate_opam_files true)

(source
 (github baffalop/vim2zed))

(authors "Nikita Gaidakov <nikita.gaidakov@gmail.com>")

(maintainers "Nikita Gaidakov <nikita.gaidakov@gmail.com>")

(license LICENSE)

(documentation https://github.com/baffalop/vim2zed)

(package
 (name vim2zed)
 (synopsis "Script for translating vim mappings (vimrc) to Zed keymap")
 (description "")
 (depends ocaml opal yojson ppx_deriving ppx_deriving_yojson)
 (tags
  (zed zed-editor vim vimrc vimscript zed-keymap keymap)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
