# Lab configuration -- edit this file for your environment.
#
# This file is imported by flake.nix and contains all site-specific settings.
#
# Generate hashed passwords with: mkpasswd -m sha-512
# Generate SSH key with: ssh-keygen -t ed25519 -f id_ed25519 -N '' -C "admin@controller"
{
  # ── Network ────────────────────────────────────────────────────
  # IP address dynamically assigned to the controller by the institutional
  # DHCP server.  This address can change whenever the DHCP lease expires
  # or is renewed, so verify it before each PXE/netboot session.
  #
  # It is used in two places:
  #   1. Netboot ramdisk -- baked into the netboot image so PXE-booted
  #      clients can reach the binary cache (Harmonia) on the controller.
  #   2. PXE proxy server (run-pxe-proxy.sh) -- the iPXE boot script
  #      fetches kernel and initrd over HTTP from this address.
  #
  # After all clients are installed, day-to-day Colmena deploys use the
  # static IP (networkBase.masterHostNumber) instead, so a DHCP address
  # change does NOT affect ongoing updates -- only new PXE installs.
  #
  # If the DHCP address changes after netboot artifacts have been built,
  # rebuild them before booting new clients:
  #   nix build .#nixosConfigurations.netboot.config.system.build.kernel  --out-link result-kernel
  #   nix build .#nixosConfigurations.netboot.config.system.build.netbootRamdisk --out-link result-initrd
  #   nix build .#nixosConfigurations.netboot.config.system.build.netbootIpxeScript --out-link result-ipxe
  #
  # Find it with: ip -4 addr show dev <ifaceName>
  masterDhcpIp = "172.16.131.145";
  # Static IP network base (each PC gets networkBase.N)
  networkBase = "10.22.10";
  # Number of student PCs
  pcCount = 25;
  # Controller host number (gets networkBase.N as its static IP)
  masterHostNumber = 99;
  # Shared network interface name on lab PCs
  ifaceName = "enp9s0f0";

  # ── User accounts ─────────────────────────────────────────────
  # Teacher account (gets Veyon Master access + no home reset)
  teacherUser = "docente";
  # Student account (autologin on client PCs, home reset at boot)
  studentUser = "informatica";

  # ── Passwords (SHA-512 hashed) ────────────────────────────────
  # Generate with: mkpasswd -m sha-512
  # Default password for all accounts is "nixos" -- change after first boot.
  teacherPassword = "$6$2mGRpSKHPodwsJaX$D6SVRoOK60Y1XRNTJl3tU5KoiPtWbtqboMLOVbeVout3rnTq6SZNC6RJpjN5royMSpcr/Ck4PY3zvgLj4I2Fl1";
  studentPassword = "$6$uv885OnHgyTHYdfU$6bw3wrbLIXMfMRJgqfhgEcq/JuObU/TCm0E7Ba2Tpah7lonydXSBHeHMKmmkBJoxR8qeX6AGAwKo6SZrok6Rm0";
  adminPassword = "$6$wq1BVhUku9cyis0R$lnGCGcK1yQFCjGsLT/tMyamTS5P2.Upmvm97koHocIrTNEnGZuHng3AlslbHMWITSJIB/DjU9MPDBKw19JqXa0";

  # ── School / organization ──────────────────────────────────────
  # Chromium homepage URL
  homepageUrl = "https://www.itismeucci.edu.it/";
  # Git identity for student home template
  studentGitName = "student";
  studentGitEmail = "student@itismeucci.com";
  # Git identity for admin home template
  adminGitName = "admin";
  adminGitEmail = "admin@itismeucci.com";

  # ── Locale / timezone ──────────────────────────────────────────
  timeZone = "Europe/Rome";
  defaultLocale = "en_US.UTF-8";
  extraLocale = "it_IT.UTF-8";
  keyboardLayout = "it";
  consoleKeyMap = "it2";
}
