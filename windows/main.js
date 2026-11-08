const { app, BrowserWindow } = require('electron');
const path = require('path');
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');
function mk() {
  const w = new BrowserWindow({ width: 1280, height: 720, fullscreen: true, autoHideMenuBar: true, backgroundColor: '#050203', icon: path.join(__dirname,'icon.ico'), webPreferences: { backgroundThrottling: true } });
  w.setMenu(null);
  w.loadFile(path.join(__dirname, 'game', 'index.html'));
  w.webContents.on('before-input-event', (e, i) => {
    if (i.type === 'keyDown' && i.key === 'F11') w.setFullScreen(!w.isFullScreen());
  });
}
app.whenReady().then(mk);
app.on('window-all-closed', () => app.quit());
