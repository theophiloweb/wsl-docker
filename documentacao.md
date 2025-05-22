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
### Script 2: wsl-manager.ps1

Anexo ao projeto

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
