#!/bin/bash

set -e

if [ $# -eq 0 ] ; then
    TIMER_MIN=20
else
    TIMER_MIN=$1
fi

if [ -d ~/Music/ ] ; then
    MUSIC_DIR=~/Music/
else
    MUSIC_DIR=$HOME
fi

MUSIC_FORMATS="mp3"
FILE_FILTERS=""
for format in $MUSIC_FORMATS; do
    FILE_FILTERS+="--file-filter=*.$format "
done

if [ ! -e ~/.alarm_sound ] ; then
    cd $MUSIC_DIR
    zenity --info --text="No alarm music set, please choose a music file to play" --no-wrap
    while true; do
        alarm_file=$(zenity --file-selection $FILE_FILTERS)
        if [ -z "$alarm_file" ]; then
            exit 1;
        fi
        mpv "$alarm_file" &
        MUSIC_PLAYER_PID=$!
        set +e
        zenity --question --text="Do you really want to use this music as an alarm ?" --no-wrap
        ANSWER=$?
        set -e
        kill $MUSIC_PLAYER_PID
        if [ $ANSWER -eq 0 ]; then
            ln -s "$alarm_file" ~/.alarm_sound
            break
        fi
    done
fi

function start_pomodoro() {
    echo "Starting a $1 mins timer"
    sleep $1m
    mpv ~/.alarm_sound &
    MUSIC_PLAYER_PID=$!
    zenity --info --text="The pomodoro timer has finished !" --no-wrap
    kill $!
}

start_pomodoro $TIMER_MIN
