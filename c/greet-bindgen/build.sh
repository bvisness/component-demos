#!/bin/bash

set -euo pipefail
set -x

mkdir -p build

wit-bindgen c --out-dir bindings greet.wit

# We build and link separately so we can compile with optimizations without
# invoking binaryen (which is annoyingly activated by default and chokes on
# components).
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
