---
description: "Connect to and operate the reusable local macOS VM ('Agent VM') for isolated GUI/desktop automation — SSH access, file transfer, networking quirks, and the hard-won gotchas for driving it without disrupting the host."
user-invocable: true
---

A reusable macOS guest VM for running GUI/desktop automation (native macOS apps)
in isolation, so work in the VM does not commandeer the host's
mouse/keyboard/display. Reuse this VM — do not recreate it from scratch each time.

## Connect

The host has a passwordless key + alias already set up:

```bash
ssh agentvm           # -> agent@192.168.64.2, key ~/.ssh/agentvm_ed25519
```

Do all CLI work this way. SSH from the host shell is the **only reliable
control channel** (see gotcha #1). Run SSH-to-VM commands with the Bash tool's
`dangerouslyDisableSandbox: true` — the VM (192.168.64.2) is not in the command
sandbox's network allowlist.

## Facts

- VirtualBuddy bundle: the VM in `~/Library/Application Support/VirtualBuddy/`
  (currently the only VM in the library; give it a generic name there — power off
  to rename).
- Guest: macOS 26.5.2 (Tahoe), arm64. User `agent`. LocalHostName `Devins-Virtual-Machine`.
- Specs: 147 GB thin disk, 22 GB RAM, 9 vCPU.
- Network: VirtualBuddy NAT. Host side = `bridge100` 192.168.64.1 (also the guest's
  gateway). Guest = **192.168.64.2** (DHCP — see "If the guest IP changes").
- SSH key: `~/.ssh/agentvm_ed25519` (host), authorized in `~agent/.ssh/authorized_keys`.
  Fingerprint `SHA256:b6BLHeqWetbZismo+mcInngaVRPOp9HShtLGyAtqFyA`.

## Start / find the VM

- Launch via **VirtualBuddy** (`open -a VirtualBuddy`), double-click the VM card,
  then click **Start** on the VM screen (the double-click only opens the VM; it
  doesn't boot it). The guest display opens in a normal window — it may land on
  any monitor; use VirtualBuddy's Window menu to locate it.
- Check if it's already up: `ping -c1 192.168.64.2` from the host, or `ssh agentvm true`.
- **SSH only comes up after the guest is booted AND logged in.** sshd / the
  network stack do not accept connections at the login window. The `agent` user is
  now set to **autologin**, so a normal boot logs in on its own and SSH becomes
  reachable without intervention — just poll after starting it:
  ```bash
  until ssh -o ConnectTimeout=4 agentvm true 2>/dev/null; do sleep 5; done
  ```
  If SSH still never comes up, look at the VM window: it's stuck pre-login (e.g.
  a FileVault/password prompt that autologin doesn't cover), not a network problem.

## Move files / text in and out

Clipboard sharing is unreliable (gotcha #3), so use one of:

```bash
scp ./localfile agentvm:~/                 # host -> guest
scp agentvm:~/remotefile ./                # guest -> host
ssh agentvm 'cat > ~/x' < ./localfile      # stream in
```

To hand a snippet to a human typing in the guest GUI without retyping it, serve
it from the host over the NAT gateway and `curl` it in the guest (the guest can
always reach the host at 192.168.64.1):

```bash
# host (isolate what you serve!):
cd /some/dir-with-only-the-file && python3 -m http.server 8765 --bind 0.0.0.0
# guest:
curl -fsS http://192.168.64.1:8765/thefile
```

## Gotchas (read before driving this VM)

1. **Host computer-use cannot reliably type into the guest GUI.** VirtualBuddy's
   host→guest key forwarding garbles input and triggers press-and-hold accent
   popups. Never type commands into the VM window. Use `ssh agentvm` instead.
   Clicking into the guest window is reliable; typing is not.
2. **Host screen-capture of the VM window fails during boot/reboot.** Screenshots
   return `SCContentFilter failure` (nil) while the guest's display surface is in
   the boot transition. It recovers once the guest reaches a stable screen
   (login/desktop). If capture fails, wait ~30–60s and retry rather than
   re-granting access.
3. **Clipboard host↔guest is flaky even with VirtualBuddyGuest.app running**
   (installed from an auto-mounted network volume in the VM). Don't depend on
   paste; use scp / the curl-from-host trick above.
4. **NAT DNS quirk.** The Apple Virtualization NAT gateway (192.168.64.1) often
   fails to forward DNS, so the guest can `ping 1.1.1.1` but not resolve names.
   Fix inside the guest (needs the `agent` password):
   ```bash
   sudo networksetup -setdnsservers "$(networksetup -listallnetworkservices | tail -n +2 | head -1)" 1.1.1.1 8.8.8.8
   ```
5. **First host→guest connection may say "No route to host"** until ARP populates.
   `ping -c2 192.168.64.2` once, then the SSH/connection succeeds.
6. **sudo in the guest needs the `agent` password** (human-supplied; not stored).
   Agents can't run `sudo` non-interactively here. Prefer no-sudo installs
   (Claude Code's native installer; Node via nvm or the standalone pkg into
   `$HOME`). When sudo is unavoidable, hand the human the exact command to run in
   a guest Terminal.

## Running an autonomous agent *inside* the VM

The point of this VM is to let a Claude Code instance run **inside the guest** so
its computer-use drives the guest's GUI from within (in-guest capture/input works
normally — unlike host→guest, gotcha #1/#2). To set that up:

- Install Claude Code in the guest over SSH (native installer, no sudo).
- Launch it in the guest; grant it **Screen Recording + Accessibility**
  (System Settings → Privacy & Security) so its computer-use works.
- It then operates the target app(s) independently while the host is free.

Most GUI apps and installs require the guest to be online — verify
`ssh agentvm 'ping -c1 apple.com'` resolves before relying on it (see gotcha #4).

## If the guest IP changes (DHCP)

192.168.64.2 is a DHCP lease and can change across reboots. To rediscover and
re-point the alias:

```bash
arp -an | grep '192.168.64'                      # host: find the guest's .64.x entry
# or, in the guest: ipconfig getifaddr en0
# then update HostName in ~/.ssh/config under "Host agentvm"
```
