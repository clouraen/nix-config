# NixOS Configuration

Sistema NixOS personalizado com suporte para múltiplos hosts e instalação automatizada.

## Hosts Suportados

- Desktop (i7 3370 + GTX 4060)
- ThinkPad T440p
- MacBook M1

## Instalação Oneliner

Execute este comando diretamente no instalador NixOS:

```bash
# Para Desktop:
curl -sL https://raw.githubusercontent.com/clouraen/nix-config/main/bootstrap.sh | bash -s -- -d /dev/sda -h desktop

# Para ThinkPad T440p:
curl -sL https://raw.githubusercontent.com/clouraen/nix-config/main/bootstrap.sh | bash -s -- -d /dev/nvme0n1 -h thinkpad-t440p

# Opções adicionais (tamanho do swap):
curl -sL https://raw.githubusercontent.com/clouraen/nix-config/main/bootstrap.sh | bash -s -- -d /dev/sda -h desktop -s 16G
```

## Instalação Manual

1. Baixe o instalador NixOS
2. Boot no instalador
3. Clone este repositório:
```bash
git clone https://github.com/clouraen/nix-config.git
cd nix-config
```

4. Execute o script de instalação:
```bash
# Para Desktop:
nix run .#install -- -d /dev/sda -h desktop -s 16G

# Para ThinkPad T440p:
nix run .#install -- -d /dev/nvme0n1 -h thinkpad-t440p -s 8G

# Para MacBook M1 (requer particionamento manual):
# Primeiro faça o particionamento manual e depois:
nix run .#install -- -d /dev/nvme0n1 -h macbook-m1 -s 8G
```

## Configurações

### Usuário Padrão
- Username: huggyturd
- Senha inicial: nixos]
- Sudo sem senha habilitado

### Desktop Environment
- Hyprland (Wayland)
- Configuração baseada em end-4/dots-hyprland

### Pacotes Comuns
- Google Chrome
- Vim
- Git
- Terminal: kitty
- Barra: waybar
- Notificações: dunst
- Menu: wofi/rofi

### Específico por Host

#### Desktop
- Drivers NVIDIA otimizados
- Suporte OpenGL/Vulkan
- Performance CPU Intel

#### ThinkPad T440p
- TLP para gerenciamento de bateria
- ThinkFan
- Trackpoint configurado

#### MacBook M1
- Asahi Linux otimizado
- Firmware específico
- Gerenciamento de energia

## Manutenção

Para atualizar o sistema:
```bash
sudo nixos-rebuild switch
```

Para atualizar com alterações no flake:
```bash
sudo nixos-rebuild switch --flake .#hostname
```

## Estrutura do Projeto
```
.
├── common/           # Configurações compartilhadas
├── hosts/           # Configurações específicas por host
├── modules/         # Módulos customizados
└── scripts/         # Scripts de instalação
```
