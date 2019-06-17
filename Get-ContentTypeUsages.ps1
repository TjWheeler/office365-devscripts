#Script:	Get-ContentTypeUsages.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
#Purpose:   Recurse the web structure and locate any usages of the content type
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


function FindCTUsages([Microsoft.SharePoint.Client.Web] $web, $name, $contentTypeId)
{
    write-host "---- Looking for usages of content type $name in $($web.Url) ----"
    $lists = $web.Lists
    $context.Load($lists)
    Execute-WithRetry $context
    
    foreach($list in $lists)
    {
        $context.Load($list)
        $context.Load($list.ContentTypes)
        Execute-WithRetry $context
        foreach($ct in $list.ContentTypes)
        {
            if($ct.Id.StringValue.ToLower().StartsWith($contentTypeId.ToLower()))
            {
                Write-Host -ForegroundColor Green "Found usage of $name at: $($list.ParentWebUrl) - $($list.Title)"
            }
        }

    }
}
function Get-ContentType($name)
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
        return $ct
    }     
    return $null

}
function RecurseWebs([Microsoft.SharePoint.Client.Web] $web, $name, $contentTypeId)
{
    $context.Load($web)
    Execute-WithRetry $context
    FindCTUsages $web $name $contentTypeId
    foreach($subWeb in $webs)
    {
        RecurseWebs $subWeb $name $contentTypeId
    }
}

$context = Create-Context $env -environmentType $environmentType

try
{
    $ct = Get-ContentType $name
    if($ct -eq $null)
    {
        Write-Error "Could not find $name Content Type"
        return
    }
    Write-Information "Found Content Type $name with ID $($ct.Id.StringValue)   "
    Write-Information "Recursing Web Structure"
    RecurseWebs $context.Site.RootWeb $name $ct.Id.StringValue
  
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
