#!/bin/bash
# Jalankan sebagai root untuk memeriksa apakah login user lfs valid

set -e

echo "🔎 Memeriksa integritas lingkungan login user lfs..."

LFS_HOME=/home/lfs
PROFILE="$LFS_HOME/.bash_profile"
BASHRC="$LFS_HOME/.bashrc"

# Cek user
if ! id lfs &>/dev/null; then
  echo "❌ User 'lfs' belum ada. Gunakan: useradd -m -s /bin/bash lfs"
  exit 1
fi

# Cek .bash_profile
if ! grep -q "/bin/bash --login" "$PROFILE"; then
  echo "⚠️  .bash_profile tidak memuat perintah shell login."
else
  echo "✅ .bash_profile terlihat benar."
fi

# Cek PATH di .bashrc
if ! grep -q "tools/bin" "$BASHRC"; then
  echo "⚠️  .bashrc tidak menyertakan \$LFS/tools/bin dalam PATH."
else
  echo "✅ .bashrc menyertakan PATH tools."
fi

# Cek file penting
for f in "$PROFILE" "$BASHRC"; do
  if [ ! -f "$f" ]; then
    echo "❌ File hilang: $f"
  else
    echo "✅ Ada: $f"
  fi
  ls -l "$f"
done

# Uji login manual (sembunyikan warning job control)
echo "🧪 Uji login (non-interaktif)..."
su - lfs -c 'echo "✅ Login ke user lfs berhasil. PATH=\$PATH"' 2>/dev/null || echo "❌ Gagal login sebagai lfs."

echo "✔️  Pemeriksaan selesai. Jika tidak ada error, login user lfs aman digunakan."
