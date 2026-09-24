# Active Directory Domain Join & Staging Submodule

This subdirectory contains the automated environment readiness and domain enrollment engine, driven by centralized XML data models.

## 📁 Files Structure

*   `JoinDomainScript_(Draft).ps1`: The advanced matrix orchestration script that automates system renaming and secure Active Directory domain injection based on hardware profiles and network subnet mapping.
*   `myxml.xml`: The underlying infrastructure metadata schema holding Site IDs, Organizational Unit (OU) targets, domain references, and hardware type mappings.

## 🌟 Advanced Staging Features

### 🗺️ Subnet-to-Site Topology Mapping
Unlike rigid, hardcoded deployment scripts, this solution dynamically evaluates the local network configuration during execution. It queries the physical network adapter context via native CIM instances, retrieves the current gateway or DHCP boundaries, and automatically matches them against the `<SiteIdentification>` matrix within the configuration XML to dynamically resolve the corporate branch location (SiteID).

### 📐 Multi-Dimensional OU Matrix Selection
The staging core correlates two independent data tracks in real-time to pick the exact target Organizational Unit (OU) inside Active Directory:
1.  **Chassis Type Verification:** Inspects local battery controllers and system enclosure configurations (`Win32_SystemEnclosure`) to determine if the target platform is a Mobile/Laptop or a Stationary/Desktop unit.
2.  **Location Staging:** Cross-references the resolved network SiteID.
The framework intersects these metrics to dynamically route the computer object into isolated, location-specific containers (e.g., `OU=notebook-1097,DC=loc`), completely eliminating manual administrative mistakes during massive OS provisioning.

### 🔄 Fault-Tolerant Schema Self-Recovery
The initialization module includes automated schema verification logic. If critical XML configuration tags are left unpopulated or missing, the script halts automated execution and engages interactive prompt overlays (`Read-Host`). Once the administrator inputs the necessary service records, the engine dynamically modifies the XML object tree in memory and **commits the corrected schema structure directly back to the physical disk**, ensuring subsequent non-interactive deployments run smoothly.
