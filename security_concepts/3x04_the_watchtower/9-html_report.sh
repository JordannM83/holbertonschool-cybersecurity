#!/bin/bash

INPUT="$1"
OUTPUT="$2"

{
    echo "<html>"
    echo "<head><title>Security Report</title></head>"
    echo "<body>"
    echo "<h1>Security Report</h1>"
    echo "<table border=\"1\">"
    echo "<tr><th>IP Address</th><th>Failed Attempts</th></tr>"

    grep "Failed password" "$INPUT" \
    | awk '{for (i=1; i<=NF; i++) if ($i == "from") print $(i+1)}' \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -5 \
    | awk '{
        print "<tr><td>" $2 "</td><td>" $1 "</td></tr>"
    }'

    echo "</table>"
    echo "</body>"
    echo "</html>"
} > "$OUTPUT"
