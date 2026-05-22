#!/bin/zsh
cd "$(dirname "$0")"

if [[ -x "./.tools/rojo/rojo" ]]; then
	./.tools/rojo/rojo serve
elif command -v rojo >/dev/null 2>&1; then
	rojo serve
else
	echo "Rojo is not installed. Install it from https://rojo.space/"
	read -k 1 "?Press any key to close..."
fi
