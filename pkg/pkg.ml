#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let opams = [
  Pkg.opam_file "opam" ~lint_deps_excluding:(Some ["io-page-unix"])
]

let () =
  Pkg.describe ~opams "mirage-unix" @@ fun _ ->
  Ok [
    Pkg.mllib "lib/oS.mllib"
  ]
