#requires -version 4
<#
.SYNOPSIS
	Get Firmware Inventory (Appliance, FLM, interconnect, storage enclosure, drive, compute, mezzanines, ...) on all HPE OneView connected sessions
	
.INPUTS
	None
	
.OUTPUTS
	CSV file hpe_serialnumbers.csv in $PSScriptRoot\reports (must exist)
	CSV columns :
		Data Center
		Rack
		Enclosure
		Enclosure Group
		Logical Enclosure
		Device Bay
		Device Type
		Device Model
		Device Name
		Device SN
		Device Firmware
		Resource URI
	
.NOTES
	Filename:		get_serialnumbers.ps1
	Version:		2.7
	Author:			olivier.desaphy@hpe.com
	Creation Date:	2019-11-13
	Purpose/Change:	Initial
			2.3 : new Qfle3 driver name
				  change $reportSerialNumbers type : System.Object[] to System.Collections.ArrayList
				  new "Device partNumber" column
			2.4 : local drives
		        2020-07-31: Catch and ignore error of Send-HPOVRequest on serverFirmwareInventoryUri. So script doesn't crash when iLO is down (Mounaam)
		    2.5 : adding ethernet/smartarray drivers for BM
			      adding amsd (Device Type=server-amsd) & sut (Device Type=server-sut) infos 
			2.6 : 20210408 : Adding partNumber for composer appliances.
			2.7 : 20220827 : Adding bm05 driver for 4820c is qlgc-fastlinq
			2.8 : 20220907 : for "Device Type" = server-hardware ==> "Device Name" = <server hardware name>, <server profile name|noprofile>
			2.8.1 : 20220930 : for all Device Type associated to a Server Hardware (iLO5, Mezzanine ...) ==> "Device Name" = <server hardware name>, <server profile name|noprofile>, <subdevice>
.EXAMPLE
	[path to]/get_serialnumbers.ps1
#>

if (! (Get-Module HPERedfishCmdlets)) {
    Write-Host "Importing HPERedfishCmdlets module ..." -ForegroundColor Yellow
    Import-Module "C:\Program Files\Hewlett Packard Enterprise\PowerShell\Modules\HPERedfishCmdlets\1.0.0.2\HPERedfishCmdlets.psd1"
}

Disable-HPERedfishCertificateAuthentication

$OUTPUTDIR = "{0}\reports" -f $PSScriptRoot

$HPEOVREPORTCSVOPTIONS = @{
	"NoTypeInformation" = $true
	"Delimiter" = ";"
	"Encoding" = "UTF8"
} 

$HPEOVREPORTSUBRECORDSEP="|"

$platform=${Global:HPEplatform}

"Connected to {0}" -f $platform |Write-Host -ForegroundColor Green

$reportSerialNumbers=[System.Collections.ArrayList]::new()

$reportSerialNumbersFile = "hpe_{0}_serialnumbers_{1}.csv" -f $platform, (Get-date -Format "yyyyMMdd-HHmmss")
$ovSerialNumbersProperties = [Ordered]@{
	"OneView Domain" = $null
	"Data Center" = $null
	Rack = $null
	Enclosure = $null
	"Enclosure Group" = $null
	"Logical Enclosure" = $null
	"Device Bay" = $null
	"Device Type" = $null
	"Device Model" = $null
	"Device Name" = $null
	"Device SN" = $null
	"Device Firmware" = $null
	"Device PartNumber" = $null
	"Resource URI" = $null
	"Inventory Date" = $null
}

# Variable $dc2oneviewDomain is sourced from [ABC]_profile.ps1
Get-Variable -Name dc2oneviewDomain -ErrorAction Stop | Out-Null



