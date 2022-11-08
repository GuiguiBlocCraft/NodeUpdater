#!/bin/bash
# Bash script developed by GuiguiBlocCraft
# Version 0.2.1

# Settings
PATH_INSTALL=.nodejs-exec
TYPE_VERSION=hydrogen

# Displays
YES_NO=\\x1B[1m\(Y/N\)\\x1B[0m

case $1 in
	"--force" | "-f")
	FORCE=1
	;;

	"--help" | "-h" | "-?")
	echo -e "   \x1B[1;32mNode\x1B[1;37m\x1B[1;37mJS Updater\x1B[0m v0.2.1"
	echo
	echo "--force (or -f)        Force download without check current version of Node"
	echo "--help (or -h)         Display this help"
	echo "--download (or -d)     Download a version"
	echo "--notprompt (or -np)   Not prompt for install or update"
	exit 1
	;;

	"--download" | "-d")
	if [ "$2" == "" ]; then
		echo "Usage: $0 --version VERSION"
		exit 2
	fi

	VERSION=$(echo $2 | cut -d"v" -f2)
	FORCE=1
	;;

	"--notprompt" | "-np")
	NOPROMPT=1
	;;

	"")
	;;

	*)
	echo -e "\x1B[0;31mArgument \x1B[1;31m$1\x1B[0;31m is not exist.\x1B[0m"
	echo
	echo -e "To display commands' list, do \"\x1B[1m--help\x1B[0m\"."
	exit 3
	;;
esac

# Get old node's version
if ($(command -v node >/dev/null 2>&1)); then
	OLD_VERSION=$(node -v | cut -c2-)
fi

if [ "$VERSION" == "" ]; then
	CONTENT=$(curl --fail -s "https://nodejs.org/dist/latest-$TYPE_VERSION/SHASUMS256.txt")
	VERSION=$(echo -n "$CONTENT" | head -1 | cut -d' ' -f3 | cut -c7- | cut -d'-' -f1)
else
	CONTENT=$(curl --fail -s "https://nodejs.org/dist/v$VERSION/SHASUMS256.txt")
fi
FILENAME=/tmp/node-v$VERSION.tar.gz

if [ "$FORCE" == "" ]; then
	if [ "$VERSION" == "$OLD_VERSION" ]; then
		echo "No update available"
		exit 0
	else
		# Prompt to install/update
		while [ "$NOPROMPT" == "" ]; do
			if [ "$OLD_VERSION" == "" ]; then
				echo "Node is not installed or not detected in the path."
				echo -en "Do you want to install v$VERSION of NodeJS in your local session? $YES_NO"
			else
				if [ "$VERSION" != "" ]; then
					echo -en "An update for $VERSION is available! Do you want to update? $YES_NO"
				else
					echo "Connection error: please check your connection before start script"
					exit 3
				fi
			fi

			read INPUT
			if [[ ${INPUT^^} == 'Y' ]]; then
				break
			elif [[ ${INPUT^^} == 'N' ]]; then
				echo "Cancelling by user"
				exit
			fi
		done
	fi
fi

PROC=$(uname -m)
if [ "$PROC" == "x86_64" ]; then PROC=x64; fi

echo "Downloading version $VERSION..."
curl --fail --progress-bar https://nodejs.org/dist/v$VERSION/node-v$VERSION-linux-$PROC.tar.gz -o $FILENAME

if [[ $? -gt 0 ]]; then
	echo -e "\n\x1B[0;31mCannot download v\x1B[1;31m$VERSION \x1B[0;31mor type of processor unknown\x1B[0m"
	exit 1
fi

SHA256SUM_CHECK=$(echo -n "$CONTENT" | grep "linux-$PROC.tar.gz" | head -1 | cut -d" " -f1)
SHA256SUM_FILE=$(sha256sum "$FILENAME" | cut -d" " -f1)

if [ ! "$SHA256SUM_CHECK" == "$SHA256SUM_FILE" ]; then
	echo -e "\n\x1B[0;31mSHA256 sum is not matching with the file downloaded!\x1B[0m"
	exit 4
fi

echo "Uncompressing node-v$VERSION.tar.gz..."
tar -xzf $FILENAME -C ~/

if [ -d $PATH_INSTALL/ ]; then
	echo "Removing old version..."
	rm -R $PATH_INSTALL/
fi

echo "Finishing..."
mv node-v$VERSION-linux-$PROC/ $PATH_INSTALL/
rm $FILENAME

if [ "$OLD_VERSION" == "" ]; then
	echo -e "# NodeJS\nexport PATH=/home/$USER/$PATH_INSTALL/bin/:\$PATH">>~/.bashrc
	echo "Done. (Please restart your bash to use node)"
elif [ "$OLD_VERSION" == "$VERSION" ]; then
	echo "Done. (Version reinstalled)"
else
	echo "Done. (v$OLD_VERSION -> v$VERSION)"
fi
