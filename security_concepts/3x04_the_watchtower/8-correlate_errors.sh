#!/bin/bash

awk '
$9 == 403 || $9 == 404 {
    count[$1]++
}
END {
    for (ip in count) {
        if (count[ip] > 5) {
            print "ALERT: IP " ip " is scanning us!"
        }
    }
}
' "$1"
