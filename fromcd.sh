#!/bin/bash

# Copyright 2021 Nathan005
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the BSD 2-Clause License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
#
# This Script requires ffmpeg and
# This script is designed to make it easier to convert m4a files from an AudioBook
#  These should be imported from a cd that you own a single folder with all the audio files
#  The files should be in a single folder in order, named by disk-track numbers
#  This is the default behavior when importing with iTunes
#
#  ex: 01-01 Intro.m4a, 01-02 Chapter 1 - Title
#
#################################################################################
#
# Should you want the file to include proper chapter markers
#  it is important when importing the files to make sure the Metadata is correct
#  Every file (from each CD) should have the same album and artist info
#  Each track should be named how you would the title of the chapter to appear
#  If a chapter is broken into multiple files - Make sure they are named the same
#  except for each subsequent track add a character after the chapter number
#
#  ex: Chapter 01 - The Beginning, Chapter 01b - The Beginning
#        The script will make the above 2 files 1 chapter with the title: Chapter 01 - The Beginning
#
#  The script will automearge these tracks
#   only if the metadata title is the same, besides the trailing character
#   I would reccomend https://metaz.io if you need to edit metadata directly
#
#################################################################################
#
# There are 6 functions, one for each step of the process
# 1) get_metadata
#     produces a metadata.txt with the basic info from a file
#     requires a file argument to work ### ex: get_metadata file.m4a
#
# 2) remove_bad_names
#     renames all m4a files in the folder its called
#     the rename removes spaces, commas, apostrophes, and adds leading zeros to single digits
#     This function also calls get_metadata on the first file it finds
#
# 3) add_chapter_metadata
#     Adds Chapter info to the metadata file from the individual files Metadata
#     See the note above about chapters spanning multiple tracks
#
#  #NOTE: if you wish to check the metadata, do so now - you can directly edit the txt file if you would like
#
# 4) join_all_m4a
#     Takes all the m4a files an m4b file using the metadata from the above commands
#
# 5) create_directory
#     Uses the artist and album info to create folders and places the file in them
#     $artist/$album/$file
#
# 6) join_cd
#     runs the first 4 commands in order (doesn't create directories)
#
# 7) join_cd_dir
#     runs the first 5 commands in order
#
# 8) join_cd_menu
#     uses bash select to present the 5 commands, so you can run them by entering numbers sequentially
#
#################################################################################

#######################################
# Check for ffmpeg
#######################################
if [ ! -x /usr/local/bin/ffmpeg ] ; then
    # fallback check using posix compliant `command` in case not installed in expected location
    command -v wget >/dev/null 2>&1 || { echo >&2 "Please install ffmpeg. Aborting."; exit 1; }
fi


#######################################
# Creates metadata.txt with the metadata from a file
# It removes track specific and iTunes specific metadata
# GLOBALS:
#   meta
# ARGUMENTS:
#   the m4a file to be processed
# OUTPUTS:
#   Write FFMETADATA.txt to the working directory
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
get_metadata () {
    meta="FFMETADATA.txt";
    ffmpeg -i "$1" -f ffmetadata $meta;

    if [ -z "$album" ];
        then album=$(ffprobe -v quiet -show_entries format_tags=album -of default=nk=1:nw=1 $1);
    fi

    sed -i '' 's/^title.*/title='"$album"'/' $meta

    sed -i '' 's/^iTunes_CDDB.*//' $meta
    sed -i '' 's/^iTunes_CDDB.*//' $meta
    sed -i '' 's/^track.*/track=0/' $meta
    sed -i '' 's/^disk.*//' $meta
    sed -i '' 's/^compilation.*//' $meta
    sed -i '' 's/^gapless_playback.*//' $meta
    sed -i '' 's/^compilation.*//' $meta
    sed -i '' 's/^iTunSMPB.*//' $meta
    sed -i '' 's/^Encoding\ Params.*//' $meta

    sed -i '' '/^[[:space:]]*$/d' $meta
}

