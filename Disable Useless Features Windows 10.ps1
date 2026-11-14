# ============================================================
#  Script de Otimização Windows 10 - PC Simples / Fraco
#  Desativa efeitos visuais, animações, OneDrive, Xbox e mais
#  Execute como Administrador!
#  Talvez seja necessário executar antes: Set-ExecutionPolicy Bypass -Scope Process -Force
# ============================================================

# Verifica se está rodando como Administrador
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERRO: Execute este script como Administrador!" -ForegroundColor Red
    Write-Host "Clique com o botão direito no PowerShell e escolha 'Executar como administrador'." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "`n=== Iniciando otimização do Windows 10 ===" -ForegroundColor Cyan
Write-Host "Isso pode levar alguns minutos...`n" -ForegroundColor Yellow

# ------------------------------------------------------------
# 1. Efeitos Visuais e Animações (Melhor Desempenho)
# ------------------------------------------------------------
Write-Host "[1/8] Desativando efeitos visuais e animações..." -ForegroundColor Green

# Define "Ajustar para obter o melhor desempenho"
$pathVisual = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
If (!(Test-Path $pathVisual)) { New-Item -Path $pathVisual -Force | Out-Null }
Set-ItemProperty -Path $pathVisual -Name "VisualFXSetting" -Value 2 -Type DWord -Force

# Desativa animações específicas
$advPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $advPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force
Set-ItemProperty -Path $advPath -Name "MenuShowDelay" -Value 0 -Type String -Force
Set-ItemProperty -Path $advPath -Name "DragFullWindows" -Value 0 -Type String -Force

# Desativa animações de janela e barra de tarefas
$explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $explorerPath -Name "TaskbarAnimations" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $explorerPath -Name "ListviewAlphaSelect" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $explorerPath -Name "ListviewShadow" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $explorerPath -Name "IconsOnly" -Value 1 -Type DWord -Force   # Ícones ao invés de miniaturas

# Desativa transparência (Aero)
$pathDWM = "HKCU:\Software\Microsoft\Windows\DWM"
If (!(Test-Path $pathDWM)) { New-Item -Path $pathDWM -Force | Out-Null }
Set-ItemProperty -Path $pathDWM -Name "EnableAeroPeek" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $pathDWM -Name "AlwaysHibernateThumbnails" -Value 0 -Type DWord -Force

# Desativa animações do sistema (acessibilidade)
$pathAccess = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $pathAccess -Name "MinAnimate" -Value 0 -Type String -Force

Write-Host "   → Efeitos visuais desativados." -ForegroundColor Gray

# ------------------------------------------------------------
# 2. Desativar OneDrive
# ------------------------------------------------------------
Write-Host "[2/8] Desativando e removendo OneDrive..." -ForegroundColor Green

# Para o processo
Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "OneDriveSetup" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Desinstala
$onedrivePaths = @(
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
    "$env:SystemRoot\System32\OneDriveSetup.exe"
)
foreach ($path in $onedrivePaths) {
    if (Test-Path $path) {
        Start-Process $path "/uninstall" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    }
}

# Política de desativação
$onedrivePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
If (!(Test-Path $onedrivePolicy)) { New-Item -Path $onedrivePolicy -Force | Out-Null }
Set-ItemProperty -Path $onedrivePolicy -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $onedrivePolicy -Name "DisableFileSync" -Value 1 -Type DWord -Force

# Remove do Explorer (barra lateral)
$clsid = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
If (!(Test-Path "HKCR:")) { New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null }
If (Test-Path $clsid) {
    Set-ItemProperty -Path $clsid -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

Write-Host "   → OneDrive desativado." -ForegroundColor Gray

# ------------------------------------------------------------
# 3. Desativar serviços e apps do Xbox / Game Bar
# ------------------------------------------------------------
Write-Host "[3/8] Desativando Xbox e Game Bar..." -ForegroundColor Green

# Serviços Xbox
$xboxServices = @(
    "XblAuthManager",
    "XblGameSave",
    "XboxNetApiSvc",
    "XboxGipSvc"
)
foreach ($svc in $xboxServices) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
}

