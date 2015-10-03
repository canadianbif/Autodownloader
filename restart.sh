#!/bin/bash
PID=$(ps aux | grep "php autodownloader.php" | grep -v "grep" | awk '{print $2}')
if [[ $PID != '' ]]; then
	kill $PID
fi
php autodownloader.php &
PID=$(ps aux | grep "php autodownloader.php" | grep -v "grep" | awk '{print $2}')
echo "PID: [$PID]"