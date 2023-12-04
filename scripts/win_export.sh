#!/usr/bin/env bash
set -euo pipefail

NAME=godot-multiplayer-demo
DIRECTORY=$(pwd)

/Applications/Godot.app/Contents/MacOS/Godot $@ --headless --export-release "Windows" $DIRECTORY/build/$NAME.exe
zip \
    build/godot-multiplayer-demo-win.zip \
    build/godot-multiplayer-demo.exe \
    build/*.dll \
    build/godot-multiplayer-demo.pck ||
    true

rm -rf \
    build/godot-multiplayer-demo.exe \
    build/*.dll \
    build/godot-multiplayer-demo.pck
