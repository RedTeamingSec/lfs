#!/bin/bash
set -e

echo "📦 Memulai build Glibc dan Libstdc++"

# Validasi environment
if [ -z "$LFS" ] || [ -z "$LFS_TGT" ]; then
  echo "❌ Environment LFS belum diatur. Jalankan 'source ~/.bash_profile'"
  exit 1
fi

cd $LFS/sources

##########################
# 1. Build & Install Glibc
##########################
echo "🔧 [1/2] Build Glibc"

rm -rf glibc-2.36
tar -xf glibc-2.36.tar.xz
cd glibc-2.36

case $(uname -m) in
  i?86) ln -sfv ld-2.36.so $LFS/lib/ld-linux.so.2 ;;
  x86_64) ln -sfv ../lib/ld-2.36.so $LFS/lib64 ;;
esac

mkdir -v build
cd build

../configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(../scripts/config.guess) \
  --enable-kernel=4.14 \
  --with-headers=$LFS/usr/include \
  libc_cv_slibdir=/usr/lib

make
make DESTDIR=$LFS install

echo "✅ Glibc selesai dibangun dan terinstal"

# Buat file /etc/nsswitch.conf di dalam $LFS
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

############################
# 2. Build & Install Libstdc++
############################
echo "🔧 [2/2] Build libstdc++ (C++)"

rm -rf gcc-12.2.0
tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
tar -xf ../mpfr-4.2.0.tar.xz && mv mpfr-4.2.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz && mv gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz && mv mpc-1.2.1 mpc

cd libstdc++-v3
mkdir -v build
cd build

../configure --host=$LFS_TGT \
  --prefix=/usr \
  --disable-multilib \
  --disable-nls \
  --disable-libstdcxx-pch \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf gcc-12.2.0

echo "✅ Libstdc++ selesai dibangun dan terinstal"

echo -e "\n🎉 DONE: Glibc dan Libstdc++ berhasil diinstal ke $LFS"
