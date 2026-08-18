#!/bin/bash
host $1 | awk '/has address/ {printf "%s", $4}'
