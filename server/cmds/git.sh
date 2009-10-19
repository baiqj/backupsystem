#!/bin/bash
set -eu

url="$1"
store_to="$2"

GIT_DIR="$store_to"

if test ! -e "$GIT_DIR"; then
	git clone --mirror "$url" "$GIT_DIR"
	touch "${GIT_DIR}/git-daemon-export-ok"
else
	git --git-dir="$GIT_DIR" remote update origin
fi

