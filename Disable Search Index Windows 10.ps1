# ============================================================
# Desativar Indexação de Pesquisa (Windows Search)
# Execute como Administrador
#  Talvez seja necessário executar antes: Set-ExecutionPolicy Bypass -Scope Process -Force
# ============================================================

Set-ExecutionPolicy Bypass -Scope Process -Force

# Verifica se está rodando como Administrador
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERRO: Execute este script como Administrador!" -ForegroundColor Red
    pause
    exit
}

Write-Host "Desativando Indexação de Pesquisa..." -ForegroundColor Cyan

# 1. Para o serviço Windows Search
Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue

# 2. Define o serviço para desativado (não inicia mais)
Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue

# 3. (Opcional) Desativa a indexação via política de registro
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
If (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name "AllowIndexingEncryptedStoresOrItems" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regPath -Name "DisableIndexingOfRemoteMailboxes" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

Write-Host "`nIndexação de Pesquisa desativada com sucesso!" -ForegroundColor Green
Write-Host "O serviço Windows Search não irá mais iniciar automaticamente." -ForegroundColor Yellow
Write-Host "Reinicie o computador para aplicar completamente." -ForegroundColor Yellow
Write-Host "`nPressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
