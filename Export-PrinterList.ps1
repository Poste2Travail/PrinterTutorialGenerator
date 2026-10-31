<#
.SYNOPSIS
    Liste automatiquement les imprimantes partagées d'un serveur d'impression Windows
    et génère le fichier printers.json utilisé par PrinterTutorialGenerator.

.DESCRIPTION
    Interroge le serveur d'impression (cmdlets PrintManagement), ne garde que les
    imprimantes partagées, puis écrit printers.json au format attendu par l'éditeur
    et les pages de tutoriel. Les champs "location" et "name" peuvent être enrichis
    via un fichier de correspondance optionnel (mapping.csv : queue;location).

.PARAMETER Server
    Nom DNS du serveur d'impression (ex. PRTSRV01.exemple.local).

.PARAMETER OutFile
    Chemin du printers.json généré.

.PARAMETER MappingFile
    Fichier CSV optionnel (séparateur ;) avec les colonnes queue;location.

.EXAMPLE
    .\Export-PrinterList.ps1 -Server PRTSRV01.exemple.local -OutFile C:\inetpub\wwwroot\printers\printers.json

.NOTES
    Nécessite le module PrintManagement (Windows 8/Server 2012 et supérieur).
    Exécution en lecture seule : aucune modification du serveur.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,

    [string]$OutFile = ".\printers.json",

    [string]$MappingFile
)

$ErrorActionPreference = 'Stop'

# Correspondances optionnelles queue -> emplacement lisible
$locations = @{}
if ($MappingFile -and (Test-Path $MappingFile)) {
    Import-Csv -Path $MappingFile -Delimiter ';' | ForEach-Object {
        $locations[$_.queue] = $_.location
    }
}

try {
    $printers = Get-Printer -ComputerName $Server |
        Where-Object { $_.Shared -eq $true } |
        Sort-Object ShareName
}
catch {
    Write-Error "Impossible de lister les imprimantes sur $Server : $($_.Exception.Message)"
    exit 1
}

$list = foreach ($p in $printers) {
    $queue = if ($p.ShareName) { $p.ShareName } else { $p.Name }
    $location = if ($locations.ContainsKey($queue)) { $locations[$queue] } elseif ($p.Location) { $p.Location } else { "À compléter" }

    [pscustomobject]@{
        name         = if ($p.Comment) { $p.Comment } else { $p.Name }
        location     = $location
        queue        = $queue
        server       = $Server
        'mac-driver' = "Generic PostScript Printer"
    }
}

$document = [ordered]@{
    config = [ordered]@{
        title_fr    = "Assistant Installation Imprimantes"
        subtitle_fr = "Installation guidée des imprimantes réseau"
        title_en    = "Printer Installation Assistant"
        subtitle_en = "Guided network printer installation"
        logo_url    = ""
        logo_position = "center"
        footer = [ordered]@{
            fr = [ordered]@{ title = "Besoin d'aide ?"; subtitle = "Support technique :"; email = "support@exemple.local"; phone = ""; hours = ""; website = ""; portal_text = ""; portal_url = "" }
            en = [ordered]@{ title = "Need help?"; subtitle = "Technical support:"; email = "support@exemple.local"; phone = ""; hours = ""; website = ""; portal_text = ""; portal_url = "" }
        }
    }
    printers = @($list)
}

$json = $document | ConvertTo-Json -Depth 6
$dir = Split-Path -Parent (Resolve-Path -Path $OutFile -ErrorAction SilentlyContinue)
if (-not $dir) { $dir = Split-Path -Parent $OutFile }
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

# UTF-8 sans BOM pour compatibilité avec le navigateur et IIS
[System.IO.File]::WriteAllText((Join-Path (Resolve-Path $dir) (Split-Path -Leaf $OutFile)), $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "$($list.Count) imprimante(s) exportée(s) dans $OutFile" -ForegroundColor Green
