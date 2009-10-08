#!/bin/bash
set -eu

url="$1"
store_to="$2"

export GIT_DIR="$store_to"
if test ! -e "$GIT_DIR"; then
	git init --bare
	git remote add origin "$url"
	rmdir "${GIT_DIR}/refs/heads"
	ln -ds "remotes/origin" "${GIT_DIR}/refs/heads"

	touch "${GIT_DIR}/git-daemon-export-ok"
fi

git remote update origin

