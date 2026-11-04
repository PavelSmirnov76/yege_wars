console.log("started");

(async () => {
console.log("inside");

const http = require('node:http');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
console.log("after-requires");

const { chromium } = require('playwright');

const payload = Buffer.from('YEGE-TC16-SMOKE\nline-2\n', 'utf8');
const filename = 'tc16-smoke.txt';
console.log("after-mkdtemp");

const expectedClipboard = 'TC16 clipboard smoke value';
const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'yege-tc16-smoke-'));
const server = http.createServer((_req, res) => {
  res.writeHead(200, {'content-type':'text/html; charset=utf-8'});
  res.end(`<!doctype html><button id="copy">Copy</button><a id="download" href="data:text/plain;base64,${payload.toString('base64')}" download="${filename}">Download</a>`);
});
let browser;
let context;
let originalClipboard;
let originalReadable = false;
let copiedOk = false;
let downloadOk = false;
let downloadBytes = 0;
let downloadHash = '';
let downloadNameOk = false;
let restoreOk = false;
let errorCode = 'none';
let serverPort;
try {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  serverPort = server.address().port;
  const origin = `http://127.0.0.1:${serverPort}`;
  browser = await chromium.launch({headless:true});
  context = await browser.newContext({acceptDownloads:true});
  await context.grantPermissions(['clipboard-read','clipboard-write'], {origin});
  const page = await context.newPage();
  await page.goto(origin);
  try {
    originalClipboard = await page.evaluate(() => navigator.clipboard.readText());
    originalReadable = true;
  } catch (e) { errorCode = e.name || 'clipboard_read_failed'; }
  if (originalReadable) {
    await page.evaluate(async value => navigator.clipboard.writeText(value), expectedClipboard);
    const readback = await page.evaluate(() => navigator.clipboard.readText());
    copiedOk = readback === expectedClipboard;
  }
  const downloadPromise = page.waitForEvent('download');
  await page.locator('#download').click();
  const download = await downloadPromise;
  downloadNameOk = download.suggestedFilename() === filename;
  const savedPath = path.join(tempDir, 'saved-download.bin');
  await download.saveAs(savedPath);
  const actual = await fs.readFile(savedPath);
  downloadBytes = actual.length;
  downloadHash = crypto.createHash('sha256').update(actual).digest('hex');
  downloadOk = downloadNameOk && actual.equals(payload);
  await fs.unlink(savedPath);
} catch (e) {
  if (errorCode === 'none') errorCode = e.name || 'smoke_failed';
} finally {
  if (context && originalReadable) {
    try {
      const page = context.pages()[0];
      await page.evaluate(async value => navigator.clipboard.writeText(value), originalClipboard);
      const restored = await page.evaluate(() => navigator.clipboard.readText());
      restoreOk = restored === originalClipboard;
    } catch (_) { restoreOk = false; }
  }
  if (context) await context.close().catch(() => {});
  if (browser) await browser.close().catch(() => {});
  if (server.listening) await new Promise(resolve => server.close(resolve));
  await fs.rm(tempDir, {recursive:true,force:true});
}
const result = {playwright:require('playwright/package.json').version, chromium:browser ? 'launched' : 'launch_failed', originPort:serverPort||null, originalClipboardReadable:originalReadable, clipboardRoundtripOk:copiedOk, clipboardRestored:restoreOk, downloadNameOk, downloadBytes, downloadSha256:downloadHash||null, downloadMatches:downloadOk, errorCode};
console.log(JSON.stringify(result));
process.exitCode = originalReadable && copiedOk && restoreOk && downloadOk ? 0 : 1;

})().catch(e => { console.log(JSON.stringify({fatal:e.name||"error"})); process.exitCode=1; });
