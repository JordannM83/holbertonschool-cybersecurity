#!/bin/bash
tshark -r "$1" -Y "http.request" -T fields -e http.user_agent | awk 'NF' | sort | uniq
