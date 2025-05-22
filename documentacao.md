# WSL Docker-Style: Documentação Completa
## Configuração do WSL no Windows 11 com Gerenciamento Estilo Docker

### 📋 Pré-requisitos

- Windows 11 (versão 21H2 ou superior)
- PowerShell com privilégios de administrador
- Windows Terminal (recomendado)
- Conexão com internet

---

## 🚀 Instalação e Configuração Inicial

### Passo 1: Instalação do WSL

Abra o PowerShell como administrador e execute:

```powershell
# Instalar WSL
wsl --install

# Verificar a versão instalada
wsl -l -v

# Se não for WSL 2, definir como padrão
wsl --set-default-version 2
```

### Passo 2: Configuração do Windows Terminal

Para evitar erros com o Windows Terminal, adicione-o ao PATH:

```powershell
# Identificar a pasta do Windows Terminal
(Get-AppxPackage Microsoft.WindowsTerminal).InstallLocation

# Adicionar ao PATH do sistema (executar como administrador)
$wtPath = (Get-AppxPackage Microsoft.WindowsTerminal).InstallLocation
$env:PATH += ";$wtPath"
```

### Passo 3: Criação da Estrutura de Diretórios

```powershell
# Criar diretório principal para as instâncias WSL
mkdir D:\WSLDistros

# Navegar para o diretório
cd D:\WSLDistros
```

### Passo 4: Limpeza de Instalações Anteriores (se necessário)

```powershell
# Listar distribuições existentes
wsl --list --verbose

# Remover distribuições antigas (substitua <NomeDaDistro>)
wsl --unregister <NomeDaDistro>

# Parar WSL
wsl --shutdown

# Limpar cache de pacotes (opcional)
# Navegar para: C:\Users\SeuNome\AppData\Local\Packages\
# Remover pastas relacionadas ao WSL antigo
```

### Passo 5: Download e Configuração da Imagem Base Ubuntu Minimal

```powershell
# Criar diretório para a imagem base
New-Item -ItemType Directory -Path "D:\WSLDistros\UbuntuMinimal2204"

# Navegar para o diretório
cd .\UbuntuMinimal2204\

# Baixar Ubuntu 22.04 Minimal
curl.exe -L -o ubuntu-22.04-minimal-rootfs.tar.gz https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz

# Importar para WSL
wsl --import UbuntuMinimal2204 D:\WSLDistros\UbuntuMinimal2204 .\ubuntu-22.04-minimal-rootfs.tar.gz --version 2
```

### Passo 6: Configuração Global do WSL

Crie um arquivo de configuração global:

```powershell
notepad "$env:USERPROFILE\.wslconfig"
```

Adicione o seguinte conteúdo:

```ini
[wsl2]
kernelCommandLine = systemd.unified_cgroup_hierarchy=1
nestedVirtualization = true
localhostForwarding = true
memory = 4GB
processors = 2
swap = 2GB
```

---

## 📜 Scripts de Gerenciamento

### Script 1: provision-web-env.sh

Crie o arquivo `D:\WSLDistros\provision-web-env.sh`:

```bash
#!/bin/bash
# Script de provisionamento para ambientes de desenvolvimento web no WSL

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
```

### Script 2: wsl-manager.ps1

Crie o arquivo `D:\WSLDistros\wsl-manager.ps1`:

