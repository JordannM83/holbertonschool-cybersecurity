#!/bin/bash
dig AXFR "$1" $2 | tail -1
