<#
.SYNOPSIS
    Local AI Workflow: Docker + Models + MCP SearXNG for Windows
.DESCRIPTION
    Prepares the full environment: checks dependencies, starts services, downloads models, and configures MCP.
.NOTES
    USAGE: Run PowerShell as Administrator
#>

# ────────────────────────────────────────────
# CONFIGURATION (modify as need)
# ────────────────────────────────────────────

# Models to download from Ollama
# recommended models for RTX 4060 (8GB VRAM minimum): 

# qwen3.5:latest    general-purpose assistant 
# qwen2.5-coder:7b  code autocompletion model
$MODELS = @(
    "qwen3.5:latest"
    "qwen2.5-coder:7b"
)

# Local domains
$DOMAINS = @(
    "webui.local"
    "searxng.local"
)

# URL de SearXNG para el MCP
$SEARXNG_URL = "http://searxng.local/search?q=<query>&format=json"

# ────────────────────────────────────────────
# INICIO
# ────────────────────────────────────────────
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Local AI Workflow - Setup (Windows)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
# ────────────────────────────────────────────
# Paso 1: Requisitos iniciales
# ────────────────────────────────────────────
Write-Host ">>> Step 1: Checking initial requirements..." -ForegroundColor Green
if ($env:OS -ne "Windows_NT") {
    Write-Host "ERROR: This script is for Windows PowerShell only." -ForegroundColor Red
    Write-Host "       On Linux use: sudo ./workflowSetup.sh" -ForegroundColor Yellow
    pause
    exit 1
}
Write-Host "Windows platform detected." -ForegroundColor Cyan

# ────────────────────────────────────────────
# Paso 1.2: Permisos de administrador
# ────────────────────────────────────────────
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Administrator privileges required to modify Windows hosts file" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "Correct permissions." -ForegroundColor Cyan

# ────────────────────────────────────────────
# Paso 1.3: Dependencias
# ────────────────────────────────────────────
Write-Host ">>> Step 1.3: Checking dependencies..." -ForegroundColor Green

# Verificar Docker Desktop
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Host "ERROR: Docker Desktop is not installed." -ForegroundColor Red
    $respuesta = Read-Host "Download Docker Desktop? (y/n)"
    if ($respuesta -eq "y") {
        Start-Process "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module"
    }
    Write-Host "Install Docker Desktop, restart the PC, and re-run this script." -ForegroundColor Yellow
    pause
    exit 1
}

try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not responding"
    }
    Write-Host "Docker Desktop is running." -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Start Docker Desktop and re-run the script." -ForegroundColor Red
    pause
    exit 1
}

# Verificar Node.js
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "Node.js not found." -ForegroundColor Yellow
        $respuesta = Read-Host "Install Node.js with winget? (y/n)"
    if ($respuesta -eq "y") {
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            Write-Host "Installing Node.js LTS..." -ForegroundColor Cyan
            winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
            Write-Host "Node.js installed. Restart the terminal and re-run this script." -ForegroundColor Yellow
        } else {
            Write-Host "ERROR: winget not available. Download manually from: https://nodejs.org/en/download" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Node.js is required, download from: https://nodejs.org/en/download" -ForegroundColor Yellow
    }
    pause
    exit 1
}
    Write-Host "Node.js already installed: $(node --version)" -ForegroundColor Cyan

# ────────────────────────────────────────────
# Step 2: Local domains
# ────────────────────────────────────────────
Write-Host ">>> Step 2: Configuring local domains..." -ForegroundColor Green
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue

foreach ($domain in $DOMAINS) {
    $entry = "127.0.0.1 $domain"
    if ($hostsContent -notmatch [regex]::Escape($domain)) {
        Add-Content -Path $hostsPath -Value $entry
        Write-Host "Added: $domain" -ForegroundColor Cyan
    } else {
        Write-Host "$domain already configured." -ForegroundColor Cyan
    }
}

# ────────────────────────────────────────────
# Paso 3: Servicios Docker
# ────────────────────────────────────────────
Write-Host ">>> Step 3: Checking services..." -ForegroundColor Green
$ollamaRunning = docker ps --format '{{.Names}}' 2>&1 | Select-String "ollama" -Quiet
if (-not $ollamaRunning) {
    Write-Host "Starting services with Docker Compose..." -ForegroundColor Cyan
    docker compose up -d
} else {
    Write-Host "Services already running." -ForegroundColor Cyan
}

# ────────────────────────────────────────────
# Paso 4: Esperar a Ollama
# ────────────────────────────────────────────
Write-Host ">>> Step 4: Checking Ollama..." -ForegroundColor Green
try {
    $ollamaResponse = curl.exe -s --connect-timeout 5 http://localhost:11434/api/tags 2>$null
    if ($ollamaResponse) {
        Write-Host "Ollama is already responding." -ForegroundColor Cyan
    } else {
        throw "Ollama is not responding yet"
    }
} catch {
    Write-Host "Waiting for Ollama to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# ────────────────────────────────────────────
# Step 5: Models
# ────────────────────────────────────────────
Write-Host ">>> Step 5: Checking models..." -ForegroundColor Green
foreach ($model in $MODELS) {
    $installed = docker exec ollama ollama list 2>$null | Select-String -SimpleMatch $model -Quiet
    if (-not $installed) {
        Write-Host "Downloading $model..." -ForegroundColor Cyan
        docker exec -it ollama ollama pull $model
    } else {
        Write-Host "$model is already downloaded." -ForegroundColor Cyan
    }
}

# ────────────────────────────────────────────
# Paso 6: MCP SearXNG
# ────────────────────────────────────────────
# Step 6: MCP SearXNG
Write-Host ">>> Step 6: Configuring MCP SearXNG..." -ForegroundColor Green
# Verificar MCP SearXNG
$mcpCmd = Get-Command mcp-searxng -ErrorAction SilentlyContinue
if (-not $mcpCmd) {
    Write-Host "Installing MCP SearXNG globally..." -ForegroundColor Cyan
    npm install -g mcp-searxng
    Write-Host "MCP SearXNG installed." -ForegroundColor Cyan
} else {
    Write-Host "MCP SearXNG already installed." -ForegroundColor Cyan
}

Write-Host "" 
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ">>> Setup completed" -ForegroundColor Green
Write-Host ">>>" -ForegroundColor Cyan
Write-Host ">>> open-webui: http://$($DOMAINS[0])" -ForegroundColor Yellow
Write-Host ">>> searxng:    http://$($DOMAINS[1])" -ForegroundColor Yellow
Write-Host ">>>" -ForegroundColor Cyan
Write-Host ">>> MCP SearXNG ready to use in Continue:" -ForegroundColor Cyan
Write-Host ">>>   command: mcp-searxng" -ForegroundColor White
Write-Host ">>>   args: --url $SEARXNG_URL" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan

pause