#Script:	Get-UserProfile.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.3
#Purpose:   Output the properties of a user.
#notes:     
param(
    $env =  $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [string] $loginName = $(Read-Host "Specify user login name or partial name")
)
&("$PSScriptRoot\Start.ps1")
$scriptStartTime = Get-Date

function Get-UserProfile($loginName)
{ 
    $siteUsers = $context.Site.RootWeb.SiteUsers
    $context.Load($siteUsers)
    Execute-WithRetry $context
    Write-Information "Connecting to PeopleManager"
    [Microsoft.SharePoint.Client.UserProfiles.PeopleManager] $peopleManager = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager -ArgumentList @($context)    
    $userList = New-Object System.Collections.Generic.List[System.Object]
    $batchCount = 0;
    
    for($i = 0; $i -lt $siteUsers.Count; $i++)
    {
        $user = $siteUsers[$i]
        if($user.Email -eq "") {continue}
        if($user.LoginName.ToLower().Contains($loginName)) 
        {
            Write-Information "Loading user profile  $($user.LoginName) - $($user.Email)"
            try 
            {
                $userRecord = @{
                    Username = $user.LoginName
                    Properties = $peopleManager.GetPropertiesFor($user.LoginName)
                    User = $context.Web.EnsureUser($user.LoginName)
                }
                $context.Load($userRecord.Properties)
                $context.Load($userRecord.User)
                $userList.Add($userRecord)
                Execute-WithRetry $context
            }
            catch
            {
                Write-Error $_
            }
        }
        
    }
    return $userList
}

$context = Create-Context $env -environmentType $environmentType
try
{
     write-host "---- Looking for user profile for $loginName ----"
     [Array]$profiles = Get-UserProfile $loginName
     if($profiles.Count -eq 0) 
     {
        Write-Warning "$loginName not found"
     } 
     else {
        Write-Host "User Profile - $loginName"
        foreach($profile in $profiles)
        {
            Write-Host "User Profile Properties - $($profile.Username)"
            $profile.Properties
            $profile.Properties.UserProfileProperties | ft Key, Value
            Write-Host "================================================="
            Write-Host ""
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
