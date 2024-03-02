#!/bin/bash

LC_ALL=C
set -e

artist="$1"
cd "$artist" || exit

for dir in *; do
    # album
    # '2005.11.01 - 十一月的萧邦'
    IFS='-' read -r a b <<< "$dir"
    [ -n "$b" ] && album="$b" || album="$a"

    # remove spaces
    album=${album// /}

    find "$dir" -name "*.wma" |
    while read -r path; do
        IFS='/' read -r _ title <<< "$path"

        # title
        title=${title%.*}
        # remove leading numbers
        title=${title//[0-9.]/}
        # remove spaces
        title=${title// /}

        echo "$path => artist: [$artist], album: [$album], title: [$title]"
        id3tool -t "$title" -a "$album" -r "$artist" "$path"
    done
done
