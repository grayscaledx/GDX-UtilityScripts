Function Get-GDXDNSInfo {

<#
.SYNOPSIS
Enter a single host/IP or a list of hosts/IP's and return the associated A/PTR records.

.DESCRIPTION
Resolve IP's or hostnames as a collective batch operation.  The tool will also send ICMP
traffic to the query location and see if the host replies.  This function does not use
NSLOOKUP as the resolution application.  

As a result, due to the limitations of the .NET framework, it will use the name servers
associated with your network interface.  Additionally, AAAA records will only be returned
when the interface used to query participates in IPv6.

Requires .NET 3.5 SP1 or later.

.PARAMETER ComputerName
The name or IP address of the target host to query.  This can be a list of items.  Type must be String.

.EXAMPLE
Get-GDXDNSInfo -ComputerName www.google.com
Will resolve IP(s) for www.google.com

.EXAMPLE
Get-GDXDNSInfo www.google.com
Will resolve IP(s) for www.google.com.  The positional parameter allows for the -ComputerName Parameter to not be
explicitly defined.

.EXAMPLE
Get-GDXDNSInfo -ComputerName www.google.com,www.yahoo.com,www.arstechnica.com
Will resolve IP(s) for www.google.com, www.yahoo.com, and www.arstechnica.com

.EXAMPLE
Get-GDXDNSInfo -ComputerName 8.8.8.8
Will resolve hostname(s) for 8.8.8.8.  The AddressList property returning a blank value on a PTR lookup is normal.

.LINK
https://github.com/grayscaledx/
#>

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
                                'Query'=$C;
                                'HostName'=$dnsResults.HostName;
                                'AddressList'=$dnsResults.AddressList;
                                # saving this line below for file export section; want to keep list in property for 
                                #'AddressExport'=$($($dnsResults.AddressList | Select -ExpandProperty IPAddressToString) -join ';');
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