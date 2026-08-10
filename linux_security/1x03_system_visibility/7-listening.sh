#!/bin/bash
ss -ltn4H | awk '{print $4}' | awk -F: '{print $NF}' | sort -nu
