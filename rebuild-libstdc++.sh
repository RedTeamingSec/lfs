#!/bin/bash
set -e

echo "🔧 Rebuilding libstdc++ untuk target $LFS_TGT"

# Validasi environment
if [ -z "$LFS" ] || [ -z "$LFS_TGT" ]; then
  echo "❌ Environment belum aktif. Jalankan: source ~/.bash_profile"
  exit 1
fi

cd $LFS/sources

# Extract ulang source gcc
rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
cd libstdc++-v3

mkdir -v build && cd build

# Konfigurasi build
../configure \
  --host=$LFS_TGT \
  --prefix=/usr \
  --disable-multilib \
  --disable-nls \
  --disable-libstdcxx-pch \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++

make
make DESTDIR=$LFS install

echo "✅ libstdc++ berhasil diinstall ke $LFS/usr/lib"
