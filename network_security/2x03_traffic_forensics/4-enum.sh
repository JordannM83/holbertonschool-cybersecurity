#!/bin/bash
tshark -r "$1" -q -z http,tree | awk '$1=="404" {print $4}'
