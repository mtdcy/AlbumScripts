#!/bin/bash 
# 

LC_ALL=C.UTF-8
set -e

. "$(dirname "$0")/lib.sh"

usage() {
    cat << EOF
    $(basename "$0") /path/to/origins /path/to/destination
EOF
}

[ $# -lt 2 ] && usage && exit 1

# find obsolute(s)
for dir in "$2"/*; do
    name="$(basename "$dir")"
    [ -d "$1/$name" ] || {
        format_string "### $name" " ==> outdated\n"
        [ "$RUN" -ne 0 ] && rm -rf "$dir"
    }
done

for dir in "$1"/*; do
    [ -d "$dir" ] || continue
    [ -L "$dir" ] && continue

    name="$(basename "$dir")"

    [ -e "$dir/ignore" ] && format_string "\n### $name" " ==> ignored\n" && continue

    target="$2/$name"

    # is artist ?
    if find "$dir" -maxdepth 1 -type f -iname "01*.flac" -o -iname "01*.wav" | grep "$dir" &> /dev/null; then 
        format_string "\n### 专辑 '$name'"  " ==> $target\n" 
        "$(dirname "$0")"/update-album.sh "$dir" "$target"
    else
        format_string "\n### 歌手 '$name'" " ==> $target\n" 
        "$(dirname "$0")"/update-artist-albums.sh "$dir" "$target"
    fi
done | tee update.log

wait
