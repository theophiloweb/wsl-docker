#!/bin/bash

# Script de Configuracao de Ambiente de Desenvolvimento para WSL Ubuntu
# Escrito inteiramente em portugues brasileiro sem acentos
# Compativel com Ubuntu WSL 22.04

set -e  # Para em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Funcao para imprimir mensagens coloridas
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Funcao para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funcao para verificar e configurar /etc/wsl.conf
configure_wsl_conf() {
    print_message $BLUE "Verificando configuracao do WSL..."
    
    local wsl_conf="/etc/wsl.conf"
    local need_restart=false
    
    # Conteudo necessario para o wsl.conf
    local required_content="[boot]
systemd=true

[interop]
appendWindowsPath=false
enabled=false"
    
    if [ ! -f "$wsl_conf" ]; then
        print_message $YELLOW "Arquivo /etc/wsl.conf nao encontrado. Criando..."
        echo "$required_content" | sudo tee "$wsl_conf" > /dev/null
        need_restart=true
        print_message $GREEN "Arquivo /etc/wsl.conf criado com sucesso!"
    else
        print_message $BLUE "Arquivo /etc/wsl.conf encontrado. Verificando configuracoes..."
        
        # Verificar se as configuracoes necessarias estao presentes
        if ! grep -q "systemd=true" "$wsl_conf" || ! grep -q "appendWindowsPath=false" "$wsl_conf" || ! grep -q "enabled=false" "$wsl_conf"; then
            print_message $YELLOW "Configuracoes incompletas encontradas. Corrigindo..."
            sudo cp "$wsl_conf" "${wsl_conf}.backup.$(date +%Y%m%d_%H%M%S)"
            echo "$required_content" | sudo tee "$wsl_conf" > /dev/null
            need_restart=true
            print_message $GREEN "Configuracoes corrigidas!"
        else
            print_message $GREEN "Configuracoes do WSL estao corretas!"
        fi
    fi
    
    if [ "$need_restart" = true ]; then
        print_message $RED "IMPORTANTE: E necessario reiniciar o WSL para aplicar as mudancas."
        print_message $RED "Execute 'wsl --shutdown' no PowerShell/CMD do Windows e abra novamente o WSL."
        read -p "Pressione Enter para continuar (as configuracoes serao aplicadas no proximo reinicio)..."
    fi
}

# Funcao para atualizar sistema
update_system() {
    print_message $BLUE "Atualizando sistema..."
    sudo apt update && sudo apt upgrade -y
    print_message $GREEN "Sistema atualizado com sucesso!"
}

# Funcao para instalar Next.js
install_nextjs() {
    print_message $BLUE "Iniciando instalacao do ambiente Next.js..."
    
    # Instalar dependencias
    print_message $BLUE "Instalando dependencias basicas..."
    sudo apt install -y curl build-essential
    
    # Instalar NVM
    print_message $BLUE "Instalando NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Instalar Node.js mais recente
    print_message $BLUE "Instalando Node.js mais recente..."
    nvm install node
    nvm use node
    
    # Criar diretorio do projeto
    local project_dir="$HOME/projeto-nextjs"
    print_message $BLUE "Criando projeto Next.js em $project_dir..."
    
    if [ -d "$project_dir" ]; then
        print_message $YELLOW "Diretorio ja existe. Removendo..."
        rm -rf "$project_dir"
    fi
    
    # Criar projeto Next.js com TypeScript e Tailwind
    npx create-next-app@latest "$project_dir" --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
    
    print_message $GREEN "Ambiente Next.js configurado com sucesso!"
    print_message $BLUE "Para iniciar o projeto:"
    print_message $BLUE "cd $project_dir && npm run dev"
}

# Funcao para instalar Node.js
install_nodejs() {
    print_message $BLUE "Iniciando instalacao do ambiente Node.js..."
    
    # Instalar NVM
    print_message $BLUE "Instalando NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Instalar Node.js e npm
    print_message $BLUE "Instalando Node.js e npm..."
    nvm install node
    nvm use node
    
    # Criar diretorio do projeto
    local project_dir="$HOME/projeto-nodejs"
    print_message $BLUE "Criando pasta do projeto em $project_dir..."
    
    mkdir -p "$project_dir"
    cd "$project_dir"
    npm init -y
    
    # Criar arquivo index.js basico
    cat > index.js << EOF
console.log('Ola, mundo! Seu ambiente Node.js esta funcionando!');
EOF
    
    print_message $GREEN "Ambiente Node.js configurado com sucesso!"
    print_message $BLUE "Para testar: cd $project_dir && node index.js"
}

