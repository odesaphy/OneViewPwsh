#requires -version 4
<#
.SYNOPSIS
	Get Connector infos of all UplinkPort in all UplinkSets for each connected OneView
	(must be connected to 1 or more OneView) 
	
.INPUTS
	None
	
.OUTPUTS
	CSV file hpe_uplinksets_sfps_[yyyyMMdd-HHmmss].csv in current directory
	CSV columns :
		OneView
		OneView Version
		UplinkSet Name
		Uplinkset Type
		Interconnect Name
		Interconnect Model
		Interconnect FW
		Uplink Port
		Connector Type
		Connector Vendor
		Connector Part Number
		Connector Revision
		Connector Vendor OUI
		Connector Serial Number
		Inventory Date
	
.NOTES
	Filename:		get_uplinksets_sfps.ps1
	Version:		1.0
	Author:			olivier.desaphy@hpe.com
	Creation Date:	2021-04-14
	Purpose/Change:	Initial
					
.EXAMPLE
	[path to]/get_uplinksets_sfps.ps1
#>

$OUTPUTDIR = "{0}\reports" -f $PSScriptRoot

# Create OUTPUTDIR if necessary
if (-not (Test-Path -LiteralPath $OUTPUTDIR)) {    
    try {
        New-Item -Path $OUTPUTDIR -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch {
		$msg = "Unable to create directory '{0}'. Error was: {1}" -f $OUTPUTDIR, $_
        Write-Error -Message $msg -ErrorAction Stop
    }
}

$HPEOVREPORTCSVOPTIONS = @{
	"NoTypeInformation" = $true
	"Delimiter" = ";"
	"Encoding" = "UTF8"
} 


$reportUplinkSets=[System.Collections.ArrayList]::new()
$reportUplinkSetsFile = "hpe_uplinksets_sfps_{0}.csv" -f (Get-date -Format "yyyyMMdd-HHmmss")


$ovProperties = [Ordered]@{
	"OneView" = $null
	"OneView Version" = $null
	"UplinkSet Name" = $null
	"UplinkSet Type" = $null
	"Interconnect Name" = $null
	"Interconnect Model" = $null
	"Interconnect FW" = $null
	"Uplink Port" = $null
	"Connector Type" = $null
	"Connector Vendor" = $null
    "Connector Part Number" = $null
	"Connector Revision" = $null
	"Connector Vendor OUI" = $null
	"Connector Serial Number" = $null 
	"Inventory Date" = $null
}

$uri = "/rest/uplink-sets"

foreach ($oneview in $Global:ConnectedSessions) {
	if (($global:ConnectedSessions).count -gt 1) {
		Set-HPOVApplianceDefaultConnection -ApplianceConnection $oneview | Out-Null
	}
	$apiVersion = $PSLibraryVersion.$($oneview.Name).XApiVersion
	$oneviewVersion = $PSLibraryVersion.$($oneview.Name).ApplianceVersion
	$oneviewVersion = "{0}.{1:d2}.{2:d2}" -f $oneviewVersion.Major, $oneviewVersion.Minor, $oneviewVersion.Build
	
	"{0} --> ({1}, {2})" -f $oneview.name, $oneviewVersion, $apiVersion | Write-Host -ForegroundColor Yellow

	$uplinkSets = Send-HPOVRequest -uri $uri
	$i=1
	foreach ($uls in $uplinkSets.members) {
		"`tUplinkSet={0} [{1}/{2}]" -f $uls.name, $i, $uplinkSets.count | Write-Host -ForegroundColor Yellow
		foreach ($port in  $uls.portConfigInfos) {
			$intUri = $port.PortUri.Substring(0, $port.portUri.IndexOf("/ports"))
			$in = Send-HPOVRequest -uri $intUri
			
			$sfpUri = "{0}/pluggableModuleInformation" -f $intUri
			$sfpsOnInterconnect = Send-HPOVRequest -uri $sfpUri 
			
			$portName = ($port.location.locationEntries | ? { $_.type -eq "Port" }).value
			$sfp = $sfpsOnInterconnect | ? { $_.portName -eq $portName }
			
			$_port =  Send-HPOVRequest -uri $port.portUri
			
			$record = New-Object PSObject -Property $ovProperties
			
			$record."OneView" = $oneview.name
			$record."OneView Version" = $oneviewVersion
			$record."UplinkSet Name" = $uls.name
			$record."Uplinkset Type" = $uls.networkType
			$record."Interconnect Name" = $in.Name
			$record."Interconnect Model" = $in.Model
			$record."Interconnect FW" = $in.firmwareVersion
			$record."Uplink Port" = $_port.name
			$record."Connector Type" = $_port.connectorType.Trim()
			$record."Connector Vendor" = $sfp.vendorName.Trim()
			$record."Connector Part Number" = $sfp.vendorPartNumber.Trim()
			$record."Connector Revision" = $sfp.vendorRevision.Trim()
			$record."Connector Vendor OUI" = $sfp.vendorOui.Trim()
			$record."Connector Serial Number" =  $sfp.serialNumber.Trim()
			$record."Inventory Date" = Get-Date
			[void]$reportUplinkSets.Add($record)
		}
		$i++
	}
	$reportUplinkSets | Export-Csv @HPEOVREPORTCSVOPTIONS -Path $OUTPUTDIR\$reportUplinkSetsFile  -Append
	$reportUplinkSets = [System.Collections.ArrayList]::new()
}

$msg = "Report file: {0}/{1}" -f $OUTPUTDIR, $reportUplinkSetsFile
Write-Host $msg -ForegroundColor Green