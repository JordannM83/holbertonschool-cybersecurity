#!/bin/bash
tshark -r "$1" --export-object http,object | md5sum
