#!/bin/bash
ps -eo pid,comm --sort=-pcpu | awk 'NR==2 {print $1, $2}'
