#!/bin/bash

CURRENT_PATH="$PWD"
INSTALL_DIR="$CURRENT_PATH/install"
DESTINATION="$CURRENT_PATH/base/src/userplugins"
PNPM_REQUIRED=0

if [ ! -d "$CURRENT_PATH/base" ]; then
	echo "downloading..."
	git clone https://github.com/Vendicated/Vencord/ base
	cd "$CURRENT_PATH/base"
	git submodule init
	PNPM_REQUIRED=1
else
	echo "checking for updates..."

	cd "$CURRENT_PATH/base"

	git restore package.json
	git restore pnpm-lock.yaml

	GIT_PULL_OUTPUT=$(git pull 2>&1)
	GIT_PULL_STATUS=$?

	if [ $GIT_PULL_STATUS -ne 0 ]; then
		echo "error running git pull:"
		echo "$GIT_PULL_OUTPUT"
		exit 1
	fi

	if [[ "$GIT_PULL_OUTPUT" != *"Already up to date."* ]]; then
		echo "new commits have been pulled."
		PNPM_REQUIRED=1
	fi

	git submodule update --init --recursive
fi

mkdir -p "$DESTINATION"

declare -A VALID_PLUGINS

echo "linking user plugins..."

for category in "user" "built-in"; do
	CATEGORY_PATH="$INSTALL_DIR/$category"
	
	if [ -d "$CATEGORY_PATH" ]; then
		for subdir in "$CATEGORY_PATH"/*; do
			if [ -d "$subdir" ]; then
				plugin_name=$(basename "$subdir")
				ln -snf "$subdir" "$DESTINATION/$plugin_name"
				VALID_PLUGINS["$plugin_name"]=1
				# echo "linked [$category]: $plugin_name"
			fi
		done
	fi
done

echo "cleaning up old symlinks..."
for link in "$DESTINATION"/*; do
	if [ -L "$link" ]; then
		link_name=$(basename "$link")
		if [[ -z "${VALID_PLUGINS[$link_name]}" ]]; then
			# echo "removing orphaned symlink: $link_name"
			rm "$link"
		fi
	fi
done

if [ $PNPM_REQUIRED -eq 1 ]; then
	cd "$CURRENT_PATH/base"
	echo "Updating Packages..."
	pnpm update
fi

echo "syncing..."

rsync -L -a --exclude=".git/" --exclude="node_modules/" --delete "$CURRENT_PATH/base/" "$CURRENT_PATH/.base.tmp/"

ln -snf "$CURRENT_PATH/base/node_modules" "$CURRENT_PATH/.base.tmp/node_modules"
ln -snf "$CURRENT_PATH/base/.git" "$CURRENT_PATH/.base.tmp/.git"

echo "running build..."
sudo unshare -m -u /bin/bash -c "pnpm build" # pnpm is an absolute piece of fucking shit and whoever managed to fuck it up this badly to the point it took me 4 FUCKING hours to find a way to isolate it in a way to trick the stupid ass program to think i am running it manually with absolutely no signs of automatiation is the biggest fucking asshole i have ever seen, how the hell does this even happen and why do i need sudo permissions to build a type script application????????