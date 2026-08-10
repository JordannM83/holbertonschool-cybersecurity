#!/bin/bash
for file in $1; do [ -f "$file" ] && grep "segfault" "$file"; done
