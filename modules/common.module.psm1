#Script:	common.module.psm1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.1
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

function Download-Url($url)
{
    $file = [System.IO.Path]::GetTempFileName()
    Write-Host "Downloading $url, please wait."
    (New-Object System.Net.WebClient).DownloadFile($url, $file)
    Write-Host "Download complete"
    return $file
}
function Extract-TempZip($file, $folderLocation)
{
    if(Test-Path $folderLocation)
    {
        Remove-Item $folderLocation -Recurse -Force
    }
    [System.IO.Compression.Zipfile]::ExtractToDirectory($file, $folderLocation)
    Remove-Item $file -Force
}
function Encrypt-PasswordFromString([string]$plainText)
{
    $secureString = $plainText | ConvertTo-SecureString -AsPlainText -Force
    return $secureString | ConvertFrom-SecureString 
}
function Encrypt-PasswordFromSecureString([SecureString]$secureString)
{
    return $secureString | ConvertFrom-SecureString 
}
function Write-Password([string]$plainText, [string]$path)
{
    $secureString = $plainText | ConvertTo-SecureString -AsPlainText -Force
    $secureStringText = $secureString | ConvertFrom-SecureString 
    Set-Content $path $secureStringText -Force
}
function Read-Password([string]$path)
{
    [OutputType([System.Security.SecureString])]
    $encryptedText = Get-Content $path
    $secureString = $encryptedText | ConvertTo-SecureString 
    return $secureString
}
function Get-Environment ([String] $name = $null, [ValidateSet("Dev","Test","UAT","Prod")][String] $environmentType = $null)
{
    $filename = "$PSScriptRoot\..\env\$name.$environmentType.environment"
    if(Test-Path $filename)
    {
        $jsonData = get-content $filename
        $environment = $jsonData | ConvertFrom-Json 
        return $environment
    }
    else 
    {
        $response = Read-Host "Environment $name not found.  Would you like to create one now? (y/N)"
        if($response -ieq "y")
        {
            & $PSScriptRoot\..\create-environment.ps1 -name $name -environmentType $environmentType
            Get-Environment $name $environmentType
        }
        else 
        {
            throw "Environment not found at path $filename"
        }
    }
}
function Delete-Environment ([String] $name = $null, [ValidateSet("Dev","Test","UAT","Prod")][String] $environmentType = $null, [switch] $force = $false)
{
    $filename = "$PSScriptRoot\..\env\$name.$environmentType.environment"
    if(Test-Path $filename)
    {
        if(-not $force)
        {
            $response = Read-Host "Are you sure you want to delete $filename? (y/N)"
            if($response -ine "y")
            {
                throw "Delete environment aborted"
            }
        }
        $filename | Remove-Item
    }
    else 
    {
        Write-Host "Environment $name not found."
    }
}
function Get-Environments ()
{
    $path = "$PSScriptRoot\..\env"
    get-childitem -Path $path -Filter "*.environment" | Select-Object -Property @{Name = 'Name'; Expression = { $_.Name.Split(".")[0] } }, @{Name = 'Type'; Expression = { $_.Name.Split(".")[1] }}, @{Name = 'Last Update'; Expression = { $_.LastWriteTime }}  
}
function Check-Environment([String] $env, [String] $environmentType = $null)
{
    $environment = Get-Environment $env $environmentType
    if($environment -ne $null)
    {
        Write-Host "Found the $($environment.environmentType) environment with Url $($environment.siteUrl)"
    }
}
function Warn-WillUpdate([String] $env, [String] $environmentType = $null, [boolean] $confirm)
{
    $environment = Get-Environment $env $environmentType
    if($confirm -eq $false) 
    {
        write-host "This process will update the $($environment.environmentType) environment at Url $($environment.siteUrl). No confirmation will be requested." 
        return
    }
    if($environment.environmentType -ieq "UAT" -or $environment.environmentType -ieq "Prod")
    {
        $response = Read-Host "This process will update the $($environment.environmentType) environment at Url $($environment.siteUrl). Proceed (y/n)" 
        if($response -ine "y")
        {
            $ErrorActionPreference = "Stop"
            throw "Updates cancelled"
        }
    }
}
