#!/bin/bash
set -eu

url="$1"
store_to="$2"

host=$(echo "$url" | cut -d ':' -f 1)
path=${url:$(expr ${#host} + 1)}
fingerprint=$(basename "$path")

incomplete="$(dirname "$store_to")/incomplete"
test -e "$incomplete" || mkdir -p "$incomplete"

buffer="${incomplete}/${fingerprint}"
obj_path="$(dirname "$store_to")/@obj_${fingerprint}"

if test -e "$obj_path"; then
	ln -sf "$obj_path" "$store_to"
else

	sftp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$host"<<EOF
get "$path" "$buffer"
rm "$path"
bye
EOF

	real_fingerprint="$(checksum "$buffer")"
	if test "$real_fingerprint" = "$fingerprint"; then
		mv -f "$buffer" "$obj_path"
		ln -sf "$obj_path" "$store_to"
	else
		rm -f "$buffer"
		echo "${url} => ${store_to}"
		echo "Checksum(${real_fingerprint}) is not expected(${fingerprint}), remove it..."
		exit -1
	fi
fi

