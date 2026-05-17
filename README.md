# Yar's AI Coding Workflow
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE.md)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Ollama](https://img.shields.io/badge/Ollama-000000?logo=ollama&logoColor=white)](https://ollama.com/)
[![SearXNG](https://img.shields.io/badge/SearXNG-0a0f1c?style=flat&logo=searxng&logoColor=white)](https://github.com/searxng/searxng)
[![Open WebUI](https://img.shields.io/badge/Open_WebUI-111827?style=flat&logo=openwebui&logoColor=white)](https://github.com/open-webui/open-webui)
[![nginx](https://img.shields.io/badge/nginx-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![NVIDIA Container Toolkit](https://img.shields.io/badge/NVIDIA_Container_Toolkit-76B900?logo=nvidia&logoColor=white)](https://github.com/NVIDIA/nvidia-container-toolkit)

This repo contains my personal local AI coding workflow — a portable set of scripts and Docker services to run a local AI development environment (model hosting, web UI, and search integration).

## Purpose
The main goal is to have an AI workflow without depending on external services that keep raising subscription prices and API usage costs.

Since I work on both Windows and Ubuntu (primarily Windows, but I'm migrating to Ubuntu 26.04), I created setup scripts for both platforms.

To make a local model comparable in knowledge to cloud-based AI providers, I needed to give it internet search capabilities. That's why SearXNG is integrated as an MCP provider — it allows the model to fetch up-to-date information from the web.

Additionally, to better understand frontend design, I integrated Open WebUI so the model can analyze images and generate base code for me to work with.

## What's Included

### Docker Compose stack
Ollama, Open WebUI, SearXNG, and nginx as a reverse proxy.

### Setup scripts
- [`workflowSetup.sh`](workflowSetup.sh) — Linux setup (requires `sudo`).
- [`workflowSetup.ps1`](workflowSetup.ps1) — Windows PowerShell setup (run as Administrator).

Both scripts configure the system, but the main difference is that the Linux script is fully automated, while the Windows one is semi-automated (you may need to install some dependencies manually).

### Continue integration
MCP server configuration for SearXNG at `.continue/mcpServers/searxng.yaml`.

### nginx reverse proxy
Routes `webui.local` and `searxng.local` to their respective containers. So you can open it directly in your web browser.

## Quick start 
### Linux
Run the setup script to install dependencies, configure Docker, add local domains, start services, and pull models:

```bash
sudo ./WorkflowSetup.sh
```

### Windows (PowerShell as Administrator)

```powershell
.\WorkflowSetup.ps1
```

## After Setup
You can:
- Open Web UI at: http://webui.local
- SearXNG at: http://searxng.local
- Copy the `.continue` folder into your own projects to enable the MCP integration

## Hardware Used
| Component | Specification |
|---|---|
| **CPU** | Intel® Core™ i7-13650HX |
| **RAM** | 32 GB DDR5 4800 MHz |
| **GPU** | NVIDIA GeForce RTX 4060 (8 GB VRAM) |
| **OS** | Ubuntu 26.04 LTS (kernel 7.0.0-15-generic) |

The default models are recommended for GPUs with at least 8 GB VRAM, matching this machine's RTX 4060. You can change which models are pulled by editing the MODELOS / $MODELOS variables in the setup scripts.

## Credits
Built with these awesome open-source projects:

[Ollama](https://github.com/ollama/ollama) · [Open WebUI](https://github.com/open-webui/open-webui) · [SearXNG](https://github.com/searxng/searxng) · [MCP-SearXNG](https://github.com/ihor-sokoliuk/mcp-searxng) · [Docker](https://github.com/docker) · [nginx](https://github.com/nginx/nginx) · [Node.js](https://github.com/nodejs/node) · [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)


## Notes
This repository reflects my personal AI coding workflow, including my preferred local tools, model choices (listed in the setup scripts), and domain names.

Feel free to adapt the configuration to your own environment, or reach out if you need any changes.
