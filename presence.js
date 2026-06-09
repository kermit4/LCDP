const dgram = require('dgram');
const crypto = require('crypto');

const NAME = process.argv[2] || process.env.NAME || 'anon';
const BOOTSTRAP = [['148.71.89.128', 24254], ['159.69.54.127', 24254]];
const IP_UDP_HEADER = 28;

const sock = dgram.createSocket('udp4');
const peers = new Set();
const presence = {};

// HMAC-derived token: no per-peer state to store.
// See README: "You could use a hash of their address and a secret."
const secret = crypto.randomBytes(32);

function tokenFor(addr) {
  return crypto.createHmac('sha256', secret).update(addr).digest('hex').slice(0, 32);
}

function send(host, port, msgs) {
  sock.send(JSON.stringify(msgs), port, host);
}

function split(addr) {
  const i = addr.lastIndexOf(':');
  return [addr.slice(0, i), parseInt(addr.slice(i + 1))];
}

sock.bind(24254, () => {
  for (const [h, p] of BOOTSTRAP) {
    const key = `${h}:${p}`;
    peers.add(key);
    send(h, p, [{ PleaseSendPeers: {} }, { PleaseAlwaysReturnThisMessage: tokenFor(key) }]);
  }
});

sock.on('message', (data, rinfo) => {
  let msgs;
  try { msgs = JSON.parse(data); } catch { return; }

  const src = `${rinfo.address}:${rinfo.port}`;
  peers.add(src);
  const reqBytes = data.length + IP_UDP_HEADER;

  // Verified if this packet echoes the HMAC token we would compute for this address.
  const isVerified = msgs.some(m => m.AlwaysReturned === tokenFor(src));

  const out = [];
  let theirToken = null;

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
    if (m.PleaseAlwaysReturnThisMessage) theirToken = m.PleaseAlwaysReturnThisMessage;
  }

  if (out.length) {
    if (theirToken !== null) out.push({ AlwaysReturned: theirToken });
    // Include our token in every reply so an unverified peer can echo it back
    // and receive full responses starting from the very next exchange.
    out.push({ PleaseAlwaysReturnThisMessage: tokenFor(src) });

    let reply = out;
    if (!isVerified) {
      const payload = Buffer.from(JSON.stringify(out));
      if (payload.length > 2.5 * reqBytes) {
        // Minimum: our token (lets them bootstrap verification) + at most 1 peer.
        const trimmed = [{ PleaseAlwaysReturnThisMessage: tokenFor(src) }];
        const peersMsg = out.find(m => m.Peers);
        if (peersMsg) trimmed.push({ Peers: { peers: peersMsg.Peers.peers.slice(0, 1) } });
        reply = trimmed;
      }
    }
    send(rinfo.address, rinfo.port, reply);
  }
});

setInterval(() => {
  const t = Math.floor(Date.now() / 1000);
  for (const p of peers) {
    const [h, port] = split(p);
    send(h, port, [{ IAmHere: { name: NAME, t } }, { PleaseAlwaysReturnThisMessage: tokenFor(p) }]);
  }
}, 5000);

setInterval(() => {
  const now = Math.floor(Date.now() / 1000);
  console.log(`\n--- Who is here (${NAME}) ---`);
  for (const [name, { t, addr }] of Object.entries(presence))
    console.log(`  ${name}  ${addr}  ${now - t}s ago`);
}, 10000);
