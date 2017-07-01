#!/usr/bin/env bash

[[ -n "${1}" ]] || { >&2 echo "Need a zImage kernel file as argument" ; exit 1 ; }

SKIP=$(LC_ALL=C grep -a -b -o $'\x1f\x8b\x08\x00\x00\x00\x00\x00' "${1}" | cut -d ':' -f 1)

UNZIP=$(dd if="${1}" bs=1 skip=${SKIP} status=none | 2>/dev/null zcat)

UNAME=$(echo "${UNZIP}" | grep -a 'Linux version')

echo "${UNAME}" | awk '{ print $3 }'
