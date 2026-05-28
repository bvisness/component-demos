#!/bin/bash

set -euo pipefail
set -x

mkdir -p build

# We build and link separately so we can compile with optimizations without
# invoking binaryen (which is annoyingly activated by default and chokes on
# components).
clang -c -O1 -target wasm32-wasip2 \
  greet.c -o build/greet.o
clang -nostdlib -target wasm32-wasip2 \
  -Wl,--no-entry -Wl,--export-all \
  -Wl,--component-type,greet.wit \
  build/greet.o -o build/greet.wasm

wasm-tools print build/greet.wasm -o build/greet.wat
wasm-tools dump build/greet.wasm -o build/greet.dump
wasm-tools component wit build/greet.wasm -o build/greet.exported.wit
