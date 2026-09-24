<#
.SYNOPSIS
    Automated Wazuh Agent Deployment & Registration Script for Windows Target
.DESCRIPTION
    Downloads the Wazuh Agent MSI package, performs silent installation with manager IP parameters,
    and starts the Wazuh service.
#>

param(
    [string]$ManagerIP = "192.168.1.48",
    [string]$Port = "8000"
)

$ErrorActionPreference = "Stop"

Write-Host "[*] Fetching Wazuh Agent MSI from Manager http://${ManagerIP}:${Port}..." -ForegroundColor Cyan
$Url = "http://${ManagerIP}:${Port}/wazuh-agent-4.12.0-1.msi"
$OutPath = "$env:TEMP\wazuh-agent.msi"

Invoke-WebRequest -Uri $Url -OutFile $OutPath

Write-Host "[*] Installing Wazuh Agent silently..." -ForegroundColor Cyan
Start-Process msiexec.exe -ArgumentList "/i `"$OutPath`" /q WAZUH_MANAGER=`"$ManagerIP`" WAZUH_REGISTRATION_SERVER=`"$ManagerIP`"" -Wait

Write-Host "[*] Starting Wazuh Service..." -ForegroundColor Cyan
Start-Service -Name "Wazuh"

Write-Host "[+] Wazuh Agent deployed and service active." -ForegroundColor Green
