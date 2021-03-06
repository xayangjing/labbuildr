﻿<#
.Synopsis
   labbuildr allows you to create Virtual Machines with VMware Workstation from Predefined Scenarios.
   Scenarios include Exchange 2013, SQL, Hyper-V, SCVMM, SCaleIO, OneFS
.DESCRIPTION
   labbuildr is a Self Installing Lab tool for Building VMware Virtual Machines on VMware Workstation
      Copyright 2016 Karsten Bott
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
       http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
.LINK
   https://github.com/bottkars/labbuildr/wiki
.EXAMPLE
    build-lab.ps1 -createshortcut
    Creates a Desktop Shortcut for labbuildr
.EXAMPLE
    PS F:\labbuildr .\build-lab.ps1 -HyperV -ScaleIO -clusteredmdm -Disks 3 -defaults -SCVMM -ConfigureVMM -Sourcedir G:\Sources
    installs a Hyper-V Cluster with 3 Nodes, ScaleIO MDM, SDS,SDC deployed, SCVMM will be deployed on node 3
.EXAMPLE
    .\build-lab.ps1 -defaults -DConly -NW
    Builds a DC along with Networker Server
.EXAMPLE
    .\build-lab.ps1 -defaults -HV -ScaleIO -singlemdm -NMM
     Builds a HyperV Cluster with Scaleio in Single MDM Mode and NMM Modules
.EXAMPLE
    .\build-lab.ps1 -defaults -DAG -EXNodes 1 -NMM
    Builds a single-node Exchange DAG
.EXAMPLE
    .\build-lab.ps1 -defaults -Sharepoint
    Build  a Sharepoint Foundation with integrated SQL Server
#>
[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <#
    run build-lab version    #>
	[Parameter(ParameterSetName = "version",Mandatory = $false, HelpMessage = "this will display the current version")][switch]$version,
    <#
    run build-lab update    #>
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "this will update labbuildr from latest git commit")][switch]$Update,
    <#
    run build-lab update    #>
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "select a branch to update from")][ValidateSet('master','testing','develop')]$branch,
    <#
    create deskop shortcut
    #>
    [Parameter(ParameterSetName = "shortcut", Mandatory = $false)][switch]$createshortcut,
    <#
    Installs only a Domain Controller. Domaincontroller normally is installed automatically durin a Scenario Setup
    IP-Addresses: .10
    #>
	[Parameter(ParameterSetName = "DConly")][switch][alias('dc')]$DConly,
	<#
    Installs only a Docker host on 2016TP5.
    IP-Addresses: .19
    #>
	[Parameter(ParameterSetName = "docker")][switch][alias('docker')]$Dockerhost,
	[Parameter(ParameterSetName = "docker")][ValidateSet(
    '1.12.0','latest'
    )]
    $Docker_VER='latest',
	<#
    Selects the Always On Scenario
    IP-Addresses: .160 - .169
    #>
	[Parameter(ParameterSetName = "AAG",Mandatory = $true)][switch][alias('ao')]$AlwaysOn,
    <#
    Selects the Hyper-V Scenario
    IP-Addresses: .150 - .159
    #>
	[Parameter(ParameterSetName = "Hyperv")][switch][alias('hv')]$HyperV,
    <#
    E14 Scenario: Installs a Standalone or DAG Exchange 2010 Installation.
    IP-Addresses: .110 - .119
    #>
	[Parameter(ParameterSetName = "E14",Mandatory = $true)][switch][alias('ex14')]$Exchange2010,
    <#
    E15 Scenario: Installs a Standalone or DAG Exchange 2013 Installation.
    IP-Addresses: .110 - .119
    #>
	[Parameter(ParameterSetName = "E15",Mandatory = $true)][switch][alias('ex15')]$Exchange2013,
    <#
    Exchange16 Scenario: Installs a Standalone or DAG Exchange 2016 Installation.
    IP-Addresses: .120 - .129
    #>
	[Parameter(ParameterSetName = "E16",Mandatory = $true)][switch][alias('ex16')]$Exchange2016,
    <#
    Selects the Sharepoint
    IP-Addresses: .140
    #>
	[Parameter(ParameterSetName = "Sharepoint")][switch]$Sharepoint,
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $true)][ValidateSet('BuiltIn','AlwaysOn')]$SPdbtype = "BuiltIn",
    <#
    Selects the SQL Scenario
    IP-Addresses: .130
    #>
	[Parameter(ParameterSetName = "SQL")][switch]$SQL,
    <#
Specify if Networker Scenario sould be installed
    IP-Addresses: .103
    #>
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[switch][alias('nsr')]$NWServer,
    <#
    Installs Isilon Nodes
    IP-Addresses: .40 - .56
    #>
	[Parameter(ParameterSetName = "Isilon")]
    [switch][alias('isi')]$Isilon,
    <#
    Selects the Storage Spaces Scenario, still work in progress
    IP-Addresses: .170 - .179
    #>
	[Parameter(ParameterSetName = "Spaces")][switch]$Spaces,
    <#
    Selects the Syncplicity Panorama Server
    IP-Addresses: .18
    #>
    [Parameter(ParameterSetName = "Panorama")][switch][alias('pn')]$Panorama,
    <#
    Selects the EMC ViPR SRM Binary Install
    IP-Addresses: .17
    #>
	[Parameter(ParameterSetName = "SRM", Mandatory = $true)][switch][alias('srm')]$ViPRSRM,
    [Parameter(ParameterSetName = "SRM")]
    [ValidateSet(
    '4.0.0.0',
    '3.7.1.0','3.7.0.0',
    '3.6.0.3'
    )]
    $SRM_VER='4.0.0.0',
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $true)][switch][alias('asc')]$AppSync,
    [Parameter(ParameterSetName = "APPSYNC")]
    [ValidateSet(
    '3.0.0','3.0.1'#
    )]
    $APPSYNC_VER='3.0.1',
    <#
    Selects the Microsoft System Center Binary Install
    IP-Addresses: .18
    #>
	[Parameter(ParameterSetName = "SCOM", Mandatory = $true)][switch][alias('SC_OM')]$SCOM,
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [ValidateSet(
    'SC2012_R2',
    'SCTP3','SCTP4','SCTP5')]
    $SC_Version = "SC2012_R2",
    <#
    Selects the Blank Nodes Scenario
    IP-Addresses: .180 - .189
    #>
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('bn')]$Blanknode,
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('bnhv')]$BlankHV,
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('S2D')]$SpacesDirect,
	[Parameter(ParameterSetName = "Blanknodes")][string][alias('CLN')]$ClusterName,
    <#
    Selects the SOFS Scenario
    IP-Addresses: .210 - .219
    #>
    [Parameter(ParameterSetName = "SOFS")][switch]$SOFS,
    #### scenario options #####
    <#
    Determines if Exchange should be installed in a DAG
    #>
    [Parameter(ParameterSetName = "E14", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$DAG,
    <# Specify the Number of Exchange Nodes#>
    [Parameter(ParameterSetName = "E14", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [Parameter(ParameterSetName = "E15", Mandatory = $false)][ValidateRange(1, 10)][int][alias('exn')]$EXNodes,
    <# Specify the Starting exchange Node#>
    [Parameter(ParameterSetName = "E14", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][ValidateRange(1, 9)][int][alias('exs')]$EXStartNode = 1,
    <#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
	'cu2','cu1','final'
    Default is latest
    CU Location is [Driveletter]:\sources\e2016[cuver], e.g. c:\sources\e2016Preview1
    #>
	[Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [ValidateSet(
	'cu2','cu1','final'
	)]
    $e16_cu,
<#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'cu1','cu2','cu3','cu4','sp1','cu6','cu7'
    Default is latest
    CU Location is [Driveletter]:\sources\e2013[cuver], e.g. c:\sources\e2013cu7
    #>
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [ValidateSet('cu1','cu2','cu3','sp1','cu5','cu6','cu7','cu8','cu9','cu10','cu11','cu12','cu13')]
    [alias('ex_cu')]$e15_cu,
<#
    Determines Exchange UR Version to be Installed
    Valid Versions are:
    'ur13'
    Default is latest
    CU Location is [Driveletter]:\sources\e2013[cuver], e.g. c:\sources\e2013cu7
    #>
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
    [ValidateSet('ur1','ur2','ur3','ur4','ur5','ur6','ur7','ur8v2','ur9','ur10','ur11','ur12','ur13')]
    [alias('e2010_ur')]$e14_ur,
<#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'sp3'
    Default is latest
    CU Location is [Driveletter]:\sources\e2013[cuver], e.g. c:\sources\e2013cu7
    #>
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
    [ValidateSet('sp3')]
    [alias('e2010_sp')]$e14_sp,
    [Parameter(ParameterSetName = "E14", Mandatory = $false)]
    [ValidateSet('de_DE','en_US')]
    [alias('e2010_lang')]$e14_lang = 'de_DE',
    <# schould we prestage users ? #>
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$nouser,
    <# Install a DAG without Management IP Address ? #>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$DAGNOIP,
    <# Specify Number of Spaces Hosts #>
    [Parameter(ParameterSetName = "Spaces", Mandatory = $false)][ValidateRange(1, 2)][int]$SpaceNodes = "1",
    <# Specify Number of Hyper-V Hosts #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateRange(1, 9)][int][alias('hvnodes')]$HyperVNodes = "1",
	<# ScaleIO on hyper-v #>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch][alias('sc')]$ScaleIO,
	<# ScaleIOVersion
	'2.0-7120.0','2.0-6035.0','2.0-5014.0',
	'1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4','1.32-3455.5','1.32-4503.5',
	'1.31-258.2','1.31-1277.3','1.31-2333.2',
	'1.30-426.0'
	#>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][string]
    [ValidateSet(
	'2.0-7120.0','2.0-6035.0','2.0-5014.0',
	'1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4','1.32-3455.5','1.32-4503.5',
	'1.31-258.2','1.31-1277.3','1.31-2333.2',
	'1.30-426.0'
	)]
    [alias('siover')]$ScaleIOVer,
    <# single mode with mdm only on first node ( no secondary, no tb ) #>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$singlemdm,
    # <# Cluster modemdm automatically#>
    # [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$clusteredmdm,
    <# CLuster Number ? #>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateSet(1,2)][int][alias('clunum')]$Clusternum = "1",
	<# ScaleIO on hyper-v #>
    <# SCVMM on last Node ? #>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$SCVMM,
    <# Configure VMM ?#>
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][switch]$ConfigureVMM,
    <# Starting Node for Blank Nodes#>
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 9)][alias('bs')][int]$Blankstart = "1",
    <# How many Blank Nodes#>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 10)][alias('bns')][int]$BlankNodes = "1",
    <# Wich Number of isilon Nodes #>
    [Parameter(ParameterSetName = "Isilon")]
	[ValidateRange(2, 16)][alias('isn')]$isi_nodes = 2,
    <# Wich ISIMASTER to Pick #>
   	[Parameter(ParameterSetName = "Isilon")]
	[ValidateSet('ISIMASTER')]$ISIMaster,
    <# How many SOFS Nodes#>
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)][ValidateRange(1, 10)][alias('sfn')]$SOFSNODES = "1",
    <# Starting Node for SOFS#>
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)][ValidateRange(1, 9)][alias('sfs')]$SOFSSTART = "1",
    <# Specify the Number of Always On Nodes#>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)][ValidateRange(1, 5)][int][alias('aan')]$AAGNodes = "2",
    <#
    'SQL2012SP1',SQL2012SP2,SQL2012SP1SLIP, 'SQL2014'
    SQL version to be installed
    Needs to have:
    [sources]\SQL2012SP1 or
    [sources]\SQL2014
    #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [ValidateSet(#'SQL2014SP1slip','SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014','SQL2016',
	'SQL2012_ISO',
	'SQL2014SP2_ISO',
	'SQL2016_ISO')]$SQLVER,    
	######################### common Parameters start here in Order
    <# reads the Default Config from defaults.xml
    <config>
    <nmm_ver>nmm82</nmm_ver>
    <nw_ver>nw82</nw_ver>
    <master>2012R2UEFIMASTER</master>
    <sqlver>SQL2014</sqlver>
    <e15_cu>cu6</e15_cu>
    <vmnet>2</vmnet>
    <BuildDomain>labbuildr</BuildDomain>
    <MySubnet>10.10.0.0</MySubnet>
    <AddressFamily>IPv4</AddressFamily>
    <IPV6Prefix>FD00::</IPV6Prefix>
    <IPv6PrefixLength>8</IPv6PrefixLength>
    <NoAutomount>False</NoAutomount>
    </config>
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
   	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[switch]$defaults,
    <#do we want Tools Update? #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
 	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
   [Switch]$Toolsupdate,
    <# Wich version of OS Master should be installed
    '2012R2FallUpdate','2012R2U1MASTER','2012R2MASTER','2012R2UMASTER','2012MASTER','2012R2UEFIMASTER','vNextevalMaster','RELEASE_SERVER'
    #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
   	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[ValidateSet(
    '2016TP5','2016TP5_GER',
    '2012R2_Ger','2012_R2',
    '2012R2FallUpdate','2012R2Fall_Ger',
    '2012_Ger','2012'
    )]$Master,
    <#do we want a special path to the Masters ? #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	$Masterpath,
    <# Do we want Additional Disks / of additional 100GB Disks for ScaleIO. The disk will be made ready for ScaleIO usage in Guest OS#>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateRange(1, 6)][int][alias('ScaleioDisks')]$Disks,
      <#
    Enable the default gateway
    .103 will be set as default gateway, NWserver will have 2 Nics, NIC2 Pointing to NAT serving as Gateway
    #>
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [switch][alias('gw')]$Gateway,
<# select vmnet, number from 1 to 19#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
    [ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet,
 #   [Parameter(Mandatory = $false, HelpMessage = "Enter a valid VMware network Number vmnet between 1 and 19 ")]
<# This stores the defaul config in defaults.xml#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[switch]$savedefaults,
<# Specify if Machines should be Clustered, valid for Hyper-V and Blanknodes Scenario  #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[switch]$Cluster,
<#
Machine Sizes
'XS'  = 1vCPU, 512MB
'S'   = 1vCPU, 768MB
'M'   = 1vCPU, 1024MB
'L'   = 2vCPU, 2048MB
'XL'  = 2vCPU, 4096MB
'TXL' = 2vCPU, 6144MB
'XXL' = 4vCPU, 8192MB
'XXXL' = 4vCPU, 8192MB
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "Spaces", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[ValidateSet('XS', 'S', 'M', 'L', 'XL', 'TXL', 'XXL', 'XXXL')]$Size = "M",
<# Specify your own Domain name#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[ValidateLength(1,63)][ValidatePattern("^[a-zA-Z0-9][a-zA-Z0-9-]{1,63}[a-zA-Z0-9]+$")][string]$BuildDomain,
<# Turn this one on if you would like to install a Hypervisor inside a VM #>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[switch]$VTbit,
####networker
    <# install Networker Modules for Microsoft #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$NMM,
    <#
Version Of Networker Modules
    'nmm90.DA','nmm9001','nmm9002','nmm9003','nmm9004','nmm9005','nmm9006','nmm9007','nmm9008',
    'nmm8231','nmm8232',
    'nmm8221','nmm8222','nmm8223','nmm8224','nmm8225',
    'nmm8218','nmm8217','nmm8216','nmm8214','nmm8212','nmm821'
    will be downloaded by labbuildr if not found in sources
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [ValidateSet(
    'nmm9010','nmm9011','nmm9100',#
    'nmm90.DA','nmm9001','nmm9002','nmm9003','nmm9004','nmm9005','nmm9006','nmm9007','nmm9008',
    'nmm8231','nmm8232',
    'nmm8221','nmm8222','nmm8223','nmm8224','nmm8225',
    'nmm8218','nmm8217','nmm8216','nmm8214','nmm8212','nmm821'
    )]
    $nmm_ver,
<# Indicates to install Networker Server with Scenario #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[switch]$NW,
    <#
Version Of Networker Server / Client to be installed
    'nw9010','nw9011','nw9100',#
    'nw90.DA','nw9001','nw9002','nw9003','nw9004','nw9005','nw9006','nw9007','nw9008',
    'nw8232','nw8231',
    'nw8226','nw8225','nw8224','nw8223','nw8222','nw8221','nw822',
    'nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821',
    'nw8206','nw8205','nw8204','nw8203','nw8202','nw82',
    'nw8138','nw8137','nw8136','nw8135','nw8134','nw8133','nw8132','nw8131','nw813',
    'nw8127','nw8126','nw8125','nw8124','nw8123','nw8122','nw8121','nw812',
    'nw8119','nw8118','nw8117','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',
    'nw8105','nw8104','nw8103','nw8102','nw81',
    'nw8044','nw8043','nw8042','nw8041',
    'nw8037','nw8036','nw8035','nw81034','nw8033','nw8032','nw8031',
    'nw8026','nw8025','nw81024','nw8023','nw8022','nw8021',
    'nw8016','nw8015','nw81014','nw8013','nw8012',
    'nw8007','nw8006','nw8005','nw81004','nw8003','nw8002','nw80',
    'nwunknown'
    will be downloaded by labbuildr / labtools
    otherwise must be extracted to [sourcesdir]\networker\[nw_ver], ex. c:\sources\networker\nw82
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
    [ValidateSet(
    'nw9010','nw9011','nw9100',#
    'nw90.DA','nw9001','nw9002','nw9003','nw9004','nw9005','nw9006','nw9007','nw9008',
    'nw8232','nw8231',
    'nw8226','nw8225','nw8224','nw8223','nw8222','nw8221','nw822',
    'nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821',
    'nw8206','nw8205','nw8204','nw8203','nw8202','nw82',
    'nw8138','nw8137','nw8136','nw8135','nw8134','nw8133','nw8132','nw8131','nw813',
    'nw8127','nw8126','nw8125','nw8124','nw8123','nw8122','nw8121','nw812',
    'nw8119','nw8118','nw8117','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',
    'nw8105','nw8104','nw8103','nw8102','nw81',
    'nw8044','nw8043','nw8042','nw8041',
    'nw8037','nw8036','nw8035','nw81034','nw8033','nw8032','nw8031',
    'nw8026','nw8025','nw81024','nw8023','nw8022','nw8021',
    'nw8016','nw8015','nw81014','nw8013','nw8012',
    'nw8007','nw8006','nw8005','nw81004','nw8003','nw8002','nw80',
    'nwunknown'
    )]
    $nw_ver,
### network Parameters ######
<# Disable Domainchecks for running DC
This should be used in Distributed scenario´s
 #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
    [switch]$NoDomainCheck,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[Validatepattern(‘(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))’)]$MySubnet,