foreach ($oneview in $global:ConnectedSessions) {
	if (($global:ConnectedSessions).count -gt 1) {
		Set-HPOVApplianceDefaultConnection -ApplianceConnection $oneview | Out-Null
	}
	$apiVersion = $PSLibraryVersion.$($oneview.Name).XApiVersion
	$oneviewVersion = $PSLibraryVersion.$($oneview.Name).ApplianceVersion
	$oneviewVersion = "{0}.{1:d2}.{2:d2}" -f $oneviewVersion.Major, $oneviewVersion.Minor, $oneviewVersion.Build
		
	
	$datacenters=Get-HPOVDataCenter  -ErrorAction SilentlyContinue
	$composers=Get-HPOVComposerNode
	$allEnclosureGroups = (Send-HPOVRequest -uri "/rest/enclosure-groups/?start=0&count=-1" -method "GET").members
	$allLogicalEnclosures = (Send-HPOVRequest -uri "/rest/logical-enclosures/?start=0&count=-1" -method "GET").members
	foreach ($dc in $datacenters) {
		"{0}/{1} --> ({2}, {3})" -f $dc2oneviewDomain[$dc.name], $dc.name, $oneviewVersion, $apiVersion | Write-Host
		$racks = $dc.contents.resourceUri | % { Send-HPOVRequest -uri $_ }

		foreach ($rk in $racks) {
			"`tRack : {0}" -f $rk.Name | Write-Host
			$enclosures = $rk.rackMounts.mountUri | % { Send-HPOVRequest -uri $_  }
			foreach ($en in $enclosures) {
				"`t`tEnclosure : {0}" -f $en.Name | Write-Host
				$eg=$allEnclosureGroups | ? { $_.uri -eq $en.enclosureGroupUri }
				$le=$allLogicalEnclosures | ? { $_.uri -eq $en.logicalEnclosureUri }
	#region enclosure
				$record = New-Object PSObject -Property $ovSerialNumbersProperties
				$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
				$record."Data Center" = $dc.name
				$record."Rack" = $rk.Name
				$record."Enclosure" = $en.Name
				$record."Enclosure Group" = $eg.name
				$record."Logical Enclosure" = $le.name
				$record."Device Type" = $en.type
				$record."Device Model" = $en.enclosureModel
				$record."Device Name" = $en.name
				$record."Device SN" = $en.serialNumber
				$record."Device PartNumber" = $en.partNumber
				$record."Resource URI" = $en.uri
				$record."Inventory Date" = Get-Date
				[void]$reportSerialNumbers.Add($record)
	#endregion
	#region deviceBays
				foreach ($bay in $en.deviceBays) {
					if ($bay.devicePresence -eq "Present") {
						$device = Send-HPOVRequest -uri $bay.deviceUri
	#region drive-enclosure
						if ($device.category -eq "drive-enclosures") {
							$record = New-Object PSObject -Property $ovSerialNumbersProperties
							$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
							$record."Data Center" = $dc.name
							$record."Rack" = $rk.Name
							$record."Enclosure" = $en.Name
							$record."Enclosure Group" = $eg.name
							$record."Logical Enclosure" = $le.name
							$record."Device Bay" = $bay.bayNumber
							$record."Device Type" = $device.type
							$record."Device Model" = $device.model
							$record."Device Name" = $device.name
							$record."Device SN" = $device.serialNumber
							$record."Device firmware" = $device.firmwareVersion
							$record."Device PartNumber" = $device.partNumber
							$record."Resource URI" = $device.uri
							$record."Inventory Date" = Get-Date
							[void]$reportSerialNumbers.Add($record)
							
							foreach ($io in $device.ioAdapters) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = $io.type
								$record."Device Model" = $io.model
								$record."Device Name" = "{0}, IO Adapter {1}" -f $device.name, $io.ioAdapterLocation.locationEntries.value
								$record."Device SN" = $io.serialNumber
								$record."Device firmware" = $io.firmwareVersion
								$record."Device PartNumber" = $io.partNumber.Trim()
								$record."Resource URI" = $io.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							
							foreach ($db in $device.driveBays) {
								if ($db.attachedDeviceInterface -ne "NODEV") {
									$record = New-Object PSObject -Property $ovSerialNumbersProperties
									$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
									$record."Data Center" = $dc.name
									$record."Rack" = $rk.name
									$record."Enclosure" = $en.name
									$record."Enclosure Group" = $eg.name
									$record."Logical Enclosure" = $le.name
									$record."Device Bay" = $bay.bayNumber
									#$record."Device Type" = $db.drive.type
									$record."Device Type" = ("drive-enclosure-{0}{1}-drive" -f $db.drive.deviceInterface, $db.drive.driveMedia).ToLower()
									$record."Device Model" = $db.drive.model
									$record."Device Name" = "{0}, Drive {1}" -f $device.name, $db.driveBayLocation.locationEntries.value
									$record."Device SN" = $db.drive.serialNumber
									$record."Device firmware" = $db.drive.firmwareVersion
									$record."Resource URI" = $db.drive.uri
									$record."Inventory Date" = Get-Date
									[void]$reportSerialNumbers.Add($record)
								}
							}
						}
	#endregion
	#region server-hardware
						if ($device.category -eq "server-hardware") {
							#server-hardware
							# Server Profile on server-hardware ?
							if ($device.serverProfileUri) {
								$deviceName = "{0}, {1}" -f $device.name, (Send-HPOVRequest -uri $device.serverProfileUri).name
							} else {
								$deviceName = "{0}, noprofile" -f $device.name
							}
							$record = New-Object PSObject -Property $ovSerialNumbersProperties
							$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
							$record."Data Center" = $dc.name
							$record."Rack" = $rk.name
							$record."Enclosure" = $en.name
							$record."Enclosure Group" = $eg.name
							$record."Logical Enclosure" = $le.name
							$record."Device Bay" = $bay.bayNumber
							$record."Device Type" = $device.type
							$record."Device Model" = "{0}" -f $device.model
							$record."Device Name" = "{0}" -f $deviceName
							$record."Device SN" = $device.serialNumber
							$record."Device firmware" = $device.romVersion
							$record."Device PartNumber" = $device.partNumber
							$record."Resource URI" = $device.uri
							$record."Inventory Date" = Get-Date
							[void]$reportSerialNumbers.Add($record)
							
							#iLO
							$record = New-Object PSObject -Property $ovSerialNumbersProperties
							$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
							$record."Data Center" = $dc.name
							$record."Rack" = $rk.name
							$record."Enclosure" = $en.name
							$record."Enclosure Group" = $eg.name
							$record."Logical Enclosure" = $le.name
							$record."Device Bay" = $bay.bayNumber
							$record."Device Type" = "server-ilo"
							$record."Device Model" = $device.mpModel
							$record."Device Name" = "{0}, {1}" -f $deviceName, $device.mpHostInfo.mpHostName
							$record."Device firmware" = $device.mpFirmwareVersion
							$record."Resource URI" = $device.uri
							$record."Inventory Date" = Get-Date
							[void]$reportSerialNumbers.Add($record)
							
							#firmwares
						    Try {
							$fw = Send-HPOVRequest -uri $device.serverFirmwareInventoryUri -ApplianceConnection $device.ApplianceConnection -OverrideTimeout 90000
						    }
						    Catch {}
						    If ( $fw ) {
							# Agentless Management Service
							$component = $fw.components | ? { $_.componentName -like "Agentless Management Service*" }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-amsd"
								$record."Device Model" = $component.componentName
								$record."Device Name" = "{0}, amsd" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							# SUT
							$component = $fw.components | ? { $_.componentName -like "Integrated Smart Update Tools*" }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-sut"
								$record."Device Model" = $component.componentName
								$record."Device Name" = "{0}, sut" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							
							# System Programmable Logic Device
							$component = $fw.components | ? { $_.componentName -eq "System Programmable Logic Device" }
							$record = New-Object PSObject -Property $ovSerialNumbersProperties
							$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
							$record."Data Center" = $dc.name
							$record."Rack" = $rk.name
							$record."Enclosure" = $en.name
							$record."Enclosure Group" = $eg.name
							$record."Logical Enclosure" = $le.name
							$record."Device Bay" = $bay.bayNumber
							$record."Device Type" = "server-cpld"
							$record."Device Model" = $component.componentName
							$record."Device Name" = "{0}, cpld" -f $deviceName
							$record."Device firmware" = $component.componentVersion
							$record."Resource URI" = $device.uri
							$record."Inventory Date" = Get-Date
							[void]$reportSerialNumbers.Add($record)
							
							# Power
							$component = $fw.components | ? { $_.componentName -eq "Power Management Controller Firmware" }
							$record = New-Object PSObject -Property $ovSerialNumbersProperties
							$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
							$record."Data Center" = $dc.name
							$record."Rack" = $rk.name
							$record."Enclosure" = $en.name
							$record."Enclosure Group" = $eg.name
							$record."Logical Enclosure" = $le.name
							$record."Device Bay" = $bay.bayNumber
							$record."Device Type" = "server-power"
							$record."Device Model" = $component.componentName
							$record."Device Name" = "{0}, {1}" -f $deviceName, $component.componentName 
							$record."Device firmware" = $component.componentVersion
							$record."Resource URI" = $device.uri
							$record."Inventory Date" = Get-Date
							[void]$reportSerialNumbers.Add($record)
							
							# Intelligent Provisionning
							$component = $fw.components | ? { $_.componentName -eq "Intelligent Provisioning" }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-ip"
								$record."Device Model" = $component.componentName
								$record."Device Name" = "{0}, {1}" -f $deviceName, $component.componentName 
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							# NIC Driver HCI
							$component = $fw.components | ? { $_.componentName -in @("NIC Driver for HPE Synergy 3820C 10/20Gb Converged Network Adapter", "Native QLogic E3 network driver for VMware ESXi") }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-nicdriver"
								$record."Device Model" = "qfle3"
								$record."Device Name" = "{0}, nic-driver" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							
							# NIC Driver BM
							$component = $fw.components | ? { $_.componentName -like "netxtreme2 kernel module*" }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-nicdriver"
								$record."Device Model" = "bnx2x"
								$record."Device Name" = "{0}, nic-driver" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}

							# NIC Driver BM05
							$component = $fw.components | ? { $_.componentName.StartsWith("qlgc-fastlinq kernel") }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-nicdriver"
								$record."Device Model" = "qede"
								$record."Device Name" = "{0}, nic-driver" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							
							# SmartArray Driver
							$component = $fw.components | ? { $_.componentName -eq "VMware native driver module for Microsemi SmartPqi controllers" }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-sadriver"
								$record."Device Model" = "smartpqi"
								$record."Device Name" = "{0}, sa-driver" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							
							# SmartArray Driver BM Gen9
							$component = $fw.components | ? { $_.componentName -like "hpsa kernel module*" }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-sadriver"
								$record."Device Model" = "hpsa"
								$record."Device Name" = "{0}, sa-driver" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
							# SmartArray Driver BM Gen10
							$component = $fw.components | ? { $_.componentName -like "smartpqi kernel module*" }
							if ($component) {
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-sadriver"
								$record."Device Model" = "smartpqi"
								$record."Device Name" = "{0}, sa-driver" -f $deviceName
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}

							#server devices (/rest/server-hardware{i}/devices for OneView > 5.20 for Gen10 AND Gen9)
							<# $sh_devices = Send-HPOVRequest -uri ("{0}/devices" -f $device.uri) -ApplianceConnection $device.ApplianceConnection
							foreach ($sh_device in ($sh_devices.data |? { $_.Location -like "Mezzanine*" -or $_.Location -like "RAID" })) {
								if ($sh_device.Location -like "Mezzanine*") {
									$sh_device_type = "server-mezz{0}" -f $sh_device.Location.Substring(15,1)
								} elseif ($sh_devices.Location -like "*RAID*") {
									$sh_device_type = "server-embedded"
								}
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = $sh_device_type
								$record."Device Model" = $sh_device.Name
								$record."Device Name" = "{0}, {1}" -f $device.name, $sh_device.Name 
								$record."Device SN" = $sh_device.SerialNumber
								$record."Device firmware" = $sh_device.FirmwareVersion.Current.VersionString
								$record."Device PartNumber" = $sh_device.ProductPartNumber
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							} #>

							#server-embbedded
							$component = $fw.components | ? { $_.componentLocation.contains("Embedded RAID") }
							
							$record = New-Object PSObject -Property $ovSerialNumbersProperties
							$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
							$record."Data Center" = $dc.name
							$record."Rack" = $rk.name
							$record."Enclosure" = $en.name
							$record."Enclosure Group" = $eg.name
							$record."Logical Enclosure" = $le.name
							$record."Device Bay" = $bay.bayNumber
							$record."Device Type" = "server-embbedded"
							$record."Device Model" = $component.componentName
							$record."Device Name" = "{0}, {1}" -f $deviceName, $component.componentName 
							$record."Device firmware" = $component.componentVersion
							$record."Resource URI" = $device.uri
							$record."Inventory Date" = Get-Date
							[void]$reportSerialNumbers.Add($record)
							
							#server-mezz[1..3]
							foreach ($slotid in 1..3) {
								if ($device.mpModel -eq "ILO5") {
									$component = $fw.components | ? { $_.componentLocation -eq "Mezzanine Slot ${slotid}" }
									if (-not $component) {
										$component = $fw.components | ? { $_.componentLocation -eq "Slot ${slotid}" }
									}
								} else {
									$component = $fw.components | ? { $_.componentLocation -eq "Slot ${slotid}" }
								}
								$record = New-Object PSObject -Property $ovSerialNumbersProperties
								$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
								$record."Data Center" = $dc.name
								$record."Rack" = $rk.name
								$record."Enclosure" = $en.name
								$record."Enclosure Group" = $eg.name
								$record."Logical Enclosure" = $le.name
								$record."Device Bay" = $bay.bayNumber
								$record."Device Type" = "server-mezz${slotid}"
								$record."Device Model" = $component.componentName
								$record."Device Name" = "{0}, {1}" -f $deviceName, $component.componentName 
								$record."Device firmware" = $component.componentVersion
								$record."Resource URI" = $device.uri
								$record."Inventory Date" = Get-Date
								[void]$reportSerialNumbers.Add($record)
							}
						    }
							$foundLocalDrives = $false
							# Getting local drives for Gen10 for OneView >= 4.20 (apiversion >= 1000)
							if ($device.model.Contains("Gen10") -and ($apiVersion -ge 1000))  {
								$localStorageUri = "{0}/localStorage" -f $device.uri
								$localStorage = Send-HPOVRequest -uri $localStorageUri -AddHeader @{"X-Api-Version" = $apiVersion }
								foreach ($pd in ($localStorage.data | ? { $_.Location -eq "Slot 0" }).PhysicalDrives) {
									$record = New-Object PSObject -Property $ovSerialNumbersProperties
									$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
									$record."Data Center" = $dc.name
									$record."Rack" = $rk.name
									$record."Enclosure" = $en.name
									$record."Enclosure Group" = $eg.name
									$record."Logical Enclosure" = $le.name
									$record."Device Bay" = $bay.bayNumber
									$record."Device Type" = ("server-{0}{1}-drive" -f $pd.InterfaceType,$pd.MediaType).ToLower()
									$record."Device Model" = $pd.Model
									$record."Device Name" = "{0}, {1}" -f $deviceName, $pd.Location
									$record."Device SN" = $pd.SerialNumber
									$record."Device firmware" = $pd.FirmwareVersion.Current.VersionString
									$record."Resource URI" = $device.uri
									$record."Inventory Date" = Get-Date
									[void]$reportSerialNumbers.Add($record)
									$foundLocalDrives = $true
								}
								# Debug (Internal SmartArray not detected ...)
								if (($localStorage.count -eq 1) -and ($foundLocalDrives -eq $false)) {
									"WARNING : {0} {1}/{2} {3}: Local SmartArray not detected but Slot 1 Detected ({4}/{5})" -f $dc2oneviewDomain[$dc.name], $oneviewVersion, $apiversion, $device.name, $localstorage.data.Model, $localstorage.data.SerialNumber.Trim() | Write-Host -ForegroundColor Yellow
								}
							}
							# Case HVD01 (OneView 4.10.05 + Gen9) + LABBM01 (OneView 4.20.02 + Gen9)
							if ($device.model.Contains("Gen9") -and ($apiVersion -ge 800) ) {
								foreach ($pd in ($fw.components | ? { $_.componentLocation.Contains("ControllerPort 1I") })) {
									$result=$pd.componentLocation | Select-String '(ControllerPort|Box|Bay)\s([^,]+)' -AllMatches
									$pdLocation = "{0}:{1}:{2}" -f $result.Matches[0].Groups[2].Value, $result.Matches[1].Groups[2].Value, $result.Matches[2].Groups[2].Value
									$result=$pd.componentName | Select-String 'HpSmartStorageDiskDrive\s\((.*)\)'
									$pdInterfaceType = $result.Matches[0].Groups[1].Value 
									$pdMediaType = "ssd"
									$record = New-Object PSObject -Property $ovSerialNumbersProperties
									$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
									$record."Data Center" = $dc.name
									$record."Rack" = $rk.name
									$record."Enclosure" = $en.name
									$record."Enclosure Group" = $eg.name
									$record."Logical Enclosure" = $le.name
									$record."Device Bay" = $bay.bayNumber
									$record."Device Type" = ("server-{0}{1}-drive" -f $pdInterfaceType,$pdMediaType).ToLower()
									$record."Device Model" = $pd.componentKey
									$record."Device Name" = "{0}, {1}" -f $deviceName, $pdLocation
									$record."Device firmware" = $pd.componentVersion
									$record."Resource URI" = $device.uri
									$record."Inventory Date" = Get-Date
									[void]$reportSerialNumbers.Add($record)
									$foundLocalDrives = $true
								}
							}
							
							# Case BM01 (OneView 4.00.09(600) + Gen9)
							if ($device.model.Contains("Gen9") -and ($apiVersion -eq 600) ) {
								foreach ($pd in ($fw.components | ? { $_.componentName -eq "HpSmartStorageDiskDrive (SATA)" })) {
									$result=$pd.componentLocation | Select-String 'Bay\s([^,]+)'
									$pdLocation = "1I:1:{0}" -f $result.Matches[0].Groups[1].Value
									$pdInterfaceType = "sata" 
									$pdMediaType = "ssd"
									$record = New-Object PSObject -Property $ovSerialNumbersProperties
									$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
									$record."Data Center" = $dc.name
									$record."Rack" = $rk.name
									$record."Enclosure" = $en.name
									$record."Enclosure Group" = $eg.name
									$record."Logical Enclosure" = $le.name
									$record."Device Bay" = $bay.bayNumber
									$record."Device Type" = ("server-{0}{1}-drive" -f $pdInterfaceType,$pdMediaType).ToLower()
									$record."Device Model" = $pd.componentKey
									$record."Device Name" = "{0}, {1}" -f $deviceName, $pdLocation
									$record."Device firmware" = $pd.componentVersion
									$record."Resource URI" = $device.uri
									$record."Inventory Date" = Get-Date
									[void]$reportSerialNumbers.Add($record)
									$foundLocalDrives = $true
								}
							}
							
							# $foundLocalDrives = $false --> adding dummy drives
							if (-not $foundLocalDrives) {
								foreach ($pdBayId in (1..2)) {
									$pdLocation = "1I:1:{0}" -f $pdBayId
									$pdInterfaceType = "sata" 
									$pdMediaType = "ssd"
									$record = New-Object PSObject -Property $ovSerialNumbersProperties
									$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
									$record."Data Center" = $dc.name
									$record."Rack" = $rk.name
									$record."Enclosure" = $en.name
									$record."Enclosure Group" = $eg.name
									$record."Logical Enclosure" = $le.name
									$record."Device Bay" = $bay.bayNumber
									$record."Device Type" = ("server-{0}{1}-drive" -f $pdInterfaceType,$pdMediaType).ToLower()
									# $record."Device Model" = ""
									$record."Device Name" = "{0}, {1}" -f $deviceName, $pdLocation
									# $record."Device firmware" = $pd.componentVersion
									$record."Resource URI" = $device.uri
									$record."Inventory Date" = Get-Date
									[void]$reportSerialNumbers.Add($record)		
								}
							}
						}
	#endregion
					}
				}
	#endregion
	#region interconnectbays
				foreach ($bay in $en.interconnectBays) {
					if ($bay.interconnectUri -ne $null) {
						$device = Send-HPOVRequest -uri $bay.interconnectUri
						$record = New-Object PSObject -Property $ovSerialNumbersProperties
						$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
						$record."Data Center" = $dc.name
						$record."Rack" = $rk.name
						$record."Enclosure" = $en.name
						$record."Enclosure Group" = $eg.name
						$record."Logical Enclosure" = $le.name
						$record."Device Bay" = $bay.bayNumber
						$record."Device Type" = $device.type
						$record."Device Model" = $device.model
						$record."Device Name" = $device.name
						$record."Device SN" = $device.serialNumber
						$record."Device Firmware" = $device.firmwareVersion
						$record."Device PartNumber" = $device.partNumber
						$record."Resource URI" = $device.uri
						$record."Inventory Date" = Get-Date
						[void]$reportSerialNumbers.Add($record)
					}
				}
	#endregion
	#region managerBays
				foreach ($bay in $en.managerBays) {
					if ($bay.devicePresence -eq "Present") {
						$record = New-Object PSObject -Property $ovSerialNumbersProperties
						$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
						$record."Data Center" = $dc.name
						$record."Rack" = $rk.name
						$record."Enclosure" = $en.name
						$record."Enclosure Group" = $eg.name
						$record."Logical Enclosure" = $le.name
						$record."Device Bay" = $bay.bayNumber
						$record."Device Type" = $bay.managerType
						$record."Device Model" = $bay.model
						$record."Device Name" = "{0}, FLM{1}" -f $en.name, $bay.bayNumber
						$record."Device SN" = $bay.serialNumber
						$record."Device Firmware" = $bay.fwVersion
						$record."Device PartNumber" = $bay.partNumber
						$record."Resource URI" = $en.uri
						$record."Inventory Date" = Get-Date
						[void]$reportSerialNumbers.Add($record)
					}
				}
	#endregion
	#region applianceBays
				foreach ($bay in $en.applianceBays) {
					if ($bay.devicePresence -eq "Present") {
						$cmp = $composers | ? { $_.Name -eq ("{0}, appliance bay {1}" -f $en.name, $bay.bayNumber) }
						$record = New-Object PSObject -Property $ovSerialNumbersProperties
						$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
						$record."Data Center" = $dc.name
						$record."Rack" = $rk.name
						$record."Enclosure" = $en.name
						$record."Enclosure Group" = $eg.name
						$record."Logical Enclosure" = $le.name
						$record."Device Bay" = $bay.bayNumber
						$record."Device Type" = "appliance"
						$record."Device Model" = $bay.model
						$record."Device Name" = "{0}, appliance bay {1}" -f $en.name, $bay.bayNumber
						$record."Device SN" = $bay.serialNumber
						$record."Device Firmware" = $cmp.version
						$record."Device PartNumber" = $bay.partNumber
						$record."Resource URI" = $cmp.uri
						$record."Inventory Date" = Get-Date
						[void]$reportSerialNumbers.Add($record)
					}
				}
	#endregion
	#region fanBays
				foreach ($fan in $en.fanBays) {
					$record = New-Object PSObject -Property $ovSerialNumbersProperties
					$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
					$record."Data Center" = $dc.name
					$record.Rack = $rk.name
					$record.Enclosure = $en.name
					$record."Enclosure Group" = $eg.name
					$record."Logical Enclosure" = $le.name
					$record."Device Bay" = $fan.bayNumber
					$record."Device Type" = "fan"
					$record."Device Model" = $fan.model
					$record."Device Name" = "{0}, fan bay {1}" -f $en.name, $fan.bayNumber
					$record."Device SN" = $fan.serialNumber
					$record."Device PartNumber" = $fan.partNumber
					$record."Inventory Date" = Get-Date
					[void]$reportSerialNumbers.Add($record)
				}
	#endregion
	#region PowerSupplies
				foreach ($ps in $en.powerSupplyBays) {
					$record = New-Object PSObject -Property $ovSerialNumbersProperties
					$record."OneView Domain" = $dc2oneviewDomain[$dc.name]
					$record."Data Center" = $dc.name
					$record.Rack = $rk.name
					$record.Enclosure = $en.name
					$record."Enclosure Group" = $eg.name
					$record."Logical Enclosure" = $le.name
					$record."Device Bay" = $ps.bayNumber
					$record."Device Type" = "powersupply"
					$record."Device Model" = $ps.model
					$record."Device Name" = "{0}, power supply {1}" -f $en.name, $fan.bayNumber
					$record."Device SN" = $ps.serialNumber
					$record."Device PartNumber" = $ps.partNumber
					$record."Inventory Date" = Get-Date
					[void]$reportSerialNumbers.Add($record)
				}
	#endregion
			}
		}
	}
	$reportSerialNumbers | Export-Csv @HPEOVREPORTCSVOPTIONS -Path $OUTPUTDIR\$reportSerialNumbersFile -Append
	$reportSerialNumbers = [System.Collections.ArrayList]::new()
}
