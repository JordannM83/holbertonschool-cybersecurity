#!/bin/bash
tshark -r "$1" .(/bin/sh). -T fields -e frame.number
