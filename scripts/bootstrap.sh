#!/usr/bin/env bash
set -euo pipefail

echo "=== NixOS Configuration Bootstrap ==="
echo "This script will guide you through the NixOS installation process."

# Diretório de configuração
CONFIG_DIR="/home/cleiton-moura/Downloads/nix-config"

# Verificar se está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa ser executado como root!"
    exit 1
fi

# Função para clonar o repositório se não existir
setup_repo() {
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "=== Cloning configuration repository ==="
        git clone https://github.com/clouraen/nix-config "$CONFIG_DIR"
    fi
}

# Seleção de disco
select_disk() {
    echo "=== Disk Selection ==="
    echo "Available disks:"
    
    # Listar discos disponíveis
    mapfile -t disks < <(lsblk -dpno NAME,SIZE,MODEL | grep -E '^/dev/(nvme|sd|vd)')
    
    for i in "${!disks[@]}"; do
        echo "[$i] ${disks[$i]}"
    done
    
    read -rp "Enter selection: " selection
    selected_disk=$(echo "${disks[$selection]}" | awk '{print $1}')
    echo "Selected disk: $selected_disk"
    
    # Exportar variável para uso posterior
    export DISK="$selected_disk"
}

# Seleção de configuração de host
select_host() {
    echo "=== Host Configuration ==="
    echo "Select host configuration:"
    
    # Lista de configurações disponíveis no repositório
    # Estas precisam corresponder exatamente aos nomes no flake.nix
    declare -a hosts=("desktop" "thinkpad-t440p" "macbook-m1")
    
    for i in "${!hosts[@]}"; do
        echo "[$i] ${hosts[$i]}"
    done
    
    read -rp "Enter selection (0-2): " selection
    
    # Verificar se a seleção é válida
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -lt "${#hosts[@]}" ]; then
        export HOST_CONFIG="${hosts[$selection]}"
        echo "Selected host: $HOST_CONFIG"
    else
        echo "Invalid selection. Defaulting to desktop."
        export HOST_CONFIG="desktop"
        echo "Selected host: $HOST_CONFIG"
    fi
}

# Aplicar configuração NixOS
apply_config() {
    echo "=== Applying NixOS Configuration ==="
    echo "Building and switching to configuration for $HOST_CONFIG..."
    
    # Configurar sops-nix se ainda não estiver configurado
    if [ ! -f "/path/to/keys.txt" ]; then
        echo "Configurando chaves para sops-nix..."
        mkdir -p $(dirname "/path/to/keys.txt")
        nix-shell -p age --run "age-keygen -o /path/to/keys.txt"
        chmod 600 /path/to/keys.txt
    fi
    
    # Aplicar a configuração usando o nome exato do host no flake.nix
    echo "Executing: nixos-rebuild switch --flake $CONFIG_DIR#$HOST_CONFIG"
    nixos-rebuild switch --flake "$CONFIG_DIR#$HOST_CONFIG"
}

# Executar o script
setup_repo
select_disk
select_host
apply_config

echo "=== Bootstrap completed successfully ==="
echo "Your NixOS system has been configured as $HOST_CONFIG"
