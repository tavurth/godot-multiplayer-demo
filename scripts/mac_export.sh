#!/usr/bin/env bash
set -euo pipefail

NAME=godot-multiplayer-demo
DIRECTORY=$(pwd)

/Applications/Godot.app/Contents/MacOS/Godot $@ --headless --export-release "MacOS" $DIRECTORY/build/$NAME-osx.dmg
VOLUME=$(hdiutil attach $DIRECTORY/build/$NAME-osx.dmg | grep Volumes | awk '{print $3}')
cp -r /Volumes/$NAME/$NAME.app /Applications/
hdiutil detach $VOLUME
