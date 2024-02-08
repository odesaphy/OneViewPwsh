#requires -version 4
<#
.SYNOPSIS
    Get downlinks info on Server Profiles with correlation in vCenter
		(from connection in OneView to vmnic)
    	
.INPUTS
	None
	
.OUTPUTS
	CSV file hpe_downlinks.csv in $PSScriptRoot\reports
	CSV columns :
		OneView Domain
		Data Center
		Rack
		Enclosure
		Enclosure Group
		Logical Enclosure
		Logical Interconnect
		Interconnect Name
		Interconnect Status
		Interconnect State
		Interconnect Model
		Port Name
		Port State
		Port HealthStatus
		Uplink Port
		Uplink Port Neighbor
		Server Hardware
		Server PowerState
		Adapter Port
		Server Profile
		Sub Port FlexNIC
		Sub Port Type
		Sub Port State
		Sub Port Network(s)
		Sub Port Address
		uuid
		vCenter
		Cluster
		esx
		vmnic
		LinkSpeed
		dvSwitch
		Inventory Date
	
.NOTES
	Filename:		get_downlinks_v7.ps1
	Version:		1.0.1
	Author:			olivier.desaphy@hpe.com
	Creation Date:	2020-06-05
	Purpose/Change:	
				2020-12-18 : script header
					
.EXAMPLE
	[path to]/get_downlinks_v7.ps1
#>
$platform=${Global:HPEplatform}

"Connected to {0}" -f $platform |Write-Host -ForegroundColor Green

$OUTPUTDIR = "{0}\reports" -f $PSScriptRoot

$HPEOVREPORTCSVOPTIONS = @{
	"NoTypeInformation" = $true
	"Delimiter" = ";"
	"Encoding" = "UTF8"
} 

$report = [System.Collections.ArrayList]::new()
$reportFile = "hpe_{0}_downlinks_{1}.csv" -f $platform, (Get-date -Format "yyyyMMdd-HHmmss")


$HPEOVREPORTSUBRECORDSEP="|"


$recordProperties = [Ordered]@{
	"OneView Domain" = $null
	"Data Center" = $null
	"Rack" = $null
	"Enclosure" = $null
	"Enclosure Group" = $null
	"Logical Enclosure" = $null
	"Logical Interconnect" = $null
	"Interconnect Name" = $null
	"Interconnect Status" = $null
	"Interconnect State" = $null
	"Interconnect Model" = $null
	"Port Name" = $null
	"Port State" = $null
	"Port HealthStatus" = $null
	"Uplink Port" = $null
	"Uplink Port Neighbor" = $null
	"Server Hardware" = $null
	"Server PowerState" = $null
	"Adapter Port" = $null
	"Server Profile" = $null
	"Sub Port FlexNIC" = $null
	"Sub Port Type" = $null
	"Sub Port State" = $null
	"Sub Port Network(s)" = $null
	"Sub Port Address" = $null
	"uuid" = $null
	"vCenter" = $null
	"Cluster" = $null
	"esx" = $null
	"vmnic" = $null
	"LinkSpeed" = $null
	"dvSwitch" = $null
	"Inventory Date" = $null
}

$mezzHash = @{
	"mezz" = "Mezzanine"
}

$portFunctionHash = @{
	1 = "a"
	2 = "b"
	3 = "c"
	4 = "d"
}

# Variable $dc2oneviewDomain is sourced from [ABC]_profile.ps1
Get-Variable -Name dc2oneviewDomain -ErrorAction Stop | Out-Null



Function get_uplink_port($li, $co) {
	$uri = "/rest/index/trees/aggregated/{0}" -f $li.uri
	$response = Send-HPOVRequest -uri $uri
	
	$netOnCo = Send-HPOVRequest -uri $co.networkResourceUri
	
	$_uls = $response.categories.'uplink-sets' | ? { $_.Name.contains($netOnCo.name) }
	
	$uls = Send-HPOVRequest -uri $_uls.uri
	
	$portUri = $uls.portConfigInfos.portUri | ? { $_.contains($co.interconnectUri) }
	
	Send-HPOVRequest -uri $portUri
}

