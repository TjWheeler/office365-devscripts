#Script:	Delete-RecycleBins.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.3
#Purpose:   Recurse the web structure and clear all of the Web Recycle Bins.  Then clear the Site Recycle Bin.
#notes:     
param(
    $env =  $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [switch] $confirm = $true
)
$InformationPreference = "continue"
&("$PSScriptRoot\Start.ps1")

Check-Environment $env $environmentType
Warn-WillUpdate $env $environmentType $confirm 
$scriptStartTime = Get-Date

$context = Create-Context $env -environmentType $environmentType

function RecurseWebs([Microsoft.SharePoint.Client.Web] $web)
{
    $context.Load($web)
    Execute-WithRetry $context
    Write-Information "Emptying Recycle Bin at $($web.Url)"
    $web.RecycleBin.DeleteAll()
    $webs = $web.Webs
    $context.Load($webs)
    Execute-WithRetry $context
    foreach($subWeb in $webs)
    {
        RecurseWebs $subWeb 
    }
}

try
{
    $site = $context.Site
    $context.Load($site)
    RecurseWebs $context.Site.RootWeb
    Write-Information "Emptying Site Recycle Bin at $($site.Url)"
    $site.RecycleBin.DeleteAll()
    $context.ExecuteQuery()
}
finally
{
    Write-Information "Script started at $scriptStartTime"
    Write-Information "Script finished at $(Get-Date)"
    Write-Information "Time taken is $(([DateTime]::Now - $scriptStartTime).ToString())"
    if($context -ne $null)
    {
        $context.Dispose()
        $context = $null
    } 
}
