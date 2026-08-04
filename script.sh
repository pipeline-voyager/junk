#!/bin/bash

echo "Welcome to EZ Tools"
echo "Select a command"
echo "[1] lightning file searcher"
echo "[2] scan for problem"
echo "[3] policy update"
read -p "select tool: " tool
if [ "$tool" = "1" ]; then
	python -m pip install pywin32 > /dev/null
	python search.py
elif [ "$tool" = "2" ]; then 
	python scannow.py
elif [ "$tool" = "3" ]; then
	python gpupdate.py
else
	echo "Invalid"
	echo "Exiting..."
	sleep 5
	echo "Program stopped"
fi
