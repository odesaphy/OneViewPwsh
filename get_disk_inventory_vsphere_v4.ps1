#requires -version 4
<#
.SYNOPSIS
	Get Disk Inventory from HPE OneView linked with VMware ESXi naa disks and vSAN diskgroups (for computes with ESXi installed)
	
.INPUTS
	None
	
.OUTPUTS
	CSV file hpe_disk_inventory.csv in $OUTPUTDIR
	CSV columns :
		Data Center
		Rack
		Enclosure
		Enclosure Group
		Logical Enclosure
		Drive Enclosure
		Drive Bay
		Drive Model
		Drive SN
		Drive FW
		Drive Capacity
		Drive WWID
		Drive State
		Drive Status
		Server Profile
		Server Profile SN
		JBOD Name
		JBOD Status
		Server Hardware Name
		Server Hardware SN
		Server Hardware PowerState
		Server Hardware Position
		vSphere Hostname
		vSphere NAA
		vSAN Diskgroup
		vSAN Disk Usage
		vSAN Disk UUID
		vSAN Disk Format Version
		vSphere Cluster
		vCenter Server
	
.NOTES
	Filename:		hpe_disk_inventory.ps1
	Version:		4.0
	Author:			olivier.desaphy@hpe.com
	Creation Date:	2019-10-21
	Purpose/Change:	Initial

.EXAMPLE
	[path to]/hpe_disk_inventory.ps1
#>
[CmdletBinding ()]
Param(
	[Parameter (Mandatory = $false, Position=0, ParameterSetName = "Default")]
	[switch] $extraSsdInfo
)

$platform=${Global:HPEplatform}

"Connected to {0}" -f $platform |Write-Host -ForegroundColor Green

$OUTPUTDIR = "{0}\reports" -f $PSScriptRoot

$HPEOVREPORTFILE = "hpe_{0}_disk_inventory_{1}.csv" -f $platform, (Get-date -Format "yyyyMMdd-HHmmss")

$HPEOVREPORTCSVOPTIONS = @{
						"NoTypeInformation" = $true
						"Delimiter" = ";"
						"Encoding" = "UTF8"
						"Path" = "$OUTPUTDIR\$HPEOVREPORTFILE"
					} 

# Variable $dc2oneviewDomain is sourced from [ABC]_profile.ps1
Get-Variable -Name dc2oneviewDomain -ErrorAction Stop | Out-Null

	
$hpeovreport = [System.Collections.ArrayList]::new()
				
$ovRecordProperties = [Ordered]@{
	"OneView Domain" = $null
	"Data Center" = $null
	Rack = $null
	Enclosure = $null
	"Enclosure Group" = $null
	"Logical Enclosure" = $null
	"Drive Enclosure" = $null
	"Drive Bay" = $null
	"Drive Model" = $null
	"Drive SN" = $null
	"Drive FW" = $null
	"Drive Capacity" = $null
	"Drive WWID" = $null
	"Drive State" = $null
	"Drive Status" = $null
	"Server Profile" = $null
	"Server Profile SN" = $null
	"JBOD Name" = $null
	"JBOD Status" = $null
	"Server Hardware Name" = $null
	"Server Hardware SN" = $null
	"Server Hardware PowerState" = $null
	"Server Hardware Position" = $null
	"vSphere Hostname" = $null
	"vSphere NAA" = $null
	"vSAN Diskgroup" = $null
	"vSAN Disk Usage" = $null
	"vSAN Disk UUID" = $null
	"vSAN Disk Format Version" = $null
	"vSphere Cluster" = $null
	"vCenter Server" = $null
}			

# Extra SSD Info ?
if ($PSBoundParameters['extraSsdInfo']) {
	$ssdInfo = [System.Collections.ArrayList]::new()

	$ovRecordProperties.Add("Current Temperature (C)", $null)
	$ovRecordProperties.Add("Maximum Temperature (C)", $null)
	$ovRecordProperties.Add("Usage remaining (%)", $null)
	$ovRecordProperties.Add("Power On Hours", $null)
	$ovRecordProperties.Add("Estimated Life Remaining based on workload to date (days)", $null)
	$ovRecordProperties.Add("Drive", $null)
	$ovRecordProperties.Add("WWID", $null)
}

