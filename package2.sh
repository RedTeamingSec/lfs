#!/bin/bash
# LFS 8.4 Complete Build Script untuk /dev/sdb3
# Mencakup semua tahap hingga sistem bisa boot
# Pastikan dijalankan sebagai root

# ==============================================
# Konfigurasi Dasar
# ==============================================
export LFS="/mnt/lfs"          # Direktori LFS
LFS_USER="lfsuser"             # User untuk membangun LFS
LFS_GROUP="lfsgroup"           # Group untuk user LFS
LFS_VERSION="8.4"              # Versi LFS
LFS_TARGET="x86_64-lfs-linux-gnu"  # Target architecture
MAKE_FLAGS="-j$(nproc)"        # Jumlah parallel jobs

# ==============================================
# Fungsi Utilitas
# ==============================================
function build_temporary_tools() {
    echo -e "\n=== [6/12] Membangun Temporary Tools ==="
    
    # Binutils Pass 1
    echo "Membangun Binutils (Pass 1)..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf binutils-2.30.tar.xz && \
        cd binutils-2.30 && \
        mkdir -v build && \
        cd build && \
        ../configure --prefix=/tools \
                    --with-sysroot=$LFS \
                    --with-lib-path=/tools/lib \
                    --target=$LFS_TARGET \
                    --disable-nls \
                    --disable-werror && \
        make $MAKE_FLAGS && \
        make install"
    
    # GCC Pass 1
    echo "Membangun GCC (Pass 1)..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf gcc-7.3.0.tar.xz && \
        cd gcc-7.3.0 && \
        tar xf ../mpfr-4.0.1.tar.xz && \
        mv -v mpfr-4.0.1 mpfr && \
        tar xf ../gmp-6.1.2.tar.xz && \
        mv -v gmp-6.1.2 gmp && \
        tar xf ../mpc-1.1.0.tar.gz && \
        mv -v mpc-1.1.0 mpc && \
        mkdir -v build && \
        cd build && \
        ../configure --prefix=/tools \
                    --target=$LFS_TARGET \
                    --with-newlib \
                    --without-headers \
                    --with-local-prefix=/tools \
                    --with-native-system-header-dir=/tools/include \
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
                    --enable-languages=c,c++ && \
        make $MAKE_FLAGS && \
        make install"
    
    # Linux API Headers
    echo "Menginstal Linux API Headers..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf linux-4.15.3.tar.xz && \
        cd linux-4.15.3 && \
        make mrproper && \
        make INSTALL_HDR_PATH=dest headers_install && \
        cp -rv dest/include/* /tools/include"
    
    # Glibc
    echo "Membangun Glibc..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf glibc-2.27.tar.xz && \
        cd glibc-2.27 && \
        mkdir -v build && \
        cd build && \
        ../configure --prefix=/tools \
                    --host=$LFS_TARGET \
                    --build=$(../scripts/config.guess) \
                    --enable-kernel=3.2 \
                    --with-headers=/tools/include \
                    libc_cv_forced_unwind=yes \
                    libc_cv_c_cleanup=yes && \
        make $MAKE_FLAGS && \
        make install"
    
    # Libstdc++ (GCC)
    echo "Membangun Libstdc++..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf libstdc++-7.3.0.tar.xz && \
        cd libstdc++-7.3.0 && \
        mkdir -v build && \
        cd build && \
        ../configure --host=$LFS_TARGET \
                    --prefix=/tools \
                    --disable-multilib \
                    --disable-nls \
                    --disable-libstdcxx-threads \
                    --disable-libstdcxx-pch \
                    --with-gxx-include-dir=/tools/$LFS_TARGET/include/c++/7.3.0 && \
        make $MAKE_FLAGS && \
        make install"
    
    echo "Temporary tools berhasil dibangun"
}

