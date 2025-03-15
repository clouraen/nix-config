apply_config() {
    echo "=== Applying NixOS Configuration ==="
    echo "Building and switching to configuration for $HOST_CONFIG..."
    
    # Configure sops-nix if keys don't exist yet
    SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
        echo "Setting up keys for sops-nix..."
        mkdir -p "$(dirname "$SOPS_AGE_KEY_FILE")"
        nix-shell -p age --run "age-keygen -o $SOPS_AGE_KEY_FILE"
        chmod 600 "$SOPS_AGE_KEY_FILE"
        
        # Display the public key for adding to .sops.yaml
        PUBLIC_KEY=$(nix-shell -p age --run "age-keygen -y $SOPS_AGE_KEY_FILE")
        echo "Your public age key is:"
        echo "$PUBLIC_KEY"
        echo "Please add this key to your .sops.yaml file"
    fi
    
    # Apply the configuration using the exact host name in flake.nix
    echo "Executing: nixos-rebuild switch --flake $CONFIG_DIR#$HOST_CONFIG"
    nixos-rebuild switch --flake "$CONFIG_DIR#$HOST_CONFIG"
}
