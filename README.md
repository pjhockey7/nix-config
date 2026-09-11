# nix-config

NixOS + Home Manager configuration. **Flake-free** — inputs are pinned with
[nixtamal](https://nixtamal.toast.al/) instead of `flake.lock`.

## Layout

```
default.nix        # entry point: nixosConfigurations + homeConfigurations
nix/tamal/         # nixtamal: manifest.kdl (edit) + lock.json (generated)
nixos/<host>/      # per-host NixOS modules (the TVs share nixos/tv/)
home-manager/      # Home Manager modules + profiles/
```

`nixtamal` need not be installed globally — run it via `nix-shell -p nixtamal`.

## Everyday commands

Rebuild + switch a NixOS host (`framework`, `nas`, `tv-main`, `tv-bedroom`,
`tv-guest`) — build the system
closure, then activate + update the bootloader:

```sh
nix-build -A nixosConfigurations.framework.config.system.build.toplevel \
  && sudo ./result/bin/switch-to-configuration switch
```

Build a host without switching / evaluate only:

```sh
nix-build -A nixosConfigurations.framework.config.system.build.toplevel
nix-build --dry-run -A nixosConfigurations.framework.config.system.build.toplevel
```

Activate a Home Manager profile (`pj@framework`, `pj@nas`, `pj@tv`):

```sh
nix-build -A 'homeConfigurations."pj@framework".activationPackage' && ./result/activate
```

Build the installer ISO (`./result/iso/*.iso`):

```sh
nix-build -A nixosConfigurations.installer-iso.config.system.build.isoImage
```

(`nix-build` with no file argument uses `./default.nix`.)

## The `tv-*` hosts — open streaming boxes

Boots straight into a 10-foot launcher. No Chromecast, no Google TV, no Kodi.

```
greetd (autologin) → labwc → tv-launcher loop
                                │
      ┌─────────────────────────┴───────────────────┐
      │  rofi fullscreen, arrow keys + enter        │
      │  Jellyfin  Netflix  YouTube  Hulu  Max ...  │
      └─────────────────────────┬───────────────────┘
                    pick → run app in FOREGROUND
                    app exits / Home pressed → back to launcher
```

Apps are **modal**, like a set-top box. `nixos/modules/tv` owns the session;
`nixos/tv/services/casting.nix` owns the receivers.

### One appliance, several rooms

Every box runs the same system and the same `pj` user — they have separate
disks, so logins and cookies are already per-machine. The hostname is what
tells them apart, so `ssh tv-bedroom.local` reaches the right one (avahi
publishes the name; no DHCP reservation needed).

```
nixos/tv/common.nix         # the whole appliance
nixos/tv/apps.nix           # the launcher catalog, as an attrset
nixos/tv/hosts/<room>/      # hostname + the entries that room gets
```

A host file is a handful of lines:

```nix
{ config, lib, pkgs, ... }:
let apps = import ../../apps.nix { inherit config lib pkgs; };
in {
  imports = [ ../../common.nix ];
  networking.hostName = "tv-bedroom";
  services.tv.apps = with apps; [ jellyfin youtube netflix browser reboot powerOff ];
}
```

Adding a TV is a directory here plus its name in `tvRooms` in `default.nix`.
A room whose remote sends different keycodes sets `services.tv.rcXml` to its
own labwc config rather than forking the module — run `wev` over SSH to find
out what the remote actually emits.

### Why these pieces

| Piece | Why not the obvious alternative |
|---|---|
| **labwc**, not cage | cage has no keybindings, so a Chrome `--kiosk` window with no exit affordance (Netflix, Max) is unescapable from a remote. labwc binds `Home` → close. |
| **Chrome**, not Chromium/Firefox | Chrome is the only browser shipping Widevine on Linux. Each service gets its own `--user-data-dir`, so logins and crashes stay isolated. |
| **Jellyfin Desktop**, not Jellyfin web | mpv-based, so it direct-plays codecs a browser would force the `server` host to transcode. Also registers as a "Play On" target. |
| **no Kodi** | Its only unique contribution here was a DLNA renderer, which `gmediarender` provides in six lines — and Kodi has no clean way to shell out to Chrome on Wayland. |
| **UxPlay**, not Kodi AirPlay | Kodi's AirPlay is legacy audio/photo push; modern iOS mirroring doesn't speak it. |

### The DRM ceiling (accepted tradeoff)

Widevine on Linux is **L3 / "Software Secure" on every architecture**: 720p–1080p,
no 4K, HDR, Dolby Vision or Atmos. This is not a hardware limit. A browser
extension can push Netflix from its 720p default to 1080p; install it into the
Netflix profile via Chrome's managed-policy directory if you want it declarative.

### Hardware

`nixos/tv/hardware-configuration.nix` is a **placeholder that will not boot** —
it exists so the hosts type-check before hardware exists. Replace it with the
output of `nixos-generate-config --root /mnt` on the real machine.

It is shared by every TV, which only works if they address their filesystems
identically. Label the partitions at install time and keep the generated file
on `by-label` rather than the `by-uuid` it defaults to:

```sh
e2label /dev/nvme0n1p2 NIXOS && fatlabel /dev/nvme0n1p1 BOOT
```

A box that turns out genuinely different drops its own
`hardware-configuration.nix` into its host directory and imports that.

x86_64 (Intel N100/N150 class) is the recommended target: mainline kernel
support and QuickSync VA-API decode. **ARM is now viable too** — Chrome for
ARM64 Linux shipped stable in July 2026 with a native aarch64 Widevine CDM, and
`google-chrome` in the pinned nixpkgs lists `aarch64-linux`. A Pi 5 works; it
just needs a downstream kernel and loses hardware H.264 decode. The Intel VA-API
drivers in `common.nix` are already guarded behind an `isx86_64` check.

### Adding a service

Add it to the catalog in `nixos/tv/apps.nix`, then name it in whichever
rooms should show it. Each entry takes exactly one of `url` (isolated Chrome
kiosk window) or `command`:

```nix
plex = { name = "Plex"; url = "https://app.plex.tv/desktop"; };
```

`services.tv.apps` is an ordered list, so a room's menu reads in the order it
lists them.

Set `userAgent` for sites that gate a TV interface on it — that is why the
YouTube entry reaches the `/tv` leanback UI instead of the desktop site.

### First-run and debugging

The box has no terminal of its own; SSH in as `pj`.

```sh
systemctl --user status uxplay gmediarender   # receivers (run inside the session)
journalctl -u greetd -b                       # session/compositor startup
vainfo                                        # confirm hardware decode came up
wev                                           # find the keycodes your remote sends
iwctl                                         # join wifi (ethernet preferred)
```

Turn on fullscreen inside Jellyfin Desktop once (Settings → Video); it is an
app setting, not a CLI flag. To rebind the remote's "back" key, edit
`nixos/modules/tv/rc.xml` — or, for one room only, point that host's
`services.tv.rcXml` at a copy.

## Updating inputs (replaces `nix flake update`)

```sh
nix-shell -p nixtamal --run 'nixtamal refresh'   # bump all inputs to latest fresh revision
nix-shell -p nixtamal --run 'nixtamal lock'       # re-lock after editing nix/tamal/manifest.kdl
nix-shell -p nixtamal --run 'nixtamal tweak'      # edit the manifest in $EDITOR
```

Inputs (nixpkgs @ `nixos-unstable`, home-manager @ `master`) are declared in
`nix/tamal/manifest.kdl` and pinned in `nix/tamal/lock.json`.

## Why no flakes

Flakes' one indispensable feature here was input pinning; nixtamal provides that
in plain Nix with no experimental features. `default.nix` builds each NixOS host
with `nixpkgs/nixos/lib/eval-config.nix` and each Home Manager profile with
`home-manager/modules`, consuming `import ./nix/tamal { }` for pinned sources.
