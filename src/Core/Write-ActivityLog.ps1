<#
.SYNOPSIS
    Systeme de logging centralise pour l'application.
.DESCRIPTION
    Ecrit les messages dans un fichier de log et/ou vers un callback UI.
    Format : [HH:mm:ss] [LEVEL] Message
#>

function Write-ActivityLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',

        [Parameter()]
        [string]$LogDirectory,

        [Parameter()]
        [scriptblock]$UICallback
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $logLine  = "[$timestamp] [$Level] $Message"

    # Ecriture vers le fichier de log
    if ($LogDirectory) {
        if (-not (Test-Path $LogDirectory)) {
            New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        }
        $logFile   = Join-Path $LogDirectory ("MilestoneToolkit_{0}.log" -f (Get-Date -Format 'yyyy-MM-dd'))
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::AppendAllText($logFile, "$logLine`n", $utf8NoBom)
    }

    # Callback vers l'UI
    if ($UICallback) {
        & $UICallback $logLine
    }
}

<#
.SYNOPSIS
    Supprime les anciens fichiers de log. A appeler une fois au demarrage.
.PARAMETER LogDirectory
    Dossier des logs.
.PARAMETER RetentionDays
    Age maximal (jours) au-dela duquel un log est supprime. Defaut : 30.
#>
function Remove-OldLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$LogDirectory,
        [Parameter()] [int]$RetentionDays = 30
    )
    if (-not (Test-Path $LogDirectory)) { return }
    $limit = (Get-Date).AddDays(-$RetentionDays)
    Get-ChildItem -Path $LogDirectory -Filter 'MilestoneToolkit_*.log' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $limit } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