#region Get VMware Data

$vmhostViewProperties = @("Config", "Name", "Hardware", "Parent", "Runtime")

$vmhosts = @()
$clusters = @()
foreach ($vcenter in $global:DefaultVIServers) {
	$clusters += Get-View -ViewType ClusterComputeResource -Property Name -Server $vcenter
	$vmhosts += Get-View -ViewType HostSystem -Property $vmhostViewProperties -Server $vcenter
}
"Found {0} clusters and {1} esxi" -f $clusters.count, $vmhosts.count | Write-Host

$spjboddrives = [System.Collections.ArrayList]::new()

#$vmwareData = @()
$vmwareData = [System.Collections.ArrayList]::new()
$vmwRecordProperties = [Ordered]@{
	host=$null
	hostUuid=$null
	hostversion=$null
	hostbuild=$null
	vsanenabled=$null
	naa=$null
	wwid=$null
	vsandiskgroup=$null
 	vsandiskusage=$null
	vsandiskvsanuuid=$null
	vsandiskfomatversion=$null
	cluster=$null
	vcenter=$null
}

function getSsdInfo([VMware.VimAutomation.ViCore.Impl.V1.EsxCli.EsxCliImpl]$esxcli) {
	$result = $esxcli.ssacli.cmd.Invoke(@{"cmdopts"="ctrl slot=1 pd all show detail"}) -split "`n"
	
	foreach ($matchInfo in ($result | Select-String '\s*physicaldrive ?(\d*:\d*:\d*)' -Context 0,23)) {
		$mydrive = $matchInfo.Matches.Groups[1].Value
		$driveDetails = $matchInfo.Context.PostContext
		
	
		$record = [pscustomobject][ordered]@{
			"drive" = $mydrive
			"Active Path" = & { try { ($driveDetails | Select-String '\s*Active Path:' -Context 0,1).Context.PostContext.trim() } catch { $null } }
			"Redundant Path" = & { try { ($driveDetails | Select-String '\s*Redundant Path\(s\):' -Context 0,1).Context.PostContext.trim() } catch { $null } }
			"Status" = & { try { ($driveDetails | Select-String '\s*Status: ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"Firmware" = & { try { ($driveDetails | Select-String '\s*Firmware Revision: ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"Serial Number" = & { try { ($driveDetails | Select-String '\s*Serial Number: ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"WWID" = & { try { ($driveDetails | Select-String '\s*WWID: ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"Model" = & { try { ($driveDetails | Select-String '\s*Model: ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"Current Temperature (C)" = & { try { ($driveDetails | Select-String '\s*Current Temperature \(C\): ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"Maximum Temperature (C)" = & { try { ($driveDetails | Select-String '\s*Maximum Temperature \(C\): ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"Usage remaining (%)" = & { try { ($driveDetails | Select-String '\s*Usage remaining: ?(.*)\%').Matches.Groups[1].Value } catch { $null } }
			"Power On Hours" = & { try { ($driveDetails | Select-String '\s*Power On Hours: ?(.*)').Matches.Groups[1].Value } catch { $null } }
			"Estimated Life Remaining based on workload to date (days)" = & { try { ($driveDetails | Select-String '\s*Estimated Life Remaining based on workload to date: ?(.*) days').Matches.Groups[1].Value } catch { $null } }
		}
		[void]$ssdInfo.Add($record)
	}
}

function getVMwareData($vmhost) {
	if ($vmhost.Runtime.ConnectionState -notin @("Disconnected", "NotResponding")) {
		$hostUuid = $vmhost.Hardware.SystemInfo.uuid
		$vc = $global:DefaultVIServers | ? { $_.ServiceUri -eq $vmhost.Client.ServiceUrl}
		"ESXi = {0}/{1}" -f $vmhost.Name,$hostUuid | Write-Host
		
		# VSan ?
		if ($vmhost.Config.VsanHostConfig.Enabled) {
			$cl = $clusters | ? { ($_.MoRef.ToString() -eq $vmhost.Parent.ToString()) -and ($_.Client.ServiceUrl -eq $vmhost.Client.ServiceUrl)}
			$data=@()
			$dgid=0
			foreach ($dg in $vmhost.Config.VsanHostConfig.StorageInfo.DiskMapInfo) {
				foreach ($cd in $dg.Mapping.Ssd) {
					$record = New-Object PSObject -Property $vmwRecordProperties
					$record.host=$vmhost.Name; 
					$record.hostUuid=$hostUuid; 
					$record.hostversion=$vmhost.Config.Product.Version
					$record.hostbuild=$vmhost.Config.Product.Build
					$record.vsanenabled=$vmhost.Config.VsanHostConfig.Enabled
					$record.naa=$cd.CanonicalName; 
					$record.wwid=$($cd.CanonicalName.Replace("naa.","")).ToUpper();
					$record.vsandiskgroup=$dgid
					$record.vsandiskusage="Cache"
					$record.vsandiskvsanuuid=$cd.VsanDiskInfo.VsanUuid
					$record.vsandiskfomatversion=$cd.VsanDiskInfo.FormatVersion
					$record.cluster = $cl.name
					$record.vcenter = $vc.name
					[void]$vmwareData.Add($record)
				}
				foreach ($cd in $dg.Mapping.NonSsd) {
					$record = New-Object PSObject -Property $vmwRecordProperties
					$record.host=$vmhost.Name; 
					$record.hostUuid=$hostUuid; 
					$record.hostversion=$vmhost.Config.Product.Version
					$record.hostbuild=$vmhost.Config.Product.Build
					$record.vsanenabled=$vmhost.Config.VsanHostConfig.Enabled
					$record.naa=$cd.CanonicalName; 
					$record.wwid=$($cd.CanonicalName.Replace("naa.","")).ToUpper();
					$record.vsandiskgroup=$dgid
					$record.vsandiskusage="Capacity"
					$record.vsandiskvsanuuid=$cd.VsanDiskInfo.VsanUuid
					$record.vsandiskfomatversion=$cd.VsanDiskInfo.FormatVersion
					$record.cluster=$cl.name
					$record.vcenter=$vc.name
					[void]$vmwareData.Add($record)
				}
				$dgid++
			}
		} else {
			# Not in vSAN : Disks in drive enclosure start with naa.5000 or naa.58ce
			$luns = $vmhost.Config.StorageDevice.ScsiLun | ? { $_.CanonicalName -like "naa.5000*" -or $_.CanonicalName -like "naa.58ce*" }
			$data=@()
			foreach ($disk in $luns)
			{
				# Disks in drive enclosure start with naa.5000 or naa.58ce
				$record = New-Object PSObject -Property $vmwRecordProperties
				$record.host=$vmhost.Name; 
				$record.hostUuid=$hostUuid; 
				$record.hostversion=$vmhost.Config.Product.Version
				$record.hostbuild=$vmhost.Config.Product.Build
				$record.vsanenabled=$vmhost.Config.VsanHostConfig.Enabled
				$record.naa=$disk.CanonicalName; 
				$record.wwid=$($disk.CanonicalName.Replace("naa.","")).ToUpper();
				[void]$vmwareData.Add($record)
			}
		}
	}
}



<#
    checkwwid - returns True if the vmware WWID is the same disk as the OneView WWID
#>
function checkwwid($ovWWID, $vmWWID)
{
    if ($($ovWWID.Insert(0, "0x")- 1)  -eq $($vmWWID.Insert(0,"0x")) -or $($ovWWID.Insert(0, "0x")- 2)  -eq $($vmWWID.Insert(0,"0x")) -or $($ovWWID.Insert(0, "0x")- 3)  -eq $($vmWWID.Insert(0,"0x"))) 
		{
			return $true
		} else {
			return $false
		}
}




$j=1 #Enclosure

foreach ($oneview in $Global:ConnectedSessions) {
    if (($global:ConnectedSessions).count -gt 1) {
		Set-HPOVApplianceDefaultConnection -ApplianceConnection $oneview | Out-Null
    }
	$datacenters=Get-HPOVDataCenter 

	$allServerProfiles = (Send-HPOVRequest -uri "/rest/server-profiles/?start=0&count=999").members
	$allServers = (Send-HPOVRequest -uri "/rest/server-hardware/?start=0&count=999").members
	$allEnclosureGroups = (Send-HPOVRequest -uri "/rest/enclosure-groups/?start=0&count=-1").members
	$allLogicalEnclosures = (Send-HPOVRequest -uri "/rest/logical-enclosures/?start=0&count=-1").members
	$i=1
	foreach ($sp in $allServerProfiles) {
		"Server Profile : {0} [{1}/{2}]" -f $sp.name, $i, $allServerProfiles.Count | Write-Host
		foreach ($myjbod in $sp.localStorage.sasLogicalJBODs) {
			if ($myjbod.sasLogicalJBODUri -ne $null) {
				$myuri = "{0}/drives" -f $myjbod.sasLogicalJBODUri
				$jbodDrives = Send-HPOVRequest -uri $myuri -ApplianceConnection $sp.ApplianceConnection
				foreach ($myjboddrive in $jbodDrives) {
					
					$myobj= [PSCustomObject][Ordered]@{
						spname = $sp.Name
						spserialnumber = $sp.serialNumber
						spuuid = $sp.uuid
						spuri = $sp.uri
						spserverhardwareuri = $sp.serverHardwareUri
						spjbodname = $myjbod.Name
						spjbodstatus = $myjbod.status
						spjbodrivemodel = $myjboddrive.model
						spjboddrivesn=$myjboddrive.serialNumber
					}
					[void]$spjboddrives.Add($myobj)
				}
			}
		}
		#"Is a VMhost ?"
		$vmhost = $vmhosts | ? { $_.Hardware.SystemInfo.Uuid -eq $sp.uuid }
		if ($vmhost) {
			getVMwareData($vmhost)
			if ($PSBoundParameters['extraSsdInfo']) {
				$esxcli = Get-Esxcli -V2 -VMHost $vmhost.Name
				getSsdInfo($esxcli)
			}
		}
		$i++
	}
	foreach ($dc in $datacenters) {	
		$apiVersion = $PSLibraryVersion.$($oneview.Name).XApiVersion
		$oneviewVersion = $PSLibraryVersion.$($oneview.Name).ApplianceVersion.ToString()
		"{0} --> ({1}, {2})" -f $dc.name, $oneviewVersion, $apiVersion | Write-Host
		$racks = $dc.contents.resourceUri | % { Send-HPOVRequest -uri $_ }
		foreach ($rk in $racks) {
			"`tRack : {0}" -f $rk.Name | Write-Host
			$enclosures = [System.Collections.ArrayList]::new()
			$rk.rackMounts | % { [void]$enclosures.Add( (Send-HPOVRequest -uri $_.mountUri) ) }
			foreach ($en in $enclosures) {
				$eg=$allEnclosureGroups | ? { $_.uri -eq $en.enclosureGroupUri }
				$le=$allLogicalEnclosures | ? { $_.uri -eq $en.logicalEnclosureUri }
				"`t`tEnclosure{0} : {1}" -f $j, $en.Name | Write-Host
				$driveBayEnclosures = $en.deviceBays | ? { $_.coveredByDevice -like "/rest/drive-enclosures/*" -and $_.devicePresence -eq "Present" }
				$driveEnclosures = [System.Collections.ArrayList]::new()
				$driveBayEnclosures | % { [void]$driveEnclosures.Add( (Send-HPOVRequest -uri $_.deviceUri) ) }
				
				foreach ($de in $driveEnclosures) {
					"`t`t`tDrive Enclosure : {0}" -f $de.Name | Write-Host
					foreach ($db in $de.driveBays) {
						$record = New-Object PSObject -Property $ovRecordProperties
						$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
						$record."Data Center" = $dc.name
						$record.Rack = $rk.name
						$record.Enclosure = $en.name
						$record."Enclosure Group" = $eg.name
						$record."Logical Enclosure" = $le.name
						$record."Drive Enclosure" = $de.name
						$record."Drive Bay" = $db.driveBayLocation.locationEntries.value
						# Drive in bay ?
						if ($db.drive -ne $null) {
							$record."Drive Model" = $db.drive.model
							$record."Drive SN" = $db.drive.serialNumber
							$record."Drive FW" = $db.drive.firmwareVersion
							$record."Drive Capacity" = $db.drive.capacity
							$record."Drive WWID" = $db.drive.wwid
							$record."Drive State" = $db.drive.state
							$record."Drive Status" = $db.drive.status
							
							$sp = $spjboddrives | ? { $_.spjboddrivesn -eq $db.drive.serialNumber }
							# Drive attached to a server Profile ?
							if ($sp -ne $null) {
								$sh = $allServers | ? { $_.uri -eq $sp.spserverhardwareuri }
								$record."Server Profile" = $sp.spname
								$record."Server Profile SN" = $sp.spserialnumber
								$record."JBOD Name" = $sp.spjbodname
								$record."JBOD Status" = $sp.spjbodstatus
								# Server Hardware attached to Server Profile ?
								if ($sh -ne $null) {
									$record."Server Hardware Name" = $sh.name
									$record."Server Hardware SN" = $sh.serialNumber
									$record."Server Hardware PowerState" = $sh.powerState
									$record."Server Hardware Position" = $sh.position
								} 

								# Is Server Hardware a VMware Host in vCenter ?
								$vmhostDisks = $vmwareData | ? { $_.hostUuid -eq $sp.spuuid }
								if ($vmhostDisks -ne $null) {
									$record."vSphere Hostname" = $vmhostDisks[0].host
									$record."vCenter Server" = $vmhostDisks[0].vcenter
									
									"`t`t`t`tVMHost : {0}" -f $vmhostDisks[0].host | Write-Debug
									foreach ($vmhostDisk in $vmhostDisks) {
										if (checkwwid $db.drive.wwid $vmhostDisk.wwid ) {
											$record."vSphere Cluster" = $vmhostDisk.cluster
											$record."vSphere NAA" = $vmhostDisk.naa
											$record."vSAN Diskgroup" = $vmhostDisk.vsandiskgroup
											$record."vSAN Disk Usage" = $vmhostDisk.vsandiskusage
											$record."vSAN Disk UUID" = $vmhostDisk.vsandiskvsanuuid
											$record."vSAN Disk Format Version" = $vmhostDisk.vsandiskfomatversion
										}
									}
									
									if ($PSBoundParameters['extraSsdInfo']) {
										$mySsdInfo = $ssdInfo | ? { $_."Serial Number" -eq $db.drive.serialNumber }
										$record."Current Temperature (C)" = $mySsdInfo."Current Temperature (C)"
										$record."Maximum Temperature (C)" = $mySsdInfo."Maximum Temperature (C)"
										$record."Usage remaining (%)" = $mySsdInfo."Usage remaining (%)"
										$record."Power On Hours" = $mySsdInfo."Power On Hours"
										$record."Estimated Life Remaining based on workload to date (days)"  = $mySsdInfo."Estimated Life Remaining based on workload to date (days)" 
										$record."Drive"  = $mySsdInfo."Drive" 
										$record."WWID"  = $mySsdInfo."WWID"

									}
								} 
							} 
						} 
						$record | Add-Member -MemberType NoteProperty -Name "Inventory Date" -Value (Get-Date)
						[void]$hpeovreport.Add($record)
					}
				}
				$j++
			}
		}
	}
	$hpeovreport | Export-CSV @HPEOVREPORTCSVOPTIONS -Append
	$hpeovreport = [System.Collections.ArrayList]::new()
}
#endregion


