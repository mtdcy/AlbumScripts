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
#  => respect basename of target, in case pwd been used as input/$1
artist=$(basename "$2")
# special artist name
[ "$artist" = '群星' ] && unset artist
# remove comments
IFS='()（）' read -r artist _ <<< "$artist"

# find obsolute(s)
for album in "$2"/*; do
    [ -d "$1/$(basename "$album")" ] || {
        echo "=== remove outdated album $album"
        [ "$RUN" -ne 0 ] && rm -rfv "$album"
    }
done

# list albums 
find "$1" -maxdepth 1 -type d | sed '1d' |
while read -r album; do
    [ -e "$album/ignore" ] && echo "=== ignore album $album" && continue

    ARTIST="$artist" "$(dirname "$0")"/update-album.sh "$album" "$2/$(basename "$album")"
done
