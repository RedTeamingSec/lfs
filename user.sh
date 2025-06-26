#!/bin/bash
set -e

# === VARIABEL DASAR ===
LFS=/mnt/lfs
LFS_USER=lfs
LFS_HOME=/home/$LFS_USER
CHROOT_ROOT=$LFS/root

# === CEK AKSES ROOT ===
if [[ $EUID -ne 0 ]]; then
  echo "🛑 Script ini harus dijalankan sebagai root!"
  exit 1
fi

echo "🔧 Menambahkan .bashrc & .bash_profile untuk user 'lfs'..."

# === .bashrc untuk user lfs ===
sudo -u $LFS_USER bash -c 'cat > ~/.bashrc' << "EOF"
# ~/.bashrc untuk user lfs (toolchain)
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=$LFS/tools/bin:$PATH
export MAKEFLAGS="-j$(nproc)"
EOF

# === .bash_profile untuk user lfs ===
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

echo "✅ .bashrc dan .bash_profile user 'lfs' sudah ditulis."

# === Tambahkan .bashrc untuk root di dalam chroot ===
echo "🔧 Menambahkan .bashrc untuk root chroot..."

mkdir -p $CHROOT_ROOT

cat > $CHROOT_ROOT/.bashrc << "EOF"
# ~/.bashrc untuk root dalam chroot (LFS)
set +h
umask 022

export LFS=/mnt/lfs
export LC_ALL=POSIX
export LFS_TGT=$(uname -m)-lfs-linux-gnu

PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=/tools/bin:$PATH

export PATH LC_ALL LFS LFS_TGT
CONFIG_SITE=/usr/share/config.site
export CONFIG_SITE
EOF

echo "✅ .bashrc root chroot ditambahkan di: $CHROOT_ROOT/.bashrc"

echo -e "\n🎉 Selesai. Sekarang kamu bisa lanjut:"
echo "👉 su - lfs"
echo "👉 chroot $LFS /usr/bin/env -i HOME=/root ... /bin/bash --login"
