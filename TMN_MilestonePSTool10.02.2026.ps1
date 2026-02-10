
# -*- coding: utf-8 -*-

Write-Host "Vérification de la présence des modules requis..." -ForegroundColor Red -BackgroundColor White

# Vérifier et installer le module MilestonePSTools
if (-not (Get-Module -ListAvailable -Name MilestonePSTools)) {
    Install-Module -Name MilestonePSTools -Force -Scope CurrentUser
}

# Vérifier et installer le module ImportExcel
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
}

# Importer les modules
Import-Module MilestonePSTools
Import-Module ImportExcel

# Connexion au serveur Milestone XProtect
Write-Host "Connexion au serveur de Management..." -ForegroundColor Red -BackgroundColor White
Connect-ManagementServer -ShowDialog -AcceptEula -Force

# Fonction pour masquer la console
function Hide-Console {
    $consolePtr = [System.Runtime.InteropServices.Marshal]::GetHINSTANCE([System.Reflection.Assembly]::GetExecutingAssembly().GetModules()[0])
    $hwnd = Get-ConsoleWindow
    ShowWindow $hwnd 0
}

# Déclarez les fonctions nécessaires
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FreeConsole();

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

# Raccourcis pour appeler les fonctions
$FreeConsole = [Win32]::FreeConsole
$GetConsoleWindow = [Win32]::GetConsoleWindow
$ShowWindow = [Win32]::ShowWindow

# Charger les types nécessaires pour utiliser Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Constantes pour le style
$buttonSize = New-Object System.Drawing.Size(450, 50)
$buttonPadding = New-Object System.Windows.Forms.Padding(5)
$buttonMargin = New-Object System.Windows.Forms.Padding(5, 2, 5, 2)
$buttonFont = New-Object System.Drawing.Font("Segoe UI", 12)
$buttonBackColor = [System.Drawing.Color]::DodgerBlue
$buttonForeColor = [System.Drawing.Color]::White

# Fonction pour créer un bouton
function Create-Button($text, $clickAction) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Size = $buttonSize
    $button.Padding = $buttonPadding
    $button.Margin = $buttonMargin
    $button.Font = $buttonFont
    $button.BackColor = $buttonBackColor
    $button.ForeColor = $buttonForeColor
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 0
    $button.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $button.Anchor = [System.Windows.Forms.AnchorStyles]::None
    $button.Add_Click($clickAction)
    return $button
}

# Créer la fenêtre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "MilestonePSTool By TMN :)"
$form.Size = New-Object System.Drawing.Size(1000, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::Black

# Créer le TableLayoutPanel pour organiser les contrôles
$tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$tableLayoutPanel.ColumnCount = 2
$tableLayoutPanel.RowCount = 5
$tableLayoutPanel.BackColor = [System.Drawing.Color]::White
$tableLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$tableLayoutPanel.CellBorderStyle = [System.Windows.Forms.TableLayoutPanelCellBorderStyle]::None

# Ajouter des lignes au TableLayoutPanel
for ($i = 0; $i -lt $tableLayoutPanel.RowCount; $i++) {
    $tableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize, 60)))
}

# Créer une TextBox pour afficher les résultats
$resultTextBox = New-Object System.Windows.Forms.TextBox
$resultTextBox.Multiline = $true
$resultTextBox.ReadOnly = $true
$resultTextBox.ScrollBars = "Vertical"
$resultTextBox.Width = 450
$resultTextBox.Height = 150
$resultTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$resultTextBox.BackColor = [System.Drawing.Color]::LightGray
$resultTextBox.ForeColor = [System.Drawing.Color]::Black
$resultTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::None

# Actions pour les boutons
$button1Action = { #Snapshot - Selection de Caméra
    try {
        $resultTextBox.AppendText("Opération en cours, cela peut prendre plusieurs minutes...`n")
        New-Item -Name "Snapshot" -Path $PSScriptRoot -ItemType Directory | Join-Path "Snapshot"
        
        $camera = Select-Camera
        $liveSnapshot = $camera | Get-Snapshot -UseFriendlyName -Behavior GetEnd -Quality 95 -Save -Path "Snapshot" 
        $resultTextBox.AppendText("fin`n")
    } catch {
        $resultTextBox.AppendText("Erreur : $_`n")
    }
}

