function Get-RecordingStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Config,
        [Parameter(Mandatory)] [scriptblock]$Log,
        [Parameter()] [scriptblock]$Cancel = { $false },
        [Parameter()] [scriptblock]$ReportProgress = {}
    )

    $endTime   = (Get-Date).Date
    $startTime = $endTime.AddDays(-7)
    & $Log ($script:T.RS_LogPeriod -f $startTime.ToString('dd/MM/yyyy'), $endTime.ToString('dd/MM/yyyy'))

    & $Log $script:T.RS_LogCams
    $cameras = @(Get-VmsCamera)
    $total   = $cameras.Count
    & $Log ($script:T.RS_LogFound -f $total)

    # Statistiques video : UN SEUL appel groupe (parallelise par serveur d'enregistrement)
    # au lieu d'un appel reseau par camera. NOTE : l'ancien code "$cam | Get-VideoDeviceStatistics"
    # liait l'Id de la camera au parametre RecordingServerId => aucun resultat, colonnes
    # FPS/Bitrate/Resolution toujours 'N/A'. Le lookup par DeviceId corrige ce bug.
    $vidStatsLookup = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)
    try {
        foreach ($rsResult in @(Get-VideoDeviceStatistics -ErrorAction Stop)) {
            foreach ($dev in @($rsResult.VideoDeviceStatistics)) {
                if ($dev -and $dev.DeviceId) { $vidStatsLookup[$dev.DeviceId.ToString()] = $dev }
            }
        }
        & $Log ($script:T.RS_LogLiveOk -f $vidStatsLookup.Count)
    }
    catch { & $Log ($script:T.RS_LogLiveWarn -f $_) }

    $rows  = [System.Collections.Generic.List[PSCustomObject]]::new()
    $count = 0

    foreach ($cam in $cameras) {
        if (& $Cancel) { & $Log ($script:T.RS_LogCancelled -f $count, $total) ; break }

        $count++
        & $ReportProgress $count $total
        & $Log ($script:T.RS_LogProgress -f $count, $total, $cam.Name)

        $row = [PSCustomObject]@{
            ($script:T.RS_CsvNom)     = $cam.Name
            ($script:T.RS_CsvActive)  = $cam.Enabled
            ($script:T.RS_CsvSeqRec)  = 'N/A'
            ($script:T.RS_CsvPctRec)  = 'N/A'
            ($script:T.RS_CsvTimeRec) = 'N/A'
            ($script:T.RS_CsvSeqMot)  = 'N/A'
            ($script:T.RS_CsvPctMot)  = 'N/A'
            ($script:T.RS_CsvFps)     = 'N/A'
            ($script:T.RS_CsvBitrate) = 'N/A'
            ($script:T.RS_CsvRes)     = 'N/A'
        }

        try {
            $recResult = $cam | Get-CameraRecordingStats `
                -StartTime $startTime -EndTime $endTime `
                -SequenceType RecordingSequence -ErrorAction Stop

            if ($recResult -and $recResult.RecordingStats) {
                $rs  = $recResult.RecordingStats
                $pct = if ($null -ne $rs.PercentRecorded) { "$([math]::Round($rs.PercentRecorded, 1)) %" } else { 'N/A' }
                $dur = if ($null -ne $rs.TimeRecorded) {
                    $ts = [TimeSpan]$rs.TimeRecorded
                    if ([int]$ts.TotalDays -gt 0) { $script:T.RS_DurDays -f [int]$ts.TotalDays, $ts.Hours, $ts.Minutes }
                    else                          { $script:T.RS_DurHours -f $ts.Hours, $ts.Minutes }
                } else { 'N/A' }

                $row.($script:T.RS_CsvSeqRec)  = $rs.SequenceCount
                $row.($script:T.RS_CsvPctRec)  = $pct
                $row.($script:T.RS_CsvTimeRec) = $dur
                & $Log ($script:T.RS_LogRec -f $rs.SequenceCount, $pct, $dur)
            }
        }
        catch { & $Log ($script:T.RS_LogRecWarn -f $_) }

        try {
            $motResult = $cam | Get-CameraRecordingStats `
                -StartTime $startTime -EndTime $endTime `
                -SequenceType MotionSequence -ErrorAction Stop

            if ($motResult -and $motResult.RecordingStats) {
                $ms     = $motResult.RecordingStats
                $motPct = if ($null -ne $ms.PercentRecorded) { "$([math]::Round($ms.PercentRecorded, 1)) %" } else { 'N/A' }
                $row.($script:T.RS_CsvSeqMot) = $ms.SequenceCount
                $row.($script:T.RS_CsvPctMot) = $motPct
                & $Log ($script:T.RS_LogMot -f $ms.SequenceCount, $motPct)
            }
        }
        catch { & $Log ($script:T.RS_LogMotWarn -f $_) }

        $dev = $null
        if ($vidStatsLookup.TryGetValue([string]$cam.Id, [ref]$dev) -and $dev) {
            # Flux d'enregistrement en priorite, sinon flux live par defaut, sinon le premier
            $streams = @($dev.VideoStreamStatisticsArray)
            $vs = $streams | Where-Object { $_.RecordingStream }    | Select-Object -First 1
            if (-not $vs) { $vs = $streams | Where-Object { $_.LiveStreamDefault } | Select-Object -First 1 }
            if (-not $vs) { $vs = $streams | Select-Object -First 1 }
            if ($vs) {
                $fps = [math]::Round($vs.FPS, 1)
                $bps = [math]::Round($vs.BPS / 1000, 0)
                $res = if ($vs.ImageResolution) { "$($vs.ImageResolution.Width)x$($vs.ImageResolution.Height)" } else { 'N/A' }
                $row.($script:T.RS_CsvFps)     = $fps
                $row.($script:T.RS_CsvBitrate) = $bps
                $row.($script:T.RS_CsvRes)     = $res
                & $Log ($script:T.RS_LogLive -f $fps, $bps, $res)
            }
        }

        $rows.Add($row)
    }

    if ($rows.Count -gt 0 -and -not (& $Cancel)) {
        if (-not (Test-Path $Config.outputDirectory)) {
            New-Item -Path $Config.outputDirectory -ItemType Directory -Force | Out-Null
        }
        $csvPath = Join-Path $Config.outputDirectory $script:T.RS_CsvFileName
        try {
            $rows | Export-Csv -Path $csvPath -NoTypeInformation `
                -Encoding $Config.csvEncoding -Delimiter $Config.csvDelimiter
            & $Log ($script:T.RS_LogExported -f $csvPath)
        }
        catch { & $Log ("ERREUR: Export CSV : $_") }
    }
}
