# 1. Disable Windows Update via Group Policy Registry Keys
$wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$auPath = "$wuPath\AU"
New-Item -Path $wuPath -Force | Out-Null
New-Item -Path $auPath -Force | Out-Null

Set-ItemProperty -Path $wuPath -Name "DisableWindowsUpdateAccess" -Value 1 -Type DWord
Set-ItemProperty -Path $wuPath -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 1 -Type DWord
Set-ItemProperty -Path $auPath -Name "NoAutoUpdate" -Value 1 -Type DWord
Set-ItemProperty -Path $auPath -Name "AUOptions" -Value 1 -Type DWord

# 2. Disable Microsoft Store Auto-Updates via Registry Policy
$storePath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
New-Item -Path $storePath -Force | Out-Null
Set-ItemProperty -Path $storePath -Name "AutoDownload" -Value 2 -Type DWord

# 3. Stop and Disable Update Services (Windows Update, Update Orchestrator, Store Install)
$services = @("wuauserv", "UsoSvc", "InstallService")
foreach ($svc in $services) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    sc.exe config $svc start= disabled | Out-Null
}

# 4. Disable Update Orchestrator & Windows Update Scheduled Tasks
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\*" -ErrorAction SilentlyContinue | Disable-ScheduledTask | Out-Null
Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\*" -ErrorAction SilentlyContinue | Disable-ScheduledTask | Out-Null

# 5. Force Policy Refresh
gpupdate /force