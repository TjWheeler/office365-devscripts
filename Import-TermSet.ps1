#Script:	Import-TermSet.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
#Purpose:   Imports the TermSet from a previously exported xml file
param(
    $env = $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [String] $termStoreName = $(read-host "Please enter term store name or leave empty for default"),
    [Array]  $groupName = $(read-host "Please enter group name or leave empty for default"),
    [string] $filename = $(read-host "Please enter file path and name"),
    [int]    $language = 1033,
    [switch] $respectIdentifiers = $false,
    [switch] $confirm = $true
)
&("$PSScriptRoot\Start.ps1")
$context = Create-Context $env -environmentType $environmentType
Warn-WillUpdate $env $environmentType $confirm 

function OutputValidTermStores([Microsoft.SharePoint.Client.Taxonomy.TaxonomySession] $taxonomySession)
{
    $termStores = $taxonomySession.TermStores
    $context.Load($termStores);
    $context.ExecuteQuery();
    foreach($store in $termStores)
    {
        Write-Host ([Microsoft.SharePoint.Client.Taxonomy.TermStore]$store).Name
    }
}
Function WriteTerm ([System.IO.StreamWriter] $writer, [Microsoft.SharePoint.Client.Taxonomy.Term] $term, $indentLevel)
{
    WriteXml $writer "<Term name='$($term.Name)' id='$($term.Id)'>" $indentLevel #Term
    
    if($term.Terms.AreItemsAvailable)
    {
        $childTerms = $term.Terms
        $context.Load($childTerms)
        WriteXml $writer "<Terms>" ($indentLevel + 1)
        foreach($childTerm in $childTerms)
        {
            WriteTerm $writer $childTerm ($indentLevel + 2)

        }
        WriteXml $writer "</Terms>" ($indentLevel + 1)
    }
    WriteXml $writer "</Term>" $indentLevel #Term

}

function Import-Terms($termSetElement, $terms, $parent )
{
    foreach($termElement in $termSetElement.Terms.Term)
    {
        $term = $terms | Where-Object { $_.Name -eq $termElement.name }
        if($term -eq $null)
        {
            Write-Host "Creating new Term '$($termElement.name)'" -ForegroundColor Green
            if($respectIdentifiers)
            {
                $id = [Guid]::Parse($termElement.id)
            }
            else 
            {
                $id = New-Guid
            }
            $term = $parent.CreateTerm($termElement.name, $language, $id)
        }
        if(([array]$termElement.Terms).Length -gt 0)
        {
            $context.Load($term.Terms);
            $context.ExecuteQuery()
            Write-Host "Checking child terms for '$($termElement.name)'" 
            Import-Terms $termElement $term.Terms $term
        }
    }
    try 
    {
        $context.ExecuteQuery()
    }
    catch
    {
        if($_.Exception.Message.Contains("TermStoreEx:Failed to read from or write to database") -and $respectIdentifiers)
        {
            Write-Host "SharePoint refused to acknowledge the update.  This is most likely because the ID(Guid) specified already exists in another TermStore/TermSet.  Try -`$respectIdentifiers:`$false instead." -ForegroundColor Cyan
            throw
        }
    }
}
function Import-TermSet([Microsoft.SharePoint.Client.Taxonomy.TaxonomySession] $session, [Microsoft.SharePoint.Client.Taxonomy.TermGroup] $termGroup, $termSetElement)
{
    $termSets = $termGroup.TermSets
    $context.Load($termSets);
    $context.ExecuteQuery();
    $termSet = $termSets | Where-Object { $_.Name -eq $termSetElement.name}
    if($termSet -ne $null) 
    {
        Write-Host "Checking for updates to Term Set '$($termSet.Name)'"
    }
    else 
    {
        Write-Host "Creating new Term Set '$($termSetElement.name)'" -ForegroundColor Green
        if($respectIdentifiers)
        {
            $id = [Guid]::Parse($termSetElement.id)
        }
        else 
        {
            $id = New-Guid
        }
        $termSet = $termGroup.CreateTermSet($termSetElement.name, $id, $language)
    }
    $context.Load($termSet)
    $context.Load($termSet.Terms)
    $context.ExecuteQuery()
    Import-Terms $termSetElement $termSet.Terms $termSet
}
if((Test-Path $filename) -eq $false)
{
    throw "Could not find file $filename"
    return
}
[xml]$xml = Get-Content $filename -ErrorAction:stop

try
{
    $taxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($context);
    $context.Load($taxonomySession);    
    $context.ExecuteQuery();
    try 
    {
         if([string]::IsNullOrEmpty($termStoreName))
        {
            $termStore = $taxonomySession.GetDefaultSiteCollectionTermStore();
        } 
        else 
        {
            $termStore = $taxonomySession.TermStores.GetByName($termStoreName);
        }
        $context.Load($termStore);
        $context.ExecuteQuery();
    }
    catch
    {
        Write-Warning "Couldn't find a term store matching the name $termStoreName, valid names are:"
        OutputValidTermStores($taxonomySession)
        return
    }
    $termGroups = $termStore.Groups
    $context.Load($termGroups)
    $context.ExecuteQuery();

    if([string]::IsNullOrEmpty($groupName))
    {
        $termGroup = $termStore.GetSiteCollectionGroup($context.Site, $true);
    }
    else 
    {
        $termGroup = $termGroups | Where-Object { $_.Name -eq $groupName };
        if($termGroup -eq $null)
        {
            Write-Warning "Couldn't find a term group matching the name $groupName, valid names are:"
            $termGroups | Select-Object { $_.Name } | fl
            return
        }
    }
    $context.Load($termGroup);
    $context.Load($termGroup.TermSets);
    $context.ExecuteQuery();

    foreach($termSet in $xml.xml.TermStore.Group.TermSet)
    {
        Import-Termset $taxonomySession $termGroup $termSet
    }
}
catch
{
    Write-Error "Error:$_"
}
finally 
{
    if($context -ne $null) 
    {
        $context.Dispose()
        $context = $null
    }
}