# Desativa Game DVR / Game Bar via Registro
$gameDVR = "HKCU:\System\GameConfigStore"
If (!(Test-Path $gameDVR)) { New-Item -Path $gameDVR -Force | Out-Null }
Set-ItemProperty -Path $gameDVR -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

$gameBar = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
If (!(Test-Path $gameBar)) { New-Item -Path $gameBar -Force | Out-Null }
Set-ItemProperty -Path $gameBar -Name "AllowGameDVR" -Value 0 -Type DWord -Force

# Remove apps Xbox (para o usuário atual)
$xboxApps = @(
    "Microsoft.XboxApp",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.GamingApp"
)
foreach ($app in $xboxApps) {
    Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
}

Write-Host "   → Xbox e Game Bar desativados." -ForegroundColor Gray

# ------------------------------------------------------------
# 4. Outros ajustes de desempenho e bloat
# ------------------------------------------------------------
Write-Host "[4/8] Desativando dicas, telemetria leve e recursos extras..." -ForegroundColor Green

# Desativa dicas e sugestões do Windows
$contentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
If (Test-Path $contentPath) {
    $props = @("SubscribedContent-338389Enabled","SubscribedContent-338388Enabled","SubscribedContent-338393Enabled",
               "SubscribedContent-353694Enabled","SubscribedContent-353696Enabled","SoftLandingEnabled",
               "SystemPaneSuggestionsEnabled","SilentInstalledAppsEnabled")
    foreach ($p in $props) {
        Set-ItemProperty -Path $contentPath -Name $p -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

# Desativa Cortana (busca ainda funciona)
$cortana = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
If (!(Test-Path $cortana)) { New-Item -Path $cortana -Force | Out-Null }
Set-ItemProperty -Path $cortana -Name "AllowCortana" -Value 0 -Type DWord -Force

# Desativa telemetria básica (nível mínimo)
$telemetry = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
If (!(Test-Path $telemetry)) { New-Item -Path $telemetry -Force | Out-Null }
Set-ItemProperty -Path $telemetry -Name "AllowTelemetry" -Value 0 -Type DWord -Force

Write-Host "   → Dicas e telemetria reduzidas." -ForegroundColor Gray

# ------------------------------------------------------------
# 5. Plano de Energia de Alto Desempenho
# ------------------------------------------------------------
Write-Host "[5/8] Ativando plano de Alto Desempenho..." -ForegroundColor Green
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance
# Se não existir, tenta o Ultimate (Windows 10 Pro/mais recentes)
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null

Write-Host "   → Plano de energia ajustado." -ForegroundColor Gray

# ------------------------------------------------------------
# 6. Desativa alguns serviços desnecessários (com cuidado)
# ------------------------------------------------------------
Write-Host "[6/8] Desativando serviços inúteis..." -ForegroundColor Green

$servicesToDisable = @(
    "DiagTrack",                 # Telemetria
    "dmwappushservice",          # WAP Push
    "RetailDemo",                # Demo de varejo
    "MapsBroker",                # Mapas baixados
    "lfsvc",                     # Geolocalização
    "WbioSrvc",                  # Biometria (se não usar impressão digital)
    "XblAuthManager",            # Já feito acima, mas reforça
    "XblGameSave",
    "XboxNetApiSvc"
)

foreach ($svc in $servicesToDisable) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
}

Write-Host "   → Serviços desnecessários desativados." -ForegroundColor Gray

# ------------------------------------------------------------
# 7. Reinicia o Explorer para aplicar mudanças visuais
# ------------------------------------------------------------
Write-Host "[7/8] Reiniciando Explorer..." -ForegroundColor Green
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process "explorer.exe"

# ------------------------------------------------------------
# 8. Limpeza rápida de arquivos temporários
# ------------------------------------------------------------
Write-Host "[8/8] Limpando arquivos temporários..." -ForegroundColor Green
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Otimização concluída! ===" -ForegroundColor Cyan
Write-Host "Reinicie o computador para aplicar todas as mudanças." -ForegroundColor Yellow
Write-Host "Se algo não funcionar como esperado, use o Ponto de Restauração." -ForegroundColor Yellow
Write-Host "`nPressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
