#!/bin/bash

set -euo pipefail
set -x

mkdir -p build

# Split compile/link so -O1 doesn't trigger wasm-opt at link time.
clang -c -O1 -target wasm32-wasip2 --sysroot=../../_sysroot \
  greet.c -o build/greet.o
clang -target wasm32-wasip2 --sysroot=../../_sysroot \
  -mexec-model=reactor \
  -Wl,--no-entry -Wl,--export-all \
  -Wl,--component-type,greet.wit \
  build/greet.o -o build/greet.wasm

wasm-tools print build/greet.wasm -o build/greet.wat
wasm-tools dump build/greet.wasm -o build/greet.dump
wasm-tools component wit build/greet.wasm -o build/greet.exported.wit
