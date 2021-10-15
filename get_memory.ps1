#requires -version 4
<#
.SYNOPSIS
	Get DIMM inventory on servers managed by OneView (Synergy & DL	).
	
	Tested with HPEOneView.610 & HPERedFishCmdlets modules
	
	Needs iLO5 > 1.40
.INPUTS
	None
	
.OUTPUTS
	csvFile : csv file containing the inventory
	
.NOTES
	Filename:		get_memory.ps1
	Version:		1.0
	Author:			olivier.desaphy@hpe.com
	Creation Date:	2021-10-15
	Purpose/Change:	2021-10-15 - v1.0 - Initial Version

.EXAMPLE
	.\get_memory.ps1
	get DIMM inventory on servers managed by OneView (must be already connected to one or more OneView) 
#>

Disable-HPERedfishCertificateAuthentication

$OUTPUTDIR = "{0}\reports" -f $PSScriptRoot

$HPEOVREPORTCSVOPTIONS = @{
	"NoTypeInformation" = $true
	"Delimiter" = ";"
	"Encoding" = "UTF8"
} 

$platform="bg"

"Connected to {0}" -f $platform | Write-Host -ForegroundColor Green

$report=[System.Collections.ArrayList]::new()

$reportFile = "hpe_{0}_memory_{1}.csv" -f $platform, (Get-date -Format "yyyyMMdd-HHmmss")
$recordProperties = [Ordered]@{
	"OneView" = $null
	"Server" = $null
	"Server Model" = $null
	"Server SN" = $null
	"DIMM Name" = $null
	"DIMM Location" = $null
	"DIMM State" = $null
	"DIMM Size" = $null
	"DIMM Frequency" = $null
	"DIMM PartNumber" = $null
	"DIMM SerialNumber" = $null
	"DIMM MemoryType" = $null
	"DIMM BaseModuleType" = $null
	"DIMM MemoryDeviceType" = $null
	"DIMM Manufacturer" = $null
	"DIMM VendorName" = $null
	"Inventory Date" = $null
}

foreach ($oneview in $global:ConnectedSessions) {
	if (($global:ConnectedSessions).count -gt 1) {
		Set-OVApplianceDefaultConnection -ApplianceConnection $oneview | Out-Null
	}
	$apiVersion = $PSLibraryVersion.$($oneview.Name).XApiVersion
	$oneviewVersion = $PSLibraryVersion.$($oneview.Name).ApplianceVersion
	$oneviewVersion = "{0}.{1:d2}.{2:d2}" -f $oneviewVersion.Major, $oneviewVersion.Minor, $oneviewVersion.Build
	"{0} --> {1}/{2}" -f $oneview.Name.split(".")[0], $oneviewVersion, $apiVersion
	$all_sh = Get-OvServer
	$i=1
	foreach ($sh in $all_sh) {
		"`tServer {0} [{1}/{2}]" -f $sh.name, $i, $all_sh.Count
		$iloSession = $sh | Get-OvIloSso -IloRestSession

		$sessions = Get-HPERedFishDataRaw -Odataid '/redfish/v1/SessionService/Sessions' -Session $iloSession
		$oemPropertyName = $sessions.Oem.PSObject.Properties.name
		$session = $sessions.Oem.${oemPropertyName}.Links.MySession
		$iloSession.Location = $session.'@odata.id'
		$rootData = Get-HPERedFishDataRaw -OdataId '/redfish/v1' -Session $iloSession
		$iloSession | Add-Member -MemberType NoteProperty -Name 'RootData' -Value $rootData

		$systems = Get-HPERedFishDataRaw -OdataId '/redfish/v1/Systems' -Session $iloSession

		foreach ($item in $systems.members) {
			$sys = Get-HPERedFishDataRaw -Odataid $item.'@odata.id' -Session $iloSession

			$uri = "{0}?`$expand=." -f $sys.Memory.'@odata.id'
			$memorySystem = Get-HPERedfishDataRaw $uri -Session $iloSession
			foreach ($dimm in $memorySystem.members) {
				$record = New-Object PSObject -Property $recordProperties
				$record."OneView" = $oneview.Name.split(".")[0]
				$record."Server" = $sh.name
				$record."Server Model" = $sh.model
				$record."Server SN" = $sh.serialNumber
				$record."DIMM Name" = $dimm.name
				$record."DIMM Location" = ("Processor {0} DIMM {1}" -f $dimm.MemoryLocation.Socket, $dimm.MemoryLocation.Slot)
				$record."DIMM State" = $dimm.Status.State
				if ($dimm.Status.State -ne "Absent") {
					$record."DIMM State" = $dimm.Status.State
					$record."DIMM Size" = ("{0} GB" -f ([int]($dimm.CapacityMiB)/1024))
					$record."DIMM Frequency" = ("{0} Mhz" -f $dimm.OperatingSpeedMhz)
					$record."DIMM PartNumber" = $dimm.PartNumber
					$record."DIMM SerialNumber" = $dimm.SerialNumber
					$record."DIMM MemoryType" = $dimm.MemoryType
					$record."DIMM BaseModuleType" = $dimm.BaseModuleType
					$record."DIMM MemoryDeviceType" = $dimm.MemoryDeviceType
					$record."DIMM Manufacturer" = $dimm.Manufacturer
					if ($dimm.Oem.Hpe) {
						$record."DIMM VendorName" = $dimm.Oem.Hpe.VendorName
					}
				}
				$record."Inventory Date" = Get-Date

				[void]$report.Add($record)
			}
		}
		Disconnect-HPERedfish -Session $iloSession
		$i++
		$report | Export-Csv @HPEOVREPORTCSVOPTIONS -Path $OUTPUTDIR\$reportFile -Append
		$report = [System.Collections.ArrayList]::new()
	}
	
}