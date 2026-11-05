function Get-PlaybackReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Config,
        [Parameter(Mandatory)] [scriptblock]$Log,
        [Parameter()] [scriptblock]$Cancel = { $false },
        [Parameter()] [scriptblock]$ReportProgress = {}
    )

    & $Log $script:T.PR_LogCams
    $cameras = @(Get-VmsCamera)
    $total   = $cameras.Count
    & $Log ($script:T.PR_LogFound -f $total)

    $camByPath = @{}
    foreach ($cam in $cameras) { $camByPath[$cam.Path] = $cam.Name }

    try {
        $playbackData = @($cameras | Get-PlaybackInfo -Parallel -ErrorAction Stop)
        & $Log ($script:T.PR_LogDataReceived -f $playbackData.Count)
    }
    catch {
        & $Log ($script:T.PR_LogError -f $_)
        return
    }

    $rows  = [System.Collections.Generic.List[PSCustomObject]]::new()
    $count = 0

    foreach ($info in $playbackData) {
        if (& $Cancel) { & $Log ($script:T.PR_LogCancelled -f $count, $total) ; break }

        $count++
        & $ReportProgress $count $total

        $name = if ($camByPath.ContainsKey($info.Path)) { $camByPath[$info.Path] } else { $info.Path }

        if ($info.Begin -and $info.End) {
            $begin    = $info.Begin.ToLocalTime()
            $end      = $info.End.ToLocalTime()
            $beginStr = $begin.ToString('dd/MM/yyyy HH:mm')
            $endStr   = $end.ToString('dd/MM/yyyy HH:mm')
            $ts       = $end - $begin
            $durStr   = if ([int]$ts.TotalDays -gt 0) { $script:T.PR_DurDays -f [int]$ts.TotalDays, $ts.Hours }
                        else                           { $script:T.PR_DurHours -f $ts.Hours, $ts.Minutes }
            & $Log ($script:T.PR_LogRow -f $name, $beginStr, $endStr, $durStr)
        }
        else {
            $beginStr = 'N/A'
            $endStr   = 'N/A'
            $durStr   = 'N/A'
            & $Log ($script:T.PR_LogNoRec -f $name)
        }

        $rows.Add([PSCustomObject]@{
            ($script:T.PR_CsvNom)     = $name
            ($script:T.PR_CsvPremier) = $beginStr
            ($script:T.PR_CsvDernier) = $endStr
            ($script:T.PR_CsvDuree)   = $durStr
        })
    }

    if ($rows.Count -gt 0 -and -not (& $Cancel)) {
        if (-not (Test-Path $Config.outputDirectory)) {
            New-Item -Path $Config.outputDirectory -ItemType Directory -Force | Out-Null
        }
        $csvPath = Join-Path $Config.outputDirectory $script:T.PR_CsvFileName
        try {
            $rows | Export-Csv -Path $csvPath -NoTypeInformation `
                -Encoding $Config.csvEncoding -Delimiter $Config.csvDelimiter
            & $Log ($script:T.PR_LogExported -f $csvPath)
        }
        catch { & $Log ("ERREUR: Export CSV : $_") }
    }
}
