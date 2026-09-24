# Wazuh SIEM & File Integrity Monitoring (FIM) Deployment

Enterprise SIEM deployment and real-time File Integrity Monitoring (FIM) lab built on a dedicated Ubuntu 22.04 manager node and a Windows 10 target endpoint. This repository documents the installation, agent enrollment, centralized syscheck configuration, and live detection of privilege escalation and unauthorized file modifications.

---

## Architecture & Network Topology

The lab operates on a bridged host network interface (`enp4s0`), isolating the SIEM infrastructure while allowing direct agent-manager telemetry transmission.

```
+------------------------------------+       +------------------------------------+
|        Wazuh SIEM Manager          |       |      Windows Target Endpoint       |
|            (Wazuh-Lab)             |       |            (Win10-Clean)           |
|         IP: 192.168.1.48           |       |         IP: 192.168.1.50           |
|                                    |       |                                    |
|  - Wazuh Indexer (Port 9200)       | <---> |  - Wazuh Agent v4.12.0             |
|  - Wazuh Manager (Ports 1514/1515) |       |  - Syscheck Real-time FIM          |
|  - Wazuh Dashboard (HTTPS/443)     |       |  - Windows Event Log Forwarder     |
+------------------------------------+       +------------------------------------+
```

- **SIEM Manager Node (`Wazuh-Lab`)**: Ubuntu 22.04 LTS running Wazuh Manager 4.12.0, OpenSearch-backed Indexer, and HTTPS Dashboard.
- **Windows Endpoint (`Win10-Clean`)**: Windows 10 Pro running Wazuh Agent 4.12.0 with Windows Event Channel logging and Syscheck FIM modules active.

---

## Centralized FIM Configuration (`agent.conf`)

Real-time File Integrity Monitoring was configured centrally on the Manager node within `/var/ossec/etc/shared/default/agent.conf` to enforce uniform monitoring policies across all connected Windows agents without requiring individual endpoint edits.

```xml
<agent_config os="Windows">
  <syscheck>
    <disabled>no</disabled>
    <frequency>300</frequency>
    <directories check_all="yes" realtime="yes">C:\Users\sanji\Desktop\FIM_Test</directories>
  </syscheck>
</agent_config>
```

---

## Detection Verification & Telemetry Analysis

### 1. Privilege Escalation - Local Group Modification (Event ID 4732)

To test security auditing and alerting, a local user account was created and added to the local `Administrators` group on the Windows target. The security event was captured by the Windows Event Channel and processed by Wazuh Rule `60154` (Level 12 Severity).

#### Raw Alert Output (`/var/ossec/logs/alerts/alerts.log`)

```json
** Alert 1790275793.2508808: mail - windows,windows_security,group_changed,win_group_changed,pci_dss_8.1.2,pci_dss_10.2.5,gpg13_7.10,gdpr_IV_35.7.d,gdpr_IV_32.2,hipaa_164.312.a.2.I,hipaa_164.312.a.2.II,hipaa_164.312.b,nist_800_53_AC.2,nist_800_53_IA.4,nist_800_53_AU.14,nist_800_53_AC.7,tsc_CC6.8,tsc_CC7.2,tsc_CC7.3,
2026 Sep 24 18:49:53 (win10-clean) any->EventChannel
Rule: 60154 (level 12) -> 'Administrators Group Changed'
{"win":{"system":{"providerName":"Microsoft-Windows-Security-Auditing","providerGuid":"{54849625-5478-4994-a5ba-3e3b0328c30d}","eventID":"4732","version":"0","level":"0","task":"13826","opcode":"0","keywords":"0x8020000000000000","systemTime":"2026-09-24T18:48:57.1460300Z","eventRecordID":"960","processID":"632","threadID":"2248","channel":"Security","computer":"win10-clean","severityValue":"AUDIT_SUCCESS","message":"\"A member was added to a security-enabled local group.\r\n\r\nSubject:\r\n\tSecurity ID:\t\tS-1-5-21-365683523-1018791215-68183753-1000\r\n\tAccount Name:\t\tsanji\r\n\tAccount Domain:\t\tWIN10-CLEAN\r\n\tLogon ID:\t\t0x2CA80\r\n\r\nMember:\r\n\tSecurity ID:\t\tS-1-5-21-365683523-1018791215-68183753-1001\r\n\tAccount Name:\t\t-\r\n\r\nGroup:\r\n\tSecurity ID:\t\tS-1-5-32-544\r\n\tGroup Name:\t\tAdministrators\r\n\tGroup Domain:\t\tBuiltin\""},"eventdata":{"memberSid":"S-1-5-21-365683523-1018791215-68183753-1001","targetUserName":"Administrators","targetDomainName":"Builtin","targetSid":"S-1-5-32-544","subjectUserSid":"S-1-5-21-365683523-1018791215-68183753-1000","subjectUserName":"sanji","subjectDomainName":"WIN10-CLEAN","subjectLogonId":"0x2ca80"}}}
```

### 2. Agent Telemetry & Lifecycle Events

Agent connection state transitions and active responses were verified through managerial CLI tools (`agent_control`) and raw log inspection.

```text
Wazuh agent_control. List of available agents:
   ID: 000, Name: sanji (server), IP: 127.0.0.1, Active/Local
   ID: 001, Name: Windows-Agent, IP: 192.168.1.50, Never connected
   ID: 002, Name: win10-clean, IP: any, Active
```

---

## MITRE ATT&CK Mapping

| Technique | ID | Detection Rule | Log Source | Level |
| :--- | :--- | :--- | :--- | :--- |
| **Account Manipulation** | T1098 | Rule 60154 (`Administrators Group Changed`) | Windows Security (Event 4732) | 12 |
| **File Creation / Modification** | T1492 | Syscheck FIM (`C:\Users\...\FIM_Test`) | Wazuh Syscheck | 7 |
| **PowerShell Execution** | T1059.001 | ScriptBlock Logging (Event ID 4104) | Windows PowerShell | 6 |
| **Valid Accounts** | T1078 | Rule 5502 (`PAM Login Session Closed`) | Linux Syslog | 3 |

---

## Repository Structure

```
.
├── config/
│   └── agent.conf                  # Shared agent XML policy (FIM directory stanzas)
├── logs/
│   ├── alerts.log                  # Raw Wazuh alerts log output
│   └── alerts_sample.json          # Structured JSON event stream
├── scripts/
│   ├── deploy_wazuh_agent.ps1      # Automated PowerShell deployment script
│   └── trigger_sec_alerts.ps1      # Event simulation script for FIM & privilege escalation
└── README.md                       # Technical deployment report
```
