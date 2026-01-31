#!/usr/bin/env bash
# Capitalize first letter of the day
day=$(LC_ALL=fr_CA.utf8 date '+%A %Y-%m-%d %H:%M')
echo "${day^}"
