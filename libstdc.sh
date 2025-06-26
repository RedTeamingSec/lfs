#!/bin/bash
set -e

# === Environment ===
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=$LFS/tools/bin:$PATH
export MAKEFLAGS="-j$(nproc)"
cd $LFS/sources
rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
tar -xf ../mpfr-4.1.0.tar.xz
tar -xf ../gmp-6.2.1.tar.xz
tar -xf ../mpc-1.2.1.tar.gz
mv mpfr-4.1.0 mpfr
mv gmp-6.2.1 gmp
mv mpc-1.2.1 mpc

mkdir -v build && cd build

../libstdc++-v3/configure \
  --host=$LFS_TGT --build=$(../config.guess) \
  --prefix=/usr \
  --disable-multilib --disable-nls \
  --enable-libstdcxx-time=yes \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++

make -j$(nproc)
make DESTDIR=$LFS install

