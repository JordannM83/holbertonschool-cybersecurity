#!/bin/bash
tshark -r "$1" -Y "http.request.method=="POST"" -T fields -e urlencoded-form.value
