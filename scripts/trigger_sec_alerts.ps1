<#
.SYNOPSIS
    Security Telemetry & FIM Simulation Script
.DESCRIPTION
    Simulates local group modification (Event 4732) and FIM modifications in monitored directory.
#>

$FimPath = "C:\Users\sanji\Desktop\FIM_Test"

Write-Host "[*] Triggering File Integrity Monitoring (FIM) events..." -ForegroundColor Yellow
if (-not (Test-Path $FimPath)) {
    New-Item -ItemType Directory -Path $FimPath -Force
}

Set-Content -Path "$FimPath\secret_data.txt" -Value "CRITICAL SECURITY BREACH ALTERATION - $(Get-Date)"
New-Item -ItemType File -Path "$FimPath\malware_drop.exe" -Value "MZ90" -Force

Write-Host "[*] Triggering Local Privilege Escalation / Group Membership Event (Event ID 4732)..." -ForegroundColor Red
net user hacker_account Pass1234! /add
net localgroup Administrators hacker_account /add

Write-Host "[+] Security alerts triggered. Check Wazuh Dashboard or alerts.log." -ForegroundColor Green
