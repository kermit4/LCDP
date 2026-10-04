#!/usr/bin/env -S gawk -f
#
# presence.awk -- cjp2p presence demo in GAWK
#
# Joins the cjp2p network on UDP port 24254, announces itself every 5 s
# with a custom IAmHere message, and prints a live roster every 10 s.
#
# The custom message types (IAmHere / HereIsWho / WhoIsHere) are unknown
# to the cjp2p Rust node, which silently drops them.  PleaseSendPeers /
# Peers / PleaseAlwaysReturnThisMessage / AlwaysReturned are understood
# by any cjp2p peer.
#
# Usage:
#   AWKLIBPATH=/path/to/gawk-cjp2p gawk -f presence.awk [NAME]
#   NAME=alice AWKLIBPATH=$PWD gawk -f presence.awk   # from build dir
#
# Dependencies:
#   @load "udp"   -- https://github.com/kermit4/gawk-udp
#   @load "json"  -- gawkextlib json extension (provides json::from_json)
#                    typically at /usr/lib/x86_64-linux-gnu/gawk/json.so

@load "udp"
@load "json"

# --------------------------------------------------------------------------
# Helpers

# Quote s as a JSON string.  All cjp2p strings are printable ASCII so
# escaping only \ and " is sufficient here.
function json_str(s,    t) {
    t = s
    gsub(/\\/, "\\\\", t)
    gsub(/"/, "\\\"", t)
    return "\"" t "\""
}

# Stateless anti-spoofing token: keyed hash of addr with session secret.
# Two independent FNV-1a chains seeded from _s1/_s2 give a 16-hex-char
# token that is unpredictable without knowing the secrets.
# gawk's doubles cover 32-bit integers exactly so the arithmetic is exact.
function token_for(addr,    h1, h2, i, c) {
    h1 = _s1; h2 = _s2
    for (i = 1; i <= length(addr); i++) {
        c = _ord[substr(addr, i, 1)]
        h1 = and(xor(h1, c) * 16777619,  4294967295)
        h2 = and(xor(h2, c) * 2246822519, 4294967295)
    }
    return sprintf("%08x%08x", h1, h2)
}

# Set globals _HOST and _PORT from "host:port".
function split_addr(addr,    i) {
    i = index(addr, ":")
    _HOST = substr(addr, 1, i - 1)
    _PORT = substr(addr, i + 1) + 0
}

# Send a UDP datagram to addr whose body is a comma-joined list of JSON
# objects (the surrounding [] are added here).
function send_msgs(addr, body) {
    split_addr(addr)
    udp_sendto(fd, "[" body "]", _HOST, _PORT)
}

# --------------------------------------------------------------------------
# Outgoing message constructors (each returns one JSON object string)

function msg_IAmHere(name, t) {
    return "{\"IAmHere\":{\"name\":" json_str(name) ",\"t\":" t "}}"
}
function msg_PleaseSendPeers() {
    return "{\"PleaseSendPeers\":{}}"
}
function msg_PleaseAlwaysReturn(tok) {
    return "{\"PleaseAlwaysReturnThisMessage\":{\"cookie\":" json_str(tok) "}}"
}
function msg_AlwaysReturned(tok) {
    return "{\"AlwaysReturned\":{\"cookie\":" json_str(tok) "}}"
}

# Up to 20 peers from the global peers[] table.
function msg_Peers(    k, j, s) {
    j = 0; s = ""
    for (k in peers) {
        if (j > 0) s = s ","
        s = s json_str(k)
        if (++j >= 20) break
    }
    return "{\"Peers\":{\"peers\":[" s "]}}"
}

# HereIsWho for nodes seen within the last 60 s.
function msg_HereIsWho(now,    k, j, s, cutoff) {
    cutoff = now - 60
    j = 0; s = ""
    for (k in presence_time) {
        if (presence_time[k] < cutoff) continue
        if (j > 0) s = s ","
        s = s "{\"name\":"  json_str(k) \
               ",\"t\":"    presence_time[k] \
               ",\"addr\":" json_str(presence_addr[k]) "}"
        j++
    }
    return "{\"HereIsWho\":{\"nodes\":[" s "]}}"
}

# --------------------------------------------------------------------------
# dispatch(msgs, now) -- process a parsed incoming message array.
#
# Reads from globals: src (set in main loop before calling)
# Sets globals:       reply_n, reply_parts[], their_tok, first_peer

function dispatch(msgs, now,    idx, msg_type, j, k) {
    reply_n    = 0
    their_tok  = ""
    first_peer = ""
    delete reply_parts

    for (idx in msgs) {
        if (!isarray(msgs[idx])) continue
        for (msg_type in msgs[idx]) {

            if (msg_type == "Peers") {
                if (isarray(msgs[idx]["Peers"]) &&
                    isarray(msgs[idx]["Peers"]["peers"])) {
                    for (j in msgs[idx]["Peers"]["peers"]) {
                        k = msgs[idx]["Peers"]["peers"][j]
                        if (!isarray(k) && k != "")
                            peers[k] = 1
                    }
                }

            } else if (msg_type == "IAmHere") {
                if (isarray(msgs[idx]["IAmHere"])) {
                    k = msgs[idx]["IAmHere"]["name"]
                    presence_time[k] = msgs[idx]["IAmHere"]["t"] + 0
                    presence_addr[k] = src
                }

            } else if (msg_type == "HereIsWho") {
                if (isarray(msgs[idx]["HereIsWho"]) &&
                    isarray(msgs[idx]["HereIsWho"]["nodes"])) {
                    for (j in msgs[idx]["HereIsWho"]["nodes"]) {
                        if (!isarray(msgs[idx]["HereIsWho"]["nodes"][j])) continue
                        k = msgs[idx]["HereIsWho"]["nodes"][j]["name"]
                        presence_time[k] = msgs[idx]["HereIsWho"]["nodes"][j]["t"] + 0
                        presence_addr[k] = \
                            (msgs[idx]["HereIsWho"]["nodes"][j]["addr"] != "") \
                            ? msgs[idx]["HereIsWho"]["nodes"][j]["addr"] : src
                    }
                }

            } else if (msg_type == "WhoIsHere") {
                reply_parts[++reply_n] = msg_HereIsWho(now)

            } else if (msg_type == "PleaseSendPeers") {
                for (k in peers) { first_peer = k; break }
                reply_parts[++reply_n] = msg_Peers()

            } else if (msg_type == "PleaseAlwaysReturnThisMessage") {
                if (isarray(msgs[idx]["PleaseAlwaysReturnThisMessage"]))
                    their_tok = msgs[idx]["PleaseAlwaysReturnThisMessage"]["cookie"]

            }
            # AlwaysReturned and unknown types: handled elsewhere or ignored.
        }
    }
}

