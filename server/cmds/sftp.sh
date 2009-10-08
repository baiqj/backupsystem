#!/bin/bash
set -eu

url="$1"
store_to="$2"

incomplete="$(dirname "$store_to")/incomplete"
objects="$(dirname "$store_to")/objects"

test -e "$incomplete" || mkdir -p "$incomplete"
test -e "$objects" || mkdir -p "$objects"

host=$(echo "$url" | cut -d ':' -f 1)
path=${url:$(expr ${#host} + 1)}
fingerprint=$(basename "$path")
buffer="${incomplete}/${fingerprint}"
obj_path="${objects}/${fingerprint}"

if test -e "$obj_path"; then
	ln -sf "$(readlink "$obj_path")" "$store_to"
else

	sftp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$host"<<EOF
get "$path" "$buffer"
rm "$path"
bye
EOF

	real_fingerprint="$(checksum "$buffer")"
	if test "$real_fingerprint" = "$fingerprint"; then
		mv -f "$buffer" "$store_to"
		ln -sf "$store_to" "${obj_path}"
	else
		rm -f "$buffer"
		echo "${url} => ${store_to}"
		echo "Checksum(${real_fingerprint}) is not expected(${fingerprint}), remove it..."
		exit -1
	fi
fi

