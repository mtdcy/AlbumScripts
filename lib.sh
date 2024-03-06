#!/bin/bash

# ENVs:
#  ARTIST           => album artist
#  ARTIST_TITLE     => reverse order
#  UPDATE_ARTIST    => update broken artist|title in file
#  NJOBS=n          => max background transcoding processes.

LC_ALL=C.UTF-8

ARTIST="${ARTIST:-}"
ARTIST_TITLE=${ARTIST_TITLE:-0}
UPDATE_ARTIST=${UPDATE_ARTIST:-0}
TITLE_ONLY=${TITLE_ONLY:-0}         # handling malformated title with '()'

# internal variables
IFS=$'\n'
NJOBS=${NJOBS:-$(nproc)}
FFARGS=(
    -hide_banner 
    -loglevel error
)

FORMAT=(
    -c:a libfdk_aac
    -b:a 320k
    )

# fixed message width
WIDTH=48

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

    [[ "$a" =~ ^[0-9]{4} ]] && [ -n "$b" ] && {
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
    album="${album/# /}"
    album="${album/% /}"
    #album="${album//[\.\-]/ }" # no '.-' in album
    genre="${genre/# /}"
    genre="${genre/% /}"

    echo "$year/$album/$genre"
}

# title_artists_get /path/to/file
title_artists_get() {
    local title artists private
    # regex filter
    title=$(sed -f "$LIBROOT"/title.sed <<< "$(basename "${1%.*}")")

    # private.sed
    private="$(dirname "$1")/private.sed"
    [ -r "$private" ] || private="$(dirname "$1")/../private.sed"
    [ -r "$private" ] && title="$(sed -f "$private" <<< "$title")"

    #1. read artists from filename
    if [ "$TITLE_ONLY" -eq 0 ]; then 
        # 歌曲名 - 歌手1&歌手2.flac
        local c="$title"
        while [ -n "$c" ]; do 
            IFS='-' read -r a b c <<< "$c"
        done

        if [ -n "$b" ]; then
            [ "$ARTIST_TITLE" -ne 0 ] && {
                title="$b" && artists="$a"
            } || {
                title="$a" && artists="$b"
            }
        else
            # 歌曲名(歌手名1&歌手名2).flac
            # exception: 01.(系列/备注/...)歌曲名(歌手名1&歌手名2).flac
            c="$title"
            while [ -n "$c" ]; do
                IFS='()' read -r title artists c <<< "$c"
            done
        fi
    else
        title=$(sed 's/\ *(/『/g;s/)\ */』/g;s/\ *-\ */, /g' <<< "$title")
    fi
    
    #2. read artists from file
    [ "$UPDATE_ARTIST" -eq 0 ] && {
        local tags=$(ffprobe "${FFARGS[@]}" -show_entries format_tags "file://$(realpath "$1")")
        [ -z "$artists" ] && IFS='=' read -r _ artists <<< $(grep -Fi 'artist' -w <<< "$tags")
        [ -z "$title" ]   && IFS='=' read -r _ title   <<< $(grep -Fi 'title' -w <<< "$tags")
    }

    #3. use album artist
    [ -n "$ARTIST" ] && [ -z "$artists" ] && {
        artists="$ARTIST"
    }

    # map 
    artists="$(sed -f "$LIBROOT"/artist.sed <<< "$artists")"

    # finally: replace '-' with ' ', no '-' in title
    title="${title//-/ /}"

    # remove leading & trailing spaces
    title="${title% }"
    title="${title# }"
    artists="${artists% }"
    artists="${artists# }"
 
    # use '/' as seperator on output
    echo "$title/$artists"
}

# tags_get /path/to/file
tags_get() {
    echo "$(album_get "$(dirname "$1")")/$(title_artists_get "$1")"
}

# tags_read /path/to/file 
# output: artist-album-title-year-genre
tags_read() {
    local artists album title year genre tags
    tags="$(ffprobe "${FFARGS[@]}" -show_entries format_tags "file://$(realpath "$1")")"
    IFS='=' read -r _ artists <<< "$(grep -Fi 'artist' -w <<< "$tags")"
    IFS='=' read -r _ album   <<< "$(grep -Fi 'album'  -w <<< "$tags")"
    IFS='=' read -r _ title   <<< "$(grep -Fi 'title'  -w <<< "$tags")"
    IFS='=' read -r _ year    <<< "$(grep -Fi 'date'   -w <<< "$tags")"
    IFS='=' read -r _ genre   <<< "$(grep -Fi 'genre'  -w <<< "$tags")"

    artists="${artists//\//\&}"
    echo "$year/$album/$genre/$title/$artists"
}

format_red() {
    echo -ne "$(tput setaf 1)$*$(tput sgr0)"
}

format_green() {
    echo -ne "$(tput setaf 2)$*$(tput sgr0)"
}

format_yellow() {
    echo -ne "$(tput setaf 3)$*$(tput sgr0)"
}

# format_put width "string"
format_put() {
    if which tput &> /dev/null; then
        local i=0
        while [ $# -gt 0 ]; do
            tput hpa "$((WIDTH * i))"
            echo -ne "$1"; shift
            i=$((i + 1))
        done
    else
        echo -ne "$@"
    fi
}