<# Specify your IP Addressfamilie/s
Valid values 'IPv4','IPv6','IPv4IPv6'
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
<# Specify your IPv6 ULA Prefix, consider https://www.sixxs.net/tools/grh/ula/  #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
    [ValidateScript({$_ -match [IPAddress]$_ })]$IPV6Prefix,
<# Specify your IPv6 ULA Prefix Length, #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    $IPv6PrefixLength,
<#
Specify the Path to your Sources
Example[Driveletter]:\Sources, eg. USB Device, local drive c
Sources should be populated from a bases sources.zip
#>
	#[Parameter(ParameterSetName = "default", Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
    [String]$Sourcedir,
	#[Validatescript({Test-Path -Path $_ })][String]$Sourcedir,
    <#
     run build-lab -update -force to force an update
    #>
    [Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "this will force update labbuildr")]
    [switch]$force,
    <# Turn on Logging to Console#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E14", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "APPSYNC", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "docker", Mandatory = $false)]
	[switch]$ConsoleLog
) # end Param
#requires -version 3.0
#requires -module vmxtoolkit
#requires -module labtools
###################################################
### VMware Master Script
###################################################
[string]$Myself_ps1 = $MyInvocation.MyCommand
$myself = $Myself_ps1.TrimEnd(".ps1")
#$AddressFamily = 'IPv4'
$IPv4PrefixLength = '24'
$Builddir = $PSScriptRoot
if (Test-Path $env:SystemRoot\system32\ntdll.dll)
	{
	$runonos = "win_x86_64"
	}

If ($ConfirmPreference -match "none")
    {$Confirm = $false}
<#else
    {$Confirm = $true}#>
try
    {
    $Current_labbuildr_branch = Get-Content  ($Builddir + "\labbuildr.branch") -ErrorAction Stop
    }
catch
    {
    Write-Host -ForegroundColor Gray " ==>no prevoius branch"
    If (!$PSCmdlet.MyInvocation.BoundParameters['branch'].IsPresent)
        {
        $Current_labbuildr_branch = "master"
        }
    else
        {
        $Current_labbuildr_branch = $branch
        }
    }
If (!$PSCmdlet.MyInvocation.BoundParameters["branch"].IsPresent)
     {
     $PSCmdlet.MyInvocation.BoundParameters["branch"].IsPresent
     # $branch = $Current_labbuildr_branch
     }
Write-Verbose "Branch = $branch"
Write-Verbose "Current Branch = $Current_labbuildr_branch"
if ([String]::IsNullOrEmpty($PSCmdlet.MyInvocation.BoundParameters['branch']))
    {
    $branch = $Current_labbuildr_branch
    }
Write-Verbose "Branch = $branch"
Write-Verbose "Current Branch = $Current_labbuildr_branch"
try
    {
    [datetime]$Latest_labbuildr_git = Get-Content  ($Builddir + "\labbuildr-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_git = "07/11/2015"
    }
try
    {
    [datetime]$Latest_labbuildr_scripts_git = Get-Content  ($Builddir + "\labbuildr-scripts-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_scripts_git = "07/11/2015"
    }
try
    {
    [datetime]$Latest_labtools_git = Get-Content  ($Builddir + "\labtools-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labtools_git = "07/11/2015"
    }
try
    {
    [datetime]$Latest_vmxtoolkit_git = Get-Content  ($Builddir + "\vmxtoolkit-$branch.gitver") -ErrorAction Stop
    }
catch
    {
    [datetime]$Latest_vmxtoolkit_git = "07/11/2015"
    }

################## Statics
$WAIKVER = "WAIK"
$custom_domainsuffix = "local"
$AAGDB = "AWORKS"
$major = "2016"
$Edition = "3rd Anniversary SP1"
$Default_attachement = "https://www.emc.com/collateral/solution-overview/h12476-so-hybrid-cloud.pdf"
$Default_vmnet = "vmnet2"
$Default_BuildDomain = "labbuildr"
$Default_Subnet = "192.168.2.0"
$Default_IPv6Prefix = "FD00::"
$Default_IPv6PrefixLength = '8'
$Default_AddressFamily = "IPv4"
$latest_ScaleIOVer = '2.0-7120.0'
$ScaleIO_OS = "Windows"
$ScaleIO_Path = "ScaleIO_$($ScaleIO_OS)_SW_Download"
$latest_nmm = 'nmm9011'
$latest_nw = 'nw9011'
$latest_e16_cu = 'cu2'
$latest_e15_cu = 'cu13'
$latest_e14_sp = 'sp3'
$latest_e14_ur = 'ur13'
$latest_sqlver  = 'SQL2016'
$latest_master = '2012R2FallUpdate'
$Latest_2016 = '2016TP5'
$latest_sql_2012 = 'SQL2012SP2'
$NW85_requiredJava = "jre-7u61-windows-x64"
$Adminuser = "Administrator"
$Adminpassword = "Password123!"
$WAIKVER = "WAIK"
$DCNODE = "DCNODE"
$NWNODE = "NWSERVER"
$SPver = "SP2013SP1fndtn"
$SPPrefix = "SP2013"
$Sleep = 10
[string]$Sources = "Sources"
$Sourcedirdefault = "c:\$Sources"
[string]$Scripts = "labbuildr-scripts"
$Buildname = Split-Path -Leaf $Builddir
$Scenarioname = "default"
$Scenario = 1
$AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features")
$Gatewayhost = "11"
$Default_Host_ScriptDir = Join-Path $Builddir $Scripts
$DC_Scriptdir = Join-Path $Default_Host_ScriptDir "dcnode"
$DCNode_VMX = Join-Path $Builddir (Join-Path $DCNODE "$DCNODE.vmx")
$IN_Guest_UNC_Scriptroot = "\\vmware-host\Shared Folders\Scripts"
$IN_Guest_UNC_Sourcepath = "\\vmware-host\Shared Folders\Sources"
$IN_Guest_UNC_NodeScriptDir = "$IN_Guest_UNC_Scriptroot\Node"
$IN_Guest_LogDir = "C:\Scripts"
$Java7_Url = "https://labbuildrmaster.blob.core.windows.net/master/Java/jre-7u80-windows-x64.exe"
################
# labbuildr special statics
$my_repo = "labbuildr"
$labbuildr_modules_required = ('labtools','vmxtoolkit')
#$IN_Guest_UNC_NodeScriptDir = "$IN_Guest_UNC_Scriptroot\Node"
##################
### VMrun Error Condition help to tune the Bug wher the VMRUN Command can not communicate with the Host !
$VMrunErrorCondition = @("Waiting for Command execution Available", "Error", "Unable to connect to host.", "Error: The operation is not supported for the specified parameters", "Unable to connect to host. Error: The operation is not supported for the specified parameters", "Error: vmrun was unable to start. Please make sure that vmrun is installed correctly and that you have enough resources available on your system.", "Error: The specified guest user must be logged in interactively to perform this operation")
$Host.UI.RawUI.WindowTitle = "$Buildname"
###################################################
# main function go here
###################################################
function convert-iptosubnet
{
	param ($Subnet)
	$subnet = [System.Version][String]([System.Net.IPAddress]$Subnet)
	$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
	return, $Subnet
} #enc convert iptosubnet
function get-update
{
	param ([string]$UpdateSource, [string] $Updatedestination)
	$Origin = $MyInvocation.MyCommand
	$update = New-Object System.Net.WebClient
	$update.DownloadFile($Updatesource, $Updatedestination)
}
####
function update-fromGit
{
	param (
            [string]$Repo,
            [string]$RepoLocation,
            [string]$branch,
            [datetime]$latest_local_Git,
            [string]$Destination,
            [switch]$delete
            )
        $branch =  $branch.ToLower()
        $Isnew = $false
        Write-Verbose "Using update-fromgit function for $repo"
        $Uri = "https://api.github.com/repos/$RepoLocation/$repo/commits/$branch"
        $Zip = ("https://github.com/$RepoLocation/$repo/archive/$branch.zip").ToLower()
        try
            {
            $request = Invoke-WebRequest -UseBasicParsing -Uri $Uri -Method Head -ErrorAction Stop
            }
        Catch
            {
            Write-Warning "Error connecting to git"
            if ($_.Exception.Response.StatusCode -match "Forbidden")
                {
                Write-Host -ForegroundColor Gray " ==>Status inidicates that Connection Limit is exceeded"
                }
            exit
            }
        [datetime]$latest_OnGit = $request.Headers.'Last-Modified'
                Write-Verbose " ==>we have $repo version $latest_local_Git, $latest_OnGit is online !"
                $latest_local_Git -lt $latest_OnGit
                if ($latest_local_Git -lt $latest_OnGit -or $force.IsPresent )
                    {
                    $Updatepath = "$Builddir\Update"
					if (!(Get-Item -Path $Updatepath -ErrorAction SilentlyContinue))
					        {
						    $newDir = New-Item -ItemType Directory -Path "$Updatepath" | out-null
                            }
                    Write-Host -ForegroundColor Gray " ==>we found a newer Version for $repo on Git Dated $($request.Headers.'Last-Modified')"
                    if ($delete.IsPresent)
                        {
                        Write-Host -ForegroundColor Gray "==>cleaning $Destination"
                        Remove-Item -Path $Destination -Recurse -ErrorAction SilentlyContinue
                        }
                    Get-LABHttpFile -SourceURL $Zip -TarGetFile "$Builddir\update\$repo-$branch.zip" -ignoresize
                    Expand-LABZip -zipfilename "$Builddir\update\$repo-$branch.zip" -destination $Destination -Folder $repo-$branch
                    $Isnew = $true
                    $request.Headers.'Last-Modified' | Set-Content ($Builddir+"\$repo-$branch.gitver")
                    }
                else
                    {
                    Write-Host -ForegroundColor Gray " ==>no update required for $repo on $branch, already newest version "
                    }
if ($Isnew) {return $true}
}
#####
function Extract-Zip
{
	param ([string]$zipfilename, [string] $destination)
	$copyFlag = 16 # overwrite = yes
	$Origin = $MyInvocation.MyCommand
	if (test-path($zipfilename))
	{
        if (!(Test-Path $destination))
            {New-Item -ItemType Directory -Path $destination -Force | Out-Null }
        Write-Verbose "extracting $zipfilename"
        $shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items(), $copyFlag)
	}
}
function get-prereq
{
param ([string]$DownLoadUrl,
        [string]$destination )
$ReturnCode = $True
if (!(Test-Path $Destination))
    {
        Try
        {
        if (!(Test-Path (Split-Path $destination)))
            {
            New-Item -ItemType Directory  -Path (Split-Path $destination) -Force
            }
        Write-verbose "Starting Download of $DownLoadUrl"
        Start-BitsTransfer -Source $DownLoadUrl -Destination $destination -DisplayName "Getting $destination" -Priority Foreground -Description "From $DownLoadUrl..." -ErrorVariable err
                If ($err) {Throw ""}
        }
        Catch
        {
            $ReturnCode = $False
            Write-Warning " - An error occurred downloading `'$FileName`'"
            Write-Error $_
        }
    }
    else
    {
    Write-Host -ForegroundColor Gray " ==>No download needed, file exists"
    }
    return $ReturnCode
}
function domainjoin
{
    param (
    $nodeIP,
    $nodename,
    [Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
    $AddonFeatures
    )
    $Origin = $MyInvocation.MyCommand
    if ($Toolsupdate.IsPresent)
        {
        Write-Host -ForegroundColor Gray " ==>preparing VMware Tools Upgrade by injecting tools CD ( update will start before next reboot of VM )"
        Start-Process 'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe' -ArgumentList  "installTools $CloneVMX" -NoNewWindow
        }
	do
        {
        Write-Verbose "Calling $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-node.ps1 -Parameter -nodeip $Nodeip -nodename $Nodename -Domain $BuildDomain -domainsuffix $custom_domainsuffix -IPv4subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix $AddGateway -AddOnfeatures '$AddonFeatures' $CommonParameter"
        $domainadd = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-node.ps1 -Parameter "-nodeip $Nodeip -nodename $Nodename -Domain $BuildDomain -domainsuffix $custom_domainsuffix -IPv4subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix $AddGateway -AddOnfeatures '$AddonFeatures' $CommonParameter" -nowait -interactive # $CommonParameter
        }
    until ($domainadd -match "success")
    # Write-Host -ForegroundColor Gray " ==>waiting for Phase Domain Joined"
    do {
        $ToolState = Get-VMXToolsState -config $CloneVMX
        Write-Verbose $ToolState.State
        }
    until ($ToolState.state -match "running")
	# Write-Host -ForegroundColor Green "[success]"
    Write-Verbose "Paranoia, checking shared folders second time"
    $Folderstate = Set-VMXSharedFolderState -VMXName $nodename -config $CloneVMX -enabled
    Write-Verbose "Please Check inside VM for Network Warnings"
	Write-Host -ForegroundColor Gray " ==>Joining $nodename to Domain $BuildDomain " -NoNewline
	While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\3.pass) -ne "The file exists.") 
		{
		$sleep = 1
		foreach ($i in (1..$sleep)) 
			{
			Write-Host -ForegroundColor Yellow "-`b" -NoNewline
			sleep 1
			Write-Host -ForegroundColor Yellow "\`b" -NoNewline
			sleep 1
			Write-Host -ForegroundColor Yellow "|`b" -NoNewline
			sleep 1
			Write-Host -ForegroundColor Yellow "/`b" -NoNewline
			sleep 1
			}
		}
    Write-Host -ForegroundColor Green "[Done]"
    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-labshortcut.ps1 -interactive # -Parameter $CommonParameter
}
function debug
{
	param ([string]$message)
	write-host -ForegroundColor Red $message
}
function runtime
{
	param ($Time, $InstallProg)
	$Timenow = Get-Date
	$Difftime = $Timenow - $Time
	$StrgTime = ("{0:D2}" -f $Difftime.Hours).ToString() + $Dots + ("{0:D2}" -f $Difftime.Minutes).ToString() + $Dots + ("{0:D2}" -f $Difftime.Seconds).ToString()
	write-host "`r".padright(1, " ") -nonewline
	Write-Host -ForegroundColor Yellow "$InstallProg Setup Running Since $StrgTime" -NoNewline
}
<#
	.SYNOPSIS
		we test if the Domaincontroller DCNODE is up and Running
	.DESCRIPTION
		A detailed description of the test-dcrunning function.
	.EXAMPLE
		PS C:\> test-dcrunning
	.NOTES
		Requires the DC inside labbuildr Runspace
#>
function test-dcrunning
{
$Origin = $MyInvocation.MyCommand
if (!$NoDomainCheck.IsPresent)
	{
	if ((get-vmx -Path $DCNODE).state -ne "running")
		{
		Write-Host -ForegroundColor White  " ==>Domaincontroller not running, we need to start him first"
		$Started = get-vmx -path $DCNODE | Start-vmx
		if (!$started)
			{
			debug " ==>Domaincontroller not found, giving up"
			break
			}#end else	
		}
	} # end nodomaincheck
} #end test-dcrunning
<#
	.SYNOPSIS
		This Function gets IP, Domainname and VMnet from the Domaincontroller.
	.DESCRIPTION
		A detailed description of the test-domainsetup function.
	.EXAMPLE
		PS C:\> test-domainsetup
	.NOTES
		Additional information about the function.
#>
function test-domainsetup
{
	test-dcrunning
	Write-Host -ForegroundColor Gray " ==>testing shared folders on DCNODE"
    $enable_Folders =  get-vmx $DCNODE | Set-VMXSharedFolderState -Enabled
	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Domain Name ...: "
	$holdomain = Get-Content (Join-path $DC_Scriptdir "domain.txt")
	Write-Host -ForegroundColor White $holdomain
	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Subnet.........: "
	$DomainIP = Get-Content (Join-path $DC_Scriptdir "ip.txt")
	$IPv4subnet = convert-iptosubnet $DomainIP
	Write-Host -ForegroundColor White  $ipv4Subnet
	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing Default Gateway: "
	$DomainGateway = Get-Content (Join-path $DC_Scriptdir "gateway.txt")
	Write-Host -ForegroundColor White  $DomainGateway
	Write-Host -NoNewline -ForegroundColor DarkCyan "Testing VMnet .........: "
    $MyVMnet = (get-vmx $DCNODE | Get-VMXNetwork -WarningAction SilentlyContinue).network
	Write-Host -ForegroundColor White  $MyVMnet
	Write-Output $holdomain, $Domainip, $VMnet, $DomainGateway
} #end
function test-user
{
	param ($whois)
	$Origin = $MyInvocation.MyCommand
	Write-Host -ForegroundColor Gray -NoNewline " ==>waiting for user $whois logged in "
	do
		{
		$sleep = 1
		$cmdresult = $Nodeclone | Get-VMXProcessesInGuest -Guestuser $Adminuser -Guestpassword $Adminpassword
		foreach ($i in (1..$sleep))
			{
			Write-Host -ForegroundColor Yellow "-`b" -NoNewline
			sleep 1
			Write-Host -ForegroundColor Yellow "\`b" -NoNewline
			sleep 1
			Write-Host -ForegroundColor Yellow "|`b" -NoNewline
			sleep 1
			Write-Host -ForegroundColor Yellow "/`b" -NoNewline
			sleep 1
			}
	}
until ($cmdresult -match $whois) 
Write-Host	"[success]"
}
function test-source
{
	param ($SourceVer, $SourceDir)
	$SourceFiles = (Get-ChildItem $SourceDir -ErrorAction SilentlyContinue).Name
	#####
	foreach ($Version in ($Sourcever))
	{
		if ($Version -ne "")
		{
			write-verbose "Checking $Version"
			if (!($SourceFiles -contains $Version))
			{
				write-Host "$Sourcedir does not contain $Version"
				debug "Please Download and extraxt $Version to $Sourcedir\$Version"
				$Sourceerror = $true
			}
			else { write-verbose "found $Version, good..." }
		}
	}
	If ($Sourceerror) { return, $false }
	else { return, $true }
}
<#
	.SYNOPSIS
		A brief description of the checkpoint-progress function.
	.DESCRIPTION
		A detailed description of the checkpoint-progress function.
	.PARAMETER Guestpassword
		A description of the Guestpassword parameter.
	.PARAMETER Guestuser
		A description of the Guestuser parameter.
	.PARAMETER pass
		A description of the pass parameter.
	.PARAMETER reboot
		A description of the reboot parameter.
	.EXAMPLE
		PS C:\> checkpoint-progress -Guestpassword 'Value1' -Guestuser $value2
	.NOTES
		Additional information about the function.
#>
function checkpoint-progress
{
	param (
        $step,
        [switch]$reboot,
        [switch]$Nowait,
        $Guestuser = $Adminuser,
        $Guestpassword = $Adminpassword
        )
	$Origin = $MyInvocation.MyCommand
    if ($reboot.IsPresent)
        {
        $AddParameter = " -reboot"
        }
	$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\Node" -Script set-step.ps1 -nowait -interactive -Parameter " -step $step $AddParameter" # $CommonParameter
    if (!$Nowait.IsPresent)
        {
	    write-Host -ForegroundColor Gray " ==>waiting on reboot Checkpoint $step " -NoNewline
        do {
            $ToolState = Get-VMXToolsState -config $CloneVMX
            Write-Verbose $ToolState.State
            }
        until ($ToolState.state -match "running")
	    While ($FileOK = (&$vmrun -gu $Adminuser -gp $Adminpassword fileExistsInGuest $CloneVMX "$IN_Guest_LogDir\$step.pass") -ne "The file exists.") 
			{
			foreach ($i in (1..$sleep))
				{
				Write-Host -ForegroundColor Yellow "-`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "\`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "|`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "/`b" -NoNewline
				sleep 1
				}
			}
		write-host -ForegroundColor Green "[reached]"
        }
    else
        {
        Write-Verbose "Not Waiting for Reboot"
        }
}
function CreateShortcut
{
	$wshell = New-Object -comObject WScript.Shell
	$Deskpath = $wshell.SpecialFolders.Item('Desktop')
	$link = $wshell.CreateShortcut("$Deskpath\$Buildname.lnk")
	$link.TargetPath = "$psHome\powershell.exe"
	$link.Arguments = "-noexit -command $Builddir\profile.ps1"
	$link.Description = "$Buildname"
	$link.WorkingDirectory = "$Builddir"
	$link.IconLocation = 'powershell.exe'
	$link.Save()
}
function invoke-postsection
    {
    param (
    [switch]$wait)
    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_NodeScriptDir" -Script Set-Customlanguage.ps1 -Parameter "-LanguageTag $LanguageTag " -interactive # $CommonParameter
	$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_NodeScriptDir" -Script powerconf.ps1 -interactive # $CommonParameter
    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_NodeScriptDir" -Script set-uac.ps1 -interactive # $CommonParameter
    if ($LabDefaults.Puppet)
        {
        $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\Node" -Script install-puppetagent.ps1 -Parameter "-Puppetmaster $Puppetmaster" -interactive # $CommonParameter
        }
    if ($wait.IsPresent)
        {
        checkpoint-progress -step UAC -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
        }
    else
        {
        checkpoint-progress step UAC -reboot -Nowait -Guestuser $Adminuser -Guestpassword $Adminpassword
        }
    }
####################################################
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    $CommonParameter = ' -verbose'
    }
