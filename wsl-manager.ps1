# WSL Manager - Gerenciador de instancias WSL similar ao Docker
# Salve como wsl-manager.ps1 em D:\WSLDistros\


param (
    [Parameter(Mandatory=$true)][string]$action,
    [Parameter(Mandatory=$false)][string]$name,
    [Parameter(Mandatory=$false)][string]$base = "UbuntuMinimal2204", # Nome da sua distro base importada
    [Parameter(Mandatory=$false)][string]$envType = "base",
    [Parameter(Mandatory=$false)][string]$command,
    [Parameter(Mandatory=$false)][string]$backupPath # Caminho para backup/restore
)

$basePath = "D:\WSLDistros" # Caminho onde as instancias e scripts estao
$provisionScriptLocalPath = Join-Path $basePath "provision-web-env.sh"
$provisionScriptTargetPathInWSL = "/tmp/provision-web-env.sh" # Caminho do script dentro da instancia WSL
$defaultBackupPath = Join-Path $basePath "Backups" # Diretorio padrao para backups

# Verificar se o diretorio base existe
if (-not (Test-Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
    Write-Host "Diretorio base $basePath criado." -ForegroundColor Green
}

# Verificar se o diretorio de backups existe
if (-not (Test-Path $defaultBackupPath)) {
    New-Item -ItemType Directory -Path $defaultBackupPath | Out-Null
    Write-Host "Diretorio de backups $defaultBackupPath criado." -ForegroundColor Green
}

# Funcao para criar uma nova instancia
function New-WSLInstance {
    param(
        [string]$instanceName,
        [string]$baseDistroName,
        [string]$environmentType
    )

    $instanceStoragePath = Join-Path $basePath $instanceName
    $baseDistroExportTarPath = Join-Path $instanceStoragePath "base.tar"
    $instanceFsPath = Join-Path $instanceStoragePath "fs" # Diretorio para o VHDX

    if (Test-Path $instanceStoragePath) {
        Write-Host "ERRO: Diretorio da instancia '$instanceName' ja existe em '$instanceStoragePath'." -ForegroundColor Red
        return $false
    }

    # Verificar se a distro base existe
    $existingDistros = wsl --list --quiet
    if (-not ($existingDistros -contains $baseDistroName)) {
        Write-Host "ERRO: Distribuicao base '$baseDistroName' nao encontrada. Verifique com 'wsl -l'." -ForegroundColor Red
        return $false
    }

    # Criar diretorio para a instancia
    New-Item -ItemType Directory -Path $instanceStoragePath | Out-Null
    Write-Host "Diretorio da instancia criado em: $instanceStoragePath" -ForegroundColor Cyan

    Write-Host "Exportando distribuicao base '$baseDistroName'..." -ForegroundColor Yellow
    wsl --export $baseDistroName $baseDistroExportTarPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $baseDistroExportTarPath)) {
        Write-Host "ERRO: Falha ao exportar a distribuicao base '$baseDistroName'." -ForegroundColor Red
        Remove-Item -Recurse -Force $instanceStoragePath -ErrorAction SilentlyContinue
        return $false
    }

    Write-Host "Importando nova instancia '$instanceName' para '$instanceFsPath'..." -ForegroundColor Yellow
    wsl --import $instanceName $instanceFsPath $baseDistroExportTarPath --version 2
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao importar a nova instancia '$instanceName'." -ForegroundColor Red
        Remove-Item -Recurse -Force $instanceStoragePath -ErrorAction SilentlyContinue
        return $false
    }

    # Limpar arquivo .tar temporario
    Remove-Item $baseDistroExportTarPath
    Write-Host "Instancia '$instanceName' criada com sucesso." -ForegroundColor Green
    return $true
}

