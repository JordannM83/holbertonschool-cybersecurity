#!/bin/bash
mkdir -p $1 | chown root:$2 $1 | chmod 3660 $1
