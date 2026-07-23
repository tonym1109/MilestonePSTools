function Get-CameraStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Config,
        [Parameter(Mandatory)] [scriptblock]$Log,
        [Parameter()] [scriptblock]$Cancel = { $false },
        [Parameter()] [scriptblock]$ReportProgress = {}
    )

    & $Log $script:T.CS_LogQuerying

    try {
        $states = @(Get-ItemState -CamerasOnly -ErrorAction Stop)
    }
    catch {
        & $Log ($script:T.CS_LogError -f $_)
        return
    }

    $total    = $states.Count
    & $Log ($script:T.CS_LogFound -f $total)

    $rows     = [System.Collections.Generic.List[PSCustomObject]]::new()
    $ok       = 0
    $ko       = 0
    $count    = 0
    $disabled = 0

    foreach ($state in $states) {
        if (& $Cancel) { & $Log ($script:T.CS_LogCancelled -f $count, $total) ; break }

        $count++
        & $ReportProgress $count $total

        $name = if ($state.Name -and $state.Name -ne 'Not available') { $state.Name }
                else { $state.FQID.ObjectId.ToString() }

        switch ($state.State) {
            'Responding' { $ok++ ; & $Log ($script:T.CS_LogOk -f $name) }
            'Disabled'   { $disabled++ }
            default      { $ko++ ; & $Log ($script:T.CS_LogErr -f $name, $state.State) }
        }

        if ($state.State -ne 'Disabled') {
            $rows.Add([PSCustomObject]@{
                ($script:T.CS_CsvNom)  = $name
                ($script:T.CS_CsvEtat) = if ($state.State -eq 'Responding') { $script:T.CS_CsvOk } else { $state.State }
                ($script:T.CS_CsvType) = $state.ItemType
            })
        }
    }

    if ($disabled -gt 0) { & $Log ($script:T.CS_LogDisabled -f $disabled) }

    if ($ko -gt 0) {
        & $Log ($script:T.CS_LogKo -f $ko, ($total - $disabled))
    }
    else {
        & $Log ($script:T.CS_LogAllOk -f $ok)
    }

    if ($rows.Count -gt 0 -and -not (& $Cancel)) {
        if (-not (Test-Path $Config.outputDirectory)) {
            New-Item -Path $Config.outputDirectory -ItemType Directory -Force | Out-Null
        }
        $csvPath = Join-Path $Config.outputDirectory $script:T.CS_CsvFileName
        try {
            $rows | Export-Csv -Path $csvPath -NoTypeInformation `
                -Encoding $Config.csvEncoding -Delimiter $Config.csvDelimiter
            & $Log ($script:T.CS_LogExported -f $csvPath)
        }
        catch { & $Log ("ERREUR: Export CSV : $_") }
    }
}
