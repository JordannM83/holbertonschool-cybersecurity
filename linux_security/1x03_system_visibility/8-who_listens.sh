#!/bin/bash
lsof -iTCP:$1 | awk 'NR>1 { print $1 }'
