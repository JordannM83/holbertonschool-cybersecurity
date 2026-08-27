#!/bin/bash
nmap -sST -p 22,23,80 $1
