#Script:	Set-ScriptMetadata.ps1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.2
#Purpose: Updates all scripts and sets name, author and version
param(
    $version = "0.2"
)

function Update-FileLine([IO.FileInfo] $file, [string] $newLineValue, [string]$match, [int]$lineNumber)
{
    $data = $file | Get-Content
    if($data.Length -gt $lineNumber -and $data[$lineNumber] -match $match )
    {
        if($data[$lineNumber] -ne $newLineValue)
        {
            $data[$lineNumber] = $newLineValue
            Write-Host "Updating $($file.Name)"
            Set-Content -Path $file.FullName -Value $data
        }
    }
    else 
    {
        Write-Host "Updating $($file.Name)"
        if($lineNumber -eq 0)
        {
            $data = $newLineValue,$data[0..($data.Length -1)]
        } 
        else {
            $data = $data[0..($lineNumber-1)],$newLineValue,$data[$lineNumber..($data.Length -1)]
        }
        Set-Content -Path $file.FullName -Value $data    
    }
    
}

function Set-FileMetadata([IO.FileInfo] $file, [string] $version)
{
    $filenameEntry = "#Script:`t$($file.Name)"
    $authorEntry = "#Author:`tTim Wheeler (http://timwheeler.io)"
    $versionEntry = "#Version:`t$version"

    Update-FileLine $file $filenameEntry "#Script:" 0
    Update-FileLine $file $authorEntry "#Author:" 1
    Update-FileLine $file $versionEntry "#Version:" 2
}
[Array] $files = Get-ChildItem -Filter "*.ps1" -Recurse -Path $PSScriptRoot 
$files | ForEach-Object { Set-FileMetadata $_ $version }


