#Script:	Set-Feature.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
#Purpose: Enable/Disable Side Loading apps

param(
    $env = $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [boolean] $enabled = $true,
    [switch] $confirm = $true
)
$InformationPreference = "continue"
& ("$PSScriptRoot\start.ps1")
Check-Environment $env $environmentType
Warn-WillUpdate $env $environmentType $confirm 
$context = Create-Context $env -environmentType $environmentType


try
{
    $isEnabled = [Microsoft.SharePoint.Client.appcatalog]::IsAppSideloadingEnabled($context);  
    $context.ExecuteQuery()
    $featureGuid = [Guid]::Parse("AE3A1339-61F5-4f8f-81A7-ABD2DA956A7D")
    if($isEnabled.Value -eq $false -and $enabled)
    {
        $context.Site.Features.Add($featureGuid, $false, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None)
    } 
    else {
        $context.Site.Features.Remove($featureGuid, $true)
    }
    $context.ExecuteQuery()
}
finally
{
    if($context -ne $null)
    {
        $context.Dispose()
        $context = $null
    }
    write-host "Script Complete"
}
