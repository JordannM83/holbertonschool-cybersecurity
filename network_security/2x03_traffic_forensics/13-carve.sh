#!/bin/bash
tshark -r "$1" --export-object http 2>/dev/null | md5sum
