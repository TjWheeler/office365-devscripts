#Script:	Export-TermSet.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
#Purpose:   Exports the TermSet and generates xml for future import
param(
    $env = $(Read-Host "Specify environment name"),
    [ValidateSet("Dev","Test","UAT","Prod")]
    [String] $environmentType = $(Read-Host "Specify EnvironmentType Dev,Test,UAT,Prod"),
    [String] $termStoreName = $(read-host "Please enter term store name"),
    [Array]  $groupNames = $(read-host "Please enter group name"),
    [Array]  $termSetNames = $(read-host "Please enter term set name"),
    [string] $filename = $(read-host "Please enter file path and name")
)
&("$PSScriptRoot\Start.ps1")
$context = Create-Context $env -environmentType $environmentType


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
    $context.Load($term.Terms)
    $context.ExecuteQuery()
    if($term.Terms.Count -gt 0)
    {
        $childTerms = $term.Terms
        $context.Load($childTerms)
        $context.ExecuteQuery()
        WriteXml $writer "<Terms>" ($indentLevel + 1)
        foreach($childTerm in $childTerms)
        {
            WriteTerm $writer $childTerm ($indentLevel + 2)

        }
        WriteXml $writer "</Terms>" ($indentLevel + 1)
    }
    WriteXml $writer "</Term>" $indentLevel #Term

}
function ExportTermset([System.IO.StreamWriter] $writer, [Microsoft.SharePoint.Client.Taxonomy.TermSet] $termSet, $indentLevel)
{
    if($termSet -ne $null)
    {
        WriteXml $writer "<TermSet name='$($termSet.Name)' id='$($termGroup.Id)'>" ($indexLevel + 1)  #TermSet
        $context.Load($termSet)
        
        $childTerms = $termSet.Terms
        $context.Load($childTerms)
        $context.ExecuteQuery();
        WriteXml $writer "<Terms>" ($indentLevel + 1)
        foreach($term in $childTerms)
        {
            WriteTerm $writer $term ($indentLevel + 2)
        }
        WriteXml $writer "</Terms>" ($indentLevel + 1)
        WriteXml $writer "</TermSet>" ($indexLevel + 1) 

    }
}
function AppendNode($xml, $parentNode, $name)
{
    $node =  $xml.CreateNode("element", $name,"")
    $parentNode.AppendChild($node) | Out-Null
    return $node
}
function AppendAttribute($xml, $node, $name, $value)
{
    $attribute = $xml.CreateAttribute($name)
    $attribute.Value = $value
    $node.Attributes.Append($attribute) | Out-Null
    return $attribute
}
Function WriteXml([System.IO.StreamWriter] $writer, $value, [int] $tabs)
{
    for($i =0; $i -lt $tabs; $i++)
    {
       $writer.Write("`t")
    }
    $writer.WriteLine($value)
}
#Setup a stream and writer to deal with the Xml, as its easier than working with XmlDocuments
$fileStream = New-Object IO.FileStream($filename, [IO.FileMode]::Create)
$writer = New-Object IO.StreamWriter $fileStream
$writer.AutoFlush = $true
$writer.WriteLine("<xml version=`"1.0`" encoding=`"utf-8`">")
try
{
    $taxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($context);
    $context.Load($taxonomySession);    
    $context.ExecuteQuery();
    try 
    {
        $termStore = $taxonomySession.TermStores.GetByName($termStoreName);
        $context.Load($termStore);
        $context.ExecuteQuery();
    }
    catch
    {
        Write-Warning "Couldn't find a term store matching the name $termStoreName, valid names are:"
        OutputValidTermStores($taxonomySession)
        return
    }
    foreach($groupName in $groupNames)
    {
        $termGroup = $termStore.Groups.GetByName($groupName);
        $context.Load($termGroup);
        $termSets = $termGroup.TermSets
        $context.Load($termSets);
        $context.ExecuteQuery();
        $termSets | ForEach-Object { $context.Load($_) }
        $context.ExecuteQuery();
        WriteXml $writer "<Group name='$($termGroup.Name)' id='$($termGroup.Id)'>"
        foreach($setName in $termSetNames)
        {
            $termSet =  ($termSets | Where-Object {$_.Name -eq $setName })
            if($termSet -ne $null) 
            {
                ExportTermset $writer $termSet 1
            }
        }
        WriteXml $writer "</Group>"
    }
    WriteXml $writer "</xml>"
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
