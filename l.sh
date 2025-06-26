#!/bin/bash
set -e

# Pastikan variabel lingkungan sudah diset
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu

cd $LFS/sources

### ===== 1. Bangun libstdc++ dari gcc-12.2.0 (Langkah 5 Toolchain) =====
echo "=== [1] Ekstrak dan konfigurasi libstdc++ ==="
rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0

tar -xf ../mpfr-4.1.0.tar.xz
mv -v mpfr-4.1.0 mpfr

tar -xf ../gmp-6.2.1.tar.xz
mv -v gmp-6.2.1 gmp

tar -xf ../mpc-1.2.1.tar.gz
mv -v mpc-1.2.1 mpc

cd libstdc++-v3
mkdir -v build
cd build

../configure                   \
  --host=$LFS_TGT              \
  --prefix=$LFS/usr            \
  --disable-multilib           \
  --disable-nls                \
  --disable-libstdcxx-pch      \
  --with-gxx-include-dir=$LFS/usr/include/c++/12.2.0

make
make DESTDIR=$LFS install

echo "=== [✓] Selesai build libstdc++ ==="

### ===== 2. Bangun glibc-2.36 =====
cd $LFS/sources
rm -rf glibc-2.36
tar -xf glibc-2.36.tar.xz
cd glibc-2.36

mkdir -v build
cd build

echo "=== [2] Konfigurasi glibc ==="
../configure                             \
  --prefix=/usr                          \
  --host=$LFS_TGT                        \
  --build=$(../scripts/config.guess)    \
  --enable-kernel=3.2                    \
  --with-headers=$LFS/usr/include        \
  libc_cv_slibdir=/lib

make
make DESTDIR=$LFS install

echo "=== [✓] Selesai build glibc ==="
