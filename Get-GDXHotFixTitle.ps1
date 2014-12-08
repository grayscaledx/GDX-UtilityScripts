Function Get-GDXHotFixTitle {

<#
.SYNOPSIS
Queries target computer for installed patches and queries Internet for KB title for quick identification.
.DESCRIPTION
Queries the target computer for all patches that have been successfully applied.  After the list of updates is gathered, support.microsoft.com is
reached over port 80 (HTTP) and the title of the patch is collected for a quicker summary review of patches applied.
.PARAMETER ComputerName
The name or IP address of the target host to query.
.EXAMPLE
Get-GDXHotFixTitle
Returns all patches and their description title for the local computer.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="A target coputer host name or IP address to query.",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
    [string[]]$ComputerName = 'localhost',
    [Parameter(HelpMessage="Credentials to pass to target computer"
    )]
    [switch]$Credential
)

BEGIN {
    
    Write-Verbose "Initializing function container..."
    $fc = @()
    $progress = 1
    
}

PROCESS {

    foreach ($c in $ComputerName){

        Write-Verbose "Collecting updates from computer $c"
        $sysUpdates = Get-HotFix -ComputerName $c
        $sysUpdatesCount = $sysUpdates | Measure-Object | Select-Object -ExpandProperty Count

        Write-Verbose "Processing $totalUpdates updates..."
        foreach ($update in $sysUpdates){
        
            try{

                Write-Progress -Activity "Getting $sysUpdatesCount KB titles from Internet..." -Status "Finding $($update.HotFixID) title..." -percentComplete (($progress / $sysUpdatesCount) * 100)
                Write-Verbose "Collecting information on patch $($update.HotFixID)"
                $query = Invoke-WebRequest -Uri "http://support.microsoft.com/kb/$($update.HotFixID.Substring(2))"

                $props = @{
                            'HotFixID' = $update.HotFixID
                            'Title' = $query.ParsedHtml.getElementsByTagName("title") | Where-Object -Property uniqueID -eq "ms__id1" | Select-Object -ExpandProperty innerText
                            'URL' = "http://support.microsoft.com/kb/$($update.HotFixID.Substring(2))"
                            'InstalledOn' = $update.InstalledOn
                
                          }

                $objProps = New-Object -TypeName psobject -Property $props

                $fc += $objProps
                $progress += 1
                
                <#
                
                #Write-Output $($update.HotFixID).Substring(2)
                #Write-Output "http://support.microsoft.com/kb/$($update.HotFixID.Substring(2))"
                #$query | Select-Object -ExpandProperty AllElements | Where-Object -Property tagName -eq "Title" | Where-Object -Property ID -ne "ctl00_Head1"  | Select-Object -ExpandProperty innerText
                $query = Invoke-WebRequest -Uri "http://support.microsoft.com/kb/$($update.HotFixID.Substring(2))"
                $query.ParsedHtml.getElementsByTagName("title") | Where-Object -Property uniqueID -eq "ms__id1" | Select-Object -ExpandProperty innerText

                #>
            
            }

            catch { Write-Output "Derp..." }
        
        }

    }

}

END {

    Write-Output $fc

}

}