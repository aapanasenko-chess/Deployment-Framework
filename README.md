# Enterprise Windows Deployment & Disaster Recovery Toolkit

A production-ready PowerShell framework designed for system administrators to automate the full lifecycle of Windows workstation provisioning, data migration, and disaster recovery in strictly isolated corporate environments.

## Key Features

* **WMI/CIM-Driven BitLocker Recovery:** Automatically detects, filters, and unlocks encrypted volumes using numerical passwords, passphrases, or external `.BEK` keys.
* **Smart Data Profiling & Migration:** Parses storage drives to isolate user profiles, completely filters out system junk (Windows, Program Files, MSOCache, Recycle Bin), and stages data or encapsulates it into uncompressed `.Wim` images using native `DISM` calls for maximum speed.
* **Bare-Metal OS Deployment:** Automates disk partitioning for both modern **UEFI/GPT** (creating System, MSR, and Windows partitions) and legacy **MBR** layouts. Handles automated image application (`.wim`, `.esd`, `.swm`) via DISM and injects `unattend.xml` and shell layouts on the fly.
* **Isolated Network Initialization:** Features a self-contained module to configure static IP parameters and scan the subnet for available free IP addresses to establish connections when DHCP or SCCM clients fail due to strict firewall rules.
* **XML-Driven Configuration (Infrastructure-as-Code):** Dynamically applies domain staging parameters based on a centralized XML configuration file.