# Funcao para provisionar uma instancia
function Invoke-WSLProvisioning {
    param(
        [string]$instanceName,
        [string]$environmentType
    )

    if (-not (Test-Path $provisionScriptLocalPath)) {
        Write-Host "ERRO: Script de provisionamento '$provisionScriptLocalPath' nao encontrado." -ForegroundColor Red
        return $false
    }

    Write-Host "Copiando script de provisionamento para a instancia '$instanceName'..." -ForegroundColor Yellow
    # Garantir que /tmp exista (geralmente existe)
    wsl -d $instanceName -u root -e bash -c "mkdir -p /tmp"
    Get-Content $provisionScriptLocalPath | wsl -d $instanceName -u root -e bash -c "cat > $provisionScriptTargetPathInWSL"
    wsl -d $instanceName -u root -e bash -c "chmod +x $provisionScriptTargetPathInWSL"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao copiar ou dar permissao de execucao ao script de provisionamento na instancia '$instanceName'." -ForegroundColor Red
        return $false
    }

    Write-Host "Executando provisionamento para ambiente '$environmentType' na instancia '$instanceName' (como root)..." -ForegroundColor Yellow
    Write-Host "Isso pode levar alguns minutos..."
    # Executa o script. O output do script sera mostrado.
    wsl -d $instanceName -u root -e bash -c "DEBIAN_FRONTEND=noninteractive $provisionScriptTargetPathInWSL $environmentType"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "AVISO: O script de provisionamento pode ter encontrado erros. Verifique o output acima." -ForegroundColor Yellow
    }

    Write-Host "Provisionamento para '$instanceName' (tipo: $environmentType) concluido!" -ForegroundColor Green
    return $true
}

# Funcao para listar todas as instancias
function Get-WSLInstances {
    Write-Host "`nInstancias WSL registradas:" -ForegroundColor Cyan
    wsl --list --verbose

    Write-Host "`nDiretorios de instancias gerenciadas em '$basePath':" -ForegroundColor Cyan
    Get-ChildItem $basePath -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName "fs")) { # Verifica se e uma pasta de instancia importada
            $instanceDirSize = Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
            $sizeInMB = if ($instanceDirSize.Sum) { "{0:N2} MB" -f ($instanceDirSize.Sum / 1MB) } else { "0 MB" }
            Write-Host "$($_.Name) - Tamanho no disco: $sizeInMB"
        }
    }
}

# Funcao para remover uma instancia
function Remove-WSLInstance {
    param([string]$instanceName)

    $instanceStoragePath = Join-Path $basePath $instanceName
    $registeredInstances = wsl --list --quiet

    if (-not ($registeredInstances -contains $instanceName)) {
        Write-Host "AVISO: Instancia '$instanceName' nao esta registrada no WSL." -ForegroundColor Yellow
        # Prossegue para tentar remover a pasta se existir
    } else {
        Write-Host "Terminando a instancia '$instanceName' (se estiver em execucao)..." -ForegroundColor Yellow
        wsl --terminate $instanceName

        Write-Host "Desregistrando a instancia '$instanceName'..." -ForegroundColor Yellow
        wsl --unregister $instanceName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERRO: Falha ao desregistrar a instancia '$instanceName'." -ForegroundColor Red
            # Nao retorna, pois ainda pode querer remover a pasta
        }
    }

    if (-not (Test-Path $instanceStoragePath)) {
        Write-Host "ERRO: Diretorio da instancia '$instanceName' nao encontrado em '$instanceStoragePath'." -ForegroundColor Red
        if (-not ($registeredInstances -contains $instanceName)) {
             Write-Host "Nenhuma acao realizada."
        }
        return
    }

    Write-Host "Removendo arquivos da instancia '$instanceName' de '$instanceStoragePath'..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $instanceStoragePath
    Write-Host "Instancia '$instanceName' e seus arquivos removidos com sucesso!" -ForegroundColor Green
}

# Funcao para iniciar uma instancia (abrir terminal)
function Start-WSLInstance {
    param([string]$instanceName)

    $registeredInstances = wsl --list --quiet
    if (-not ($registeredInstances -contains $instanceName)) {
        Write-Host "ERRO: Instancia '$instanceName' nao encontrada ou nao registrada." -ForegroundColor Red
        return
    }

    Write-Host "Iniciando terminal na instancia '$instanceName'..." -ForegroundColor Yellow
    # Abre um novo terminal do Windows com a instancia WSL
     # Alternativa para iniciar na janela atual ou em um novo console legado:
    Write-Host "Tentando iniciar com 'wsl -d $instanceName'. Se isso nao abrir um novo terminal,"
    Write-Host "voce pode executar 'wsl -d $instanceName' manualmente em um novo PowerShell."
    wsl -d $instanceName
}

