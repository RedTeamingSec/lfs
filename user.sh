#!/bin/bash
set -euo pipefail

# === CONFIG ===
LFS=/mnt/lfs
LFS_USER=lfs
LFS_GROUP=lfs
LFS_HOME=/home/$LFS_USER

# === CEK ROOT ===
if [[ $EUID -ne 0 ]]; then
  echo "🛑 Script ini harus dijalankan sebagai root!"
  exit 1
fi

# === BUAT GRUP DAN USER ===
if ! getent group $LFS_GROUP > /dev/null; then
  groupadd $LFS_GROUP
  echo "✅ Grup '$LFS_GROUP' dibuat."
else
  echo "✅ Grup '$LFS_GROUP' sudah ada."
fi

if ! id $LFS_USER &>/dev/null; then
  useradd -s /bin/bash -g $LFS_GROUP -m -k /dev/null $LFS_USER
  echo "✅ User '$LFS_USER' dibuat."
  passwd $LFS_USER
else
  echo "✅ User '$LFS_USER' sudah ada."
fi

# === PERMISSION DIREKTORI ===
mkdir -pv $LFS/{sources,tools}
chown -v $LFS_USER:$LFS_GROUP $LFS/{sources,tools}
chmod -v a+wt $LFS/sources

# === SET .bashrc UNTUK USER LFS ===
su - $LFS_USER -c bash << 'EOF'
cat > ~/.bashrc << 'EOM'
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=$LFS/tools/bin:$PATH
export MAKEFLAGS="-j$(nproc)"
EOM
EOF

# === SET .bash_profile UNTUK USER LFS ===
su - $LFS_USER -c bash << 'EOF'
cat > ~/.bash_profile << 'EOM'
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /bin/bash --login
EOM
EOF

echo -e "\n🎉 Selesai: User 'lfs' siap dipakai.\n"
echo "👉 Sekarang jalankan:"
echo "   su - lfs"
echo "   echo \$LFS      # Harus output: /mnt/lfs"
