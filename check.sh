#!/bin/bash
# LFS 11.2 - Version Check Script

set -e

echo "🔍 Mengecek versi software untuk LFS 11.2..."

# Fungsi bantu
check_version() {
    local name=$1
    local version=$2
    local expected=$3
    printf "  %-12s: %-20s (diperlukan ≥ %s)\n" "$name" "$version" "$expected"
}

# 1. bash ≥ 5.0
bash_version=$(bash --version | head -n1 | cut -d" " -f4)
check_version "bash" "$bash_version" "5.0"

# 2. binutils ≥ 2.36
ld_version=$(ld --version | head -n1 | awk '{print $NF}')
check_version "ld (binutils)" "$ld_version" "2.36"

# 3. bison ≥ 3.7.5
bison_version=$(bison --version | head -n1 | awk '{print $4}')
check_version "bison" "$bison_version" "3.7.5"

# 4. bzip2 (no version, check presence)
type bzip2 &>/dev/null && echo "  bzip2       : ✔ ditemukan" || echo "  bzip2       : ❌ TIDAK ditemukan"

# 5. coreutils ≥ 8.32
coreutils_version=$(chown --version | head -n1 | awk '{print $NF}')
check_version "coreutils" "$coreutils_version" "8.32"

# 6. diffutils ≥ 3.7
diff_version=$(diff --version | head -n1 | awk '{print $NF}')
check_version "diffutils" "$diff_version" "3.7"

# 7. findutils ≥ 4.8.0
find_version=$(find --version | head -n1 | awk '{print $NF}')
check_version "findutils" "$find_version" "4.8.0"

# 8. gawk ≥ 5.1.0
gawk_version=$(gawk --version | head -n1 | awk '{print $3}')
check_version "gawk" "$gawk_version" "5.1.0"

# 9. gcc ≥ 11.2.0
gcc_version=$(gcc --version | head -n1 | awk '{print $3}')
check_version "gcc" "$gcc_version" "11.2.0"

# 10. grep ≥ 3.7
grep_version=$(grep --version | head -n1 | awk '{print $NF}')
check_version "grep" "$grep_version" "3.7"

# 11. gzip ≥ 1.10
gzip_version=$(gzip --version | head -n1 | awk '{print $2}')
check_version "gzip" "$gzip_version" "1.10"

# 12. m4 ≥ 1.4.19
m4_version=$(m4 --version | head -n1 | awk '{print $NF}')
check_version "m4" "$m4_version" "1.4.19"

# 13. make ≥ 4.3
make_version=$(make --version | head -n1 | awk '{print $3}')
check_version "make" "$make_version" "4.3"

# 14. patch ≥ 2.7.6
patch_version=$(patch --version | head -n1 | awk '{print $NF}')
check_version "patch" "$patch_version" "2.7.6"

# 15. perl ≥ 5.34.0
perl_version=$(perl -V:version | cut -d"'" -f2)
check_version "perl" "$perl_version" "5.34.0"

# 16. python ≥ 3.10.0
python_version=$(python3 --version | awk '{print $2}')
check_version "python3" "$python_version" "3.10.0"

# 17. sed ≥ 4.8
sed_version=$(sed --version | head -n1 | awk '{print $NF}')
check_version "sed" "$sed_version" "4.8"

# 18. tar ≥ 1.34
tar_version=$(tar --version | head -n1 | awk '{print $NF}')
check_version "tar" "$tar_version" "1.34"

# 19. texinfo ≥ 6.8
texinfo_version=$(makeinfo --version | head -n1 | awk '{print $NF}')
check_version "texinfo" "$texinfo_version" "6.8"

# 20. xz ≥ 5.2.5
xz_version=$(xz --version | head -n1 | awk '{print $4}')
check_version "xz" "$xz_version" "5.2.5"

echo -e "\n✅ Pengecekan selesai. Pastikan semua versi memenuhi syarat minimum LFS 11.2."