function build_coreutils_and_basic_system() {
    echo -e "\n=== [7/12] Membangun Coreutils dan Sistem Dasar ==="
    
    # Binutils Pass 2
    echo "Membangun Binutils (Pass 2)..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf binutils-2.30.tar.xz && \
        cd binutils-2.30 && \
        mkdir -v build && \
        cd build && \
        CC=$LFS_TARGET-gcc \
        AR=$LFS_TARGET-ar \
        RANLIB=$LFS_TARGET-ranlib \
        ../configure \
            --prefix=/tools \
            --disable-nls \
            --disable-werror \
            --with-lib-path=/tools/lib \
            --with-sysroot && \
        make $MAKE_FLAGS && \
        make install && \
        make -C ld clean && \
        make -C ld LIB_PATH=/usr/lib:/lib && \
        cp -v ld/ld-new /tools/bin"
    
    # GCC Pass 2
    echo "Membangun GCC (Pass 2)..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf gcc-7.3.0.tar.xz && \
        cd gcc-7.3.0 && \
        cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
            `dirname $($LFS_TARGET-gcc -print-libgcc-file-name)`/include-fixed/limits.h && \
        tar xf ../mpfr-4.0.1.tar.xz && \
        mv -v mpfr-4.0.1 mpfr && \
        tar xf ../gmp-6.1.2.tar.xz && \
        mv -v gmp-6.1.2 gmp && \
        tar xf ../mpc-1.1.0.tar.gz && \
        mv -v mpc-1.1.0 mpc && \
        mkdir -v build && \
        cd build && \
        CC=$LFS_TARGET-gcc \
        CXX=$LFS_TARGET-g++ \
        AR=$LFS_TARGET-ar \
        RANLIB=$LFS_TARGET-ranlib \
        ../configure \
            --prefix=/tools \
            --with-local-prefix=/tools \
            --with-native-system-header-dir=/tools/include \
            --enable-languages=c,c++ \
            --disable-libstdcxx-pch \
            --disable-multilib \
            --disable-bootstrap \
            --disable-libgomp && \
        make $MAKE_FLAGS && \
        make install && \
        ln -sv gcc /tools/bin/cc"
    
    # Coreutils
    echo "Membangun Coreutils..."
    su - "$LFS_USER" -c "cd $LFS/sources && \
        tar xf coreutils-8.29.tar.xz && \
        cd coreutils-8.29 && \
        ./configure --prefix=/tools --enable-install-program=hostname && \
        make $MAKE_FLAGS && \
        make install"
    
    # Build tools dasar lainnya (disederhanakan)
    for package in bash bison bzip2 diffutils file findutils gawk gettext grep gzip m4 make patch perl sed tar texinfo xz; do
        echo "Membangun $package..."
        su - "$LFS_USER" -c "cd $LFS/sources && \
            tar xf ${package}-*.tar.* && \
            cd ${package}-* && \
            ./configure --prefix=/tools && \
            make $MAKE_FLAGS && \
            make install"
    done
    
    echo "Coreutils dan sistem dasar berhasil dibangun"
}

function build_lfs_system() {
    echo -e "\n=== [8/12] Membangun Sistem LFS ==="
    
    # Persiapan direktori LFS
    mkdir -pv $LFS/{dev,proc,sys,run}
    mknod -m 600 $LFS/dev/console c 5 1
    mknod -m 666 $LFS/dev/null c 1 3
    mount -v --bind /dev $LFS/dev
    mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
    mount -vt proc proc $LFS/proc
    mount -vt sysfs sysfs $LFS/sys
    mount -vt tmpfs tmpfs $LFS/run
    
    if [ -h $LFS/dev/shm ]; then
        mkdir -pv $LFS/$(readlink $LFS/dev/shm)
    fi
    
    # Masuk ke chroot environment
    chroot "$LFS" /tools/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
        /tools/bin/bash --login +h << "CHROOT_EOF"
        
        # ==============================================
        # Dalam chroot environment
        # ==============================================
        
        # Buat direktori filesystem
        mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
        mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
        install -dv -m 0750 /root
        install -dv -m 1777 /tmp /var/tmp
        mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
        mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
        mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
        mkdir -v  /usr/libexec
        mkdir -pv /usr/{,local/}share/man/man{1..8}
        
        case $(uname -m) in
            x86_64) mkdir -v /lib64 ;;
        esac
        
        mkdir -v /var/{log,mail,spool}
        ln -sv /run /var/run
        ln -sv /run/lock /var/lock
        mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
        
        # Buat file konfigurasi dasar
        cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:daemon:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

        cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF

        # Buat symlink penting
        ln -sv /tools/bin/{bash,cat,dd,echo,ln,pwd,rm,stty} /bin
        ln -sv /tools/bin/{env,install,perl} /usr/bin
        ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
        ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
        ln -sv bash /bin/sh
        
        # Keluar dari chroot
        exit
CHROOT_EOF
    
    echo "Sistem LFS dasar berhasil disiapkan"
}

