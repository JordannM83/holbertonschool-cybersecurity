#!/bin/bash
IFS=. read -r i1 i2 i3 i4 <<< "$1"; IFS=. read -r m1 m2 m3 m4 <<< "$2"; echo "$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"