#!/bin/bash
find $1 -size +1M -mtime -7 ! -name "*.gz" -type f 2>/dev/null
