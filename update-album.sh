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

# prepare target dir
DEST="$2"

if [ -e "$DEST" ]; then
    # remove outdated
    for file in "$DEST"/*; do
        name="$(basename "$file")"
        ls "$1/${name%.*}."* &> /dev/null || {
            format_string "... $name" " ==> outdated\n"
            [ "$RUN" -ne 0 ] && rm -rf "$file"
        }
    done
else
    mkdir -p "$DEST"
fi

njobs=0
for file in "$1"/*; do
    # ignore dirs
    [ -d "$file" ] && continue

    # target path
    name="$(basename "$file")" 
    target="$DEST/$name"
   
    case "${file,,}" in
        *.wma|*.flac|*.wav|*.mp3|*.m4a|*.ape)
            # ignore cue files
            [ -e "${file%.*}.cue" ] && {
                #format_string "... $file ignored\n"
                continue
            }

            target="${target%.*}.m4a"

            # skip modify time check, do deep check with tags
            #[ -e "$target" ] && [ "$target" -nt "$file" ] && continue

            # use target dir as album
            IFS='-' read -r year album genre <<< "$(album_get "$2")"

            # get title & artist
            IFS='-' read -r title artist <<< "$(title_artist_get "$file")"

            # album artist
            [ -z "$ARTIST" ] && IFS='&' read -r album_artist _ <<< "$artist" || album_artist="$ARTIST"

            # update ?
            update="${FORCE:-0}"
            [ ! -e "$target" ] && update=1

            # compare tags
            [ "$update" -eq 0 ] && {
                # get target tags
                IFS='-' read -r a b c d e <<< "$(tags_read "$target")"
                [ "$artist" = "$a" ] &&
                [ "$album"  = "$b" ] &&
                [ "$title"  = "$c" ] &&
                [ "$year"   = "$d" ] &&
                [ "$genre"  = "$e" ] ||
                update=1
            }

            [ "$update" -ne 0 ] && {
                format_string                                       \
                    "$(printf '#%02d' "$njobs") $name"              \
                    " ==> $(basename "$target")"                    \
                    " << [$year][$album][$genre][$artist][$title]\n"

                #echo -e "#$(printf '%02d' $njobs) '$file' ==> '$target'"
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
                        format_string "#$(printf '%02d' "$njobs") too much background jobs ...\n"
                        wait
                    }
                }
            }
            ;;
        *.jpg|*.jpeg|*.webp|*.png)
            if [ ! -e "$target" ] || [ "$file" -nt "$target" ]; then
                format_string "--- $name" " ==> $target\n"
                [ "$RUN" -ne 0 ] && cp "$file" "$target"
            fi
            ;;
        *)
            #format_string "--- $file" " ==> ignored\n" \
            ;;
    esac 
done

# wait for background jobs
[ "$njobs" -gt 0 ] && format_string "<<< wait for background jobs ...\n" && wait || true
