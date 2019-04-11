#Script:	Test-SPConnection.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.3
#Purpose: CSOM Connection Test Script
param(
    $env =  $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod")
)
&("$PSScriptRoot\Start.ps1")
$context = Create-Context $env -environmentType $environmentType

try
{
    $web = $context.Web
    $context.Load($web)
    write-host "Attempting conntection to $env - $environmentType"
    $context.ExecuteQuery()
    write-host "Successfully conntected to $env at Url $($web.Url)" -f Green
    $context.Dispose()
    $context = $null
}
catch
{
    Write-Error "Failed to connect to $env at Url $($web.Url).  Error:$_"
}
