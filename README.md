# WSL Docker-Style 🐳

<div align="center">

![WSL](https://img.shields.io/badge/WSL-2-0078d4?style=for-the-badge&logo=windows&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-11-0078d4?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

</div>

---

<div align="center">

# 🚀 WSL Potencializado: Gerenciamento Simplificado e Ambientes de Desenvolvimento Automatizados 🐧

<p>
 <img src="logo.png" alt="WSL Docker" width="600"/>
</p>

![WSL 2 Badge](https://img.shields.io/badge/WSL-2-blue.svg?logo=linux&style=for-the-badge)
![PowerShell Badge](https://img.shields.io/badge/PowerShell-%3E%3D5.1-blue.svg?logo=powershell&style=for-the-badge)
![Bash Script Badge](https://img.shields.io/badge/Bash-Script-green.svg?logo=gnubash&style=for-the-badge)
![License MIT Badge](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

</div>

---

# WSL-Docker-Style

> **Ferramenta de Gerenciamento WSL via PowerShell**

Uma ferramenta de linha de comando elegante, criada em PowerShell, para simplificar e automatizar o gerenciamento de múltiplas instâncias do Subsistema Windows para Linux (WSL), oferecendo uma experiência de controle semelhante à do Docker.

---

## 🚀 Por que usar esta ferramenta?

Em um ambiente de desenvolvimento moderno, é comum precisar de múltiplos ambientes isolados para diferentes projetos. O Docker resolve isso com contêineres, mas o WSL2 por si só já oferece um poderoso ambiente de virtualização de distribuições Linux completas, que podem servir como ambientes de desenvolvimento robustos e isolados.

### O Problema
Gerenciar instâncias WSL (instalar, iniciar, parar, remover, clonar, configurar) via linha de comando padrão do `wsl.exe` pode ser verboso e pouco intuitivo.

### A Solução
Este script traz a simplicidade e agilidade do fluxo de trabalho do Docker para o gerenciamento de instâncias WSL, encapsulando comandos complexos em um menu interativo e fácil de usar.

---

## ✨ Funcionalidades Principais

O script centraliza todas as operações essenciais do WSL em uma interface amigável:

### 📋 Visualização e Instalação
- **Visualização de Distros**: Lista todas as distribuições Linux disponíveis para instalação online
- **Instalação Simplificada**: Instala novas distribuições diretamente do repositório oficial

### 🐳 Controle de Instâncias (Estilo Docker)
- Inicia, para e reinicia instâncias específicas
- Desliga todas as instâncias em execução com um único comando (`wsl --shutdown`)

### 💾 Gerenciamento de Snapshots
- **Criar (Exportar)**: Gera um backup (.tar) de uma instância existente, permitindo clonagem ou migração
- **Restaurar (Importar)**: Cria uma nova instância a partir de um arquivo de snapshot, ideal para replicar ambientes de desenvolvimento

### ⚙️ Configuração Centralizada
- Define qual instância WSL será a padrão
- Ajusta as configurações de performance globais do WSL2 (CPU, memória, swap) editando o arquivo `.wslconfig` de forma guiada

### 🗂️ Organização e Limpeza
- **Remoção Segura**: Remove uma ou múltiplas instâncias através de um menu de seleção numerado, com confirmação para evitar perdas acidentais
- **Organização**: Inclui uma função para criar diretórios padrão (`C:\distro` e `C:\distro\clone`) para organizar os arquivos das instâncias

---

## ⚙️ Como Usar

### Pré-requisitos
- Windows 11 com o WSL2 instalado e ativado
- PowerShell

### 🚀 Execução

1. **Salve o script** como `envwsl.ps1`

2. **Abra um terminal PowerShell**

3. **Navegue** até o diretório onde você salvou o arquivo

4. **Ajuste a política de execução** (se necessário):
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

5. **Execute o script**:
   ```powershell
   .\envwsl.ps1
   ```

### 🖥️ Interface do Menu

Após a execução, um menu interativo elegante será exibido:

```
=================================================================

           W     W   SSSSS   L
           W     W   S       L
           W  W  W   SSSSS   L
           W W W W       S   L
            W   W    SSSSS   LLLLL

               SSSSS  TTTTTT  Y   Y  L      EEEEE
               S        TT     Y Y   L      E
               SSSSS    TT      Y    L      EEEEE
                   S    TT      Y    L      E
               SSSSS    TT      Y    LLLLL  EEEEE

            DDDDDD    OOOOO   CCCCC  K   K  EEEEE  RRRRRR
            D    D   O     O  C      K  K   E      R    R
            D    D   O     O  C      KKK    EEEEE  RRRRRR
            D    D   O     O  C      K  K   E      R   R
            DDDDDD    OOOOO   CCCCC  K   K  EEEEE  R    R

=================================================================

                     WSL Management Tool
                  Gerenciador WSL Estilo Docker

Menu Principal - Gerenciador WSL
--------------------------------
1. Ver distribuições disponíveis online
2. Instalar nova distribuição (encerra o script após iniciar)
3. Criar pasta para distros (C:\distro)
4. Restaurar instância a partir de um snapshot (.tar)
5. Criar snapshot (backup) de uma instância
6. Definir instância padrão
7. Controlar e configurar instâncias (Iniciar, Parar, Remover, Performance)
8. Sair

Escolha uma opção:
```

---

## 👨‍💻 Autor

**Francisco das Chagas Teófilo da Silva**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/francisco-das-chagas-teófilo-da-silva-b5633324/)

---

## 📜 Licença

Este projeto está licenciado sob a **Licença MIT**. Veja o arquivo `LICENSE` para mais detalhes.

---

<div align="center">
  <strong>🌟 Se este projeto foi útil para você, considere dar uma estrela! 🌟</strong>
</div>
