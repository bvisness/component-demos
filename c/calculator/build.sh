#!/bin/bash

set -euo pipefail
set -x

mkdir -p build

# We build and link separately so we can compile with optimizations without
# invoking binaryen (which is annoyingly activated by default and chokes on
# components).
clang -c -O1 -target wasm32-wasip2 \
  calculator.c -o build/calculator.o
clang -nostdlib -target wasm32-wasip2 \
  -Wl,--no-entry -Wl,--export-all \
  -Wl,--component-type,calculator.wit \
  build/calculator.o -o build/calculator.wasm

wasm-tools print build/calculator.wasm -o build/calculator.wat
wasm-tools dump build/calculator.wasm -o build/calculator.dump
wasm-tools component wit build/calculator.wasm -o build/calculator.exported.wit
