#!/bin/bash
# Script de provisionamento para ambientes de desenvolvimento web no WSL
# Salve este arquivo como provision-web-env.sh

# Detectar argumentos
ENV_TYPE=${1:-"base"}
USERNAME=${2:-$(whoami)}

echo "Configurando ambiente: $ENV_TYPE para usuário: $USERNAME"

# Atualização básica
apt update && apt upgrade -y
apt install -y curl wget git unzip build-essential

# Configuração por tipo de ambiente
case "$ENV_TYPE" in
  "php")
    echo "Configurando ambiente PHP..."
    apt install -y php8.1 php8.1-cli php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip
    apt install -y nginx mariadb-server
    
    # Instalar Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    
    # Configurar Nginx
    systemctl enable nginx
    systemctl start nginx
    ;;
    
  "node")
    echo "Configurando ambiente Node.js..."
    # Instalar NVM para gerenciar versões do Node
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Instalar Node.js LTS
    nvm install --lts
    nvm use --lts
    
    # Instalar Yarn
    npm install -g yarn
    ;;
    
  "python")
    echo "Configurando ambiente Python..."
    apt install -y python3 python3-pip python3-venv
    
    # Instalar ferramentas úteis
    pip3 install virtualenv pipenv
    ;;
    
  "base")
    echo "Configurando ambiente base..."
    # Instalação mínima já feita com os pacotes iniciais
    ;;
    
  *)
    echo "Tipo de ambiente não reconhecido. Instalando configuração base."
    ;;
esac

# Configurar firewall
apt install -y ufw
ufw allow ssh
ufw allow http
ufw allow https

# Configurações do sistema
echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf

# Configurações para o usuário
if [ "$USERNAME" != "root" ]; then
  # Adicionar ao grupo sudo se não estiver
  usermod -aG sudo $USERNAME
  
  # Configurar .bashrc com aliases úteis
  cat > /home/$USERNAME/.bash_aliases << EOL
alias ll='ls -la'
alias update='sudo apt update && sudo apt upgrade -y'
alias refresh='source ~/.bashrc'
EOL

  # Ajustar permissões
  chown $USERNAME:$USERNAME /home/$USERNAME/.bash_aliases
fi

echo "Provisionamento concluído para ambiente $ENV_TYPE!"