if ($PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent)
    {
    $CommonParameter = ' -debug'
    }
####################################################
switch ($PsCmdlet.ParameterSetName)
{
    "update"
        {
        $ReloadProfile = $False
        $Repo = $my_repo
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_git
        $Destination = "$Builddir"
        $Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination
        if (Test-Path "$Builddir\deletefiles.txt")
		    {
			$deletefiles = get-content "$Builddir\deletefiles.txt"
			foreach ($deletefile in $deletefiles)
			    {
				try
					{
					Remove-Item -Path (join-path $Builddir $deletefile) -Recurse -ErrorAction Stop
					}
				catch
				    {
					
					}
			    }
            }
        else
            {
            Write-Host -ForegroundColor Gray " ==>no Deletions required"
            }
        ####
        $Repo = "labbuildr-scripts"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_scripts_git
        $Destination = "$Default_Host_ScriptDir"
        $Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete
        foreach ($Repo in $labbuildr_modules_required)
            {
        $RepoLocation = "bottkars"
        try
            {
            [datetime]$Latest_local_git = Get-Content  ($Builddir + "\$($Repo)-$branch.gitver")  -ErrorAction SilentlyContinue
            }
        catch
            {}
        #$Latest_local_git = $Latest_$($repo)_git
        $Destination = "$Builddir\$Repo"
        if ($Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete)
            {
            $ReloadProfile = $True
            }
        }
        ####
        $Branch | Set-Content -Path "$Builddir\labbuildr.branch" -Force # -Verbose
        if ($ReloadProfile)
            {
            Remove-Item .\Update -Recurse -Confirm:$false
			Write-Host -ForegroundColor White  " ==>Update Done"
            Write-Host -ForegroundColor White  " ==>press any key for reloading Modules"
            pause
            ./profile.ps1
            }
        else
            {
            ."./$Myself_ps1"
            }
    return
    #$ReloadProfile
    }# end Updatefromgit
    "Shortcut"
        {
				Write-Host -ForegroundColor White  "creating desktop Shortcut for $Buildname"
				createshortcut
                return
    }# end shortcut
    "Version"
        {
				Write-Host -ForegroundColor Magenta -NoNewline "$my_repo version $major-$Edition on branch : "
                Write-Host -ForegroundColor Cyan "$Current_labbuildr_branch"
                If ($branch -ne "master")
                    {
                    Write-Warning "you are on $branch, considered experimental
==>recommended action is running '.\build-lab.ps1 -update -branch master -force'"
Write-Host
                    }
                if ($Latest_labbuildr_git)
                    {
                    Write-Host -ForegroundColor White "$my_repo Git Release $Latest_labbuildr_git"
                    }
                if ($Latest_vmxtoolkit_git)
                    {
                    Write-Host -ForegroundColor White  "vmxtoolkit Git Release $Latest_vmxtoolkit_git"
                    }
                if ($Latest_labbuildr_scripts_git)
                    {
                    Write-Host -ForegroundColor White  "scripts Git Release $Latest_labbuildr_scripts_git"
                    }
                if ($Latest_labtools_git)
                    {
                    Write-Host -ForegroundColor White  "labtools Git Release $Latest_labtools_git"
                    }
                Write-Host -ForegroundColor Gray '   Copyright 2016 Karsten Bott
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
       http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.'
				return
			} #end Version
}
####################################################
if (!(test-path (Join-path $builddir $scripts )))
	{
	Write-Warning "labbuildr changed the scriptdir to $Scripts. we can not find scripts $Scripts, please run
	 .\build-lab.ps1 -update -force"
	Break
	}

#################### default Parameter Section Start
write-verbose "Config pre defaults"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    write-output $PSCmdlet.MyInvocation.BoundParameters
    }
