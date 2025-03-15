#!/usr/bin/env bash
set -euo pipefail

echo "Iniciando bootstrap do sistema NixOS..."

# Verificar se está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa ser executado como root!"
    exit 1
fi

# Diretório de configuração
CONFIG_DIR="/home/cleiton-moura/Downloads/nix-config"

# Configurar sops-nix se ainda não estiver configurado
if [ ! -f "/path/to/keys.txt" ]; then
    echo "Configurando chaves para sops-nix..."
    mkdir -p $(dirname "/path/to/keys.txt")
    nix-shell -p age --run "age-keygen -o /path/to/keys.txt"
    chmod 600 /path/to/keys.txt
fi

# Aplicar configuração NixOS
echo "Aplicando configuração NixOS..."
nixos-rebuild switch --flake "$CONFIG_DIR#seuhost"

echo "Bootstrap concluído com sucesso!"
