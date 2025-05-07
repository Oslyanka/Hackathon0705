# Script para instalar e configurar o Ollama com o modelo Deepseek
$ErrorActionPreference = "Stop"

# Verificar se está executando como administrador
if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Por favor, execute este script como Administrador." -ForegroundColor Red
    Exit
}

Write-Host "Iniciando configuração do Ollama..." -ForegroundColor Cyan

# Passo 1: Instalar Chocolatey (se necessário)
if (-NOT (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Passo 2: Instalar Python (se necessário)
if (-NOT (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Python..." -ForegroundColor Yellow
    choco install python --confirm
} else {
    Write-Host "Python já está instalado." -ForegroundColor Green
}

# Passo 3: Instalar pip (se necessário)
if (-NOT (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando pip..." -ForegroundColor Yellow
    python -m ensurepip --upgrade
} else {
    Write-Host "Pip já está instalado." -ForegroundColor Green
}

# Passo 4: Baixar e instalar Ollama
Write-Host "Baixando e instalando Ollama..." -ForegroundColor Yellow
$ollamaInstallerUrl = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
$tempDir = [System.IO.Path]::GetTempPath()
$ollamaZipPath = Join-Path $tempDir "ollama-windows-amd64.zip"
$ollamaExtractPath = Join-Path $tempDir "ollama"

if (-not (Test-Path -Path $ollamaExtractPath)) {
    New-Item -Path $ollamaExtractPath -ItemType Directory -Force | Out-Null
}

Invoke-WebRequest -Uri $ollamaInstallerUrl -OutFile $ollamaZipPath
Write-Host "Download concluído." -ForegroundColor Green

Expand-Archive -Path $ollamaZipPath -DestinationPath $ollamaExtractPath -Force

$ollamaInstallDir = "C:\Program Files\Ollama"
if (-not (Test-Path -Path $ollamaInstallDir)) {
    New-Item -Path $ollamaInstallDir -ItemType Directory -Force | Out-Null
}

Copy-Item -Path "$ollamaExtractPath\*" -Destination $ollamaInstallDir -Recurse -Force

# Adicionar Ollama ao PATH
Write-Host "Adicionando Ollama ao PATH..." -ForegroundColor Yellow
$env:Path += ";$ollamaInstallDir"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Passo 5: Verificar e iniciar o Ollama
Write-Host "Verificando instalação do Ollama..." -ForegroundColor Yellow
try {
    & "$ollamaInstallDir\ollama.exe" --version
    Write-Host "Instalação do Ollama bem-sucedida!" -ForegroundColor Green

    Write-Host "Iniciando serviço Ollama..." -ForegroundColor Yellow
    Start-Process -FilePath "$ollamaInstallDir\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5

    # Baixar o modelo Deepseek se necessário
    $modelName = "deepseek-coder:6.7b-instruct"
    Write-Host "Verificando se o modelo '$modelName' está disponível..." -ForegroundColor Yellow

    $modelAvailable = $false
    try {
        $tagsJson = Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
        foreach ($model in $tagsJson.models) {
            if ($model.name -eq $modelName) {
                $modelAvailable = $true
                break
            }
        }
    } catch {
        Write-Host "Erro ao acessar o serviço Ollama. Verifique se ele está rodando corretamente." -ForegroundColor Red
    }

    if (-NOT $modelAvailable) {
        Write-Host "Baixando o modelo $modelName..." -ForegroundColor Yellow
        & "$ollamaInstallDir\ollama.exe" pull $modelName
        Write-Host "Modelo $modelName baixado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "Modelo $modelName já está disponível." -ForegroundColor Green
    }

    Write-Host "Configuração do Ollama concluída com sucesso!" -ForegroundColor Cyan
    Write-Host "Você pode usar o comando: ollama run $modelName" -ForegroundColor White

} catch {
    Write-Host "Erro na verificação ou instalação do Ollama: $_" -ForegroundColor Red
}
