#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  Pkg.describe "mirage-unix" @@ fun _ ->
  Ok [
    Pkg.mllib "lib/oS.mllib"
  ]
