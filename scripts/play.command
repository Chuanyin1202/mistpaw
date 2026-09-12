#!/bin/zsh
# Double-click in Finder to run this local Godot project.
cd -- "${0:A:h:h}" || exit 1
if command -v godot >/dev/null 2>&1; then
  exec godot --path .
else
  exec /opt/homebrew/bin/godot --path .
fi
