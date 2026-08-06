#!/bin/bash
HOST="$1"
until nc -z "$HOST" 80 2>/dev/null; do
    echo "Waiting..."
    sleep 1
done
echo "Service UP!"
