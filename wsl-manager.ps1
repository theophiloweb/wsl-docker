# WSL Manager - Gerenciador de instancias WSL similar ao Docker
# Salve como wsl-manager.ps1 em D:\WSLDistros\


param (
    [Parameter(Mandatory=$true)][string]$action,
    [Parameter(Mandatory=$false)][string]$name,
    [Parameter(Mandatory=$false)][string]$base = "UbuntuMinimal2204", # Nome da sua distro base importada
    [Parameter(Mandatory=$false)][string]$envType = "base",
    [Parameter(Mandatory=$false)][string]$command
)

$basePath = "D:\WSLDistros" # Caminho onde as instancias e scripts estao
$provisionScriptLocalPath = Join-Path $basePath "provision-web-env.sh"
$provisionScriptTargetPathInWSL = "/tmp/provision-web-env.sh" # Caminho do script dentro da instancia WSL

# Verificar se o diretorio base existe
if (-not (Test-Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
    Write-Host "Diretorio base $basePath criado." -ForegroundColor Green
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
    "help" {
        Show-Help
    }
    default {
        Write-Host "ERRO: Acao '$action' nao reconhecida." -ForegroundColor Red
        Show-Help
    }
}