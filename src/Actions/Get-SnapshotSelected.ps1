function Get-SnapshotSelected {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Config,
        [Parameter(Mandatory)] [scriptblock]$Log,
        [Parameter()] [scriptblock]$Cancel = { $false },
        [Parameter()] [nullable[datetime]]$SnapshotTime = $null
    )

    & $Log $script:T.SS_LogOpening

    $camera = Select-Camera
    if (-not $camera) {
        & $Log $script:T.SS_LogNone
        return
    }

    if (& $Cancel) { return }

    $snapshotDir = Join-Path $Config.outputDirectory 'Snapshots'
    if (-not (Test-Path $snapshotDir)) {
        New-Item -Path $snapshotDir -ItemType Directory -Force | Out-Null
    }

    if ($SnapshotTime) { & $Log ($script:T.SS_LogHistorique -f $SnapshotTime.ToString('dd/MM/yyyy HH:mm')) }
    & $Log ($script:T.SS_LogCapturing -f $camera.Name)

    try {
        if ($SnapshotTime) {
            $camera | Get-Snapshot -UseFriendlyName -Behavior GetNearest `
                -Time $SnapshotTime -Quality $Config.snapshotQuality -Save -Path $snapshotDir
        }
        else {
            $camera | Get-Snapshot -UseFriendlyName -Behavior GetEnd `
                -Quality $Config.snapshotQuality -Save -Path $snapshotDir
        }
        & $Log ($script:T.SS_LogSaved -f $snapshotDir)
    }
    catch {
        & $Log ($script:T.SS_LogError -f $camera.Name, $_)
    }
}
