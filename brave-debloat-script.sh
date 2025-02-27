#!/bin/bash

# Brave Browser Debloat & Privacy Enhancement Script
# Compatible with:
# - SteamOS (Arch-based with Flatpak packages)
# - Kali Linux (Debian-based)

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Brave Browser Privacy & Debloating Script ===${NC}\n"

# Check if running as root for hosts file modification
IS_ROOT=false
if [ "$EUID" -eq 0 ]; then
    IS_ROOT=true
fi

# Detect system type
IS_FLATPAK=false
IS_DEBIAN=false
IS_ARCH=false

# Detect if flatpak is installed
if command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}Flatpak detected, checking for Brave Browser...${NC}"
    # Check if Brave is installed as Flatpak - this is a more reliable check
    if flatpak list | grep -q "com.brave.Browser"; then
        IS_FLATPAK=true
        echo -e "${GREEN}✓ Confirmed Brave Browser is installed via Flatpak${NC}"
    fi
fi

# If not found via Flatpak, check traditional installations
if [ "$IS_FLATPAK" = false ]; then
    if command -v brave-browser &> /dev/null; then
        echo -e "${GREEN}Found Brave Browser installed natively${NC}"
    elif command -v brave &> /dev/null; then
        echo -e "${GREEN}Found Brave Browser installed natively (brave command)${NC}"
    else
        echo -e "${YELLOW}No native Brave installation found, rechecking Flatpak...${NC}"
        # Double-check Flatpak again with different methods
        if [ -d "$HOME/.var/app/com.brave.Browser" ]; then
            IS_FLATPAK=true
            echo -e "${GREEN}Found Brave Browser Flatpak directory${NC}"
        else
            # Try looking for the desktop file
            for LOCATION in "$HOME/.local/share/flatpak/exports/share/applications" "/var/lib/flatpak/exports/share/applications"; do
                if [ -f "$LOCATION/com.brave.Browser.desktop" ]; then
                    IS_FLATPAK=true
                    echo -e "${GREEN}Found Brave Browser Flatpak desktop file${NC}"
                    break
                fi
            done
        fi
    fi
fi

# If still not found, exit with error
if [ "$IS_FLATPAK" = false ] && ! command -v brave-browser &> /dev/null && ! command -v brave &> /dev/null; then
    echo -e "${RED}Error: Could not find Brave Browser installation.${NC}"
    echo -e "${YELLOW}If you're sure Brave is installed, please run it once to create necessary directories,${NC}"
    echo -e "${YELLOW}or specify the installation path manually by editing this script.${NC}"
    exit 1
fi

