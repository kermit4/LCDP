const dgram = require('dgram');

const NAME = process.argv[2] || process.env.NAME || 'anon';
const BOOTSTRAP = [['148.71.89.128', 24254], ['159.69.54.127', 24254]];

const sock = dgram.createSocket('udp4');
const peers = new Set();
const presence = {};
const token = Math.random().toString(36).slice(2);

function send(host, port, msgs) {
  sock.send(JSON.stringify(msgs), port, host);
}

function split(addr) {
  const i = addr.lastIndexOf(':');
  return [addr.slice(0, i), parseInt(addr.slice(i + 1))];
}

sock.bind(24254, () => {
  for (const [h, p] of BOOTSTRAP) {
    peers.add(`${h}:${p}`);
    send(h, p, [{ PleaseSendPeers: {} }, { PleaseAlwaysReturnThisMessage: token }]);
  }
});

sock.on('message', (data, rinfo) => {
  let msgs;
  try { msgs = JSON.parse(data); } catch { return; }

  const src = `${rinfo.address}:${rinfo.port}`;
  peers.add(src);
  const out = [];

  for (const m of msgs) {
    if (m.Peers) m.Peers.peers.forEach(p => peers.add(p));
    if (m.IAmHere) presence[m.IAmHere.name] = { t: m.IAmHere.t, addr: src };
    if (m.HereIsWho) (m.HereIsWho.nodes || []).forEach(n =>
      presence[n.name] = { t: n.t, addr: n.addr || src });
    if (m.WhoIsHere) {
      const cutoff = Math.floor(Date.now() / 1000) - 60;
      out.push({ HereIsWho: { nodes: Object.entries(presence)
        .filter(([, v]) => v.t >= cutoff)
        .map(([name, v]) => ({ name, ...v })) } });
    }
    if (m.PleaseSendPeers) out.push({ Peers: { peers: [...peers].slice(0, 20) } });
    if (m.PleaseAlwaysReturnThisMessage && out.length)
      out.push({ AlwaysReturned: m.PleaseAlwaysReturnThisMessage });
  }

  if (out.length) send(rinfo.address, rinfo.port, out);
});

setInterval(() => {
  const t = Math.floor(Date.now() / 1000);
  for (const p of peers) {
    const [h, port] = split(p);
    send(h, port, [{ IAmHere: { name: NAME, t } }, { PleaseAlwaysReturnThisMessage: token }]);
  }
}, 5000);

setInterval(() => {
  const now = Math.floor(Date.now() / 1000);
  console.log(`\n--- Who is here (${NAME}) ---`);
  for (const [name, { t, addr }] of Object.entries(presence))
    console.log(`  ${name}  ${addr}  ${now - t}s ago`);
}, 10000);

