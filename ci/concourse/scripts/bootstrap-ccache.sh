#!/bin/sh

mkdir ccache
cat >ccache/ccache.conf <<EOF
max_size = 500M
EOF
tar czvf ccache_tar/ccache_gpdb.tar.gz ccache
