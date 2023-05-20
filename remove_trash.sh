#!/bin/bash

# ln -s $HOME/.config/remove_trash.sh /usr/local/bin/rt

RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Define the maximum size in bytes (20GB)
MAX_SIZE=$((20*1024*1024*1024))

# If the trash directory does not exist, create it
if [ ! -d "$TRASH_HOME" ]; then
	mkdir "$TRASH_HOME"
fi

# Function to delete the oldest files in the trash directory
delete_oldest_files() {
	# Get a list of all files in the trash directory, sorted by modification time (oldest first)
	files=($(sudo find "$TRASH_HOME" -type f -printf '%T@ %p\n' | sort -n | cut -d' ' -f 2))

	# Calculate the current size of the trash directory
	size=$(sudo du -bs "$TRASH_HOME" | cut -f 1)

	# Delete the oldest files until the size of the trash directory is less than the maximum size
	for file in "${files[@]}"; do
		if [ $size -lt $MAX_SIZE ]; then
		break
		fi
		echo "sudo remove [$file]"
		sudo rm -rf "$file"
		size=$(sudo du -bs "$TRASH_HOME" | cut -f 1)
	done

	# Delete empty directories in the trash directory
	find "$TRASH_HOME" -type d -empty -delete
}

if ! crontab -l | grep -q 'rt check'; then
	(crontab -l ; echo "0 * * * * /usr/local/bin/rt check") | crontab -
	echo "定时任务注册成功"
fi

for arg in "$@"; do
	if [[ "$arg" == "/" ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	elif [[ "$arg" == "/." ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	elif [[ "$arg" == "/.." ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	elif [[ "$arg" == ~ ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	fi
done

base_file_array=()
for base_file in $(ls /); do
	base_file_array+=("/$base_file")
done

for arg in "$@"; do
	current_file=""
	if [[ "$arg" =~ ^/ ]]; then
		current_file="/$(echo "$arg" | sed 's#^/\+\|\(/\+\)$##g')"
	else
		current_file=$(echo "$arg" | sed 's#^/\+\|\(/\+\)$##g')
	fi

	if [[ "$current_file" == "/" ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	elif [[ "$current_file" == "/." ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	elif [[ "$current_file" == "/.." ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	elif [[ "$current_file" == ~ ]]; then
		echo -e "${RED}${BOLD}Error: can not delete the file in the home path!${RESET}" >&2
		echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
		exit
	fi
	for base_file in "${base_file_array[@]}"; do
		if [[ "$base_file" == "$current_file" ]]; then
			echo -e "${RED}${BOLD}Error: can not delete the file in the root path!${RESET}" >&2
			echo -e "${RED}${BOLD}Error: check your input path!${RESET}" >&2
			exit
		fi
	done
done

if [[ "$1" == "-check" ]]; then
  # Check the size of the trash directory
	size=$(sudo du -bs "$TRASH_HOME" | cut -f 1)
	echo "Trash directory size: $size"

	if [ $size -gt $MAX_SIZE ]; then
		echo "Trash directory size is over 20GB. Deleting old files..."
		delete_oldest_files
		echo "Done."
	fi
elif [[ "$1" == "-crush" ]]; then
	echo "Delete all file in $TRASH_HOME"
	sudo rm -rf $TRASH_HOME
else
	# Loop through each argument passed to the command
	for arg in "$@"; do
		# Get the full path of the argument
		full_path=$(readlink -f "$arg")
		echo "Moved $full_path to $TRASH_HOME"
		# Get the parent directory of the argument
		parent_dir=$(dirname "$full_path")
		# Get the filename of the argument
		filename=$(basename "$full_path")
		# Create the directory structure in the trash directory
		mkdir -p "$TRASH_HOME$parent_dir"
		# Move the file to the trash directory, preserving the directory structure
		sudo mv -b "$full_path" "$TRASH_HOME$parent_dir/$filename"
	done
fi

