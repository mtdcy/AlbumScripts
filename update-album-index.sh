#!/bin/bash
# 
# $0 /path/to/artist

set -e
umask 022

LIBROOT=$(dirname "$0")
. "$LIBROOT"/lib.sh

RUN=${RUN:-0}

cd "$1"
for album in *; do
    [ -d "$album" ] || continue

    formated="$(sed         \
        -e 's/（/ (/g'      \
        -e 's/）/) /g'      \
        -e 's/-/ - /g'      \
        -e 's/\s\+/ /g'     \
        <<< "$album")"

    [ "$formated" = "$album" ] || {
        echo "=== rename: $album => $formated"
        [ "$RUN" -ne 0 ] && mv "$album" "$formated"
    }
done
cd -
