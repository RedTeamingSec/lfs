#!/bin/bash
set -e

# === Environment ===
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=$LFS/tools/bin:$PATH
export MAKEFLAGS="-j$(nproc)"

cd $LFS/sources

extract() {
  tar -xf "$1"
  cd "${1%.tar.*}"
}

cleanup() {
  cd $LFS/sources
  rm -rf "${1%.tar.*}"
}

# === 1. Binutils Pass 1 ===
extract binutils-2.39.tar.xz
mkdir -v build && cd build
../configure --prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT --disable-nls --disable-werror
make
make install
cd ../..
cleanup binutils-2.39.tar.xz

# === 2. GCC Pass 1 ===
extract gcc-12.2.0.tar.xz
tar -xf ../mpfr-4.1.0.tar.xz && mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz  && mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz  && mv -v mpc-1.2.1 mpc

mkdir -v build && cd build
../configure --target=$LFS_TGT --prefix=$LFS/tools \
  --with-glibc-version=2.36 --with-sysroot=$LFS \
  --with-newlib --without-headers --enable-initfini-array \
  --disable-nls --disable-shared --disable-multilib \
  --disable-decimal-float --disable-threads \
  --disable-libatomic --disable-libgomp --disable-libquadmath \
  --disable-libssp --disable-libvtv --disable-libstdcxx \
  --enable-languages=c
make
make install
cd ../..
cleanup gcc-12.2.0.tar.xz

# === 3. Linux API Headers ===
extract linux-5.19.2.tar.xz
make mrproper
make headers
find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include $LFS/usr
cd ..
cleanup linux-5.19.2.tar.xz

# === 4. Glibc ===
extract glibc-2.36.tar.xz
mkdir -v build && cd build
../configure --prefix=/usr --host=$LFS_TGT \
  --build=$(../scripts/config.guess) \
  --enable-kernel=3.2 --with-headers=$LFS/usr/include \
  libc_cv_slibdir=/lib
make
make DESTDIR=$LFS install
cd ../..
cleanup glibc-2.36.tar.xz

# === 5. GCC Pass 2 ===
extract gcc-12.2.0.tar.xz
cd gcc-12.2.0
tar -xf ../mpfr-4.1.0.tar.xz && mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz && mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz && mv -v mpc-1.2.1 mpc

mkdir -v build && cd build
../configure --build=$(../config.guess) --host=$LFS_TGT --target=$LFS_TGT \
  --prefix=$LFS/tools --enable-languages=c,c++ \
  --disable-multilib --disable-bootstrap --disable-libgomp
make
make install
cd ../../
cleanup gcc-12.2.0.tar.xz

# === 6. Libstdc++ ===
extract gcc-12.2.0.tar.xz
cd gcc-12.2.0
mkdir -v build && cd build
../libstdc++-v3/configure \
  --host=$LFS_TGT --build=$(../config.guess) \
  --prefix=/usr --disable-multilib --disable-nls \
  --enable-libstdcxx-time=yes \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++
make
make DESTDIR=$LFS install
cd ../../
cleanup gcc-12.2.0.tar.xz

echo -e "\n✅ Toolchain LFS 11.2 (gcc 12.2.0, glibc 2.36, binutils 2.39) berhasil dibangun!"
