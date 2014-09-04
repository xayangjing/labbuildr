<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2014/06/16/announcement-labbuildr-released
#>
#requires -version 3
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
$Domain = $env:USERDOMAIN
net localgroup "Backup Operators" $Domain\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SCVMM /Add
$Files = Get-ChildItem -Path $Builddir -Filter Configuration*.ini
foreach ($file in $Files) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
}
."\\vmware-host\Shared Folders\Sources\SQL2012SP1\Setup.exe" /q /ACTION=Install /FEATURES=SQL,SSMS /INSTANCENAME=MSSQL$env:Computername /SQLSVCACCOUNT="$Domain\svc_sql" /SQLSVCPASSWORD="Password123!" /SQLSYSADMINACCOUNTS="$Domain\svc_sqladm" "$Domain\Administrator" "$Domain\svc_sql" /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /IACCEPTSQLSERVERLICENSETERMS
# Start-Process C:\scripts\Autologon.exe -ArgumentList "SVC_SQLADM $Domain Password123! /accepteula"
# New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "sql" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\sql.pass`""
# Restart-Computer
New-Item -ItemType File -Path c:\scripts\sql.pass