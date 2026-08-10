#!/bin/bash
lsof -i :$1 | awk 'NR>1 { print $1 }'
