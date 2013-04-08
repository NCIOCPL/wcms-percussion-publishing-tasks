# Load the Notification XML
$doc = [xml](get-content syndicationlist.xml);

$docNsMgr = new-object Xml.XmlNamespaceManager $doc.NameTable

$docNsMgr.AddNamespace("catalog", "http://www.cdc.gov/socialmedia/syndication/SyndicationCatalog.xsd");
$docNsMgr.AddNamespace("content", "http://www.cdc.gov/socialmedia/syndication/SyndicationContent.xsd");

# Make a copy of the outermost Catalog node and CatalogSource.
# We'll then copy individual the CatalogItem nodes one at a time,
# each replacing the one before.
$noticeEnvelope = $doc.DocumentElement.CloneNode($False);
$catalogSource = $doc.SelectSingleNode("//catalog:CatalogSource", $docNsMgr);
if($catalogSource -eq $null) {echo "Error: Cannot locate CatalogSource element.";}
$bucket = $noticeEnvelope.AppendChild( $catalogSource );

# Build notification messages for each catalog item.
$catalogItems = $doc.SelectNodes("//catalog:CatalogItem", $docNsMgr);
$catalogItems | ForEach-Object {

	$bucket = $noticeEnvelope.AppendChild($_);
	
	$noticeEnvelope.OuterXml | Out-file (".\DebugOut\" + $_.CatalogId + ".xml") -Encoding "UTF8";

	$bucket = $noticeEnvelope.RemoveChild($_);
}