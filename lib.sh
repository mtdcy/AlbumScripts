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
FFARGS=(
    -hide_banner 
    -loglevel error
)

FORMAT=(
    -c:a libfdk_aac
    -b:a 320k
    )

# fixed message width
WIDTH=40

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
    album=${album//[\.\-]/ }    # no '.-' in album
    genre=${genre/# /}
    genre=${genre/% /}

    echo "$year-$album-$genre"
}

# title_artist_get /path/to/file
title_artist_get() {
    local title artists private
    # regex filter
    title=$(sed -f "$LIBROOT"/title.sed <<< "$(basename "${1%.*}")")

    # private.sed
    private="$(dirname "$1")/private.sed"
    [ -r "$private" ] || private="$(dirname "$1")/../private.sed"
    [ -r "$private" ] && title="$(sed -f "$private" <<< "$title")"

    #1. read artists from filename
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
    artists=${artists% }"
    artists=${artists# }"
 
    # use '-' as seperator on output
    echo "$title-$artists"
}

# tags_read /path/to/file 
# output: artist-album-title-year-genre
tags_read() {
    local tags="$(ffprobe "${FFARGS[@]}" -show_entries format_tags "file://$(realpath "$1")")"
    local artists album title year genre
    IFS='=' read -r _ artists <<< "$(grep -Fi 'artist' -w <<< "$tags")"
    IFS='=' read -r _ album   <<< "$(grep -Fi 'album'  -w <<< "$tags")"
    IFS='=' read -r _ title   <<< "$(grep -Fi 'title'  -w <<< "$tags")"
    IFS='=' read -r _ year    <<< "$(grep -Fi 'date'   -w <<< "$tags")"
    IFS='=' read -r _ genre   <<< "$(grep -Fi 'genre'  -w <<< "$tags")"
    echo "$artists-$album-$title-$year-$genre"
}

# format_string width "string"
format_string() {
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
