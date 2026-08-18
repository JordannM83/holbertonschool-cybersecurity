#!/bin/bash
grep "localhost" /etc/hosts | awk 'NR<2 {print $1}'
