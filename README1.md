# WSL Docker Style: Gerenciamento de Ambientes Isolados no WSL

![GitHub release (latest by date)](https://img.shields.io/github/v/release/theophiloweb/wsl-docker)
![GitHub](https://img.shields.io/github/license/theophiloweb/wsl-docker)

Bem-vindos à apresentação do **WSL Manager**, uma solução prática para criar e gerenciar ambientes de desenvolvimento isolados no Windows Subsystem for Linux (WSL), com a simplicidade do Docker e a vantagem da persistência de dados!

---

## Por que Ambientes Isolados São Importantes? 🛠️

No desenvolvimento de software, especialmente em projetos web, é comum trabalhar com diferentes versões de linguagens, bibliotecas e ferramentas. Imagine um projeto que usa Node.js 16 e outro que precisa do Node.js 18 — sem ambientes isolados, isso pode gerar conflitos e dores de cabeça. Ambientes isolados garantem que cada projeto tenha suas próprias dependências e configurações, mantendo tudo organizado e funcional.

O WSL nos permite rodar Linux no Windows de forma nativa, e com o **WSL Manager**, podemos criar esses ambientes isolados de maneira prática e persistente, sem as complicações de configurações de armazenamento que o Docker exige.

---

## Apresentando o WSL Manager 🚀

O **WSL Manager** é um script PowerShell chamado `wsl-manager.ps1` que transforma o WSL em uma ferramenta poderosa para gerenciar ambientes de desenvolvimento. Ele funciona como uma interface simples e intuitiva, permitindo criar, configurar e controlar instâncias WSL sem precisar entender comandos complexos do WSL — o script faz tudo para você!

### O que ele faz?

- Cria instâncias WSL baseadas em uma distribuição Linux (como `UbuntuMinimal2204`).
- Configura ambientes específicos (PHP, Node.js, Python, etc.) usando o script `provision-web-env.sh`.
- Gerencia essas instâncias com comandos fáceis, como listar, remover, fazer backup e mais.

### Principais Comandos

Aqui estão os comandos mais importantes do `wsl-manager.ps1` e exemplos de como usá-los:

- **create**: Cria uma nova instância WSL e provisiona o ambiente.
  ```powershell
  .\wsl-manager.ps1 -action create -name meu-projeto -base UbuntuMinimal2204 -envType node
  ```
  Isso cria uma instância chamada `meu-projeto` com um ambiente Node.js.

- **provision**: Configura ou atualiza o ambiente de uma instância existente.
  ```powershell
  .\wsl-manager.ps1 -action provision -name meu-projeto -envType php
  ```

- **list**: Lista todas as instâncias WSL registradas.
  ```powershell
  .\wsl-manager.ps1 -action list
  ```

- **remove**: Remove uma instância WSL.
  ```powershell
  .\wsl-manager.ps1 -action remove -name meu-projeto
  ```

- **exec**: Executa um comando dentro da instância como root.
  ```powershell
  .\wsl-manager.ps1 -action exec -name meu-projeto -command "npm install"
  ```

- **backup**: Faz backup de uma instância.
  ```powershell
  .\wsl-manager.ps1 -action backup -name meu-projeto
  ```

- **restore**: Restaura uma instância a partir de um backup.
  ```powershell
  .\wsl-manager.ps1 -action restore -name meu-projeto
  ```

- **monitor**: Monitora o uso de recursos das instâncias.
  ```powershell
  .\wsl-manager.ps1 -action monitor
  ```

- **stopall**: Para todas as instâncias em execução.
  ```powershell
  .\wsl-manager.ps1 -action stopall
  ```

- **help**: Mostra todos os comandos disponíveis.
  ```powershell
  .\wsl-manager.ps1 -action help
  ```

---

## O Papel do Script de Provisionamento 📋

O script `provision-web-env.sh` é chamado pelo `wsl-manager.ps1` para configurar o ambiente dentro da instância WSL. Ele instala as ferramentas e pacotes necessários com base no tipo de ambiente escolhido (ex.: PHP, Node.js, Python). Por exemplo:

- Para Node.js, ele já instala o NVM, Node.js LTS e Yarn. Poderia ser melhorado para incluir ferramentas como `create-react-app` e `create-next-app` para projetos React e Next.js.
- Para PHP, instala PHP 8.1, Nginx, MariaDB e Composer.

Esse script é flexível e pode ser adaptado para suportar mais tipos de ambientes conforme necessário.

---

## Como Usar o WSL Manager? ⚙️

### Instalação

1. Clone o repositório do GitHub:
   ```bash
   git clone https://github.com/theophiloweb/wsl-docker.git
   ```
2. Navegue até o diretório:
   ```bash
   cd wsl-docker
   ```
3. Execute o script para ver os comandos disponíveis:
   ```powershell
   .\wsl-manager.ps1 -action help
   ```

### Configuração

- Certifique-se de ter o WSL instalado no seu Windows.
- Tenha uma distribuição base (como `UbuntuMinimal2204`) pronta para criar novas instâncias.

Depois disso, é só usar os comandos para criar e gerenciar seus ambientes!

---

## Por que o WSL Manager é Melhor? 🌟

- **Simplicidade**: Não precisa aprender comandos complexos do WSL — o script faz tudo.
- **Persistência**: Diferente do Docker, que exige configurações extras para manter dados, o WSL já persiste tudo nativamente.
- **Flexibilidade**: Suporta diversos tipos de ambientes (PHP, Node.js, Python, etc.) em instâncias isoladas.

---

## Onde Encontrar o Projeto? 📂

O **WSL Manager** está disponível no GitHub:
[https://github.com/theophiloweb/wsl-docker/tree/main](https://github.com/theophiloweb/wsl-docker/tree/main)

Sinta-se à vontade para explorar, usar e contribuir!

---

## Autor 👨‍💻

**Teophilo Silva**

---

## Ideia para a Logo 🎨

Que tal uma logo que combine o pinguim estilizado do WSL com a baleia do Docker carregando containers? Isso simboliza a fusão das duas tecnologias: a leveza do WSL com a ideia de ambientes isolados do Docker, tudo com persistência nativa. Você pode criar algo assim no Canva ou com um designer gráfico!

---

Espero que essa apresentação inspire seus alunos a explorar o poder dos ambientes isolados com o WSL Manager!