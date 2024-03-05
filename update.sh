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
    [ -d "$1/$(basename "$dir")" ] || {
        echo "### remove obsolute $dir"
        [ "$RUN" -ne 0 ] && rm -rfv "$dir"
    }
done

# artist or album list
LIST=($(find "$1" -maxdepth 1 -type d))

for dir in "$1"/*; do
    [ -d "$dir" ] || continue

    [ -e "$dir/ignore" ] && echo -e "\n### ignore $dir" && continue

    target="$2${dir##"$1"}"

    # is artist ?
    if [ "$(find "$dir"/* -maxdepth 0 -type d ! -iname "CD*" | wc -l)" -gt 0 ]; then
        echo -e "\n### update artist: $dir -> $target" 
        "$(dirname "$0")"/update-artist-albums.sh "$dir" "$target" #> /dev/null
    else
        echo -e "\n### update album: $dir -> $target" 
        "$(dirname "$0")"/update-album.sh "$dir" "$target" #> /dev/null
    fi
done | tee update.log

wait
