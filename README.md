```

### **Brave Browser Privacy Debloating Script**

**Purpose**:\
This script is designed to help users enhance their privacy and security when using the Brave browser by modifying its default settings. It focuses on "debloating" Brave by removing unwanted features, adjusting settings to prioritize privacy, and automating tasks that may otherwise be tedious for users who value their online privacy. It also provides the option to create backups of Brave's profile data and preferences for easy recovery in case of issues.

**Why This Script is Helpful**:\
Brave is an excellent browser that blocks ads, trackers, and respects user privacy. However, by default, some features in Brave may still undermine privacy or create unnecessary overhead. For example, certain settings like telemetry, sync, and fingerprinting protection might not be fully optimized for privacy-conscious users. This script automates the process of making Brave more secure and privacy-focused by:

-   Disabling fingerprinting, telemetry, and data collection.
-   Removing unnecessary features and services that may compromise privacy.
-   Customizing the Brave profile to prioritize secure and private browsing habits.
-   Backing up and restoring configuration files to ensure users can always return to their preferred settings.

This script is designed to be a starting point for users who want to fine-tune their Brave browser for maximum privacy, but it can also be easily customized for further debloating or integration into a more complex privacy-focused setup.

**How This Script Works**:\
The script automates the following tasks:

1.  **Detection and Installation**:

    -   It checks whether the necessary tools (e.g., `jq` for JSON manipulation) are installed on your system, and installs them if they are not present.
    -   It identifies whether the user is on a Debian-based or Arch-based system and adapts installation procedures accordingly.
2.  **Backup Creation**:

    -   The script creates backups of critical Brave profile data (such as `Preferences` and `Local State`), allowing users to restore their settings if needed.
3.  **Debloating Brave**:

    -   It modifies Brave's settings to disable features that may pose privacy risks, such as telemetry and other data collection mechanisms.
    -   It creates a custom Brave shortcut that launches a more privacy-optimized instance of the browser, with preferences already configured for secure browsing.
4.  **Profile Directory Detection**:

    -   The script automatically detects the correct Brave profile directory, even if the user has custom profiles, ensuring that the script applies changes to the correct configuration.
5.  **System Customization**:

    -   The script adjusts Brave's internal settings, ensuring that the browser is configured to maximize privacy, disable tracking, and prevent fingerprinting.

**Features**:

-   **Debloats Brave**: Removes unnecessary Brave features that can compromise user privacy.
-   **Backup Functionality**: Creates backups of Brave profile data to ensure the user's settings can be restored at any time.
-   **Automatic Setup**: Installs required tools (`jq`), detects system type (Debian-based or Arch-based), and customizes Brave according to the user's needs.
-   **User-Friendly Feedback**: Provides helpful messages and error handling throughout the process, so users always know what's happening.
-   **Custom Brave Launch Script**: Automatically creates a launch script with the optimal configuration for a privacy-first experience.
 
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
