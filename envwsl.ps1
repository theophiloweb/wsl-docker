# Script em Portugues do Brasil (pt-BR) sem acentos.
# Codificacao: UTF-8 (recomendado para salvar o arquivo .ps1)

# Garantir que a política de execução está configurada corretamente
Try {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "`n[INFO] Politica de execucao ajustada para RemoteSigned.`n" -ForegroundColor Green
}
Catch {
    Write-Host "[ERRO] Falha ao definir politica de execucao." -ForegroundColor Red
}


# Funcao para exibir o titulo ASCII art
function ExibirTituloASCII {
    Clear-Host
    
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "                                                                 " -ForegroundColor Cyan   
    Write-Host "                                                                 " -ForegroundColor Cyan
    Write-Host "           W     W   SSSSS   L                                   " -ForegroundColor Yellow
    Write-Host "           W     W   S       L                                   " -ForegroundColor Yellow
    Write-Host "           W  W  W   SSSSS   L                                   " -ForegroundColor Yellow
    Write-Host "           W W W W       S   L                                   " -ForegroundColor Yellow
    Write-Host "            W   W    SSSSS   LLLLL                              " -ForegroundColor Yellow
    Write-Host "                                                                 " -ForegroundColor Cyan
    Write-Host "               SSSSS  TTTTTT  Y   Y  L      EEEEE               " -ForegroundColor Magenta
    Write-Host "               S        TT     Y Y   L      E                   " -ForegroundColor Magenta
    Write-Host "               SSSSS    TT      Y    L      EEEEE               " -ForegroundColor Magenta
    Write-Host "                   S    TT      Y    L      E                   " -ForegroundColor Magenta
    Write-Host "               SSSSS    TT      Y    LLLLL  EEEEE               " -ForegroundColor Magenta
    Write-Host "                                                                 " -ForegroundColor Cyan
    Write-Host "            DDDDDD    OOOOO   CCCCC  K   K  EEEEE  RRRRRR       " -ForegroundColor Blue
    Write-Host "            D    D   O     O  C      K  K   E      R    R       " -ForegroundColor Blue
    Write-Host "            D    D   O     O  C      KKK    EEEEE  RRRRRR       " -ForegroundColor Blue
    Write-Host "            D    D   O     O  C      K  K   E      R   R        " -ForegroundColor Blue
    Write-Host "            DDDDDD    OOOOO   CCCCC  K   K  EEEEE  R    R       " -ForegroundColor Blue
    Write-Host "                                                                 " -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "                     WSL Management Tool                         " -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "                  Gerenciador WSL Estilo Docker                 " -ForegroundColor Gray
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

function Criar-PastaDistros {
    $pasta = "C:\distro"

    Try {
        if (-Not (Test-Path -Path $pasta)) {
            New-Item -ItemType Directory -Path $pasta -Force | Out-Null
            Write-Host "`n[OK] Pasta criada com sucesso em '$pasta'." -ForegroundColor Green
        }
        else {
            Write-Host "`n[INFO] A pasta '$pasta' ja existe." -ForegroundColor Yellow
        }
    }
    Catch {
        Write-Host "`n[ERRO] Nao foi possivel criar a pasta '$pasta'." -ForegroundColor Red
    }
    PausarExecucao
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

# Funcao para iniciar/parar instancias
function Controlar-Instancias {
    ExibirTituloASCII
    Write-Host "Iniciar/Parar Instancias WSL"
    Write-Host "----------------------------"
    
    $listaNomesInstancias = ListarInstanciasLocais
    
    if ($listaNomesInstancias.Count -eq 0) {
        Write-Host "[INFO] Nenhuma instancia WSL encontrada." -ForegroundColor Yellow
        PausarExecucao
        return
    }
    
    try {
        # Mostrar status atual
        Write-Host "`n[INFO] Status atual das instancias:" -ForegroundColor Cyan
        $statusInstancias = wsl --list --verbose
        
        if ($statusInstancias.Count -gt 1) {
            for ($i = 1; $i -lt $statusInstancias.Count; $i++) {
                $linha = $statusInstancias[$i].Trim() -replace "\x00", ""
                if (-not [string]::IsNullOrWhiteSpace($linha)) {
                    Write-Host "  $linha" -ForegroundColor Gray
                }
            }
        }
        
        Write-Host "`nOpcoes de controle:"
        Write-Host "1. Iniciar instancia especifica"
        Write-Host "2. Parar instancia especifica"
        Write-Host "3. Parar todas as instancias"
        Write-Host "4. Reiniciar instancia especifica"
        Write-Host "5. Voltar ao menu principal"
        
        $opcao = ObterEntradaUsuario "`nEscolha uma opcao"
        
        switch ($opcao) {
            "1" {
                $nome = ObterEntradaUsuario "Digite o nome da instancia para INICIAR"
                if ($listaNomesInstancias -contains $nome) {
                    Write-Host "[INFO] Iniciando instancia '$nome'..." -ForegroundColor Yellow
                    try {
                        # Iniciar executando um comando simples
                        wsl -d $nome -- echo "Instancia iniciada com sucesso"
                        Write-Host "[OK] Instancia '$nome' iniciada." -ForegroundColor Green
                    } catch {
                        Write-Host "[ERRO] Falha ao iniciar '$nome': $($_.Exception.Message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "[ERRO] Instancia '$nome' nao encontrada." -ForegroundColor Red
                }
            }
            
            "2" {
                $nome = ObterEntradaUsuario "Digite o nome da instancia para PARAR"
                if ($listaNomesInstancias -contains $nome) {
                    Write-Host "[INFO] Parando instancia '$nome'..." -ForegroundColor Yellow
                    try {
                        wsl --terminate $nome
                        Write-Host "[OK] Instancia '$nome' parada." -ForegroundColor Green
                    } catch {
                        Write-Host "[ERRO] Falha ao parar '$nome': $($_.Exception.Message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "[ERRO] Instancia '$nome' nao encontrada." -ForegroundColor Red
                }
            }
            
            "3" {
                $confirma = ObterEntradaUsuario "Confirma parar TODAS as instancias WSL? (s/n)"
                if ($confirma.ToLower() -eq 's' -or $confirma.ToLower() -eq 'sim') {
                    Write-Host "[INFO] Parando todas as instancias WSL..." -ForegroundColor Yellow
                    try {
                        wsl --shutdown
                        Write-Host "[OK] Todas as instancias foram paradas." -ForegroundColor Green
                    } catch {
                        Write-Host "[ERRO] Falha ao parar instancias: $($_.Exception.Message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "[INFO] Operacao cancelada." -ForegroundColor Yellow
                }
            }
            
            "4" {
                $nome = ObterEntradaUsuario "Digite o nome da instancia para REINICIAR"
                if ($listaNomesInstancias -contains $nome) {
                    Write-Host "[INFO] Reiniciando instancia '$nome'..." -ForegroundColor Yellow
                    try {
                        wsl --terminate $nome
                        Start-Sleep -Seconds 2
                        wsl -d $nome -- echo "Instancia reiniciada com sucesso"
                        Write-Host "[OK] Instancia '$nome' reiniciada." -ForegroundColor Green
                    } catch {
                        Write-Host "[ERRO] Falha ao reiniciar '$nome': $($_.Exception.Message)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "[ERRO] Instancia '$nome' nao encontrada." -ForegroundColor Red
                }
            }
            
            "5" {
                Write-Host "[INFO] Voltando ao menu principal..." -ForegroundColor Cyan
                return
            }
            
            default {
                Write-Host "[ERRO] Opcao invalida." -ForegroundColor Red
            }
        }
        
    } catch {
        Write-Host "[ERRO] Falha na operacao: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    PausarExecucao
}

# Funcao para definir instancia padrao
function Definir-InstanciaPadrao {
    ExibirTituloASCII
    Write-Host "Definir Instancia Padrao do WSL"
    Write-Host "-------------------------------"
    
    $listaNomesInstancias = ListarInstanciasLocais
    
    if ($listaNomesInstancias.Count -eq 0) {
        Write-Host "[INFO] Nenhuma instancia WSL encontrada." -ForegroundColor Yellow
        PausarExecucao
        return
    }
    
    try {
        # Mostrar instância padrão atual
        Write-Host "[INFO] Identificando instancia padrao atual..." -ForegroundColor Cyan
        $statusCompleto = wsl --list --verbose
        $instanciaPadraoAtual = "Nenhuma"
        
        if ($statusCompleto.Count -gt 1) {
            for ($i = 1; $i -lt $statusCompleto.Count; $i++) {
                $linha = $statusCompleto[$i].Trim() -replace "\x00", ""
                if ($linha.StartsWith("*")) {
                    $instanciaPadraoAtual = ($linha -replace "^\*\s*", "" -split "\s+")[0]
                    break
                }
            }
        }
        
        Write-Host "`nInstancia padrao atual: " -NoNewline -ForegroundColor White
        Write-Host "$instanciaPadraoAtual" -ForegroundColor Yellow
        
        Write-Host "`nInstancias disponiveis:"
        for ($i = 0; $i -lt $listaNomesInstancias.Count; $i++) {
            $marcador = if ($listaNomesInstancias[$i] -eq $instanciaPadraoAtual) { " (ATUAL)" } else { "" }
            Write-Host ("{0}. {1}{2}" -f ($i + 1), $listaNomesInstancias[$i], $marcador)
        }
        
        $nomeNovaInstanciaPadrao = ObterEntradaUsuario "`nDigite o nome da instancia que sera a nova PADRAO"
        
        if (-not ([string]::IsNullOrWhiteSpace($nomeNovaInstanciaPadrao)) -and ($listaNomesInstancias -contains $nomeNovaInstanciaPadrao)) {
            
            if ($nomeNovaInstanciaPadrao -eq $instanciaPadraoAtual) {
                Write-Host "[INFO] A instancia '$nomeNovaInstanciaPadrao' ja e a padrao atual." -ForegroundColor Yellow
            } else {
                Write-Host "[INFO] Definindo '$nomeNovaInstanciaPadrao' como instancia padrao..." -ForegroundColor Yellow
                
                try {
                    wsl --set-default $nomeNovaInstanciaPadrao
                    Write-Host "[OK] Instancia padrao alterada para '$nomeNovaInstanciaPadrao' com sucesso!" -ForegroundColor Green
                    Write-Host "[INFO] Agora o comando 'wsl' sem parametros abrira '$nomeNovaInstanciaPadrao'." -ForegroundColor Cyan
                } catch {
                    Write-Host "[ERRO] Falha ao definir instancia padrao: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "[ERRO] Nome da instancia invalido ou nao encontrado." -ForegroundColor Red
        }
        
    } catch {
        Write-Host "[ERRO] Falha na operacao: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    PausarExecucao
}

# Funcao para criar snapshot de uma instancia (com selecao numerada)
function Criar-Snapshot {
    ExibirTituloASCII
    Write-Host "Criar Snapshot (Backup) de Instancia WSL"
    Write-Host "----------------------------------------"

    $listaNomesInstancias = ListarInstanciasLocais

    if ($listaNomesInstancias.Count -eq 0) {
        Write-Host "[INFO] Nenhuma instancia WSL encontrada para criar snapshot." -ForegroundColor Yellow
        PausarExecucao
        return
    }

    Write-Host "`nInstancias disponiveis:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $listaNomesInstancias.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i + 1), $listaNomesInstancias[$i])
    }

    $escolha = ObterEntradaUsuario "`nDigite o NUMERO da instancia para criar o snapshot"
    $nomeInstancia = ""

    if ($escolha -match '^\d+$' -and [int]$escolha -ge 1 -and [int]$escolha -le $listaNomesInstancias.Count) {
        $nomeInstancia = $listaNomesInstancias[[int]$escolha - 1]
    } else {
        Write-Host "[ERRO] Selecao invalida." -ForegroundColor Red
        PausarExecucao
        return
    }

    Write-Host "[INFO] Instancia selecionada: '$nomeInstancia'" -ForegroundColor Green

    # O resto da funcao continua igual...
    $dataHora = Get-Date -Format "yyyyMMdd_HHmmss"
    $nomeSnapshotSugerido = "${nomeInstancia}_snapshot_${dataHora}"
    
    Write-Host "`nNome sugerido para o arquivo de snapshot: " -NoNewline -ForegroundColor White
    Write-Host "$nomeSnapshotSugerido.tar" -ForegroundColor Yellow
    
    $nomeSnapshot = ObterEntradaUsuario "Digite o nome do snapshot (Enter para usar o sugerido)"
    
    if ([string]::IsNullOrWhiteSpace($nomeSnapshot)) {
        $nomeSnapshot = $nomeSnapshotSugerido
    }
    
    $pastaSnapshots = "C:\distro\clone" # Pasta padrao para snapshots
    $caminhoCompleto = Join-Path $pastaSnapshots "$nomeSnapshot.tar"
    
    try {
        $pastaDestino = Split-Path -Path $caminhoCompleto -Parent
        if (-not (Test-Path -Path $pastaDestino -PathType Container)) {
            Write-Host "[INFO] Criando pasta '$pastaDestino'..." -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null
        }
        
        Write-Host "`n[INFO] Criando snapshot da instancia '$nomeInstancia'..." -ForegroundColor Cyan
        Write-Host "[INFO] Aguarde, este processo pode demorar..." -ForegroundColor Yellow
        
        wsl --export $nomeInstancia $caminhoCompleto
        
        Write-Host "`n[OK] Snapshot criado com sucesso!" -ForegroundColor Green
        Write-Host "[INFO] Localizacao: $caminhoCompleto" -ForegroundColor Gray
        
    } catch {
        Write-Host "`n[ERRO] Falha ao criar snapshot: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    PausarExecucao
}

# Funcao para centralizar o gerenciamento de instancias
function Gerenciar-Instancias {
    while ($true) {
        ExibirTituloASCII
        Write-Host "Controlar e Configurar Instancias WSL"
        Write-Host "-------------------------------------"
        
        # Exibe um status rapido
        Write-Host "`n[INFO] Status atual das instancias:" -ForegroundColor Cyan
        wsl --list --verbose
        Write-Host "-------------------------------------"

        Write-Host "1. Iniciar/Parar/Reiniciar instancia"
        Write-Host "2. Configurar performance (CPU, Memoria, etc.)"
        Write-Host "3. Remover instancias (selecao por numero)"
        Write-Host "4. Voltar ao Menu Principal"
        
        $opcao = ObterEntradaUsuario "`nEscolha uma opcao"
        
        switch ($opcao) {
            "1" { Controlar-Instancias } # Reutiliza a funcao que ja era boa
            "2" { Configurar-PerformanceWSL } # Nova funcao
            "3" { Remover-InstanciaNumerada } # Nova funcao
            "4" { return }
            default { Write-Host "[ERRO] Opcao invalida." -ForegroundColor Red; PausarExecucao }
        }
    }
}

# Funcao para configurar performance do WSL via .wslconfig (VERSAO CORRIGIDA)
function Configurar-PerformanceWSL {
    ExibirTituloASCII
    Write-Host "Configurar Performance do WSL (.wslconfig)"
    Write-Host "------------------------------------------"
    
    $caminhoConfig = "$env:USERPROFILE\.wslconfig"
    Write-Host "[INFO] O arquivo de configuracao esta em: $caminhoConfig" -ForegroundColor Gray
    
    # Carrega configuracoes existentes se o arquivo existir
    $config = @{}
    if (Test-Path $caminhoConfig) {
        $conteudoArquivo = Get-Content $caminhoConfig
        $secaoAtual = ""
        foreach ($linha in $conteudoArquivo) {
            if ($linha -match '\[(.*)\]') {
                $secaoAtual = $matches[1].Trim()
            } elseif ($linha -match '(.*)=(.*)') {
                $chave = $matches[1].Trim()
                $valor = $matches[2].Trim()
                if ($secaoAtual -eq "wsl2") {
                    $config[$chave] = $valor
                }
            }
        }
    }
    
    Write-Host "\nConfiguracoes atuais ([wsl2]):" -ForegroundColor Cyan
    
    # --- INICIO DA CORRECAO ---
    # Verifica se o valor existe antes de exibir, caso contrario, mostra o texto padrao.
    $textoPadrao = 'Nao definido (padrao do sistema)'
    $processadoresExibicao = if ([string]::IsNullOrWhiteSpace($config.processors)) { $textoPadrao } else { $config.processors }
    $memoriaExibicao = if ([string]::IsNullOrWhiteSpace($config.memory)) { $textoPadrao } else { $config.memory }
    $swapExibicao = if ([string]::IsNullOrWhiteSpace($config.swap)) { $textoPadrao } else { $config.swap }

    Write-Host "  Processadores: $processadoresExibicao"
    Write-Host "  Memoria: $memoriaExibicao"
    Write-Host "  Swap: $swapExibicao"
    # --- FIM DA CORRECAO ---

    Write-Host "\nDigite os novos valores ou pressione Enter para manter o atual/padrao."
    
    $novoProcessors = ObterEntradaUsuario "Novo numero de processadores (ex: 4)"
    $novaMemory = ObterEntradaUsuario "Nova memoria (ex: 8GB)"
    $novoSwap = ObterEntradaUsuario "Novo tamanho de swap (ex: 2GB)"
    
    if (-not [string]::IsNullOrWhiteSpace($novoProcessors)) { $config.processors = $novoProcessors }
    if (-not [string]::IsNullOrWhiteSpace($novaMemory)) { $config.memory = $novaMemory }
    if (-not [string]::IsNullOrWhiteSpace($novoSwap)) { $config.swap = $novoSwap }
    
    # Monta o novo arquivo .wslconfig
    $novoConteudo = @("[wsl2]")
    $config.GetEnumerator() | ForEach-Object { $novoConteudo += "$($_.Name) = $($_.Value)" }
    
    try {
        Set-Content -Path $caminhoConfig -Value $novoConteudo -Encoding utf8
        Write-Host "\n[OK] Arquivo .wslconfig salvo com sucesso!" -ForegroundColor Green
        Write-Host "[IMPORTANTE] E necessario reiniciar o WSL para que as alteracoes tenham efeito." -ForegroundColor Yellow
        Write-Host "  Use a opcao 'Parar todas as instancias' no menu anterior ou execute 'wsl --shutdown'." -ForegroundColor Yellow
    } catch {
        Write-Host "\n[ERRO] Falha ao salvar o arquivo .wslconfig: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    PausarExecucao
}

# Funcao para remover distros instaladas com selecao por numero
function Remover-InstanciaNumerada {
    ExibirTituloASCII
    Write-Host "Remover Instancias WSL Instaladas"
    Write-Host "---------------------------------"

    $listaNomesInstancias = ListarInstanciasLocais
    
    if ($listaNomesInstancias.Count -eq 0) {
        Write-Host "[INFO] Nenhuma instancia WSL encontrada para remover." -ForegroundColor Yellow
        PausarExecucao
        return
    }

    Write-Host "`nInstancias instaladas:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $listaNomesInstancias.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i + 1), $listaNomesInstancias[$i])
    }
    Write-Host ("{0}. Remover TODAS as instancias" -f ($listaNomesInstancias.Count + 1)) -ForegroundColor Red

    $entrada = ObterEntradaUsuario "`nDigite os NUMEROS das instancias que deseja remover (separados por virgula) ou a opcao para remover todas"

    if ([string]::IsNullOrWhiteSpace($entrada)) {
        Write-Host "[INFO] Nenhuma selecao. Operacao cancelada." -ForegroundColor Yellow
        PausarExecucao
        return
    }
    
    # Opcao de remover todas
    if ($entrada -eq ($listaNomesInstancias.Count + 1)) {
        $confirma = ObterEntradaUsuario "CONFIRMA a remocao de TODAS as instancias? Esta acao e IRREVERSIVEL. (s/n)"
        if ($confirma.ToLower() -in @('s', 'sim')) {
            Write-Host "[INFO] Removendo todas as instancias..." -ForegroundColor Yellow
            foreach ($distro in $listaNomesInstancias) {
                try {
                    wsl --unregister $distro
                    Write-Host "[OK] Distro '$distro' removida." -ForegroundColor Green
                } catch {
                    Write-Host "[ERRO] Falha ao remover '$distro'." -ForegroundColor Red
                }
            }
        } else {
            Write-Host "[INFO] Operacao cancelada pelo usuario." -ForegroundColor Yellow
        }
        PausarExecucao
        return
    }

    # Remocao por numero
    $indices = $entrada -split ',' | ForEach-Object { $_.Trim() }
    
    foreach ($idxStr in $indices) {
        if ($idxStr -match '^\d+$' -and [int]$idxStr -ge 1 -and [int]$idxStr -le $listaNomesInstancias.Count) {
            $distroParaRemover = $listaNomesInstancias[[int]$idxStr - 1]
            
            $confirma = ObterEntradaUsuario "Confirma a remocao da distro '$distroParaRemover'? (s/n)"
            if ($confirma.ToLower() -in @('s', 'sim')) {
                try {
                    Write-Host "[INFO] Removendo distro '$distroParaRemover'..." -ForegroundColor Yellow
                    wsl --unregister $distroParaRemover
                    Write-Host "[OK] Distro '$distroParaRemover' removida com sucesso." -ForegroundColor Green
                } catch {
                    Write-Host "[ERRO] Falha ao remover '$distroParaRemover': $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "[INFO] Remocao da distro '$distroParaRemover' cancelada." -ForegroundColor Yellow
            }
        } else {
            Write-Host "[AVISO] Numero '$idxStr' invalido ou fora do intervalo." -ForegroundColor Yellow
        }
    }
    PausarExecucao
}

# Funcao para restaurar snapshot
function Restaurar-Snapshot {
    ExibirTituloASCII
    Write-Host "Restaurar Snapshot de Instancia WSL"
    Write-Host "-----------------------------------"
    
    # Listar snapshots na pasta padrao
    $pastaSnapshots = "C:\WSL\Snapshots"
    $snapshotsEncontrados = @()
    
    if (Test-Path $pastaSnapshots) {
        $snapshotsEncontrados = Get-ChildItem -Path $pastaSnapshots -Filter "*.tar" | Sort-Object LastWriteTime -Descending
    }
    
    if ($snapshotsEncontrados.Count -gt 0) {
        Write-Host "`nSnapshots encontrados na pasta padrao:"
        for ($i = 0; $i -lt $snapshotsEncontrados.Count; $i++) {
            $arquivo = $snapshotsEncontrados[$i]
            $tamanhoMB = [math]::Round($arquivo.Length / 1MB, 2)
            $dataModificacao = $arquivo.LastWriteTime.ToString("dd/MM/yyyy HH:mm")
            Write-Host ("{0}. {1} ({2} MB - {3})" -f ($i + 1), $arquivo.Name, $tamanhoMB, $dataModificacao) -ForegroundColor Cyan
        }
        Write-Host ("{0}. Especificar caminho personalizado" -f ($snapshotsEncontrados.Count + 1)) -ForegroundColor Yellow
    } else {
        Write-Host "[INFO] Nenhum snapshot encontrado na pasta padrao ($pastaSnapshots)." -ForegroundColor Yellow
        Write-Host "Voce pode especificar o caminho de um arquivo .tar de snapshot." -ForegroundColor Gray
    }
    
    $opcao = ObterEntradaUsuario "`nEscolha uma opcao ou digite o caminho completo do snapshot"
    $caminhoSnapshot = ""
    
    # Verificar se e um numero (opcao do menu)
    if ($opcao -match '^\d+$' -and $snapshotsEncontrados.Count -gt 0) {
        $indice = [int]$opcao - 1
        if ($indice -ge 0 -and $indice -lt $snapshotsEncontrados.Count) {
            $caminhoSnapshot = $snapshotsEncontrados[$indice].FullName
        } elseif ($indice -eq $snapshotsEncontrados.Count) {
            $caminhoSnapshot = ObterEntradaUsuario "Digite o caminho completo do arquivo de snapshot"
        } else {
            Write-Host "[ERRO] Opcao invalida." -ForegroundColor Red
            PausarExecucao
            return
        }
    } else {
        # Assumir que e um caminho
        $caminhoSnapshot = $opcao
    }
    
    if ([string]::IsNullOrWhiteSpace($caminhoSnapshot) -or -not (Test-Path $caminhoSnapshot -PathType Leaf)) {
        Write-Host "[ERRO] Arquivo de snapshot invalido ou nao encontrado." -ForegroundColor Red
        PausarExecucao
        return
    }
    
    $nomeNovaInstancia = ObterEntradaUsuario "Digite o nome para a instancia restaurada"
    
    if ([string]::IsNullOrWhiteSpace($nomeNovaInstancia)) {
        Write-Host "[ERRO] Nome da instancia nao pode ser vazio." -ForegroundColor Red
        PausarExecucao
        return
    }
    
    # Verificar se ja existe instancia com esse nome
    $listaNomesInstanciasExistentes = ListarInstanciasLocais
    if ($listaNomesInstanciasExistentes -contains $nomeNovaInstancia) {
        $substituir = ObterEntradaUsuario "Ja existe uma instancia com o nome '$nomeNovaInstancia'. Substituir? (s/n)"
        if ($substituir.ToLower() -ne 's' -and $substituir.ToLower() -ne 'sim') {
            Write-Host "[INFO] Operacao cancelada." -ForegroundColor Yellow
            PausarExecucao
            return
        } else {
            Write-Host "[INFO] Removendo instancia existente '$nomeNovaInstancia'..." -ForegroundColor Yellow
            try {
                wsl --unregister $nomeNovaInstancia
            } catch {
                Write-Host "[ERRO] Falha ao remover instancia existente: $($_.Exception.Message)" -ForegroundColor Red
                PausarExecucao
                return
            }
        }
    }
    
    $pastaInstalacao = ObterEntradaUsuario "Digite o caminho onde a instancia sera instalada (ex: C:\WSL\Restored\$nomeNovaInstancia)"
    
    if ([string]::IsNullOrWhiteSpace($pastaInstalacao)) {
        Write-Host "[ERRO] Caminho de instalacao nao pode ser vazio." -ForegroundColor Red
        PausarExecucao
        return
    }
    
    try {
        # Criar pasta se nao existir
        if (-not (Test-Path -Path $pastaInstalacao -PathType Container)) {
            Write-Host "[INFO] Criando pasta '$pastaInstalacao'..." -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $pastaInstalacao -Force | Out-Null
        }
        
        Write-Host "`n[INFO] Restaurando snapshot para instancia '$nomeNovaInstancia'..." -ForegroundColor Cyan
        Write-Host "[INFO] Origem: $caminhoSnapshot" -ForegroundColor Gray
        Write-Host "[INFO] Destino: $pastaInstalacao" -ForegroundColor Gray
        Write-Host "[INFO] Aguarde..." -ForegroundColor Yellow
        
        $inicio = Get-Date
        wsl --import $nomeNovaInstancia $pastaInstalacao $caminhoSnapshot
        $fim = Get-Date
        $duracao = $fim - $inicio
        
        Write-Host "`n[OK] Snapshot restaurado com sucesso!" -ForegroundColor Green
        Write-Host "[INFO] Instancia: $nomeNovaInstancia" -ForegroundColor Gray
        Write-Host "[INFO] Localizacao: $pastaInstalacao" -ForegroundColor Gray
        Write-Host "[INFO] Tempo decorrido: $($duracao.ToString('mm\:ss'))" -ForegroundColor Gray
        Write-Host "`n[DICA] Use 'wsl -d $nomeNovaInstancia' para acessar a instancia restaurada." -ForegroundColor Cyan
        
    } catch {
        Write-Host "`n[ERRO] Falha ao restaurar snapshot: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    PausarExecucao
}

# --- Menu Principal ---
$manterMenuAtivo = $true
while ($manterMenuAtivo) {
    ExibirTituloASCII
    Write-Host "Menu Principal - Gerenciador WSL"
    Write-Host "--------------------------------"
    Write-Host "1. Ver distribuicoes disponiveis online"
    Write-Host "2. Instalar nova distribuicao (encerra o script apos iniciar)"
    Write-Host "3. Criar pasta para distros (C:\distro)"
    Write-Host "4. Restaurar instancia a partir de um snapshot (.tar)"
    Write-Host "5. Criar snapshot (backup) de uma instancia"
    Write-Host "6. Definir instancia padrao"
    Write-Host "7. Controlar e configurar instancias (Iniciar, Parar, Remover, Performance)"
    Write-Host "8. Sair"
    Write-Host ""

    $opcaoSelecionada = ObterEntradaUsuario "Escolha uma opcao"

    switch ($opcaoSelecionada) {
        "1" { ListarDistribuicoesOnline }
        "2" {
            InstalarNovaDistribuicao
            $manterMenuAtivo = $false # Encerra o script para focar na instalacao
        }
        "3" { Criar-PastaDistros }
        "4" { Restaurar-Snapshot } # Funcao ja existente, otima para este fim
        "5" { Criar-Snapshot } # Funcao modificada para selecao numerada
        "6" { Definir-InstanciaPadrao } # Funcao ja existente
        "7" { Gerenciar-Instancias } # Nova funcao que centraliza o controle
        "8" {
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