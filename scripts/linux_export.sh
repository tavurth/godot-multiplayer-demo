#!/usr/bin/env bash
set -euo pipefail

NAME=godot-multiplayer-demo
DIRECTORY=$(pwd)

/Applications/Godot.app/Contents/MacOS/Godot $@ --headless --export-release "Linux" $DIRECTORY/build/$NAME.x86_64

zip build/godot-multiplayer-demo-linux.zip \
    build/godot-multiplayer-demo.x86_64 \
    build/*.so \
    build/godot-multiplayer-demo.pck ||
    true

rm -rf \
    build/godot-multiplayer-demo.x86_64 \
    build/*.so \
    build/godot-multiplayer-demo.pck