# Funcao para instalar Python
install_python() {
    print_message $BLUE "Iniciando instalacao do ambiente Python..."
    
    # Instalar Python e pip
    print_message $BLUE "Instalando Python3, pip e venv..."
    sudo apt install -y python3 python3-pip python3-venv
    
    # Criar diretorio do projeto
    local project_dir="$HOME/projeto-python"
    print_message $BLUE "Criando projeto Python em $project_dir..."
    
    if [ -d "$project_dir" ]; then
        print_message $YELLOW "Diretorio ja existe. Removendo..."
        rm -rf "$project_dir"
    fi
    
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # Criar ambiente virtual
    print_message $BLUE "Criando ambiente virtual..."
    python3 -m venv venv
    source venv/bin/activate
    
    # Instalar pacotes basicos
    print_message $BLUE "Instalando pacotes basicos (requests, flask)..."
    pip install requests flask
    
    # Criar arquivo requirements.txt
    pip freeze > requirements.txt
    
    # Criar arquivo Python basico
    cat > app.py << EOF
from flask import Flask
import requests

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Ola, mundo! Seu ambiente Python com Flask esta funcionando!'

@app.route('/test-requests')
def test_requests():
    try:
        response = requests.get('https://httpbin.org/json')
        return f'Teste de requests bem-sucedido: {response.status_code}'
    except Exception as e:
        return f'Erro no teste de requests: {str(e)}'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF
    
    # Criar script de ativacao
    cat > ativar_ambiente.sh << EOF
#!/bin/bash
source venv/bin/activate
echo "Ambiente virtual Python ativado!"
echo "Para executar a aplicacao: python app.py"
EOF
    chmod +x ativar_ambiente.sh
    
    print_message $GREEN "Ambiente Python configurado com sucesso!"
    print_message $BLUE "Para ativar o ambiente: cd $project_dir && source venv/bin/activate"
    print_message $BLUE "Para executar a aplicacao: python app.py"
}

# Funcao para instalar Java
install_java() {
    print_message $BLUE "Iniciando instalacao do ambiente Java..."
    
    # Instalar JDK e Maven
    print_message $BLUE "Instalando OpenJDK e Maven..."
    sudo apt install -y default-jdk maven
    
    # Criar diretorio do projeto
    local project_dir="$HOME/projeto-java"
    print_message $BLUE "Criando projeto Maven em $project_dir..."
    
    if [ -d "$project_dir" ]; then
        print_message $YELLOW "Diretorio ja existe. Removendo..."
        rm -rf "$project_dir"
    fi
    
    # Criar projeto Maven
    mvn archetype:generate -DgroupId=com.exemplo.app -DartifactId=projeto-java -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false -DoutputDirectory="$HOME"
    
    # Renomear diretorio para o padrao esperado
    if [ -d "$HOME/projeto-java" ]; then
        rm -rf "$HOME/projeto-java"
    fi
    mv "$HOME/projeto-java" "$project_dir" 2>/dev/null || true
    
    cd "$project_dir"
    
    # Atualizar versao do Java no pom.xml
    sed -i 's/<maven.compiler.source>.*<\/maven.compiler.source>/<maven.compiler.source>11<\/maven.compiler.source>/' pom.xml
    sed -i 's/<maven.compiler.target>.*<\/maven.compiler.target>/<maven.compiler.target>11<\/maven.compiler.target>/' pom.xml
    
    # Compilar projeto
    print_message $BLUE "Compilando projeto..."
    mvn clean compile
    
    print_message $GREEN "Ambiente Java configurado com sucesso!"
    print_message $BLUE "Para compilar: cd $project_dir && mvn clean compile"
    print_message $BLUE "Para executar: mvn exec:java -Dexec.mainClass=\"com.exemplo.app.App\""
}

# Funcao para instalar PHP
install_php() {
    print_message $BLUE "Iniciando instalacao do ambiente PHP..."
    
    # Instalar PHP, Composer e Apache
    print_message $BLUE "Instalando PHP, Composer e Apache2..."
    sudo apt install -y php php-cli php-mbstring php-xml php-curl composer apache2
    
    # Configurar Apache
    print_message $BLUE "Configurando Apache..."
    sudo systemctl enable apache2
    sudo systemctl start apache2
    
    # Criar diretorio do projeto
    local project_dir="$HOME/projeto-php"
    print_message $BLUE "Criando projeto PHP em $project_dir..."
    
    if [ -d "$project_dir" ]; then
        print_message $YELLOW "Diretorio ja existe. Removendo..."
        rm -rf "$project_dir"
    fi
    
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # Inicializar projeto com Composer
    composer init --no-interaction --name="exemplo/projeto-php" --description="Projeto PHP de exemplo"
    
    # Criar estrutura basica
    mkdir -p public src
    
    # Criar arquivo index.php
    cat > public/index.php << EOF
<?php
require_once '../vendor/autoload.php';

echo "<h1>Ola, mundo!</h1>";
echo "<p>Seu ambiente PHP esta funcionando!</p>";
echo "<p>Versao do PHP: " . phpversion() . "</p>";
echo "<p>Data/Hora: " . date('Y-m-d H:i:s') . "</p>";
?>
EOF
    
    # Criar arquivo de configuracao do Apache
    cat > apache-config.txt << EOF
Para configurar o Apache para servir este projeto:
1. sudo ln -s $project_dir/public /var/www/html/projeto-php
2. Acesse http://localhost/projeto-php no navegador
EOF
    
    print_message $GREEN "Ambiente PHP configurado com sucesso!"
    print_message $BLUE "Para testar: php -S localhost:8000 -t public/"
    print_message $BLUE "Ou configure o Apache conforme arquivo apache-config.txt"
}

