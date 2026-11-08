#!/data/data/com.termux/files/usr/bin/bash
# Bikin paket Windows (EchosVrat.exe) dari Termux, tanpa Node/Wine.
# Memakai Electron versi Windows yang sudah jadi, lalu game ditaruh di dalamnya.
#
# Pemakaian (dari folder utama repo):  bash windows/build_exe_termux.sh
set -e

V="33.2.1"
HERE="$(cd "$(dirname "$0")" && pwd)"     # folder windows/
GAME="$(dirname "$HERE")/game"            # folder game/
OUTDIR="$HOME/storage/downloads"
OUT="$OUTDIR/EchosVrat_Windows.zip"
W="$HOME/exebuild"

[ -f "$GAME/index.html" ] || { echo "Folder game tidak ketemu: $GAME"; exit 1; }
[ -d "$OUTDIR" ] || { echo "Folder $OUTDIR belum ada. Jalankan dulu: termux-setup-storage"; exit 1; }

pkg install -y curl unzip zip >/dev/null
rm -rf "$W"; mkdir -p "$W"; cd "$W"

echo "[1/4] Download Electron Windows v$V (~100MB)..."
curl -L --fail -o e.zip "https://github.com/electron/electron/releases/download/v$V/electron-v$V-win32-x64.zip"

echo "[2/4] Ekstrak..."
mkdir EchosVrat; unzip -q e.zip -d EchosVrat

echo "[3/4] Pasang game..."
rm -f EchosVrat/resources/default_app.asar
mkdir -p EchosVrat/resources/app
cp "$HERE/main.js" "$HERE/package.json" "$HERE/icon.ico" EchosVrat/resources/app/
cp -r "$GAME" EchosVrat/resources/app/game
mv EchosVrat/electron.exe EchosVrat/EchosVrat.exe

echo "[4/4] Zip..."
cd "$W"; rm -f "$OUT"; zip -qr "$OUT" EchosVrat

echo
echo "SELESAI: $OUT"
echo "Kirim ke PC, extract, lalu jalankan EchosVrat/EchosVrat.exe"
