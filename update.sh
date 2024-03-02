#!/bin/bash 
# 

LC_ALL=C.UTF-8
set -e

. $(dirname "$0")/lib.sh

usage() {
    cat << EOF
    $(basename "$0") /path/to/origins /path/to/destination
EOF
}

[ $# -lt 2 ] && usage && exit 1

# artist or album list
LIST=($(find "$1"/* -maxdepth 0 -type d))

for dir in "${LIST[@]}"; do
    
    target="$2${dir##$1}"

    # is artist ?
    if [ $(find "$dir"/* -maxdepth 0 -type d | wc -l) -gt 0 ]; then
        echo "update artist: $dir -> $target" 
        $(dirname "$0")/update-artist-album.sh "$dir" "$target" #> /dev/null
    else
        echo "update album: $dir -> $target" 
        $(dirname "$0")/update-album.sh "$dir" "$target" #> /dev/null
    fi
done

wait
