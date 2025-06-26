#!/bin/bash
set -e

# === Variabel Dasar ===
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export MAKEFLAGS="-j$(nproc)"
cd $LFS/sources

extract_tar() {
  tar -xf "$1"
  cd $(tar -tf "$1" | head -1 | cut -d/ -f1)
}

# === 1. Binutils Pass 1 ===
echo "🔧 Building Binutils-2.39 (Pass 1)"
extract_tar binutils-2.39.tar.xz
mkdir -v build && cd build
../configure --prefix=$LFS/tools \
  --with-sysroot=$LFS \
  --target=$LFS_TGT \
  --disable-nls \
  --enable-gprofng=no \
  --disable-werror
make
make install
cd $LFS/sources && rm -rf binutils-2.39

# === 2. GCC Pass 1 ===
echo "🔧 Building GCC-12.2.0 (Pass 1)"
extract_tar gcc-12.2.0.tar.xz
tar -xf ../mpfr-4.1.0.tar.xz && mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz && mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz && mv -v mpc-1.2.1 mpc

mkdir -v build && cd build
../configure --target=$LFS_TGT \
  --prefix=$LFS/tools \
  --with-glibc-version=2.36 \
  --with-sysroot=$LFS \
  --with-newlib \
  --without-headers \
  --enable-initfini-array \
  --disable-nls \
  --disable-shared \
  --disable-multilib \
  --disable-decimal-float \
  --disable-threads \
  --disable-libatomic \
  --disable-libgomp \
  --disable-libquadmath \
  --disable-libssp \
  --disable-libvtv \
  --disable-libstdcxx \
  --enable-languages=c
make
make install
cd $LFS/sources && rm -rf gcc-12.2.0

# === 3. Linux API Headers ===
echo "🔧 Installing Linux API Headers (5.19.2)"
extract_tar linux-5.19.2.tar.xz
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr
cd $LFS/sources && rm -rf linux-5.19.2

# === 4. Glibc ===
echo "🔧 Building Glibc-2.36"
extract_tar glibc-2.36.tar.xz
mkdir -v build && cd build
../configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(../scripts/config.guess) \
  --enable-kernel=3.2 \
  --with-headers=$LFS/usr/include \
  libc_cv_slibdir=/lib
make
make DESTDIR=$LFS install
cd $LFS/sources && rm -rf glibc-2.36

# === 5. Libstdc++ dari GCC ===
echo "🔧 Building libstdc++ dari GCC-12.2.0"
extract_tar gcc-12.2.0.tar.xz
cd libstdc++-v3
mkdir -v build && cd build
../configure --host=$LFS_TGT \
  --prefix=$LFS/usr \
  --disable-multilib \
  --disable-nls \
  --disable-libstdcxx-pch \
  --with-gxx-include-dir=$LFS/usr/include/c++/12.2.0
make
make DESTDIR=$LFS install
cd $LFS/sources && rm -rf gcc-12.2.0

echo "✅ Toolchain selesai! Siap lanjut ke Bab 6 (Final System)."
