#!/bin/bash
tshark -r "$1" -Y "http.request.uri.(UNION|SELECT|union|select)" -T fields -e http.request.uri