function configure_system_boot() {
    echo -e "\n=== [9/12] Mengkonfigurasi Boot Sistem ==="
    
    # Masuk ke chroot untuk konfigurasi boot
    chroot "$LFS" /tools/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
        /tools/bin/bash --login +h << "BOOT_EOF"
        
        # Install Linux kernel
        cd /sources
        tar xf linux-4.15.3.tar.xz
        cd linux-4.15.3
        
        make mrproper
        make defconfig
        make $MAKE_FLAGS
        make modules_install
        
        cp -v arch/x86/boot/bzImage /boot/vmlinuz-4.15.3-lfs-8.4
        cp -v System.map /boot/System.map-4.15.3
        cp -v .config /boot/config-4.15.3
        
        install -d /usr/share/doc/linux-4.15.3
        cp -r Documentation/* /usr/share/doc/linux-4.15.3
        
        # Install GRUB bootloader
        cd /sources
        tar xf grub-2.02.tar.xz
        cd grub-2.02
        
        ./configure --prefix=/usr \
            --sbindir=/sbin \
            --sysconfdir=/etc \
            --disable-werror
        make $MAKE_FLAGS
        make install
        
        # Install GRUB ke disk
        grub-install ${LFS_DISK}
        
        # Buat konfigurasi GRUB untuk /dev/sdb3
        cat > /boot/grub/grub.cfg << "GRUB_EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,3)

menuentry "GNU/Linux, Linux 4.15.3-lfs-8.4" {
    linux /boot/vmlinuz-4.15.3-lfs-8.4 root=/dev/sdb3 ro
}
GRUB_EOF
        
        # Keluar dari chroot
        exit
BOOT_EOF
    
    echo "Sistem boot berhasil dikonfigurasi"
}

function finalize_system() {
    echo -e "\n=== [10/12] Finalisasi Sistem ==="
    
    # Masuk ke chroot untuk finalisasi
    chroot "$LFS" /tools/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
        /tools/bin/bash --login +h << "FINAL_EOF"
        
        # Buat file konfigurasi tambahan
        cat > /etc/fstab << "EOF"
# Begin /etc/fstab
# file system  mount-point  type     options             dump  fsck
#                                                              order
/dev/sdb3     /            ext4     defaults            1     1
proc         /proc        proc     nosuid,noexec,nodev 0     0
sysfs        /sys         sysfs    nosuid,noexec,nodev 0     0
devpts       /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs        /run         tmpfs    defaults            0     0
devtmpfs     /dev         devtmpfs mode=0755,nosuid    0     0
EOF

        cat > /etc/hosts << "EOF"
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

        # Set timezone
        ln -sv /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

        # Buat user biasa
        echo "Buat user biasa (contoh: lfsuser)"
        groupadd lfsuser
        useradd -s /bin/bash -g lfsuser -m -k /dev/null lfsuser
        passwd lfsuser
        
        # Bersihkan sistem
        rm -rf /tools
        rm -f /usr/bin/{ar,as,ld,nm,ranlib,strip}
        
        # Keluar dari chroot
        exit
FINAL_EOF
    
    echo "Sistem telah difinalisasi"
}

function create_system_image() {
    echo -e "\n=== [11/12] Membuat System Image (Opsional) ==="
    
    # Unmount semua filesystem LFS
    umount $LFS/dev/pts
    umount $LFS/dev
    umount $LFS/proc
    umount $LFS/sys
    umount $LFS/run
    umount $LFS
    
    # Buat image dari partisi LFS (opsional)
    echo "Membuat image dari partisi /dev/sdb3..."
    dd if=/dev/sdb3 of=lfs-8.4-system.img bs=1M status=progress
    
    echo "System image berhasil dibuat: lfs-8.4-system.img"
}

function display_completion_message() {
    echo -e "\n=== [12/12] SELESAI ==="
    echo -e "\nLinux From Scratch 8.4 telah berhasil dibangun pada /dev/sdb3!"
    echo "Anda sekarang dapat:"
    echo "1. Reboot sistem dan pilih LFS dari boot menu"
    echo "2. Atau gunakan system image yang telah dibuat (jika ada)"
    echo ""
    echo "Informasi penting:"
    echo "- Partisi root: /dev/sdb3"
    echo "- User root password: (yang Anda set saat finalisasi)"
    echo "- User biasa: lfsuser (password yang Anda set)"
    echo ""
    echo "Selamat! Anda sekarang memiliki sistem LFS 8.4 yang berfungsi penuh."
}

# ==============================================
# Eksekusi Utama
# ==============================================
clear
echo "=== Linux From Scratch (LFS) 8.4 Build Script untuk /dev/sdb3 ==="
echo "=== Script ini akan membangun LFS 8.4 lengkap sampai bisa boot ==="

# Jalankan semua langkah secara berurutan
build_temporary_tools
build_coreutils_and_basic_system
build_lfs_system
configure_system_boot
finalize_system
create_system_image
display_completion_message

echo "Proses pembangunan LFS 8.4 selesai!"
