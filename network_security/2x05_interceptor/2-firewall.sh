#!/bin/bash
nft add rule "$1" input { ip saddr 10.200.0.0/24 tcp dport 3128 accept }
