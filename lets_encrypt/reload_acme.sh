#!/bin/bash
# reload_acme.sh
# based on https://github.com/hungnguyenm/edgemax-acme

mkdir -p /config/ssl
cat /tmp/server.key /tmp/full.cer > /config/ssl/server.pem
rm /tmp/server.key /tmp/full.cer