function Get-VmsLicenseSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [scriptblock]$Log
    )

    & $Log $script:T.LI_LogHeader
    try {
        $products = @(Get-LicensedProducts -ErrorAction Stop)

        if ($products.Count -eq 0) {
            & $Log $script:T.LI_LogNone
            return
        }

        foreach ($product in $products) {
            & $Log ($script:T.LI_LogProduct -f $product.DisplayName)

            $expRaw = $product.ExpirationDate
            if ($expRaw -and $expRaw -ne 'N/A') {
                try {
                    $expDate  = [datetime]$expRaw
                    $daysLeft = ($expDate - (Get-Date)).Days
                    $expStr   = $expDate.ToString('dd/MM/yyyy')
                    if ($daysLeft -lt 0) {
                        & $Log ($script:T.LI_LogExpired -f $expStr, [math]::Abs($daysLeft))
                    }
                    elseif ($daysLeft -lt 30) {
                        & $Log ($script:T.LI_LogExpSoon -f $expStr, $daysLeft)
                    }
                    else {
                        & $Log ($script:T.LI_LogExpiry -f $expStr, $daysLeft)
                    }
                }
                catch {
                    & $Log ($script:T.LI_LogExpiryRaw -f $expRaw)
                }
            }
            else {
                & $Log $script:T.LI_LogPerpetual
            }

            if ($product.Slc) {
                & $Log ($script:T.LI_LogSlc -f $product.Slc)
            }

            foreach ($careProp in @('CarePlus','CarePremium')) {
                $val = $product.$careProp
                if ($val -and $val -ne 'N/A') {
                    & $Log ($script:T.LI_LogCareProp -f $careProp, $val)
                }
            }
        }

        # Detail des canaux par type (Get-LicenseDetails remplace LicensedChannels/UsedChannels)
        $details = @(Get-LicenseDetails -ErrorAction SilentlyContinue)
        if ($details.Count -gt 0) {
            & $Log $script:T.LI_LogDetailHeader
            foreach ($detail in $details) {
                & $Log ($script:T.LI_LogDetail -f $detail.LicenseType, $detail.Activated, $detail.InGrace, $detail.NotLicensed)
            }
        }
    }
    catch {
        & $Log ($script:T.LI_LogError -f $_)
    }
}
