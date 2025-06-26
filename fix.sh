#!/bin/bash
# Jalankan sebagai root untuk memperbaiki login user lfs

set -e

echo "🔧 Memperbaiki .bash_profile dan .bashrc user lfs..."

# Pastikan user lfs ada
grep '^lfs:' /etc/passwd >/dev/null || {
  echo "❌ User lfs tidak ditemukan. Buat dulu dengan 'useradd -m -s /bin/bash lfs'"
  exit 1
}

# Perbaiki .bash_profile
cat > /home/lfs/.bash_profile << "EOF"
exec env -i \
  HOME=$HOME \
  TERM=$TERM \
  PS1='\u:\w\$ ' \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /bin/bash --login
EOF

# Perbaiki .bashrc
cat > /home/lfs/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=$LFS/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

# Set permission yang benar
chown lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc
chmod 644 /home/lfs/.bash_profile /home/lfs/.bashrc

echo "✅ Berhasil memperbaiki shell login untuk user lfs. Coba: su - lfs"
