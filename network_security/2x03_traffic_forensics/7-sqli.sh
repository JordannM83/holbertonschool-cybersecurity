#!/bin/bash
tshark -r "$1" -Y "http.request.uri.(UNION|SELECT|union|select)" -T fields -e http.request.uri
#tshark -r "$1" -Y 'http.request' -T fields -e http.request.full_uri 2>/dev/null | python3 -c 'import sys,urllib.parse; [print(u) for u in map(str.strip,sys.stdin) if u and ("UNION" in urllib.parse.unquote(u).upper() or "SELECT" in urllib.parse.unquote(u).upper())]'
