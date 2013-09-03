#!/bin/bash
set -eu

url="$1"
store_to="$2"

rsync -av --numeric-ids --delete "$url" "$store_to"

