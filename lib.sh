#!/bin/bash

# ENVs:
#  ARTIST           => album artist
#  TITLE_ARTIST     => artist in filename after title
#  ARTIST_TITLE     => reverse order
#  UPDATE_ARTIST    => update broken artist|title in file
#  NJOBS=n          => max background transcoding processes.

LC_ALL=C.UTF-8

ARTIST="${ARTIST:-}"
TITLE_ARTIST=${TITLE_ARTIST:-0}
ARTIST_TITLE=${ARTIST_TITLE:-0}
UPDATE_ARTIST=${UPDATE_ARTIST:-0}

# internal variables
IFS=$'\n'
NJOBS=${NJOBS:-$(nproc)}
FFARGS=(-hide_banner -loglevel error)

# album_get path/to/album 
album_get() {
    local album
    # remove leading numbers & special chars
    album=$(basename "$1" | sed -e 's/^[0-9.\ \-]*//')

    echo "$album"
}

title_artist_get() {
    #1. force artist
    local artist="$ARTIST"
    local title=$(basename "$1")
    # remove extension 
    title=${title%.*}
    # remove leading special chars
    title=$(echo "$title" | sed -e 's/^[0-9\.\ \-]*//')

    #2. read artist from filename
    if [ -z "$artist" ] || [[ "$title" =~ "$artist" ]]; then
        # title - artist
        IFS='-' read -r a b <<< "$title"
        if [ ! -z "$b" ]; then
            [ "$ARTIST_TITLE" -ne 0 ] && {
                title="$b" && artist="$a"
            } || {
                title="$a" && artist="$b"
            }
        else
            # chinese '（）'
            IFS='()（）' read -r title artist <<< "$title"
        fi
    fi
    
    #3. read artist from file
    [ -z "$artist" ] && {
        IFS='=' read _ artist <<< $(ffprobe "${FFARGS[@]}" -show_entries format_tags "$1" | grep -i artist -w)
    }

    # remove spaces
    title=${title/# /}
    title=${title/% /}

    # replace special chars
    title="${title//[()\-]/}"           # no '()-' in title, spaces are allowed(English title)
    artist="${artist//[,_\/\ \-]/\&}"   # concat artists with '&', spaces are allowed(person name)

    # use '-' as seperator on output
    echo "$title-$artist"
}
