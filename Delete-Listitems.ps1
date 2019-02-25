#Script:	Delete-Listitems.ps1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.2
#Purpose: Delete all list items, even if 5000 item threshold limit has been hit.
#Remarks: Uses CSOM to delete items in batches.
param(
    $env = $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [String] $listname = "FAQ", # $(Read-Host "Specify List Name"),
    [int] $batchSize = 50,
    [int] $batchSleepSeconds = 1,  #how many seconds to sleep between batches.  This can help if we get throttled (429 response).
    [switch] $confirm = $true
)
$InformationPreference = "Continue"
&("$PSScriptRoot\Start.ps1")
Check-Environment $env $environmentType
Warn-WillUpdate $env $environmentType $confirm 
Add-Type -AssemblyName System.Web
$scriptStartTime = Get-Date
$rowLimit = 4999


function Get-ViewFields()
{
    return "<ViewFields><FieldRef Name='ID'></FieldRef></ViewFields>"
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
            throw
        }
    }
    throw "Throttling as caused this process to terminate even after the retries"
}
function Delete-Items($maxId)
{
    $totalDeletions = 0
    $currentId = $maxId
    [Microsoft.SharePoint.Client.Web] $web = $context.Web
    $list = $web.Lists.GetByTitle($listname)
    [Microsoft.SharePoint.Client.CamlQuery] $query = New-Object Microsoft.SharePoint.Client.CamlQuery
    while($currentId -gt 0)
    {
        $lastId = [Math]::Max($currentId - $rowLimit, 0);
        $query.ViewXml = 
@"
    <View>$(Get-ViewFields)
        <Query>
            <Where>
                <And>
                    <Leq>
                        <FieldRef Name='ID'></FieldRef><Value Type='Integer'>$($currentId)</Value>
                    </Leq> 
                    <Geq>
                        <FieldRef Name='ID'></FieldRef><Value Type='Integer'>$($lastId)</Value>
                    </Geq>
                </And> 
            </Where>
            <OrderBy>
                <FieldRef Name='ID' Ascending="TRUE"></FieldRef>
            </OrderBy>
        </Query>
        <RowLimit>$rowLimit</RowLimit>
    </View>
"@
        $items = $list.GetItems($query)
        $context.Load($items)
        Write-Information "Looking for items with an ID between $lastId and $currentId"
        Execute-WithRetry $context
        $totalItems = $items.Count
        if($totalItems -gt 0)
        {
            Write-Information "Deleting $($items.Count) items"
            $batchCount = 0
            while($items.Count -gt 0)
            {
                $items[0].DeleteObject()
                $totalDeletions++
                $batchCount++
                if($batchCount -ge $batchSize) 
                {
                    Write-Information "Commiting deletion batch with $batchCount items"
                    Execute-WithRetry $context
                    $batchCount = 0
                    Sleep $batchSleepSeconds
                }
            }
            if($batchCount -gt 0)
            {
                Write-Information "Commiting remaining deletions"
                Execute-WithRetry $context
            }
        }
        $currentId = [Math]::Max($currentId - $rowLimit,0);
    }
    Write-Information "Deleted a total of $totalDeletions list items from $listname"
}
function Get-MaxID([Microsoft.SharePoint.Client.ClientContext] $context, $listname)
{
    [Microsoft.SharePoint.Client.Web] $web = $context.Web
    $list = $web.Lists.GetByTitle($listname)
    [Microsoft.SharePoint.Client.CamlQuery] $query = New-Object Microsoft.SharePoint.Client.CamlQuery
    $query.ViewXml = 
@"
    <View>$(Get-ViewFields)
        <Query>
          <OrderBy>
            <FieldRef Name='ID' Ascending="FALSE"></FieldRef>
          </OrderBy>
       </Query>
       <RowLimit>1</RowLimit>
    </View>
"@
    $items = $list.GetItems($query)
    $context.Load($items)
    Execute-WithRetry $context
    $totalItems = $items.Count
    if($totalItems -eq 0)
    {
        return $null
    }
    Write-Information "Max ID is $($items[0].ID)"
    return $items[0].ID
}

#Main entry point
$context = Create-Context $env -environmentType $environmentType
try
{
    Load-Context $context
    $maxId = Get-MaxID $context $listname
    if($maxId -eq $null)
    {
        Write-Information "No data to delete"
        return
    }
    Delete-Items $maxId
    Write-Information "Script Complete"
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







