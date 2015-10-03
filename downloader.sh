#!/bin/bash
TV_DIR=~/Movies/TV_Shows/
MOVIE_DIR=~/Movies/Movies/
DL_LINK=$1
NOTIFICATIONEMAIL=$2
# Extract filename from download link
FILENAME=$(echo $1 | egrep -o -e '[^\/]*?\.(zip|avi|mkv|mp4)')

ISZIP=$(echo $FILENAME | egrep -e '(.zip)')
# If download is a zip file, then its a TV Show from the autodownloader, dont send a starting message
if [[ "$ISZIP" = '' ]]; then
	osascript sendFinishedMessage.applescript $NOTIFICATIONEMAIL "Starting download: $FILENAME ...."
fi

# Download file and store output in variable
AXELOUTPUT=$(axel -a -n 30 -s 5000000 -o ~/Movies/"$FILENAME" "$DL_LINK")
FINISHTIME=$(date +"%r")
AXELERROR=$(echo $AXELOUTPUT | grep "100%")

# Determine if download successful or failed
if [[ "$AXELERROR" = '' ]]; then
	echo -e "\nLink: $DL_LINK failed to download\n" >> logs/basherror.log
	echo -e $FINISHTIME"\nError Downloading File: $FILENAME\n\n" >> logs/bashapplication.log
	osascript sendFinishedMessage.applescript $NOTIFICATIONEMAIL "$FILENAME failed to download."
	# exit 1
else
	echo -e $FINISHTIME"\n$FILENAME Download Complete\n\n" >> logs/bashapplication.log

	# Replace non-space characters between words with spaces in the filename
	FILENAMEWITHSPACES=$(echo $FILENAME | tr ._ ' ' | sed 's/%20/ /g')
	# Determine if file is a TV Show (US or UK)
	DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*?[sS][0-3][0-9][eE][0-3][0-9]')
	CHARTOREMOVE=8
	if [[ "$DOWNLOADNAME" = '' ]]; then
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*?1?[0-9]x[0-3][0-9]')
		CHARTOREMOVE=6
	fi

	if [[ "$DOWNLOADNAME" = '' ]]; then
		# Process Movies
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -o -e '.*?(480p|720p|1080p)')
		mv ~/Movies/"$FILENAME" "$MOVIE_DIR"
	else
		# Process TV Shows
		SHOWNAME=$(echo $DOWNLOADNAME | rev | cut -c $CHARTOREMOVE- | rev)
		mkdir -p "$TV_DIR$SHOWNAME"

		# Unzip if file is compressed, otherwise do nothing, then sort
		if [[ "$ISZIP" != '' ]]; then
			unzip -o ~/Movies/"$FILENAME" -d "$TV_DIR$SHOWNAME"
			rm ~/Movies/"$FILENAME"
		else
			mv ~/Movies/"$FILENAME" "$TV_DIR$SHOWNAME"
		fi
	fi

	osascript sendFinishedMessage.applescript $NOTIFICATIONEMAIL "$DOWNLOADNAME has been downloaded."
fi