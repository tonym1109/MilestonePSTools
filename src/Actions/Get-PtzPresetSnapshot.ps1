function Get-PtzPresetSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Config,
        [Parameter(Mandatory)] [scriptblock]$Log,
        [Parameter()] [scriptblock]$Cancel = { $false },
        [Parameter()] [scriptblock]$ReportProgress = {},
        [Parameter()] [nullable[datetime]]$SnapshotTime = $null
    )

    $outputDir = Join-Path $Config.outputDirectory 'PTZ_Snapshots'
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    & $Log $script:T.PTZ_LogSelecting

    $cameras = Select-Camera |
        Where-Object { $_.Enabled } |
        Get-Camera |
        Where-Object { $_.Enabled -and $_.PtzPresetFolder.PtzPresets.Count -gt 0 }

    if (-not $cameras) {
        & $Log $script:T.PTZ_LogNone
        return
    }

    $cameraList  = @($cameras)
    $totalCams   = $cameraList.Count
    & $Log ($script:T.PTZ_LogFound -f $totalCams)

    if ($SnapshotTime) { & $Log ($script:T.PTZ_LogHistorique -f $SnapshotTime.ToString('dd/MM/yyyy HH:mm')) }

    $totalPresets = ($cameraList | ForEach-Object { $_.PtzPresetFolder.PtzPresets.Count } | Measure-Object -Sum).Sum
    $donePresets  = 0

    foreach ($camera in $cameraList) {
        if (& $Cancel) { & $Log $script:T.PTZ_LogCancelled ; break }

        $presets = $camera.PtzPresetFolder.PtzPresets
        & $Log ($script:T.PTZ_LogCamera -f $camera.Name, $presets.Count)

        foreach ($ptzPreset in $presets) {
            if (& $Cancel) { & $Log $script:T.PTZ_LogCancelled ; break }

            $donePresets++
            & $ReportProgress $donePresets $totalPresets
            & $Log ($script:T.PTZ_LogMoving -f $ptzPreset.Name)

            try { Invoke-PtzPreset -PtzPreset $ptzPreset -VerifyCoordinates }
            catch { & $Log ($script:T.PTZ_LogPosErr -f $_) }

            & $Log $script:T.PTZ_LogCapturing
            try {
                $safeCam    = $camera.Name    -replace '[\\/:*?"<>|]', '_'
                $safePreset = $ptzPreset.Name -replace '[\\/:*?"<>|]', '_'
                $snapParams = @{
                    Quality  = $Config.snapshotQuality
                    Save     = $true
                    Path     = $outputDir
                    FileName = "$safeCam -- $safePreset.jpg"
                }
                if ($SnapshotTime) {
                    $camera | Get-Snapshot @snapParams -Behavior GetNearest -Time $SnapshotTime
                }
                else {
                    $camera | Get-Snapshot @snapParams -Behavior GetEnd
                }
                & $Log ($script:T.PTZ_LogSaved -f $ptzPreset.Name)
            }
            catch { & $Log ($script:T.PTZ_LogError -f $ptzPreset.Name, $_) }
        }
    }

    if (-not (& $Cancel)) {
        & $Log ($script:T.PTZ_LogDone -f $outputDir)
    }
}
