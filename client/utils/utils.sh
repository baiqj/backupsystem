#!/bin/bash
set -u

function add_queue {
	local name="$1"
	local content="$2"

	echo "$content" > "${TODOdir}/RQ${name}"
}

function checksum {
	local file="$1"
	local hash_len=64
	local cksum=$(sha256sum "$file")

	echo "${cksum:0:${hash_len}}"
}

