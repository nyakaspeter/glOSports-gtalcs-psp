#!/bin/sh
# mkpatch.sh <NNNN-name> <file in upstream>...: diff of the named files between
# upstream at 1132a76 + patches/0001..(NNNN-1) and the current upstream/ -> patches/NNNN-name.patch
set -eu
P=$(cd "$(dirname "$0")/.." && pwd)
SRC=${SRC:-$P/upstream}  # SRC=<other tree>/upstream: diff that tree instead
name=$1; shift; n=${name%%-*}
tmp=$(mktemp -d); git -C "$P/upstream" worktree add -q "$tmp/wt" 1132a76
for p in "$P"/patches/[0-9]*; do
    b=$(basename "$p"); [ "${b%%-*}" -lt "$n" ] || continue
    case $p in *.xz) xz -dc "$p" | git -C "$tmp/wt" apply;; *) git -C "$tmp/wt" apply "$p";; esac
done
: > "$P/patches/$name.patch"
for f in "$@"; do
    (cd "$tmp" && diff -u "wt/$f" "$SRC/$f" | sed "1s|^--- wt/$f.*|--- a/$f|; 2s|^+++ .*|+++ b/$f|") >> "$P/patches/$name.patch" || true
done
git -C "$P/upstream" worktree remove --force "$tmp/wt"; rm -rf "$tmp"
wc -l "$P/patches/$name.patch"
