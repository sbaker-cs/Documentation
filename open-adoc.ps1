param([string]$FilePath)

$path = [System.IO.Path]::GetDirectoryName($FilePath)
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
$outFile = Join-Path $env:TEMP "$baseName.html"

$lastLine = Get-Content $FilePath -Tail 1
$extraParams = @()

if ($lastLine -match '^//\s*adoc-params:\s*(.+)$') {
    $extraParams = $Matches[1].Trim() -split '\s+'
}

Set-Location $path
& asciidoctor $FilePath -o $outFile @extraParams
Start-Process $outFile
