#!/bin/bash

LOCKFILE="/Users/benjaminfeder/Movies/Autodownloader/sorter.lock"
if [ ! -e "$LOCKFILE" ]; then
	echo $$ > "$LOCKFILE"

	MESSAGESCRIPT="/Users/benjaminfeder/Movies/Autodownloader/sendFinishedMessage.applescript"

	# Grab config file contents and set-up directories based on root directory config variable
	CONFIG=$(cat /Users/benjaminfeder/Movies/Autodownloader/config.txt)
	# Initialize all config variables
	ROOT_DIR=$(echo "$CONFIG" | egrep -e 'ROOT_DIR=[^ ]*' | sed -E 's/ROOT_DIR=//')
	if [[ ! "$ROOT_DIR" ]]; then
		ROOT_DIR=/Users/benjaminfeder/Movies/
		echo "ROOT_DIR=/Users/benjaminfeder/Movies/" >> config.txt
	fi
	TV_DIR=$(echo "$CONFIG" | egrep -e 'TV_DIR=[^ ]*' | sed -E 's/TV_DIR=//')
	if [[ ! "$TV_DIR" ]]; then
		TV_DIR="${ROOT_DIR}TV_Shows/"
	fi
	MOVIE_DIR=$(echo "$CONFIG" | egrep -e 'MOVIE_DIR=[^ ]*' | sed -E 's/MOVIE_DIR=//')
	if [[ ! "$MOVIE_DIR" ]]; then
		MOVIE_DIR="${ROOT_DIR}Movies/"
	fi
	REQ_SORT="${ROOT_DIR}Requires_Sorting/"
	FINISH_DIR="${ROOT_DIR}Finished/"
	mkdir $MOVIE_DIR $TV_DIR $FINISH_DIR $REQ_SORT

	# If remaining files in finished, run sorter again
	while [[ $(ls $FINISH_DIR) ]]; do

		for FULLFILENAME in $FINISH_DIR*; do
			FILENAME=$(echo $FULLFILENAME | egrep -oe '[^\/]*$.*')
			EXTENSION=$(echo $FILENAME | egrep -oe '.(zip|avi|mp4|mkv)')
			# Replace non-space characters between words with spaces in the filename
			FILENAMEWITHSPACES=$(echo $FILENAME | tr ._ ' ' | sed 's/%[12][0-9A-F]/ /g')

			# Determine media type and name convention based on filename
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
				CHARTOREMOVE=12
			fi
			# Full Season
			if [[ "$DOWNLOADNAME" = '' ]]; then
				DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oie '.*(season |s)[0-9]{1,2}')
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
				if [[ "$DOWNLOADNAME" != '' ]]; then
					mv "$FINISH_DIR$FILENAME" "$MOVIE_DIR$DOWNLOADNAME$EXTENSION"
				else
					mv "$FINISH_DIR$FILENAME" "$REQ_SORT"
				fi
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
				if [[ "$EXTENSION" = '.zip' ]]; then
					ZIPSUCCESS=$(unar -o "$TV_DIR$SHOWNAME" "$FINISH_DIR$FILENAME")
					if [[ "$ZIPSUCCESS" ]]; then
						rm "$FINISH_DIR$FILENAME"
					fi
				else
					mv "$FINISH_DIR$FILENAME" "$TV_DIR$SHOWNAME"
				fi
			fi

			NOTIFICATION_EMAIL=$(echo "$CONFIG" | egrep -e 'NOTIFICATION_EMAIL=[^ ]*' | sed -E 's/NOTIFICATION_EMAIL=//')
			if [[ "$NOTIFICATION_EMAIL" ]]; then
				if [[ "$DOWNLOADNAME" != '' ]]; then
					osascript "$MESSAGESCRIPT" $NOTIFICATION_EMAIL "$DOWNLOADNAME is ready to watch. Enjoy"'!'
				else
					osascript "$MESSAGESCRIPT" $NOTIFICATION_EMAIL "$FILENAME has been downloaded, but requires manual sorting."
				fi
			fi

		done
	done

	rm $LOCKFILE
fi