```powershell
# WSL Manager - Gerenciador de instâncias WSL similar ao Docker

param (
    [Parameter(Mandatory=$true)]
    [string]$action,
    [Parameter(Mandatory=$false)]
    [string]$name,
    [Parameter(Mandatory=$false)]
    [string]$base = "Ubuntu",
    [Parameter(Mandatory=$false)]
    [string]$envType = "base"
)

$basePath = "D:\WSLDistros"
$provisionScript = "$basePath\provision-web-env.sh"

# Verificar se o diretório base existe
if (-not (Test-Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}

# Função para criar uma nova instância
function New-WSLInstance {
    param($name, $base)
    $targetPath = "$basePath\$name"
    
    if (Test-Path $targetPath) {
        Write-Host "ERRO: Instância '$name' já existe." -ForegroundColor Red
        return $false
    }
    
    # Criar diretório para a instância
    New-Item -ItemType Directory -Path "$targetPath" | Out-Null
    
    Write-Host "Exportando distribuição base $base..." -ForegroundColor Yellow
    wsl --export $base "$targetPath\base.tar"
    
    if (-not (Test-Path "$targetPath\base.tar")) {
        Write-Host "ERRO: Falha ao exportar a distribuição base." -ForegroundColor Red
        return $false
    }
    
    Write-Host "Importando nova instância $name..." -ForegroundColor Yellow
    wsl --import $name "$targetPath\fs" "$targetPath\base.tar"
    
    # Limpar arquivo temporário
    Remove-Item "$targetPath\base.tar"
    
    return $true
}

# Função para provisionar uma instância
function Invoke-WSLProvisioning {
    param($name, $envType)
    
    # Verificar se o script de provisionamento existe
    if (-not (Test-Path $provisionScript)) {
        Write-Host "ERRO: Script de provisionamento não encontrado em $provisionScript" -ForegroundColor Red
        return
    }
    
    # Copiar o script para a instância WSL
    Write-Host "Copiando script de provisionamento para a instância..." -ForegroundColor Yellow
    wsl -d $name -e bash -c "mkdir -p /tmp"
    Get-Content $provisionScript | wsl -d $name -e bash -c "cat > /tmp/provision.sh"
    wsl -d $name -e bash -c "chmod +x /tmp/provision.sh"
    
    # Executar o script de provisionamento
    Write-Host "Executando provisionamento para ambiente $envType..." -ForegroundColor Yellow
    wsl -d $name -e bash -c "sudo /tmp/provision.sh $envType"
    
    Write-Host "Provisionamento concluído!" -ForegroundColor Green
}

# Função para listar todas as instâncias
function Get-WSLInstances {
    $instances = wsl --list --verbose
    Write-Host "`nInstâncias WSL configuradas:" -ForegroundColor Cyan
    Write-Host $instances
    
    Write-Host "`nDiretórios de instâncias:" -ForegroundColor Cyan
    Get-ChildItem $basePath -Directory | ForEach-Object {
        $size = "{0:N2} MB" -f ((Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "$($_.Name) - $size"
    }
}

# Função para remover uma instância
function Remove-WSLInstance {
    param($name)
    $targetPath = "$basePath\$name"
    
    if (-not (Test-Path $targetPath)) {
        Write-Host "ERRO: Instância '$name' não encontrada." -ForegroundColor Red
        return
    }
    
    # Parar a instância se estiver em execução
    Write-Host "Terminando a instância $name..." -ForegroundColor Yellow
    wsl --terminate $name
    
    # Desregistrar a instância
    Write-Host "Desregistrando a instância $name..." -ForegroundColor Yellow
    wsl --unregister $name
    
    # Remover os arquivos
    Write-Host "Removendo arquivos da instância $name..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $targetPath
    
    Write-Host "Instância $name removida com sucesso!" -ForegroundColor Green
}

# Função para iniciar uma instância
function Start-WSLInstance {
    param($name)
    $exists = wsl --list | Where-Object { $_ -match $name }
    if (-not $exists) {
        Write-Host "ERRO: Instância '$name' não encontrada." -ForegroundColor Red
        return
    }
    
    Write-Host "Iniciando instância $name..." -ForegroundColor Yellow
    wsl -d $name
}

# Função para executar um comando em uma instância
function Invoke-WSLCommand {
    param($name, $command)
    $exists = wsl --list | Where-Object { $_ -match $name }
    if (-not $exists) {
        Write-Host "ERRO: Instância '$name' não encontrada." -ForegroundColor Red
        return
    }
    
    Write-Host "Executando comando na instância $name..." -ForegroundColor Yellow
    wsl -d $name -e bash -c "$command"
}

# Função para exibir ajuda
function Show-Help {
    Write-Host "WSL Manager - Gerenciador de instâncias WSL similar ao Docker" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso: .\wsl-manager.ps1 -action <ação> [parâmetros]" -ForegroundColor White
    Write-Host ""
    Write-Host "Ações disponíveis:" -ForegroundColor Yellow
    Write-Host "  create  : Cria uma nova instância WSL" -ForegroundColor White
    Write-Host "    Parâmetros: -name <nome> [-base <distro_base>] [-envType <tipo_ambiente>]" -ForegroundColor Gray
    Write-Host "    Exemplo: .\wsl-manager.ps1 -action create -name projeto-php -base UbuntuMinimal2204 -envType php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  provision: Provisiona uma instância existente" -ForegroundColor White
    Write-Host "    Parâmetros: -name <nome> [-envType <tipo_ambiente>]" -ForegroundColor Gray
    Write-Host "    Exemplo: .\wsl-manager.ps1 -action provision -name projeto-node -envType node" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  start   : Inicia uma instância WSL" -ForegroundColor White
    Write-Host "    Parâmetros: -name <nome>" -ForegroundColor Gray
    Write-Host "    Exemplo: .\wsl-manager.ps1 -action start -name projeto-php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  list    : Lista todas as instâncias WSL configuradas" -ForegroundColor White
    Write-Host "    Exemplo: .\wsl-manager.ps1 -action list" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  remove  : Remove uma instância WSL" -ForegroundColor White
    Write-Host "    Parâmetros: -name <nome>" -ForegroundColor Gray
    Write-Host "    Exemplo: .\wsl-manager.ps1 -action remove -name projeto-php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  exec    : Executa um comando em uma instância WSL" -ForegroundColor White
    Write-Host "    Parâmetros: -name <nome> -command <comando>" -ForegroundColor Gray
    Write-Host "    Exemplo: .\wsl-manager.ps1 -action exec -name projeto-php -command 'ls -la'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  help    : Exibe esta ajuda" -ForegroundColor White
    Write-Host "    Exemplo: .\wsl-manager.ps1 -action help" -ForegroundColor Gray
}

# Processar a ação solicitada
switch ($action.ToLower()) {
    "create" {
        if (-not $name) {
            Write-Host "ERRO: Nome da instância não especificado." -ForegroundColor Red
            return
        }
        $success = New-WSLInstance -name $name -base $base
        if ($success -and $envType -ne "") {
            Invoke-WSLProvisioning -name $name -envType $envType
        }
    }
    
    "provision" {
        if (-not $name) {
            Write-Host "ERRO: Nome da instância não especificado." -ForegroundColor Red
            return
        }
        
        Invoke-WSLProvisioning -name $name -envType $envType
    }
    
    "start" {
        if (-not $name) {
            Write-Host "ERRO: Nome da instância não especificado." -ForegroundColor Red
            return
        }
        
        Start-WSLInstance -name $name
    }
    
    "list" {
        Get-WSLInstances
    }
    
    "remove" {
        if (-not $name) {
            Write-Host "ERRO: Nome da instância não especificado." -ForegroundColor Red
            return
        }
        
        Remove-WSLInstance -name $name
    }
    
    "exec" {
        if (-not $name) {
            Write-Host "ERRO: Nome da instância não especificado." -ForegroundColor Red
            return
        }
        
        if (-not $command) {
            Write-Host "ERRO: Comando não especificado." -ForegroundColor Red
            return
        }
        
        Invoke-WSLCommand -name $name -command $command
    }
    
    "help" {
        Show-Help
    }
    
    default {
        Write-Host "ERRO: Ação '$action' não reconhecida." -ForegroundColor Red
        Show-Help
    }
}
```

---

## 🔧 Configuração de Política de Execução

Para executar os scripts PowerShell, configure a política de execução:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

---

## 🎯 Uso Prático

### Criar uma Nova Instância

```powershell
# Exemplo: Criar instância PHP
D:\WSLDistros\wsl-manager.ps1 -action create -name projeto-php -base UbuntuMinimal2204 -envType php

# Exemplo: Criar instância Node.js
D:\WSLDistros\wsl-manager.ps1 -action create -name projeto-node -base UbuntuMinimal2204 -envType node

# Exemplo: Criar instância Python
D:\WSLDistros\wsl-manager.ps1 -action create -name projeto-python -base UbuntuMinimal2204 -envType python
```

### Listar Instâncias

```powershell
D:\WSLDistros\wsl-manager.ps1 -action list
```

### Acessar uma Instância

```powershell
# Método 1: Usando o script
D:\WSLDistros\wsl-manager.ps1 -action start -name projeto-php

# Método 2: Comando direto
wsl -d projeto-php
```

### Configurar Usuário Padrão (dentro da instância)

```bash
# Dentro da instância WSL
echo -e "[user]\ndefault=$USER" | sudo tee /etc/wsl.conf

# Sair e reiniciar a instância
exit
```

```powershell
# No PowerShell
wsl --terminate projeto-php
wsl -d projeto-php
```

### Provisionar uma Instância Existente

```powershell
D:\WSLDistros\wsl-manager.ps1 -action provision -name projeto-php -envType php
```

### Executar Comando em uma Instância

```powershell
D:\WSLDistros\wsl-manager.ps1 -action exec -name projeto-php -command "php --version"
```

### Remover uma Instância

```powershell
D:\WSLDistros\wsl-manager.ps1 -action remove -name projeto-php
```

---

## 📚 Comandos de Referência Rápida

| Ação | Comando |
|------|---------|
| **Criar instância** | `D:\WSLDistros\wsl-manager.ps1 -action create -name [nome] -base UbuntuMinimal2204 -envType [tipo]` |
| **Listar instâncias** | `D:\WSLDistros\wsl-manager.ps1 -action list` |
| **Iniciar instância** | `D:\WSLDistros\wsl-manager.ps1 -action start -name [nome]` |
| **Acessar diretamente** | `wsl -d [nome]` |
| **Provisionar** | `D:\WSLDistros\wsl-manager.ps1 -action provision -name [nome] -envType [tipo]` |
| **Executar comando** | `D:\WSLDistros\wsl-manager.ps1 -action exec -name [nome] -command "[comando]"` |
| **Remover instância** | `D:\WSLDistros\wsl-manager.ps1 -action remove -name [nome]` |
| **Ver ajuda** | `D:\WSLDistros\wsl-manager.ps1 -action help` |

---

## 🛠️ Troubleshooting

### Erro de Política de Execução

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Script não Encontrado

Use o caminho completo:

```powershell
& "D:\WSLDistros\wsl-manager.ps1" -action list
```

### Distribuição Base não Encontrada

Verifique as distribuições disponíveis:

```powershell
wsl --list
```

### Problemas de Rede na Instância

Reinicie o WSL:

```powershell
wsl --shutdown
```

### Erro de Permissão no Ubuntu

```bash
# Dentro da instância
sudo usermod -aG sudo $USER
```

---

## 🌟 Ambientes Suportados

- **base**: Instalação mínima com ferramentas básicas
- **php**: PHP 8.1, Nginx, MariaDB, Composer
- **node**: Node.js LTS via NVM, Yarn
- **python**: Python 3, pip, virtualenv, pipenv

---

## 📝 Notas Importantes

1. **Backup**: Sempre faça backup de suas instâncias importantes
2. **Recursos**: Monitore o uso de CPU e memória no arquivo `.wslconfig`
3. **Atualizações**: Execute `sudo apt update && sudo apt upgrade` regularmente
4. **Portas**: Use `localhostForwarding = true` no `.wslconfig` para acessar serviços
5. **Performance**: Mantenha arquivos de projeto dentro do sistema de arquivos do WSL para melhor performance

---

## 🔄 Fluxo de Trabalho Recomendado

1. **Criar** uma nova instância para cada projeto
2. **Provisionar** com o ambiente específico necessário
3. **Desenvolver** dentro da instância
4. **Remover** quando o projeto não for mais necessário
5. **Backup** das configurações importantes antes de remover

Esta documentação fornece um sistema completo de gerenciamento de instâncias WSL similar ao Docker, permitindo criar, gerenciar e provisionar ambientes de desenvolvimento isolados de forma eficiente.