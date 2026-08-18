#!/bin/bash
grep "localhost" /etc/hosts | awk 'NR<2 {printf "%s", $1}'
