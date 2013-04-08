function Main(){
	LoadConfig("app.config");
	$publishUrl = GetPublishUrl;

	# Load the Notification XML
	$doc = [xml](get-content $appSettings["syndicationFileName"]);

	Execute-HTTPPostCommand $publishUrl $doc
}

function GetPublishUrl(){
	return $appSettings["syndicationServer"] + $appSettings["syndicationPublishUrl"];
}

# Sends and HTTP POST request to the specified URL.
#
# $targetUrl - URL to send the post to.
# $data - data to transmit with the post.
function Execute-HTTPPostCommand($targetUrl, $data) {

    $webRequest = [System.Net.WebRequest]::Create($targetUrl)
    $webRequest.ContentType = "text/html"
    $PostStr = [System.Text.Encoding]::UTF8.GetBytes($data)
    $webrequest.ContentLength = $PostStr.Length
    $webRequest.ServicePoint.Expect100Continue = $false

    $webRequest.PreAuthenticate = $true
    $webRequest.Method = "POST"

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($PostStr, 0,$PostStr.length)
    $requestStream.Close()

    [System.Net.WebResponse] $resp = $webRequest.GetResponse();
    $rs = $resp.GetResponseStream();
    [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs;
    [string] $results = $sr.ReadToEnd();
	$rs.Close();
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