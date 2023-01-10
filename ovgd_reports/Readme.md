# How to get OneView Global Dashboard Reports through REST API ?

A Quick & Dirty Powershell example
```
# OVGD Parameters
$ovgdLoginDomain = "Local"
$ovgdUsername = "Administrator"
$ovgdPassword = "Oneview1!"

$ovgdUrl = "https://192.168.6.132"
$ContentType = "application/json"

$headers = @{}
$headers["X-Api-Version"] = 2
		
# Disable SSL 
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
	
# Get OVGD Token
$body = [PSCustomObject]@{
        authLoginDomain = $ovgdLoginDomain
        userName = $ovgdUsername
        password = $ovgdPassword
} | ConvertTo-Json

$uri = "{0}/rest/login-sessions" -f $ovgdUrl
$response = Invoke-RestMethod -Method POST -body $body -Uri $uri -Headers $headers -ContentType $ContentType

$ovgdToken = $response.token

# Update Headers
$headers["Auth"] = $ovgdToken

# Get Ovgd Reports
$uri = "{0}/rest/global/reporttemplates" -f $ovgdUrl
$response = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ContentType $ContentType

# Display List of Available Reports
$response.members |Select Description, uri

<# 
description                                                                             uri
-----------                                                                             ---
Noncompliant Server profiles for a given Server Profile Template                        /rest/global/reporttemplates/d4ecaf47-1172-4c42-bf21-b58bb6d0a9f1
Converged Systems Available Storage                                                     /rest/global/reporttemplates/8553c793-165c-4241-a7a4-933e83fa1a88
Server Firmware Instances Tallied by Version                                            /rest/global/reporttemplates/c8352923-47ed-40c5-9893-a0e12fa61ffa
Service Pack for ProLiant (SPP) Bundles available and missing per Appliance             /rest/global/reporttemplates/cf9787ff-d433-4c5f-ae87-478985ada010
HPE OneView and HPE Synergy Licenses                                                    /rest/global/reporttemplates/2cf03ded-db6f-4439-a26e-fcab475802bf
Server Firmware Components and Details                                                  /rest/global/reporttemplates/208b03c4-8f4a-43c9-8dd1-d4e32d24b893
Converged Systems Storage Usage                                                         /rest/global/reporttemplates/4e1c89ca-5df1-45db-b69e-de84329520c4
Information on available bays in enclosures                                             /rest/global/reporttemplates/e644bdc1-4408-4544-ad35-5dfe28d6dae4
Server Profiles, their associated Server Profile Template, Appliance and Compliance     /rest/global/reporttemplates/e81d3fa9-0ed0-4baa-816d-bfce032cddab
Noncompliant Server Profiles and their associated Server Profile Template and Appliance /rest/global/reporttemplates/064970cd-e90f-4f0b-b217-00bae39b1506
Compliant Server profiles for a given Server Profile Template                           /rest/global/reporttemplates/4129bcac-7232-4e34-8359-21d6f0f41aee
Compliant Server Profiles and their associated Server Profile Template and Appliance    /rest/global/reporttemplates/a1380947-1f81-48c7-beff-80e57d7c71c7
Server Profiles without SPT association                                                 /rest/global/reporttemplates/026507e4-9245-4670-843c-8c92ccb6b1d1
All Server Profiles without SPT association and their containing appliance              /rest/global/reporttemplates/b86c158f-5f66-482e-9460-3b8c6f4dfd23
Noncompliant Server Profiles and their associated Server Profile Templates              /rest/global/reporttemplates/b1705451-5d76-48b4-8ae4-681743ee5e01
Global available Server Profile Templates (SPT) and Server Profile compliance           /rest/global/reporttemplates/85f3d307-aec8-44cc-a5e8-388a68546a41
Profile and Server compliance against Service Pack for ProLiant (SPP) baselines         /rest/global/reporttemplates/3ec0df0d-2ea5-4162-b6e6-92d9da220b16
Server Firmware Instance Details                                                        /rest/global/reporttemplates/0634d0c9-0eca-4106-b13d-8e07a605297a
All available Server Profile Templates with associated Server Profile compliance        /rest/global/reporttemplates/99917e0f-1584-4214-8566-06fea819588f
Storage Pool Status and Utilization                                                     /rest/global/reporttemplates/32b077a0-e571-4ffe-bd13-14b641850f27
Service Alerts triggered by Remote Support                                              /rest/global/reporttemplates/0d808385-5506-4a05-a704-67b37cf8199b
Remote Support Warranties and Contracts Status                                          /rest/global/reporttemplates/94a61c83-029c-433e-a005-e21e3a9c758e
Server Solid State Drive Wear and Life Remaining                                        /rest/global/reporttemplates/f066509a-36fb-445e-9dc8-101d8813b763
Models, ROM and iLO versions, Server details                                            /rest/global/reporttemplates/cb947a3e-85de-4b7a-a047-106ebf3f231d
Enclosure health and details                                                            /rest/global/reporttemplates/dcf613ba-4fe2-4dea-9017-67f85234d049
Available Server Profile Templates (SPTs) and Server Profile (SP) compliance            /rest/global/reporttemplates/c60ab77a-69e5-4f57-b6dc-d7c14bc22dfe
Compliant Server profiles and their associated Server Profile Templates                 /rest/global/reporttemplates/29925915-efff-4dfc-ac7d-e49f3bf15213
Critical resource alerts summary and details                                            /rest/global/reporttemplates/17800e78-7053-48cc-82d7-98dec4926e5a
All available Server Profile Templates with associated Server Profile compliance        /rest/global/reporttemplates/f196b319-e259-42b1-9031-bcba59ba92e4
Interconnect health and details                                                         /rest/global/reporttemplates/7849efe5-b986-429a-9a28-aa6bc9a95f65 
#>

# Get Report Uri for "Models, ROM and iLO versions, Server details"
$reportDescription = "Models, ROM and iLO versions, Server details"
$reportUri = ($response.members | Where-Object { $_.description -eq $reportDescription }).Uri 

# Invoke Report
$uri = "{0}/rest/global/reportresults" -f $ovgdUrl
$body = [PSCustomObject]@{
        templateid = $reportUri
} | ConvertTo-Json

$response = Invoke-RestMethod -Method POST -body $body -Uri $uri -Headers $headers -ContentType $ContentType

# Get Report Results
$uri = "{0}{1}" -f $ovgdUrl, $response.uri
$response = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ContentType $ContentType

$response.reportresult.results[-1].data |%{$_.value -join '#'} | ConvertFrom-Csv -Delimiter '#' | ft -AutoSize

<# 
Status Server          Name Model             Processor                            Proc. Count Memory Serial Number iLO                                                                         iLO FW
------ ------          ---- -----             ---------                            ----------- ------ ------------- ---                                                                         ------
1      Frame06, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201180GR    1. fe80:0:0:0:2:0:3:911e, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.31 1.40 Jun 18 2019
1      Frame02, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201036GR    1. fe80:0:0:0:2:0:3:9106, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.7  1.40 Jun 18 2019
1      Frame04, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201108GR    1. fe80:0:0:0:2:0:3:9112, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.19 1.40 Jun 18 2019
1      Frame05, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201144GR    1. fe80:0:0:0:2:0:3:9118, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.25 1.40 Jun 18 2019
1      Frame10, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201324GR    1. fe80:0:0:0:2:0:3:9136, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.55 1.40 Jun 18 2019
1      Frame13, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201432GR    1. fe80:0:0:0:2:0:3:9148, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.73 1.40 Jun 18 2019
1      Frame11, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201360GR    1. fe80:0:0:0:2:0:3:913c, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.61 1.40 Jun 18 2019
1      Frame08, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201252GR    1. fe80:0:0:0:2:0:3:912a, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.43 1.40 Jun 18 2019
1      Frame12, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201396GR    1. fe80:0:0:0:2:0:3:9142, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.67 1.40 Jun 18 2019
1      Frame07, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201216GR    1. fe80:0:0:0:2:0:3:9124, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.37 1.40 Jun 18 2019
1      Frame15, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201504GR    1. fe80:0:0:0:2:0:3:9154, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.85 1.40 Jun 18 2019
1      Frame09, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201288GR    1. fe80:0:0:0:2:0:3:9130, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.49 1.40 Jun 18 2019
1      Frame14, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201468GR    1. fe80:0:0:0:2:0:3:914e, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.79 1.40 Jun 18 2019
1      Frame03, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201072GR    1. fe80:0:0:0:2:0:3:910c, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.13 1.40 Jun 18 2019
1      Frame01, bay 3       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201000GR    1. fe80:0:0:0:2:0:3:9100, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.1  1.40 Jun 18 2019
1      Frame06, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201186GR    1. fe80:0:0:0:2:0:3:911f, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.32 1.40 Jun 18 2019
1      Frame02, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201042GR    1. fe80:0:0:0:2:0:3:9107, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.8  1.40 Jun 18 2019
1      Frame04, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201114GR    1. fe80:0:0:0:2:0:3:9113, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.20 1.40 Jun 18 2019
1      Frame11, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201366GR    1. fe80:0:0:0:2:0:3:913d, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.62 1.40 Jun 18 2019
1      Frame05, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201150GR    1. fe80:0:0:0:2:0:3:9119, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.26 1.40 Jun 18 2019
1      Frame10, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201330GR    1. fe80:0:0:0:2:0:3:9137, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.56 1.40 Jun 18 2019
1      Frame13, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201438GR    1. fe80:0:0:0:2:0:3:9149, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.74 1.40 Jun 18 2019
1      Frame08, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201258GR    1. fe80:0:0:0:2:0:3:912b, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.44 1.40 Jun 18 2019
1      Frame12, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201402GR    1. fe80:0:0:0:2:0:3:9143, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.68 1.40 Jun 18 2019
1      Frame07, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201222GR    1. fe80:0:0:0:2:0:3:9125, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.38 1.40 Jun 18 2019
1      Frame15, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201510GR    1. fe80:0:0:0:2:0:3:9155, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.86 1.40 Jun 18 2019
1      Frame09, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201294GR    1. fe80:0:0:0:2:0:3:9131, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.50 1.40 Jun 18 2019
1      Frame14, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201474GR    1. fe80:0:0:0:2:0:3:914f, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.80 1.40 Jun 18 2019
1      Frame03, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201078GR    1. fe80:0:0:0:2:0:3:910d, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.14 1.40 Jun 18 2019
1      Frame01, bay 4       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201006GR    1. fe80:0:0:0:2:0:3:9101, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.2  1.40 Jun 18 2019
1      Frame03, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201084GR    1. fe80:0:0:0:2:0:3:910e, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.15 1.40 Jun 18 2019
1      Frame06, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201192GR    1. fe80:0:0:0:2:0:3:9120, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.33 1.40 Jun 18 2019
1      Frame02, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201048GR    1. fe80:0:0:0:2:0:3:9108, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.9  1.40 Jun 18 2019
1      Frame04, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201120GR    1. fe80:0:0:0:2:0:3:9114, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.21 1.40 Jun 18 2019
1      Frame11, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201372GR    1. fe80:0:0:0:2:0:3:913e, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.63 1.40 Jun 18 2019
1      Frame05, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201156GR    1. fe80:0:0:0:2:0:3:911a, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.27 1.40 Jun 18 2019
1      Frame10, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201336GR    1. fe80:0:0:0:2:0:3:9138, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.57 1.40 Jun 18 2019
1      Frame07, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201228GR    1. fe80:0:0:0:2:0:3:9126, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.39 1.40 Jun 18 2019
1      Frame13, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201444GR    1. fe80:0:0:0:2:0:3:914a, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.75 1.40 Jun 18 2019
1      Frame08, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201264GR    1. fe80:0:0:0:2:0:3:912c, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.45 1.40 Jun 18 2019
1      Frame12, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201408GR    1. fe80:0:0:0:2:0:3:9144, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.69 1.40 Jun 18 2019
1      Frame15, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201516GR    1. fe80:0:0:0:2:0:3:9156, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.87 1.40 Jun 18 2019
1      Frame09, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201300GR    1. fe80:0:0:0:2:0:3:9132, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.51 1.40 Jun 18 2019
1      Frame14, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201480GR    1. fe80:0:0:0:2:0:3:9150, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.81 1.40 Jun 18 2019
1      Frame01, bay 5       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201012GR    1. fe80:0:0:0:2:0:3:9102, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.3  1.40 Jun 18 2019
1      Frame03, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201090GR    1. fe80:0:0:0:2:0:3:910f, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.16 1.40 Jun 18 2019
1      Frame06, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201198GR    1. fe80:0:0:0:2:0:3:9121, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.34 1.40 Jun 18 2019
1      Frame02, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201054GR    1. fe80:0:0:0:2:0:3:9109, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.10 1.40 Jun 18 2019
1      Frame04, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201126GR    1. fe80:0:0:0:2:0:3:9115, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.22 1.40 Jun 18 2019
1      Frame11, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201378GR    1. fe80:0:0:0:2:0:3:913f, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.64 1.40 Jun 18 2019
1      Frame05, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201162GR    1. fe80:0:0:0:2:0:3:911b, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.28 1.40 Jun 18 2019
1      Frame07, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201234GR    1. fe80:0:0:0:2:0:3:9127, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.40 1.40 Jun 18 2019
1      Frame13, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201450GR    1. fe80:0:0:0:2:0:3:914b, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.76 1.40 Jun 18 2019
1      Frame08, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201270GR    1. fe80:0:0:0:2:0:3:912d, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.46 1.40 Jun 18 2019
1      Frame12, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201414GR    1. fe80:0:0:0:2:0:3:9145, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.70 1.40 Jun 18 2019
1      Frame10, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201342GR    1. fe80:0:0:0:2:0:3:9139, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.58 1.40 Jun 18 2019
1      Frame15, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201522GR    1. fe80:0:0:0:2:0:3:9157, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.88 1.40 Jun 18 2019
1      Frame09, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201306GR    1. fe80:0:0:0:2:0:3:9133, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.52 1.40 Jun 18 2019
1      Frame14, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201486GR    1. fe80:0:0:0:2:0:3:9151, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.82 1.40 Jun 18 2019
1      Frame01, bay 6       Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201018GR    1. fe80:0:0:0:2:0:3:9103, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.4  1.40 Jun 18 2019
1      Frame03, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201096GR    1. fe80:0:0:0:2:0:3:9110, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.17 1.40 Jun 18 2019
1      Frame06, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201204GR    1. fe80:0:0:0:2:0:3:9122, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.35 1.40 Jun 18 2019
1      Frame02, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201060GR    1. fe80:0:0:0:2:0:3:910a, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.11 1.40 Jun 18 2019
1      Frame04, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201132GR    1. fe80:0:0:0:2:0:3:9116, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.23 1.40 Jun 18 2019
1      Frame05, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201168GR    1. fe80:0:0:0:2:0:3:911c, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.29 1.40 Jun 18 2019
1      Frame07, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201240GR    1. fe80:0:0:0:2:0:3:9128, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.41 1.40 Jun 18 2019
1      Frame13, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201456GR    1. fe80:0:0:0:2:0:3:914c, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.77 1.40 Jun 18 2019
1      Frame11, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201384GR    1. fe80:0:0:0:2:0:3:9140, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.65 1.40 Jun 18 2019
1      Frame08, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201276GR    1. fe80:0:0:0:2:0:3:912e, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.47 1.40 Jun 18 2019
1      Frame12, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201420GR    1. fe80:0:0:0:2:0:3:9146, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.71 1.40 Jun 18 2019
1      Frame10, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201348GR    1. fe80:0:0:0:2:0:3:913a, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.59 1.40 Jun 18 2019
1      Frame15, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201528GR    1. fe80:0:0:0:2:0:3:9158, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.89 1.40 Jun 18 2019
1      Frame09, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201312GR    1. fe80:0:0:0:2:0:3:9134, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.53 1.40 Jun 18 2019
1      Frame14, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201492GR    1. fe80:0:0:0:2:0:3:9152, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.83 1.40 Jun 18 2019
1      Frame01, bay 11      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201024GR    1. fe80:0:0:0:2:0:3:9104, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.5  1.40 Jun 18 2019
1      Frame03, bay 12      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201102GR    1. fe80:0:0:0:2:0:3:9111, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.18 1.40 Jun 18 2019
1      Frame06, bay 12      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201210GR    1. fe80:0:0:0:2:0:3:9123, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.36 1.40 Jun 18 2019
1      Frame02, bay 12      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201066GR    1. fe80:0:0:0:2:0:3:910b, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.12 1.40 Jun 18 2019
1      Frame04, bay 12      Synergy 480 Gen10 Intel(R) Xeon(R) CPU E5620 @ 2.40GHz 2           32768  2J201138GR    1. fe80:0:0:0:2:0:3:9117, 2. dc5:0:0:0:c78e:80a8:f210:79b7, 3. 172.18.31.24 1.40 Jun 18 2019
#>
```