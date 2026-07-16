{ ... }: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    # Config/db/metadata: /var/lib/jellyfin (local, small, on the server's own disk)
    # Media libraries: point at paths under /nas via the web UI at
    # http://<server-ip>:8096 on first launch.
  };
}
