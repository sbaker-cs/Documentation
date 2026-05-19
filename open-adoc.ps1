param([string]$FilePath)

$path = [System.IO.Path]::GetDirectoryName($FilePath)
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
$outFile = Join-Path $env:TEMP "$baseName.html"

$lastLine = Get-Content $FilePath -Tail 1
$extraParams = @()

if ($lastLine -match '^//\s*open-adoc:\s*(.+)$') {
    $extraParams = $Matches[1].Trim() -split '\s+'
}

Set-Location $path
$errOutput = $( & asciidoctor $FilePath -o $outFile @extraParams ) 2>&1 | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
Start-Process $outFile

if ($errOutput) {
    if ($errOutput) {
        $errOutput | ForEach-Object { Write-Host $_.Exception.Message -ForegroundColor Yellow }
    }
    Read-Host
}