# --------------------------------------------------------------------------
# send_reply(src, req_bytes) -- build reply and apply anti-amplification.
#
# Reads globals: reply_n, reply_parts[], their_tok, first_peer, is_verified

function send_reply(src, req_bytes,    i, parts, n, body) {
    # Only reply when there is substantive content.  AlwaysReturned and
    # PleaseAlwaysReturnThisMessage are piggybacked onto real replies, never
    # sent alone -- sending them alone creates a ping-pong loop.
    if (reply_n == 0) return

    # Assemble: [AlwaysReturned,] content..., PleaseAlwaysReturnThisMessage
    n = 0
    delete parts
    if (their_tok != "")           parts[++n] = msg_AlwaysReturned(their_tok)
    for (i = 1; i <= reply_n; i++) parts[++n] = reply_parts[i]
    parts[++n] = msg_PleaseAlwaysReturn(token_for(src))

    body = ""
    for (i = 1; i <= n; i++) {
        if (i > 1) body = body ","
        body = body parts[i]
    }

    # Anti-amplification: if unverified and response > 2.5x request, trim to
    # just our cookie + at most one peer address (no AlwaysReturned -- the
    # unverified peer needs our token, not proof that we exist).
    if (!is_verified && length(body) + 2 > 2.5 * req_bytes) {
        body = msg_PleaseAlwaysReturn(token_for(src))
        if (first_peer != "")
            body = "{\"Peers\":{\"peers\":[" json_str(first_peer) "]}}," body
    }

    send_msgs(src, body)
}

# --------------------------------------------------------------------------

BEGIN {
    # Accept NAME as first positional arg (delete it so gawk won't read it
    # as a filename) or as NAME env var or -v NAME=... option.
    if (ARGC > 1 && ARGV[1] !~ /=/) {
        NAME = ARGV[1]
        delete ARGV[1]
    }
    if (NAME == "") NAME = ENVIRON["NAME"] != "" ? ENVIRON["NAME"] : "anon"

    BOOTSTRAP[1] = "148.71.89.128:24254"
    BOOTSTRAP[2] = "159.69.54.127:24254"
    IP_UDP_HEADER = 28

    # Build ord[] lookup and seed two independent 32-bit secrets for token_for().
    for (_i = 0; _i <= 127; _i++)
        _ord[sprintf("%c", _i)] = _i
    srand()
    _s1 = int(rand() * 4294967296)
    _s2 = int(rand() * 4294967296)

    fd = udp_open(24254)
    if (fd < 0) {
        print "udp_open(24254) failed -- port in use?" > "/dev/stderr"
        exit 1
    }
    print "Listening on UDP 24254 as " NAME

    for (i in BOOTSTRAP) {
        peers[BOOTSTRAP[i]] = 1
        send_msgs(BOOTSTRAP[i],
            msg_PleaseSendPeers() "," \
            msg_PleaseAlwaysReturn(token_for(BOOTSTRAP[i])))
    }

    last_ping  = systime()
    last_print = systime()

    while (1) {
        now = systime()

        if (now - last_ping >= 5) {
            for (peer in peers)
                send_msgs(peer,
                    msg_IAmHere(NAME, now) "," \
                    msg_PleaseAlwaysReturn(token_for(peer)))
            last_ping = now
        }

        if (now - last_print >= 10) {
            print "\n--- Who is here (" NAME ") ---"
            for (pname in presence_time)
                printf "  %-20s  %-22s  %ds ago\n",
                    pname, presence_addr[pname], now - presence_time[pname]
            last_print = now
        }

        nb = udp_recvfrom(fd, pkt, 1000)
        if (nb <= 0) { delete pkt; continue }

        src       = pkt["host"] ":" pkt["port"]
        req_bytes = nb + IP_UDP_HEADER
        peers[src] = 1

        delete msgs
        json::from_json(pkt["data"], msgs)
        if (length(msgs) == 0) { delete pkt; continue }
        delete pkt

        # Verification: did this peer echo our token back?
        is_verified = 0
        for (idx in msgs) {
            if (!isarray(msgs[idx])) continue
            if ("AlwaysReturned" in msgs[idx] &&
                isarray(msgs[idx]["AlwaysReturned"]) &&
                msgs[idx]["AlwaysReturned"]["cookie"] == token_for(src)) {
                is_verified = 1
                break
            }
        }

        dispatch(msgs, now)
        send_reply(src, req_bytes)
        delete msgs
    }

    udp_close(fd)
}
