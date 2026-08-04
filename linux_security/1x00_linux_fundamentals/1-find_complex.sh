#!/bin/bash
find $1 -size +1M -mtime -1 ! -name "*.gz" -type f 2>/dev/null