$button2Action = { #Snapshot - Toute les Caméras
    Start-Sleep -Milliseconds 100
    try {
        $resultTextBox.AppendText("Opération en cours, cela peut prendre plusieurs minutes...`n")
        New-Item -Name "Snapshot" -Path $PSScriptRoot -ItemType Directory | Join-Path "Snapshot"
        
        $camera = Get-VmsCamera
        $Snapshot = $camera | Get-Snapshot -UseFriendlyName -Behavior GetEnd -Quality 95 -Save -Path "Snapshot" 
        $resultTextBox.AppendText("fin`n")
    } catch {
        $resultTextBox.AppendText("Erreur : $_`n")
    }
}

$button3Action = { #Export des Hardware
    try {
        $resultTextBox.AppendText("Opération en cours, cela peut prendre plusieurs minutes...`n")
        $cameras = Get-VmsCameraReport -IncludePlainTextPassword | ForEach-Object {
            [PSCustomObject]@{

                Nom         = $_.Name

                Fabricant   = $_.DriverFamily

                Modèle      = $_.Model

                IP          = $_.Address

                MAC         = $_.MAC

                Firmware    = $_.Firmware

                Activation  = $_.Enabled

                ServeurRec  = $_.RecorderName

                User        = $_.Username

                Pass        = $_.Password

                Gps         = $_.GpsCoordinates
                
            }
        }
        $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "Liste des Caméras.csv"
        $cameras | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        $resultTextBox.AppendText("Fin`n")
    } catch {
        $resultTextBox.AppendText("Erreur : $_`n")
    }
}

$button4Action = { #Grouper les Caméras par modèle
    try {
        $resultTextBox.AppendText("Opération en cours, cela peut prendre plusieurs minutes...`n")
        $parentFolderName = "Modèle"
        $parentFolder = Get-VmsDeviceGroup -Name $parentFolderName -ErrorAction SilentlyContinue
        if (-not $parentFolder) {
            $parentFolder = New-VmsDeviceGroup -Name $parentFolderName
        }
        $cameras = Get-VmsCameraReport
        $camerasByModel = $cameras | Group-Object -Property Model
        foreach ($group in $camerasByModel) {
            $model = $group.Name
            $camerasInModel = $group.Group
            $deviceGroup = Get-VmsDeviceGroup -ParentGroup $parentFolder -Name $model -ErrorAction SilentlyContinue
            if (-not $deviceGroup) {
                $deviceGroup = New-VmsDeviceGroup -ParentGroup $parentFolder -Name $model
            }
            foreach ($camera in $camerasInModel) {
                Add-VmsDeviceGroupMember -Group $deviceGroup -DeviceId $camera.Id
            }
        }
        $resultTextBox.AppendText("fin`n")
    } catch {
        $resultTextBox.AppendText("Erreur : $_`n")
    }
}

