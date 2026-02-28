<#
.SYNOPSIS
    Cree des Device Groups dans Milestone organises par modele de camera.
.DESCRIPTION
    Cree un dossier parent "Modele" dans les Device Groups, puis un sous-dossier
    par modele de camera, et y ajoute les cameras correspondantes.
.PARAMETER Config
    Hashtable de configuration.
.PARAMETER Log
    Scriptblock callback pour logger vers l'UI.
#>

function Set-CameraGroupByModel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [scriptblock]$Log
    )

    $parentFolderName = 'Modele'

    & $Log "Recuperation des informations cameras..."
    $cameras = Get-VmsCameraReport
    & $Log "$($cameras.Count) cameras trouvees."

    # Creer ou recuperer le dossier parent
    $parentFolder = Get-VmsDeviceGroup | Where-Object { $_.Name -eq $parentFolderName } | Select-Object -First 1
    if (-not $parentFolder) {
        try {
            $parentFolder = New-VmsDeviceGroup -Name $parentFolderName
            & $Log "Dossier parent '$parentFolderName' cree."
        } catch {
            $parentFolder = Get-VmsDeviceGroup | Where-Object { $_.Name -eq $parentFolderName } | Select-Object -First 1
            if (-not $parentFolder) { throw }
            & $Log "Dossier parent '$parentFolderName' recupere (existait deja)."
        }
    }

    # Grouper par modele
    $camerasByModel = $cameras | Group-Object -Property Model
    & $Log "$($camerasByModel.Count) modeles differents detectes."

    foreach ($group in $camerasByModel) {
        $model = $group.Name
        if ([string]::IsNullOrWhiteSpace($model)) {
            $model = 'Inconnu'
        }

        # Creer ou recuperer le sous-dossier du modele
        $deviceGroup = Get-VmsDeviceGroup -ParentGroup $parentFolder | Where-Object { $_.Name -eq $model } | Select-Object -First 1
        if (-not $deviceGroup) {
            try {
                $deviceGroup = New-VmsDeviceGroup -ParentGroup $parentFolder -Name $model
            } catch {
                $deviceGroup = Get-VmsDeviceGroup -ParentGroup $parentFolder | Where-Object { $_.Name -eq $model } | Select-Object -First 1
                if (-not $deviceGroup) { throw }
            }
        }

        foreach ($camera in $group.Group) {
            Add-VmsDeviceGroupMember -Group $deviceGroup -DeviceId $camera.Id
        }

        & $Log "Modele '$model' : $($group.Count) camera(s) ajoutee(s)."
    }

    & $Log "Organisation par modele terminee."
}