# Funcao para executar um comando em uma instancia
function Invoke-WSLCommand {
    param(
        [string]$instanceName,
        [string]$commandToExecute
    )

    $registeredInstances = wsl --list --quiet
    if (-not ($registeredInstances -contains $instanceName)) {
        Write-Host "ERRO: Instancia '$instanceName' nao encontrada ou nao registrada." -ForegroundColor Red
        return
    }
    if ([string]::IsNullOrWhiteSpace($commandToExecute)) {
        Write-Host "ERRO: Nenhum comando especificado para executar." -ForegroundColor Red
        return
    }

    Write-Host "Executando comando na instancia '$instanceName' (como root):" -ForegroundColor Yellow
    Write-Host "Comando: $commandToExecute"
    wsl -d $instanceName -u root -e bash -c "$commandToExecute"
}

# Funcao para fazer backup de uma instancia
function Backup-WSLInstance {
    param(
        [string]$instanceName,
        [string]$backupDestination
    )

    $registeredInstances = wsl --list --quiet
    if (-not ($registeredInstances -contains $instanceName)) {
        Write-Host "ERRO: Instancia '$instanceName' nao encontrada ou nao registrada." -ForegroundColor Red
        return $false
    }

    # Se nao for especificado um caminho, usar o diretorio padrao
    if ([string]::IsNullOrWhiteSpace($backupDestination)) {
        $backupDestination = $defaultBackupPath
    }

    # Verificar se o diretorio de destino existe
    if (-not (Test-Path $backupDestination)) {
        try {
            New-Item -ItemType Directory -Path $backupDestination -Force | Out-Null
            Write-Host "Diretorio de backup criado: $backupDestination" -ForegroundColor Green
        } catch {
            Write-Host "ERRO: Nao foi possivel criar o diretorio de backup '$backupDestination'." -ForegroundColor Red
            return $false
        }
    }

    # Criar nome do arquivo de backup com timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFileName = "$instanceName-backup-$timestamp.tar"
    $backupFilePath = Join-Path $backupDestination $backupFileName

    # Terminar a instancia se estiver em execucao
    Write-Host "Terminando a instancia '$instanceName' (se estiver em execucao)..." -ForegroundColor Yellow
    wsl --terminate $instanceName

    # Exportar a instancia
    Write-Host "Exportando instancia '$instanceName' para '$backupFilePath'..." -ForegroundColor Yellow
    wsl --export $instanceName $backupFilePath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $backupFilePath)) {
        Write-Host "ERRO: Falha ao exportar a instancia '$instanceName'." -ForegroundColor Red
        return $false
    }

    # Calcular tamanho do backup
    $backupSize = (Get-Item $backupFilePath).Length / 1MB
    Write-Host "Backup da instancia '$instanceName' concluido com sucesso!" -ForegroundColor Green
    Write-Host "Arquivo: $backupFilePath" -ForegroundColor Cyan
    Write-Host "Tamanho: $([Math]::Round($backupSize, 2)) MB" -ForegroundColor Cyan
    return $true
}

