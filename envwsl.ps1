# Script em Portugues do Brasil (pt-BR) sem acentos.
# Codificacao: UTF-8 (recomendado para salvar o arquivo .ps1)

# Funcao para exibir o titulo ASCII art
function ExibirTituloASCII {
    Clear-Host
    Write-Host "WW      WW   SSSSSS   LL"
    Write-Host "WW      WW  SS    SS  LL"
    Write-Host "WW   W  WW  SSSSSS   LL"
    Write-Host "WW  W W WW  SS        LL"
    Write-Host " WWWW  WWWW  SSSSSS   LLLLLL"
    Write-Host "-------------------------------"
    Write-Host " Gerenciador WSL Estilo Docker "
    Write-Host "-------------------------------"
    Write-Host ""
}

# Funcao para pausar a execucao do script
function PausarExecucao {
    Write-Host ""
    Read-Host -Prompt "Pressione Enter para continuar..."
}

# Funcao para ler entrada do usuario
function ObterEntradaUsuario {
    param (
        [string]$MensagemPromptUsuario
    )
    return Read-Host -Prompt $MensagemPromptUsuario
}

# 1. Listar distribuicoes online
function ListarDistribuicoesOnline {
    ExibirTituloASCII
    Write-Host "Listando distribuicoes disponiveis online..."
    Write-Host "----------------------------------------------------"
    try {
        wsl --list --online
    }
    catch {
        Write-Host "Erro ao listar distribuicoes online. Verifique sua conexao com a internet e se o WSL esta habilitado."
    }
    PausarExecucao
}

# 2. Instalar nova distribuicao (e instancia)
function InstalarNovaDistribuicao {
    ExibirTituloASCII
    Write-Host "Instalar Nova Distribuicao WSL"
    Write-Host "------------------------------"
    Write-Host "Distribuicoes disponiveis online (use o NOME da coluna NAME):"
    wsl --list --online # Exibe a lista para o usuario escolher
    Write-Host ""
    $nomeDistribuicaoParaInstalar = ObterEntradaUsuario "Digite o NOME da distribuicao que deseja instalar (ex: Ubuntu-22.04)"

    if (-not [string]::IsNullOrWhiteSpace($nomeDistribuicaoParaInstalar)) {
        Write-Host "Iniciando a instalacao de '$nomeDistribuicaoParaInstalar'..."
        Write-Host "A instalacao continuara neste terminal ou em uma nova janela."
        Write-Host "Voce precisara criar um usuario e senha para a nova distribuicao."
        Write-Host "Após concluir, você deverá entrar na instância com comando wsl - d <nome_da_distribuicao> para criar usuário e senha"
        try {
            Write-Host "Comando de instalacao para '$nomeDistribuicaoParaInstalar' disparado. Aguarde..."
            # O comando wsl --install pode ser interativo e tomar controle do console.
            # O script deve sair apos este comando ser iniciado.
            wsl --install -d $nomeDistribuicaoParaInstalar
            
            # Esta mensagem pode ou nao ser exibida dependendo de como 'wsl --install' se comporta.
            Write-Host "Processo de instalacao da distribuicao '$nomeDistribuicaoParaInstalar' iniciado."
            Write-Host "Siga as instrucoes na tela. O script sera encerrado."
        }
        catch {
            Write-Host "Erro ao iniciar a instalacao de '$nomeDistribuicaoParaInstalar'."
            # A mensagem de excecao pode conter acentos, pois vem do sistema.
            Write-Host "Detalhes do erro: $($_.Exception.Message)"
            PausarExecucao # Permite ao usuario ver o erro antes do script encerrar.
        }
    } else {
        Write-Host "Nome da distribuicao nao pode ser vazio."
        PausarExecucao # Permite ao usuario ver a mensagem antes do script encerrar.
    }
    # O loop principal do menu ira tratar o encerramento do script.
}

# Funcao auxiliar para listar instancias locais instaladas
function ListarInstanciasLocais {
    try {
        # O comando wsl --list --quiet retorna os nomes das instancias.
        $saidaComandoWsl = wsl --list --quiet
        $nomesLimpasInstancias = @()

        if ($null -ne $saidaComandoWsl) {
            # Garante que estamos iterando sobre uma colecao.
            # Se for uma unica string, o loop foreach ainda funciona.
            foreach ($linha in $saidaComandoWsl) {
                $nomeSemEspacos = $linha.Trim()
                # Remove caracteres nulos que podem aparecer na saida do wsl.
                $nomeFinal = $nomeSemEspacos -replace "\x00", ""
                if (-not [string]::IsNullOrWhiteSpace($nomeFinal)) {
                    $nomesLimpasInstancias += $nomeFinal
                }
            }
        }
        return $nomesLimpasInstancias
    }
    catch {
        Write-Host "Erro ao listar instancias WSL instaladas."
        # Write-Host "Detalhes do erro: $($_.Exception.Message)" # Opcional: mostrar detalhes do erro.
        return @() # Retorna array vazio em caso de erro.
    }
}

