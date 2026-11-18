# ============================================================
# DESATIVAR WINDOWS DEFENDER + FIREWALL
# SOMENTE PARA VMs DESCARTÁVEIS DE TESTE
# Execute como Administrador
# ============================================================
Set-ExecutionPolicy Bypass -Scope Process -Force

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERRO: Execute este script como Administrador!" -ForegroundColor Red
    pause
    exit
}

Write-Host "`n=== ATENÇÃO ===" -ForegroundColor Red
Write-Host "Este script desativa completamente a proteção do Windows." -ForegroundColor Yellow
Write-Host "Use APENAS em máquinas virtuais descartáveis!" -ForegroundColor Yellow
Write-Host "Pressione Ctrl+C agora se não tiver certeza.`n" -ForegroundColor Red
Start-Sleep -Seconds 5

# ------------------------------------------------------------
# 1. Desativar Windows Defender
# ------------------------------------------------------------
Write-Host "[1/3] Desativando Windows Defender..." -ForegroundColor Green

# Preferências do Defender
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
Set-MpPreference -DisablePrivacyMode $true -ErrorAction SilentlyContinue
Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIntrusionPreventionSystem $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue

# Políticas de registro (mais permanentes)
$defenderPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
If (!(Test-Path $defenderPolicy)) { New-Item -Path $defenderPolicy -Force | Out-Null }
Set-ItemProperty -Path $defenderPolicy -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force

$realTime = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
If (!(Test-Path $realTime)) { New-Item -Path $realTime -Force | Out-Null }
Set-ItemProperty -Path $realTime -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $realTime -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $realTime -Name "DisableOnAccessProtection" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $realTime -Name "DisableScanOnRealtimeEnable" -Value 1 -Type DWord -Force

# Parar serviços
Stop-Service -Name "WinDefend" -Force -ErrorAction SilentlyContinue
Set-Service -Name "WinDefend" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name "WdNisSvc" -Force -ErrorAction SilentlyContinue
Set-Service -Name "WdNisSvc" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name "Sense" -Force -ErrorAction SilentlyContinue
Set-Service -Name "Sense" -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "   → Windows Defender desativado." -ForegroundColor Gray

# ------------------------------------------------------------
# 2. Desativar Firewall do Windows
# ------------------------------------------------------------
Write-Host "[2/3] Desativando Firewall do Windows..." -ForegroundColor Green

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction SilentlyContinue
netsh advfirewall set allprofiles state off | Out-Null

Write-Host "   → Firewall desativado." -ForegroundColor Gray

# ============================================================
# DESATIVAR WINDOWS DEFENDER + FIREWALL (VERSÃO FORTE)
# APENAS PARA VMs DESCARTÁVEIS DE TESTE
# Execute como Administrador
# ============================================================

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERRO: Execute como Administrador!" -ForegroundColor Red
    pause
    exit
}

Write-Host "`n=== ATENÇÃO ===" -ForegroundColor Red
Write-Host "Este script tenta desativar completamente o Defender." -ForegroundColor Yellow
Write-Host "Use SOMENTE em VMs descartáveis!" -ForegroundColor Yellow
Write-Host "Aguarde..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# ------------------------------------------------------------
# 1. Desativar Tamper Protection (muito importante)
# ------------------------------------------------------------
Write-Host "[1/5] Tentando desativar Tamper Protection..." -ForegroundColor Green

$tamper = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
If (Test-Path $tamper) {
    Set-ItemProperty -Path $tamper -Name "TamperProtection" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $tamper -Name "TamperProtectionSource" -Value 0 -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 2. Políticas de desativação permanente
# ------------------------------------------------------------
Write-Host "[2/5] Aplicando políticas de desativação..." -ForegroundColor Green

$defender = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
If (!(Test-Path $defender)) { New-Item -Path $defender -Force | Out-Null }
Set-ItemProperty -Path $defender -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $defender -Name "DisableAntiVirus" -Value 1 -Type DWord -Force

$realTime = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
If (!(Test-Path $realTime)) { New-Item -Path $realTime -Force | Out-Null }
Set-ItemProperty -Path $realTime -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $realTime -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $realTime -Name "DisableOnAccessProtection" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $realTime -Name "DisableScanOnRealtimeEnable" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $realTime -Name "DisableIOAVProtection" -Value 1 -Type DWord -Force

$spynet = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"
If (!(Test-Path $spynet)) { New-Item -Path $spynet -Force | Out-Null }
Set-ItemProperty -Path $spynet -Name "SpyNetReporting" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $spynet -Name "SubmitSamplesConsent" -Value 2 -Type DWord -Force

# ------------------------------------------------------------
# 3. Desativar via preferências do Defender
# ------------------------------------------------------------
Write-Host "[3/5] Desativando monitoramento em tempo real..." -ForegroundColor Green

Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIntrusionPreventionSystem $true -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 4. Parar e desabilitar serviços + matar processos
# ------------------------------------------------------------
Write-Host "[4/5] Parando serviços e processos do Defender..." -ForegroundColor Green

$services = @("WinDefend", "WdNisSvc", "Sense", "WdNisDrv", "WdFilter", "WdBoot")
foreach ($svc in $services) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    sc.exe config $svc start= disabled | Out-Null
}

# Matar o processo principal
taskkill /F /IM MsMpEng.exe /T 2>$null
taskkill /F /IM NisSrv.exe /T 2>$null
taskkill /F /IM SecurityHealthService.exe /T 2>$null

# ------------------------------------------------------------
# 5. Desativar Firewall
# ------------------------------------------------------------
Write-Host "[5/5] Desativando Firewall..." -ForegroundColor Green

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction SilentlyContinue
netsh advfirewall set allprofiles state off | Out-Null

Write-Host "`n=== Concluído ===" -ForegroundColor Cyan
Write-Host "Reinicie a VM agora." -ForegroundColor Yellow
Write-Host "Depois de reiniciar, verifique se o 'Antimalware Service Executable' sumiu." -ForegroundColor Yellow
Write-Host "`nPressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")