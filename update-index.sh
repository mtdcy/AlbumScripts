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
#  * index.title.flac
#  * index.title(artist1&artist2).flac      # need TITLE_ARTIST=1

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
LIST=($(find "$@" -type f | sort -n))

for file in "${LIST[@]}"; do
    # ignore cue files
    [ -e "${file%.*}.cue" ] && continue

    # title & artist
    IFS='/' read -r title artist <<< $(title_artist_get "$file")

    # build new filename
    target=$(dirname "$file")"/$(printf '%02d' $index).$title"
    # add artist
    [ "$TITLE_ARTIST" -ne 0 ] && [ -n "$artist" ] && target+="(${artist//\//\&})"
    # add extension (lowercase)
    target+=".$(echo ${file##*.} | tr A-Z a-z)"

    format_string "... $file" " ==> $(basename "$target")" " << [$artist][$title]\n"
    
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
        # 1. artist exists without append to filename 
        # 2. force update artist to file
        if [ -n "$artist" ] && [ "$TITLE_ARTIST" -eq 0 ] || [ "$UPDATE_ARTIST" -ne 0 ]; then
            ffmpeg "${FFARGS[@]}"                   \
                -i "file://$(realpath "$file")"     \
                -map 0                              \
                -map_metadata 0                     \
                -metadata ARTIST="${artist//&/\/}"  \
                -metadata TITLE="$title"            \
                -c copy                             \
                "${codec[@]}"                       \
                "/tmp/$$.${target##*.}" &&
            rm "$file" &&
            mv "/tmp/$$.${target##*.}" "$target"
            # not writing album
        elif [ "$file" != "$target" ]; then
            mv "$file" "$target"
        fi
    }

    index=$(("$index" + 1))
done
