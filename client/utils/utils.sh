#!/bin/bash
set -u

function add_queue {
	name="$1"
	content="$2"

	echo "$content" > "${TODOdir}/RQ${name}"
}

function checksum {
	file="$1"
	hash_len=64
	checksum=$(sha256sum "$file")

	echo "${checksum:0:${hash_len}}"
}

