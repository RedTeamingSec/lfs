cat > /home/lfs/setup-lfs-env.sh << "EOF"
#!/bin/bash
# Script ini dijalankan oleh root untuk men-setup environment user lfs

cat > /home/lfs/.bash_profile << "EOL"
exec env -i HOME=\$HOME TERM=\$TERM PS1='\\u:\\w\\$ ' /bin/bash
EOL

cat > /home/lfs/.bashrc << "EOL"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=\$(uname -m)-lfs-linux-gnu
PATH=\$LFS/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOL

chown lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc
chmod 644 /home/lfs/.bash_profile /home/lfs/.bashrc
echo "File .bashrc dan .bash_profile berhasil dibuat untuk user lfs."
EOF

chmod +x /home/lfs/setup-lfs-env.sh
