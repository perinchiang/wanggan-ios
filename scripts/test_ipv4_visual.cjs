const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const html = fs.readFileSync(path.join(__dirname, '../Resources/ipv4-address-visual.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'local visualization script exists');

function loadVisual() {
  const messages = [];
  const root = { innerHTML: '', textContent: '', addEventListener(type, callback) { this[type] = callback; } };
  const document = {
    getElementById() { return root; },
    body: { scrollHeight: 400, classList: { toggle() {} } },
    documentElement: { scrollHeight: 400, style: { setProperty() {} } }
  };
  const window = { webkit: { messageHandlers: { ipv4Visual: { postMessage(message) { messages.push(message); } } } } };
  vm.runInNewContext(script, { document, window, setInterval() { return 1; }, clearInterval() {} });
  return { api: window.WangGanIPv4, root, messages };
}

test('two parameter sets calculate their own binary network address', () => {
  const { api } = loadVisual();
  assert.equal(api.networkAddress('192.168.1.10', 24), '192.168.1.0');
  assert.equal(api.networkAddress('10.20.30.40', 16), '10.20.0.0');
  assert.equal(api.networkAddress('192.168.1.200', 25), '192.168.1.128');
  assert.equal(api.parseIPv4('256.1.2.3', 24), null);
  assert.equal(api.parseIPv4('01.2.3.4', 24), null);
});

test('practice hides the answer until the app confirms it, and sends only a selection', () => {
  const { api, root, messages } = loadVisual();
  const input = { ip: '10.20.30.40', prefix: 16, mode: 'practice', selectedOctet: null,
                  solved: false, theme: 'light', fontScale: 1, reduceMotion: true };
  api.update(input);
  assert.match(root.innerHTML, /data-boundary="2"/);
  assert.doesNotMatch(root.innerHTML, /网络地址：/);
  assert.doesNotMatch(root.innerHTML, /class="bit network"/);
  root.click({ target: { closest(selector) {
    return selector === '[data-boundary]' ? { dataset: { boundary: '2' } } : null;
  } } });
  assert.equal(messages.at(-1).type, 'select');
  assert.equal(messages.at(-1).value, 2);
  api.update({ ...input, selectedOctet: 2, solved: true });
  assert.match(root.innerHTML, /网络地址：/);
  assert.match(root.innerHTML, /10\.20\.0\.0\/16/);
});
