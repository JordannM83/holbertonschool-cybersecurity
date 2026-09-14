#!/usr/bin/env bash

set -eu

if [ "$#" -ne 1 ]; then
	printf 'Usage: %s FILE\n' "$0" >&2
	exit 1
fi

if [ ! -e "$1" ]; then
	printf 'Error: file does not exist: %s\n' "$1" >&2
	exit 1
fi

setfacl -m u:auditor_hipaa:r "$1"
