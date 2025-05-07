# Script para preparar o ambiente para o Assistente Virtual com Deepseek-Coder
$ErrorActionPreference = "Stop"

# Verificar se está executando como administrador
if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Por favor, execute este script como Administrador." -ForegroundColor Red
    Exit
}

Write-Host "Configurando ambiente para o Assistente Virtual com Deepseek..." -ForegroundColor Cyan

# Passo 1: Instalar ou verificar Python
if (-NOT (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Python..." -ForegroundColor Yellow
    choco install python --confirm
    # Adicionar Python ao PATH
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:Path = $machinePath + ";" + $userPath
} else {
    Write-Host "Python já está instalado." -ForegroundColor Green
}

# Passo 2: Instalar dependências Python necessárias
Write-Host "Instalando dependências Python..." -ForegroundColor Yellow
python -m pip install requests readline

# Passo 3: Verificar se Ollama está instalado e baixar o modelo Deepseek-Coder
$ollamaPath = "C:\Program Files\Ollama\ollama.exe"

if (-NOT (Test-Path $ollamaPath)) {
    Write-Host "Ollama não encontrado! Certifique-se de que o Ollama está instalado." -ForegroundColor Yellow
    Write-Host "   Por favor, execute o script setup_ollama_model.ps1 primeiro." -ForegroundColor Yellow
    Exit
} else {
    Write-Host "Ollama encontrado em $ollamaPath" -ForegroundColor Green
    
    # Iniciar o serviço Ollama se não estiver em execução
    $ollamaRunning = Get-NetTCPConnection -LocalPort 11434 -ErrorAction SilentlyContinue
    if (-NOT $ollamaRunning) {
        Write-Host "Iniciando o serviço Ollama..." -ForegroundColor Yellow
        Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
        Write-Host "Aguardando inicialização do serviço..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } else {
        Write-Host "Serviço Ollama já está em execução." -ForegroundColor Green
    }
    
    # Verificar se o modelo Deepseek-Coder está disponível
    $modelName = "deepseek-coder:6.7b-instruct"
    Write-Host "Verificando se o modelo $modelName está disponível..." -ForegroundColor Yellow
    
    $tagsJson = Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
    $modelExists = $false
    
    foreach ($model in $tagsJson.models) {
        if ($model.name -eq $modelName) {
            $modelExists = $true
            break
        }
    }

    if (-NOT $modelExists) {
        Write-Host "Baixando o modelo $modelName. Isso pode levar alguns minutos..." -ForegroundColor Yellow
        & $ollamaPath pull $modelName
        Write-Host "Modelo $modelName baixado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "Modelo $modelName já está disponível." -ForegroundColor Green
    }
}

# Passo 4: Criar ou verificar o script do assistente virtual
$assistentePath = Join-Path (Get-Location) "main.py"

if (-NOT (Test-Path $assistentePath)) {
    Write-Host "O script do assistente virtual não foi encontrado." -ForegroundColor Yellow
    Write-Host "Será necessário criar o arquivo main.py." -ForegroundColor Yellow
} else {
    Write-Host "Script do assistente virtual encontrado em $assistentePath" -ForegroundColor Green
}

Write-Host "`nConfiguração concluída! Para executar o assistente virtual:" -ForegroundColor Cyan
Write-Host "   python main.py" -ForegroundColor White
Write-Host "   (Com modelo específico: python main.py deepseek-coder:6.7b-instruct)" -ForegroundColor White
Write-Host "   (Com modelo e manual: python main.py deepseek-coder:6.7b-instruct caminho/para/manual.json)" -ForegroundColor White
