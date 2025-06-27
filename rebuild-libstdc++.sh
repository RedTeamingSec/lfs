#!/bin/bash
set -e

echo "🔧 Rebuilding libstdc++ untuk target $LFS_TGT"

# Validasi environment
if [ -z "$LFS" ] || [ -z "$LFS_TGT" ]; then
  echo "❌ Environment belum aktif. Jalankan: source ~/.bash_profile"
  exit 1
fi

cd $LFS/sources

# ==== 4. Glibc ====
echo "🔧 [4/7] Glibc"

tar -xf glibc-2.36.tar.xz
cd glibc-2.36

# Tambahkan patch untuk masalah libstdc++
sed -i 's/-lstdc++//g' support/Makefile
sed -i 's/-lgcc_s//g' support/Makefile

case $(uname -m) in
  i?86) ln -sfv ld-2.36.so $LFS/lib/ld-linux.so.2 ;;
  x86_64) ln -sfv ../lib/ld-2.36.so $LFS/lib64 ;;
esac

mkdir -v build && cd build

../configure --prefix=/usr --host=$LFS_TGT \
  --build=$(../scripts/config.guess) \
  --enable-kernel=4.14 --with-headers=$LFS/usr/include \
  libc_cv_slibdir=/usr/lib

# Tambahkan flag ini saat make
make -j$(nproc) LDFLAGS="-nostdlib -nostartfiles"
make DESTDIR=$LFS install

# ==== 5. Libstdc++ ====
echo "🔧 [5/7] libstdc++"

tar -xf gcc-12.2.0.tar.xz
cd gcc-12.2.0
cd libstdc++-v3
mkdir -v build && cd build

../configure --host=$LFS_TGT --prefix=/usr \
  --disable-multilib --disable-nls --disable-libstdcxx-pch \
  --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/12.2.0

make -j$(nproc)
make DESTDIR=$LFS install

# Buat symlink yang diperlukan
ln -sv gcc $LFS/tools/bin/cc
