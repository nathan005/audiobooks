# audiobooks
Shell Script to aid in converting files to chapterized .m4b files to simplify creation of my Plex audiobook library

I'm running OSX, this script has only been tested on my local system as it was written to work for me - I welcome input to simplify this for other systems as well.

### This Script requires ffmpeg 
[Install ffmepg OSX?](https://superuser.com/questions/624561/install-ffmpeg-on-os-x)


## Usage
> NOTE: I wrote this primarily for my personal use, so I have not tested it on other systems.

1. Place the script in the folder with the m4a files you wish to convert
2. Make the file executable
    1. open terminal (command+space type terminal)
    2. type in cd followed by a space: `cd `
    3. drag the folder with the m4a files into the terminal window _(will highlight blue and add a directory when you let go)_ 
    4. press enter _you should see the directory name before the % in terminal now_
    5. add the following command `chmod +x fromcd.sh`
3. Execute the script by typing `./fromcd.sh` in terminal
4. Choose the option you would like to run

## Converting from CD
The functions are designed to make it easier to convert m4a files from an AudioBook CD
This should be imported from a cd that you own to a single folder with all the audio files in order, named by disk-track numbers
This is the default behavior when importing with iTunes etc.

> ex: 01-01 Intro.m4a, 01-02 Chapter 1 - Title

### Chapterized files
If you want the file to include chapter markers, when importing the files to make sure the metadata is correct.

- Every file (from each CD) should have the same album and artist info
- Each track should be named how you would the title of the chapter to appear
- If a chapter is broken into multiple files - Make sure they are named the same, but with a trailing digit following the chapter number

> ex: Chapter 01 - The Beginning, Chapter 01b - The Beginning

_Will make the 2 files above, 01... and 01b... into 1 chapter with the title: 1. The Beginning_

* The script will merge these tracks only if the metadata title is the same, besides the trailing character
  
* I would reccomend https://metaz.io if you need to edit metadata 

* The script is set to remove "Chapter " and output the chapter number followed by a period. 
I find this easier to read since I know the number is a chapter number

## Options
There are 5 options, plus quit
#### 1) Create metadata file
Will rename all .m4a files in the working directory. 
And produce a FFMETADATA.txt file with album and track info

The rename removes spaces, commas, apostrophes, and adds leading zeros to single digits

> See the note in Chapterized Files about chapters spanning multiple tracks

> NOTE: if you wish to check the metadata, do so now - you can directly edit the txt file if you would like

#### 2) Join *.m4a and exisiting FFMETADATA.txt
Takes all the m4a files in the directory and the FFMETADATA.txt file from the above commands and makes a chapterized m4b file.

> This command requires there be both an m4a and a FFMETADATA.txt in the working directory.

#### 3) Create metadata and m4b
Same as running both 1 followed by 2. 

#### 4) Create m4b and put in dir
Same as running both 1, 2, followed by 5 

#### 5) Create Directories for *.m4b
Uses the artist and album info to create folders and places the file in them `$artist/$album/$file`

#### 6) quit
exits the select menu
> as with every program it also can be exitied with control+c