###################################################
## do we want defaults ?
if ($defaults.IsPresent)
    {
    if (Test-Path $Builddir\defaults.xml)
        {
        Write-Host -ForegroundColor White " ==>loading defaults from $Builddir\defaults.xml"
        $LabDefaults = Get-LABDefaults
        }
       if (!($LabDefaults))
            {
            try
                {
                $LabDefaults = Get-labDefaults -Defaultsfile ".\defaults.xml.example"
                }
            catch
                {
            Write-Warning "no  defaults or example defaults found, exiting now"
            exit
                }
            Write-Host -ForegroundColor Magenta "Using generic defaults from $my_repo"
        }
        $DefaultGateway = $LabDefaults.DefaultGateway
        if (!$nmm_ver)
            {
            try
                {
                $nmm_ver = $LabDefaults.nmm_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Host -ForegroundColor Gray " ==>defaulting NMM version to $latest_nmm"
                 $nmm_ver = $latest_nmm
                }
            }
        $nmm_scvmm_ver = $nmm_ver -replace "nmm","scvmm"
        if (!$nw_ver)
            {
            try
                {
                $nw_ver = $LabDefaults.nw_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Host -ForegroundColor Gray " ==>defaulting nw version to $latest_nw"
                 $nw_ver = $latest_nw
                }
            }
        if (!$Masterpath)
            {
            try
                {
                $Masterpath = $LabDefaults.Masterpath
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No Masterpath specified, trying default"
                $Masterpath = $Builddir
                }
            }
        if (!$Sourcedir)
            {
            try
                {
                $Sourcedir = $LabDefaults.Sourcedir
                }
            catch [System.Management.Automation.ParameterBindingException]
                {
                Write-Host -ForegroundColor Gray " ==>No sources specified, trying default"
                $Sourcedir = $Sourcedirdefault
                }
            }
        if (!$Master)
            {
            try
                {
                $master = $LabDefaults.master
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No Master specified, trying default"
                $Master = $latest_master
                }
            }
        if (!$SQLVER)
            {
            try
                {
                $sqlver = $LabDefaults.sqlver
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No sqlver specified, trying default"
                $sqlver = $latest_sqlver
                }
            }
        if (!$e14_sp)
            {
            try
                {
                $e14_sp = $LabDefaults.e14_sp
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No Exchange 2010 SP Specified, setting $latest_e14_sp"
                $e14_sp = $latest_e14_sp
                }
            }
        if (!$e14_ur)
            {
            try
                {
                $e14_ur = $LabDefaults.e14_ur
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No Exchange 2010 Update Rollup Specified, setting $latest_e14_ur"
                $e14_ur = $latest_e14_ur
                }
            }
        if (!$e15_cu)
            {
            try
                {
                $e15_cu = $LabDefaults.e15_cu
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No Exchange 2013 CU Specified, setting $latest_e15_cu"
                $e15_cu = $latest_e15_cu
                }
            }
        if (!$e16_cu)
            {
            try
                {
                $e16_cu = $LabDefaults.e16_cu
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No Exchange 2016 CU Specified, setting $latest_e16_cu"
                $e16_cu = $latest_e16_cu
                }
            }
        if (!$ScaleIOVer)
            {
            try
                {
                $ScaleIOVer = $LabDefaults.ScaleIOVer
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No ScaleIOVer specified, trying default"
                $ScaleIOVer = $latest_ScaleIOVer
                }
            }
        if (!$vmnet)
            {
            try
                {
                $vmnet = $LabDefaults.vmnet
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }
        if (!$BuildDomain)
            {
            try
                {
                $BuildDomain = $LabDefaults.BuildDomain
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No BuildDomain specified, trying default"
                $BuildDomain = $Default_BuildDomain
                }
            }
        if  (!$MySubnet)
            {
            try
                {
                $MySubnet = $LabDefaults.mysubnet
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No mysubnet specified, trying default"
                $MySubnet = $Default_Subnet
                }
            }
       if (!$vmnet)
            {
            try
                {
                $vmnet = $LabDefaults.vmnet
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }
       if (!$AddressFamily)
            {
            try
                {
                $AddressFamily = $LabDefaults.AddressFamily
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No AddressFamily specified, trying default"
                $AddressFamily = $Default_AddressFamily
                }
            }
       if (!$IPv6Prefix)
            {
            try
                {
                $IPv6Prefix = $LabDefaults.IPv6Prefix
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No IPv6Prefix specified, trying default"
                $IPv6Prefix = $Default_IPv6Prefix
                }
            }
       if (!$IPv6PrefixLength)
            {
            try
                {
                $IPv6PrefixLength = $LabDefaults.IPv6PrefixLength
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==>No IPv6PrefixLength specified, trying default"
                $IPv6PrefixLength = $Default_IPv6PrefixLength
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("Gateway")))
            {
            if ($LabDefaults.Gateway -eq "true")
                {
                $Gateway = $true
                [switch]$NW = $True
                $DefaultGateway = "$IPv4Subnet.$Gatewayhost"
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NoDomainCheck")))
            {
            if ($LabDefaults.NoDomainCheck -eq "true")
                {
                [switch]$NoDomainCheck = $true
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NMM")))
            {
            if ($LabDefaults.NMM -eq "true")
                {
                $nmm = $true
                $nw = $true
                }
            }
    }
if (!$MySubnet) {$MySubnet = "192.168.2.0"}
$IPv4Subnet = convert-iptosubnet $MySubnet
if (!$BuildDomain) { $BuildDomain = $Default_BuildDomain }
if (!$ScaleIOVer) {$ScaleIOVer = $latest_ScaleIOVer}
if (!$SQLVER) {$SQLVER = $latest_sqlver}
if (!$e14_ur) {$e14_ur = $latest_e14_ur}
if (!$e14_sp) {$e14_sp = $latest_e14_sp}
if (!$e15_cu) {$e15_cu = $latest_e15_cu}
if (!$e16_cu) {$e16_cu = $latest_e16_cu}
if (!$Master) {$Master = $latest_master}
if (!$nmm_ver) {$nmm_ver= $latest_nmm}
if (!$nw_ver) {$nw_ver= $latest_nw}
if (!$vmnet) {$vmnet = $Default_vmnet}
if (!$IPv6PrefixLength){$IPv6PrefixLength = $Default_IPv6PrefixLength}
if (!$LabDefaults.DNS1)
    {
    $DNS1 = "$IPv4Subnet.10"
    }
else
    {
    $DNS1 = $LabDefaults.DNS1
    }
if ($LabDefaults.custom_domainsuffix)
	{
	$custom_domainsuffix = $LabDefaults.custom_domainsuffix
	}
else
	{
	$custom_domainsuffix = "local"
	}
if ($LabDefaults.LanguageTag)
	{
	$LanguageTag= $LabDefaults.LanguageTag
	}
else
	{
	$LanguageTag = "en_US"
	}
write-verbose "After defaults !!!! "
Write-Verbose "Sourcedir : $Sourcedir"
Write-Verbose "NWVER : $nw_ver"
Write-Verbose "Gateway : $($Gateway.IsPresent)"
Write-Verbose "NMM : $($nmm.IsPresent)"
Write-Verbose "MySubnet : $MySubnet"
Write-Verbose "ScaleIOVer : $ScaleIOVer"
Write-Verbose "Masterpath : $Masterpath"
Write-Verbose "Master : $Master"
Write-Verbose "Defaults before Safe:"
If ($DefaultGateway -match "$IPv4Subnet.$Gatewayhost")
    {
    $gateway = $true
    }
If ($Gateway.IsPresent)
            {
            $DefaultGateway = "$IPv4Subnet.$Gatewayhost"
            }
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    if (Test-Path $Builddir\defaults.xml)
        {
        Get-Content $Builddir\defaults.xml | Write-Host -ForegroundColor Gray
        }
    }
#### do we have unset parameters ?
if (!$AddressFamily){$AddressFamily = "IPv4" }
###################################################
if ($savedefaults.IsPresent)
{
$defaultsfile = New-Item -ItemType file $Builddir\defaults.xml -Force
Write-Host -ForegroundColor White  "saving defaults to $Builddir\defaults.xml"
$config =@()
        $config += ("<config>")
        $config += ("<LanguageTag>$($LanguageTag)</LanguageTag>")
        $config += ("<nmm_ver>$($nmm_ver)</nmm_ver>")
        $config += ("<nmm>$($nmm)</nmm>")
        $config += ("<nw_ver>$($nw_ver)</nw_ver>")
        $config += ("<master>$($Master)</master>")
        $config += ("<sqlver>$($SQLVER)</sqlver>")
        $config += ("<e14_ur>$($e14_ur)</e14_ur>")
        $config += ("<e14_sp>$($e14_sp)</e14_sp>")
        $config += ("<e15_cu>$($e15_cu)</e15_cu>")
        $config += ("<e16_cu>$($e16_cu)</e16_cu>")
        $config += ("<vmnet>$($VMnet)</vmnet>")
        $config += ("<vlanID>$($vlanID)</vlanID>")
        $config += ("<Custom_DomainSuffix>$($Custom_DomainSuffix)</Custom_DomainSuffix>")
        $config += ("<BuildDomain>$($BuildDomain)</BuildDomain>")
        $config += ("<MySubnet>$($MySubnet)</MySubnet>")
        $config += ("<AddressFamily>$($AddressFamily)</AddressFamily>")
        $config += ("<IPV6Prefix>$($IPV6Prefix)</IPV6Prefix>")
        $config += ("<IPv6PrefixLength>$($IPv6PrefixLength)</IPv6PrefixLength>")
        $config += ("<Gateway>$($Gateway.IsPresent)</Gateway>")
        $config += ("<DefaultGateway>$($DefaultGateway)</DefaultGateway>")
        $config += ("<DNS1>$($DNS1)</DNS1>")
        $config += ("<DNS2>$($DNS2)</DNS2>")
        $config += ("<Sourcedir>$($Sourcedir)</Sourcedir>")
        $config += ("<ScaleIOVer>$($ScaleIOVer)</ScaleIOVer>")
        $config += ("<Masterpath>$($Masterpath)</Masterpath>")
        $config += ("<NoDomainCheck>$($NoDomainCheck)</NoDomainCheck>")
        $config += ("<Puppet>$($Puppet)</Puppet>")
        $config += ("<PuppetMaster>$($PuppetMaster)</PuppetMaster>")
        $config += ("<Hostkey>$($LabDefaults.HostKey)</Hostkey>")
        $config += ("</config>")
$config | Set-Content $defaultsfile
}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent -and $savedefaults.IsPresent )
    {
    Write-Verbose  "Defaults after Save"
    Get-Content $Builddir\defaults.xml | Write-Host -ForegroundColor Magenta
    }
####### Master Check
if (!$Sourcedir)
    {
    Write-Warning "no Sourcedir specified, will exit now"
    exit
    }
else
    {
    try
        {
        Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null
        }
    catch
        [System.Management.Automation.DriveNotFoundException]
        {
        Write-Warning "Drive not found, make sure to have your Source Stick connected"
        return
        }
    catch [System.Management.Automation.ItemNotFoundException]
        {
        Write-Warning "no sources directory found named $Sourcedir"
        return
        }
     }
if (!$Master)
    {
    Write-Warning "No Master was specified. See get-help .\labbuildr.ps1 -Parameter Master !!"
    Write-Host -ForegroundColor Gray " ==>Load masters from $UpdateUri"
    break
    } # end Master
write-verbose "After Masterconfig !!!! "
########
########
if ($runonos  -match "win_x86_64")
	{
	write-verbose "Evaluating Machine Type, Please wait ..."
	#### Eval CPU
	$Numcores = (gwmi win32_Processor).NumberOfCores
	$NumLogCPU = (gwmi win32_Processor).NumberOfLogicalProcessors
	$CPUType = (gwmi win32_Processor).Name
	$MachineMFCT = (gwmi win32_ComputerSystem).Manufacturer
	$MachineModel = (gwmi win32_ComputerSystem).Model
	##### Eval Memory #####
	$Totalmemory = 0
	$Memory = (get-wmiobject -class "win32_physicalmemory" -namespace "root\CIMV2").Capacity
	foreach ($Dimm in $Memory) { $Totalmemory = $Totalmemory + $Dimm }
	$Totalmemory = $Totalmemory / 1GB
	Switch ($Totalmemory)
	{
		{ $_ -gt 0 -and $_ -le 8 }
		{
			$Computersize = 1
			$SQLSize = "L"
			$Exchangesize = "XL"
		}
		{ $_ -gt 8 -and $_ -le 16 }
		{
			$Computersize = 2
			$Exchangesize = "TXL"
			$SQLSize = "XL"
		}
		{ $_ -gt 16 -and $_ -le 32 }
		{
			$Computersize = 3
			$Exchangesize = "TXL"
			$SQLSize = "TXL"
		}
		else
		{
			$Computersize = 3
			$Exchangesize = "XXL"
			$SQLSize = "TXL"
		}
	}
	If ($NumLogCPU -le 4 -and $Computersize -le 2)
	{
		Write-Host -ForegroundColor White "==>Running $my_repo on a $MachineMFCT $MachineModel with $CPUType with $Numcores Cores and $NumLogCPU Logicalk CPUs and $Totalmemory GB Memory "
	}
	If ($NumLogCPU -gt 4 -and $Computersize -le 2)
	{
		Write-Host -ForegroundColor White "==>Running $my_repo on a $MachineMFCT $MachineModel with $CPUType with $Numcores Cores and $NumLogCPU Logical CPU and $Totalmemory GB Memory"
		Write-Host "Consider Adding Memory "
	}
	If ($NumLogCPU -gt 4 -and $Computersize -gt 2)
	{
		Write-Host -ForegroundColor White  "Excellent, Running $my_repo on a $MachineMFCT $MachineModel with $CPUType with $Numcores Cores and $NumLogCPU Logical CPU and $Totalmemory GB Memory"
	}
	}
else
	{
    $MachineModel = uname -a
    Write-Host -ForegroundColor White  "Excellent, running labbuildr on $MachineModel"
    if ($runonos -eq "OSX")
		{
		sw_vers
		}
    $Computersize = 2
	$Exchangesize = "TXL"
	$SQLSize = "XL"
	}####### Building required Software Versions Tabs
$NW_Sourcedir = Join-Path $Sourcedir "Networker"
$Sourcever = @()
# $Sourcever = @("$nw_ver","$nmm_ver","E2013$e15_cu","$WAIKVER","$SQL2012R2")
if (!($DConly.IsPresent))
{
	if ($Exchange2010.IsPresent)
        {
        $EX_Version = "E2010"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
	if ($Exchange2013.IsPresent)
        {
        $EX_Version = "E2013"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
    if ($Exchange2016.IsPresent)
        {
        $EX_Version = "E2016"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
	#  if (($NMM.IsPresent) -and ($Blanknode -eq $false)) { $Sourcever += $nmm_ver }
	# if ($NW.IsPresent) { $Sourcever += $nw_ver }
	# if ($NWServer.IsPresent -or $NW.IsPresent -or $NMM.IsPresent )
    #    {
    #    $Sourcever += $nw_ver
    #    }
	if ($SQL.IsPresent -or $AlwaysOn.IsPresent)
        {
        $Sourcever +=  $AAGDB #$SQLVER,
        $Scenarioname = "SQL"
        $SQL = $true
        $Scenario = 2
        }
	if ($HyperV.IsPresent)
	{
        $Scenarioname = "Hyper-V"
        $Scenario = 3
        if ($ScaleIO.IsPresent)
            {
            $Sourcever += "ScaleIO"
            }
	}
	if ($Sharepoint.IsPresent)
	{
        $Scenarioname = "Sharepoint"
        $Scenario = 4
	}
} # end not dconly
Write-Host -ForegroundColor White  "Version $($major).$Edition"
Write-Host -ForegroundColor Magenta " ==>Building Proposed Workorder"
If ($DAG.IsPresent)
    {
    if (!$EXNodes)
        {
        $EXNodes = 2
        Write-Host -ForegroundColor Gray " ==>No -EXnodes specified, defaulting to $EXNodes Nodes for DAG Deployment"
        }
    }
if (!$EXnodes)
    {$EXNodes = 1}
if ($Blanknode.IsPresent)
{
	$Work_Items +=  " ==>we are going to Install $BlankNodes Blank Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using $VMnet"
    Write-Host -ForegroundColor Magenta " ==>The Gateway will be $DefaultGateway"
	if ($VTbit) { write-verbose "Virtualization will be enabled in the Nodes" }
	if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered" }
}
if ($SOFS.IsPresent)
{
	$Work_Items +=  " ==>we are going to Install $SOFSNODES SOFS Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using $VMnet"
    if ($DefaultGateway.IsPresent){ Write-Host -ForegroundColor Magenta " ==>The Gateway will be $DefaultGateway"}
	if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered ( Single Node Clusters )" }
}
if ($HyperV.IsPresent)
{
}#end Hyperv.ispresent
if ($ScaleIO.IsPresent)
{
    If ($HyperVNodes -lt 3)
                {
                Write-Host -ForegroundColor Gray " ==>Need 3 nodes for ScaleIO, incrementing to 3"
                $HyperVNodes = 3
                }
$Work_Items +=  " ==>we are going to Install ScaleIO on $HyperVNodes Hyper-V Nodes in cluster HV$($Clusternum)Cluster"
    if ($DefaultGateway.IsPresent){ Write-Host -ForegroundColor Magenta " ==>The Gateway will be $DefaultGateway"}
	# if ($Cluster.IsPresent) { write-verbose "The Nodes will be Clustered ( Single Node Clusters )" }
}
if ($AlwaysOn.IsPresent -or $PsCmdlet.ParameterSetName -match "AAG" -or $SPdbtype -eq "AlwaysOn")
{
	$Work_Items +=  " ==>we are going to Install an SQL Always On Cluster with $AAGNodes Nodes with size $Size in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet"
	$AlwaysOn = $true
    # if ($NoNMM -eq $false) {Write-Host -ForegroundColor White  "Networker Modules will be installed on each Node"}
}
#if ($NWServer.IsPresent -or $NW.IsPresent)
#################################################
## Download Sewction       ######################
#################################################
$Work_Items = $()
Write-Host -ForegroundColor Magenta " ==>Entering Download Section"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    write-host "Press enter to Continue to Automatic Downloads or ctrl-c to exit"
    Pause
    }
##### exchange downloads section
if ($Exchange2010.IsPresent)
    {
    if (!$e14_sp)
        {
        $e14_sp = $Latest_e14_sp
        }
    if (!$e14_ur)
        {
        $e14_ur = $Latest_e14_ur
        }
    If ($Master -notin ('2012_Ger','2012'))
        {
        Write-Warning "You selected $Master as master, but only master up to 2012 are supported in this scenario"
        return
        }
    If (!(Receive-LABExchange -Exchange2010 -e14_sp $e14_sp -e14_ur $e14_ur  -e14_lang $e14_lang -Destination $Sourcedir -unzip))
        {
        Write-Host -ForegroundColor Gray " ==>we could not receive Exchange 2010 $e14_sp"
        return
        }
    $EX_Version = "E2010"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf"
    )
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
		$Destination_file = Join-Path $Destination $FileName
        if (!(test-path  $Destination_file))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Destination_file))
                { Write-Host -ForegroundColor Gray " ==>Error Downloading file $Url, Please check connectivity"
                  Write-Host -ForegroundColor Gray " ==>creating dummy File"
                  New-Item -ItemType file -Path $Destination_file | out-null
                }
            }
        }
	    if ($DAG.IsPresent)
	        {
		    $Work_Items +=  " ==>we will form a $EX_Version $EXNodes-Node DAG"
	        }
}
#########
##### exchange downloads section
if ($Exchange2013.IsPresent)
    {
    if (!$e15_cu)
        {
        $e15_cu = $Latest_e15_cu
        }
    If ($Master -gt '2012Z')
        {
        Write-Warning "Only master up 2012R2Fallupdate supported in this scenario"
        exit
        }
    If (!(Receive-LABExchange -Exchange2013 -e15_cu $e15_cu -Destination $Sourcedir -unzip))
        {
        Write-Host -ForegroundColor Gray " ==>we could not receive Exchange 2013 $e15_cu"
        return
        }
    $EX_Version = "E2013"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf"
    )
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
		$Destination_file = Join-Path $Destination $FileName
        if (!(test-path  $Destination_file))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Destination_file))
                { Write-Host -ForegroundColor Gray " ==>Error Downloading file $Url, Please check connectivity"
                  Write-Host -ForegroundColor Gray " ==>creating dummy File"
                  New-Item -ItemType file -Path $Destination_file | out-null
                }
            }
        }
	    if ($DAG.IsPresent)
	        {
		    $Work_Items +=  " ==>we will form a $EX_Version $EXNodes-Node DAG"
	        }
}
#########
##### exchange 2016 downloads section
if ($Exchange2016.IsPresent)
    {
    if (!$e16_cu)
        {
        $e16_cu = $Latest_e16_cu
        }
    If ($Master -gt '2012Z')
        {
        Write-Warning "Only master up 2012R2Fallupdate supported in this scenario"
        exit
        }
    If (!(Receive-LABExchange -Exchange2016 -e16_cu $e16_cu -Destination $Sourcedir -unzip))
        {
        Write-Warning " ==>we could not receive Exchange 2016 $e16_cu"
        return
        }
    $EX_Version = "E2016"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = ($Default_attachement)
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
		$Destination_file = Join-Path $Destination $FileName
        if (!(test-path  $Destination_file))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Destination_file))
                { Write-Host -ForegroundColor Gray " ==>Error Downloading file $Url, Please check connectivity"
                  Write-Host -ForegroundColor Gray " ==>creating dummy File"
                  New-Item -ItemType file -Path $Destination_file | out-null
                }
            }
        }
	    if ($DAG.IsPresent)
	        {
		    $Work_Items +=  " ==>we will form a $EXNodes-Node DAG"
	        }
}
#########
if ($NMM.IsPresent)
    {
    Write-Host -ForegroundColor Magenta " ==>Networker Modules $nmm_ver will be intalled by User selection" }
