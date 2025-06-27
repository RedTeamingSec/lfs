#!/bin/bash
set -e

echo "==> [0] Menyiapkan .bash_profile dan .bashrc..."

# ==========================
# === .bash_profile Toolchain
# ==========================
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# ==========================
# === .bashrc Toolchain
# ==========================
cat > ~/.bashrc << "EOF"
set +h
umask 022

LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=$LFS/tools/bin:/bin:/usr/bin
MAKEFLAGS="-j$(nproc)"
LC_ALL=POSIX

export LFS LC_ALL LFS_TGT PATH MAKEFLAGS
EOF

# Terapkan environment
source ~/.bash_profile

# Validasi variabel
if [ -z "$LFS" ] || [ -z "$LFS_TGT" ]; then
  echo "❌ Environment LFS belum aktif dengan benar!"
  exit 1
fi

# =====================
# === GCC PASS 2    ===
# =====================
echo "==> [1/5] Building GCC Pass 2..."

cd $LFS/sources
rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0

rm -f gcc/include/{limits.h,float.h}
tar -xf ../mpfr-4.2.0.tar.xz && mv mpfr-4.2.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz && mv gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz && mv mpc-1.2.1 mpc

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

make -j$(nproc)
make install

echo "==> GCC Pass 2 selesai."

# =====================
# === libstdc++     ===
# =====================
echo "==> [2/5] Building libstdc++..."

cd $LFS/sources
rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0/libstdc++-v3

mkdir -v build
cd build

../configure                             \
  --host=$LFS_TGT                        \
  --prefix=$LFS/usr                      \
  --disable-multilib                     \
  --disable-nls                          \
  --disable-libstdcxx-pch                \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++

make -j$(nproc)
make install

cd $LFS/sources
rm -rf gcc-12.2.0

echo "==> libstdc++ selesai."

# =====================
# === linux-headers ===
# =====================
echo "==> [3/5] Installing Linux API Headers..."

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

echo "==> Linux headers selesai."

# =====================
# === glibc          ===
# =====================
echo "==> [4/5] Building glibc..."

cd $LFS/sources
rm -rf glibc-2.36
tar -xf glibc-2.36.tar.xz
cd glibc-2.36

case $(uname -m) in
  i?86)   ln -sfv ld-2.36.so $LFS/lib/ld-linux.so.2 ;;
  x86_64) ln -sfv ../lib/ld-2.36.so $LFS/lib64 ;;
esac

mkdir -v build
cd build

../configure                              \
  --prefix=/usr                           \
  --host=$LFS_TGT                         \
  --build=$(../scripts/config.guess)     \
  --enable-kernel=4.14                    \
  --with-headers=$LFS/usr/include        \
  libc_cv_slibdir=/usr/lib

make -j$(nproc)
make DESTDIR=$LFS install

echo "=> Menambahkan /etc/nsswitch.conf..."
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

echo "==> glibc selesai."

# =====================
# === Binutils (bab 6)
# =====================
echo "==> [5/5] Building Binutils (Bab 6)..."

cd $LFS/sources
rm -rf binutils-2.39
tar -xf binutils-2.39.tar.xz
cd binutils-2.39

mkdir -v build
cd build

../configure               \
  --prefix=/usr            \
  --build=$(../config.guess) \
  --host=$LFS_TGT          \
  --disable-nls            \
  --enable-shared          \
  --disable-werror         \
  --enable-64-bit-bfd

make -j$(nproc)
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf binutils-2.39

echo "✅ Semua selesai: .bashrc, GCC Pass 2, libstdc++, linux-headers, glibc, dan binutils (Bab 6) telah dibangun!"
