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

## 📖 Sobre o Projeto

Bem-vindo! Este guia explora abordagens aprimoradas para gerenciar suas instâncias do Subsistema Windows para Linux (WSL) e para configurar ambientes de desenvolvimento isolados e prontos para uso, inspirando-se na simplicidade e eficiência de ferramentas modernas como Docker, mas aproveitando a integração profunda do WSL com o Windows.

---

## 🎯 Objetivo

Simplificar e automatizar tarefas comuns no WSL, tornando o fluxo de trabalho de desenvolvimento mais rápido, consistente e agradável. Apresentamos duas frentes principais:

1. **Gerenciamento de Instâncias WSL "Estilo Docker"**: Uma maneira mais intuitiva de lidar com suas distribuições Linux.
2. **Configuração Automatizada de Ambientes**: Um script Bash robusto para provisionar rapidamente ambientes de desenvolvimento completos dentro de uma instância WSL Ubuntu.

---

## 🔧 Parte 1: Gerenciamento de Instâncias WSL ("Estilo Docker")

Gerenciar múltiplas instâncias WSL através de comandos diretos no terminal pode ser poderoso, mas também verboso e propenso a erros para operações rotineiras.

### 📋 Abordagem Tradicional com Comandos `wsl.exe`

Comandos diretos oferecem controle granular total:

**Listar distribuições online:**
```powershell
wsl --list --online
```

**Instalar uma distribuição (ex: Ubuntu-22.04):**
```powershell
wsl --install -d Ubuntu-22.04
```

**Listar instaladas:**
```powershell
wsl --list --verbose
```

**Remover uma instância:**
```powershell
wsl --unregister NomeDaDistribuicao
```

**Exportar (Backup):**
```powershell
wsl --export NomeDaDistribuicao caminho\do\backup.tar
```

**Importar (Restaurar):**
```powershell
wsl --import NovaInstancia caminho\de\instalacao caminho\do\backup.tar
```

### ✅ Vantagens e Desvantagens

**👍 Vantagens:** 
- Controle máximo
- Sem dependências externas

**👎 Desvantagens:** 
- Repetitivo
- Curva de aprendizado para novos usuários
- Maior chance de erros de digitação em comandos complexos

### 🎨 Abordagem "WSL Docker Style" com Script PowerShell Interativo

Inspirado na facilidade de uso de interfaces como Docker Desktop, um script PowerShell encapsula esses comandos em um menu interativo e em português, proporcionando uma experiência mais amigável ao usuário.

---

## 👨‍💻 Autor

<div align="center">

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/francisco-das-chagas-te%C3%B3filo-da-silva-15a12b2ab/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/theophiloweb)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:teophilo@gmail.com)

**Francisco das Chagas Teófilo da Silva**

📧 **Email:** teophilo@gmail.com  
🔗 **LinkedIn:** [Francisco das Chagas Teófilo da Silva](https://www.linkedin.com/in/francisco-das-chagas-te%C3%B3filo-da-silva-15a12b2ab/)  
🐙 **GitHub:** [theophiloweb](https://github.com/theophiloweb)

</div>

---

## 📄 Licença

<div align="center">

![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

</div>

---

<div align="center">

## 🚀 Pronto para Revolucionar seu Desenvolvimento?

**⬇️ Baixe a documentação completa e comece agora mesmo! ⬇️**

[![Download](https://img.shields.io/badge/Download-Documentação_Completa-4CAF50?style=for-the-badge&logo=download&logoColor=white)](#)

---

**⭐ Se este projeto te ajudou, deixe uma estrela no GitHub! ⭐**

![Footer](https://img.shields.io/badge/Made_with-❤️_and_PowerShell-blue?style=for-the-badge)

</div>

---

## 🤝 Contribuições

Contribuições são sempre bem-vindas! Sinta-se à vontade para:

- Abrir issues para reportar bugs ou sugerir melhorias
- Enviar pull requests com novos recursos
- Melhorar a documentação
- Compartilhar o projeto com outros desenvolvedores

---

<div align="center">

**Desenvolvido com ❤️ e muito ☕**

</div>