if ($global:DefaultVIServers) {
	$vmhosts = @()
	$clusters = @()
	
	foreach ($vcenter in $Global:DefaultVIServers) {
		$vmhosts += Get-View -ViewType HostSystem -Property Name, Summary, Parent, Config -Server $vcenter
		$clusters += Get-View -ViewType ClusterComputeResource -Property Name -Server $vcenter
	}	
	<# $vmhosts = Get-View -ViewType HostSystem -Property Name, Summary, Parent, Config -Server $global:DefaultVIServers
	$clusters = Get-View -ViewType ClusterComputeResource -Property Name -Server $global:DefaultVIServers #>
	
	
} else {
	Write-Error "Not connected to any vCenter(s)" -ErrorAction Stop
}

foreach ($oneview in $global:ConnectedSessions) {
	if (($global:ConnectedSessions).count -gt 1) {
		Set-HPOVApplianceDefaultConnection -ApplianceConnection $oneview | Out-Null
	}
	$datacenters=Get-HPOVDataCenter -ErrorAction SilentlyContinue
	foreach ($dc in $datacenters) {
		$bbName = $dc2oneviewDomain[$dc.name]
		"{0} --> {1}" -f $dc.name, $bbName | Write-Host
		$racks = $dc.contents.resourceUri | % { Send-HPOVRequest -uri $_  }
		foreach ($rk in $racks) {
			"`t{0}" -f $rk.name | Write-Host
			$enclosures = $rk.rackMounts.mountUri | % { Send-HPOVRequest -uri $_  }
			foreach ($en in $enclosures) {
				"`t`t{0}" -f $en.name | Write-Host
				foreach ($bay in $en.interconnectBays) {
					if ($bay.interconnectUri -ne $null) {
						$in = Send-HPOVRequest -uri $bay.interconnectUri 
						if ($in.model -eq "Virtual Connect SE 40Gb F8 Module for Synergy") {
							"`t`t`t{0}" -f $in.Name | Write-Host
							$eg = Send-HPOVRequest -uri $en.enclosureGroupUri
							$le = Send-HPOVRequest -Uri $en.logicalEnclosureUri
							$li = Send-HPOVRequest -uri $in.logicalInterconnectUri
							$uri = "/rest/connections?filter=`"interconnectUri='{0}'`"" -f $in.uri
							$connections = Send-HPOVRequest -uri $uri

							$uri = "/rest/index/trees{0}?childDepth=1&parentDepth=1" -f $in.uri
							$indexTrees = Send-HPOVRequest -uri $uri

							$sh = $indexTrees.parents.BLADE_TO_INTERCONNECT | % { Send-HPOVRequest -uri $_.resource.uri }
							$dl = $indexTrees.parents.PORT_TO_INTERCONNECT | ? { $_.resource.attributes.portType -eq "DOWNLINK" }
							
							$uplinkPorts = $in.ports | ? { $_.portType -eq "Uplink" -and $_.portHealthStatus -ne "Disabled" }
							$uplinkSets = $uplinkPorts.associatedUplinkSetUri |% { Send-HPOVRequest -uri $_ }

							foreach ($co in $connections.members) {
								$record = New-Object PSObject -Property $recordProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								#$record."Data Center" = $bbName
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Logical Interconnect" = $li.name
								$record."Interconnect Name" = $in.name
								$record."Interconnect Status" = $in.state
								$record."Interconnect State" = $in.status
								$record."Interconnect Model" = $in.model
							
								$inPort = $in.ports | ? { $_.name -eq ("d{0}" -f $co.interconnectPort) }
								$record."Interconnect Name" = $in.Name
								$record."Port Name" = $inPort.portName.split("d")[1]
								$record."Port State" = $inPort.portStatus
								$record."Port HealthStatus" = $inPort.portHealthStatus
								
								if ($co.connectionInstanceType -eq "NetworkSet") {
									$netUri = (Send-HPOVRequest -uri $co.networkResourceUri).networkUris[0]
								}
								if ($co.connectionInstanceType -eq "Ethernet") {
									$netUri = $co.networkResourceUri
								}

								$uls = $uplinkSets | ? { $netUri -in $_.networkUris }
								$uplinkPortUri = $uls.portConfigInfos.portUri | ? { $_.StartsWith($co.interconnectUri) }
								$uplinkPort = Send-HPOVRequest -uri $uplinkPortUri
								
								$record."Uplink Port" = ("{0}, {1}" -f $uplinkPort.interconnectName, $uplinkPort.name)
								$record."Uplink Port Neighbor" = ("{0} {1}" -f $uplinkPort.neighbor.remoteSystemName, $uplinkPort.neighbor.remotePortId)
								$physicalPort = $sh.portMap.deviceSlots.physicalPorts | ? { ($_.interconnectPort -eq $co.interconnectPort) -and ($_.interconnectUri -eq $co.interconnectUri)}
								if (-not [string]::IsNullOrEmpty($physicalPort)) {
									$_sh = $sh | ? { ($_.portMap.deviceSlots.physicalPorts.interconnectUri -eq $co.interconnectUri) -and ($physicalPort.mac -in $_.portMap.deviceSlots.physicalPorts.mac)}
									
									"_sh name : {0}" -f $_sh.name | Write-Debug
									$deviceSlot = $_sh.portMap.deviceSlots | ? { $physicalPort.mac -in $_.physicalPorts.mac  }
									
									"{0} --> {1} / {2}{3}:{4}{5}" -f $co.interconnectPort, $_sh.name, $deviceSlot.location, $deviceSlot.deviceNumber, $physicalPort.portNumber, $virtualPort.portFunction | Write-Debug
									
									$record."Server Hardware" = $_sh.name
									$record."Server PowerState" = $_sh.powerState
									$record."Adapter Port" = ("{0} {1}:{2}" -f $mezzHash[$deviceSlot.location], $deviceSlot.deviceNumber, $physicalPort.portNumber)
									"{0} --> {1} --> {2}" -f $co.uri, $_sh.name,  $_sh.serverProfileUri | Write-Debug
									if (-not [string]::IsNullOrEmpty($_sh.serverProfileUri)) {
										$sp = Send-HPOVRequest -uri $_sh.serverProfileUri
										"sp name : {0}" -f $sp.name | Write-Debug
										$record."Server Profile" = $sp.name
										$record."uuid" = $sp.uuid
										$myvmhost = $vmhosts | ? { $_.Summary.Hardware.Uuid -eq $sp.uuid }
										
										if (-not [string]::IsNullOrEmpty($myvmhost)) {
											$vcenter = $global:DefaultVIServers | ? { $_.ServiceUri -eq $myvmhost.Client.ServiceUrl}
											$cluster = $clusters | ? { ($_.MoRef.ToString() -eq $myvmhost.Parent.ToString()) -and ($_.Client.ServiceUrl -eq $myvmhost.Client.ServiceUrl)}
											$pnic = $myvmhost.Config.Network.Pnic | ? { $_.Mac -eq $co.macAddress }

											$record."vCenter" = $vcenter.name
											$record."esx" = $myvmhost.Name
											$record."vmnic" = $pnic.Device
											$record."dvSwitch" = ($myvmhost.Config.Network.ProxySwitch | ? { $pnic.key -in $_.Pnic }).DvsName
											
											if (-not [string]::IsNullOrEmpty($pnic.LinkSpeed)) {
												$record."LinkSpeed" = $pnic.LinkSpeed.SpeedMb
											} else {
												$record."LinkSpeed" = "down"
											}
											
											if (-not [string]::IsNullOrEmpty($cluster.name)) {
												$record."Cluster" = $cluster.name
											} else {
												$record."Cluster" = "Not in a cluster"
											}
										} else {
											$record."vCenter" = "Not in a vCenter"
										}								
									
										$record."Sub Port FlexNIC" = ("{0} {1}:{2}-{3}" -f $mezzHash[$deviceSlot.location], $deviceSlot.deviceNumber, $physicalPort.portNumber, $portFunctionHash[$co.interconnectSubPort])
										$record."Sub Port Type" = "Ethernet"
										$record."Sub Port State" = ($inPort.subports | ? { $_.portNumber -eq $co.interconnectSubPort}).portStatus
										
										if (-not [string]::IsNullOrEmpty($co.networkResourceUri)) {
											$net = Send-HPOVRequest -uri $co.networkResourceUri
											$record."Sub Port Network(s)" = $net.name
										}
										
										$record."Sub Port Address" = $co.macAddress
									}
								}
								$record."Inventory Date" = Get-Date
								[void]$reportAdd($record)
							}
						}
					}
				}
			}
		}
		$report | Export-Csv @HPEOVREPORTCSVOPTIONS -Path $OUTPUTDIR\$reportFile -Append
		$report = [System.Collections.ArrayList]::new()
	}
}


