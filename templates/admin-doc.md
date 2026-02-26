# Network Change Report

<small>YYYY Day-nth of Month -- Timezone hh:mm AM/PM</small>


## Network Layout

[Network Diagram goes here.]

Rationale: placed XYZ and ABC into the DMZ, DEF acts as a network filter to the rest of the network; that way systems don't need to handle things like DDoS or brute-force attacks independently, where bans apply network-wide.

<small>Completely made up, please replace the above with your actual rationale and remove this tag.</small>


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

| Hostname Prefix | IP (Local) | IP (Public) | OS |
| --- | --- | --- | --- |
| rsyslog | `10.2.5.2` | `36.3.5.2` | Ubuntu Server 24.04 LTS |
| wazuh | `10.2.5.3` | `36.3.5.3` | Ubuntu Server 24.04 LTS |


## Example System


### System & Service Configuration


#### SSH

| Configuration | Old Value | New Value | Rationale |
| --- | --- | --- | --- |
| PermitRootLogin | Yes | No | Administrators should go through proper sign-in channels so that accountability may be properly enforced. |


#### LDAP(S)

| Configuration | Old Value | New Value | Rationale |
| --- | --- | --- | --- |
| Certificate Validation | `Disabled` | `Verify CA Chain` | Prevents Man-in-the-Middle (MitM) attacks by ensuring the server certificate is signed by a trusted Authority. |


### Software Modification

| Name | Action | Rationale |
| --- | --- | --- |
| Wazuh | + | A File Integrity Monitoring (FIM) service is a much needed piece of software which allows the aggregated monitoring of system security events and integrity. |
| John the Ripper | - | A cracking tool known for being used to violate the integrity of files and systems should not/does not need to be on a production system. |


### Codebase Changes

| Codebase Name | File Path | Description | Rationale |
| --- | --- | --- | --- |
| Frontend 1 | /var/lib/www-data/login/success | Replaced visible error verboseness with generic error codes | A security via obscurity type move--reduces information leakage of edge-cases. |


### Firewall Configuration

Firewall Software: FirewallD

| Direction | Port | IP | Type | Allowed |
| --- | --- | --- | --- | --- |
| In | ALL | ALL | ALL | TCP & UDP | No |
| In | ALL | ALL | ALL | TCP & UDP | Yes |
| In | ALL | 80 | ALL | TCP & UDP | Yes |
| In | ALL | 22 | ALL | TCP & UDP | Yes |
| In & Out | ALL | ALL | ALL | ICMP timestamp requests | No |

Rationale: Having the firewall use a whitelist approach while the outgoing use a blacklist is by far one of the most easiest firewall types to set up as having a whitelist for **outgoing** packets would lead to many levels of breakage if not configured with the utmost care and attention to *every*thing. Additionally, a whitelist approach for **incoming** packets strikes a balance of ease of use, usability/availability as the range of packets that for a fact ***neeeeed*** to come in are much more scarce and specific. Touching on the ICMP timestamp request block, those specific type of ICMP pings grab the timestamp of the server which is a form of reconissaince, so it has been negated.

## AD/ADMIN/WWW/DEV/DB

<small>Empty--fill out using the above example appropriately and remove this tag.</small>