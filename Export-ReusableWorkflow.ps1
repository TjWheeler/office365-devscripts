#Script:	Export-ReusableWorkflow.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
#Purpose:   Exports the a workflow along with any Identifiers used.  This information is then used to modify the workflow on Import to another environment
#Example: 
param(
    $env = "kpc", # $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [string] $path = $(read-host "Please enter a directory path where the files will be exported to"),
    [Array]  $workflows = $(throw "Please enter name(s) of reusable workflows to export."),
)
&("$PSScriptRoot\Start.ps1")
$context = Create-Context $env -environmentType $environmentType



Function WriteXml([System.IO.StreamWriter] $writer, $value, [int] $tabs)
{
    for($i =0; $i -lt $tabs; $i++)
    {
       $writer.Write("`t")
    }
    $writer.WriteLine($value)
}

Function DeleteDocument([string]$serverRelativeUrl)
{
    $file = $context.Site.RootWeb.GetFileByServerRelativeUrl($serverRelativeUrl)
    $context.Load($file)
    try
    {
        $context.ExecuteQuery()
        $file.DeleteObject()
        $context.ExecuteQuery();
    }
    catch
    {
        if($_.Exception.Message.Contains("File Not Found"))
        {
            return
        }
        throw
    }
}
Function PackageWorkflow([Microsoft.SharePoint.Client.WorkflowServices.WorkflowDeploymentService] $workflowDeploymentService, [Guid] $definitionId, $filename, $title, $description)
{
    if(-not $filename.ToLower().EndsWith(".wsp"))
    {
        $filename += ".wsp"
    }
    $url = $context.Site.ServerRelativeUrl
    if(-not $url.EndsWith("/"))
    {
        $url += "/"
    }
    $url += "SiteAssets/$filename"
    DeleteDocument $url
    $result = $workflowDeploymentService.PackageDefinition($definitionId, $filename, $title, $description)
    $context.ExecuteQuery()
    return $url
}

function ExportWorkflows()
{
    $workflowServicesManager = New-Object Microsoft.SharePoint.Client.WorkflowServices.WorkflowServicesManager $context, $context.Web
    $workflowDeploymentService = $workflowServicesManager.GetWorkflowDeploymentService()
    $publishedWorkflowDefinitions = $workflowDeploymentService.EnumerateDefinitions($true)
    $context.Load($publishedWorkflowDefinitions)
    $context.ExecuteQuery()
    
    foreach ($workflowDefinition in $publishedWorkflowDefinitions) {
        if($workflows.Contains($workflowDefinition.DisplayName))
        {
            Write-Host "$($workflowDefinition.Id.ToString()) - $($workflowDefinition.DisplayName)"
            $fileUrl = PackageWorkflow $workflowDeploymentService $workflowDefinition.Id $workflowDefinition.DisplayName $workflowDefinition.DisplayName "Exported by script"
            Write-Host "Downloading Workflow $fileUrl"
            DownloadFile $context $fileUrl "$path\$($workflowDefinition.DisplayName).wsp"
            ExportWorkflowDetails $context "$path\$($workflowDefinition.DisplayName).wsp" $workflowDefinition
        }
    }
}
ExportWorkflowDetails($context, $filePath, $workflowDefinition)
{
    
}


function Test()
{
    $workflowServicesManager = New-Object Microsoft.SharePoint.Client.WorkflowServices.WorkflowServicesManager $context, $context.Web
    $workflowDeploymentService = $workflowServicesManager.GetWorkflowDeploymentService()
    $workflowSubscriptionService = $workflowServicesManager.GetWorkflowSubscriptionService()


    #// get all installed workflows
    $publishedWorkflowDefinitions = $workflowDeploymentService.EnumerateDefinitions($true)
    $context.Load($publishedWorkflowDefinitions)
    $context.ExecuteQuery()

    #// display list of all installed workflows
    WriteXml $writer "<WorkflowDefinitions>"
    $defs = $publishedWorkflowDefinitions | ConvertTo-Xml
    foreach($def in $defs.Objects.Object)
    {
        WriteXml $writer $def.OuterXml
    }
    WriteXml $writer "</WorkflowDefinitions>"

    
    foreach ($workflowDefinition in $publishedWorkflowDefinitions) {
        Write-Host "$($workflowDefinition.Id.ToString()) - $($workflowDefinition.DisplayName)"
        if($workflows.Contains($workflowDefinition.DisplayName))
        {
            PackageWorkflow $workflowDeploymentService $workflowDefinition.Id $workflowDefinition.DisplayName $workflowDefinition.DisplayName "Exported by script"
        }
        #Get associations
        $workflowAssociations = $workflowSubscriptionService.EnumerateSubscriptionsByDefinition($workflowDefinition.Id);
        $context.Load($workflowAssociations);
        $context.ExecuteQuery();
        foreach ($association in $workflowAssociations) {
          Write-Host "$($association.Id) $($association.Name)"
        }
    }
}



try
{
    $context.Load($context.Site)
    $context.ExecuteQuery()
    #Setup a stream and writer to deal with the Xml, as its easier than working with XmlDocuments
    $filename = "C:\Temp\workflowtemp.xml"
    $fileStream = New-Object IO.FileStream($filename, [IO.FileMode]::Create)
    $writer = New-Object IO.StreamWriter($fileStream, [System.Text.Encoding]::UTF8)
    $writer.AutoFlush = $true
    
    $writer.WriteLine("<xml version=`"1.0`" encoding=`"utf-8`">")
    
    ExportWorkflows
    
    WriteXml $writer "</xml>"
    Write-Host -ForegroundColor Green "Created $filename successfully"
}
catch
{
    Write-Error "Error:$_"
}
finally 
{
    if($fileStream -ne $null)
    {
        $fileStream.Dispose()
    }
    if($context -ne $null) 
    {
        $context.Dispose()
        $context = $null
    }
}



