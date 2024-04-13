directory="kitty-kit"
for entry in "$directory"/*; do
	if [ -d "$entry" ]; then
		wally $1 $entry
	fi
done
