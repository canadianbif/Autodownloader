#!/bin/bash
DL_LINK=$1
NOTIFICATION_EMAIL=$2

TEMP_DIR=~/"Movies/Incomplete/"
MOVIE_DIR=~/"Movies/Movies/"
TV_DIR="/Volumes/TVShowHDD/TV_Shows/"
mkdir $TEMP_DIR $MOVIE_DIR $TV_DIR

# Extract filename from download link
FILENAME=$(echo $1 | egrep -o -e '[^\/]*?\.(zip|avi|mkv|mp4)')

ISZIP=$(echo $FILENAME | egrep -e '(.zip)')
# If download is not a zip file, then it was manually downloaded, if email was provided send a starting message
if [[ ! "$ISZIP" && "$NOTIFICATION_EMAIL" ]]; then
	osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "Starting download: $FILENAME ...."
fi

# Download file and store output in variable
AXELOUTPUT=$(axel -a -n 30 -s 5000000 -o "$TEMP_DIR$FILENAME" "$DL_LINK")
FINISHTIME=$(date +"%r")
AXELERROR=$(echo $AXELOUTPUT | grep "100%")

# Determine if download successful or failed
if [[ ! "$AXELERROR" ]]; then
	echo -e "\nLink: $DL_LINK failed to download\n" >> logs/basherror.log
	echo -e $FINISHTIME"\nError Downloading File: $FILENAME\n\n" >> logs/bashapplication.log
	if [[ "$NOTIFICATION_EMAIL" ]]; then
		osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "$FILENAME failed to download."
	fi
	# exit 1
else
	echo -e $FINISHTIME"\n$FILENAME Download Complete\n\n" >> logs/bashapplication.log

	# Replace non-space characters between words with spaces in the filename
	FILENAMEWITHSPACES=$(echo $FILENAME | tr ._ ' ' | sed 's/%20/ /g')
	# Determine filename based on if file fits a TV Show name format (US or UK or Daily Show)
	# Standard US
	DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*?[sS][0-3][0-9][eE][0-3][0-9]')
	CHARTOREMOVE=8
	# UK
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*?1?[0-9]x[0-3][0-9]')
		CHARTOREMOVE=6
	fi
	# Daily Show
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*?20([[:digit:]]{2} ){3}')
		CHARTOREMOVE=13
	fi
	# Full Season
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*(Season|SEASON|season) [\d]+')
		CHARTOREMOVE=1
	fi

	# Process Movies
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*?(480p|720p|1080p)')
		mv "$TEMP_DIR$FILENAME" "$MOVIE_DIR"
	# Process TV Shows
	else
		if [[ "#CHARTOREMOVE" != '1' ]]; then
			SHOWNAME=$(echo $DOWNLOADNAME | rev | cut -c $CHARTOREMOVE- | rev)
		else
			SHOWNAME=$(echo $DOWNLOADNAME | \
				perl -nle'print $& if m{^[a-zA-Z0-9 &]+?(?=[^a-zA-Z0-9]*?([Ss]eason|SEASON|[Ss][\d]{1,2}))}' \
				| rev | cut -c $CHARTOREMOVE- | rev )
		fi
		mkdir "$TV_DIR$SHOWNAME"

		# Unzip if file is compressed, otherwise do nothing, then sort
		if [[ "$ISZIP" ]]; then
			unzip -o "$TEMP_DIR$FILENAME" -d "$TV_DIR$SHOWNAME"
			rm "$TEMP_DIR$FILENAME"
		else
			mv "$TEMP_DIR$FILENAME" "$TV_DIR$SHOWNAME"
		fi
	fi

	if [[ "$NOTIFICATION_EMAIL" ]]; then
		osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "$DOWNLOADNAME has been downloaded."
	fi
fi