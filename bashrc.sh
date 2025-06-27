#!/bin/bash
set -e

echo "📦 [LFS] Build Toolchain Lengkap (Urutan Resmi)"

# ==== 0. Setup Environment ====
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022

LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
LC_ALL=POSIX
MAKEFLAGS="-j$(nproc)"
PATH=$LFS/tools/bin:/bin:/usr/bin

export LFS LFS_TGT LC_ALL MAKEFLAGS PATH
EOF

source ~/.bash_profile

if [ -z "$LFS" ] || [ -z "$LFS_TGT" ]; then
  echo "❌ Environment belum aktif!"
  exit 1
fi
