#!/bin/bash
function checksum {
    file="$1"
	hash_len=64
	checksum=$(sha256sum "$file")

	echo "${checksum:0:${hash_len}}"
}

