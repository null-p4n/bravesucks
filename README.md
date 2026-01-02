# Brave Browser Privacy & Debloat Script

Make Brave quieter, lighter, and more private with one command. The script now highlights Flatpak installs (including Steam Deck/SteamOS), Debian-based distros, and Arch-based systems, and it can optionally disable Brave AI/Leo features for newer releases.

## Quick start (Linux/macOS)

```bash
git clone https://github.com/null-p4n/bravesucks
cd bravesucks
chmod +x brave-debloat.sh
# You can also export DISABLE_BRAVE_AI=false to keep AI/Leo features
./brave-debloat.sh
```

After running:
- Launch with hardened defaults: `~/.local/bin/brave-private`
- Desktop entry: `~/.local/share/applications/brave-private.desktop`

## What the script does

- Detects Brave in Flatpak or native installs and picks the right binary.
- Backs up your profile (`Preferences`, `Local State`, hosts file) before changes.
- Creates a private launcher with updated `--disable-features` flags tuned for current Brave builds (including Leo/AI surface areas).
- Prompts to disable Brave AI/Leo; non-interactive runs default to disabling it. Set `DISABLE_BRAVE_AI=false` to keep AI features.
- Cleans preferences (Rewards, Ads, Wallet, telemetry, IPFS, AI if selected).
- Removes Brave lab flags (including new Leo/AI flags) and blocks telemetry domains at the hosts level.
- Adds a DNS blocking helper script for nftables/iptables users.
- Applies Flatpak overrides to shrink Brave’s sandbox footprint when installed via Flatpak.

## Supported platforms

- Flatpak builds (`com.brave.Browser`) on SteamOS/Steam Deck and other Flatpak-focused setups.
- Debian-based distributions (e.g., Debian, Ubuntu, Pop!_OS).
- Arch-based distributions (e.g., Arch, EndeavourOS, Manjaro, SteamOS base).
- Windows (policy template in `windows/examples/brave.reg` and PowerShell helper in `brave-debloat.ps1`).

## Options (Linux/macOS)

- **Disable Brave AI/Leo:** respond to the prompt, or set `DISABLE_BRAVE_AI=true|false` before running.
- **jq installation:** the script will install `jq` automatically on Debian/Arch when run as root; otherwise it prints manual commands.

## Windows policy template

If you need to apply the same hardening on Windows, import `windows/examples/brave.reg` (mirroring the `policy_templates.zip` layout from Brave’s Group Policy page) via Registry Editor. It preconfigures common Brave policies—Rewards, VPN, Wallet, IPFS, Tor, Shields exceptions, and AI Chat—to align with the privacy defaults used by the Linux script.

## Windows PowerShell helper

To mirror the bash workflow on Windows, run `brave-debloat.ps1` from an elevated PowerShell prompt:

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
.\brave-debloat.ps1
```

The script will:
- Detect Brave, create a `~/bin/brave-private.cmd` launcher with hardened flags, and prompt to disable Brave AI/Leo (default: disable).
- Back up your Preferences/Local State, then disable Rewards, Ads, Wallet, Telemetry, IPFS, and (optionally) AI settings.
- Remove Brave lab flags from Local State where present.
- Block Brave telemetry domains in the hosts file when run as Administrator (otherwise prints the entries to add).
- Ask whether to apply the same Brave policy keys shipped in `windows/examples/brave.reg`; if you agree, run as Administrator so it can write to `HKLM\SOFTWARE\Policies\BraveSoftware\Brave`.

## Troubleshooting tips

- Make sure you have run Brave at least once so profile folders exist.
- If Brave is running, close it before executing the script to ensure preference updates apply.
- Not running as root? The script will print the hosts entries so you can add them manually.
- Flatpak users: confirm `flatpak list | grep com.brave.Browser` shows the package.

## Contributing

Issues and PRs are welcome. Please include your distro, Brave installation method (Flatpak/native), and whether you opted out of Brave AI/Leo when reporting problems.
