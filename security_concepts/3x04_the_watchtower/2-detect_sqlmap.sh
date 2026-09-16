#!/bin/bash

grep -i 'sqlmap' "$1" \
| awk -F'"' '{
    split($1, ip, " ");

    request = $2;

    method = request;
    sub(/ .*/, "", method);

    path = request;
    sub(/^[^ ]+ /, "", path);
    sub(/ HTTP\/[0-9.]+$/, "", path);

    print ip[1] "," method "," path;
}'