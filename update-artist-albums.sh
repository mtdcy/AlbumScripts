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

# list albums 
LIST=($(ls -d "$1"/*/))

for album in "${LIST[@]}"; do
    ARTIST="$artist" $(dirname "$0")/update-album.sh "$album" "$2"/$(basename "$album")
done
