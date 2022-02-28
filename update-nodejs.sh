#!/bin/bash
case $1 in
	"--force" | "-f")
	FORCE=1
	;;
	"--help" | "-h" | "-?")
	echo "Script bash by GuiguiBlocCraft"
	echo "===== An NodeJS updater ======"
	echo
	echo "--force (or -f)     Force download without check current version of Node"
	echo "--help (or -h)      Display this help"
	echo "--version (or -v)   Download a version"
	exit 1
	;;
	"--version" | "-v")
	if [ "$2" == "" ]; then
		echo "Usage: $0 --version VERSION"
		exit 2
	fi

	VERSION=$(echo $2 | cut -d"v" -f2)
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
tar -xzf $FILENAME

echo "Removing old version..."
rm -R nodejs-linux/
mv node-v$VERSION-linux-x64/ nodejs-linux/
rm $FILENAME

if [ "$OLD_VERSION" == "" ]; then
	echo -e "# NodeJS\nexport PATH=/home/$USERNAME/nodejs-linux/bin/:\$PATH">>~/.bashrc
	echo "Done. (Please restart your bash to use node)"
elif [ "$OLD_VERSION" == "$VERSION" ]; then
	echo "Done. (Version reinstalled)"
else
	echo "Done. (v$OLD_VERSION -> v$VERSION)"
fi
