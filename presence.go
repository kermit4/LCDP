package main

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"time"
)

var (
	name     = "anon"
	peers    = map[string]bool{}
	presence = map[string][2]any{} // name -> [t, addr]
	secret   []byte                // HMAC key, generated once at startup
)

const ipUDPHeader = 28

// tokenFor derives a per-address token via HMAC — no per-peer state to store.
// See README: "You could use a hash of their address and a secret."
func tokenFor(addr string) string {
	mac := hmac.New(sha256.New, secret)
	mac.Write([]byte(addr))
	return hex.EncodeToString(mac.Sum(nil))[:32]
}

func splitAddr(s string) (string, int) {
	i := strings.LastIndex(s, ":")
	p, _ := strconv.Atoi(s[i+1:])
	return s[:i], p
}

func main() {
	if len(os.Args) > 1 {
		name = os.Args[1]
	} else if v := os.Getenv("NAME"); v != "" {
		name = v
	}

	secret = make([]byte, 32)
	rand.Read(secret)

	conn, _ := net.ListenPacket("udp4", ":24254")
	defer conn.Close()

	sendTo := func(host string, port int, msgs []any) {
		addr, _ := net.ResolveUDPAddr("udp4", fmt.Sprintf("%s:%d", host, port))
		b, _ := json.Marshal(msgs)
		conn.WriteTo(b, addr)
	}
	sendAddr := func(addr net.Addr, msgs []any) {
		b, _ := json.Marshal(msgs)
		conn.WriteTo(b, addr)
	}

	for _, b := range [][2]string{{"148.71.89.128", "24254"}, {"159.69.54.127", "24254"}} {
		port, _ := strconv.Atoi(b[1])
		key := b[0] + ":" + b[1]
		peers[key] = true
		sendTo(b[0], port, []any{
			map[string]any{"PleaseSendPeers": map[string]any{}},
			map[string]any{"PleaseAlwaysReturnThisMessage": map[string]any{"cookie": tokenFor(key)}},
		})
	}

	go func() {
		for range time.Tick(5 * time.Second) {
			t := time.Now().Unix()
			for p := range peers {
				h, port := splitAddr(p)
				sendTo(h, port, []any{
					map[string]any{"IAmHere": map[string]any{"name": name, "t": t}},
					map[string]any{"PleaseAlwaysReturnThisMessage": map[string]any{"cookie": tokenFor(p)}},
				})
			}
		}
	}()

	go func() {
		for range time.Tick(10 * time.Second) {
			now := time.Now().Unix()
			fmt.Printf("\n--- Who is here (%s) ---\n", name)
			for n, info := range presence {
				t, _ := info[0].(int64)
				addr, _ := info[1].(string)
				fmt.Printf("  %s  %s  %ds ago\n", n, addr, now-t)
			}
		}
	}()

	buf := make([]byte, 65535)
	for {
		n, addr, err := conn.ReadFrom(buf)
		if err != nil {
			continue
		}
		data := make([]byte, n)
		copy(data, buf[:n])
		var msgs []map[string]any
		if json.Unmarshal(data, &msgs) != nil {
			continue
		}
		src := addr.String()
		peers[src] = true
		reqBytes := float64(len(data) + ipUDPHeader)
		now := time.Now().Unix()

		// Verified if this packet echoes the HMAC token we would compute for this address.
		isVerified := false
		for _, m := range msgs {
			if ar, ok := m["AlwaysReturned"].(map[string]any); ok {
				if tok, ok := ar["cookie"].(string); ok && tok == tokenFor(src) {
					isVerified = true
					break
				}
			}
		}

		var out []any
		var theirToken any

		for _, m := range msgs {
			if p, ok := m["Peers"].(map[string]any); ok {
				if ps, ok := p["peers"].([]any); ok {
					for _, peer := range ps {
						if s, ok := peer.(string); ok {
							peers[s] = true
						}
					}
				}
			}
			if iah, ok := m["IAmHere"].(map[string]any); ok {
				nm, _ := iah["name"].(string)
				t, _ := iah["t"].(float64)
				presence[nm] = [2]any{int64(t), src}
			}
			if hiw, ok := m["HereIsWho"].(map[string]any); ok {
				if ns, ok := hiw["nodes"].([]any); ok {
					for _, node := range ns {
						if nm, ok := node.(map[string]any); ok {
							n, _ := nm["name"].(string)
							t, _ := nm["t"].(float64)
							a, _ := nm["addr"].(string)
							if a == "" {
								a = src
							}
							presence[n] = [2]any{int64(t), a}
						}
					}
				}
			}
			if _, ok := m["WhoIsHere"]; ok {
				cutoff := now - 60
				var nodes []any
				for n, info := range presence {
					t, _ := info[0].(int64)
					a, _ := info[1].(string)
					if t >= cutoff {
						nodes = append(nodes, map[string]any{"name": n, "t": t, "addr": a})
					}
				}
				out = append(out, map[string]any{"HereIsWho": map[string]any{"nodes": nodes}})
			}
			if _, ok := m["PleaseSendPeers"]; ok {
				var pl []string
				for p := range peers {
					pl = append(pl, p)
					if len(pl) >= 20 {
						break
					}
				}
				out = append(out, map[string]any{"Peers": map[string]any{"peers": pl}})
			}
			if patm, ok := m["PleaseAlwaysReturnThisMessage"].(map[string]any); ok {
				theirToken = patm["cookie"]
			}
		}

		if len(out) > 0 {
			if theirToken != nil {
				out = append(out, map[string]any{"AlwaysReturned": map[string]any{"cookie": theirToken}})
			}
			// Include our token in every reply so an unverified peer can echo it back
			// and receive full responses starting from the very next exchange.
			out = append(out, map[string]any{"PleaseAlwaysReturnThisMessage": map[string]any{"cookie": tokenFor(src)}})

			if !isVerified {
				payload, _ := json.Marshal(out)
				if float64(len(payload)) > 2.5*reqBytes {
					// Minimum: our token (lets them bootstrap verification) + at most 1 peer.
					trimmed := []any{map[string]any{"PleaseAlwaysReturnThisMessage": map[string]any{"cookie": tokenFor(src)}}}
					for _, item := range out {
						if pm, ok := item.(map[string]any); ok {
							if p, ok := pm["Peers"].(map[string]any); ok {
								if pl, ok := p["peers"].([]string); ok && len(pl) > 0 {
									trimmed = append(trimmed, map[string]any{"Peers": map[string]any{"peers": pl[:1]}})
								}
								break
							}
						}
					}
					out = trimmed
				}
			}
			sendAddr(addr, out)
		}
	}
}