$button5Action = { #Snapshot - Par Preset Ptz
    try {
        $resultTextBox.AppendText("Opération en cours, cela peut prendre plusieurs minutes...`n")
New-Item -Name "Ptz Snapshot" -Path $PSScriptRoot -ItemType Directory | Join-Path "Ptz Snapshot"

$cameras = Select-Camera | Where-Object Enabled | Get-Camera | Where-Object { $_.Enabled -and $_.PtzPresetFolder.PtzPresets.Count -gt 0 }


function Invoke-PtzPreset {
   
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [VideoOS.Platform.ConfigurationItems.PtzPreset]
        $PtzPreset,

        [Parameter()]
        [switch]
        $VerifyCoordinates,
        
        [Parameter()]
        [double]
        $Tolerance = 0.001,
        
        [Parameter()]
        [int]
        $Timeout = 5
    )
    
    process {
        $cameraId = if ($PtzPreset.ParentItemPath -match 'Camera\[(.{36})\]') {
            $Matches[1]
        }
        else {
            Write-Error "Could not parse camera ID from ParentItemPath value '$($PtzPreset.ParentItemPath)'"
            return
        }

        $camera = Get-Camera -Id $cameraId
        $cameraItem = $camera | Get-PlatformItem
        $presetItem = [VideoOS.Platform.Configuration]::Instance.GetItem([guid]::new($PtzPreset.Id), [VideoOS.Platform.Kind]::Preset)
        
        $params = @{
            MessageId = 'Control.TriggerCommand'
            DestinationEndpoint = $presetItem.FQID
            UseEnvironmentManager = $true
        }
        Send-MipMessage @params

        if (-not $VerifyCoordinates) {
            return
        }

        if ($cameraItem.Properties['pan'] -ne 'Absolute' -or $cameraItem.Properties['pan'] -ne 'Absolute' -or $cameraItem.Properties['zoom'] -ne 'Absolute') {
            Write-Warning "VerifyCoordinates switch provided but camera does not use absolute PTZ positioning. Coordinates will not be verified."
            return
        }

        $positionReached = $false
        $stopwatch = [Diagnostics.StopWatch]::StartNew()
        while ($stopwatch.ElapsedMilliseconds -lt ($timeout * 1000)) {
            $position = Send-MipMessage -MessageId Control.PTZGetAbsoluteRequest -DestinationEndpoint $cameraItem.FQID -UseEnvironmentManager
            
            $xDifference = [Math]::Abs($position.Pan) - [Math]::Abs($ptzPreset.Pan)
            $yDifference = [Math]::Abs($position.Tilt) - [Math]::Abs($ptzPreset.Tilt)
            $zDifference = [Math]::Abs($position.Zoom) - [Math]::Abs($ptzPreset.Zoom)

            if ($xDifference -gt $Tolerance) {
                Write-Warning "Expected Pan = $($ptzPreset.Pan), Current Pan = $($position.Pan), Off by $xDifference"
            }
            elseif ($yDifference -gt $Tolerance) {
                Write-Warning "Desired Tilt = $($ptzPreset.Tilt), Current Pan = $($position.Tilt), Off by $yDifference"
            }
            elseif ($zDifference -gt $Tolerance) {
                Write-Warning "Desired Zoom = $($ptzPreset.Zoom), Current Pan = $($position.Zoom), Off by $zDifference"
            }
            else {
                $positionReached = $true
                Start-Sleep -Milliseconds 2500
                break
            }
            Start-Sleep -Milliseconds 100
        }
        if (-not $positionReached) {
            Write-Error "Camera failed to reach preset position"
        }
    }
}


foreach ($camera in $cameras) {

    foreach ($ptzPreset in $camera.PtzPresetFolder.PtzPresets) {
        
        $resultTextBox.AppendText("Moving $($camera.Name) to $($ptzPreset.Name) preset position`n")
        Invoke-PtzPreset -PtzPreset $ptzPreset -VerifyCoordinates

        $resultTextBox.AppendText("Snapshot enregistré. . .`n")
        $snapshotParams = @{
          
            Quality = 95
            Save = $true
            Path = "Ptz Snapshot"
            FileName = "$($camera.Name) -- $($ptzPreset.Name).jpg"
        }
        $null = $camera | Get-Snapshot @snapshotParams -Behavior GetEnd
    }
}


        $resultTextBox.AppendText("fin`n")
    } catch {
        $resultTextBox.AppendText("Erreur : $_`n")
    }
}


# Créer les boutons
$button1 = Create-Button "Snapshot - Selection de Caméra" $button1Action
$button2 = Create-Button "Snapshot - Toute les Caméras" $button2Action
$button3 = Create-Button "Export des Hardware" $button3Action
$button4 = Create-Button "Grouper les Caméras par modèle" $button4Action
$button5 = Create-Button "Snapshot - Par Preset Ptz" $button5Action

# Ajouter les boutons et la TextBox au TableLayoutPanel
$tableLayoutPanel.Controls.Add($button1, 0, 0) #Select Snaps
$tableLayoutPanel.Controls.Add($button2, 0, 1) #All Snaps
$tableLayoutPanel.Controls.Add($button3, 1, 0) #Export Hardware
$tableLayoutPanel.Controls.Add($button4, 1, 1) #Group By Model
$tableLayoutPanel.Controls.Add($button5, 0, 3) #Ptz Snaps



$tableLayoutPanel.Controls.Add($resultTextBox, 0, 4)

# Centrer les contrôles dans le TableLayoutPanel
foreach ($control in $tableLayoutPanel.Controls) {
    $control.Anchor = [System.Windows.Forms.AnchorStyles]::None
}

# Ajouter le TableLayoutPanel au formulaire
$form.Controls.Add($tableLayoutPanel)

# Ajouter un gestionnaire d'événements pour la fermeture du formulaire
$form.add_FormClosing({
    Disconnect-ManagementServer
    Write-Host "Déconnecté du serveur de Management."
})

# Masquer la console
$ShowWindow.Invoke($GetConsoleWindow.Invoke(), 0)

# Afficher la fenêtre
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
