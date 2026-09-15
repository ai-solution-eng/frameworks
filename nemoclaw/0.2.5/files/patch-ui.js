// Boot-time patcher for the OpenClaw control-ui. Makes the dashboard auto-connect
// from the BARE URL by serving a same-origin auto-token.js (CSP 'self' allows it)
// and referencing it with a <script src> tag in index.html (inline scripts are
// blocked by the gateway's `script-src 'self'` CSP, so the logic MUST be a file).
//
// Usage: node patch-ui.js <uiDir> <token>
//   <uiDir>  = the writable copy of dist/control-ui (contains index.html)
// Writes:
//   <uiDir>/auto-token.js   (the auto-connect logic, token baked in)
//   <uiDir>/index.html      (gets a <script src="./auto-token.js"> tag injected)
const fs = require('fs');
const path = require('path');
const uiDir = process.argv[2];
const tok = process.argv[3];
if (!uiDir || !tok) { console.error('usage: node patch-ui.js <uiDir> <token>'); process.exit(1); }
const indexPath = path.join(uiDir, 'index.html');
const jsPath = path.join(uiDir, 'auto-token.js');
if (!fs.existsSync(indexPath)) { console.error('index.html not found at', indexPath); process.exit(1); }

// 1) Write the auto-connect script (same-origin file -> allowed by CSP script-src 'self').
const autoJs =
  '(function(){' +
  'var t=' + JSON.stringify(tok) + ';' +
  'if(window.__nemoclawAutoToken) return; window.__nemoclawAutoToken=true;' +
  'function go(){' +
  'var a=document.querySelector("openclaw-app");' +
  'if(!a||!a.settings||typeof a.connect!=="function") return false;' +
  'if(a.connected) return true;' +
  'a.settings.token=t;' +
  'try{ if(a.disconnect) a.disconnect(); }catch(e){}' +
  'try{ a.connect(); }catch(e){}' +
  'return true;' +
  '}' +
  'var n=0;' +
  'var iv=setInterval(function(){ n++; if(go()||n>200) clearInterval(iv); },100);' +
  '})();\n';
fs.writeFileSync(jsPath, autoJs);
console.log('wrote', jsPath, '(' + autoJs.length + ' bytes)');

// 2) Inject <script src="./auto-token.js"> into index.html (idempotent).
const MARK = 'auto-token.js';
let s = fs.readFileSync(indexPath, 'utf8');
if (s.includes(MARK)) {
  console.log('index.html already references auto-token.js; skipping injection');
  process.exit(0);
}
const m = s.search(/<head[^>]*>/i);
if (m === -1) { console.error('no <head> tag in', indexPath); process.exit(1); }
const at = s.indexOf('>', m) + 1;
s = s.slice(0, at) + '<script src="./auto-token.js"></' + 'script>' + s.slice(at);
fs.writeFileSync(indexPath, s);
console.log('injected <script src="./auto-token.js"> into', indexPath);
