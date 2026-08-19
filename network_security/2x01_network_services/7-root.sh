#!/bin/bash
ns=$(dig +trace "$1" | awk '$3 == "IN" && $4 == "NS" {print $5; exit}'); dig +short "$ns" | head -n1
