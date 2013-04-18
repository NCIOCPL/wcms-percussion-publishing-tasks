Add-Type -AssemblyName System.Web;

function Main(){
	LoadConfig("app.config");

	# Load the Notification XML
	$doc = [xml](get-content $appSettings["syndicationFileName"] -encoding "UTF8");

    SendNotifications $doc
}

# Splits the master notification document into multiple small documents
# and transmits them to the syndication network.
function SendNotifications($notificationList) {
	$publishUrl = GetPublishUrl;

	[Xml.XmlNamespaceManager] $docNsMgr = GetNamespaceManager $notificationList;


	# Make a copy of the outermost Catalog node and CatalogSource.
	# We'll then copy individual the CatalogItem nodes one at a time,
	# each replacing the one before.
    $noticeEnvelope = CopyEnvelopeXml $docNsMgr $notificationList

	# Build notification messages for each catalog item.
	$catalogItems = $notificationList.SelectNodes("//catalog:CatalogItem", $docNsMgr);
	$catalogItems | ForEach-Object {
        # Fill in a specific content item
        [void]$noticeEnvelope.AppendChild($_);

        $noticeEnvelope.OuterXml | Out-file (".\DebugOut\" + $_.Id + ".xml") -Encoding "UTF8";

        # Create a set of fields to send.
	    $fields = @{} # Empty hashtable
	    $fields.Add("xml", $noticeEnvelope.OuterXml);
	    Execute-HTTPPostCommand $publishUrl $fields

        # Remove the content item so we can reuse the envelope.
        $bucket = $noticeEnvelope.RemoveChild($_);
    }
}

# Builds the XML namespace manager for parsing the catalog XML.
function GetNamespaceManager($document){
   	$nsManager = new-object Xml.XmlNamespaceManager $doc.NameTable
	[void]$nsManager.AddNamespace("catalog", "http://www.cdc.gov/socialmedia/syndication/SyndicationCatalog.xsd");
	[void]$nsManager.AddNamespace("content", "http://www.cdc.gov/socialmedia/syndication/SyndicationContent.xsd");

    # Freaking big kludge.  Putting a comma in the return here puts the object into
    # an array, causing the namespace manager to be returned as the proper type.
    # Otherwise, it would end up coming out the other side as an Object array.
    return , [Xml.XmlNamespaceManager]$nsManager;
}

function CopyEnvelopeXml($docNsMgr, $document) {
    # Outermost XML elements.
	$noticeEnvelope = $document.DocumentElement.CloneNode($False);

    # Copy the catalogSource node.
	$catalogSource = $document.SelectSingleNode("//catalog:CatalogSource", $docNsMgr);
	if($catalogSource -eq $null) {Throw "Error: Cannot locate CatalogSource element.";}
	[void]$noticeEnvelope.AppendChild( $catalogSource );

    return $noticeEnvelope;    
}

function GetPublishUrl(){
	return $appSettings["syndicationServer"] + $appSettings["syndicationPublishUrl"];
}

# Sends an HTTP POST request to the specified URL.
#
# $targetUrl - URL to send the post to.
# $fields - Hashlist of name value pairs to send as fields.
function Execute-HTTPPostCommand($targetUrl, $fields) {

    $webRequest = [System.Net.WebRequest]::Create($targetUrl)
    $webRequest.ContentType = "application/x-www-form-urlencoded";
	$webrequest.Referer = "CM_Syndication";
    $webRequest.Method = "POST"

    $requestStream = $webRequest.GetRequestStream()    
    $first = $true;
	$fields.Keys | ForEach {
		$data = $_ + "=" +  [System.Web.HttpUtility]::UrlEncode($fields[$_]);
        if(-not $first ){
            $data = "&" + $data
        }

		$bytes = [System.Text.Encoding]::UTF8.GetBytes($data);
		$requestStream.Write($bytes, 0, $bytes.length);
        $first = $false;
	}
    $requestStream.Close()

    [System.Net.WebResponse] $resp = $webRequest.GetResponse();
	
	if(200 -ne [int]$resp.StatusCode){
		Echo "Expected status 200, received instead: " [int]$resp.StatusCode
	}
	
	$resp.Close();
	
    return $results;
}

# Loads configuration data in a format similar to that used by .Net.
# Parses through an appSettings section, looking for keys added with an <add> element
# and stores values in a global hashtable ($appSettings) with lookups based on the key attribute.
#
# Based on code from http://rkeithhill.wordpress.com/2006/06/01/creating-and-using-a-configuration-file-for-your-powershell-scripts/
function LoadConfig(){
    param($path = $(throw "You must specify a config file"))

    $global:appSettings = @{}
    $config = [xml](get-content $path)
    foreach ($addNode in $config.configuration.appsettings.add) {
        if ($addNode.Value.Contains(‘,’)) {
            # Array case
            $value = $addNode.Value.Split(‘,’)
            for ($i = 0; $i -lt $value.length; $i++) { 
                $value[$i] = $value[$i].Trim() 
            }
        }
        else {
            # Scalar case
            $value = $addNode.Value
        }
        $global:appSettings.Add($addNode.Key, $value)
    }
}


Main;