if ($Sharepoint.IsPresent)
    {
    $Prereqdir = "$spver"+"prereq"
    Write-Verbose " ==>we are now going to Test Sharepoint Prereqs"
    $DownloadUrls = (
		    "http://download.microsoft.com/download/9/1/3/9138773A-505D-43E2-AC08-9A77E1E0490B/1033/x64/sqlncli.msi", # Microsoft SQL Server 2008 R2 SP1 Native Client
		    "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi", # Microsoft Sync Framework Runtime v1.0 SP1 (x64)
		    "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe", # Windows Server App Fabric
            "http://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe", # Cumulative Update Package 1 for Microsoft AppFabric 1.1 for Windows Server (KB2671763)
            "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu", #Windows Identity Foundation (KB974405)
		    "http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi", # Microsoft Identity Extensions
		    "http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi", # Microsoft Information Protection and Control Client
		    "http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe" # Microsoft WCF Data Services 5.0
                )
    if (Test-Path $Sourcedir/$Prereqdir)
        {
        Write-Verbose "Sharepoint Prereq Sourcedir Found"
        }
        else
        {
        Write-Verbose "==>creating Prereq Sourcedir for Sharepoint"
        New-Item -ItemType Directory -Path $Sourcedir\$Prereqdir | Out-Null
        }
    foreach ($URL in $DownloadUrls)
        {
        $FileName = Split-Path -Leaf -Path $Url
        Write-Verbose "...checking for $FileName"
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                {
                Write-Warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            }
        }
        $URL = "http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe"
        $FileName = "WcfDataServices56.exe"
        Write-Verbose "...checking for $FileName"
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                {
                Write-Warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            }
        $Url = "http://download.microsoft.com/download/6/E/3/6E3A0B03-F782-4493-950B-B106A1854DE1/sharepoint.exe"
        Write-Verbose "Testing Sharepoint SP1 Foundation exists in $Sourcedir"
        if (!(test-path  "$Sourcedir\$SPver"))
            {
            $FileName = Split-Path -Leaf -Path $Url
            Write-Verbose "Trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                {
                Write-Warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            Write-Verbose "Extracting $FileName"
            Start-Process -FilePath "$Sourcedir\$FileName" -ArgumentList "/extract:$Sourcedir\$SPver /quiet /passive" -Wait
            }
    $Work_Items +=  " ==>we are going to Install Sharepoint 2013 in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet and SQL"
    }# end SPPREREQ
if ($ConfigureVMM.IsPresent)
    {
    [switch]$SCVMM = $true
    }
############## scvmm  download section
if ($SCVMM.IsPresent)
  {
    Write-Host -ForegroundColor Gray " ==>Entering SCVMM Prereq Section"
    [switch]$SQL=$true
    $Prereqdir = "prereq"
    if ($SC_Version -match "2012")
        {
        $SQLVER = "SQL2012_ISO"
        }
    If (!(Receive-LABSysCtrInstallers -SC_Version $SC_Version -Component SCVMM -Destination $Sourcedir -unzip -WarningAction SilentlyContinue))
        {
        Write-Warning " ==>we could not receive scvmm"
        return
        }
    }# end SCOMPREREQ
############## SCOM  download section
if ($SCOM.IsPresent)
  {
    Write-Host -ForegroundColor Gray " ==>Entering SCOM Prereq Section"
    [switch]$SQL=$true
    $Prereqdir = "prereq"
    if ($SC_Version -match "2012")
        {
        $SQLVER = "SQL2012SP2"
        }
    If (!(Receive-LABSysCtrInstallers -SC_Version $SC_Version -Component SCOM -Destination $Sourcedir -unzip -WarningAction SilentlyContinue))
        {
        Write-Warning " ==>we could not receive scom"
        return
        }
    }# end SCOMPREREQ
############## SCVMM download section
#######
#################
if ($SQL.IsPresent -or $AlwaysOn.IsPresent)
    {
    If ($SQLVER -match 'SQL2016')
        {
        $Java8_required = $true
        }
    $AAGURL = "https://labbuildrmaster.blob.core.windows.net/addons/AdventureWorks2012.7z"
    $URL = $AAGURL
    $FileName = Split-Path -Leaf -Path $Url
	$Aworks_Dir = Join-Path $Sourcedir $AAGDB
	$Aworks_File = Join-Path $Aworks_Dir $FileName
	$Aworks_BAK = Join-Path $Aworks_Dir "AdventureWorks2012.bak"
	If (Test-Path $Aworks_Dir)
		{
		Write-Verbose "we got $Aworks_Dir"
		}
	else
		{
		New-Item -ItemType Directory $Aworks_Dir -Force | Out-Null
		}
    Write-Host "Testing $FileName in $Aworks_Dir"

    if (!(test-path $Aworks_BAK))
        {
        Write-Verbose "Trying Download"
        if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Aworks_File))
            {
            Write-Warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        #New-Item -ItemType Directory -Path "$Aworks_Dir" -Force
        Expand-LABpackage -Archive $Aworks_File -destination $Aworks_Dir
        }
    if (!($SQL_OK = receive-labsql -SQLVER $SQLVER -Destination $Sourcedir -Product_Dir "SQL" -extract -WarningAction SilentlyContinue))
        {
        break
        }
}
if ($Panorama.IsPresent)
    {
    $Targetir = "$Sourcedir/panorama"
    if (Test-Path "$Sourcedir/panorama/Syncplicity Panorama.msi")
        {
        Write-Host -ForegroundColor Gray " ==>Syncplicity found"
        }
    else
        {
        Write-Host -ForegroundColor Gray " ==>we need to get Panorama trying Automated Download"
        $url = "https://download.syncplicity.com/panorama-connector/Syncplicity Panorama.msi"
        if ($url)
            {
            $FileName = Split-Path -Leaf -Path $Url
            get-prereq -DownLoadUrl $url -destination "$Sourcedir/panorama/$FileName"
            }
        }
     }
############## networker dowwnload section
if ($NWServer.IsPresent -or $NMM.IsPresent -or $NW.IsPresent)
    {
    if ((Test-Path "$NW_Sourcedir/$nw_ver/win_x64/networkr/networker.msi") -or (Test-Path "$NW_Sourcedir/$nw_ver/win_x64/networkr/lgtoclnt-*.exe"))
        {
        Write-Host -ForegroundColor Gray " ==>Networker $nw_ver found"
        }
    else #if ($nw_ver -lt "nw84")
        {
        Write-Host -ForegroundColor Gray " ==>we need to get $NW_ver, trying Automated Download"
        $NW_download_ok  =  receive-LABNetworker -nw_ver $nw_ver -arch win_x64 -Destination $NW_Sourcedir -unzip # $CommonParameter
        if ($NW_download_ok)
            {
            Write-Host -ForegroundColor Magenta "Received $nw_ver"
            }
        else
            {
            Write-Warning " ==>we can only autodownload Cumulative Updates from ftp, please get $nw_ver from support.emc.com"
            break
            }
      } #end elseif
}
if ($NMM.IsPresent)
    {
    if ((Test-Path "$NW_Sourcedir/$nmm_ver/win_x64/networkr/NetWorker Module for Microsoft.msi") -or (Test-Path "$NW_Sourcedir/$nmm_ver/win_x64/networkr/NWVSS.exe"))
        {
        Write-Host -ForegroundColor Gray  " ==>Networker NMM $nmm_ver found"
        }
    else
        {
        Write-Host -ForegroundColor Gray " ==>we need to get $NMM_ver, trying Automated Download"
        $Nmm_download_ok  =  receive-LABnmm -nmm_ver $nmm_ver -Destination $NW_Sourcedir -unzip # $CommonParameterReceive-LABnmm -
      }
    }
####SACELIO Downloader #####
if ($ScaleIO.IsPresent)
    {
    $Java8_required = $true
    ##
    # ScaleIO_1.32_Complete_Windows_SW_Download\ScaleIO_1.32_Windows_Download #
    Write-Verbose "Now Checking for ScaleIO $ScaleIOVer"
    $ScaleIO_Major = $ScaleIOVer[0]
    $ScaleIORoot = join-path $Sourcedir "Scaleio\"
    $ScaleIOPath = (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*mdm-$ScaleIOVer.msi" -ErrorAction SilentlyContinue ).Directory.FullName
    try
        {
        Test-Path $ScaleIOPath | Out-Null
        }
    catch
        {
        Write-Host -ForegroundColor Gray " ==>we did not find ScaleIO $ScaleIOVer, we will check local zip/try to download latest version!"
        Receive-LABScaleIO -Destination $Sourcedir -arch Windows -unzip -Confirm:$false -force
        }
        if ($ScaleIO_Major -ge 2)
            {
            Write-Host -ForegroundColor Magenta "Checking for OpenSSL"
			try
				{
				$OpenSSL = Receive-LABOpenSSL -Destination $Sourcedir -OpenSSL_Ver 1_0_1 -ErrorAction Stop
				}
			catch
				{
				Write-Warning "could not retrieve OpenSSL"
				exit
				}
            }
        Write-Verbose "Checking Diskspeed"
        $URL = "https://gallery.technet.microsoft.com/DiskSpd-a-robust-storage-6cd2f223/file/132882/1/Diskspd-v2.0.15.zip"
        $FileName = Split-Path -Leaf -Path $Url
        $Zipfilename = Join-Path $Sourcedir $FileName
        $Destinationdir = Join-Path "$Sourcedir" "diskspd"
        # $Directory = Split-Path
        if (!(test-path  (join-path "$Sourcedir" "\diskspd\amd64fre\diskspd.exe")))
        {
        ## Test if we already have the ZIP
        if (!(test-path  "$Zipfilename"))
            {
            Write-Verbose "Trying Download DiskSpeed"
            if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir"))
                {
                    Write-Warning "Error Downloading file $Url, Please check connectivity"
                        exit
                }
            }
        Extract-Zip -zipfilename $Zipfilename -destination $Destination
    }# end DiskSpeed
} #end ScaleIO
##### puppet stuff
############
if ($LabDefaults.Puppet)
    {
    If ($LabDefaults.Puppetmaster -match "Enterprise")
    {
        $Puppetmaster  = "PuppetENMaster1"
    }
else
    {
    $Puppetmaster  = "PuppetMaster1"
    }
Write-Verbose "Pupppetmaster will be $Puppetmaster"
}
if ($nw.IsPresent -and !$NoDomainCheck.IsPresent) { Write-Host -ForegroundColor Magenta " ==>Networker $nw_ver Node will be installed" }
write-verbose "Checking Environment"
if ($NW.IsPresent -or $NWServer.IsPresent)
{
    if (!$Scenarioname)
        {
        $Scenarioname = "nwserver"
        $Scenario = 8
        }
	Receive-LABAcrobat -Destination $Sourcedir
    $Java7_required = $True
    #####
If ($nw_ver -gt "nw85.BR1")
            {
            $Java8_required = $true
            $Java7_required = $false
            if ($LatestJava7)
                {
                $LatestJava = $LatestJava7
                }
            if ($LatestJava8)
                {
                $LatestJava = $LatestJava8
                }
            }
}
#end $nw
if ($Java7_required)
    {
    Write-Verbose "Checking for Java 7"
    if (!($Java7 = Get-ChildItem -Path $Sourcedir -Filter 'jre-7*x64*'))
	    {
		Write-Host -ForegroundColor Yellow "Java7 not found, downloading from $my_repo repo"
        $FileName = Split-Path -Leaf $Java7_Url
        $Destination = Join-Path $Sourcedir $FileName
        Receive-LABBitsFile -DownLoadUrl $Java7_Url -destination $Destination
        $Java7 = Get-ChildItem -Path $Sourcedir -Filter 'jre-7*x64*'
        }
    $Java7 = $Java7 | Sort-Object -Property Name -Descending
    $LatestJava = $Java7[0].Name
    }
If ($Java8_required)
    {
    Write-Verbose "Checking for Java 8"
    if (!($Java8 = Get-ChildItem -Path $Sourcedir -Filter 'jre-8*x64*'))
        {
	    Write-Host -ForegroundColor Gray " ==>Java8 not found, trying download"
        Write-Verbose "Asking for latest Java8"
        $LatestJava = (receive-labjava64 -DownloadDir $Sourcedir).LatestJava8
        if (!$LatestJava)
            {
            break
            }
	    }
    else
        {
        $Java8 = $Java8 | Sort-Object -Property Name -Descending
	    $LatestJava = $Java8[0].Name
        Write-Verbose "Got $LatestJava"
        }
    }
if ($Dockerhost.IsPresent)
	{
	if ($Master -lt "2016TP5")
		{
		Write-Host " ==>setting Docker Master to $Latest_2016"
		$master = $Latest_2016
		}
	# Receive-LABDocker -Destination $Sourcedir -ver 1.12 -arch win -branch beta
	if ($Size -lt "TXL")
		{$Size = "XXL" }
	}
##end Autodownloaders
##### Master Downloader
$MyMaster = test-labmaster -Masterpath "$Masterpath" -Master $Master -mastertype vmware -Confirm:$Confirm
$MasterVMX = $mymaster.config
Write-Verbose " ==>we got master $MasterVMX"
##########################################
Write-Host -ForegroundColor Magenta " ==>leaving download section"
if ($Work_Items)
	{ 
	Write-Host -ForegroundColor Magenta $Work_Items
	}
if (!($SourceOK = test-source -SourceVer $Sourcever -SourceDir $Sourcedir))
{
	Write-Verbose "Sourcecomplete: $SourceOK"
	break
}
if ($DefaultGateway) {$AddGateway  = "-DefaultGateway $DefaultGateway"}
If ($VMnet -ne "VMnet2") { debug "setting different Network is untested and own Risk !" }
if (!$NoDomainCheck.IsPresent){
####################################################################
# DC Validation
$Nodename = $DCNODE
$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
if ($Nodeclone = get-vmx $DCNODE -WarningAction SilentlyContinue)
{
	Write-Host -ForegroundColor White  " ==>Domaincontroller already deployed, Comparing Workorder Parameters with Running Environment"
	test-dcrunning
    if ( $AddressFamily -match 'IPv4' )
        {
	    test-user -whois Administrator
	    write-verbose "Verifiying Domainsetup"
        $EnableFolders = get-vmx -path $DCNODE | Set-VMXSharedFolderState -enabled
	    $Checkdom = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\$DCNODE" -Script checkdom.ps1 # $CommonParameter
	    $BuildDomain, $RunningIP, $VMnet, $MyGateway = test-domainsetup
	    $IPv4Subnet = convert-iptosubnet $RunningIP
	    $Work_Items +=  " ==>will Use Domain $BuildDomain and Subnet $IPv4Subnet.0 for on $VMnet the Running Workorder"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        If ($MyGateway)
            {
            $Work_Items +=  " ==>we will configure Default Gateway at $MyGateway"
            $AddGateway  = "-DefaultGateway $MyGateway"
            Write-Verbose -Message " ==>we will add a Gateway with $AddGateway"
            }
    else
        {
        write-verbose " no domain check on IPv6only"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        }
    }
}#end test-domain
else
{
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
	###################################################
	# Part 1, Definition of Domain Controller
	###################################################
	#$Nodename = $DCNODE
	$DCName = $BuildDomain + "DC"
	#$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
	$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$DCNODE"
	###################################################
	Write-Verbose "IPv4Subnet :$IPv4Subnet"
    Write-Verbose "IPV6Prefix :$IPv6Prefix"
    Write-Verbose "IPv6Prefixlength : $IPv6PrefixLength"
    write-verbose "DCName : $DCName"
    Write-Verbose "Domainsuffix : $custom_domainsuffix"
    Write-Verbose "Domain : $BuildDomain"
    Write-Verbose "AddressFamily : $AddressFamily"
    Write-Verbose "DefaultGateway : $DefaultGateway"
    Write-Verbose "DNS1 : $DNS1"
    If ($DefaultGateway.IsPresent)
        {
        Write-Verbose "Gateway : $DefaultGateway"
        }
	Write-Host -ForegroundColor Magenta " ==>we will Build Domain $BuildDomain and Subnet $IPv4subnet.0  on $VMnet for the Running Workorder"
    Write-Host -ForegroundColor Magenta " ==>setting Language to $LanguageTag"
    if ($DefaultGateway){ Write-Host -ForegroundColor Magenta " ==>The Gateway will be $DefaultGateway"}
	if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        {
        Write-Verbose "Press any key to Continue Cloning"
        Pause
        }
    Set-LABDNS1 -DNS1 "$IPv4Subnet.10"
	$CloneOK = Invoke-Expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 0 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Size 'L' -Sourcedir $Sourcedir"
	###################################################
	#
	# DC Setup
	#
	###################################################
	if ($CloneOK)
		{
		$NodeClone = Get-VMX -Path $CloneVMX
		test-user -whois Administrator
		Write-Verbose $IN_Guest_UNC_ScenarioScriptDir
        $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script new-dc.ps1 -Parameter "-dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix  -AddressFamily $AddressFamily $AddGateway $CommonParameter" -interactive -nowait
        Write-Host -ForegroundColor White  " ==>preparing Domain " -NoNewline
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            write-verbose "verbose enabled, Please press any key within VM $Dcname"
            While ($FileOK = (&$vmrun -gu Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\2.pass) -ne "The file exists.")
				{
				foreach ($i in (1..$sleep))
					{
					Write-Host -ForegroundColor Yellow "-`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "\`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "|`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "/`b" -NoNewline
					sleep 1
					}
				}
            }
        else
            {
			$Sleep = 1
		    While (!($Nodeclone | Test-VMXFileInGuest -Guestuser $Adminuser -Guestpassword $Adminpassword -Filename c:\scripts\2.pass))
				{
				foreach ($i in (1..$sleep))
					{
					Write-Host -ForegroundColor Yellow "-`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "\`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "|`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "/`b" -NoNewline
					sleep 1
					}
				}
			}
        Write-Host -ForegroundColor Green "[success]"
        test-user -whois Administrator
        if ($Toolsupdate.IsPresent)
            {
            Write-Host -ForegroundColor Gray " ==>preparing VMware Tools Upgrade by injecting tools CD ( update will start before next reboot of VM )"
            Start-Process $Global:vmrun -ArgumentList  "installTools $CloneVMX" -NoNewWindow
            }
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-domain.ps1 -Parameter "-domain $BuildDomain -domainsuffix $custom_domainsuffix $CommonParameter" -nowait -interactive 
		Write-Host -ForegroundColor White  " ==>creating Domain $BuildDomain " -NoNewline
		While (!($Nodeclone | Test-VMXFileInGuest -Guestuser $Adminuser -Guestpassword $Adminpassword -Filename c:\scripts\3.pass))
                {
				foreach ($i in (1..$sleep))
					{
					Write-Host -ForegroundColor Yellow "-`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "\`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "|`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "/`b" -NoNewline
					sleep 1
					}
			}
		write-host -ForegroundColor Green "[finished]"
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script dns.ps1 -Parameter "-IPv4subnet $IPv4Subnet -IPv4Prefixlength $IPV4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily  -IPV6Prefix $IPV6Prefix $AddGateway $CommonParameter"  -interactive
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script add-serviceuser.ps1 -interactive
	    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-labshortcut.ps1 -interactive # -Parameter $CommonParameter
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir  -Script pwpolicy.ps1 -interactive
        $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script set-winrm.ps1 -interactive
        if ($NW.IsPresent)
            {
		    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
            }
        invoke-postsection
		# run-vmpowershell -Script gpo.ps1 -interactive
		# GPO on freetype domain ? Exchange Powershell Issues ?
	} #DC node End
}#end else createdc
####################################################################
### Scenario Deployment Begins .....                           #####
####################################################################
}
#### Is AlwaysOn Needed ?
If ($AlwaysOn.IsPresent -or $PsCmdlet.ParameterSetName -match "AAG")
{
		# we need a DC, so check it is running
		test-dcrunning
        $ListenerIP = "$IPv4Subnet.169"
        $IN_Guest_UNC_ScenarioScriptDir = Join-Path $IN_Guest_UNC_Scriptroot "AAG"
        $In_Guest_UNC_SQLScriptDir = Join-Path $IN_Guest_UNC_Scriptroot "SQL"
        $AAGName = $BuildDomain+"AAG"
        If ($AddressFamily -match 'IPv6')
            {
            $ListenerIP = "$IPV6Prefix$ListenerIP"
            } # end addressfamily
		$AAGLIST = @()
		foreach ($AAGNode in (1..$AAGNodes))
		{
			###################################################
			# Setup of a AlwaysOn Node
			# Init
			$Nodeip = "$IPv4Subnet.16$AAGNode"
			$Nodename = "AAGNODE" + $AAGNODE
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
			$AAGLIST += $CloneVMX
            #$In_Guest_UNC_SQLScriptDir = "$Default_Host_ScriptDir\sql\"
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, Failover-Clustering, RSAT-Clustering, WVR"
            ###################################################
			Write-Verbose $IPv4Subnet
            write-verbose $Nodeip
            Write-Verbose $Nodename
            Write-Verbose $ListenerIP
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            Write-verbose "Now Pausing"
            pause
            }
			# Clone Base Machine
			$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $AAGNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $SQLSize -Sourcedir $Sourcedir -sql"
			###################################################
			If ($CloneOK)
			{
		$NodeClone = Get-VMX -Path $CloneVMX
				test-user -whois Administrator
			    domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                invoke-postsection -wait
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1 -interactive
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SQLScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -reboot" -interactive -nowait
                $SQLSetupStart = Get-Date
			}
		} ## end foreach AAGNODE
		If ($CloneOK)
		{
			# $NodeClone = Get-VMX -Path $CloneVMX
			###### Check for all SQl Setups Done .. ####
			Write-Host -ForegroundColor Magenta " ==>Checking SQL INSTALLED and Rebooted on All Machines"
			foreach ($CloneVMX in $AAGLIST)
			    {
                Write-Host "Testing $CloneVMX"
                $NodeClone = Get-VMX -Path $CloneVMX
				While ($FileOK = (&$vmrun -gu $builddomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\sql.pass) -ne "The file exists.")
				    {
				    runtime $SQLSetupStart "$SQLVER $Nodename "
				    }
                $script_invoke = $nodeclone | invoke-vmxpowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$IN_Guest_UNC_Scriptroot\SQL" -Script set-sqlroles.ps1 -interactive
			    } # end aaglist
			$NodeClone = Get-VMX -Path $CloneVMX
	        $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix 'AAGNODE' -IPAddress '$IPv4Subnet.160' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script enable-aag.ps1 -interactive
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-aag.ps1 -interactive -Parameter "-Nodeprefix 'AAGNODE' -AgName '$AAGName' -DatabaseList 'AdventureWorks2012' -BackupShare '\\vmware-host\Shared Folders\Sources\AWORKS' -IPv4Subnet $IPv4Subnet -IPV6Prefix $IPV6Prefix -AddressFamily $AddressFamily $CommonParameter"
            foreach ($CloneVMX in $AAGLIST)
            {
			$NodeClone = Get-VMX -Path $CloneVMX
                if ($NMM.IsPresent)
                    {
				    Write-Host -ForegroundColor White  " ==>Installing Networker $nmm_ver an NMM $nmm_ver on all Nodes"
					Write-Host -ForegroundColor White  $CloneVMX
					$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
					$script_invoke = $NodeClone | Invoke-VMXPowershell -ScriptPath "$IN_Guest_UNC_Scriptroot\SQL" -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver" -Guestuser $Adminuser -Guestpassword $Adminpassword
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-aag.ps1 -interactive -nowait
					} # end !NMM
				else
                    {
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-aag.ps1 -interactive -nowait
                    }# end else nmm
				}
           #
			Write-Host -ForegroundColor White  "Done"
		}# end cloneok
	} # End Switchblock AAG
