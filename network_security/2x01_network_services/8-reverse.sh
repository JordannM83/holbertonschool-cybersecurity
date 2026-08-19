#!/bin/bash
host "$1" | awk '{printf "%s", $5}'
