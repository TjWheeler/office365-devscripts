#Script:	Get-CheckedOut.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.3
#Purpose:   Checks the Style Library and Master Pages library to see if any of the items are checked out to the current user or any user.
param(
    $env =  $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [boolean] $mineOnly = $true
)
&("$PSScriptRoot\Start.ps1")
$scriptStartTime = Get-Date

function Get-CheckedOutItems($context, $mineOnly, $list)
{
    $query = New-Object Microsoft.SharePoint.Client.CamlQuery
    if($mineOnly)
    {
        $query.ViewXml = "<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='CheckoutUser' /><Value Type='Integer'><UserID Type='Integer' /></Value></Eq></Where></Query></View>"
    }
    else {
        $query.ViewXml = "<View Scope='RecursiveAll'><Query><Where><IsNotNull><FieldRef Name='CheckoutUser' /></IsNotNull></Where></Query></View>"
    }
    $listItems = $list.GetItems($query)
    $context.Load($listItems)
    Execute-WithRetry $context
    return $listItems

}

$context = Create-Context $env -environmentType $environmentType
try
{
     write-host "---- Style Library Checked Out ----"
     $items = Get-CheckedOutItems $context $meOnly $context.Site.RootWeb.Lists.GetByTitle("Style Library")
     foreach($item in $items)
     {
        Write-Host "($($item.FieldValues.CheckoutUser.LookupValue)) $($item.FieldValues.FileRef)"
     }
     write-host "---- Master Page Library Checked Out ----"
     $items = Get-CheckedOutItems $context $meOnly $context.Site.GetCatalog([Microsoft.SharePoint.Client.ListTemplateType]::MasterPageCatalog)
     foreach($item in $items)
     {
        Write-Host "($($item.FieldValues.CheckoutUser.LookupValue)) $($item.FieldValues.FileRef)"
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


