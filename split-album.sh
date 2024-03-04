#!/bin/bash
#
# requires: brew install cuetools shntool flac
#

# Usage: $0 path/to/cue 

set -e
LC_ALL=C.UTF-8
IFS=$'\n'

LOC="$(cd $(dirname $0) && pwd && cd -)"

cue="$1"

[[ "$cue" =~ .*.cue ]] || {
    cue=$(find "$cue"/*.cue -type f | head -n1)
}

[ ! -e "$cue" ] && echo "cue $cue not exists" && exit 1

# change encodings
vim +"set fileencoding=utf-8 | wq" "$cue"

# enter source dir
cd $(dirname "$cue") && cue=$(basename "$cue")

for ext in wav flac ape; do
    file="${cue/%cue/$ext}"

    [ -e "$file" ] || continue

    echo "split ""$file"

    # do split 
    shnsplit -f "$cue" -t '%n.%t' -o flac -O always "$file" || {
        # some cue may split failed 
        cuebreakpoints "$cue" | sed 's/$/0/g' | shnsplit -t '%n' -o flac -O always "$file" 
    }
    [ $? -ne 0 ] && exit $?

    # remove pregap
    rm -fv 00.pregap.flac || true
    # add tags
    cuetag.sh "$cue" $(find *.flac | grep -v "${cue/%cue/flac}")
    # remove cue and its data file
    #rm "$cue" "$file" &&
    # 我们要合并多个CD，track/TRACKTOTAL会导致显示顺序错误 => 按文件名排序
    metaflac --preserve-modtime     \
        --remove-tag=track          \
        --remove-tag=TRACKNUMBER    \
        --remove-tag=TRACKTOTAL     \
        $(find . -name "*.flac" | grep -v "$file")
    #    #--remove-tag=TITLE       \
    exit
done

cd -
