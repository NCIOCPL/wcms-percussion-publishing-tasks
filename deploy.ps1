<#
    .SYNOPSIS
        Deploys /publishing to /content for a site and subsite.
    .DESCRIPTION
        Deploys the content ready for publishing in /publishing to the published
        content folder /content.
        Deploys both Live and Preview content for CancerGov, TCGA, DCEG, Proteomics, and Imaging.
        Deploys content for Static.    
    .PARAMETER sitename
        Name of the site published content to deploy
    .PARAMETER subsite
        Live or preview
    .PARAMETER percsitetype
        Static (Static sites only)
#>
param (
    [string]$sitename,
    [string]$subsite,
    [Parameter(Mandatory=$False)]
        [string]$percsitetype
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
    if( -not $percsitetype ) {
        $copy = Start-Process robocopy -ArgumentList "E:\publishing\PercussionSites\CDESites\$sitename\$subsite\PublishedContent e:\content\PercussionSites\CDESites\$sitename\$subsite\PublishedContent /copy:DAT /DCOPY:T /MIR" -NoNewWindow -PassThru -Wait
    } Else {
        $copy = Start-Process robocopy -ArgumentList "E:\publishing\StaticSites\$percsitetype\$sitename\$subsite e:\content\StaticSites\$percsitetype\$sitename\$subsite /copy:DAT /DCOPY:T /MIR" -NoNewWindow -PassThru -Wait        
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