# Funcao para restaurar uma instancia a partir de um backup
function Restore-WSLInstance {
    param(
        [string]$instanceName,
        [string]$backupSource
    )

    # Verificar se ja existe uma instancia com esse nome
    $registeredInstances = wsl --list --quiet
    if ($registeredInstances -contains $instanceName) {
        Write-Host "AVISO: Ja existe uma instancia com o nome '$instanceName'." -ForegroundColor Yellow
        $confirmation = Read-Host "Deseja remover a instancia existente e continuar? (S/N)"
        if ($confirmation -ne "S" -and $confirmation -ne "s") {
            Write-Host "Operacao de restauracao cancelada." -ForegroundColor Yellow
            return $false
        }
        
        # Remover a instancia existente
        Remove-WSLInstance -instanceName $instanceName
    }

    # Se nao for especificado um arquivo de backup, listar os backups disponiveis
    if ([string]::IsNullOrWhiteSpace($backupSource)) {
        Write-Host "Selecione o arquivo de backup para restaurar:" -ForegroundColor Cyan
        
        # Verificar se o diretorio de backups existe
        if (-not (Test-Path $defaultBackupPath)) {
            Write-Host "ERRO: Diretorio de backups nao encontrado em '$defaultBackupPath'." -ForegroundColor Red
            return $false
        }
        
        # Listar arquivos de backup
        $backupFiles = Get-ChildItem -Path $defaultBackupPath -Filter "*.tar" | Sort-Object LastWriteTime -Descending
        if ($backupFiles.Count -eq 0) {
            Write-Host "ERRO: Nenhum arquivo de backup encontrado em '$defaultBackupPath'." -ForegroundColor Red
            return $false
        }
        
        # Mostrar lista de backups
        for ($i = 0; $i -lt $backupFiles.Count; $i++) {
            $backupSize = [Math]::Round($backupFiles[$i].Length / 1MB, 2)
            $backupDate = $backupFiles[$i].LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Host "[$i] $($backupFiles[$i].Name) - $backupSize MB - $backupDate" -ForegroundColor White
        }
        
        # Solicitar selecao do usuario
        $selection = Read-Host "Digite o numero do backup a ser restaurado"
        if (-not [int]::TryParse($selection, [ref]$null) -or [int]$selection -lt 0 -or [int]$selection -ge $backupFiles.Count) {
            Write-Host "ERRO: Selecao invalida." -ForegroundColor Red
            return $false
        }
        
        $backupSource = $backupFiles[[int]$selection].FullName
    } elseif (-not (Test-Path $backupSource)) {
        # Verificar se o arquivo especificado existe
        Write-Host "ERRO: Arquivo de backup '$backupSource' nao encontrado." -ForegroundColor Red
        return $false
    }

    # Criar diretorio para a instancia
    $instanceStoragePath = Join-Path $basePath $instanceName
    if (-not (Test-Path $instanceStoragePath)) {
        New-Item -ItemType Directory -Path $instanceStoragePath | Out-Null
    }
    
    $instanceFsPath = Join-Path $instanceStoragePath "fs"
    if (-not (Test-Path $instanceFsPath)) {
        New-Item -ItemType Directory -Path $instanceFsPath | Out-Null
    }

    # Importar a instancia
    Write-Host "Importando instancia '$instanceName' a partir de '$backupSource'..." -ForegroundColor Yellow
    wsl --import $instanceName $instanceFsPath $backupSource --version 2
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao importar a instancia '$instanceName'." -ForegroundColor Red
        Remove-Item -Recurse -Force $instanceStoragePath -ErrorAction SilentlyContinue
        return $false
    }

    Write-Host "Instancia '$instanceName' restaurada com sucesso!" -ForegroundColor Green
    return $true
}

