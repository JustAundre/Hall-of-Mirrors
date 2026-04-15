# Network Change Report

<small>YYYY Day-nth of Month -- Timezone hh:mm AM/PM</small>

## Network Layout

[Network Diagram goes here.]

Rationale: Placed XYZ and ABC into the DMZ, DEF acts as a network filter to the rest of the network; that way systems don't need to handle things like DDoS or brute-force attacks independently, where bans apply network-wide.

## Overview

### Existing Servers

| Hostname Prefix | IP (Local) | IP (Public) | OS |
| --- | --- | --- | --- |
| ad | `10.10.10.10` | `36.3.5.10` | Windows Server (2025) |
| admin | `10.2.5.20` | `36.3.5.20` | Windows Server (2022) |
| dev | `10.2.5.30` | `36.3.5.30` | Windows Server (2022) |
| www | `10.2.5.40` | `36.3.5.40` | Alma Linux 9 |
| db | `10.2.5.50` | `36.3.5.50` | Alma Linux 8.6 |

### Added Servers

| Hostname Prefix | IP (Local) | IP (Public) | OS | Purpose |
| --- | --- | --- | --- |
| rsyslog | `10.2.5.20` | `36.3.5.20` | Ubuntu Server 24.04 LTS | Remote logging to prevent deletion of evidence and to assist in ease of access to logs via a unified front. |
| wazuh | `10.2.5.30` | `36.3.5.30` | Ubuntu Server 24.04 LTS | Wazuh (the software) is rather flexibile in parsing logs and easily is able to filter through logs while having a nice-looking dashboard—there is hardly ever a reason to not use it. |

## Server ABC (Template)

### System & Service Configuration

#### SSH

| Configuration | Old Value | New Value | Rationale |
| --- | --- | --- | --- |
| PermitRootLogin | Yes | No | Administrators should go through proper sign-in channels so that accountability may be properly enforced. |

#### LDAP(S)

| Configuration | Old Value | New Value | Rationale |
| --- | --- | --- | --- |
| Certificate Validation | `Disabled` | `Verify CA Chain` | Prevents Man-in-the-Middle (MitM) attacks by ensuring the server certificate is signed by a trusted Authority. |

### Software Changes

| Name | Action | Rationale |
| --- | --- | --- |
| Wazuh | Add (+) | A File Integrity Monitoring (FIM) service is a much needed piece of software which allows the aggregated monitoring of system security events and integrity. |
| John the Ripper | Remove (-) | A cracking tool known for being used to violate the integrity of files and systems should not/does not need to be on a production system. |

### Codebase Changes

| Codebase Name | File Path | Description | Rationale |
| --- | --- | --- | --- |
| Frontend 1 | /var/lib/www-data/login/success | Replaced visible error verboseness with generic error codes | A security via obscurity type move—reduces information leakage of edge-cases. |

### Firewall

Firewall Software: `FirewallD`

| Direction | Port | IP | Type | Allowed |
| --- | --- | --- | --- | --- |
| In | ALL | ALL | ALL | TCP & UDP | No |
| In | ALL | ALL | ALL | TCP & UDP | Yes |
| In | ALL | 80 | ALL | TCP & UDP | Yes |
| In | ALL | 22 | ALL | TCP & UDP | Yes |
| In & Out | ALL | ALL | ALL | ICMP timestamp requests | No |
| In & Out | ALL | ALL | ALL | ICMP ping packets | No |

Rationale: Having the firewall use a whitelist approach while the outgoing use a blacklist is by far one of the most easiest firewall types to set up as having a whitelist for **outgoing** packets would lead to many levels of breakage if not configured with the utmost care and attention to *everything*. Additionally, a whitelist approach for **incoming** packets strikes a balance of ease of use, usability/availability as the range of packets that for a fact ***need*** to come in are much more scarce and specific. Touching on the ICMP timestamp request block, that specific types of ICMP ping grabs the timestamp of the server which is a form of reconnaissance, so it has been negated.

## Server XYZ (Copy and fill out as needed)

<small>Fill out using the above example appropriately and remove this tag.</small>