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
    local artists
    local title=$(basename "$1")
    # remove extension 
    title=${title%.*}
    # remove leading special chars
    title=$(echo "$title" | sed -e 's/^[0-9\.\ \-]*//')

    #1. read artists from filename
    # title - artists
    # 01 - 歌曲名 - 歌手名1&歌手名2.flac
    IFS='-' read -r a b <<< "$title"
    if [ ! -z "$b" ]; then
        [ "$ARTIST_TITLE" -ne 0 ] && {
            title="$b" && artists="$a"
        } || {
            title="$a" && artists="$b"
        }
    else
        # 01.歌曲名(歌手名1&歌手名2).flac
        # exception: 01.(系列/备注/...)歌曲名(歌手名1&歌手名2).flac
        # chinese '（）'
        local c="$title"
        while [ -n "$c" ]; do
            IFS='()（）' read -r _ artists c <<< "$c"
        done

        [ -n "$artists" ] && {
            title="${title%$artists*}"
            title="${title%[\(（]}"
        }

        #title=$(sed -e "s:$artists.*$::" \
        #            -e 's/[\(（]\?$//'  \
        #            <<< "$title")
    fi
    
    #2. read artists from file
    [ "$UPDATE_ARTIST" -eq 0 ] && {
        local tags=$(ffprobe "${FFARGS[@]}" -show_entries format_tags "$1")
        [ -z "$artists" ] && IFS='=' read -r _ artists <<< $(grep -i 'artist' -w <<< "$tags")
        [ -z "$title" ]   && IFS='=' read -r _ title   <<< $(grep -i 'title' -w <<< "$tags")
    }

    # concat artists with '&', spaces are allowed(person name)
    #  => correct format: artist1/artist2/...
    #artists="${artists//[,_\/\ \-]/\&}"    # use this line to correct malformed artists
    artists="${artists//[,_\/\-，、]/\&}"

    #3. prepend album artist
    [ ! -z "$ARTIST" ] && {
        [[ "$artists" =~ "$ARTIST" ]] || {
            [ -z "$artists" ] && artists="$ARTIST" || artists="$ARTIST&$artists"
        }
    }

    # remove spaces
    title=${title/# /}
    title=${title/% /}
    artists=${artists/# /}
    artists=${artists/% /}

    # replace special chars
    # no '.-' in title, spaces are allowed(English title)
    title="${title//[\.\-]/ }"

    # use '-' as seperator on output
    echo "$title-$artists"
}