# 3. Desregistrar (remover) instancia WSL
function DesregistrarInstancia {
    ExibirTituloASCII
    Write-Host "Remover Instancia WSL Existente"
    Write-Host "-------------------------------"
    $listaNomesInstancias = ListarInstanciasLocais

    if ($listaNomesInstancias.Count -eq 0) {
        Write-Host "Nenhuma instancia WSL instalada para remover."
        PausarExecucao
        return
    }

    Write-Host "Instancias WSL instaladas:"
    for ($i = 0; $i -lt $listaNomesInstancias.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i + 1), $listaNomesInstancias[$i])
    }
    Write-Host ""

    $nomeInstanciaAlvo = ObterEntradaUsuario "Digite o NOME EXATO da instancia que deseja remover"

    if (-not ([string]::IsNullOrWhiteSpace($nomeInstanciaAlvo)) -and ($listaNomesInstancias -contains $nomeInstanciaAlvo)) {
        $confirmaAcao = ObterEntradaUsuario "Tem certeza que deseja remover a instancia '$nomeInstanciaAlvo'? Esta acao nao pode ser desfeita. (s/n)"
        if ($confirmaAcao -eq 's') {
            Write-Host "Removendo instancia '$nomeInstanciaAlvo'..."
            try {
                wsl --unregister $nomeInstanciaAlvo
                Write-Host "Instancia '$nomeInstanciaAlvo' removida com sucesso."
            }
            catch {
                Write-Host "Erro ao remover a instancia '$nomeInstanciaAlvo'."
                Write-Host "Detalhes do erro: $($_.Exception.Message)"
            }
        } else {
            Write-Host "Remocao cancelada."
        }
    } else {
        Write-Host "Nome da instancia invalido ou nao encontrado."
    }
    PausarExecucao
}

# 4. Exportar (backup) instancia WSL
function ExportarInstancia {
    ExibirTituloASCII
    Write-Host "Fazer Backup (Exportar) de Instancia WSL"
    Write-Host "----------------------------------------"
    $listaNomesInstancias = ListarInstanciasLocais

    if ($listaNomesInstancias.Count -eq 0) {
        Write-Host "Nenhuma instancia WSL instalada para fazer backup."
        PausarExecucao
        return
    }

    Write-Host "Instancias WSL instaladas:"
    for ($i = 0; $i -lt $listaNomesInstancias.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i + 1), $listaNomesInstancias[$i])
    }
    Write-Host ""

    $nomeInstanciaAlvo = ObterEntradaUsuario "Digite o NOME EXATO da instancia para backup"

    if (-not ([string]::IsNullOrWhiteSpace($nomeInstanciaAlvo)) -and ($listaNomesInstancias -contains $nomeInstanciaAlvo)) {
        $caminhoArquivoExportado = ObterEntradaUsuario "Digite o caminho completo e nome do arquivo para o backup (ex: C:\BackupWSL\meu_backup.tar)"
        if (-not [string]::IsNullOrWhiteSpace($caminhoArquivoExportado)) {
            $pastaBackup = Split-Path -Path $caminhoArquivoExportado -Parent
            if (-not (Test-Path -Path $pastaBackup -PathType Container)) {
                Write-Host "A pasta de backup '$pastaBackup' nao existe. Tentando criar..."
                try {
                    New-Item -ItemType Directory -Path $pastaBackup -Force -ErrorAction Stop | Out-Null
                    Write-Host "Pasta de backup '$pastaBackup' criada com sucesso."
                } catch {
                    Write-Host "Erro ao criar pasta de backup '$pastaBackup'."
                    Write-Host "Detalhes do erro: $($_.Exception.Message)"
                    PausarExecucao
                    return
                }
            }

            Write-Host "Fazendo backup da instancia '$nomeInstanciaAlvo' para '$caminhoArquivoExportado'..."
            try {
                wsl --export $nomeInstanciaAlvo $caminhoArquivoExportado
                Write-Host "Backup da instancia '$nomeInstanciaAlvo' concluido com sucesso em '$caminhoArquivoExportado'."
            }
            catch {
                Write-Host "Erro durante o backup da instancia '$nomeInstanciaAlvo'."
                Write-Host "Detalhes do erro: $($_.Exception.Message)"
            }
        } else {
            Write-Host "Caminho do arquivo de backup nao pode ser vazio."
        }
    } else {
        Write-Host "Nome da instancia invalido ou nao encontrado."
    }
    PausarExecucao
}

