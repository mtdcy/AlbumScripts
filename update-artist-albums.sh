#!/bin/bash
#
# Usage: $0 <input dir> <output dir>

set -e

. "$(dirname "$0")/lib.sh"

usage() {
    cat << EOF
    $(basename "$0") path/to/artist path/to/destination
EOF
}

[ $# -lt 1 ] && usage && exit 1

# artist
artist=$(basename "$(realpath "$1")")
# special artist name
[ "$artist" = '群星' ] && unset artist
# remove comments
IFS='()（）' read -r artist _ <<< "$artist"
        
format_put "### 歌手 '$artist'" " ==> $2\n" 

# find outdated files
for album in "$2"/*; do
    name="$(basename "$album")"
    [ -e "$1/$name" ] || {
        format_put "=== $name" " ==> $(format_yellow "outdated\n")"
        [ "$RUN" -ne 0 ] && rm -rf "$album"
    }
done

# list albums 
for album in "$1/"*; do
    name="$(basename "$album")"

    [ -e "$album/ignore" ] && format_put "=== $name" " ==> $(format_yellow "ignored\n")" && continue

    if [ -d "$album" ]; then
        ARTIST="$artist" "$(dirname "$0")"/update-album.sh "$album" "$2/$name"
    elif [ -f "$album" ]; then
        format_put "--- $name" " ==> $2/$name\n"
        [ "$RUN" -ne 0 ] && cp "$album" "$2/$name"
    fi
done
