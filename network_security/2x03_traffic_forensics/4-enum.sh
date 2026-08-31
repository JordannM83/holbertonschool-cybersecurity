#!/bin/bash
tshark -r "$1" -y "http.response.code==404" | wc -l
