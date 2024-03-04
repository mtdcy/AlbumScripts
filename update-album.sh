#!/bin/bash

set -e

LIBROOT=$(dirname "$0")
. "$LIBROOT"/lib.sh

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

echo ">>> $1 ==> $2"

# prepare target dir
DEST="$2" && mkdir -pv "$DEST"

# remove obsolute(s)
for file in "$2"/*; do
    find "$1" -name "$(basename "${file%.*}").*" || {
        echo "remove outdated file $file"
        [ "$RUN" -ne 0 ] && rm -fv "$file"
    }
done

# list files into an array
LIST=($(find "$1" -maxdepth 1 -type f | sed '1d'))

njobs=0
for file in "${LIST[@]}"; do
    # target path
    target="$DEST/"$(basename "$file")
   
    case "${file,,}" in
        *.wma|*.flac|*.wav|*.mp3|*.m4a|*.ape)
            # ignore cue files
            [ -e "${file%.*}.cue" ] && echo -e "... $file ==> ignored" && continue;

            # use target dir as album
            IFS='-' read -r year album genre <<< $(album_get "$2")

            # get title & artist
            IFS='-' read -r title artist <<< $(title_artist_get "$file")

            # album artist
            [ -z "$ARTIST" ] && IFS='&' read -r album_artist _ <<< "$artist" || album_artist="$ARTIST"

            echo -e "\t==> ARTIST: [$artist], ALBUM: [$album], TITLE: [$title], YEAR: [$year], GENRE: [$genre]"

            # replace extension
            #case "${target,,}" in
            #    *.mp3)
            #        # mp3 is a common file type, no need to convert to m4a
            #        ;;
            #    *)
            #        ;;
            #esac
            target="${target%.*}.m4a"
            echo -e "#$(printf '%02d' $njobs) $file ==> $target"

            if [ "$FORCE" -ne 0 ] || [ "$file" -nt "$target" ]; then
                [ "$RUN" -ne 0 ] && {
                    # using temp file to avoid write partial files
                    ffmpeg "${FFARGS[@]}"                      \
                        -i "file://$(realpath "$file")"        \
                        -map 0                                 \
                        -map_metadata 0                        \
                        -metadata artist="${artist//&/\/}"     \
                        -metadata album_artist="$album_artist" \
                        -metadata album="$album"               \
                        -metadata title="$title"               \
                        -metadata date="$year"                 \
                        -metadata genre="$genre"               \
                        -c copy                                \
                        -c:a libfdk_aac                        \
                        -b:a 320k                              \
                        "/tmp/$$-$njobs.m4a" &&
                    mv "/tmp/$$-$njobs.m4a" "$target" &

                    njobs=$(("$njobs" + 1))
                    [ $(("$njobs" % "$NJOBS")) -eq 0 ] && {
                        echo -e "#$(printf '%02d' "$njobs") too much background jobs ..."
                        wait
                    }
                }
            fi
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
echo -e "<<< wait for background jobs ...\n"
wait
