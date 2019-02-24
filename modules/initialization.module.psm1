#Script:	initialization.module.psm1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.1
#Module: initialization.module.psm1
#Author: Tim Wheeler (http://timwheeler.io/)
#Purpose: Set's
#Remarks: An environment file is named [EnviornmentName].environment and stores data in JSON format
#       : Environment files are used by other scripts to get credentials
#Example: .\create-environment.ps1 -siteUrl "https://mytenancy.sharepoint.com/sites/mysitecollection" -name "dev1" -username "my@email.com" -credentialType SharePointOnline -environmentType Dev
$libsPath = "$PSScriptRoot\..\libs"
$csomPath = "$libsPath\csom"
$modulesPath = "$PSScriptRoot"
function DownloadLibrary($name, $url, $path)
{
    Write-Host "Downloading $name from $url to $path"
    $file = Download-Url $url
    Extract-TempZip $file $path
}

function DownloadLibraries()
{
    DownloadLibrary "MS Client Side Object Model (Online)" "https://www.nuget.org/api/v2/package/Microsoft.SharePointOnline.CSOM/16.1.8523.1200" "$csomPath\Online"
    DownloadLibrary "MS Client Side Object Model (2013)" "https://www.nuget.org/api/v2/package/Microsoft.SharePoint2013.CSOM/15.0.5031.1001" "$csomPath\2013"
    DownloadLibrary "MS Client Side Object Model (2016)" "https://www.nuget.org/api/v2/package/Microsoft.SharePoint2016.CSOM/16.0.4690.1000" "$csomPath\2016"
    DownloadLibrary "MS Client Side Object Model (2019)" "https://www.nuget.org/api/v2/package/Microsoft.SharePoint2019.CSOM/16.0.10337.12109" "$csomPath\2019"
}

if(-not (Test-Path $csomPath))
{
    $response = Read-Host -Prompt "The MS CSOM Libraries don't exist, would you like to download them now? (y/n)"
    if($response -ieq "y")
    {
        DownloadLibraries
    }
    else {
        throw "Libraries not installed"
    }
}

#Add-Type -LiteralPath ("$libsPath\CSOM\16\lib\net45\Microsoft.SharePoint.Client.dll") -PassThru | out-null
#Add-Type -LiteralPath ("$libsPath\CSOM\16\lib\net45\Microsoft.SharePoint.Client.Runtime.dll") -PassThru | out-null
Import-Module -Name "$modulesPath\common.module.psm1" -Force -DisableNameChecking
Import-Module -Name "$modulesPath\sp.module.psm1" -Force -DisableNameChecking
$office365DevScriptsInitialized = $true
