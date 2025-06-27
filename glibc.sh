#!/bin/bash
set -e

echo "📦 [LFS] Build Toolchain Lengkap (Urutan Resmi)"

# ==== 0. Setup Environment ====
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022

LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
LC_ALL=POSIX
MAKEFLAGS="-j$(nproc)"
PATH=$LFS/tools/bin:/bin:/usr/bin

export LFS LFS_TGT LC_ALL MAKEFLAGS PATH
EOF

source ~/.bash_profile

if [ -z "$LFS" ] || [ -z "$LFS_TGT" ]; then
  echo "❌ Environment belum aktif!"
  exit 1
fi

cd $LFS/sources

# ==== 1. Binutils Pass 1 ====
echo "🔧 [1/7] Binutils Pass 1"

tar -xf binutils-2.39.tar.xz
cd binutils-2.39
mkdir -v build
cd build

../configure --prefix=$LFS/tools \
  --with-sysroot=$LFS \
  --target=$LFS_TGT \
  --disable-nls \
  --disable-werror

make
make install
cd $LFS/sources
rm -rf binutils-2.39

# ==== 2. GCC Pass 1 ====
echo "🔧 [2/7] GCC Pass 1"

tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
tar -xf ../mpfr-4.2.0.tar.xz && mv mpfr-4.2.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz && mv gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz && mv mpc-1.2.1 mpc

sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
mkdir -v build && cd build

../configure --target=$LFS_TGT --prefix=$LFS/tools \
  --with-glibc-version=2.36 --with-newlib --without-headers \
  --enable-initfini-array --disable-nls --disable-shared \
  --disable-multilib --disable-decimal-float --disable-threads \
  --disable-libatomic --disable-libgomp --disable-libquadmath \
  --disable-libssp --disable-libvtv --disable-libstdcxx \
  --enable-languages=c

make
make install
cd $LFS/sources
rm -rf gcc-12.2.0

# ==== 3. Linux API Headers ====
echo "🔧 [3/7] Linux Headers"

tar -xf linux-5.19.2.tar.xz
cd linux-5.19.2
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr
cd $LFS/sources
rm -rf linux-5.19.2

# ==== 4. Glibc ====
echo "🔧 [4/7] Glibc"

tar -xf glibc-2.36.tar.xz
cd glibc-2.36

case $(uname -m) in
  i?86) ln -sfv ld-2.36.so $LFS/lib/ld-linux.so.2 ;;
  x86_64) ln -sfv ../lib/ld-2.36.so $LFS/lib64 ;;
esac

mkdir -v build && cd build

../configure --prefix=/usr --host=$LFS_TGT \
  --build=$(../scripts/config.guess) \
  --enable-kernel=4.14 --with-headers=$LFS/usr/include \
  libc_cv_slibdir=/usr/lib

make
make DESTDIR=$LFS install

cat > $LFS/etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF
cd $LFS/sources
rm -rf glibc-2.36

# ==== 5. Libstdc++ ====
echo "🔧 [5/7] libstdc++"

tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
cd libstdc++-v3
mkdir -v build && cd build

../configure --host=$LFS_TGT --prefix=/usr \
  --disable-multilib --disable-nls --disable-libstdcxx-pch \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++

make
make DESTDIR=$LFS install
cd $LFS/sources
rm -rf gcc-12.2.0

# ==== 6. Binutils Pass 2 ====
echo "🔧 [6/7] Binutils Pass 2"

tar -xf binutils-2.39.tar.xz
cd binutils-2.39
mkdir -v build && cd build

../configure --prefix=/usr --build=$(../config.guess) \
  --host=$LFS_TGT --disable-nls --enable-shared \
  --enable-64-bit-bfd

make
make DESTDIR=$LFS install
cd $LFS/sources
rm -rf binutils-2.39

# ==== 7. GCC Pass 2 ====
echo "🔧 [7/7] GCC Pass 2"

tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
tar -xf ../mpfr-4.2.0.tar.xz && mv mpfr-4.2.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz && mv gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz && mv mpc-1.2.1 mpc
mkdir -v build && cd build

../configure --build=$(../config.guess) --host=$LFS_TGT \
  --target=$LFS_TGT --prefix=/usr --disable-nls \
  --enable-languages=c,c++ --disable-libstdcxx-pch \
  --disable-multilib --disable-bootstrap --with-system-zlib

make
make DESTDIR=$LFS install
cd $LFS/sources
rm -rf gcc-12.2.0

echo -e "\n✅ Toolchain lengkap selesai (binutils, gcc, headers, glibc, libstdc++)!"
