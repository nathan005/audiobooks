# audiobooks
Shell Script to aid in converting files to chapterized .m4b files to simplify creation of my Plex audiobook library

I'm running OSX, this script has only been tested on my local system as it was written to work for me - I welcome input to simplify this for other systems as well.

### This Script requires ffmpeg 
[Install ffmepg OSX?](https://superuser.com/questions/624561/install-ffmpeg-on-os-x)


## Usage
> NOTE: I wrote this primarily for my personal use, so I have not tested it on other systems.

1. Place the script in 

## Converting from CD
Most of the functions are designed to make it easier to convert m4a files from an AudioBook CD
This should be imported from a cd that you own a single folder with all the audio files in order, named by disk-track numbers
This is the default behavior when importing with iTunes etc.

> ex: 01-01 Intro.m4a, 01-02 Chapter 1 - Title

### Chapterized files
If you want the file to include chapter markers, when importing the files to make sure the metadata is correct.

- Every file (from each CD) should have the same album and artist info
- Each track should be named how you would the title of the chapter to appear
- If a chapter is broken into multiple files - Make sure they are named the same, but with a trailing digit following the chapter number

> ex: Chapter 01 - The Beginning, Chapter 01b - The Beginning

_Will make the 2 files, 01... and 01b... into 1 chapter with the title: Chapter 01 - The Beginning_

* The script will merge these tracks only if the metadata title is the same, besides the trailing character
  
* I would reccomend https://metaz.io if you need to edit metadata 

##Functions
There are 6 functions, one for each step of the process
#### 1) get_metadata
produces a FFMETADATA.txt with the basic info from a file
requires a file argument to work if run solo
`ex: get_metadata file.m4a`

#### 2) remove_bad_names
renames all .m4a files in the working directory the rename removes spaces, commas, apostrophes, and adds leading zeros to single digits

This function also calls get_metadata on the first file it finds

#### 3) add_chapter_metadata
Adds Chapter info to the metadata file from the individual files Metadata
See the note above about chapters spanning multiple tracks

> NOTE: if you wish to check the metadata, do so now - you can directly edit the txt file if you would like

#### 4) join_all_m4a
Takes all the m4a files an m4b file using the metadata from the above commands

#### 5) create_directory
Uses the artist and album info to create folders and places the file in them `$artist/$album/$file`

#### 6) join_cd
runs the first 4 commands in order (doesn't create directories)

#### 7) join_cd_dir
runs the first 5 commands in order

#### 8) join_cd_menu
uses bash select to present the 5 commands, so you can run them by entering numbers sequentially
