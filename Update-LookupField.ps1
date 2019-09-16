#Script:	Update-LookupField.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
#Purpose:   Fix the lookup list reference.  
#notes:     
param(
    $env =  $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [string] $fieldName = $(Read-Host "Specify fieldname"),
    $lookupListUrl = $(Read-Host "Specify list web url eg; /sites/somesite/someweb"),
    $lookupListName = $(Read-Host "Specify list name. eg; Documents"),
    $readOnly = $false,
    [switch] $confirm = $true
)
$InformationPreference = "continue"
&("$PSScriptRoot\Start.ps1")
$scriptStartTime = Get-Date
if($readOnly -eq $false) 
{
    Warn-WillUpdate $env $environmentType $confirm
}

$context = Create-Context $env -environmentType $environmentType
try
{
    write-host "---- Looking for site field $fieldName ----"
    $web = $context.Web
    $context.Load($web)
    $listWeb = $context.Site.OpenWeb($lookupListUrl)
    [Microsoft.SharePoint.Client.List] $list = $listWeb.Lists.GetByTitle($lookupListName)
    $field = $web.Fields.GetByInternalNameOrTitle($fieldName)
    $context.Load($field)
    $context.Load($list)
    $context.Load($listWeb)
    $context.Load($web.Fields)
    
    $context.ExecuteQuery()
    $schema = $field.SchemaXml
    write-host "Current Schema:" $schema
    [Xml]$schemaXml = $schema
    $requiresUpdate = $false
    if($schemaXml.Field.Attributes["WebId"].'#text'.Replace("{","").Replace("}","") -ne $listWeb.Id)
    {
        Write-host "Found issue with Web Id, Is: $($schemaXml.Field.Attributes["WebId"].'#text') should be $($listWeb.Id)"
        write-host ""
        $schemaXml.Field.Attributes["WebId"].'#text' = $listWeb.Id.ToString()
        $requiresUpdate = $true
    }
    if($schemaXml.Field.Attributes["List"].'#text' -ne $list.Id.ToString())
    {
        Write-host "Found issue with List, Is: $($schemaXml.Field.Attributes["List"].'#text') should be $($list.Id.ToString())"
        $schemaXml.Field.Attributes["List"].'#text' = $list.Id.ToString()
        $requiresUpdate = $true
    }
    

    if($requiresUpdate -and $readOnly -eq $false)
    {
        $schema = $schemaXml.OuterXml
        write-host ""
        write-host "New Schema:" $schema
        write-host ""
        $field.SchemaXml = $schema
        $field.Update()
        $context.ExecuteQuery()
        write-host "Updated schema"
    }
    else {
        write-host "No changes made"
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
