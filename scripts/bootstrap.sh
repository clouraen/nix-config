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

# Host configuration selection function
select_host() {
  echo ""
  echo "=== Host Configuration Selection ==="
  echo ""

  # Find available host configurations
  HOSTS_DIR="$(dirname "$0")/../hosts"
  mapfile -t HOSTS < <(find "$HOSTS_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort)

  if [ ${#HOSTS[@]} -eq 0 ]; then
    echo "Error: No host configurations found in $HOSTS_DIR"
    exit 1
  fi

  # Display menu
  echo "Available host configurations:"
  echo "-----------------------------"
  for i in "${!HOSTS[@]}"; do
    echo "[$((i+1))] ${HOSTS[$i]}"
  done
  echo "-----------------------------"

  # Get user selection
  local selection
  while true; do
    read -rp "Select host configuration [1-${#HOSTS[@]}]: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#HOSTS[@]}" ]; then
      SELECTED_HOST="${HOSTS[$((selection-1))]}"
      break
    else
      echo "Invalid selection. Please try again."
    fi
  done

  echo "Selected host: $SELECTED_HOST"
  
  # Create hostname file
  echo "$SELECTED_HOST" > "$(dirname "$0")/../hostname"
  echo "Host configuration set to $SELECTED_HOST"
}

# Aplicar configuração NixOS
apply_config() {
    echo "=== Applying NixOS Configuration ==="
    echo "Building and switching to configuration for $HOST_CONFIG..."
    
    # Configurar sops-nix se ainda não estiver configurado
    if [ ! -f "$CONFIG_DIR/keys.txt" ]; then
        echo "Configurando chaves para sops-nix..."
        mkdir -p "$CONFIG_DIR"
        nix-shell -p sops -p age --run "age-keygen -o $CONFIG_DIR/keys.txt"
        chmod 600 "$CONFIG_DIR/keys.txt"
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
