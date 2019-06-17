#Script:	Get-SiteField.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
#Purpose:   Get properties of a field in the Root Web
#notes:     
param(
    $env =  $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [string] $fieldName = $(Read-Host "Specify fieldname")
)
$InformationPreference = "continue"
&("$PSScriptRoot\Start.ps1")
$scriptStartTime = Get-Date


$context = Create-Context $env -environmentType $environmentType
try
{
     write-host "---- Looking for site field $fieldName ----"
    $fields = $context.Site.RootWeb.Fields
    $context.Load($fields)
    Write-Information "Loading fields"
    Execute-WithRetry $context
    
    [Array] $filtered = $fields | where-object { $_.InternalName -ieq $fieldName}
    if($filtered.Count -eq 0) 
    {
        Write-Warning "$fieldName not found"
    } 
    else {
        foreach($field in $filtered)
        {
            Write-Host "---- $field.InternalName ----"
            Write-Host "`nProperties:"
            $field 
            Write-Host "`n`n"
        }
    }     
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
