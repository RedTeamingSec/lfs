#!/bin/bash

# Versi minimal yang dibutuhkan LFS 11.2 (dari buku LFS)
declare -A REQUIRED_VERSIONS=(
    ["bash"]="5.1.8"
    ["binutils"]="2.38"
    ["bison"]="3.8.2"
    ["coreutils"]="8.32"
    ["gawk"]="5.1.1"
    ["gcc"]="11.2.0"
    ["glibc"]="2.36"
    ["grep"]="3.7"
    ["gzip"]="1.10"
    ["m4"]="1.4.19"
    ["make"]="4.3"
    ["patch"]="2.7.6"
    ["sed"]="4.8"
    ["tar"]="1.34"
)

# Fungsi untuk membandingkan versi
function version_compare() {
    local current=$1
    local required=$2
    printf '%s\n%s\n' "$required" "$current" | sort -V -C
}

# Header
echo "============================================"
echo "  LFS 11.2 Dependency Checker for Debian 12"
echo "============================================"
echo

# Loop untuk cek setiap paket
for pkg in "${!REQUIRED_VERSIONS[@]}"; do
    required_ver=${REQUIRED_VERSIONS[$pkg]}
    
    # Cek versi paket (tergantung bagaimana paket mengembalikan versi)
    case $pkg in
        "glibc")
            current_ver=$(ldd --version | head -n1 | awk '{print $NF}')
            ;;
        "gcc")
            current_ver=$(gcc --version | head -n1 | awk '{print $4}')
            ;;
        "make")
            current_ver=$(make --version | head -n1 | awk '{print $3}')
            ;;
        *)
            current_ver=$($pkg --version | head -n1 | awk '{print $NF}')
            ;;
    esac

    # Bandingkan versi
    if version_compare "$current_ver" "$required_ver"; then
        echo -e "[✓] $pkg\t$current_ver\t>= $required_ver (LFS 11.2)"
    else
        echo -e "[✗] $pkg\t$current_ver\t< $required_ver (MINIMAL: $required_ver)"
    fi
done

echo
echo "Catatan:"
echo "1. Jika ada tanda [✗], versi paket tidak memenuhi syarat LFS 11.2."
echo "2. Untuk LFS, disarankan menggunakan versi TEPAT seperti yang tercantum di buku."
echo "3. Beberapa paket (seperti GCC) mungkin perlu dikompilasi manual untuk versi spesifik."
