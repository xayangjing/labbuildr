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
param(
[ValidateSet('nw8116','nw8115','nw8114', 'nw8113', 'nw811', 'nw81', 'nw8102', 'nw8102', 'nw8104', 'nw8105', 'nw8112', 'nw82', 'nwunknown')]$nw_ver = "nw82"

)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
start-process -filepath "\\vmware-host\Shared Folders\Sources\$NW_ver\win_x64\networkr\setup.exe" -ArgumentList '/S /v" /passive /l*v c:\scripts\nwclientsetup.log NW_INSTALLLEVEL=100 NW_FIREWALL_CONFIG=1 INSTALLBBB=1 NWREBOOT=0 setuptype=Install"' -wait 