(lang dune 3.20)

(name zvim)

(generate_opam_files true)

(source
 (github baffalop/zvim))

(authors "Nikita Gaidakov <nikita.gaidakov@gmail.com>")

(maintainers "Nikita Gaidakov <nikita.gaidakov@gmail.com>")

(license LICENSE)

(documentation https://github.com/baffalop/zvim)

(package
 (name zvim)
 (synopsis "Script for translating vim mappings (vimrc) to Zed keymap")
 (description "")
 (depends ocaml opal)
 (tags
  (zed zed-editor vim vimrc vimscript zed-keymap keymap)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
