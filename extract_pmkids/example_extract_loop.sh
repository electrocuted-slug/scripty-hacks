#!/bin/bash
for f in *.pcap; do bash handshake_extractor.sh $f; done
