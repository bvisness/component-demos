#!/bin/bash

set -euo pipefail
set -x

mkdir -p build

# Regenerate C bindings from the WIT world.
# Produces:
#   bindings/greet.h                 - typed prototype of our impl function
#   bindings/greet.c                 - canonical ABI glue (cabi_realloc, cabi_post_greet,
#                                      and the `greet` wrapper that calls our impl)
#   bindings/greet_component_type.o  - relocatable carrying the `component-type` custom section
wit-bindgen c --out-dir bindings greet.wit

clang -c -O1 -target wasm32-wasip2 --sysroot=../../_sysroot \
  greet.c -o build/greet.o
clang -c -O1 -target wasm32-wasip2 --sysroot=../../_sysroot \
  bindings/greet.c -o build/greet_bindings.o
clang -target wasm32-wasip2 --sysroot=../../_sysroot \
  -mexec-model=reactor \
  -Wl,--no-entry \
  build/greet.o build/greet_bindings.o bindings/greet_component_type.o \
  -o build/greet.wasm

wasm-tools print build/greet.wasm -o build/greet.wat
wasm-tools dump build/greet.wasm -o build/greet.dump
wasm-tools component wit build/greet.wasm -o build/greet.exported.wit
