#!/bin/bash
curl -x http://proxy_ip:3128 -o /dev/null -s -w "%{http_code}\n" http://example.com/test.exe | grep 403