# Funcao para monitorar recursos das instancias WSL
function Get-WSLResourceUsage {
    param(
        [switch]$Verbose,
        [switch]$Debug
    )
    
    Write-Host "Detectando instancias WSL..." -ForegroundColor Cyan
    
    # Habilitar debug se solicitado
    if ($Debug) {
        Write-Host "`n=== MODO DEBUG ATIVADO ===" -ForegroundColor Magenta
        Write-Host "Comando: wsl -l -v" -ForegroundColor Gray
        $debugOutput = wsl -l -v 2>$null
        $debugOutput | ForEach-Object { 
            Write-Host "  Linha bruta: '$_'" -ForegroundColor White
            $cleaned = $_.ToString().Trim() -replace '[\x00-\x1F\x7F]', ''
            Write-Host "  Linha limpa: '$cleaned'" -ForegroundColor White
            Write-Host "  Contem 'Running': $($cleaned.Contains('Running'))" -ForegroundColor White
        }
        Write-Host "=== FIM DEBUG ===`n" -ForegroundColor Magenta
    }
    
    # Definir codificação UTF-8 para a saída
    $originalEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    
    try {
        # Passo 1: Executar wsl -l -v
        Write-Host "`nPasso 1: Executando 'wsl -l -v'..." -ForegroundColor Yellow
        $allInstances = wsl -l -v 2>$null
        if (-not $allInstances) {
            Write-Host "Nenhuma instancia WSL encontrada no sistema." -ForegroundColor Yellow
            return
        }
        
        # Passo 2: Exibir todas as instâncias
        Write-Host "`nPasso 2: Todas as instancias WSL registradas:" -ForegroundColor Cyan
        $allInstances | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        
        # Passo 3: Procurar instâncias em execução
        Write-Host "`nPasso 3: Procurando instancias em execucao..." -ForegroundColor Yellow
        $runningInstances = @()
        
        foreach ($line in $allInstances) {
            # Limpar a linha removendo caracteres de controle e espaços extras
            $cleanLine = $line.ToString().Trim() -replace '[\x00-\x1F\x7F]', ''
            Write-Host "`nProcessando linha: '$cleanLine'" -ForegroundColor Gray
            Write-Host "  Contem 'Running': $($cleanLine.Contains('Running'))" -ForegroundColor Gray
            Write-Host "  Contem 'Executando': $($cleanLine.Contains('Executando'))" -ForegroundColor Gray
            
            # Ignorar linhas vazias e cabeçalhos
            if ([string]::IsNullOrWhiteSpace($cleanLine) -or
                $cleanLine -match "^\s*NAME\s+" -or
                $cleanLine -match "Distribui" -or
                $cleanLine -match "Windows Subsystem" -or
                $cleanLine -match "^-+$") {
                Write-Host "  Ignorando (cabecalho/vazia)" -ForegroundColor Gray
                continue
            }
            
            # Verificar se a linha contém "Running" ou "Executando"
            if ($cleanLine.Contains("Running") -or $cleanLine.Contains("Executando")) {
                Write-Host "  Estado detectado: 'Running' ou 'Executando'" -ForegroundColor Green
                # Extrair o nome da instância
                $instanceName = $cleanLine -replace '^\*\s*', '' -replace '\s+(Running|Executando)\s+.*$', ''
                $instanceName = $instanceName.Trim()
                
                if (-not [string]::IsNullOrWhiteSpace($instanceName)) {
                    Write-Host "  Instancia em execucao encontrada: '$instanceName'" -ForegroundColor Green
                    $runningInstances += $instanceName
                } else {
                    Write-Host "  AVISO: Nome da instancia vazio ou invalido" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  Nao esta em execucao (nenhum estado 'Running' ou 'Executando' encontrado)" -ForegroundColor Gray
            }
        }
        
        # Passo 4: Exibir instâncias em execução
        Write-Host "`nPasso 4: Instancias WSL em execucao encontradas:" -ForegroundColor Yellow
        if ($runningInstances.Count -eq 0) {
            Write-Host "  Nenhuma instancia WSL em execucao no momento." -ForegroundColor Yellow
            Write-Host "  Para iniciar uma instancia, use: wsl -d <nome-da-instancia>" -ForegroundColor Gray
            return
        }
        
        $runningInstances = $runningInstances | Select-Object -Unique
        $runningInstances | ForEach-Object { Write-Host "  * $_" -ForegroundColor White }
        
        # Passo 5: Monitorar cada instância
        foreach ($instance in $runningInstances) {
            Write-Host "`nPasso 5: Monitorando recursos da instancia '$instance'..." -ForegroundColor Yellow
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host "MONITORAMENTO DE RECURSOS: $instance" -ForegroundColor Green
            Write-Host "============================================================" -ForegroundColor Cyan
            
            # Verificar se a instância ainda está em execução
            Write-Host "  Verificando conexao..." -ForegroundColor Gray
            $testConnection = wsl -d "$instance" -e echo "alive" 2>$null
            if ($LASTEXITCODE -ne 0 -or $testConnection -ne "alive") {
                Write-Host "  ERRO: Nao foi possivel conectar a instancia '$instance'" -ForegroundColor Red
                Write-Host "  A instancia pode ter parado durante a execucao." -ForegroundColor Yellow
                continue
            }
            Write-Host "  Conexao confirmada" -ForegroundColor Green
            
            try {
                # Informações do sistema
                Write-Host "`nINFORMACOES DO SISTEMA:" -ForegroundColor Cyan
                $systemInfo = wsl -d "$instance" -e bash -c "uname -a" 2>$null
                if ($systemInfo) {
                    Write-Host "  Sistema: $systemInfo" -ForegroundColor White
                }
                
                # Informações de CPU
                Write-Host "`nINFORMACOES DE CPU:" -ForegroundColor Cyan
                $cpuModel = wsl -d "$instance" -e bash -c "grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//'" 2>$null
                $cpuCores = wsl -d "$instance" -e bash -c "nproc" 2>$null
                
                if ($cpuModel) {
                    Write-Host "  Modelo: $cpuModel" -ForegroundColor White
                }
                if ($cpuCores) {
                    Write-Host "  Cores disponiveis: $cpuCores" -ForegroundColor White
                }
                
                # Carga do sistema
                $loadAvg = wsl -d "$instance" -e bash -c "cat /proc/loadavg" 2>$null
                if ($loadAvg) {
                    Write-Host "  Carga media (1m 5m 15m): $loadAvg" -ForegroundColor White
                }
                
                # Uso de memória
                Write-Host "`nUSO DE MEMORIA:" -ForegroundColor Cyan
                $memInfo = wsl -d "$instance" -e bash -c "free -h" 2>$null
                if ($memInfo) {
                    $memInfo | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
                }
                
                # Uso de disco
                Write-Host "`nUSO DE DISCO:" -ForegroundColor Cyan
                $diskInfo = wsl -d "$instance" -e bash -c "df -h / | tail -1" 2>$null
                if ($diskInfo) {
                    Write-Host "  $diskInfo" -ForegroundColor White
                }
                
                # Processos principais por CPU
                Write-Host "`nPROCESSOS PRINCIPAIS (por uso de CPU):" -ForegroundColor Cyan
                $topProcesses = wsl -d "$instance" -e bash -c "ps aux --sort=-%cpu | head -6" 2>$null
                if ($topProcesses) {
                    $topProcesses | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
                }
                
                # Processos principais por memória
                Write-Host "`nPROCESSOS PRINCIPAIS (por uso de memoria):" -ForegroundColor Cyan
                $topMemProcesses = wsl -d "$instance" -e bash -c "ps aux --sort=-%mem | head -6" 2>$null
                if ($topMemProcesses) {
                    $topMemProcesses | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
                }
                
                # Verificar se htop está disponível
                Write-Host "`nFERRAMENTAS DE MONITORAMENTO:" -ForegroundColor Magenta
                $htopAvailable = wsl -d "$instance" -e bash -c "command -v htop >/dev/null 2>&1 && echo 'yes' || echo 'no'" 2>$null
                if ($htopAvailable -eq "yes") {
                    Write-Host "  * htop disponivel - Para monitoramento interativo: wsl -d $instance -e htop" -ForegroundColor Green
                } else {
                    Write-Host "  * htop nao instalado - Para instalar: wsl -d $instance -e sudo apt install htop" -ForegroundColor Yellow
                }
                
                Write-Host "  * Para top basico: wsl -d $instance -e top" -ForegroundColor Green
                Write-Host "  * Para iostat: wsl -d $instance -e iostat -x 1" -ForegroundColor Green
                
            } catch {
                Write-Host "  Erro ao obter informacoes da instancia '$instance': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "`n============================================================" -ForegroundColor Green
        Write-Host "MONITORAMENTO CONCLUIDO" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
        
    } finally {
        # Restaurar codificação original
        [Console]::OutputEncoding = $originalEncoding
    }
}

# Funcao para encerrar todas as instancias WSL em execucao
function Stop-AllWSLInstances {
    # Verificar se ha instancias em execucao
    $runningOutput = wsl --list --running
    
    # Verificar se a saida esta vazia ou contem apenas cabecalhos
    if (-not $runningOutput -or ($runningOutput -join " " -match "^NAME.*STATE.*VERSION" -and $runningOutput.Count -le 1)) {
        Write-Host "Nenhuma instancia WSL em execucao no momento." -ForegroundColor Yellow
        return
    }

    Write-Host "Instancias WSL em execucao antes do encerramento:" -ForegroundColor Cyan
    Write-Host $runningOutput

    # Confirmar com o usuario
    $confirmation = Read-Host "Deseja encerrar todas as instancias WSL em execucao? (S/N)"
    if ($confirmation -ne "S" -and $confirmation -ne "s") {
        Write-Host "Operacao de encerramento cancelada." -ForegroundColor Yellow
        return
    }

    # Metodo 1: Encerrar todas as instancias de uma vez
    Write-Host "Encerrando todas as instancias WSL..." -ForegroundColor Yellow
    wsl --shutdown
    
    # Verificar se todas foram encerradas
    Start-Sleep -Seconds 2
    $stillRunning = wsl --list --running
    
    # Se ainda houver instancias em execucao, tentar metodo alternativo
    if (-not [string]::IsNullOrWhiteSpace($stillRunning) -and $stillRunning -match "\w+") {
        Write-Host "Algumas instancias ainda estao em execucao. Tentando metodo alternativo..." -ForegroundColor Yellow
        
        # Extrair nomes das instancias em execucao, ignorando cabecalhos
        $instances = @()
        foreach ($line in $stillRunning) {
            if (-not [string]::IsNullOrWhiteSpace($line) -and 
                -not ($line -match "^NAME") -and 
                -not ($line -match "Distribui") -and
                -not ($line -match "Windows Subsystem for Linux")) {
                
                # Extrair o nome da instancia (primeiro token)
                $instanceName = $line.Trim() -split "\s+", 2 | Select-Object -First 1
                
                # Verificar se e um nome valido
                if (-not [string]::IsNullOrWhiteSpace($instanceName) -and 
                    -not ($instanceName -eq "NAME") -and 
                    -not ($instanceName -match "Distribui")) {
                    $instances += $instanceName
                }
            }
        }
        
        # Encerrar cada instancia individualmente
        foreach ($instance in $instances) {
            Write-Host "Encerrando instancia: $instance" -ForegroundColor Yellow
            wsl --terminate $instance
            Start-Sleep -Seconds 1
        }
    }
    
    # Verificacao final
    Start-Sleep -Seconds 2
    $finalCheck = wsl --list --running
    if ([string]::IsNullOrWhiteSpace($finalCheck) -or $finalCheck -notmatch "\w+") {
        Write-Host "Todas as instancias WSL foram encerradas com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "AVISO: Algumas instancias podem ainda estar em execucao:" -ForegroundColor Red
        Write-Host $finalCheck
    }
}

# Funcao para exibir ajuda
function Show-Help {
    Write-Host "WSL Manager - Gerenciador de instancias WSL similar ao Docker" -ForegroundColor Cyan
    Write-Host "Localizacao dos scripts e instancias: $basePath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Uso: .\wsl-manager.ps1 -action <acao> [parametros]" -ForegroundColor White
    Write-Host ""
    Write-Host "Acoes disponiveis:" -ForegroundColor Yellow
    Write-Host "  create    : Cria e provisiona uma nova instancia WSL." -ForegroundColor White
    Write-Host "    Parametros: -name <nome_instancia> [-base <distro_base_importada>] [-envType <tipo_ambiente>]" -ForegroundColor Gray
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action create -name projeto-php -base UbuntuMinimal2204 -envType php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  provision : Provisiona (ou reprovisiona) uma instancia existente." -ForegroundColor White
    Write-Host "    Parametros: -name <nome_instancia> [-envType <tipo_ambiente>]" -ForegroundColor Gray
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action provision -name projeto-node -envType node" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  start     : Inicia um terminal na instancia WSL especificada." -ForegroundColor White
    Write-Host "    Parametros: -name <nome_instancia>" -ForegroundColor Gray
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action start -name projeto-php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  list      : Lista todas as instancias WSL configuradas e seus diretorios." -ForegroundColor White
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action list" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  remove    : Remove uma instancia WSL (desregistra e apaga os arquivos)." -ForegroundColor White
    Write-Host "    Parametros: -name <nome_instancia>" -ForegroundColor Gray
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action remove -name projeto-php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  exec      : Executa um comando dentro de uma instancia WSL (como root)." -ForegroundColor White
    Write-Host "    Parametros: -name <nome_instancia> -command ""<comando_linux>""" -ForegroundColor Gray
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action exec -name projeto-php -command ""ls -la /app""" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  backup    : Cria um backup de uma instancia WSL." -ForegroundColor White
    Write-Host "    Parametros: -name <nome_instancia> [-backupPath <caminho_destino>]" -ForegroundColor Gray
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action backup -name projeto-php -backupPath D:\WSLBackups" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  restore   : Restaura uma instancia WSL a partir de um backup." -ForegroundColor White
    Write-Host "    Parametros: -name <nome_instancia> [-backupPath <caminho_arquivo_backup>]" -ForegroundColor Gray
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action restore -name projeto-php -backupPath D:\WSLBackups\projeto-php-backup.tar" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  monitor   : Mostra informacoes de uso de recursos das instancias WSL em execucao." -ForegroundColor White
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action monitor" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  stopall   : Encerra todas as instancias WSL em execucao." -ForegroundColor White
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action stopall" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  help      : Exibe esta ajuda." -ForegroundColor White
    Write-Host "    Exemplo   : .\wsl-manager.ps1 -action help" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Tipos de ambiente para -envType (definidos em provision-web-env.sh): base, php, node, python." -ForegroundColor Magenta
}

# Processar a acao solicitada
switch ($action.ToLower()) {
    "create" {
        if (-not $name) { Write-Host "ERRO: Nome da instancia (-name) nao especificado." -ForegroundColor Red; Show-Help; return }
        $success = New-WSLInstance -instanceName $name -baseDistroName $base -environmentType $envType
        if ($success) {
            Invoke-WSLProvisioning -instanceName $name -environmentType $envType
        }
    }
    "provision" {
        if (-not $name) { Write-Host "ERRO: Nome da instancia (-name) nao especificado." -ForegroundColor Red; Show-Help; return }
        Invoke-WSLProvisioning -instanceName $name -environmentType $envType
    }
    "start" {
        if (-not $name) { Write-Host "ERRO: Nome da instancia (-name) nao especificado." -ForegroundColor Red; Show-Help; return }
        Start-WSLInstance -instanceName $name
    }
    "list" {
        Get-WSLInstances
    }
    "remove" {
        if (-not $name) { Write-Host "ERRO: Nome da instancia (-name) nao especificado." -ForegroundColor Red; Show-Help; return }
        Remove-WSLInstance -instanceName $name
    }
    "exec" {
        if (-not $name) { Write-Host "ERRO: Nome da instancia (-name) nao especificado." -ForegroundColor Red; Show-Help; return }
        if (-not $command) { Write-Host "ERRO: Comando (-command) nao especificado." -ForegroundColor Red; Show-Help; return }
        Invoke-WSLCommand -instanceName $name -commandToExecute $command
    }
    "backup" {
        if (-not $name) { Write-Host "ERRO: Nome da instancia (-name) nao especificado." -ForegroundColor Red; Show-Help; return }
        Backup-WSLInstance -instanceName $name -backupDestination $backupPath
    }
    "restore" {
        if (-not $name) { Write-Host "ERRO: Nome da instancia (-name) nao especificado." -ForegroundColor Red; Show-Help; return }
        Restore-WSLInstance -instanceName $name -backupSource $backupPath
    }
    "monitor" {
        Get-WSLResourceUsage
    }
    "stopall" {
        Stop-AllWSLInstances
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "ERRO: Acao '$action' nao reconhecida." -ForegroundColor Red
        Show-Help
    }
}