# Funcao para instalar MySQL
install_mysql() {
    print_message $BLUE "Instalando MySQL..."
    
    sudo apt install -y mysql-server mysql-client
    
    # Iniciar e habilitar MySQL
    sudo systemctl enable mysql
    sudo systemctl start mysql
    
    print_message $BLUE "Configurando MySQL..."
    print_message $YELLOW "Execute 'sudo mysql_secure_installation' para configurar a seguranca"
    
    # Criar usuario de exemplo
    sudo mysql -e "CREATE USER IF NOT EXISTS 'dev'@'localhost' IDENTIFIED BY 'dev123';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'dev'@'localhost' WITH GRANT OPTION;"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    print_message $GREEN "MySQL instalado e configurado!"
    print_message $BLUE "Usuario: dev | Senha: dev123"
    print_message $BLUE "Para conectar: mysql -u dev -p"
}

# Funcao para instalar PostgreSQL
install_postgresql() {
    print_message $BLUE "Instalando PostgreSQL..."
    
    sudo apt install -y postgresql postgresql-contrib
    
    # Iniciar e habilitar PostgreSQL
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    print_message $BLUE "Configurando PostgreSQL..."
    
    # Criar usuario de desenvolvimento
    sudo -u postgres createuser --interactive --pwprompt dev || true
    sudo -u postgres createdb -O dev devdb || true
    
    print_message $GREEN "PostgreSQL instalado e configurado!"
    print_message $BLUE "Usuario: dev | Database: devdb"
    print_message $BLUE "Para conectar: psql -U dev -d devdb -h localhost"
}

# Funcao para instalar MongoDB
install_mongodb() {
    print_message $BLUE "Instalando MongoDB..."
    
    # Instalar dependencias
    sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
    
    # Adicionar chave GPG
    curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    
    # Adicionar repositorio
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    
    # Atualizar e instalar
    sudo apt update
    sudo apt install -y mongodb-org
    
    # Iniciar e habilitar MongoDB
    sudo systemctl enable mongod
    sudo systemctl start mongod
    
    print_message $GREEN "MongoDB instalado e configurado!"
    print_message $BLUE "Para conectar: mongosh"
}

# Funcao para mostrar submenu de banco de dados
show_database_menu() {
    while true; do
        echo
        print_message $BLUE "=== MENU DE BANCO DE DADOS ==="
        echo "1. MySQL"
        echo "2. PostgreSQL" 
        echo "3. MongoDB"
        echo "4. Voltar ao menu principal"
        echo
        read -p "Escolha uma opcao (1-4): " db_choice
        
        case $db_choice in
            1)
                install_mysql
                break
                ;;
            2)
                install_postgresql
                break
                ;;
            3)
                install_mongodb
                break
                ;;
            4)
                return
                ;;
            *)
                print_message $RED "Opcao invalida. Tente novamente."
                ;;
        esac
    done
}

# Funcao para mostrar menu principal
show_main_menu() {
    while true; do
        echo
        print_message $GREEN "=== CONFIGURADOR DE AMBIENTE DE DESENVOLVIMENTO ==="
        print_message $GREEN "=== WSL Ubuntu - Versao em Portugues ==="
        echo
        echo "Escolha o ambiente que deseja configurar:"
        echo "1. Next.js"
        echo "2. Node.js"
        echo "3. Python"
        echo "4. Java"
        echo "5. PHP"
        echo "6. Banco de Dados"
        echo "7. Sair"
        echo
        read -p "Digite sua escolha (1-7): " choice
        
        case $choice in
            1)
                install_nextjs
                break
                ;;
            2)
                install_nodejs
                break
                ;;
            3)
                install_python
                break
                ;;
            4)
                install_java
                break
                ;;
            5)
                install_php
                break
                ;;
            6)
                show_database_menu
                ;;
            7)
                print_message $GREEN "Saindo do configurador. Ate logo!"
                exit 0
                ;;
            *)
                print_message $RED "Opcao invalida. Por favor, escolha entre 1-7."
                ;;
        esac
    done
}

# Funcao principal
main() {
    print_message $GREEN "Bem-vindo ao Configurador de Ambiente de Desenvolvimento!"
    print_message $BLUE "Este script ira configurar seu ambiente WSL Ubuntu para desenvolvimento."
    echo
    
    # Verificar e configurar WSL
    configure_wsl_conf
    
    # Atualizar sistema
    update_system
    
    # Mostrar menu principal
    show_main_menu
    
    print_message $GREEN "Configuracao concluida com sucesso!"
    print_message $BLUE "Seu ambiente de desenvolvimento esta pronto para uso."
}

# Executar script principal
main "$@"