<#
.SYNOPSIS
    Telecharge les modules requis dans le dossier Dependencies/ pour usage offline.
.DESCRIPTION
    Executez ce script sur une machine ayant acces a Internet.
    Les modules seront enregistres localement dans Dependencies/.
    Vous pourrez ensuite copier tout le projet (avec Dependencies/) sur une machine
    sans acces Internet et lancer l'application en mode Offline.
.EXAMPLE
    .\Save-Dependencies.ps1
    # Telecharge MilestonePSTools dans Dependencies/

    # Copiez ensuite le dossier complet sur la machine cible.
.NOTES
    Necessite un acces a PowerShell Gallery (https://www.powershellgallery.com).
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

$depPath = Join-Path $PSScriptRoot 'Dependencies'

# Creer le dossier si absent
if (-not (Test-Path $depPath)) {
    New-Item -Path $depPath -ItemType Directory -Force | Out-Null
}

# Liste des modules : source unique partagee (src/Core/RequiredModules.ps1)
. (Join-Path $PSScriptRoot 'src/Core/RequiredModules.ps1')
$modules = (Get-RequiredModules).Name

Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Telechargement des dependances offline'     -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

foreach ($moduleName in $modules) {
    Write-Host "[$moduleName] " -NoNewline

    $targetDir = Join-Path $depPath $moduleName
    if (Test-Path $targetDir) {
        Write-Host "deja present, mise a jour..." -ForegroundColor Yellow
        Remove-Item $targetDir -Recurse -Force
    }
    else {
        Write-Host "telechargement..." -ForegroundColor White
    }

    try {
        Save-Module -Name $moduleName -Path $depPath -Force
        Write-Host "[$moduleName] OK" -ForegroundColor Green
    }
    catch {
        Write-Host "[$moduleName] ERREUR: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ''
Write-Host 'Dependances enregistrees dans :' -ForegroundColor Green
Write-Host "  $depPath" -ForegroundColor White
Write-Host ''
Write-Host 'Vous pouvez maintenant copier le projet sur une machine offline.' -ForegroundColor Cyan
Write-Host 'Le mode Offline sera actif automatiquement si le dossier Dependencies/ est present.' -ForegroundColor Cyan
