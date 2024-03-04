#!/bin/bash
#
# Usage: $0 <input dir> <output dir>

set -e

. $(dirname "$0")/lib.sh

usage() {
    cat << EOF
    $(basename "$0") path/to/artist path/to/destination
EOF
}

[ $# -lt 1 ] && usage && exit 1

# artist
artist=$(basename "$2")
# special artist name
[ "$artist" = '群星' ] && unset artist
# remove trailing chars
artist="${artist%.*}"

# find obsolute(s)
find "$2" -maxdepth 1 -type d | sed '1d' |
while read -r album; do
    [ -d "$1"/$(basename "$album") ] || {
        echo "remove obsolute album $album"
        [ "$RUN" -ne 0 ] && rm -rf "$album"
    }
done

# list albums 
find "$1" -maxdepth 1 -type d | sed '1d' |
while read -r album; do
    ARTIST="$artist" $(dirname "$0")/update-album.sh "$album" "$2"/$(basename "$album")
done
