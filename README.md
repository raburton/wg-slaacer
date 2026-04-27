# wg-slaacer

Simple eBPF-based helper that watches WireGuard IPv6 address usage and automatically updates peers' AllowedIPs via Generic Netlink (libmnl), to allow the use of SLAAC. The project combines a tiny kernel-side eBPF probe with a user-space provisioner that performs incremental WireGuard allowed-IP adds/removals. This code was almost entirely written by Google Gemini, I didn't even know what eBPF was until I used Gemini to explore how I might solve the SLAAC issue, but it took a lot of shepherding to get this result.

**Purpose**
- Monitor WireGuard peer AllowedIP activity in-kernel and emit events when new addresses are observed.
- Userspace application automatically updates peer AllowedIPs via netlink (no shelling out to `wg`).
- Optional DOS protection via a token-bucket quota (compile-time switch).

**Prerequisites**
- Linux with BPF/CO-RE support and a recent kernel (v6.16+) to support necessary wireguard features.
- Development tools: `clang`, `gcc`, `make`, `bpftool` in PATH.
- Libraries: `libbpf` (headers + dev), `libmnl` (dev). On Debian/Ubuntu: `libbpf-dev libmnl-dev`.
- Root privileges are required for building & loading BPF programs and manipulating WireGuard nets.

**Build**
```bash
sudo make
```

- Without DOS protection (if you trust your peers):

```bash
sudo make DOS_PROTECTION=0
```

**Install**
```bash
sudo make install
```

**Run**

By default the target WireGuard interface is `wg1`. Copy `src/wg-slaacer.conf` to `/etc/` for adjustable runtime parameters used by the daemon.

- From systemd:
```bash
systemctl enable wg-slaacer
systemctl start  wg-slaacer
```

- Or for testing:

```bash
sudo build/wg-slaacer
```


**Security tradeoffs (auto-learning)**

Auto-learning AllowedIPs improves convenience, reduces manual configuration, and enables SLAAAC and privacy extensions, but introduces several security considerations. If you trust your peers, e.g. you're running this on your home router for yourself and family, this is not going to be an issue and you can disable the DOS protection for a lighter (CPU & memory) process. If you are running a commercial VPN provider, these might be an issue - but even there, these issues still require an authenticated peer.

- Risk: an attacker on the network (or a compromised host) can cause the daemon to learn and install AllowedIPs that route traffic unexpectedly (address spoofing or route hijacking).
  - Mitigations: normal routing comes into play, you can't just claim any IP address and expect to get traffic routed back to you. IPTables can be used to used to filter traffic and limit the wg interface to known address ranges. Ideally a filter should be added to prevent auto learning of invalid addresses in the first place. Once a peer has claimd an IP, no other peer can take that IP unless it has expired (by default, 24 hours after it was last used to send data).

- Risk: rapid event floods can trigger excessive netlink operations or resource exhaustion (DOS).
  - Mitigations: enable the token-bucket rate limiting (compile-time `DOS_PROTECTION`). Tune bucket sizes and cleanup intervals in `src/wg-slaacer.conf`. A per-peer concurrent IP limit should be implemented, but so far I haven't found an elegant way to do it (there may not be one), as locking options in eBPF are limited.

**Further reading**
- Full write-up: https://yourblog.example/post-about-provisioner  (placeholder link)
