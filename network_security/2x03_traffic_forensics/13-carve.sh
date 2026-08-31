#!/bin/bash
tshark -r "$1" --export-objects http,./extracted && md5sum ./extracted/*