switch ($PsCmdlet.ParameterSetName)
{
"E14"{
        $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$EX_Version"
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, Server-Media-Foundation"
        $AddonFeatures = "$AddonFeatures, NET-Framework-Features,NET-HTTP-Activation,RPC-over-HTTP-proxy,RSAT-Clustering,Web-Mgmt-Console,WAS-Process-Model,Web-Asp-Net,Web-Basic-Auth,Web-Client-Auth,Web-Digest-Auth,Web-Dir-Browsing,Web-Dyn-Compression,Web-Http-Errors,Web-Http-Logging,Web-Http-Redirect,Web-Http-Tracing,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Lgcy-Mgmt-Console,Web-Metabase,Web-Net-Ext,Web-Request-Monitor,Web-Server,Web-Static-Content,Web-Windows-Auth,Web-WMI"
        # we need ipv4
        if ($AddressFamily -notmatch 'ipv4')
            {
            $EXAddressFamiliy = 'IPv4IPv6'
            }
        else
        {
        $EXAddressFamiliy = $AddressFamily
        }
        if ($DAG.IsPresent)
            {
            $AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering"
            if ($DAGNOIP.IsPresent)
			    {
				$DAGIP = ([System.Net.IPAddress])::None
			    }
			else
                {
                $DAGIP = "$IPv4subnet.110"
                }
        }
		foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
			###################################################
			# Setup e14 Node
			# Init
			$Nodeip = "$IPv4Subnet.12$EXNODE"
			$Nodename = "$EX_Version"+"N"+"$EXNODE"
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
			$EXLIST += $CloneVMX
			###################################################
            Write-Verbose $IPv4Subnet
            Write-Verbose "IPv4PrefixLength = $IPv4PrefixLength"
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose "IPv6Prefix = $IPV6Prefix"
            Write-Verbose "IPv6PrefixLength = $IPv6PrefixLength"
            Write-Verbose "Addressfamily = $AddressFamily"
            Write-Verbose "EXAddressFamiliy = $EXAddressFamiliy"
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
            $Exchangesize = "XXL"
		    test-dcrunning
		    $CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $EXNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -AddDisks -Disks 3 -Disksize 500GB -Size $Exchangesize -Sourcedir $Sourcedir "
		    ###################################################
		    If ($CloneOK)
                {
				$NodeClone = Get-VMX -Path $CloneVMX
                $EXnew = $True
			    test-user -whois Administrator
			    domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $EXAddressFamiliy -AddOnfeatures $AddonFeatures
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchangeprereqs.ps1 -interactive -Parameter "-ex_lang $e14_lang"
                checkpoint-progress -step exprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script powerconf.ps1 -interactive
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchange.ps1 -interactive -nowait -Parameter "$CommonParameter -e14_sp $e14_sp -e14_ur $e14_ur -ex_lang $e14_lang"
                }
            }
        if ($EXnew)
        {
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
			  $NodeClone = Get-VMX $Nodename
            $CloneVMX = $Nodeclone.config
            #
			test-user -whois Administrator
            Write-Host -ForegroundColor White  " ==>waiting for Pass 4 ($EX_Version Installed) for $Nodename "
            #$EXSetupStart = Get-Date
			While ($FileOK = (&$vmrun -gu $BuildDomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX "$IN_Guest_LogDir\exchange.pass") -ne "The file exists.")
				{
				sleep $Sleep
				} #end while
			Write-Host
            do {
                $ToolState = Get-VMXToolsState -config $CloneVMX
                Write-Verbose $ToolState.State
                }
            until ($ToolState.state -match "running")
    		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-exchange.ps1 -interactive -Parameter "$CommonParameter -e14_sp $e14_sp -e14_ur $e14_ur -ex_lang $e14_lang"
            if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
                {
                if ($DAG.IsPresent)
                    {
				    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version $CommonParameter"
				    } # end if $DAG
                if (!($nouser.ispresent))
                    {
	                do
				        {
                        ($cmdresult = &$vmrun -gu "$BuildDomain\Administrator" -gp Password123! runPrograminGuest  $CloneVMX -activeWindow -interactive c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ". 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; . '$IN_Guest_UNC_ScenarioScriptDir\User.ps1' -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter")
					    if ($BugTest) { debug $Cmdresult }
				        }
				    until ($VMrunErrorCondition -notcontains $cmdresult)
                    } #end creatuser
            }# end if last server
       }
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
			  $NodeClone = Get-VMX $Nodename
            $CloneVMX = $Nodeclone.config
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-security.ps1 -interactive
			########### Entering networker Section ##############
			if ($NMM.IsPresent)
			{
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver"
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-nmm.ps1 -interactive
            }# end nmm
			########### leaving NMM Section ###################
		    invoke-postsection
    }#end foreach exnode
        }
} #End Switchblock Exchange
"E15"
	{
    $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
    $AddonFeatures = "$AddonFeatures, RSAT-DNS-SERVER, Desktop-Experience, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation"
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\E2013"
    # we need ipv4
    if ($AddressFamily -notmatch 'ipv4')
        {
        $EXAddressFamiliy = 'IPv4IPv6'
        }
    else
    {
    $EXAddressFamiliy = $AddressFamily
    }
    if ($DAG.IsPresent)
        {
        $AddonFeatures = "$AddonFeatures, Failover-Clustering"
        if ($DAGNOIP.IsPresent)
			{
			$DAGIP = ([System.Net.IPAddress])::None
			}
		else
            {
            $DAGIP = "$IPv4subnet.110"
            }
    }
	foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
        {
		###################################################
		# Setup E15 Node
		# Init
		$Nodeip = "$IPv4Subnet.11$EXNODE"
		$Nodename = "$EX_Version"+"N"+"$EXNODE"
		$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
		$EXLIST += $CloneVMX
		# $Exprereqdir = "$Sourcedir\EXPREREQ\"
		###################################################
        Write-Verbose $IPv4Subnet
        Write-Verbose "IPv4PrefixLength = $IPv4PrefixLength"
        write-verbose $Nodename
        write-verbose $Nodeip
        Write-Verbose "IPv6Prefix = $IPV6Prefix"
        Write-Verbose "IPv6PrefixLength = $IPv6PrefixLength"
        Write-Verbose "Addressfamily = $AddressFamily"
        Write-Verbose "EXAddressFamiliy = $EXAddressFamiliy"
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            Write-verbose "Now Pausing"
            pause
            }
		test-dcrunning
		$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $EXNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -AddDisks -Disks 3 -Disksize 500GB -Size $Exchangesize -Sourcedir $Sourcedir "
		###################################################
		If ($CloneOK)
        {
		$NodeClone = Get-VMX -Path $CloneVMX
        $EXnew = $True
		test-user -whois Administrator
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $EXAddressFamiliy -AddOnfeatures $AddonFeatures
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchangeprereqs.ps1 -interactive
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script powerconf.ps1 -interactive
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchange.ps1 -interactive -nowait -Parameter "$CommonParameter -ex_cu $e15_cu"
        }
        }
    if ($EXnew)
    {
    foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
        {
        $Nodename = "$EX_Version"+"N"+"$EXNODE"
		$NodeClone = Get-VMX $Nodename
        $CloneVMX = $Nodeclone.config
		test-user -whois Administrator
        Write-Host -ForegroundColor White  " ==>waiting for Pass 4 (E15 Installed) for $Nodename "
        #$EXSetupStart = Get-Date
			While ($FileOK = (&$vmrun -gu $BuildDomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX $IN_Guest_LogDir\exchange.pass) -ne "The file exists.")
			{
				sleep $Sleep
			} #end while
			Write-Host
                do {
                    $ToolState = Get-VMXToolsState -config $CloneVMX
                        Write-Verbose $ToolState.State
                    }
                until ($ToolState.state -match "running")
     	$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-exchange.ps1 -interactive
#  -nowait
        if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
            {
            if ($DAG.IsPresent)
                {
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir  -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy $CommonParameter"
				} # end if $DAG
            if (!($nouser.ispresent))
                {
                Write-Host -ForegroundColor Magenta " ==>creating Accounts and Mailboxes:"
	            do
				    {
					($cmdresult = &$vmrun -gu "$BuildDomain\Administrator" -gp Password123! runPrograminGuest  $CloneVMX -activeWindow -interactive c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; . '$IN_Guest_UNC_ScenarioScriptDir\User.ps1' -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter")
					if ($BugTest) { debug $Cmdresult }
				    }
				until ($VMrunErrorCondition -notcontains $cmdresult)
                } #end creatuser
        }# end if last server
    }
    foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
        {
        $Nodename = "$EX_Version"+"N"+"$EXNODE"
		$NodeClone = Get-VMX -Path $CloneVMX        
		$CloneVMX = $Nodeclone.config
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-security.ps1 -interactive
		########### Entering networker Section ##############
		if ($NMM.IsPresent)
		{
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver"
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-nmm.ps1 -interactive
        }# end nmm
		########### leaving NMM Section ###################
		invoke-postsection
}#end foreach exnode
    }
} #End Switchblock Exchange
"E16"
	{
        $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\E2016"
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
            $AddonFeatures = "$AddonFeatures, RSAT-DNS-Server, AS-HTTP-Activation, Desktop-Experience, NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation"
        # we need ipv4
        if ($AddressFamily -notmatch 'ipv4')
            {
            $EXAddressFamiliy = 'IPv4IPv6'
            }
        else
        {
        $EXAddressFamiliy = $AddressFamily
        }
        if ($DAG.IsPresent)
            {
            $AddonFeatures = "$AddonFeatures, Failover-Clustering"
            if ($DAGNOIP.IsPresent)
			    {
				$DAGIP = ([System.Net.IPAddress])::None
			    }
			else
                {
                $DAGIP = "$IPv4subnet.110"
                }
        }
		foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
			###################################################
			# Setup e16 Node
			# Init
			$Nodeip = "$IPv4Subnet.12$EXNODE"
			$Nodename = "$EX_Version"+"N"+"$EXNODE"
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
			$EXLIST += $CloneVMX
		    # $Exprereqdir = "$Sourcedir\EXPREREQ\"
			###################################################
            Write-Verbose $IPv4Subnet
            Write-Verbose "IPv4PrefixLength = $IPv4PrefixLength"
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose "IPv6Prefix = $IPV6Prefix"
            Write-Verbose "IPv6PrefixLength = $IPv6PrefixLength"
            Write-Verbose "Addressfamily = $AddressFamily"
            Write-Verbose "EXAddressFamiliy = $EXAddressFamiliy"
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
            $Exchangesize = "XXL"
		    test-dcrunning
		    $CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $EXNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -AddDisks -Disks 3 -Disksize 500GB -Size $Exchangesize -Sourcedir $Sourcedir "
		    ###################################################
		    If ($CloneOK)
                {
				$NodeClone = Get-VMX -Path $CloneVMX
                $EXnew = $True
			    test-user -whois Administrator
			    domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $EXAddressFamiliy -AddOnfeatures $AddonFeatures
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchangeprereqs.ps1 -interactive
                checkpoint-progress -step exprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script powerconf.ps1 -interactive
			    Switch ($e16_cu)
                        {
                        "final"
                            {
                            $install_from = "exe"
                            }
                        default
                            {
                            $install_from = "iso"
                            }
                        }
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-exchange.ps1 -interactive -nowait -Parameter "$CommonParameter -ex_cu $e16_cu -install_from $install_from"
                }
            }
        if ($EXnew)
        {
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
			$NodeClone = Get-VMX $Nodename
            $CloneVMX = $Nodeclone.config
			test-user -whois Administrator
            Write-Host -ForegroundColor White  " ==>waiting for Exchange Installed on $Nodename " -NoNewline
            #$EXSetupStart = Get-Date
			$Sleep = 2
			    While ($FileOK = (&$vmrun -gu $BuildDomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX "$IN_Guest_LogDir\exchange.pass") -ne "The file exists.")
			    {
				foreach ($i in (1..$sleep))
					{
					Write-Host -ForegroundColor Yellow "-`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "\`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "|`b" -NoNewline
					sleep 1
					Write-Host -ForegroundColor Yellow "/`b" -NoNewline
					sleep 1
					}
				} #end while
                Write-Host -ForegroundColor Green "[finished]"
				do 
					{
                    $ToolState = Get-VMXToolsState -config $CloneVMX
                    Write-Verbose $ToolState.State
                    }
                until ($ToolState.state -match "running")
    		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-exchange.ps1 -interactive
            if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
                {
                if ($DAG.IsPresent)
                    {
				    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version $CommonParameter"
				    } # end if $DAG
                if (!($nouser.ispresent))
                    {
                    Write-Host -ForegroundColor Magenta " ==>creating Accounts and Mailboxes:"
	                do
				        {
						 #$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "'C:\Program Files\Microsoft\Exchange Server\V15\bin\'" -script "RemoteExchange.ps1;Connect-ExchangeServer -auto; . '$IN_Guest_UNC_ScenarioScriptDir\User.ps1' -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter"
                        ($cmdresult = &$vmrun -gu "$BuildDomain\Administrator" -gp Password123! runPrograminGuest  $CloneVMX -activeWindow -interactive c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; . '$IN_Guest_UNC_ScenarioScriptDir\User.ps1' -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter")
					    if ($BugTest) { debug $Cmdresult }
				        }
				    until ($VMrunErrorCondition -notcontains $cmdresult)
                    } #end creatuser
            }# end if last server
       }
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
			$NodeClone = Get-VMX $Nodename
            $CloneVMX = $Nodeclone.config
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-security.ps1 -interactive
			########### Entering networker Section ##############
			if ($NMM.IsPresent)
			{
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver"
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-nmm.ps1 -interactive
            }# end nmm
			########### leaving NMM Section ###################
		    invoke-postsection
    }#end foreach exnode
        }
} #End Switchblock Exchange
##### Hyper-V Block #####
	"HyperV"
    {
        [int]$Base_IP = 150
        switch ($Clusternum)
            {
            1
                {
                [int]$ipoffset = 0
                [int]$Firstnode = 1
                [int]$IPNum = $Base_IP + $ipoffset
                $ClusterIP = "$IPv4Subnet.$IPNum"
                }
            2
                {
                [int]$ipoffset = 5
                [int]$Firstnode = 1
                [int]$IPNum = $Base_IP + $ipoffset
                $ClusterIP = "$IPv4Subnet.$IPNum"
                }
            }
        Write-Verbose "Clusterip = $ClusterIP"
        #$Firstnode = "1" #for later use
        #$Clusternum = "1" # for later use
        $Clusterprefix = "HV$Clusternum"
        #$LASTVMX = "HVNODE$HyperVNodes"
        $FirstVMX =  "$($Clusterprefix)NODE$Firstnode"
		$HVLIST = @()
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, Hyper-V, Hyper-V-Tools, Hyper-V-PowerShell, WindowsStorageManagementService"
		if ($ScaleIO.IsPresent)
            {
            if (!$Cluster.IsPresent)
                {
                Write-Host -ForegroundColor Magenta " ==>we want a Cluster for Automated SCALEIO Deployment, adjusting"
                [switch]$Cluster = $true
                }
            If (!$Disks){$Disks = 1}
            $cloneparm = " -AddDisks -disks $Disks"
            if ("XXL" -notmatch $Size)
                {
                Write-Host -ForegroundColor Gray " ==>we adjust size to XL Machine to make ScaleIO RUN"
                $Size = "XL"
                }
            If ($Computersize -le "2" -and !$Scaleiowarn )
                {
                Write-Host -ForegroundColor Gray " ==>Your Computer is at low Memory For ScaleIO Scenario"
                Write-Host -ForegroundColor Gray " ==>Insufficient memory might cause MDM Setup to fail"
                Write-Host -ForegroundColor Gray " ==>machines with < 16GB might not be able to run the Scenario"
                Write-Host -ForegroundColor Gray " ==>Please make sure to close all desktop Apps"
                pause
                $Scaleiowarn = $true
                }
            }
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, WVR"}
        If (!(get-vmx "$($Clusterprefix)Node*" -WarningAction SilentlyContinue))
            {
            $newdeploy = $true
            Write-Host -ForegroundColor Magenta " ==>This is a Hyper-v Newdepoly"
            }
        else
            {
            Write-Host -ForegroundColor Gray " ==>Node1 Already Deployed, no autoconfig is done"
            }
        foreach ($HVNODE in ($Firstnode..$HyperVNodes))
		{
			if ($HVNODE -eq $HyperVNodes -and $SCVMM.IsPresent)
            {
            $LastNode = $True
            if ("XL" -notmatch $Size)
                {
                $Size = "TXL"
                }
            }
			###################################################
			# Hyper-V  Node Setup
			# Init
            [int]$IPNum = $Base_IP+$ipoffset+$HVNODE
			$Nodeip = "$IPv4Subnet.$IPNum"
            Write-Verbose "Nodeip = $Nodeip"
			$Nodename = "$($Clusterprefix)NODE$($HVNode)"
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
			$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\HyperV\"
            $In_Guest_UNC_SQLScriptDir = "$IN_Guest_UNC_Scriptroot\sql\"
            $In_Guest_UNC_SCVMMScriptDir = "$IN_Guest_UNC_Scriptroot\scvmm\"
            Write-Verbose "IPv4 Subnet = $IPv4Subnet"
            Write-Verbose $Nodename
            Write-Verbose $AddonFeatures
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
			###################################################
			# Clone BAse Machine
			# Write-Host -ForegroundColor White  "Hyper-V Development is still not finished and untested, be careful"
			test-dcrunning
			$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $HVNode -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir $cloneparm"
			###################################################
            If ($CloneOK)
			    {
				$NodeClone = Get-VMX -Path $CloneVMX
				test-user -whois Administrator
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
				test-user Administrator
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-hyperv.ps1 -interactive
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script set-winrm.ps1 -interactive
                if ($ScaleIO.IsPresent)
                    {
                    $SIO_ProtectionDomainName = "PD_$Clusterprefix"
                    $SIO_StoragePoolName = "SP_$Clusterprefix"
                    $SIO_SystemName = "ScaleIO@$Clusterprefix"
                    if ($singlemdm.IsPresent)
                        {
                        [int]$IPNum = $Base_IP + $ipoffset + 1
                        $mdmipa = "$IPv4Subnet.$IPNum"
                        $mdmipb = "$IPv4Subnet.$IPNum"
                        }
                    else
                        {
                        [int]$IPNum = $Base_IP + $ipoffset + 1
                        $mdmipa = "$IPv4Subnet.$IPNum"
                        [int]$IPNum = $Base_IP + $ipoffset + 2
                        $mdmipb = "$IPv4Subnet.$IPNum"
                        }
                    switch ($HVNODE)
                        {
                        1
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1  -Parameter "-openssl_ver $($OpenSSL.Version)" -interactive
                                }
                            $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role MDM -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                            }
                        2
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1  -Parameter "-openssl_ver $($OpenSSL.Version)" -interactive
                                }
                            if (!$singlemdm.IsPresent)
                                {
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role MDM -disks $Disks -ScaleIOVer $ScaleIOVer  -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                                }
                            else
                                {
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer  -mdmipa $mdmipa -mdmipb $mdmipa" -interactive
                                }
                            }
                        3
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1  -Parameter "-openssl_ver $($OpenSSL.Version)" -interactive
                                }
                            if (!$singlemdm.IsPresent)
                                {
                                switch ($scaleio_major)
                                    {
                                    1
                                        {
                                        $script_invoke = $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role TB -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                                        }
                                    2
                                        {
                                        $script_invoke = $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role TB -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                                        }
                                    }
                                }
                            else
                                {
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipa" -interactive
                                }
                            Write-Host -ForegroundColor Magenta "generating SIO Config File"
                            Set-LABSIOConfig -mdm_ipa $mdmipa -mdm_ipb $mdmipb -gateway_ip "$IPv4Subnet.153" -system_name $SIO_SystemName -pool_name $SIO_StoragePoolName -pd_name $SIO_ProtectionDomainName
                            Write-Host -ForegroundColor Gray " ==>installing JAVA"
		                    $Parm = "/s"
		                    $Execute = "\\vmware-host\Shared Folders\Sources\$LatestJava"
		                    do
		                        {
			                    ($cmdresult = &$vmrun -gu Administrator -gp Password123! runPrograminGuest  $CloneVMX -activeWindow  $Execute $Parm) 2>&1 | Out-Null
		                        }
		                    until ($VMrunErrorCondition -notcontains $cmdresult)
                            $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role gateway -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                            }
                        default
                            {
                            if ($ScaleIO_Major -ge 2)
                                {
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-openssl.ps1 -Parameter "-openssl_ver $($OpenSSL.Version)" -interactive
                                }
                                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-scaleio.ps1 -Parameter "-Role SDS -disks $Disks -ScaleIOVer $ScaleIOVer -mdmipa $mdmipa -mdmipb $mdmipb" -interactive
                            }
                        }
                    }
	            if ($NMM.IsPresent)
		            {
			        $script_invoke = $NodeClone | Invoke-VMXPowershell -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver" -Guestuser $Adminuser -Guestpassword $Adminpassword
                    $NMM_Parameter = "-nmm_ver $nmm_ver"
                    If ($SCVMM.IsPresent -and $LastNode)
                        {
                        $NMM_Parameter = "$NMM_Parameter -scvmm"
                        }
			        $script_invoke = $NodeClone | Invoke-VMXPowershell -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter $NMM_Parameter -Guestuser $Adminuser -Guestpassword $Adminpassword
		            }# End Nmm
            invoke-postsection -wait
            } # end Clone OK
		} # end HV foreach
		########### leaving NMM Section ###################
    If ($newdeploy)
        {
        Write-Host -ForegroundColor Magenta " ==>Trying New Cluster Deployment for $Clusterprefix!! "
        if ($Cluster.IsPresent)
		{
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix '$Clusterprefix' -IPAddress '$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
			Write-Host -ForegroundColor Gray " ==>setting up Hyper-V Replica Broker"
            $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script new-hypervreplicabroker.ps1 -interactive
        }
	    if ($ScaleIO.IsPresent)
            {
            Write-Host -ForegroundColor Gray " ==>configuring mdm"
            if ($singlemdm.IsPresent)
                    {
                    $script_invoke = get-vmx $FirstVMX | invoke-vmxpowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-mdm.ps1 -Parameter "-IPv4Subnet $IPv4Subnet -singlemdm -CSVnum 3 -ScaleIO_Major $ScaleIO_Major"-interactive
                    }
            else
                    {
                    $script_invoke = get-vmx $FirstVMX | invoke-vmxpowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-mdm.ps1 -Parameter "-IPv4Subnet $IPv4Subnet -CSVnum 3 -ScaleIO_Major $ScaleIO_Major" -interactive
                    }
            }
		if ($SCVMM.IsPresent)
		    {
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SQLScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -DefaultDBpath $CommonParameter" -interactive
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script install-vmmprereq.ps1 -Parameter "-sc_version $SC_Version $CommonParameter"  -interactive
            checkpoint-progress -step vmmprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script install-vmm.ps1 -Parameter "-sc_version $SC_Version $CommonParameter" -interactive
            if ($ConfigureVMM.IsPresent)
                {
			    Write-Host -ForegroundColor Gray " ==>Configuring VMM"
                if ($Cluster.IsPresent)
                    {
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script configure-vmm.ps1 -Parameter "-Cluster" -interactive
                    }
                    else
                    {
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SCVMMScriptDir -Script configure-vmm.ps1 -interactive
                    }
                }
            } #end SCVMM
        }#end newdeploy
	} # End Switchblock hyperv
