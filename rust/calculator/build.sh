#!/bin/bash

set -euo pipefail
set -x

cargo build --release

mkdir -p build
cp target/wasm32-wasip2/release/calculator.wasm build/calculator.wasm

wasm-tools print build/calculator.wasm -o build/calculator.wat
wasm-tools dump build/calculator.wasm -o build/calculator.dump
wasm-tools component wit build/calculator.wasm -o build/calculator.exported.wit
