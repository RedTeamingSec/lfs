#!/bin/bash
set -e

echo "📦 [LFS] Setup Environment dan Toolchain Lengkap"

# ====== 1. Siapkan ~/.bash_profile dan ~/.bashrc untuk user lfs ======
echo "==> Menyiapkan .bash_profile dan .bashrc..."

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

# ====== Validasi environment ======
if [ -z "$LFS" ] || [ -z "$LFS_TGT" ]; then
  echo "❌ Environment \$LFS atau \$LFS_TGT tidak aktif!"
  exit 1
fi

# ====== 2. GCC Pass 1 ======
echo "==> [1/6] Building GCC Pass 1..."

cd $LFS/sources
rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0

tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz
mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz
mv -v mpc-1.2.1 mpc

sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64

mkdir -v build
cd build

../configure --target=$LFS_TGT --prefix=$LFS/tools \
  --with-glibc-version=2.36 \
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

cd $LFS/sources
rm -rf gcc-12.2.0

# ====== 3. Binutils (Pass 2) ======
echo "==> [2/6] Building Binutils Pass 2..."

cd $LFS/sources
rm -rf binutils-2.39
tar -xf binutils-2.39.tar.xz
cd binutils-2.39

mkdir -v build
cd build

../configure --prefix=$LFS/tools \
  --build=$(../config.guess) \
  --host=$LFS_TGT \
  --disable-nls \
  --enable-shared \
  --disable-werror \
  --enable-64-bit-bfd

make
make install

cd $LFS/sources
rm -rf binutils-2.39

# ====== 4. GCC Pass 2 ======
echo "==> [3/6] Building GCC Pass 2..."

cd $LFS/sources
rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0

tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz
mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz
mv -v mpc-1.2.1 mpc

mkdir -v build
cd build

../configure                                       \
  --build=$(../config.guess)                      \
  --host=$LFS_TGT                                  \
  --target=$LFS_TGT                                \
  --prefix=$LFS/tools                              \
  --disable-nls                                    \
  --enable-languages=c,c++                         \
  --disable-libstdcxx-pch                          \
  --disable-multilib                               \
  --disable-bootstrap                              \
  --with-system-zlib

make
make install

cd $LFS/sources
rm -rf gcc-12.2.0

# ====== 5. libstdc++ ======
echo "==> [4/6] Building libstdc++..."

cd $LFS/sources
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0/libstdc++-v3

mkdir -v build
cd build

../configure --host=$LFS_TGT --prefix=$LFS/usr \
  --disable-multilib --disable-nls \
  --disable-libstdcxx-pch \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++

make
make install

cd $LFS/sources
rm -rf gcc-12.2.0

# ====== 6. Linux API Headers ======
echo "==> [5/6] Installing Linux Headers..."

cd $LFS/sources
rm -rf linux-5.19.2
tar -xf linux-5.19.2.tar.xz
cd linux-5.19.2

make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

cd $LFS/sources
rm -rf linux-5.19.2

# ====== 7. Glibc ======
echo "==> [6/6] Building Glibc..."

cd $LFS/sources
rm -rf glibc-2.36
tar -xf glibc-2.36.tar.xz
cd glibc-2.36

case $(uname -m) in
  i?86) ln -sfv ld-2.36.so $LFS/lib/ld-linux.so.2 ;;
  x86_64) ln -sfv ../lib/ld-2.36.so $LFS/lib64 ;;
esac

mkdir -v build
cd build

../configure --prefix=/usr --host=$LFS_TGT \
  --build=$(../scripts/config.guess) \
  --enable-kernel=4.14 \
  --with-headers=$LFS/usr/include \
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

echo -e "\n✅ Toolchain selesai: GCC Pass 1, Binutils, GCC Pass 2, libstdc++, Linux Headers, dan Glibc!"
