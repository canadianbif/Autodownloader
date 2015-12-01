#!/bin/bash
DL_LINK=$1
NOTIFICATION_EMAIL=$2

TEMP_DIR=~/"Movies/Incomplete/"
MOVIE_DIR=~/"Movies/Movies/"
TV_DIR="/Volumes/TVShowHDD/TV_Shows/"
DL_LOG="logs/downloads/"
mkdir $TEMP_DIR $DL_LOG $MOVIE_DIR $TV_DIR

# Extract filename from download link
FILENAME=$(echo $1 | egrep -oe '[^\/]*?\.(zip|avi|mkv|mp4)')

ISZIP=$(echo $FILENAME | egrep -e '(.zip)')
# If download is not a zip file, then it was manually downloaded, if email was provided send a starting message
if [[ ! "$ISZIP" && "$NOTIFICATION_EMAIL" ]]; then
	osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "Starting download: $FILENAME ...."
fi

# Download file and store output in variable
axel -a -n 30 -s 5000000 -o "$TEMP_DIR$FILENAME" "$DL_LINK" &>"$DL_LOG$FILENAME.txt"
AXELOUTPUT=$(cat "$DL_LOG$FILENAME.txt")
FINISHTIME=$(date +"%r")
AXELSUCCESS=$(echo $AXELOUTPUT | grep "100%")

# Download failed
if [[ ! "$AXELSUCCESS" ]]; then
	# Log error accordingly
	LINE="-------------------------------------------------------------------------"
	echo -e "\n$FINISHTIME:\n$LINE\nLink:\n$DL_LINK\nfailed to download\n" >> logs/basherror.log
	echo -e "Axel output found at:\n$DL_LOG$FILENAME.txt\n$LINE\n" >> logs/basherror.log
	echo -e $FINISHTIME"\nError Downloading File: $FILENAME\n\n" >> logs/bashapplication.log
	if [[ "$NOTIFICATION_EMAIL" ]]; then
		osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "$FILENAME failed to download."
	fi

	#exit 1

# Download was successful
else
	echo -e $FINISHTIME"\n$FILENAME Download Complete\n\n" >> logs/bashapplication.log

	# Replace non-space characters between words with spaces in the filename
	FILENAMEWITHSPACES=$(echo $FILENAME | tr ._ ' ' | sed 's/%([12][0-9A-F]|5[B-F])/ /g')
	# Determine filename based on if file fits a TV Show name format (US or UK or Daily Show)
	# Standard US
	DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?[sS][0-3][0-9][eE][0-3][0-9]')
	CHARTOREMOVE=8
	# UK
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?1?[0-9]x[0-3][0-9]')
		CHARTOREMOVE=6
	fi
	# Daily Show
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?20([[:digit:]]{2} ){3}')
		CHARTOREMOVE=13
	fi
	# Full Season
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oie '.*(season|s) ?[0-9]{1,2}')
		CHARTOREMOVE=1
	fi
	# Full Series
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oie '.*(complete.*series|series.*complete)')
		CHARTOREMOVE=0
	fi

	# Process Movies
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?(480p|720p|1080p)')
		mv "$TEMP_DIR$FILENAME" "$MOVIE_DIR"
	# Process TV Shows
	else
		if [[ "$CHARTOREMOVE" != '1' ]]; then
			SHOWNAME=$(echo $DOWNLOADNAME | rev | cut -c $CHARTOREMOVE- | rev)
		else
			SHOWNAME=$(echo $DOWNLOADNAME | \
				perl -nle'print $& if m{^[a-zA-Z0-9 &]+?(?=[^a-zA-Z0-9]*?([Ss]eason|SEASON|[Ss][\d]{1,2}))}' \
				| rev | cut -c $CHARTOREMOVE- | rev )
		fi
		SHOWNAME=$(echo $SHOWNAME | tr '[:upper:]' '[:lower:]')
		mkdir "$TV_DIR$SHOWNAME"

		# Unzip if file is compressed, otherwise do nothing, then sort
		if [[ "$ISZIP" ]]; then
			ZIPSUCCESS=$(unar -o "$TV_DIR$SHOWNAME" "$TEMP_DIR$FILENAME")
			if [[ "$ZIPSUCCESS" ]]; then
				rm "$TEMP_DIR$FILENAME"
			fi
		else
			mv "$TEMP_DIR$FILENAME" "$TV_DIR$SHOWNAME"
		fi
	fi

	if [[ "$NOTIFICATION_EMAIL" ]]; then
		osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "$DOWNLOADNAME has been downloaded."
	fi
fi