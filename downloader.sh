#!/bin/bash
DL_LINK=$1

TEMP_DIR=~/"Movies/Incomplete/"
FINISH_DIR=~/"Movies/Finished/"
DL_LOG="logs/downloads/"
mkdir $TEMP_DIR $DL_LOG $FINISH_DIR

# Extract filename from download link
FILENAME=$(echo $1 | sed 's/%2F/\//g' | egrep -oe '[^\/]*$.*')
EXTENSION=$(echo $FILENAME | egrep -oe '.(zip|avi|mp4|mkv)')
if [[ ! "$EXTENSION" ]]; then
	FILENAME=$(echo "$FILENAME.zip")
	EXTENSION='.zip'
fi

# Get notification email from config file variables
CONFIG=$(cat config.txt)
NOTIFICATION_EMAIL=$(echo "$CONFIG" | egrep -e 'NOTIFICATION_EMAIL=[^ ]*' | sed -E 's/NOTIFICATION_EMAIL=//')
echo $NOTIFICATION_EMAIL
# If download is not a zip file, then it was manually downloaded, if email was provided send a starting message
if [[ "$EXTENSION" != '.zip' && "$NOTIFICATION_EMAIL" ]]; then
	osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "Starting download: $FILENAME ...."
fi

# Download file and store output in variable
axel -a -n 30 -s 20000000 -o "$TEMP_DIR$FILENAME" "$DL_LINK" &>"$DL_LOG$FILENAME.txt"
AXELOUTPUT=$(tail -3 "$DL_LOG$FILENAME.txt")
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

	exit 1

# Download was successful
else
	echo -e $FINISHTIME"\n$FILENAME Download Complete\n\n" >> logs/bashapplication.log

	mv "$TEMP_DIR$FILENAME" "$FINISH_DIR$FILENAME"
	rm "$DL_LOG$FILENAME.txt"

	exit 0
fi