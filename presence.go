package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
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
	token    = strconv.Itoa(rand.Int())
)

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
		peers[b[0]+":"+b[1]] = true
		sendTo(b[0], port, []any{
			map[string]any{"PleaseSendPeers": map[string]any{}},
			map[string]any{"PleaseAlwaysReturnThisMessage": token},
		})
	}

	go func() {
		for range time.Tick(5 * time.Second) {
			t := time.Now().Unix()
			for p := range peers {
				h, port := splitAddr(p)
				sendTo(h, port, []any{
					map[string]any{"IAmHere": map[string]any{"name": name, "t": t}},
					map[string]any{"PleaseAlwaysReturnThisMessage": token},
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
		var msgs []map[string]any
		if json.Unmarshal(buf[:n], &msgs) != nil {
			continue
		}
		src := addr.String()
		peers[src] = true
		now := time.Now().Unix()
		var out []any

		for _, m := range msgs {
			if p, ok := m["Peers"].(map[string]any); ok {
				for _, peer := range p["peers"].([]any) {
					if s, ok := peer.(string); ok {
						peers[s] = true
					}
				}
			}
			if iah, ok := m["IAmHere"].(map[string]any); ok {
				nm, _ := iah["name"].(string)
				t, _ := iah["t"].(float64)
				presence[nm] = [2]any{int64(t), src}
			}
			if hiw, ok := m["HereIsWho"].(map[string]any); ok {
				for _, node := range hiw["nodes"].([]any) {
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
			if tok, ok := m["PleaseAlwaysReturnThisMessage"]; ok && len(out) > 0 {
				out = append(out, map[string]any{"AlwaysReturned": tok})
			}
		}

		if len(out) > 0 {
			sendAddr(addr, out)
		}
	}
}

