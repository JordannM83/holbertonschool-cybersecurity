#!/bin/bash
dig +short SOA "$1" | awk '{printf "%s", $1}'
