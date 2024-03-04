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
    local album=$(basename "$1")
    local year
    local genre

    # support album format:
    #  1. date - album 
    #  2. year.album

    IFS='-' read -r a b <<< "$album"
    [ -z "$b" ] && {
        # year only
        IFS='.' read -r a b <<< "$album"
    }
    [ -n "$b" ] && {
        album="$b"
        year="${a%%.*}"
    }

    # genre: 
    #  => don't remove genre from album name
    local c="$album"
    while [ -n "$c" ]; do
        IFS='()（）' read -r _ genre c <<< "$c"
    done

    # remove spaces
    year="${year// /}"
    album=${album/# /}
    album=${album/% /}
    genre=${genre/# /}
    genre=${genre/% /}

    echo "$year-$album-$genre"
}

title_artist_get() {
    local artists
    local title=$(basename "$1")
    # remove extension 
    title=${title%.*}
    # remove leading special chars
    title=$(sed -e 's/^[0-9\.\_\ \-]*//'    \
                -e 's/（/(/g'               \
                -e 's/）/)/g'               \
                <<< "$title")
    # exceptions
    title=$(sed -f "$LIBROOT"/title.sed <<< "$title")

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
            IFS='()' read -r _ artists c <<< "$c"

            # exceptions
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
        [ -z "$artists" ] && IFS='=' read -r _ artists <<< $(grep -i 'artist' -w <<< "$tags")
        [ -z "$title" ]   && IFS='=' read -r _ title   <<< $(grep -i 'title' -w <<< "$tags")
        local tags=$(ffprobe "${FFARGS[@]}" -show_entries format_tags "file://$(realpath "$1")")
    }

    # concat artists with '&', spaces are allowed(person name)
    #  => correct format: artist1/artist2/...
    #artists="${artists//[,_\/\ \-]/\&}"    # use this line to correct malformed artists
    artists="${artists//[,_\/\-，、]/\&}"

    # map 
    artists=$(sed -f "$LIBROOT"/artist.sed <<< "$artists")

    #3. prepend album artist
    [ -n "$ARTIST" ] && {
        ARTIST=$(sed -f "$LIBROOT"/artist.sed <<< "$ARTIST")

        [[ "$artists" =~ "$ARTIST" ]] || {
            [ -z "$artists" ] && artists="$ARTIST" || artists="$ARTIST&$artists"
        }
    }
    
    # uniq => array
    IFS='&' read -r -a artists <<< "$(echo "${artists}" | tr '&' '\n' | sort -u -f | tr '\n' '&')"

    # remove spaces
    title=${title/# /}
    title=${title/% /}

    # replace special chars
    # no '.-' in title, spaces are allowed(English title)
    title="${title//[\.]}"
    title="${title//[\-]/,}"

    # use '-' as seperator on output
    echo "$title-$(IFS='&' echo "${artists[*]}")"
}
