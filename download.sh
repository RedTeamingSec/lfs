#!/bin/bash
set -e

cd $LFS/sources

# Unduh daftar file dan checksum dari situs resmi LFS
wget -nc https://www.linuxfromscratch.org/lfs/downloads/11.2/wget-list
wget -nc https://www.linuxfromscratch.org/lfs/downloads/11.2/md5sums

# Unduh semua file sumber berdasarkan wget-list
wget --input-file=wget-list --continue --directory-prefix=.

# Verifikasi md5 checksum
echo "🔍 Mengecek integritas paket dengan md5sums..."
md5sum -c md5sums
