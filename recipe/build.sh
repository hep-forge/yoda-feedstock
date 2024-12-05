#! /usr/bin/bash

./configure --prefix=$PREFIX

make -j$(nproc)
make install
