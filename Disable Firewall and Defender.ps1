# ============================================================
# DESATIVAR WINDOWS DEFENDER + FIREWALL
# SOMENTE PARA VMs DESCARTÁVEIS DE TESTE
# Execute como Administrador
# ============================================================

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

# ------------------------------------------------------------
# 3. Finalização
# ------------------------------------------------------------
Write-Host "[3/3] Concluído." -ForegroundColor Green

Write-Host "`n=== Proteções desativadas ===" -ForegroundColor Cyan
Write-Host "Reinicie a VM para garantir que tudo foi aplicado." -ForegroundColor Yellow
Write-Host "Lembre-se: esta VM agora está completamente desprotegida." -ForegroundColor Red
Write-Host "`nPressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")