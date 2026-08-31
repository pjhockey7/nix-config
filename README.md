# nix-config

NixOS + Home Manager configuration. **Flake-free** — inputs are pinned with
[nixtamal](https://nixtamal.toast.al/) instead of `flake.lock`.

## Layout

```
default.nix        # entry point: nixosConfigurations + homeConfigurations
nix/tamal/         # nixtamal: manifest.kdl (edit) + lock.json (generated)
nixos/<host>/      # per-host NixOS modules
home-manager/      # Home Manager modules + profiles/
```

`nixtamal` need not be installed globally — run it via `nix-shell -p nixtamal`.

## Everyday commands

Rebuild + switch a NixOS host (`framework`, `nas`) — build the system
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

Activate a Home Manager profile (`pj@framework`, `pj@nas`):

```sh
nix-build -A 'homeConfigurations."pj@framework".activationPackage' && ./result/activate
```

Build the installer ISO (`./result/iso/*.iso`):

```sh
nix-build -A nixosConfigurations.installer-iso.config.system.build.isoImage
```

(`nix-build` with no file argument uses `./default.nix`.)

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
