#Script:	Set-ModernExperience.ps1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.1
#Credits: https://sharepoint.stackexchange.com/questions/188014/enable-new-list-experience-on-document-library-programmatically/195126
#Purpose: Disable the SharePoint Modern Experience
#Example: .\sp-testconnection.ps1 twdev1 dev
param(
    $env = $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [ValidateSet("Enabled", "Disabled")]
    [string] $enabled = $(Read-Host "Specify Enabled/Disabled")
)
$InformationPreference = "continue"
& ("$PSScriptRoot\start.ps1")
$context = Create-Context $env -environmentType $environmentType
$web = $context.Web
$context.Load($web)
#Function from https://sharepoint.stackexchange.com/questions/188014/enable-new-list-experience-on-document-library-programmatically/195126
function Set-NewExperience{
    <#
      .Synopsis
       Sets the document library experience for a site or web
      .DESCRIPTION
       Sets the document library experience for a site or web
      .EXAMPLE
       The following would disable the new experience for an entire site collection
       Set-NewExperience -Url "https://tenant.sharepoint.com/teams/eric" -Scope Site -State Disabled
      .EXAMPLE
       The following would disable the new experience for a single web
       Set-NewExperience -Url "https://tenant.sharepoint.com/teams/eric" -Scope Web -State Disabled
      .EXAMPLE
       The following would enable the new experience for an entire site collection
       Set-NewExperience -Url "https://tenant.sharepoint.com/teams/eric" -Scope Site -State Enabled -Context $clientContext
      .Link
      https://support.office.com/en-us/article/Switch-the-default-for-document-libraries-from-new-or-classic-66dac24b-4177-4775-bf50-3d267318caa9
    #>
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)][ValidateSet("Site", "Web")]
        [string]$Scope,
        [Parameter(Mandatory=$true)][ValidateSet("Enabled", "Disabled")]
        [string]$State,
    [Parameter(Mandatory=$true)]
        [Microsoft.SharePoint.Client.ClientContext]$context
    )

    Process{
        if($Scope -eq "Site"){
            # To apply the script to the site collection level, uncomment the next two lines.
            $site = $context.Site
            $featureguid = new-object System.Guid "E3540C7D-6BEA-403C-A224-1A12EAFEE4C4"
        }
        else{
            # To apply the script to the website level, uncomment the next two lines, and comment the preceding two lines.
            $site = $context.Web
            $featureguid = new-object System.Guid "52E14B6F-B1BB-4969-B89B-C4FAA56745EF" 
        }
        if($State -eq "Disabled")
        {
            # To disable the option to use the new UI, uncomment the next line.
            $site.Features.Add($featureguid, $true, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None)
            $message = "New library experience has been disabled on $URL"
        }
        else{
            # To re-enable the option to use the new UI after having first disabled it, uncomment the next line.
            # and comment the preceding line.
            $site.Features.Remove($featureguid, $true)
            $message = "New library experience has been enabled on $URL"
        }
        try{
            $context.ExecuteQuery()
            write-host -ForegroundColor Green $message
        }
        catch{
            Write-Host -ForegroundColor Red $_.Exception.Message
        }
    }
    
}

try
{
    Load-Context $context
    Set-NewExperience -Url $context.Url -Scope Site -State $enabled -Context $context 
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
