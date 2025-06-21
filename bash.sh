#!/bin/bash
# LFS 8.4 Complete Build Script untuk /dev/sdb3
# Mencakup semua tahap hingga sistem bisa boot
# Pastikan dijalankan sebagai root

# ==============================================
# Konfigurasi Dasar
# ==============================================

export LFS="/mnt/lfs"          # Direktori LFS
LFS_USER="lfsuser"             # User untuk membangun LFS
LFS_GROUP="lfsgroup"           # Group untuk user LFS


cat > /home/"$LFS_USER"/.bashrc << EOF
set +h
umask 022
export LFS=/mnt/lfs
export LC_ALL=POSIX
export LFS_TGT=$LFS_TARGET
export PATH=/tools/bin:/bin:/usr/bin
EOF

    # Buat .bash_profile yang hanya memuat .bashrc
    cat > /home/"$LFS_USER"/.bash_profile << "EOF"
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

    chown "$LFS_USER:$LFS_GROUP" /home/"$LFS_USER"/.{bashrc,bash_profile}

    echo "Lingkungan LFS berhasil disiapkan untuk user $LFS_USER"
}
