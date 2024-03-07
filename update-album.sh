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
format_put ">>> 专辑 '$(basename $(realpath "$1"))'"  " ==> $DEST\n" 

if [ -e "$DEST" ]; then
    # remove outdated
    for file in "$DEST"/*; do
        name="$(basename "$file")"
        ls "$1/${name%.*}."* &> /dev/null || {
            format_put "... $name" " ==> $(format_yellow "outdated\n")"
            [ "$RUN" -ne 0 ] && rm -rf "$file"
        }
    done
else
    mkdir -p "$DEST"
fi

# use target dir as album
IFS='/' read -r year album genre <<< "$(album_get "$2")"

njobs=0
for file in "$1"/*; do
    # ignore dirs
    [ -d "$file" ] && continue

    # target path
    name="$(basename "$file")" 
    target="$DEST/$name"

    ind="==>"
    [ "$RUN" -ne 0 ] && ind="$(format_green "$ind")"
   
    case "${file,,}" in
        *.wma|*.flac|*.wav|*.mp3|*.m4a|*.ape|*.ogg)
            # ignore cue files
            [ -e "${file%.*}.cue" ] && {
                #format_put "... $file ignored\n"
                continue
            }

            target="${target%.*}.$FORMAT"

            # skip modify time check, do deep check with tags
            #[ -e "$target" ] && [ "$target" -nt "$file" ] && continue

            # get title & artists
            IFS='/' read -r title artists <<< "$(title_artists_get "$file")"

            # album artist
            [ -n "$ARTIST" ] && album_artist="$ARTIST" || IFS='&' read -r album_artist _ <<< "$artists"

            # update ?
            update="${FORCE:-0}"
            [ ! -f "$target" ] && update=1

            # compare tags
            [ "$update" -eq 0 ] && [ "$year/$album/$genre/$title/$artists" != "$(tags_read "$target")" ] && update=1

            [ "$update" -ne 0 ] && {
                format_put                                          \
                    "$(printf '#%02d' "$njobs") $name"              \
                    " $ind $(basename "$target")"  \
                    " << [$year][$album][$genre][$artists][$title]\n"

                #echo -e "#$(printf '%02d' $njobs) '$file' ==> '$target'"
                # using temp file to avoid write partial files
                [ "$RUN" -ne 0 ] && {
                    eval ffmpeg "${FFARGS[@]}"                      \
                        -i "file://$(realpath "$file")"             \
                        -map 0                                      \
                        -map_metadata 0                             \
                        -metadata artist="${artists//&/\/}"         \
                        -metadata album_artist="$album_artist"      \
                        -metadata album="$album"                    \
                        -metadata title="$title"                    \
                        -metadata date="$year"                      \
                        -metadata genre="$genre"                    \
                        -c copy                                     \
                        "$CODEC"                                    \
                        "/tmp/$$-$njobs.$FORMAT" &&
                    mv "/tmp/$$-$njobs.$FORMAT" "$target" &

                    njobs=$(("$njobs" + 1))
                    [ $(("$njobs" % "$NJOBS")) -eq 0 ] && {
                        format_put                                  \
                            "#$(printf '%02d' "$njobs") 转码"       \
                            "$(format_green " ==> wait for background jobs ...\n")"
                        wait
                    }
                }
            }
            ;;
        *.jpg|*.jpeg|*.webp|*.png)
            if [ ! -e "$target" ] || [ "$file" -nt "$target" ]; then
                format_put "--- $name" " $ind $target\n"
                [ "$RUN" -ne 0 ] && cp "$file" "$target"
            fi
            ;;
        *)
            #format_put "--- $file" " ==> ignored\n" \
            ;;
    esac 
done

# wait for background jobs
[ "$njobs" -gt 0 ] && \
format_put \
    "<<< 转码" \
    "$(format_green " ==> wait for background jobs ...\n")" &&
    echo ""
wait || true
