#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSROOT_DIR="$SCRIPT_DIR/_sysroot"

# Variants of the wasm32 builtins we know how to install. Each must correspond
# to a `wasm32-unknown-<variant>/` directory in the libclang_rt tarball.
BUILTIN_VARIANTS=(wasi wasip1 wasip2 wasi-threads wasip1-threads)

echo "Fetching latest wasi-sdk release..."
RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/WebAssembly/wasi-sdk/releases/latest)
TAG=$(echo "$RELEASE_JSON" | jq -r .tag_name)

SYSROOT_URL=$(echo "$RELEASE_JSON" \
  | jq -r '.assets[] | select(.name | test("^wasi-sysroot-.*\\.tar\\.gz$")) | .browser_download_url')
BUILTINS_URL=$(echo "$RELEASE_JSON" \
  | jq -r '.assets[] | select(.name | test("^libclang_rt-.*\\.tar\\.gz$")) | .browser_download_url')

if [ -z "$SYSROOT_URL" ] || [ -z "$BUILTINS_URL" ]; then
  echo "Could not find required assets in release $TAG" >&2
  exit 1
fi

echo "Release:  $TAG"
echo "Sysroot:  $SYSROOT_URL"
echo "Builtins: $BUILTINS_URL"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- Sysroot ---

echo
echo "Downloading sysroot..."
curl -fL --progress-bar -o "$TMP/sysroot.tar.gz" "$SYSROOT_URL"

echo "Extracting to $SYSROOT_DIR..."
rm -rf "$SYSROOT_DIR"
mkdir -p "$SYSROOT_DIR"
tar -xzf "$TMP/sysroot.tar.gz" -C "$SYSROOT_DIR" --strip-components=1

# --- Builtins ---
#
# Check what clang already has before touching the system. Each variant has a
# specific destination clang reports via `-print-libgcc-file-name`; if the file
# is already there, we leave it alone.

echo
echo "Checking clang for existing wasm32 builtins..."
MISSING_VARIANTS=()
MISSING_DESTS=()
for variant in "${BUILTIN_VARIANTS[@]}"; do
  dest=$(clang --target=wasm32-"$variant" -print-libgcc-file-name)
  if [ -f "$dest" ]; then
    echo "  [present] wasm32-$variant"
  else
    echo "  [missing] wasm32-$variant -> $dest"
    MISSING_VARIANTS+=("$variant")
    MISSING_DESTS+=("$dest")
  fi
done

if [ ${#MISSING_VARIANTS[@]} -eq 0 ]; then
  echo
  echo "All wasm32 builtins are already installed. Skipping download."
  echo
  echo "Done. Use --sysroot=$SYSROOT_DIR in C build scripts."
  exit 0
fi

echo
echo "Downloading compiler-rt builtins..."
curl -fL --progress-bar -o "$TMP/builtins.tar.gz" "$BUILTINS_URL"

BUILTINS_DIR="$TMP/builtins"
mkdir -p "$BUILTINS_DIR"
tar -xzf "$TMP/builtins.tar.gz" -C "$BUILTINS_DIR" --strip-components=1

echo
echo "These paths require root. The script will run:"
PLAN=()
for ((i=0; i<${#MISSING_VARIANTS[@]}; i++)); do
  src="$BUILTINS_DIR/wasm32-unknown-${MISSING_VARIANTS[i]}/libclang_rt.builtins.a"
  if [ ! -f "$src" ]; then
    echo "  (tarball has no entry for wasm32-${MISSING_VARIANTS[i]}, skipping)"
    continue
  fi
  echo "  sudo install -D -m 644 $src ${MISSING_DESTS[i]}"
  PLAN+=("$src" "${MISSING_DESTS[i]}")
done

if [ ${#PLAN[@]} -eq 0 ]; then
  echo
  echo "No builtins from the tarball matched the missing variants. Nothing to do."
  exit 0
fi

echo
read -r -p "Proceed with sudo install? [y/N] " confirm
case "$confirm" in
  y|Y|yes|YES) ;;
  *) echo "Skipping builtins install."; exit 0 ;;
esac

for ((i=0; i<${#PLAN[@]}; i+=2)); do
  sudo install -D -m 644 "${PLAN[i]}" "${PLAN[i+1]}"
done

echo
echo "Done."
echo "  Use --sysroot=$SYSROOT_DIR in C build scripts."
echo "  Builtins are installed where clang's --target=wasm32-* expects them."
