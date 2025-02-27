```
# Brave Browser Debloat & Privacy Enhancement Script

This script helps debloat and enhance the privacy settings of the Brave Browser. It is designed to work on both SteamOS (Arch-based) and Kali Linux (Debian-based) systems, with a focus on security and privacy.

The script removes unnecessary features, disables telemetry, and configures Brave with more privacy-friendly defaults. It's ideal for users who value their privacy and want to reduce the attack surface of their browser while maintaining a functional and secure browsing experience.

## Features

- Detects Brave Browser installation via both Flatpak and traditional package managers (like `apt` or `pacman`).
- Automatically backs up Brave Browser profile and preferences before making changes.
- Disables telemetry, syncing, and various unwanted features like Brave Rewards, Brave Ads, and more.
- Creates a custom launcher to run Brave with improved privacy settings.
- Adds a desktop shortcut for easy access to the privacy-focused Brave browser.

## Supported Systems

- **SteamOS** (Arch-based with Flatpak)
- **Kali Linux** (Debian-based)

## Prerequisites

- **jq** (JSON processor) is required for modifying Brave's preferences. If it's not installed, the script will attempt to install it based on your distribution.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/null-p4n/bravesucks
   cd bravesucks

```

1.  Make the script executable:

    ```
    chmod +x brave-debloat.sh

    ```

2.  Run the script with appropriate privileges:

    ```
    ./brave-debloat.sh

    ```

    > **Note:** If running on a system with Flatpak, ensure that you have the Flatpak package of Brave installed before running the script.

Usage
-----

-   After running the script, a new custom Brave launcher will be created in `~/.local/bin/brave-private`. You can run Brave with enhanced privacy settings by executing:

    ```
    ~/.local/bin/brave-private

    ```

-   A desktop shortcut will also be created under `~/.local/share/applications/brave-private.desktop`, allowing you to launch Brave directly with privacy enhancements.

-   The script modifies Brave preferences to disable features like:

    -   Brave Rewards
    -   Brave Ads
    -   Brave Wallet
    -   Telemetry
    -   Syncing and background tasks

Troubleshooting
---------------

-   **Brave Browser Not Found:** If the script cannot detect your Brave installation, it will provide instructions to manually specify the path or run the browser once to generate necessary configuration files.

-   **jq Not Found:** The script will attempt to install `jq` automatically for Debian-based systems. If it's unavailable, you will be given instructions to manually install it.

Contributing
------------

If you find any issues or want to contribute to the script, feel free to fork the repository and create a pull request. Contributions are welcome!

License
-------

This project is licensed under the MIT License - see the [LICENSE](https://chatgpt.com/c/LICENSE) file for details.

```

This README provides clear information about the script, including what it does, how to install and use it, as well as troubleshooting tips. It should help others understand and benefit from your work on GitHub!

```
