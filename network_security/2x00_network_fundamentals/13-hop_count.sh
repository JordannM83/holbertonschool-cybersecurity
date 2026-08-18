#!/bin/bash
traceroute $1 | awk 'END {print $1 -1}'