###### new SOFS Block
	"SOFS" {
        $AddonFeatures = "File-Services, RSAT-File-Services, RSAT-ADDS, RSAT-ADDS-TOOLS, Failover-Clustering, RSAT-Clustering, WVR"
		foreach ($Node in ($SOFSSTART..$SOFSNODES))
		{
			###################################################
			# Setup of a SOFS Node
			# Init
			$Nodeip = "$IPv4Subnet.21$Node"
			$Nodename = "SOFSNode$Node"
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
			$Host_ScriptDir = "$Default_Host_ScriptDir\SOFS\"
            $Size = "XL"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose $Size
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
			test-dcrunning
			# Clone Base Machine
			$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir "
			###################################################
			If ($CloneOK)
				{
				$NodeClone = Get-VMX -Path $CloneVMX
				test-user -whois Administrator
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
				invoke-postsection -wait
			}# end Cloneok
		} # end foreach
		# if ($Cluster)
		# {
			write-host
			Write-Host -ForegroundColor Gray " ==>Forming SOFS Cluster"
            do {
                }
            until ((Get-VMXToolsState -config $Cluster).State -eq "running")
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix 'SOFS' -IPAddress '$IPv4Subnet.210' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script new-sofsserver.ps1 -Parameter "-SOFSNAME 'SOFSServer'  $CommonParameter" -interactive
		# }
	} # End Switchblock SOFS
