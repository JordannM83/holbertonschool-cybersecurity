#!/bin/bash
tshark -r "$1" -Y 'frame contains "/bin/sh"' | awk '{print $1}'
