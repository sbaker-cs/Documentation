param (
    [switch] $h,
    [switch] $f, # force rendering
    [switch] $pdf, # also render documentation in PDF
    [switch] $o  # open files after rendering
)

if ($h) {
    Write-Host "AsciiDoc rendering script

    -f`t`t`t Force rendering of all .adoc files
    -o`t`t`t Open files after rendering"
    return
}

Import-Module ThreadJob

function IsDirty {
    param (
        [string] $sourceFile,
        [string] $renderFile
    )

    if (-not [System.IO.File]::Exists($renderFile)) {
        Write-Host "$renderFile does not exist"
        return $true
    }

    (Get-Item $sourceFile).LastWriteTime -gt (Get-Item $renderFile).LastWriteTime
}

$docPath = $PSScriptRoot
$currentPath = Get-Location
Set-Location $docPath

$docDirty = IsDirty $docPath\Documentation.adoc $docPath\Render\Documentation.html
Get-ChildItem -R $docPath\resources\partial | ForEach-Object {
    if (IsDirty $_ $docPath\Render\Documentation.html)
    {
        $docDirty = $true
    }
}

$commands = @();

if ($f -or $docDirty) {
    $gitPath = If (Test-Path 'C:\git') {'C:\git'} else {'E:\git'}

    # debug with -w
    $commands += {
        Write-Host "Rendering Documentation"
        asciidoctor -r asciidoctor-kroki -r asciidoctor-tabs -D .\Render\ -a gitPath=$using:gitPath -a toc=left -o Documentation.html $using:docPath\Documentation.adoc
        if ($using:o) {
            . "$using:docPath\Render\Documentation.html"
        }
    }, {
        if ($using:pdf) {
            Write-Host "Rendering Documentation PDF"
            asciidoctor-pdf $using:docPath\Documentation.adoc -o .\Render\Documentation.pdf -b pdf -r asciidoctor-kroki -a allow-uri-read -q
            if ($using:o) {
                . "$using:docPath\Render\Documentation.pdf"
            }
        }
    }
}

$commands | ForEach-Object {
    Start-ThreadJob -ScriptBlock $_ -ArgumentList (@{
    } | Out-String)
} | Receive-Job -Wait -AutoRemoveJob

Set-Location $currentPath

[System.Media.SystemSounds]::Hand.Play()
