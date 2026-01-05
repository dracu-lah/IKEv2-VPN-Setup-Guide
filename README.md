# IKEv2 VPN Setup Guide (Linux)

A comprehensive guide for manually configuring a corporate IKEv2 VPN on Linux using **NetworkManager** and **strongSwan**. This configuration mirrors the security requirements typically found on corporate IKEv2 servers (e.g., GCM-AES encryption).

---

## 📋 Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Automated Setup](#2-automated-setup)
3. [Manual File Preparation](#3-manual-file-preparation)
4. [Manual Configuration Steps](#4-manual-configuration-steps)
5. [DNS Configuration](#5-dns-configuration)

---

## 1. Prerequisites
Install the IKEv2 plugin for NetworkManager based on your distribution:

**Arch Linux**
```bash
sudo pacman -S networkmanager-strongswan strongswan
```

**Ubuntu / Debian**
```bash
sudo apt update
sudo apt install network-manager-strongswan libcharon-extra-plugins
```

**Fedora**
```bash
sudo dnf install NetworkManager-strongswan-gnome
```

---

## 2. Automated Setup
For convenience, a script is provided to automate file extraction and connection setup.

1. Ensure your `.p12` file is in the same directory as the script.
2. Run the setup script:
   ```bash
   ./setup_vpn.sh
   ```
3. Follow the prompts to enter:
   - **VPN Connection Name**
   - **Gateway Address**
   - **Internal DNS IP**

The script will extract certificates to `~/vpn` and configure the NetworkManager connection with the correct security settings.

---

## 3. Manual File Preparation
VPN credentials often come in a `.p12` (PKCS#12) container. These must be extracted for use with NetworkManager.

1. Create a workspace:
   ```bash
   mkdir -p ~/vpn && cd ~/vpn
   ```
2. Move your `.p12` file to this folder and run the following commands (replace `yourfile.p12` with your filename):

   ```bash
   # Extract CA Certificate
   openssl pkcs12 -in yourfile.p12 -cacerts -nokeys -out ca.crt

   # Extract User Certificate
   openssl pkcs12 -in yourfile.p12 -clcerts -nokeys -out client.crt

   # Extract Private Key
   openssl pkcs12 -in yourfile.p12 -nocerts -nodes -out client.key
   ```

---

## 4. Manual Configuration Steps

### Step A: Basic Connection Setup
1. Open **Network Settings**, click the **+** (plus) icon, and select **IPsec/IKEv2 (strongswan)**.
2. **Gateway:** Enter the server address (e.g., `vpn.example.com`).
3. **Authentication:** Select **Certificate/private key**.
4. **Certificates:** Point the fields to the files created in `~/vpn`:
   - **CA Certificate:** `ca.crt`
   - **User Certificate:** `client.crt`
   - **Private Key:** `client.key`

| Create Connection | Identity Config |
| :---: | :---: |
| ![Create VPN](screenshots/create_vpn.png) | ![Basic Config](screenshots/basic_config.png) |

---

### Step B: Cipher & Algorithm Proposals
To ensure compatibility with modern security standards (Windows-style GCM-AES), click the **Algorithms** button:

* **Phase 1 (IKE):** `aes256-sha256-modp2048`
* **Phase 2 (ESP):** `aes128gcm16`
* **Options:**
    - [x] Request an inner IP address
    - [x] Enforce UDP encapsulation

| Options | Algorithms |
| :---: | :---: |
| ![Options Settings](screenshots/options.png) | ![Algorithm Settings](screenshots/algorithms.png) |

---

### Step C: IPv4, DNS & Split Tunneling
1. Go to the **IPv4 Settings** tab.
2. **Method:** Set to **Automatic (DHCP) addresses only**.
3. **DNS:** Enter your internal DNS IP (e.g., `10.27.27.2`).
4. **Routes:** Click **Routes...** and check **"Use this connection only for resources on its network"** (Split Tunneling).

| IPv4 & DNS | Routing Verification |
| :---: | :---: |
| ![IPv4 and Routing](screenshots/routing_dns.png) | ![Routing Check](screenshots/routing_dns_check.png) |

---

## 5. DNS Configuration
If your VPN connects but internal hostnames do not resolve, ensure `systemd-resolved` is managing your DNS.

```bash
# Enable and start systemd-resolved
sudo systemctl enable --now systemd-resolved

# Link systemd-resolved to /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```