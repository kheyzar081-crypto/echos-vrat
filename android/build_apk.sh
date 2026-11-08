#!/data/data/com.termux/files/usr/bin/bash
# Bikin APK (WebView) dari game HTML, langsung di Termux. Tanpa Gradle / Android Studio.
#
# Pemakaian (dari folder utama repo):
#   bash android/build_apk.sh
# Opsional:  bash android/build_apk.sh <index.html> <folder_music>
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"      # folder android/
ROOT="$(dirname "$DIR")"                  # folder utama repo
HTML="${1:-$ROOT/game/index.html}"
MD="${2:-$(dirname "$HTML")/music}"
RD="$DIR/res"                             # ikon launcher
APPNAME="Echos Vrat"
PKG="com.echosvrat.game"
OUTDIR="$HOME/storage/downloads"
OUT="$OUTDIR/EchosVrat.apk"
KS="$HOME/echos.jks"                      # kunci tanda tangan (JANGAN di-upload ke GitHub)

[ -f "$HTML" ] || { echo "File HTML tidak ketemu: $HTML"; exit 1; }
[ -d "$MD" ]   || { echo "Folder music tidak ketemu: $MD"; exit 1; }
[ -d "$RD" ]   || { echo "Folder ikon (res) tidak ketemu: $RD"; exit 1; }
[ -d "$OUTDIR" ] || { echo "Folder $OUTDIR belum ada. Jalankan dulu: termux-setup-storage"; exit 1; }

echo "[1/7] Pasang alat build..."
pkg install -y openjdk-17 aapt ecj dx apksigner zip >/dev/null

AJ="$PREFIX/share/java/android.jar"
[ -f "$AJ" ] || AJ="$HOME/.android/android.jar"
[ -f "$AJ" ] || { echo "android.jar tidak ditemukan. Taruh di ~/.android/android.jar"; exit 1; }

B="$HOME/apkbuild"
rm -rf "$B"; mkdir -p "$B/assets" "$B/obj" "$B/src/${PKG//.//}"
cp "$HTML" "$B/assets/index.html"
cp -r "$RD" "$B/res"
mkdir -p "$B/assets/music"; cp "$MD"/*.mp3 "$B/assets/music/"

echo "[2/7] Tulis manifest & kode..."
cat > "$B/AndroidManifest.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PKG" android:versionCode="1" android:versionName="1.0">
  <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="28"/>
  <application android:icon="@mipmap/ic_launcher" android:label="$APPNAME" android:hardwareAccelerated="true"
      android:theme="@android:style/Theme.NoTitleBar.Fullscreen">
    <activity android:name=".MainActivity" android:screenOrientation="sensorLandscape"
        android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout|uiMode">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
EOF

cat > "$B/src/${PKG//.//}/MainActivity.java" <<EOF
package $PKG;
import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
  WebView w;
  @Override protected void onCreate(Bundle b) {
    super.onCreate(b);
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    w = new WebView(this);
    setContentView(w);
    WebSettings s = w.getSettings();
    s.setJavaScriptEnabled(true);
    s.setDomStorageEnabled(true);
    s.setMediaPlaybackRequiresUserGesture(false);
    w.setBackgroundColor(0xFF050203);
    w.setOverScrollMode(View.OVER_SCROLL_NEVER);
    w.setWebViewClient(new WebViewClient());
    w.loadUrl("file:///android_asset/index.html");
  }
  @Override public void onWindowFocusChanged(boolean f) {
    super.onWindowFocusChanged(f);
    if (f) getWindow().getDecorView().setSystemUiVisibility(
      View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
      View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
      View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
  }
  @Override public void onBackPressed() { w.evaluateJavascript("esc()", null); }
  @Override protected void onPause()  { super.onPause();  w.evaluateJavascript("_bgOff()", null); w.onPause(); }
  @Override protected void onResume() { super.onResume(); w.onResume(); w.evaluateJavascript("_bgOn()", null); }
}
EOF

echo "[3/7] Compile Java..."
cd "$B"
SRC="src/${PKG//.//}/MainActivity.java"
ecj -cp "$AJ" -d obj "$SRC" || ecj -bootclasspath "$AJ" -d obj "$SRC"

echo "[4/7] Dex..."
if command -v d8 >/dev/null; then d8 --lib "$AJ" --output . $(find obj -name '*.class')
else dx --dex --output=classes.dex obj; fi
[ -f classes.dex ] || { echo "classes.dex gagal dibuat"; exit 1; }

echo "[5/7] Paket APK..."
aapt package -f -M AndroidManifest.xml -S res -A assets -I /system/framework/framework-res.apk -F app.unsigned.apk
aapt add app.unsigned.apk classes.dex >/dev/null

echo "[6/7] Siapkan kunci tanda tangan..."
[ -f "$KS" ] || keytool -genkeypair -keystore "$KS" -alias echos -keyalg RSA -keysize 2048 \
  -validity 10000 -storepass android -keypass android -dname "CN=Echos Vrat"

echo "[7/7] Tanda tangan APK..."
if apksigner sign --ks "$KS" --ks-pass pass:android --key-pass pass:android --out "$OUT" app.unsigned.apk 2>/dev/null; then :
else apksigner -p android "$KS" app.unsigned.apk "$OUT"; fi

echo
echo "SELESAI: $OUT"
echo "Buka file itu dari Downloads lalu izinkan 'install dari sumber ini'."
