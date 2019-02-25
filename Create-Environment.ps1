#Script:	Create-Environment.ps1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.2
#Purpose: Create/Update an environment file with encrypted passwords
#Remarks: An environment file is named [EnviornmentName].[environmentType].environment and stores data in JSON format
#       : Environment files are used by other scripts to get credentials
#Example: .\create-environment.ps1 -siteUrl "https://mytenancy.sharepoint.com/sites/mysitecollection" -name "dev1" -username "my@email.com" -credentialType SharePointOnline -environmentType Dev -csomVersion:Online
param(
    [String] $siteUrl = $(Read-Host "Specify SiteUrl"),
    [String] $username = $(Read-Host "Specify Username"),
    [String] $password = $null,
    [String] $name = $(Read-Host "Specify Environment Name"),
    [ValidateSet("Network","SharePointOnline")]
    [String] $credentialType = "SharePointOnline",
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify Environment Type Dev, Test, UAT, Prod"),
    [ValidateSet("Online","2013","2016","2019")]
    [String] $csomVersion = $(Read-Host "Specify CSOM Version Online, 2013, 2016, 2019")
)
&("$PSScriptRoot\Start.ps1")
$envPath = "$PSScriptRoot\env"
$filename = "$envPath\$name.$environmentType.environment"
$environment = $null
$schemaVersion = "1"
$securePassword = $null
if([string]::IsNullOrEmpty($password))
{
    $psCredential = Get-Credential $username    
    $securePassword = Encrypt-PasswordFromSecureString $psCredential.Password
    $username = $psCredential.UserName
} 
else 
{
    $securePassword = Encrypt-PasswordFromString $password
}

function Validate-Environment($toValidate)
{
    #TODO: validate url and sponline username contains @.  
}
function Encrypt-Password([SecureString]$password)
{
    return Encrypt-PasswordFromSecureString $password
}

if(Test-Path $filename)
{
    $jsonData = get-content $filename
    $environment = $jsonData | ConvertFrom-Json 
    $environment.siteUrl = $siteUrl
    $environment.username = $username
    $environment.encryptedPassword = $securePassword
    $environment.name = $name
    $environment.credentialType = $credentialType
    $environment.environmentType = $environmentType
    $environment.schemaVersion = $schemaVersion
    $environment.csomVersion = $scomVersion
}
else 
{
    $environment = @{
        schemaVersion = $schemaVersion
        siteUrl = $siteUrl
        username = $username
        encryptedPassword = $securePassword
        name = $name
        credentialType = $credentialType
        environmentType = $environmentType
        csomVersion = $csomVersion
    }
}
Validate-Environment $environment
if(-not [IO.Directory]::Exists($envPath))
{
    New-Item -ItemType directory -Path $envPath
}
$environment | ConvertTo-Json | set-content $filename