# 5. Importar (restaurar) instancia WSL
function ImportarInstancia {
    ExibirTituloASCII
    Write-Host "Restaurar (Importar) Instancia WSL de Backup"
    Write-Host "--------------------------------------------"
    $caminhoArquivoExportado = ObterEntradaUsuario "Digite o caminho completo do arquivo de backup .tar para restaurar"

    if ([string]::IsNullOrWhiteSpace($caminhoArquivoExportado) -or -not (Test-Path $caminhoArquivoExportado -PathType Leaf)) {
        Write-Host "Arquivo de backup '$caminhoArquivoExportado' invalido ou nao encontrado."
        PausarExecucao
        return
    }

    $nomeNovaInstanciaImportada = ObterEntradaUsuario "Digite o nome para a nova instancia restaurada"
    if ([string]::IsNullOrWhiteSpace($nomeNovaInstanciaImportada)) {
        Write-Host "Nome da nova instancia nao pode ser vazio."
        PausarExecucao
        return
    }

    # Verificar se ja existe instancia com esse nome
    $listaNomesInstanciasExistentes = ListarInstanciasLocais
    if ($listaNomesInstanciasExistentes -contains $nomeNovaInstanciaImportada) {
        Write-Host "Ja existe uma instancia WSL com o nome '$nomeNovaInstanciaImportada'. Escolha um nome diferente."
        PausarExecucao
        return
    }

    $pastaInstalacaoNovaInstancia = ObterEntradaUsuario "Digite o caminho da pasta onde a nova instancia sera instalada (ex: C:\WSLInstancias\$nomeNovaInstanciaImportada)"
    if ([string]::IsNullOrWhiteSpace($pastaInstalacaoNovaInstancia)) {
        Write-Host "Caminho da pasta de instalacao nao pode ser vazio."
        PausarExecucao
        return
    }

    # Criar diretorio de instalacao se nao existir
    if (-not (Test-Path -Path $pastaInstalacaoNovaInstancia -PathType Container)) {
        Write-Host "A pasta de instalacao '$pastaInstalacaoNovaInstancia' nao existe. Tentando criar..."
        try {
            New-Item -ItemType Directory -Path $pastaInstalacaoNovaInstancia -Force -ErrorAction Stop | Out-Null
            Write-Host "Pasta de instalacao '$pastaInstalacaoNovaInstancia' criada com sucesso."
        } catch {
            Write-Host "Erro ao criar pasta de instalacao '$pastaInstalacaoNovaInstancia'."
            Write-Host "Detalhes do erro: $($_.Exception.Message)"
            PausarExecucao
            return
        }
    }

    Write-Host "Restaurando instancia '$nomeNovaInstanciaImportada' de '$caminhoArquivoExportado' para '$pastaInstalacaoNovaInstancia'..."
    try {
        wsl --import $nomeNovaInstanciaImportada $pastaInstalacaoNovaInstancia $caminhoArquivoExportado
        Write-Host "Instancia '$nomeNovaInstanciaImportada' restaurada com sucesso em '$pastaInstalacaoNovaInstancia'."
    }
    catch {
        Write-Host "Erro ao restaurar a instancia '$nomeNovaInstanciaImportada'."
        Write-Host "Detalhes do erro: $($_.Exception.Message)"
    }
    PausarExecucao
}


# --- Menu Principal ---
$manterMenuAtivo = $true
while ($manterMenuAtivo) {
    ExibirTituloASCII
    Write-Host "Menu Principal - Gerenciador WSL"
    Write-Host "--------------------------------"
    Write-Host "1. Listar distribuicoes online"
    Write-Host "2. Instalar nova distribuicao (encerra o script apos iniciar)"
    Write-Host "3. Remover instancia WSL existente"
    Write-Host "4. Fazer backup (exportar) de instancia WSL"
    Write-Host "5. Restaurar (importar) instancia WSL de backup"
    Write-Host "6. Sair"
    Write-Host ""

    $opcaoSelecionada = ObterEntradaUsuario "Escolha uma opcao"

    switch ($opcaoSelecionada) {
        "1" { ListarDistribuicoesOnline }
        "2" {
            InstalarNovaDistribuicao
            $manterMenuAtivo = $false # Define para sair do loop e do script
        }
        "3" { DesregistrarInstancia }
        "4" { ExportarInstancia }
        "5" { ImportarInstancia }
        "6" {
            Write-Host "Saindo do script..."
            $manterMenuAtivo = $false
        }
        default {
            Write-Host "Opcao invalida. Pressione Enter para tentar novamente."
            PausarExecucao
        }
    }
}

Write-Host "Script finalizado."
# Fim do Script