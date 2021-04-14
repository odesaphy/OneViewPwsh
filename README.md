# OneViewPwsh
OneView Powershell stuff

Get_UplinkSets_sfps.ps1 --> Get connector info for all the uplinks in all uplinksets 

CSV output :
```
|OneView  |OneView Version|UplinkSet Name       |UplinkSet Type|Interconnect Name             |Interconnect Model                           |Interconnect FW|Uplink Port|Connector Type|Connector Vendor|Connector Part Number|Connector Revision|Connector Vendor OUI|Connector Serial Number|Inventory Date     |
|---------|---------------|---------------------|--------------|------------------------------|---------------------------------------------|---------------|-----------|--------------|----------------|---------------------|------------------|--------------------|-----------------------|-------------------|
|oneview_a|5.50.00        |ULS-NS-ADMIN         |Ethernet      |RACK01-FRAME04, interconnect 2|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q2:1       |SFP-SR        |HPE             |455883-B21           |2                 |00:01:9c            |7CR830N8NE             |14/04/2021 11:16:51|
|oneview_a|5.50.00        |ULS-NS-ADMIN         |Ethernet      |RACK01-FRAME03, interconnect 5|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q2:1       |SFP-SR        |HPE             |455883-B21           |2                 |00:01:9c            |7CR830NBEL             |14/04/2021 11:16:52|
|oneview_a|5.50.00        |ULS-TUNNEL-A         |Ethernet      |RACK01-FRAME03, interconnect 5|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q1:1       |SFP-SR        |HPE             |455883-B21           |2                 |00:01:9c            |7CR830N8N0             |14/04/2021 11:16:52|
|oneview_a|5.50.00        |ULS-TUNNEL-A         |Ethernet      |RACK01-FRAME04, interconnect 2|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q1:1       |SFP-SR        |HPE             |455883-B21           |2                 |00:01:9c            |7CR830N9K9             |14/04/2021 11:16:53|
|oneview_b|5.40.00        |ULS-SANBCK-IMPAIRE-01|FibreChannel  |RACK02-FRAME01, interconnect 2|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q6:1       |QSFP+SR       |HPE             |817040-B21           |01                |00:17:6a            |ATA117340000018 @@     |14/04/2021 11:16:56|
|oneview_b|5.40.00        |ULS-SANBCK-IMPAIRE-01|FibreChannel  |RACK02-FRAME01, interconnect 2|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q6:2       |QSFP+SR       |HPE             |817040-B21           |01                |00:17:6a            |ATA117340000018 @@     |14/04/2021 11:16:57|
|oneview_b|5.40.00        |ULS-NS-PROD-B        |Ethernet      |RACK02-FRAME01, interconnect 3|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q1:1       |QSFP+SR       |HPE             |817040-B21           |01                |00:17:6a            |ATA116160000309 @@     |14/04/2021 11:16:57|
|oneview_b|5.40.00        |ULS-NS-PROD-B        |Ethernet      |RACK02-FRAME02, interconnect 6|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q1:1       |QSFP+SR       |HPE             |817040-B21           |01                |00:17:6a            |ATA116160000203        |14/04/2021 11:16:58|
|oneview_c|5.50.00        |ULS-NS-VSAN          |Ethernet      |RACK01-FRAME02, interconnect 3|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q2:1       |SFP-SR        |HPE             |455883-B21           |2                 |00:01:9c            |7CR803NBKL             |14/04/2021 11:17:05|
|oneview_c|5.50.00        |ULS-NS-VSAN          |Ethernet      |RACK01-FRAME01, interconnect 6|Virtual Connect SE 40Gb F8 Module for Synergy|1.4.2.1005     |Q2:1       |SFP-SR        |HPE             |455883-B21           |2                 |00:01:9c            |7CR803NBCU             |14/04/2021 11:17:05|
```
