#!/bin/bash

set -e
umask 022

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

echo -e "\n>>> $1 ==> $2"

# prepare target dir
DEST="$2" && mkdir -pv "$DEST"

# remove obsolute(s)
for file in "$2"/*; do
    find "$1" -name "$(basename "${file%.*}").*" > /dev/null || {
        echo "... remove outdated file $file"
        [ "$RUN" -ne 0 ] && rm -fv "$file"
    }
done

njobs=0
for file in "$1"/*; do
    # ignore dirs
    [ -d "$file" ] && continue

    # target path
    target="$DEST/"$(basename "$file")
   
    case "${file,,}" in
        *.wma|*.flac|*.wav|*.mp3|*.m4a|*.ape)
            # ignore cue files
            [ -e "${file%.*}.cue" ] && echo -e "... $file ==> ignored" && continue;

            # use target dir as album
            IFS='-' read -r year album genre <<< "$(album_get "$2")"

            # get title & artist
            IFS='-' read -r title artist <<< "$(title_artist_get "$file")"

            # album artist
            [ -z "$ARTIST" ] && IFS='&' read -r album_artist _ <<< "$artist" || album_artist="$ARTIST"

            echo -e "=== ARTIST: [$artist], ALBUM: [$album], TITLE: [$title], YEAR: [$year], GENRE: [$genre]"

            target="${target%.*}.m4a"

            # update ?
            UPDATE=0
            if [ "$FORCE" -ne 0 ] || [ ! -e "$target" ] || [ "$file" -nt "$target" ]; then
                UPDATE=1
            else
                # get target tags
                IFS='-' read -r a b c d e <<< "$(tags_read "$target")"
                [ "$artist" = "$a" ] &&
                [ "$album"  = "$b" ] &&
                [ "$title"  = "$c" ] &&
                [ "$year"   = "$d" ] &&
                [ "$genre"  = "$e" ] ||
                UPDATE=1
            fi

            [ "$UPDATE" -ne 0 ] && {
                echo -e "#$(printf '%02d' $njobs) '$file' ==> '$target'"
                # using temp file to avoid write partial files
                [ "$RUN" -ne 0 ] && {
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
                        "${FORMAT[@]}"                         \
                        "/tmp/$$-$njobs.m4a" &&
                    mv "/tmp/$$-$njobs.m4a" "$target" &

                    njobs=$(("$njobs" + 1))
                    [ $(("$njobs" % "$NJOBS")) -eq 0 ] && {
                        echo -e "#$(printf '%02d' "$njobs") too much background jobs ..."
                        wait
                    }
                }
            }
            ;;
        *.jpg|*.jpeg|*.webp|*.png)
            if [ ! -e "$target" ] || [ "$file" -nt "$target" ]; then
                echo -e "--- $file ==> $target"
                [ "$RUN" -ne 0 ] && cp "$file" "$target"
            fi
            ;;
        *)
            echo -e "--- $file ==> ignored"
            ;;
    esac 
done

# wait for background jobs
[ "$njobs" -gt 0 ] && echo -e "<<< wait for background jobs ..." && wait || true
