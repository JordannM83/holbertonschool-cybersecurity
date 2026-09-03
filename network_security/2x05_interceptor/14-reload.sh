#!/bin/bash
if (squid -k parse) then
    squid -k reconfigure
else
    echo "$(squid -k parse)"
    exit
