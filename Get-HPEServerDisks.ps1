function Get-HPEServerDisks
{
<#
	.SYNOPSIS
		Get physical disks on a Synergy Compute module

	.DESCRIPTION
		Retrieve disk info :
			* Id
			* Model
			* InterfaceType
			* MediaType = $myDiskDriveData.MediaType
			* SN#
			* CapacityGB
			* FW
			* Health
			* State
			* Location
			* Controller
	   
	.PARAMETER -Name 
		Specify a server name.

	.PARAMETER -Enclosure 
		Specify a Synergy enclosure name.

	.PARAMETER -BayId 
		Specify a bay number within the Synergy enclosure.

	.PARAMETER -All 
		Get disk info for all Compute Modules in the Synergy enclosure.

	.PARAMETER -ApplianceConnection
		Specify one or more HPOneView.Appliance.Connection object(s) or Name property value(s).
		Default Value: ${Global:ConnectedSessions} | ? Default

	.EXAMPLE
		Get-HPEServerDisks -Name "CZJ00007T1, bay 8"

	.EXAMPLE
		Get-HPEServerDisks -Enclosure CZJ00007T1 -BayId 8

	.EXAMPLE
		 Get-HPEServerDisks -Enclosure CZJ00007T1 -All

	.Notes
		NAME:  Get-HPEServerDisks
		LASTEDIT: 2017/05/18
		KEYWORDS: Get-HPEServerDisks

	.Link
		olivier.desaphy@hpe.com
 #>
#Requires -Version 5.0
	[CmdletBinding (DefaultParameterSetName = "Default")]
	Param 
	(
		
		[Parameter (Mandatory = $true, ParameterSetName = "Default")]
		[string]$Name,
		[Parameter (Mandatory = $true, ParameterSetName = "ByBayId")]
		[string] $Enclosure,
		[Parameter (Mandatory = $false, ParameterSetName = "ByBayId")]
		[ValidateRange(1,12)]
		[int] $BayId,
		[Parameter (Mandatory = $false, ParameterSetName = "ByBayId")]
		[switch] $All,
		[Parameter (Mandatory = $false, ParameterSetName = "Default")]
		[Parameter (Mandatory = $false, ParameterSetName = "ByBayId")]
		[ValidateNotNullorEmpty()]
		[Alias ('Appliance')]
		[Object]$ApplianceConnection = (${Global:ConnectedSessions} | ? Default)
		
	)
	
	Begin
	{
		if ($PSBoundParameters['Enclosure'] -and $PSBoundParameters['BayId']) {
			$enc = Get-HPOVEnclosure -Name $Enclosure -ErrorAction Stop
			$bay = $enc.deviceBays | ? { $_.bayNumber -eq $BayId }
			
			if ($bay.devicePresence -eq "Present") {
				$server = Get-HPOVServer | ? { $_.uri -eq $bay.deviceUri}
			} else {
				$msg = "[{0}] = No device in bay {1}" -f $enc.Name, $bayId
				Write-Error -Message $msg -ErrorAction Stop
			}
		} 
		if ($PSBoundParameters['Enclosure'] -and $PSBoundParameters['All']) {
			$enc = Get-HPOVEnclosure -Name $Enclosure -ErrorAction Stop
			$bays = $enc.deviceBays | ? { $_.devicePresence -eq "Present"} 
			$server = Get-HPOVServer | ? { $_.uri -in $bays.deviceUri }
		}
		
		if ($PSBoundParameters['Name']) {
			$server = Get-HPOVServer -Name $Name -ErrorAction Stop
		}
	}
	Process
	{
		$report = @()
		$server |% {
			$myserver = $_
			"Getting disks on server {0} ..." -f $myserver.name | Write-Verbose
			$remoteConsole ="$($myserver.Uri)/remoteConsoleUrl"
			$resp = Send-HPOVRequest $remoteConsole 
			$URL,$session          = $resp.remoteConsoleUrl.Split("&")
			$http, $iLOIP          = $URL.split("=")
			$sName,$sessionkey     = $session.split("=")

			$rootURI   = "https://$iLOIP/rest/v1"
			$iloSession = new-object PSObject -Property @{"RootUri" = $rootURI ; "X-Auth-Token" = $sessionkey}

			$arrayCtrlData = Get-HPRESTDataRaw -href '/rest/v1/Systems/1/SmartStorage/ArrayControllers' -Session $iloSession

			"Found {0} Smart Array Controller(s)" -f $arrayCtrlData.Total | Write-Verbose
			
			if ($arrayCtrlData.Total -gt 0) {
				$arrayCtrlData.links.Member.href | %{
					$_smartArrayhref = $_
					$myArrayCtrlData = Get-HPRESTDataRaw -href $_smartArrayhref -Session $iloSession
					
					"Getting drives on {0} in {1} ..." -f $myArrayCtrlData.Model, $myArrayCtrlData.Location | Write-Verbose
					
					$_diskDriveshref = "{0}/DiskDrives" -f $_smartArrayhref
					
					$diskDrivesData = Get-HPRESTDataRaw -href $_diskDriveshref -Session $iloSession

					"Found {0} drives ..." -f $diskDrivesData.links.Member.Count | Write-Verbose
					$disksOnServer = @()
					$diskDrivesData.links.Member.href | % {
						$_href= $_

						$myDiskDriveData = Get-HPRESTDataRaw -href $_href -Session $iloSession

						$disksOnServer += [PSCustomObject][Ordered]@{
							Server = $myserver.Name
							Id = $myDiskDriveData.Id
							Model = $myDiskDriveData.Model
							InterfaceType = $myDiskDriveData.InterfaceType
							MediaType = $myDiskDriveData.MediaType
							"SN#" = $myDiskDriveData.SerialNumber
							CapacityGB = $myDiskDriveData.CapacityGB
							FW = $myDiskDriveData.FirmwareVersion.Current.VersionString
							Health = $myDiskDriveData.Status.Health
							State = $myDiskDriveData.Status.State
							Location = $myDiskDriveData.Location
							Controller = "{0} in {1}" -f $myArrayCtrlData.Model, $myArrayCtrlData.Location
						}
					}
				}
			}
			$report += $disksOnServer
		}
		$report
	}
}