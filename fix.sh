#!/bin/bash
# Jalankan sebagai root untuk memeriksa apakah login user lfs valid

cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
