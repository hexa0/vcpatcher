#!/bin/bash

CURRENT_PATH="$PWD"
TEMP_DIR="$CURRENT_PATH/.temp/"
DESTINATION="$CURRENT_PATH/base/src/userplugins/"
PNPM_REQUIRED=0

if [ ! -d $CURRENT_PATH/base ]; then
    git clone https://github.com/Vendicated/Vencord/ base
	cd "$CURRENT_PATH/base"
	git submodule init
	PNPM_REQUIRED=1
else
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

SOURCE_DIRS=()

for subdir in "$CURRENT_PATH/install/"*; do
	if [ -d "$subdir" ]; then
		SOURCE_DIRS+=("$subdir/")
		echo "found source directory: $subdir/"
	fi
done

if [ ${#SOURCE_DIRS[@]} -eq 0 ]; then
    echo "No source directories found in $CURRENT_PATH/install/ to copy."
else
	mkdir -p "$TEMP_DIR"
	rsync -a "${SOURCE_DIRS[@]}" "$TEMP_DIR/"
	rsync -a --delete "$TEMP_DIR/" "$DESTINATION"
	rm -rf "$TEMP_DIR"
fi

cd "$CURRENT_PATH/base"

if [ $PNPM_REQUIRED -eq 1 ]; then
    pnpm update
fi

pnpm build