#######################################
# renames m4a files in the working directory
# It removes commas, apostrophes,
#  replaces spaces with underscores,
#  adds leading zeros to single digit numbers
#
# Calls the "get_metadata" function
#
# GLOBALS:
#   i, album, artist
# ARGUMENTS:
#   *.m4a files in the working directory
# OUTPUTS:
#   Renames all .m4a files in the working directory
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
remove_bad_names () {
    i=1;
    album="";
    artist="";

    for f in *.m4a; do
        space=${f// /_}
        fix=${space//[,\']}
        zero=$(sed -E 's|(^[1-9]-)(.*)$|0\1\2|'<<< "$fix")
        mv "$f" "$zero"

        if [[ $i = 1 ]]; then
          album=$(ffprobe -v quiet -show_entries format_tags=album -of default=nk=1:nw=1 $zero);
          echo $album;
          artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=nk=1:nw=1 $zero);
          get_metadata $zero;
        fi

        ((i++));
    done
}

#######################################
# adds chapter metadata to the FFMETADATA.txt
#
# Should only be called after the "get_metadata" or "remove_bad_names" functions
#
# GLOBALS:
#   duration, start_time, pre_title
# ARGUMENTS:
#   *.m4a files in the working directory that include metadata
# OUTPUTS:
#   Writes Chapter metadata to FFMETADATA.txt
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
add_chapter_metadata () {
    duration=0;
    start_time=0;
    pre_title="";

    if [ -z "$meta" ];
        then meta="FFMETADATA.txt";
    fi

    for f in *.m4a; do
        time_base=$(ffprobe -v quiet -show_entries stream=time_base -of default=nk=1:nw=1 $f);
        ch_duration=$(ffprobe -v quiet -show_entries stream=duration_ts -of default=nk=1:nw=1 $f);
        ch_start_time=$(ffprobe -v quiet -show_entries stream=start_time -of default=nk=1:nw=1 $f);
        title=$(ffprobe -v quiet -show_entries format_tags=title -of default=nk=1:nw=1 $f);

        title=$(sed -E 's|^[cC]hapter (.*)$|\1|' <<< "$title")
        title=$(sed -E 's|^[cC]h (.*)$|\1|' <<< "$title")
        title=$(sed -E 's|([0-9]{1,2})[a-zA-Z](.*)$|\1\2|' <<< "$title")
        title=$(sed -E 's|0([1-9])(.*)$|\1\2|' <<< "$title")
        title=$(sed -E 's|([0-9]{1,2}): (.*)$|\1. \2|' <<< "$title")
        title=$(sed -E 's|([0-9]{1,2})[ ][-][ ](.*)$|\1. \2|' <<< "$title")
        title=$(sed -E 's|([0-9]{1,2})[ ](.*)$|\1. \2|' <<< "$title")

        duration=$(echo "$duration + $ch_duration"  | bc);

        t=$(echo "$title" | awk '{print tolower($0)}');
        if [[ ${pre_title} == ${t} ]]; then

            sed -i '' '$d' $meta;
            sed -i '' '$d' $meta;
            echo -e "END=$duration \ntitle=$title" >> $meta;

        else
            echo -e "[CHAPTER] \nTIMEBASE=$time_base \nSTART=$start_time \nEND=$duration \ntitle=$title" >> $meta;
        fi

        pre_title=${t};
        start_time=$(echo "$start_time + $ch_duration"  | bc);

    done
}

#######################################
# joins all .m4a's in the working directory
# adds the chapter metadata to the joined file
#
# Should only be called after the "get_metadata" or "remove_bad_names" functions
# If you desire chapters, should be called after add_chapter_metadata
#
# GLOBALS:
#   fn, joined, output, meta, album
# ARGUMENTS:
#   *.m4a files in the working directory
#   expects FFMETADATA.txt in the working directlry
# OUTPUTS:
#   Writes an .m4a file (by combining all .m4a files in the working directory)
#   Writes an .m4b file (add metadata to above .m4a with the FFMETADATA.txt)
#   Removes the .m4a file created in step 1
#   *files are named by the metadata "album" with spaces removed
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
join_all_m4a () {

    if [ -z "$meta" ];
        then meta="FFMETADATA.txt";
    fi

    if [ -z "$album" ];then
        i=1
        for f in *.m4a; do
            album=$(ffprobe -v quiet -show_entries format_tags=album -of default=nk=1:nw=1 $f);
            break;
        done
    fi

    fn=${album// /}
    joined="${fn}.m4a"
    output="${fn}.m4b"
    ls *.m4a | awk -F':' '{ print "file "$1 }' | ffmpeg -f concat -safe 0 -protocol_whitelist "file,http,https,tcp,tls,pipe" -i - -c copy $joined
    ffmpeg -i $joined -i $meta -map_metadata 1 -codec copy $output;
    rm $joined;
}

#######################################
# Makes directories from a .m4b file in the pattern $artist/$album/$file
# uses metadata found in the file to create
#
# GLOBALS:
#   None
# ARGUMENTS:
#   *.m4b files in the working directory
# OUTPUTS:
#   Makes directories $artist
#   Makes directories $artist/$album
#   Moves .m4b file into the directory
#   Moves .jpg file (if same name as .m4b) into the directory
#   Writes and error.log file with a list of files with no metadata
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
create_directory () {
    for f in *.m4b; do
        artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=nk=1:nw=1 $f);
        album=$(ffprobe -v quiet -show_entries format_tags=album -of default=nk=1:nw=1 $f);

        if [ -z "$artist" ] && [ -z "$album" ];
            then echo "no metadata for $f" >> error.log;
            else d="$artist/$album"
            if [ ! -d "$artist" ]; then
                mkdir -p "$artist";
                mkdir -p "$d";
            elif [ ! -d "$d" ]; then
                mkdir -p "$d";
            fi
            mv "$f"  "$d/${f}"
            if test -f "${f%.*}.jpg"; then
                mv "${f%.*}.jpg" "$d/${f%.*}.jpg"
            fi
        fi
    done
}

#######################################
# joins all .m4a's in the working directory
# creates a chapterized .m4b file
#
# GLOBALS:
#   See other functions
# ARGUMENTS:
#   *.m4a files in the working directory
# OUTPUTS:
#   Writes an .m4b file (by combining all .m4a files in the working directory)
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
join_cd () {
    remove_bad_names;
    add_chapter_metadata;
    join_all_m4a;
}

#######################################
# joins all .m4a's in the working directory
# creates a chapterized .m4b file
# places file in directory $artist/$album/$file
#
# GLOBALS:
#   See other functions
# ARGUMENTS:
#   *.m4a files in the working directory
# OUTPUTS:
#   Writes an .m4b file (by combining all .m4a files in the working directory)
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
join_cd_dir () {
    remove_bad_names;
    add_chapter_metadata;
    join_all_m4a;
    create_directory;
}

#######################################
# Uses Select to run all the functions above from promt
# joins all .m4a's in the working directory
# creates a chapterized .m4b file
# can place file in directory $artist/$album/$file
#
# GLOBALS:
#   See other functions
# ARGUMENTS:
#   *.m4a files in the working directory
# OUTPUTS:
#   Writes an .m4b file (by combining all .m4a files in the working directory)
# RETURN:
#   0 if write succeeds, non-zero on error.
#######################################
join_cd_menu () {
    select opt in 'Create metadata file' 'Join *.m4a and exisiting FFMETADATA.txt' 'Create metadata and m4b' 'Create m4b and put in dir' 'Create Directories for *.m4b' quit; do
    PS3="What would you like to do: "
      case $opt in
        'Create metadata file')
          remove_bad_names
          add_chapter_metadata;;
        'Join *.m4a and exisiting FFMETADATA.txt')
          join_all_m4a;;
        'Create metadata and m4b')
          join_cd ;;
        'Create m4b and put in dir')
          join_cd_dir ;;
        'Create Directories for *.m4b')
          create_directory;;
        quit)
          break;;
        *)
          echo "Invalid option $REPLY";;
      esac
    done
}

join_cd_menu
