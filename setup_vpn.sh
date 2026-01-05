#!/bin/bash

# setup_vpn.sh
# Automates IKEv2 VPN setup with StrongSwan and NetworkManager based on the README guide.

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== IKEv2 VPN Setup Script ===${NC}"

# 1. Gather Inputs
read -p "Enter VPN Connection Name (e.g., MyCorpVPN): " VPN_NAME
if [ -z "$VPN_NAME" ]; then echo -e "${RED}Error: VPN Name is required.${NC}"; exit 1; fi

read -p "Enter Server Gateway Address (e.g., vpn.example.com): " SERVER_ADDRESS
if [ -z "$SERVER_ADDRESS" ]; then echo -e "${RED}Error: Server Address is required.${NC}"; exit 1; fi

read -p "Enter Internal DNS IP (e.g., 10.27.27.2): " DNS_IP
if [ -z "$DNS_IP" ]; then echo -e "${RED}Error: DNS IP is required.${NC}"; exit 1; fi

# 2. Find .p12 file
P12_FILE=$(find . -maxdepth 1 -name "*.p12" -print -quit)

if [ -z "$P12_FILE" ]; then
    echo -e "${RED}Error: No .p12 file found in the current directory.${NC}"
    exit 1
fi

echo -e "${GREEN}Found P12 file: $P12_FILE${NC}"

# 3. Prepare Directory and Extract Certs
VPN_DIR="$HOME/vpn"
mkdir -p "$VPN_DIR"

echo "Extracting certificates to $VPN_DIR..."

# Define paths
CA_CERT="$VPN_DIR/ca.crt"
USER_CERT="$VPN_DIR/client.crt"
PRIVATE_KEY="$VPN_DIR/client.key"

# Extract CA Certificate
openssl pkcs12 -in "$P12_FILE" -cacerts -nokeys -out "$CA_CERT"

# Extract User Certificate
openssl pkcs12 -in "$P12_FILE" -clcerts -nokeys -out "$USER_CERT"

# Extract Private Key
openssl pkcs12 -in "$P12_FILE" -nocerts -nodes -out "$PRIVATE_KEY"

# Set permissions for private key
chmod 600 "$PRIVATE_KEY"

echo -e "${GREEN}Certificates extracted successfully.${NC}"

# 4. Configure NetworkManager
echo "Creating NetworkManager connection..."

# Construct vpn.data string
# Key mappings for nm-strongswan:
# address: Gateway
# certificate: User Certificate path
# key: Private Key path
# ca: CA Certificate path
# method: authentication method (key = certificate/private key)
# virtual: Request inner IP (yes)
# encap: Enforce UDP encapsulation (yes)
# ike: Phase 1 algorithms
# proposal: Phase 2 (ESP) algorithms

VPN_DATA="address=$SERVER_ADDRESS,certificate=$USER_CERT,key=$PRIVATE_KEY,ca=$CA_CERT,method=key,virtual=yes,encap=yes,ike=aes256-sha256-modp2048,proposal=aes128gcm16"

# Create connection
# ipv4.method auto: Automatic (DHCP)
# ipv4.never-default yes: Use this connection only for resources on its network (Split Tunneling)
# ipv4.dns: Set internal DNS

nmcli connection add \
    type vpn \
    vpn-type strongswan \
    con-name "$VPN_NAME" \
    ifname "*" \
    vpn.data "$VPN_DATA" \
    ipv4.method auto \
    ipv4.never-default yes \
    ipv4.dns "$DNS_IP"

echo -e "${GREEN}Success! VPN connection '$VPN_NAME' has been created.${NC}"
echo "You can verify settings in your Network Manager GUI or connect using: nmcli con up \"$VPN_NAME\""