# Check OS type
if [ -f "/etc/os-release" ]; then
    source /etc/os-release
    if [[ "$ID" == "steamos" || "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
        IS_ARCH=true
        echo -e "${GREEN}Detected Arch-based system (SteamOS or similar)${NC}"
    elif [[ "$ID" == "kali" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
        IS_DEBIAN=true
        echo -e "${GREEN}Detected Debian-based system (Kali or similar)${NC}"
    else
        echo -e "${YELLOW}Unrecognized OS type: $ID${NC}"
        echo -e "${YELLOW}Continuing with generic Linux support${NC}"
    fi
fi

# Determine Brave executable based on installation method
BRAVE_EXEC=""
if [ "$IS_FLATPAK" = true ]; then
    BRAVE_EXEC="flatpak run com.brave.Browser"
elif command -v brave-browser &> /dev/null; then
    BRAVE_EXEC="brave-browser"
elif command -v brave &> /dev/null; then
    BRAVE_EXEC="brave"
fi

echo -e "${GREEN}Using Brave executable: $BRAVE_EXEC${NC}"

# Determine Brave profile location based on installation method
BRAVE_DIR=""
if [ "$IS_FLATPAK" = true ]; then
    # Check both possible Flatpak config locations
    if [ -d "$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser" ]; then
        BRAVE_DIR="$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser"
    else
        BRAVE_DIR="$HOME/.var/app/com.brave.Browser/.config/BraveSoftware/Brave-Browser"
    fi
else
    BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser"
fi

DEFAULT_PROFILE="Default"
PROFILE_DIR=""

# Check if profile directory exists
if [ -d "$BRAVE_DIR" ]; then
    if [ -d "$BRAVE_DIR/$DEFAULT_PROFILE" ]; then
        PROFILE_DIR="$BRAVE_DIR/$DEFAULT_PROFILE"
        echo -e "${GREEN}Found Brave profile at: $PROFILE_DIR${NC}"
    else
        # Try to find any profile directory
        PROFILE_DIR=$(find "$BRAVE_DIR" -type d -name "Profile*" 2>/dev/null | head -n 1)
        if [ -n "$PROFILE_DIR" ]; then
            echo -e "${GREEN}Found Brave profile at: $PROFILE_DIR${NC}"
        else
            echo -e "${YELLOW}No profile directory found in $BRAVE_DIR${NC}"
            echo -e "${YELLOW}Will continue with other configurations${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Brave configuration directory not found at: $BRAVE_DIR${NC}"
    echo -e "${YELLOW}Looking for alternative locations...${NC}"
    
    # Try alternative locations
    ALT_LOCATIONS=(
        "$HOME/.config/brave"
        "$HOME/.var/app/com.brave.Browser/config/brave"
        "$HOME/.var/app/com.brave.Browser/.config/brave"
    )
    
    for DIR in "${ALT_LOCATIONS[@]}"; do
        if [ -d "$DIR" ]; then
            BRAVE_DIR="$DIR"
            if [ -d "$DIR/$DEFAULT_PROFILE" ]; then
                PROFILE_DIR="$DIR/$DEFAULT_PROFILE"
            else
                PROFILE_DIR=$(find "$DIR" -type d -name "Profile*" 2>/dev/null | head -n 1)
            fi
            
            if [ -n "$PROFILE_DIR" ]; then
                echo -e "${GREEN}Found Brave directory at: $BRAVE_DIR${NC}"
                echo -e "${GREEN}Found Brave profile at: $PROFILE_DIR${NC}"
                break
            fi
        fi
    done
    
    if [ -z "$PROFILE_DIR" ]; then
        echo -e "${YELLOW}No Brave profile found. Have you run Brave at least once?${NC}"
        echo -e "${YELLOW}Will continue with other configurations${NC}"
    fi
fi

# Make backup of preferences if profile exists
if [ -n "$PROFILE_DIR" ]; then
    BACKUP_DIR="$HOME/brave-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo -e "${BLUE}Creating backup in $BACKUP_DIR${NC}"

    if [ -f "$PROFILE_DIR/Preferences" ]; then
        cp "$PROFILE_DIR/Preferences" "$BACKUP_DIR/Preferences.bak"
        echo -e "${GREEN}✓ Preferences backup created${NC}"
    fi

    if [ -f "$BRAVE_DIR/Local State" ]; then
        cp "$BRAVE_DIR/Local State" "$BACKUP_DIR/Local_State.bak"
        echo -e "${GREEN}✓ Local State backup created${NC}"
    fi
fi

# Check for jq installation or try to install it
JQ_AVAILABLE=false
if command -v jq &> /dev/null; then
    JQ_AVAILABLE=true
else
    echo -e "${YELLOW}jq not found. Attempting to install...${NC}"
    if [ "$IS_DEBIAN" = true ] && [ "$IS_ROOT" = true ]; then
        apt-get update && apt-get install -y jq && JQ_AVAILABLE=true
    elif [ "$IS_ARCH" = true ] && [ "$IS_ROOT" = true ]; then
        pacman -Sy --noconfirm jq && JQ_AVAILABLE=true
    elif [ "$IS_ROOT" = false ]; then
        echo -e "${YELLOW}Not running as root, can't install jq automatically.${NC}"
        echo -e "${YELLOW}Please install jq manually for better preference handling:${NC}"
        if [ "$IS_DEBIAN" = true ]; then
            echo -e "${YELLOW}  sudo apt-get update && sudo apt-get install -y jq${NC}"
        elif [ "$IS_ARCH" = true ]; then
            echo -e "${YELLOW}  sudo pacman -Sy --noconfirm jq${NC}"
        fi
    fi
fi

# Function to modify preferences - safer than direct editing
modify_preference() {
    KEY=$1
    VALUE=$2
    FILE=$3
    
    if [ -f "$FILE" ]; then
        if [ "$JQ_AVAILABLE" = true ]; then
            # Create a temporary file
            TEMP_FILE=$(mktemp)
            
            # Use jq to modify the preference
            jq "$KEY = $VALUE" "$FILE" > "$TEMP_FILE"
            
            # Check if jq was successful
            if [ $? -eq 0 ]; then
                mv "$TEMP_FILE" "$FILE"
                echo -e "${GREEN}✓ Set $KEY to $VALUE${NC}"
            else
                echo -e "${RED}Error: Failed to modify preference $KEY${NC}"
                rm "$TEMP_FILE"
            fi
        else
            echo -e "${YELLOW}Warning: 'jq' is not installed. Skipping preference modification.${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: File not found: $FILE${NC}"
    fi
}

# Create custom launch script based on installation method
echo -e "\n${BLUE}Creating custom Brave launch script${NC}"
LAUNCH_SCRIPT="$HOME/.local/bin/brave-private"
mkdir -p "$HOME/.local/bin"

# Different launch script content based on installation method
if [ "$IS_FLATPAK" = true ]; then
    cat > "$LAUNCH_SCRIPT" << EOL
#!/bin/bash

flatpak run com.brave.Browser \
  --disable-brave-sync \
  --disable-features=BraveRewards,BraveAds,BraveWallet,BraveNews,Speedreader,BraveAdblock,BraveSpeedreader,BraveVPN,Crypto,CryptoWallets \
  --disable-background-networking \
  --disable-component-extensions-with-background-pages \
  --disable-domain-reliability \
  --disable-features=InterestCohortAPI,Fledge,Topics,InterestFeedV2,UseChromeOSDirectVideoDecoder \
  --disable-sync-preferences \
  --disable-site-isolation-trials \
  --disable-prediction-service \
  --disable-remote-fonts \
  --disable-extensions-http-throttling \
  --disable-breakpad \
  --disable-speech-api \
  --disable-translate \
  --disable-sync \
  --disable-first-run-ui \
  --disable-client-side-phishing-detection \
  --disable-component-updater \
  --disable-suggestions-service \
  --disable-webgl \
  --no-pings \
  --no-report-upload \
  --no-service-autorun \
  --no-first-run \
  --aggressive-cache-discard \
  --metrics-recording-only \
  --clear-token-service \
  --reset-variation-state \
  --block-new-web-contents \
  --start-maximized \
  --incognito \
  "\$@"
EOL
else
    cat > "$LAUNCH_SCRIPT" << EOL
#!/bin/bash

$BRAVE_EXEC \
  --disable-brave-sync \
  --disable-features=BraveRewards,BraveAds,BraveWallet,BraveNews,Speedreader,BraveAdblock,BraveSpeedreader,BraveVPN,Crypto,CryptoWallets \
  --disable-background-networking \
  --disable-component-extensions-with-background-pages \
  --disable-domain-reliability \
  --disable-features=InterestCohortAPI,Fledge,Topics,InterestFeedV2,UseChromeOSDirectVideoDecoder \
  --disable-sync-preferences \
  --disable-site-isolation-trials \
  --disable-prediction-service \
  --disable-remote-fonts \
  --disable-extensions-http-throttling \
  --disable-breakpad \
  --disable-speech-api \
  --disable-translate \
  --disable-sync \
  --disable-first-run-ui \
  --disable-client-side-phishing-detection \
  --disable-component-updater \
  --disable-suggestions-service \
  --disable-webgl \
  --no-pings \
  --no-report-upload \
  --no-service-autorun \
  --no-first-run \
  --aggressive-cache-discard \
  --metrics-recording-only \
  --clear-token-service \
  --reset-variation-state \
  --block-new-web-contents \
  --start-maximized \
  --incognito \
  "\$@"
EOL
fi

chmod +x "$LAUNCH_SCRIPT"
echo -e "${GREEN}✓ Created private Brave launcher at: $LAUNCH_SCRIPT${NC}"
echo -e "${YELLOW}Run Brave with improved privacy using: $LAUNCH_SCRIPT${NC}"

# Create desktop entry for the private launcher
DESKTOP_ENTRY="$HOME/.local/share/applications/brave-private.desktop"
mkdir -p "$HOME/.local/share/applications"

# Determine the icon based on installation method
ICON_PATH="brave-browser"
if [ "$IS_FLATPAK" = true ]; then
    ICON_PATH="com.brave.Browser"
fi

cat > "$DESKTOP_ENTRY" << EOL
[Desktop Entry]
Version=1.0
Name=Brave (Private Mode)
GenericName=Web Browser - Privacy Mode
Comment=Access the Internet with enhanced privacy settings
Exec=$LAUNCH_SCRIPT %U
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOL

echo -e "${GREEN}✓ Created desktop launcher for private Brave${NC}"

# Disable flags via preference files
if [ -n "$PROFILE_DIR" ] && [ "$JQ_AVAILABLE" = true ]; then
    echo -e "\n${BLUE}Modifying Brave preferences${NC}"

    # Check if Brave is running
    if pgrep -f "brave" > /dev/null || pgrep -f "com.brave.Browser" > /dev/null; then
        echo -e "${YELLOW}Warning: Brave Browser is currently running.${NC}"
        echo -e "${YELLOW}Close Brave Browser and run this script again for full effect.${NC}"
    else
        # Modify preferences with jq
        PREF_FILE="$PROFILE_DIR/Preferences"
        if [ -f "$PREF_FILE" ]; then
            # Disable Brave Rewards
            modify_preference '.brave.rewards.enabled' 'false' "$PREF_FILE"
            modify_preference '.brave.rewards.hide_button' 'true' "$PREF_FILE"
            
            # Disable Brave Ads
            modify_preference '.brave.brave_ads.enabled' 'false' "$PREF_FILE"
            modify_preference '.brave.brave_ads.opted_in' 'false' "$PREF_FILE"
            
            # Disable Brave Wallet
            modify_preference '.brave.wallet.rpc_allowed_origins' '[]' "$PREF_FILE"
            modify_preference '.brave.wallet.keyring_lock_timeout_mins' '0' "$PREF_FILE"
            
            # Disable Telemetry
            modify_preference '.brave.p3a_enabled' 'false' "$PREF_FILE"
            modify_preference '.brave.stats.usage_ping_enabled' 'false' "$PREF_FILE"
            
            # Disable other features
            modify_preference '.brave.today.opted_in' 'false' "$PREF_FILE"
            modify_preference '.brave.ipfs.enabled' 'false' "$PREF_FILE"
            
            echo -e "${GREEN}✓ Updated Brave preferences${NC}"
        else
            echo -e "${YELLOW}Warning: Preferences file not found at $PREF_FILE${NC}"
        fi
        
        # Modify Local State file to disable flags
        LOCAL_STATE_FILE="$BRAVE_DIR/Local State"
        if [ -f "$LOCAL_STATE_FILE" ]; then
            FLAGS_TO_DISABLE=(
                "brave-news"
                "brave-speedreader"
                "brave-wallet"
                "brave-ads-custom-push-notifications"
                "brave-vpn"
                "ipfs"
            )
            
            for FLAG in "${FLAGS_TO_DISABLE[@]}"; do
                modify_preference ".browser.enabled_labs_experiments |= (. - [\"$FLAG\"])" "." "$LOCAL_STATE_FILE"
            done
            
            echo -e "${GREEN}✓ Disabled Brave flags in Local State file${NC}"
        else
            echo -e "${YELLOW}Warning: Local State file not found at $LOCAL_STATE_FILE${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Skipping preference modifications due to missing profile or jq${NC}"
    echo -e "${YELLOW}Manual configuration recommended:${NC}"
    echo -e "1. Visit brave://settings/ and disable Brave Rewards, Ads, and Wallet"
    echo -e "2. Visit brave://flags/ and disable unwanted features"
fi

# Block Brave's telemetry at network level
echo -e "\n${BLUE}Setting up network-level blocks${NC}"

HOSTS_ENTRIES=(
    "0.0.0.0 variations.brave.com"
    "0.0.0.0 go-updater.brave.com"
    "0.0.0.0 componentupdater.brave.com"
    "0.0.0.0 crlsets.brave.com"
    "0.0.0.0 laptop-updates.brave.com"
    "0.0.0.0 brave-core-ext.s3.brave.com"
    "0.0.0.0 grant.rewards.brave.com"
    "0.0.0.0 stats.brave.com"
    "0.0.0.0 p3a.brave.com"
    "0.0.0.0 analytics.brave.com"
    "0.0.0.0 rewards.brave.com"
    "0.0.0.0 pcdn.brave.com"
)

if [ "$IS_ROOT" = true ]; then
    # Backup hosts file
    cp /etc/hosts "$BACKUP_DIR/hosts.bak"
    echo -e "${GREEN}✓ Created hosts file backup${NC}"
    
    # Check if entries already exist
    MODIFIED=false
    for ENTRY in "${HOSTS_ENTRIES[@]}"; do
        if ! grep -q "$ENTRY" /etc/hosts; then
            echo "$ENTRY" >> /etc/hosts
            MODIFIED=true
        fi
    done
    
    if [ "$MODIFIED" = true ]; then
        echo -e "${GREEN}✓ Added Brave telemetry domains to /etc/hosts${NC}"
    else
        echo -e "${GREEN}✓ All Brave telemetry domains already blocked in /etc/hosts${NC}"
    fi
else
    echo -e "${YELLOW}Not running as root, cannot modify /etc/hosts file.${NC}"
    echo -e "${YELLOW}To block Brave telemetry domains, add these lines to /etc/hosts:${NC}"
    for ENTRY in "${HOSTS_ENTRIES[@]}"; do
        echo -e "   $ENTRY"
    done
    echo -e "${YELLOW}Run: sudo nano /etc/hosts${NC}"
fi

# Create a local DNS blocker script as alternative
DNS_BLOCK_SCRIPT="$HOME/.local/bin/brave-dns-block.sh"

cat > "$DNS_BLOCK_SCRIPT" << 'EOL'
#!/bin/bash

# Block Brave browser telemetry using iptables/nftables
# Run with sudo permissions

BRAVE_DOMAINS=(
    "variations.brave.com"
    "go-updater.brave.com"
    "componentupdater.brave.com"
    "crlsets.brave.com"
    "laptop-updates.brave.com"
    "brave-core-ext.s3.brave.com"
    "grant.rewards.brave.com"
    "stats.brave.com"
    "p3a.brave.com"
    "analytics.brave.com"
    "rewards.brave.com"
    "pcdn.brave.com"
)

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Detect which firewall tool is available
if command -v nft &> /dev/null; then
    echo "Using nftables for firewall rules..."
    USE_NFTABLES=true
elif command -v iptables &> /dev/null; then
    echo "Using iptables for firewall rules..."
    USE_NFTABLES=false
else
    echo "No firewall tool found (neither nftables nor iptables). Exiting."
    exit 1
fi

echo "Blocking Brave telemetry domains..."

for DOMAIN in "${BRAVE_DOMAINS[@]}"; do
    # Get IP addresses for the domain
    IPS=$(dig +short "$DOMAIN" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
    
    if [ -z "$IPS" ]; then
        echo "No IP found for $DOMAIN, skipping"
        continue
    fi
    
    for IP in $IPS; do
        if [ "$USE_NFTABLES" = true ]; then
            # Using nftables
            # Check if the table exists
            if ! nft list tables | grep -q "brave_block"; then
                nft add table inet brave_block
                nft add chain inet brave_block output { type filter hook output priority 0 \; }
            fi
            
            # Add the rule if it doesn't exist
            if ! nft list table inet brave_block | grep -q "$IP"; then
                nft add rule inet brave_block output ip daddr $IP drop
                echo "Blocked $DOMAIN ($IP) using nftables"
            else
                echo "$DOMAIN ($IP) already blocked in nftables"
            fi
        else
            # Using iptables
            if ! iptables -C OUTPUT -d "$IP" -j REJECT 2>/dev/null; then
                iptables -A OUTPUT -d "$IP" -j REJECT
                echo "Blocked $DOMAIN ($IP) using iptables"
            else
                echo "$DOMAIN ($IP) already blocked in iptables"
            fi
        fi
    done
done

echo "Brave telemetry blocking complete"
EOL

chmod +x "$DNS_BLOCK_SCRIPT"
echo -e "${GREEN}✓ Created DNS blocking script at: $DNS_BLOCK_SCRIPT${NC}"
echo -e "${YELLOW}Run with: sudo $DNS_BLOCK_SCRIPT${NC}"

# Create a Flatpak-specific override for Brave if needed
if [ "$IS_FLATPAK" = true ]; then
    echo -e "\n${BLUE}Setting up Flatpak-specific overrides for Brave${NC}"
    
    # Check if flatpak override command works
    if flatpak override --user com.brave.Browser --no-autostart &>/dev/null; then
        echo -e "${GREEN}✓ Created Flatpak override to disable autostart${NC}"
        
        # Add more privacy-enhancing overrides
        flatpak override --user com.brave.Browser --nosocket=session-bus &>/dev/null
        flatpak override --user com.brave.Browser --nofilesystem=xdg-download/brave-telemetry &>/dev/null
        
        echo -e "${GREEN}✓ Applied additional Flatpak privacy overrides${NC}"
    else
        echo -e "${YELLOW}Unable to create Flatpak overrides. You may need to run:${NC}"
        echo -e "${YELLOW}flatpak override --user com.brave.Browser --no-autostart${NC}"
        echo -e "${YELLOW}This is optional and won't affect the main functionality${NC}"
    fi
fi

# Final summary
echo -e "\n${BLUE}=== Setup Complete ===${NC}"
echo -e "${GREEN}Brave Browser has been configured for enhanced privacy:${NC}"
echo -e "1. Created private launcher: ${YELLOW}$LAUNCH_SCRIPT${NC}"
echo -e "2. Added desktop shortcut: ${YELLOW}Brave (Private Mode)${NC}"
echo -e "3. Created network blocking tools"

if [ -n "$PROFILE_DIR" ] && [ "$JQ_AVAILABLE" = true ]; then
    echo -e "4. Modified browser preferences"
fi

if [ "$IS_FLATPAK" = true ]; then
    echo -e "5. Applied Flatpak-specific overrides"
fi

echo -e "\n${BLUE}=== Recommended Additional Steps ===${NC}"
echo -e "1. Manually verify settings at: ${YELLOW}brave://settings/privacy${NC}"
echo -e "2. Verify flag settings at: ${YELLOW}brave://flags/${NC}"
echo -e "3. Consider using a privacy-focused DNS like NextDNS or Pi-hole"
echo -e "4. Install the following privacy extensions:"
echo -e "   - uBlock Origin"
echo -e "   - Privacy Badger"
echo -e "   - ClearURLs"

if [ "$IS_DEBIAN" = true ] && [ "$IS_ROOT" = false ]; then
    echo -e "\n${YELLOW}For Kali/Debian systems:${NC}"
    echo -e "Run this script with sudo for full functionality: ${YELLOW}sudo $0${NC}"
fi

echo -e "\n${GREEN}Launch privacy-focused Brave with: $LAUNCH_SCRIPT${NC}"
