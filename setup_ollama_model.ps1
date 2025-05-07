# Check if running as administrator
$ErrorActionPreference = "Stop"

if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as Administrator."
    Exit
}

Write-Host "Setting up Ollama model..."

# Step 1: Install Chocolatey (if it's not installed)
if (-NOT (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Step 2: Install Python 3 (if not installed)
if (-NOT (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python..."
    choco install python --confirm
}

# Step 3: Install pip (if not installed)
if (-NOT (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "Installing pip..."
    python -m ensurepip --upgrade
}

# Step 4: Download and Install Ollama
Write-Host "Downloading and installing Ollama..."
$ollamaInstallerUrl = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
$tempDir = [System.IO.Path]::GetTempPath()
$ollamaZipPath = Join-Path $tempDir "ollama-windows-amd64.zip"
$ollamaExtractPath = Join-Path $tempDir "ollama"

# Create the directory if it doesn't exist
if (-not (Test-Path -Path $ollamaExtractPath)) {
    New-Item -Path $ollamaExtractPath -ItemType Directory -Force | Out-Null
}

# Download Ollama
Invoke-WebRequest -Uri $ollamaInstallerUrl -OutFile $ollamaZipPath
Write-Host "Download complete."

# Extract Ollama
Write-Host "Extracting Ollama..."
Expand-Archive -Path $ollamaZipPath -DestinationPath $ollamaExtractPath -Force

# Create Program Files directory for Ollama if it doesn't exist
$ollamaInstallDir = "C:\Program Files\Ollama"
if (-not (Test-Path -Path $ollamaInstallDir)) {
    New-Item -Path $ollamaInstallDir -ItemType Directory -Force | Out-Null
}

# Copy files to Program Files
Write-Host "Installing Ollama to $ollamaInstallDir..."
Copy-Item -Path "$ollamaExtractPath\*" -Destination $ollamaInstallDir -Recurse -Force

# Add to PATH
Write-Host "Adding Ollama to PATH..."
$env:Path += ";$ollamaInstallDir"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Step 5: Verify installation
Write-Host "Verifying setup..."
try {
    & "$ollamaInstallDir\ollama.exe" --version
    Write-Host "Ollama installation successful!"
    
    # Start Ollama service
    Write-Host "Starting Ollama service..."
    Start-Process -FilePath "$ollamaInstallDir\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden
    
    # Pull a basic model (e.g., tinyllama)
    Write-Host "Pulling a basic model (tinyllama). This may take a few minutes..."
    Start-Sleep -Seconds 5  # Give the service time to start
    & "$ollamaInstallDir\ollama.exe" pull tinyllama
    
    Write-Host "Ollama setup complete! You can now use Ollama with the command 'ollama'"
    Write-Host "Example usage: ollama run tinyllama"
} catch {
    Write-Host "Error verifying Ollama installation: $_"
    Write-Host "Please check if the installation was successful and try running ollama.exe manually."
}