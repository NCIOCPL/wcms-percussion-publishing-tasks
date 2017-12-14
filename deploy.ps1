<#
    .SYNOPSIS
        Deploys /publishing to /content for a site and subsite.
    .DESCRIPTION
        Deploys the content ready for publishing in /publishing to the published
        content folder /content.
        Deploys both Live and Preview content for CancerGov, TCGA, DCEG, Proteomics, and Imaging.
        Deploys content for FlatSites.    
    .PARAMETER sitename
        Name of the site published content to deploy
    .PARAMETER subsite
        Live or Preview (CDESite), or Flat (FlatSites)
#>
param (
    [string]$sitename,
    [string]$subsite
) #end param

function Main ($siteName, $subSite) {
    ## Check our inputs and display message if not set.
    if ((-not $siteName ) -Or (-not $subSite )) {
        if( -not $siteName ) {
            Write-Host ""
            Write-Host -foregroundcolor "red" "You must specify the site to deploy."
            Write-Host ""
        }

        if( -not $subSite ) {
            Write-Host ""
            Write-Host -foregroundcolor "red" "You must specify the subsite to deploy."
            Write-Host ""
        }

        exit
    }
    
    # Start time of robocopy process
    $startTime = Get-Date
    
    # Perform robocopy of /publishing to /content
    $copy = if( $subsite -eq "flat" ) {
        Start-Process robocopy -ArgumentList "E:\publishing\PercussionSites\FlatSites\$sitename e:\content\PercussionSites\FlatSites\$sitename /copy:DAT /DCOPY:T /MIR" -NoNewWindow -PassThru -Wait        
    } Else {
        Start-Process robocopy -ArgumentList "E:\publishing\PercussionSites\CDESites\$sitename\$subsite\PublishedContent e:\content\PercussionSites\CDESites\$sitename\$subsite\PublishedContent /copy:DAT /DCOPY:T /MIR" -NoNewWindow -PassThru -Wait	
    }

    $processid = $copy.Id
    $processexitcode = $copy.ExitCode

    # Write process ID of robocopy and timestamp of start in logs
    Add-Content 'E:\Rhythmyx\jetty\base\logs\robocopylog.txt' "Robocopy started for $siteName $subSite process $processid : $startTime"

    # Write process ID of robocopy and timestamp of completion in logs
    Add-Content 'E:\Rhythmyx\jetty\base\logs\robocopylog.txt' "Robocopy finished for $siteName $subSite process $processid : $(Get-Date)"

    Add-Content 'E:\Rhythmyx\jetty\base\logs\robocopylog.txt' "Robocopy exited with code $processexitcode for $siteName $subSite process $processid"

    Write-Host -foregroundcolor "green" "Deployment completed."
}

Main $sitename $subsite