###### end SOFS Block
	"Sharepoint" {
        if ($Disks)
            {
		    $cloneparm = " -AddDisks -disks $Disks"
            }
            $Node = 1
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, Net-Framework-Features"
            $AddonFeatures = "$AddonFeatures, Web-Server, Web-WebServer, Web-Common-Http, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-App-Dev"
            $AddonFeatures = "$AddonFeatures, Web-Asp-Net, Web-Net-Ext, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Health, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor"
            $AddonFeatures = "$AddonFeatures, Web-Http-Tracing, Web-Security, Web-Basic-Auth, Web-Windows-Auth, Web-Filtering, Web-Digest-Auth, Web-Performance, Web-Stat-Compression"
            $AddonFeatures = "$AddonFeatures, Web-Dyn-Compression, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Compat, Web-Metabase, Application-Server, AS-Web-Support, AS-TCP-Port-Sharing"
            $AddonFeatures = "$AddonFeatures, AS-WAS-Support, AS-HTTP-Activation, AS-TCP-Activation, AS-Named-Pipes, AS-Net-Framework, WAS, WAS-Process-Model, WAS-NET-Environment"
            $AddonFeatures = "$AddonFeatures, WAS-Config-APIs, Web-Lgcy-Scripting, Windows-Identity-Foundation, Server-Media-Foundation, Xps-Viewer"
            $Prefix= $SPPrefix
            $SPSize = "TXL"
			###################################################
			# Setup of a Sharepoint Node
			# Init
			$Nodeip = "$IPv4Subnet.14$Node"
			$Nodename = "$Prefix"+"Node$Node"
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
			$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$Prefix\"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose $AddonFeatures
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
			test-dcrunning
			# Clone Base Machine
		    $CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $SPSize -Sourcedir $Sourcedir $cloneparm"
			###################################################
			If ($CloneOK)
				{
				$NodeClone = Get-VMX -Path $CloneVMX
				test-user -whois Administrator
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script powerconf.ps1 -interactive
                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-spprereqs.ps1 -interactive
                checkpoint-progress -step spprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
                Write-Host -ForegroundColor Gray " ==>Installing Sharepoint"
                If ($AlwaysOn.IsPresent)
                    {
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-sp.ps1 -Parameter "-DBtype AAG" -interactive
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-sp.ps1 -Parameter "-DBtype AAG" -interactive
                    }
                else
                    {
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-sp.ps1 -interactive
                    }
                if ($NMM.IsPresent)
                    {
				    Write-Host -ForegroundColor White  "Installing Networker $nw_ver an NMM $nmm_ver on all Nodes"
					Write-Host -ForegroundColor White  $CloneVMX
					#$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_Scriptroot -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
                    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
					$script_invoke = $NodeClone | Invoke-VMXPowershell -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver" -Guestuser $Adminuser -Guestpassword $Adminpassword
					}
				invoke-postsection
			}# end Cloneok
	} # End Switchblock Sharepoint
	"Blanknodes" {
        if ($SpacesDirect.IsPresent )
            {
            If ($Master -lt "2016")
                {
                Write-Host -ForegroundColor Gray " ==>Master 2016TP3 or Later is required for Spaces Direct"
                exit
                }
            if ($Disks -lt 2)
                {
                $Disks = 2
                }
            if ($BlankNodes -lt 4)
                {
                $BlankNodes = 4
                }
            $Cluster = $true
            $BlankHV = $true
            }
        If ($BlankHV.IsPresent)
            {
            $VTbit = $True
            }
        if ($Disks)
            {
		    $cloneparm = " -AddDisks -disks $Disks"
            }
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, RSAT-Clustering-AutomationServer, RSAT-Clustering-CmdInterface, WVR"}
        if ($BlankHV.IsPresent) {$AddonFeatures = "$AddonFeatures, Hyper-V, RSAT-Hyper-V-Tools, Multipath-IO"}
        $Blank_End = (($Blankstart+$BlankNodes)-1)
		test-dcrunning
		foreach ($Node in ($Blankstart..$Blank_End))
		{
			###################################################
			# Setup of a Blank Node
			# Init
            $Node_range = 180
            $Node_byte = $Node_range+$node
            $Nodeip = "$IPv4Subnet.$Node_byte"
            $Nodeprefix = "Node"
            $NamePrefix = "GEN"
		    $Nodename = "$NamePrefix$NodePrefix$Node"
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
            $ClusterIP = "$IPv4Subnet.180"
			###################################################
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose "Disks: $Disks"
            Write-Verbose "Blanknodes: $BlankNodes"
            Write-Verbose "Cluster: $($Cluster.IsPresent)"
            Write-Verbose "Pre Clustername: $ClusterName"
            Write-Verbose "Pre ClusterIP: $ClusterIP"
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
			# Clone Base Machine
			if ($VTbit)
			{
				$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir -SharedDisk $cloneparm"
			}
			else
			{
				$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir $cloneparm"
			}
			###################################################
			If ($CloneOK)
				{
				$NodeClone = Get-VMX -Path $CloneVMX
				test-user -whois Administrator
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                if ($NW.IsPresent)
                    {
		            $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
                    }
				invoke-postsection
			}# end Cloneok
		} # end foreach
    	if ($Cluster.IsPresent)
		    {
			write-host
			Write-Host -ForegroundColor Gray " ==>Forming Blanknode Cluster"
            If ($ClusterName)
                {
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix '$NodePrefix' -ClusterName $ClusterName -IPAddress '$IPv4Subnet.$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive -Verbose
                }
            else
                {
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix '$NodePrefix' -IPAddress '$IPv4Subnet.$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive -Verbose
                }
            }
	} # End Switchblock Blanknode
	"docker" {
		$Disks = 2
		$node = 1
        $VTbit = $True
		[switch]$Cluster = $true
        if ($Disks)
            {
		    $cloneparm = " -AddDisks -disks $Disks"
            }
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features, containers, Hyper-V, RSAT-Hyper-V-Tools, Multipath-IO"
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, RSAT-Clustering-AutomationServer, RSAT-Clustering-CmdInterface, WVR"}
		test-dcrunning
			###################################################
			# Setup of a DockerHost
			# Init
            $Node_range = 18
            $Node_byte = $Node_range+$node
            $Nodeip = "$IPv4Subnet.$Node_byte"
            $Nodeprefix = "WINHost"
            $NamePrefix = "Docker"
		    $Nodename = "$NamePrefix$NodePrefix$Node"
			$CloneVMX = Join-Path  $Builddir (Join-path $Nodename "$Nodename.vmx")
			$Host_ScriptDir = Join-Path $Default_Host_ScriptDir $NamePrefix
			$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NamePrefix\"
            #$ClusterIP = "$IPv4Subnet.180"
			###################################################
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose "Disks: $Disks"
            Write-Verbose "dockerhost: $dockerhost"
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
			# Clone Base Machine
			$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir -SharedDisk $cloneparm"
			###################################################
			If ($CloneOK)
				{
				$NodeClone = Get-VMX -Path $CloneVMX
				test-user -whois Administrator
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                if ($NW.IsPresent)
                    {
		            $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
                    }
				invoke-postsection -wait
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-docker.ps1 -interactive -Parameter "-Docker_VER $Docker_VER"
			}# end Cloneok
		 # end foreach
<#
    	if ($Cluster.IsPresent)
		    {
			write-host
			Write-Host -ForegroundColor Gray " ==>Forming Blanknode Cluster"
            If ($ClusterName)
                {
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix '$NodePrefix' -ClusterName $ClusterName -IPAddress '$IPv4Subnet.$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive -Verbose
                }
            else
                {
			    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script create-cluster.ps1 -Parameter "-Nodeprefix '$NodePrefix' -IPAddress '$IPv4Subnet.$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive -Verbose
                }
            }
#>
	} # End Switchblock Blanknode
	"Spaces" {
		foreach ($Node in (1..$SpaceNodes))
		{
			###################################################
			# Setup of a Blank Node
			# Init
			$Nodeip = "$IPv4Subnet.17$Node"
            $NodePrefix	= "Spaces"
            $Nodename = "$NodePrefix$Node"
			$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
			$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
			###################################################
			# we need a DC, so check it is running
		    Write-Verbose $IPv4Subnet
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose $Disks
            Write-Verbose $ClusterName
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-verbose "Now Pausing"
                pause
                }
			test-dcrunning
			if ($SpaceNodes -gt 1) {$AddonFeatures = "Failover-Clustering, RSAT-Clustering"}
			$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -AddOnfeatures $AddonFeature"
			###################################################
			If ($CloneOK)
				{
				$NodeClone = Get-VMX -Path $CloneVMX
				write-verbose "Copy Configuration files, please be patient"
				test-user -whois Administrator
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
				invoke-postsection -wait
			}# end Cloneok
		} # end foreach
		if ($SpaceNodes -gt 1)
		{
			write-host
			Write-Host -ForegroundColor Gray " ==>Forming Storage Spaces Cluster"
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_Scriptroot -Script create-cluster.ps1 -Parameter "-Nodeprefix 'Spaces' -IPAddress '$IPv4Subnet.170' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
		}
	} # End Switchblock Spaces
	"SQL" {
		$Node = 1 # chnge when supporting Nodes Parameter and AAG
		###################################################
		# Setup of a Blank Node
		# Init
        $size = 'XL'
		$Nodeip = "$IPv4Subnet.13$Node"
		$Nodename = "SQLNODE$Node"
		$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
		$IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\SQL\"
		###################################################
		# we need a DC, so check it is running
        Write-Verbose $IPv4Subnet
        write-verbose $Nodename
        write-verbose $Nodeip
        $AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features")
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
             {
             Write-verbose "Now Pausing"
             pause
             }
        if ($Cluster.IsPresent) {$AddonFeatures = ("$AddonFeatures", "Failover-Clustering")}
		test-dcrunning
		$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir -sql"
		###################################################
		If ($CloneOK)
			{
			$NodeClone = Get-VMX -Path $CloneVMX
			test-user -whois Administrator
			domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
			invoke-postsection -wait
            $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script prepare-disks.ps1
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER $CommonParameter" -interactive
            $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script set-sqlroles.ps1 -interactive
			if ($NMM.IsPresent)
			{
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
				$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nmm.ps1 -interactive -Parameter "-nmm_ver $nmm_ver"
			}# End NoNmm
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script import-database.ps1 -interactive
			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script finish-sql.ps1 -interactive -nowait
		}# end Cloneok
	} #end Switchblock SQL
"Panorama"
{
	###################################################
	# Panorama Setup
	###################################################
    $Nodeip = "$IPv4Subnet.19"
	$NodePrefix = "Panorama"
    $Nodename = $NodePrefix
	$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features,Web-Mgmt-Console, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI"
	###################################################
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        {
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }
	test-dcrunning
	$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -bridge -Gateway -size $Size -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
		{
		$NodeClone = Get-VMX -Path $CloneVMX
		test-user -whois Administrator
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        Write-Host -ForegroundColor Gray " ==>Building Panorama Server"
        invoke-postsection -wait
	    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script panorama.ps1 -interactive -parameter " $CommonParameter"
	}
} #Panorama End
"SRM"
{
	###################################################
	# SRM Setup
	###################################################
	$Nodeip = "$IPv4Subnet.17"
	$NodePrefix = "ViPRSRM"
    $Nodename = $NodePrefix
	$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS"
	###################################################
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        {
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }
	test-dcrunning
	$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Gateway -size XXL -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
		{
		$NodeClone = Get-VMX -Path $CloneVMX
		test-user -whois Administrator
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        if ($NW.IsPresent)
            {
            Write-Host -ForegroundColor Gray " ==>Install NWClient"
		    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
            }
        invoke-postsection -wait
	    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script INSTALL-SRM.ps1 -interactive -parameter "-SRM_VER $SRM_VER $CommonParameter"
        Write-Host -ForegroundColor White "You can now Connect to http://$($Nodeip):58080/APG/ with admin/changeme"
}
} #SRM End
"APPSYNC"
{
	###################################################
	# APPSYNC Setup
	###################################################
	$Nodeip = "$IPv4Subnet.14"
	$NodePrefix = "APPSYNC"
    $Nodename = $NodePrefix
	$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, Desktop-Experience"
	###################################################
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        {
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }
	test-dcrunning
	$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Gateway -size XXL -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	{
		$NodeClone = Get-VMX -Path $CloneVMX
		test-user -whois Administrator
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        if ($NW.IsPresent)
            {
		    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
            }
        invoke-postsection -wait
	    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script INSTALL-APPSYNC.ps1 -interactive -parameter "-APPSYNC_VER $APPSYNC_VER $CommonParameter"
        Write-Host -ForegroundColor White "You can now connect to Appsync Console from the destop icon on Appssync with admin/Password123!"
}
} #APPSYNC End
"SCOM"
{
	###################################################
	# SCO Setup
	###################################################
	$Nodeip = "$IPv4Subnet.18"
	$Nodename = "SCOM"
	$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS"
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\SCOM"
    $In_Guest_UNC_SQLScriptDir = "$IN_Guest_UNC_Scriptroot\sql\"
	###################################################
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        {
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }
	test-dcrunning
	$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 6 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Gateway -size XXL -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	{
		$NodeClone = Get-VMX -Path $CloneVMX
		test-user -whois Administrator
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
        if ($NW.IsPresent)
            {
		    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter "-nw_ver $nw_ver"
            }
        invoke-postsection -wait
	    $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SQLScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -DefaultDBpath" -interactive
        $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script INSTALL-Scom.ps1 -interactive -parameter "-SC_Version $SC_Version $CommonParameter"
}
} #APPSYNC End
    "Isilon" {
        Write-Host -ForegroundColor Gray " ==>Calling Isilon Installer"
        Invoke-Expression -Verbose "$Builddir\install-isi.ps1 -Nodes $isi_nodes -Disks 4 -Disksize 36GB -defaults "
        Write-Host -ForegroundColor White  "Isilon Setup done"
        } # end isilon
}
if (($NW.IsPresent -and !$NoDomainCheck.IsPresent) -or $NWServer.IsPresent)
    {
    if ($Master -match '_Ger')
        {
        Write-Host -ForegroundColor Magenta " ==>Networker does not Support German, checking for en-Us Master"
        Switch ($Master)
            {
            "2012_Ger"
                {
                $Master = "2012"
                }
            default
                {
                $Master = "2012R2FallUpdate"
                }
            }
        $NWMaster = test-labmaster -Masterpath "$Masterpath" -Master $Master -Confirm:$Confirm
        <#
        $NWMaster = get-vmx -path "$Masterpath\$Master" -WarningAction SilentlyContinue
        if (!$NWMaster)
            {
            if (Receive-LABMaster -Master $Master -Destination $Masterpath -unzip -Confirm:$Confirm)
                {
                $NWMaster = get-vmx -path "$Masterpath\$Master" -ErrorAction SilentlyContinue
                }
            else
                {
                Write-Warning "No valid master found /downloaded"
                break
                }
            }
        #>
        $MasterVMX = $nwmaster.config
        }
	###################################################
	# Networker Setup
	###################################################
	$Nodeip = "$IPv4Subnet.$Gatewayhost"
	$Nodename = $NWNODE
	$CloneVMX = Join-Path $Builddir (Join-Path $Nodename "$Nodename.vmx")
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NWNODE"
	###################################################
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose "Node has ip: $Nodeip"
    if ($nw_ver -ge "nw85")
        {
        $Size = "L"
        }
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        {
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }
	test-dcrunning
    If ($DefaultGateway -match $Nodeip){$SetGateway = "-Gateway"}

	$CloneOK = Invoke-expression "$Builddir\Clone-Node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference 9 -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -NW $SetGateway -size $Size -Sourcedir $Sourcedir $CommonParameter"
	###################################################
	If ($CloneOK)
	    {
		$NodeClone = Get-VMX -Path $CloneVMX
		test-user -whois Administrator
		domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddonFeatures $AddonFeatures
		# Setup Networker
		test-user -whois Administrator 
#		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "owner=$BuildDomain\\Administrator") { write-host -NoNewline "." }
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-program.ps1 -Parameter "-Program $LatestJava -ArgumentList '/s' $CommonParameter"-interactive
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-acrobat.ps1 -Parameter "$CommonParameter"-interactive
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-nwserver.ps1 -Parameter "-nw_ver $nw_ver $CommonParameter"-interactive
		if (!$Gateway.IsPresent)
            {
            checkpoint-progress -step networker -reboot
            }
        Write-Host -ForegroundColor Gray " ==>Waiting for NSR Media Daemon to start "
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "nsrd.exe")
			{
			$sleep = 1
			foreach ($i in (1..$sleep)) 
				{
				Write-Host -ForegroundColor Yellow "-`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "\`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "|`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "/`b" -NoNewline
				sleep 1
				}
			}
		write-host -ForegroundColor Green "[started]"
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script nsruserlist.ps1 -interactive
		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script create-nsrdevice.ps1 -interactive -Parameter "-AFTD AFTD1"
        If ($DefaultGateway -match $Nodeip){
                $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script firewall.ps1 -interactive
        		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script add-rras.ps1 -interactive -Parameter "-IPv4Subnet $IPv4Subnet"
                checkpoint-progress -step rras -reboot
        }
        invoke-postsection -wait
        $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-nmc.ps1 -interactive
		Write-Host -ForegroundColor Gray " ==>Please finish NMC Setup by Double-Clicking Networker Management Console from Desktop on $NWNODE"
	}
} #Networker End
$StopWatch.Stop()
Write-host -ForegroundColor White "Deployment took $($StopWatch.Elapsed.ToString())"
Write-Host -ForegroundColor White  "Deployed VM´s in Scenario $Scenarioname"
get-vmx | where scenario -match $Scenarioname | ft vmxname,state,activationpreference
return