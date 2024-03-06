#!/bin/bash
#
# requires: brew install cuetools shntool flac
#

# Usage: $0 path/to/cue 

set -e
umask 022

LIBROOT=$(dirname "$0")
. "$LIBROOT"/lib.sh

CUE="$1"

[ -d "$CUE" ] && {
    CUE=($(find "$CUE" -iname "*.cue" -type f))
}

for cue in "${CUE[@]}"; do
    [ -e "$(dirname "$cue")/ignore" ] && continue 

    format_string "=== $cue" " ==> split\n"
    # change encodings
    vim +"set fileencoding=utf-8 ff=unix | wq" "$cue" || true

    # enter source dir
    cd "$(dirname "$cue")" && cue="$(basename "$cue")"

    find . -name "*.flac" ! -iname "${cue%.*}.flac" -exec rm -f {} \; || true

    # find data file
    for ext in wav flac ape; do
        [ -e "${cue%.*}.$ext" ] && file="${cue%.*}.$ext"
    done

    [ -z "$file" ] && format_string "--- $cue" " ==> missing data file\n" && cd - && continue;

    # do split 
    #  => shnsplit translate '/' to '-' by default, but we use '-' as IFS
    shnsplit -f "$cue" -t '%n.%t' -o flac -O always -m '/ ' "$file" || {
        # some cue may split failed 
        cuebreakpoints "$cue" | sed 's/$/0/g' | shnsplit -t '%n' -o flac -O always "$file" 
    }

    # remove pregap
    rm -fv 00.pregap.flac || true

    list=($(find . -name "*.flac" | grep -Fv "$file"))
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

if [ -d "$1/CD1" ]; then
    RUN=1 "$(dirname "$0")"/update-index.sh "$1/CD"*/*.flac
    for flac in "$1/CD"*/*.flac; do
        [ -e "${flac%.*}.cue" ] && continue
        mv "$flac" "$1"
    done
fi
