# Intrusion Report

## Services

### Failed Authentication

- Target user(s): `cdc`, `redputer3`, `redputer$3`, `john.leguizamo`, `root`
- Machines(s): all
- Volume of attack(s): Minimal

```js
Apr 25 13:58:18 db.team8.isucdc.com sshd[395]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=12.110.242.128  user=root
Apr 25 13:58:22 db.team8.isucdc.com sshd[404]: pam_sss(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=12.110.242.128 user=john.leguizamo
Apr 25 13:58:20 db.team8.isucdc.com sshd[397]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=12.110.242.128  user=cdc
Apr 25 13:58:20 db.team8.isucdc.com sshd[397]: pam_sss(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=12.110.242.128 user=cdc
Apr 25 14:34:32 db.team8.isucdc.com sshd[500]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=12.110.242.128  user=redputer3$
Apr 25 14:34:32 db.team8.isucdc.com sshd[500]: pam_sss(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=12.110.242.128 user=redputer3$
Apr 25 14:35:10 db.team8.isucdc.com sshd[511]: pam_sss(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=12.110.242.128 user=redputer3
```



### Compromises

#### AD

The AD was compromised via local persistence and credential theft. The attacker established a "beachhead" using elevated service accounts and modified registry permissions to prevent administrative removal of malicious tasks.

Following a full remediation protocol—including ownership seizure and Kerberos key rotation—the system has been stabilized and unauthorized access has been terminated.

##### Attacker Persistence

Analysis of the `HKLM` registry hive and system logs identified three primary methods of persistence:

- Registry Hijacking: The attacker applied a custom Security Descriptor (SD) to the `TaskCache`\Tree registry keys. This created a "logic lock" that returned Access Denied errors even when the Domain Administrator attempted to delete the malicious entries.     Malicious Scheduled Tasks: Two specific back-doors were identified:

- Fake *"Proxy"*: Likely used for command-and-control (C2) tunneling.
- Fake *"Windows Error Reporting"*: A masqueraded task used to execute malicious binaries with SYSTEM-level privileges.
- **Unauthorized Account**: A back-door local user named `scrat` was created and assigned to the local Administrator
- **Password Complexity**: Not quite persistence in the traditional methods, however the password complexity requirements were raised to extremely high standards to inhibit our retrieval of compromised credentials.
- **De-escalation**: Removed our permissions to view `sysvol.`

##### Remediation Actions Taken

To reclaim the environment, the following engineering steps were executed:

- Ownership Seizure: The attacker had practically *locked* the registry keys, the `Owner` attribute was manually reassigned to the `Administrators` group. The "`Replace owner on sub-containers and objects`" flag was utilized to force-propagate permissions down to the hidden malicious tasks, *allowing for their successful deletion*.

- Kerberos Invalidation: the attacker had achieved `SYSTEM` access, the Domain's Kerberos keys were considered compromised—to invalidate any forged "Golden Tickets," the following was performed:

  - `krbtgt` Password Rotation: The password for the `krbtgt` account was reset twice.

  - Ticket Cache Purge: The command `klist purge -li 0x3e7` was executed to clear all existing tickets from the `SYSTEM` session memory.

- Service Hardening Several services frequently used for pivoting were audited and disabled to prevent re-infection:    

  - Disabled `WinHttpAutoProxySvc`.

  - Template Services: Registry-level hardening was applied to `CDPUserSvc` and `OneSyncSvc` to prevent them from acting as triggers for the attacker's scripts.

##### Final Security Posture

- **Persistence Status**: All "Proxy" and "Error Reporting" tasks have been deleted from both the Registry and the physical `C:\Windows\System32\Tasks` directory.
- **Account Status**: The scrat user has been removed.
- **Integrity Check**: A `WMI` audit confirmed no "*headless*" Event Consumers remain in the root\subscription name-space.
- **Verification**: Post-remediation logs show no further unauthorized Event 4672 (Special Privileges Assigned) logins.