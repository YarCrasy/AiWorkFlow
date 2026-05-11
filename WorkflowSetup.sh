#!/bin/bash
# Local AI Workflow: Docker + Models + MCP SearXNG
# USAGE: sudo ./workflowSetup.sh

set -e

# CONFIGURATION (modify as need)
# ────────────────────────────────────────────
# Models to download from Ollama
## recommended models for RTX 4060 (8GB VRAM minimum): 
### qwen3.5:9b          general-purpose assistant 
### qwen2.5-coder:7b    code autocompletion model
MODELS=(
    "qwen3.5:9b"
    "qwen2.5-coder:7b"
)
# Local domains
DOMAINS=(
    "webui.local"
    "searxng.local"
)
# SearXNG URL for the MCP
SEARXNG_URL="http://searxng.local/search?q=<query>&format=json"

# ────────────────────────────────────────────
# START
# ────────────────────────────────────────────
echo "============================================"
echo "  Local AI Workflow - Setup"
echo "============================================"

# ────────────────────────────────────────────
# Step 1: Dependencies
# ────────────────────────────────────────────
echo ">>> Step 1: Installing dependencies..."
if ! dpkg -s ca-certificates curl >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y ca-certificates curl
else
    echo "Dependencies already installed."
fi

if command -v nvidia-smi >/dev/null 2>&1; then
    if ! command -v nvidia-ctk >/dev/null 2>&1; then
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
          sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
          sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        sudo apt update
        sudo apt install -y nvidia-container-toolkit
    else
        echo "NVIDIA Container Toolkit already installed."
    fi
else
    echo "No NVIDIA GPU detected, skipping this step."
fi

# ────────────────────────────────────────────
# Step 2: Docker repository
# ────────────────────────────────────────────
echo ">>> Step 2: Configuring Docker repository..."
if [ ! -f /etc/apt/sources.list.d/docker.sources ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    source /etc/os-release
    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
else
    echo "Docker repository already configured."
fi

# ────────────────────────────────────────────
# Step 3: Docker
# ────────────────────────────────────────────
echo ">>> Step 3: Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
else
    echo "Docker already installed: $(docker --version)"
fi

# ────────────────────────────────────────────
# Step 4: Local domains
# ────────────────────────────────────────────
echo ">>> Step 4: Configuring local domains..."
DOMAINS_ENTRY="127.0.0.1 ${DOMAINS[*]}"
if ! grep -q "$DOMAINS_ENTRY" /etc/hosts; then
    echo "$DOMAINS_ENTRY" | sudo tee -a /etc/hosts
    echo "Domains added."
else
    echo "Domains already configured."
fi

# ────────────────────────────────────────────
# Step 5: Docker services
# ────────────────────────────────────────────
echo ">>> Step 5: Checking services..."
if ! docker ps --format '{{.Names}}' | grep -q "ollama"; then
    sudo docker compose up -d
else
    echo "Services already running."
fi

# ────────────────────────────────────────────
# Step 6: Wait for Ollama
# ────────────────────────────────────────────
echo ">>> Step 6: Checking Ollama..."
if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "Ollama is already responding."
else
    echo "Waiting for Ollama to be ready..."
    sleep 10
fi

# ────────────────────────────────────────────
# Step 7: Models
# ────────────────────────────────────────────
echo ">>> Step 7: Checking models..."
for MODEL in "${MODELS[@]}"; do
    if ! sudo docker exec ollama ollama list 2>/dev/null | grep -q "$MODEL"; then
        echo "Downloading $MODEL..."
        sudo docker exec -it ollama ollama pull "$MODEL"
    else
        echo "$MODEL is already downloaded."
    fi
done

# ────────────────────────────────────────────
# Step 8: Node.js and MCP SearXNG
# ────────────────────────────────────────────
echo ">>> Step 8: Configuring Node.js and MCP..."
if ! command -v node >/dev/null 2>&1; then
    sudo apt install -y nodejs npm
else
    echo "Node.js already installed: $(node --version)"
fi

if ! command -v mcp-searxng >/dev/null 2>&1; then
    sudo npm install -g mcp-searxng
else
    echo "MCP SearXNG already installed."
fi

# ────────────────────────────────────────────
# Step 9: Permissions
# ────────────────────────────────────────────
echo ">>> Step 9: Checking permissions..."
if groups $USER | grep -q docker; then
    echo "User already in docker group."
else
    sudo usermod -aG docker $USER
    echo "User added to docker group. Run: newgrp docker"
fi

echo ""
echo "============================================"
echo ">>> Setup completed"
echo ">>>"
echo ">>> open-webui: http://${DOMAINS[0]}"
echo ">>> searxng:    http://${DOMAINS[1]}"
echo ">>>"
echo ">>> MCP SearXNG ready to use in Continue:"
echo ">>>   command: mcp-searxng"
echo ">>>   args: --url $SEARXNG_URL"
echo "============================================"