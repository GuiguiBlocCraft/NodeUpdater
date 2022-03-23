#!/bin/bash
case $1 in
	"--force" | "-f")
	FORCE=1
	;;

	"--help" | "-h" | "-?")
	echo "Bash script by GuiguiBlocCraft"
	echo "                       v0.1.0"
	echo "===== An NodeJS updater ======"
	echo
	echo "--force (or -f)        Force download without check current version of Node"
	echo "--help (or -h)         Display this help"
	echo "--version (or -v)      Download a version"
	echo "--notprompt (or -np)   Not prompt for install or update"
	exit 1
	;;

	"--version" | "-v")
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
esac

# Get old node's version
if ($(command -v node >/dev/null 2>&1)); then
	OLD_VERSION=$(node -v | cut -c2-)
fi

if [ "$VERSION" == "" ]; then
	VERSION=$(curl --fail -s "https://nodejs.org/dist/latest-gallium/SHASUMS256.txt" | head -1 | cut -d' ' -f3 | cut -c7- | cut -d'-' -f1)
fi
FILENAME=/tmp/node-v$VERSION.tar.gz

if [ "$FORCE" == "" ]; then
	if [ "$VERSION" == "$OLD_VERSION" ]; then
		echo "No update available"
		exit 0
	else
		# Prompt to install/update
		while [[ "$NOPROMPT" == "" ]]; do
			if [ "$OLD_VERSION" == "" ]; then
				echo "Node is not installed or not detected in the path."
				echo -n "Do you want to install v$VERSION of NodeJS in your local session? (Y/N)"
			else
				echo -n "An update for $VERSION is available! Do you want to update? (Y/N)"
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
	echo "Cannot download v$VERSION or type of processor unknown"
	exit 1
fi

echo "Uncompressing node-v$VERSION.tar.gz..."
tar -xzf $FILENAME -C ~/

PATH_INSTALL=nodejs-linux/

if [ -d $PATH_INSTALL ]; then
	echo "Removing old version..."
	rm -R $PATH_INSTALL
fi

echo "Finishing..."
mv node-v$VERSION-linux-$PROC/ $PATH_INSTALL
rm $FILENAME

if [ "$OLD_VERSION" == "" ]; then
	echo -e "# NodeJS\nexport PATH=/home/$USER/nodejs-linux/bin/:\$PATH">>~/.bashrc
	echo "Done. (Please restart your bash to use node)"
elif [ "$OLD_VERSION" == "$VERSION" ]; then
	echo "Done. (Version reinstalled)"
else
	echo "Done. (v$OLD_VERSION -> v$VERSION)"
fi
