# OneViewPwsh
OneView Powershell stuff
get_memory.ps1 --> Get DIMM inventory on Gen10 Servers managed by OneView (Synergy & ProLiant)

CSV output :

|OneView|Server|Server Model|Server SN|DIMM Name|DIMM Location|DIMM State|DIMM Size|DIMM Frequency|DIMM PartNumber|DIMM SerialNumber|DIMM MemoryType|DIMM BaseModuleType|DIMM MemoryDeviceType|DIMM Manufacturer|DIMM VendorName|Inventory Date|
|-------|------|------------|---------|---------|-------------|----------|---------|--------------|---------------|-----------------|-----|-----|----|----|-----|----|
|oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm1|Processor 1 DIMM 1|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|45975CCF|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
|oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm3|Processor 1 DIMM 3|Enabled|16 GB|3200 Mhz|	M393A2K43DB3-CWE|458E3543|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
|oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm5|Processor 1 DIMM 5|Enabled|16 GB|3200 Mhz|	M393A2K43DB3-CWE|45971389|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
|oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm7|Processor 1 DIMM 7|Enabled|16 GB|3200 Mhz|	M393A2K43DB3-CWE|458E369C|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
|oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm10|Processor 1 DIMM 10|Enabled|16 GB|3200 Mhz|	M393A2K43DB3-CWE|459354F9|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm12|Processor 1 DIMM 12|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|4597466B|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm14|Processor 1 DIMM 14|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|45974CE1|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc1dimm16|Processor 1 DIMM 16|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|45978622|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm1|Processor 2 DIMM 1|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|458E3792|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm3|Processor 2 DIMM 3|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|458E3613|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm5|Processor 2 DIMM 5|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|459354E9|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm7|Processor 2 DIMM 7|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|45978519|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm10|Processor 2 DIMM 10|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|45978415|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm12|Processor 2 DIMM 12|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|459785E8|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm14|Processor 2 DIMM 14|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|459783A3|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
oneview.ode.net|dl385gen10p.ode.net|ProLiant DL385 Gen10 Plus|CZ21230C0B|proc2dimm16|Processor 2 DIMM 16|Enabled|16 GB|3200 Mhz|M393A2K43DB3-CWE|459783A2|DRAM|RDIMM|DDR4|Samsung|Samsung|10/15/2021 2:33:13 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc1dimm1|Processor 1 DIMM 1|Enabled|64 GB|2933 Mhz|P03053-7A1|850B39C9|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc1dimm3|Processor 1 DIMM 3|Enabled|64 GB|2933 Mhz|P03053-7A1|850B3A09|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc1dimm5|Processor 1 DIMM 5|Enabled|64 GB|2933 Mhz|P03053-7A1|850B3A34|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc1dimm8|Processor 1 DIMM 8|Enabled|64 GB|2933 Mhz|P03053-7A1|850B3A44|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc1dimm10|Processor 1 DIMM 10|Enabled|64 GB|2933 Mhz|P03053-7A1|850B39FF|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc1dimm12|Processor 1 DIMM 12|Enabled|64 GB|2933 Mhz|P03053-7A1|850B3A01|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc2dimm1|Processor 2 DIMM 1|Enabled|64 GB|2933 Mhz|P03053-7A1|850B3652|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc2dimm3|Processor 2 DIMM 3|Enabled|64 GB|2933 Mhz|P03053-7A1|850B35B8|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc2dimm5|Processor 2 DIMM 5|Enabled|64 GB|2933 Mhz|P03053-7A1|850B360B|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc2dimm8|Processor 2 DIMM 8|Enabled|64 GB|2933 Mhz|P03053-7A1|850B35F6|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc2dimm10|Processor 2 DIMM 10|Enabled|64 GB|2933 Mhz|P03053-7A1|850B3655|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|
synergy.ode.net|frame1, bay 1|Synergy 480 Gen10|CZJ11905TH|proc2dimm12|Processor 2 DIMM 12|Enabled|64 GB|2933 Mhz|P03053-7A1|850B35DC|DRAM|RDIMM|DDR4|HPE|SK Hynix|10/15/2021 2:52:17 PM|


Get_UplinkSets_sfps.ps1 --> Get connector info for all the uplinks in all uplinksets 

CSV output :

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
