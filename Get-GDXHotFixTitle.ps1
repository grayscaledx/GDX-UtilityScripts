Function Get-GDXHotFixTitle {

<#
.SYNOPSIS
Queries target computer for installed patches and queries Internet for KB title for quick identification.
.DESCRIPTION
Queries the target computer for all patches that have been successfully applied.  After the list of updates is gathered, support.microsoft.com is
reached over port 80 (HTTP) and the title of the patch is collected for a quicker summary review of patches applied to the system or the titles
of a list of KB's for quick research.

Requires PowerShell version 3.0 or greater.  Will add PowerShell 2.0 support later with .Net methods.

Presently, this is designed to only run against a local computer and cannot be targeted at remote computers or use alernate credentials.
.PARAMETER ComputerName
The name or IP address of the target host to query.  If this is targetting a remote computer, the current indentity and its credentials will be passed onto the remote system.

.PARAMETER HotFixID
NOTE: This parameter supercedes the ComputerName parameter.  When this parameter is used, only this parameter is queried for titles.
A single or a list of KB entries to be scraped for their titles.


.EXAMPLE
Get-GDXHotFixTitle
Returns all patches and their description title for the local computer.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="A target computer host name or IP address to query.",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
    [string[]]$ComputerName = 'localhost',
    [Parameter(HelpMessage="A single KB entry or a list of KB entries.  All entries passed into this parameter require a leading KB.",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
    [ValidatePattern("KB[0-9]+")]
    [string[]]$HotFixID = $null

    <#
    [Parameter(HelpMessage="Credentials to pass to target computer"
    )]
    [switch]$Credential
    #>
)

BEGIN {
    
    Write-Verbose "Initializing function container..."
    $fc = @()
    $progress = 1

    if ($HotFixID -ne $null) {
        Write-Warning "HotFixID argument takes precedent over ComputerName argument; Any computer names entered will not be processed ..."
        $ComputerName = 'localhost'
    }
    
}

PROCESS {

    foreach ($c in $ComputerName){

        if ($HotFixID -ne $null) {
        
            Write-Verbose "Processing manually entered list of KB IDs from HotFixID argument ..."
            $sysUpdates = $HotFixID
            $sysUpdatesCount = $sysUpdates | Measure-Object | Select-Object -ExpandProperty Count
            Write-Verbose "Processing $sysUpdatesCount updates from HotFixID argument ..."
        
        } else {
        
            Write-Verbose "Collecting updates from computer $c"
            $sysUpdates = Get-HotFix -ComputerName $c
            $sysUpdatesCount = $sysUpdates | Measure-Object | Select-Object -ExpandProperty Count
            Write-Verbose "Processing $sysUpdatesCount updates for computer $c ..."

        }
        
        foreach ($update in $sysUpdates){
        
            try{

                if ($HotFixID -ne $null) {

                    Write-Progress -Activity "Getting $sysUpdatesCount KB titles from Internet ..." -Status "Finding $update title..." -percentComplete (($progress / $sysUpdatesCount) * 100)
                
                    Write-Debug "Manual"

                    Write-Verbose "Collecting information on patch $update"
                    $query = Invoke-WebRequest -Uri "http://support.microsoft.com/kb/$($update.Substring(2))"

                    $props = @{
                                'HotFixID' = $update
                                'Title' = $query.ParsedHtml.getElementsByTagName("title") | Where-Object -Property uniqueID -eq "ms__id1" | Select-Object -ExpandProperty innerText
                                'URL' = "http://support.microsoft.com/kb/$($update.Substring(2))"
                                'InstalledOn' = "N/A"
                    
                              }

                } else {

                    Write-Progress -Activity "Getting $sysUpdatesCount KB titles from Internet ..." -Status "Finding $($update.HotFixID) title..." -percentComplete (($progress / $sysUpdatesCount) * 100)
                
                    Write-Debug "Processed Object"

                    Write-Verbose "Collecting information on patch $($update.HotFixID)"
                    $query = Invoke-WebRequest -Uri "http://support.microsoft.com/kb/$($update.HotFixID.Substring(2))"

                    $props = @{
                                'HotFixID' = $update.HotFixID
                                'Title' = $query.ParsedHtml.getElementsByTagName("title") | Where-Object -Property uniqueID -eq "ms__id1" | Select-Object -ExpandProperty innerText
                                'URL' = "http://support.microsoft.com/kb/$($update.HotFixID.Substring(2))"
                                'InstalledOn' = $update.InstalledOn
                              }
                           
                }

                $objProps = New-Object -TypeName psobject -Property $props

                $fc += $objProps
                $progress += 1

            }

            catch { Write-Output "$_" }
        
        }

    }
    
}

END {

    Write-Progress -Activity "Getting $sysUpdatesCount KB titles from Internet..." -Completed
    Write-Output $fc

}

}