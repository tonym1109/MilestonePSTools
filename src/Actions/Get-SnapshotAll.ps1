function Get-SnapshotAll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Config,
        [Parameter(Mandatory)] [scriptblock]$Log,
        [Parameter()] [scriptblock]$Cancel = { $false },
        [Parameter()] [scriptblock]$ReportProgress = {},
        [Parameter()] [nullable[datetime]]$SnapshotTime = $null
    )

    $snapshotDir = Join-Path $Config.outputDirectory 'Snapshots'
    if (-not (Test-Path $snapshotDir)) {
        New-Item -Path $snapshotDir -ItemType Directory -Force | Out-Null
    }

    & $Log $script:T.SA_LogCams
    $cameras = @(Get-VmsCamera)
    $total   = $cameras.Count
    & $Log ($script:T.SA_LogFound -f $total)

    if ($SnapshotTime) { & $Log ($script:T.SA_LogHistorique -f $SnapshotTime.ToString('dd/MM/yyyy HH:mm')) }

    $behavior = if ($SnapshotTime) { 'GetNearest' } else { 'GetEnd' }
    $quality  = $Config.snapshotQuality

    $received = 0
    $errors   = 0

    for ($i = 0; $i -lt $cameras.Count; $i++) {
        $cam = $cameras[$i]

        if (& $Cancel) { & $Log $script:T.SA_LogCancelled ; break }

        try {
            if ($SnapshotTime) {
                $cam | Get-Snapshot -UseFriendlyName -Behavior $behavior `
                    -Time $SnapshotTime -Quality $quality -Save -Path $snapshotDir
            } else {
                $cam | Get-Snapshot -UseFriendlyName -Behavior $behavior `
                    -Quality $quality -Save -Path $snapshotDir
            }
            $received++
            & $Log ($script:T.SA_LogOk -f $received, $total, $cam.Name)
        } catch {
            $errors++
            & $Log ($script:T.SA_LogError -f $cam.Name, $_)
        }

        & $ReportProgress ($i + 1) $total
    }

    $msg = if ($errors -gt 0) { $script:T.SA_LogDoneErr -f $received, $errors, $snapshotDir }
           else                { $script:T.SA_LogDone    -f $received, $snapshotDir }
    & $Log $msg
}
