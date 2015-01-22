<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
[CmdletBinding()]
param (
$nodeIP,
$nodename,
$IPv4Subnet = "192.168.2",
[ValidateSet('24')]$IPv4PrefixLength = '24',
$IPv6Prefix = "",
[ValidateSet('8','24','32','48','64')]$IPv6PrefixLength = '8',
[Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
$AddonFeatures,
[switch]$Gateway,
$Domain
)
$Addonfeatures = $Addonfeatures.Replace(" ","")
$Features = $AddonFeatures.split(",")
$IPv6subnet = "$IPv6Prefix$IPv4Subnet"
$IPv6Address = "$IPv6Prefix$nodeIP"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
Set-Content -Path "$Builddir\$ScriptName$Logtime.log" "$nodeIP, $IPv4Subnet, $nodename"
Write-Verbose $IPv6PrefixLength
Write-Verbose $IPv6Address
Write-Verbose $IPv6subnet
Write-Verbose $AddonFeatures

<# checking uefi or Normal Machine dirty hack
if ($eth0 = Get-NetAdapter -Name "Ethernet0" -ErrorAction SilentlyContinue) {
[switch]$uefi = $True
}
else
{
$eth0 = Get-NetAdapter -Name "Ethernet" -ErrorAction SilentlyContinue
}
#>

$nics = @()
$Nics = Get-NetAdapter | Sort-Object -Property Name
$eth0 = $nics[0]
$eth1 = $nics[1]

 
if ($eth1) 
    {
    Rename-NetAdapter $eth0.Name -NewName "External DHCP"
    Rename-NetAdapter $eth1.Name -NewName $Domain
    }
else
    {
    Rename-NetAdapter $eth0.Name -NewName $Domain
    }

<#
elseif  ($eth1 = Get-NetAdapter -Name "Ethernet1" -ErrorAction SilentlyContinue ) 
    {
    Rename-NetAdapter $eth0.Name -NewName "External DHCP"
    Rename-NetAdapter $eth1.Name -NewName "Ethernet"
    }

#>

If ($AddressFamily -match 'IPv4')
{

    if ($Gateway.IsPresent)
        {
        New-NetIPAddress -InterfaceAlias "$Domain" -AddressFamily IPv4 –IPAddress "$nodeIP" –PrefixLength $IPv4PrefixLength -DefaultGateway "$IPv4subnet.103"
        }
    else
        {
        New-NetIPAddress -InterfaceAlias "$Domain"  -AddressFamily IPv4 –IPAddress "$nodeIP" –PrefixLength $IPv4PrefixLength
        }
}

If ($AddressFamily -match 'IPv6')
    {
    if ($Gateway.IsPresent)
        {
        New-NetIPAddress -InterfaceAlias "$Domain" -AddressFamily IPv6 –IPAddress $IPv6Address –PrefixLength $IPv6PrefixLength -DefaultGateway "$IPv6subnet.103"
        }
        else
        {
        New-NetIPAddress -InterfaceAlias "$Domain" -AddressFamily IPv6 –IPAddress $IPv6Address –PrefixLength $IPv6PrefixLength
        }
    
}

Set-DnsClientServerAddress -InterfaceAlias "$Domain" -ServerAddresses "$IPv4Subnet.10"
if ( $AddressFamily -notmatch 'IPv4')
    {
    $eth0 | Disable-NetAdapterBinding -ComponentID ms_tcpip
    $eth1 | Disable-NetAdapterBinding -ComponentID ms_tcpip
    Set-DnsClientServerAddress -InterfaceAlias "$Domain" -ServerAddresses "$IPv6subnet.10"
    }

Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
Write-Host "Running Feature Installer"

Get-WindowsFeature $Features | Add-WindowsFeature
<#
foreach ($Feature in $Features)
    { 
        if (Get-WindowsFeature $Feature)
        {
            add-WindowsFeature $Feature 
        }
        else 
        {
            Write-Verbose "feature $Feature not found in osvesion"
        }
    }
#>


if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
Rename-Computer -NewName $nodename
New-Item -ItemType File -Path c:\scripts\2.pass
restart-computer