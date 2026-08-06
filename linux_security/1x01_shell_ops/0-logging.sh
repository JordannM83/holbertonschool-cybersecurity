#!/bin/bash
echo "Starting Task" >> $1 2>&1
echo "Doing Work" >> $1 2>&1
echo "Error: Work Failed" >> $1 2>&1
