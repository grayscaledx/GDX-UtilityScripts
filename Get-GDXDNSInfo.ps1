Function Get-GDXDNSInfo {

    [CmdletBinding()]
    param(
        [Parameter(HelpMessage="A target computer IP address, DNS FQDN, or Machine name.  Can be a list of strings.",
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$True)]
        [ValidateScript({foreach ($ComputerName in $_) {$ComputerName.GetType().FullName -eq "System.String"}})]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )    

    BEGIN { $dnsContainer = @() }

    PROCESS {

        foreach ($C in $ComputerName){

            try {
                
                $dnsResults = [Net.DNS]::GetHostEntry($C)

                $dnsProps = @{
                                'HostName'=$dnsResults.HostName;
                                'AddressList'=$($($dnsResults.AddressList | Select -ExpandProperty IPAddressToString) -join ';');
                                'IsAlive'=$(Test-Connection $C -Count 2 -Quiet)
                            }

                $dnsObj = New-Object -TypeName psobject -Property $dnsProps
                $dnsObj.PSObject.Typenames.Insert(0,'GDX.DNSInfo')
                $dnsContainer += $dnsObj

                Write-Verbose "Completed processing target host $C"

            }

            <#catch [System.Net.Sockets.SocketException] {
                
                $dnsProps = @{
                                'HostName'="NoHostFound";
                                'AddressList'=$C;
                                'IsAlive'=$(Test-Connection $C -Count 2 -Quiet)
                            }

                $dnsObj = New-Object -TypeName psobject -Property $dnsProps
                $dnsObj.PSObject.Typenames.Insert(0,'GDX.DNSInfo')
                $dnsContainer += $dnsObj

            }#>
            
            catch {
            
                $dnsProps = @{
                                'HostName'="NoHostFound";
                                'AddressList'=$C;
                                'IsAlive'=$(Test-Connection $C -Count 2 -Quiet)
                            }

                $dnsObj = New-Object -TypeName psobject -Property $dnsProps
                $dnsObj.PSObject.Typenames.Insert(0,'GDX.DNSInfo')
                $dnsContainer += $dnsObj

                Write-Verbose "Completed processing target host $C; No hostname found."

            }                      
        
        }
    
    }

    END { Write-Output $dnsContainer }

    

}