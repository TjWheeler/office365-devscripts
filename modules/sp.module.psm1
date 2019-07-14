#Script:	sp.module.psm1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.1
#Import-Module -Name "Common.Module.psm1" -Force -DisableNameChecking 
$InformationPreference = "continue"
$libsPath = "$PSScriptRoot\..\libs"
function LoadCSOMLibraries($env)
{
    $typesLoaded = $false
    try 
    {
        if (("ClientContext" -as [Microsoft.SharePoint.Client.ClientContext]) -eq $null) {
	        $typesLoaded = $true
        }
    }
    catch 
    { 
        #ignore 
    }
    if($typesLoaded)
    {
        $basePath = [IO.Path]::GetFullPath($libsPath)
        $path = [IO.Path]::GetFullPath([Microsoft.SharePoint.Client.ClientContext].Assembly.Location)
        $verifyPath = [IO.Path]::GetFullPath("$basePath\CSOM\$($env.csomVersion)\lib\net45\Microsoft.SharePoint.Client.dll")
        if($path -ne $verifyPath)
        {
            throw "Error - CSOM Already Loaded.  CSOM Library mismatch. CSOM has already been loaded at location $path.  You must close the PowerShell session to use the requuired version ($($env.csomVersion))."
        }
        #Types already loaded
        return
    }
    else 
    {
        Add-Type -LiteralPath ("$libsPath\CSOM\$($env.csomVersion)\lib\net45\Microsoft.SharePoint.Client.dll") -PassThru | out-null
        Add-Type -LiteralPath ("$libsPath\CSOM\$($env.csomVersion)\lib\net45\Microsoft.SharePoint.Client.RunTime.dll") -PassThru | out-null
        Add-Type -LiteralPath ("$libsPath\CSOM\$($env.csomVersion)\lib\net45\Microsoft.SharePoint.Client.Taxonomy.dll") -PassThru | out-null
        Add-Type -LiteralPath ("$libsPath\CSOM\$($env.csomVersion)\lib\net45\Microsoft.SharePoint.Client.UserProfiles.dll") -PassThru | out-null
        Add-Type -LiteralPath ("$libsPath\CSOM\$($env.csomVersion)\lib\net45\Microsoft.SharePoint.Client.WorkflowServices.dll") -PassThru | out-null
    }
}
function Create-Context (
    [String] $env = $null,
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $null
)
{
    $environment = Get-Environment $env $environmentType
    LoadCSOMLibraries $environment
    Write-Information "Loaded environment $($environment.Name):$($environment.EnvironmentType)"
    $securePassword = $environment.encryptedPassword | ConvertTo-SecureString
    if($environment.credentialType -eq "SharePointOnline")
    {
        $credential = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($environment.username, $securePassword) -ErrorAction:Stop
    }
    elseif($environment.credentialType -eq "Network")
    {
        $credential = New-Object System.Net.NetworkCredential($username, $securePassword) -ErrorAction:Stop
    }
    else 
    {
        throw "Unknown credentialType"
    }
    $context = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext -ArgumentList ($environment.siteUrl)
    $context.Credentials = $credential
    return $context
}
function Load-Context([Microsoft.SharePoint.Client.ClientContext] $context)
{
    $web = $context.Web
    $context.Load($web)
    write-host "Attempting connection to $($context.Url)"
    $context.ExecuteQuery()
    write-host "Successfully conntected to $($web.Url)" -f Green
}
function Execute-WithRetry([Microsoft.SharePoint.Client.ClientContext] $context) 
{
    $retry = 1;
    while($retry -lt 5) 
    {
        try
        {
            $context.ExecuteQuery()
            return
        }
        catch
        {
            if($_.Exception.Message -match "(429)")
            {
                $sleepTime = $retry * 5
                write-warning "We are being throttled, sleeping for $sleepTime of attempt ($retry of 5)"
                Sleep ($retry * 5)
                $retry++    
                continue
            }
            if($_.Exception.Message -match "(503)")
            {
                $sleepTime = $retry * 5
                write-warning "We are got back a 503 from SharePoint, will retry, sleeping for $sleepTime of attempt ($retry of 5)"
                Sleep ($retry * 5)
                $retry++    
                continue
            }
            throw
        }
    }
    throw "Throttling or Server Error as caused this process to terminate even after the retries"
}
Function DownloadFile($context, $fileUrl, $downloadLocation)
{
  $web = $context.Web
  $file = $web.GetFileByServerRelativeUrl($fileUrl)
  $context.Load($file)
  Execute-WithRetry $context;
  if($file.Exists -eq $false)
  {
    throw "File does not exist $fileUrl"
  }
  try {
        if($context.HasPendingRequest)
        {
          Execute-WithRetry $context
        }
        $fileInfo = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($context, $fileUrl)
        [IO.Stream]$sharePointStream = $fileInfo.Stream
        $fileStream = new-object IO.FileStream($downloadLocation, [IO.FileMode]::Create)
        $sharePointStream.CopyTo($fileStream)
        $fileStream.Close()
        Write-host "Created file $downloadLocation" 
  }
  finally {
    if($fileInfo -ne $null -and $fileInfo.Stream -ne $null)
    {
      $fileInfo.Stream.Dispose()
    }
    if($sharePointStream -ne $null)
    {
        $sharePointStream.Dispose()
    }
    
  }

}	