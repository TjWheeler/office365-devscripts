#Script:	Get-ContentType.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.3
#Purpose:   Get a ContentType in the Root Web
#notes:     
param(
    $env =  $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [string] $name = $(Read-Host "Specify name")
)
$InformationPreference = "continue"
&("$PSScriptRoot\Start.ps1")
$scriptStartTime = Get-Date



$context = Create-Context $env -environmentType $environmentType
try
{
     write-host "---- Looking for content type $name ----"
    $items = $context.Site.RootWeb.ContentTypes
    $context.Load($items)
    Write-Information "Loading Content Types"
    Execute-WithRetry $context
    
    [Array] $filtered = $items | where-object { $_.Name -ieq $name}
    if($filtered.Count -eq 0) 
    {
        Write-Warning "$name not found"
    } 
    else {
        $ct = $filtered[0]
        $context.Load($ct)
        Execute-WithRetry $context
        $ct | fl Name, Description, Group, Hidden, Id, SchemaXml
        return $ct
    }     
    return $null
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
