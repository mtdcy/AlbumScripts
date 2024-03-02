#!/bin/bash

set -e

. $(dirname "$0")/lib.sh

usage() {
    cat << EOF
    $(basename "$0") /path/to/album /path/to/destination

    Environments:

    RUN=1           - run real command, default: 0
    FORCE=1         - force update existing files.

    Notes:

    - 始终从文件名获取'TITLE'
    - 始终从目标文件夹获取'ALBUM'
    - 如果'ARTIST'为空，将从原文件中获取.
EOF
}

RUN=${RUN:-0}
FORCE=${FORCE:-0}

[ $# -lt 2 ] && usage && exit 1

# list files into an array
LIST=($(find "$1" -type f | sort -n))

# prepare target dir
DEST="$2" && mkdir -pv "$DEST"

njobs=0
for file in "${LIST[@]}"; do
    # target path
    target="$DEST/"$(basename "$file")
   
    case "${file,,}" in
        *.wma|*.flac|*.wav)
            # ignore cue files
            [ -e "${file%.*}.cue" ] && echo -e "$file ==> ignored" && continue;
            
            IFS='-' read -r title artist <<< $(title_artist_get "$file")

            # use target dir as album
            album=$(album_get "$2")

            # replace extension
            target="${target%.*}.m4a"
            echo -ne "$(printf '%02d' $njobs): $file ==> $target"
           
            [ $RUN -ne 0 ] && {
                # remove existing one
                [ $FORCE -ne 0 ] && rm -f "$target" || true

                [ ! -e "$target" ] && {
                    echo -e " << ARTIST: [$artist], ALBUM: [$album], TITLE: [$title]"

                    # replace seperator char
                    artist="${artist//&/\/}"

                    # album artist
                    [ -z "$ARTIST" ] && IFS='&' read album_artist _ <<< "$artist" || album_artist="$ARTIST"
                    
                    # using temp file to avoid write partial files
                    ffmpeg "${FFARGS[@]}"                      \
                        -i "$file"                             \
                        -metadata artist="$artist"             \
                        -metadata album_artist="$album_artist" \
                        -metadata album="$album"               \
                        -metadata title="$title"               \
                        -c:a libfdk_aac                        \
                        -b:a 320k                              \
                        "/tmp/$$-$njobs.m4a" &&
                    mv "/tmp/$$-$njobs.m4a" "$target" &

                    njobs=$(expr $njobs + 1) &&
                    [ $(expr $njobs % $NJOBS) -eq 0 ] &&
                    echo -e "$njobs: too much background jobs ..." &&
                    wait || true
                } || echo -e " >> target exists, skip"
            } || echo -e " >> testing ..."
            ;;
        *.jpg)
            echo -e "... $file ==> $target"
            [ $RUN -ne 0 ] && cp "$file" "$target"
            ;;
        *)
            echo -e "... $file ==> ignored"
            ;;
    esac 
done

# wait for background jobs
echo -e "=== wait for background jobs ...\n" && wait
