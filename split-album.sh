#!/bin/bash
#
# requires: brew install cuetools shntool flac
#

# Usage: $0 path/to/cue 

set -e
LC_ALL=C.UTF-8
IFS=$'\n'

for cue in "$@"; do
    # find cue file
    [ -d "$cue" ] && {
        cue=$(find "$cue"/*.cue -type f | head -n1)
    }

    [ ! -e "$cue" ] && echo "cue $cue not exists" && continue

    # change encodings
    vim +"set fileencoding=utf-8 | wq" "$cue" || true

    # enter source dir
    cd "$(dirname "$cue")" && cue="$(basename "$cue")"

    # find data file
    for ext in wav flac ape; do
        [ -e "${cue%.*}.$ext" ] && file="${cue%.*}.$ext"
    done

    [ -z "$file" ] && echo "can't find data file for $cue" && cd - && continue;

    echo ">>> split $file"

    # do split 
    shnsplit -f "$cue" -t '%n.%t' -o flac -O always "$file" || {
        # some cue may split failed 
        cuebreakpoints "$cue" | sed 's/$/0/g' | shnsplit -t '%n' -o flac -O always "$file" 
    }

    # remove pregap
    rm -fv 00.pregap.flac || true

    list=($(find . -name "*.flac" | grep -v "$file"))
    # add tags (ignore errors)
    cuetag.sh "$cue" "${list[@]}" || true
    # remove cue and its data file
    #rm "$cue" "$file" &&
    # 我们要合并多个CD，track/TRACKTOTAL会导致显示顺序错误 => 按文件名排序
    metaflac --preserve-modtime                        \
        --remove-tag=track                             \
        --remove-tag=TRACKNUMBER                       \
        --remove-tag=TRACKTOTAL                        \
        "${list[@]}" || true
    #    #--remove-tag=TITLE                           \

    # back to place
    cd -
done
