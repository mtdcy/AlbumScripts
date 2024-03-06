#!/bin/bash
#
# Supported input file name:
#  * title.flac 
#  * index - title.flac
#  * index - title - artist.flac
#  * index - title - artist1&artist2.flac
#  * index - artist - title.flac            # need ARTIST_TITLE=1
#  * 
#  * index.title.flac
#  * index.title(artist1&artist2).flac
#
# Output file name syntax:
#  * index.title(artist1&artist2).flac

set -e
umask 022

LIBROOT=$(dirname "$0")
. "$LIBROOT"/lib.sh

usage() {
    cat << EOF
    $(basename "$0") files ...
EOF
}

[ $# -eq 0 ] && usage && exit 1

RUN=${RUN:-0}

index="01"
for file in "$@"; do
    # ignore cue files
    [ -e "${file%.*}.cue" ] && continue

    # title & artists
    IFS='/' read -r title artists <<< $(title_artists_get "$file")

    # build new filename
    target=$(dirname "$file")"/$(printf '%02d' $index).$title"
    # add artists: ignore if = album artist
    [ -n "$artists" ] && [ "$artists" != "$ARTIST" ] && target+="(${artists//\//\&})"
    # add extension (lowercase)
    target+=".$(echo ${file##*.} | tr A-Z a-z)"

    ind="==>"
    [ "$RUN" -ne 0 ] && ind="$(format_green "$ind")"

    format_put "... $(basename "$file")" " $ind $(basename "$target")" " << [$artists][$title]\n"
    
    # ape -> flac, better to work with ffmpeg
    case "${target,,}" in
        *.ape)
            target="${target%.*}.flac"
            codec=(-c:a flac)
            ;;
        *)
            codec=(-c:a copy)
            ;;
    esac

    # rename files
    [ "$RUN" -ne 0 ] && {
        # 2. force update artists to file
        if [ "$UPDATE_ARTIST" -ne 0 ]; then
            IFS='/' read -r year album genre <<< "$(album_get "$(realpath "$(dirname "$file")")")"

            # we prefer artist instead of performer
            ffmpeg "${FFARGS[@]}"                       \
                -i "file://$(realpath "$file")"         \
                -map 0                                  \
                -map_metadata 0                         \
                -metadata album_artist="$ARTIST"        \
                -metadata album="$album"                \
                -metadata title="$title"                \
                -metadata artist="${artists//&/\/}"     \
                -metadata date="$year"                  \
                -metadata genre="$genre"                \
                -metadata performer=""                  \
                -c copy                                 \
                "${codec[@]}"                           \
                "/tmp/$$.${target##*.}" &&
            rm "$file" &&
            mv "/tmp/$$.${target##*.}" "$target"
            # not writing album
        elif [ ! -e "$target" ]; then
            mv "$file" "$target"
        fi
    }

    index=$(("$index" + 1))
done
