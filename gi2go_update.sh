#!/bin/bash

echo "Downloading GO sql files...\n"
cd /tmp
mkdir go_update_temp
cd go_update_temp
wget ftp://ftp.geneontology.org/pub/go/godatabase/archive/latest-lite/go_*-seqdb-tables.tar.gz 
tar zxf go_*-seqdb-tables.tar.gz
