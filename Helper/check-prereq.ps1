
$pwd = (get-location).path
$netfx = "dotNetFx40_Full_x86_x64.exe"
IF ($PSVersionTable.Psversion.Major -gt 2)
    {
    write-host " Found Powershell $($PSVersionTable.Psversion) , great ! "
    }
else #posh 2 or lower
    {
    Write-Host "Found Powershell"
    Write-Host $PSVersionTable.Psversion
    write-host "PS version to old, need to Upgrade"
    $netversions = .\get-netversions.ps1
if ($netversions -contains "4.0")
        { 
        Write-Output "Great, net Framework 4.0 Found "
        }
else
        {
        Write-Host "Netfx 4 not found"
        write-host "installing netfx 4.0, this may take a while"  -ForegroundColor Yellow
        start-process -FilePath .\$netfx -ArgumentList "/q /norestart"
        do
            {
            write-host -NoNewline "."
            sleep 5
            }
        until (!(get-process $netfx.TrimEnd(".exe") -ErrorAction SilentlyContinue ))
        Write-Host

} #end else
write-host "installing powershell 3.0, reboot required" -ForegroundColor Yellow
start-process  -filepath wusa.exe -ArgumentList "$pwd\Windows6.1-KB2506143-x64.msu /quiet /norestart"
do
    {
        write-host -NoNewline "."
        sleep 5
    }
until (!(get-process wusa -ErrorAction SilentlyContinue ))
write-host "done, please press any key to restart computer" -ForegroundColor Yellow
# $commandline = Join-Path $PSScriptRoot $MyInvocation.MyCommand
# New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "ChechRequirements" -Value "$PSHOME\powershell.exe -Command $commandline"
# Write-Output $Commandline
# pause
restart-computer
}  #end posh 2 or lower


#### Testing First-Mount
write-host -ForegroundColor Yellow "Checking OS Version"
if ([System.Environment]::OSVersion.Version.Minor -lt 2 -and [System.Environment]::OSVersion.Version.Major -eq 6)
    { 
    write-output "Running Windows 7, mount requires old method. Trying first mount to install VHD Drivers"
    
    Start-Process  "$psHome\powershell.exe"  -Verb Runas -ArgumentList "-ExecutionPolicy Bypass -command $pwd\..\mount-sourcevhd.ps1 -sourcevhd  $pwd\..\sources.vhd -verbose -mount"
    Write-Host "We are waiting for mounter, Press any key when mounter finished" -ForegroundColor Yellow
    pause
    }
#### vmware check ####
write-host -ForegroundColor Yellow "testing VMware Installed.... "
if (!(Test-Path "HKCR:\")) { $NewPSDrive = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT }

if (!($VMWAREpath = Get-ItemProperty HKCR:\Applications\vmware.exe\shell\open\command -ErrorAction SilentlyContinue))
{
	Write-Error "VMware Binaries not found from registry"; Break
}

Write-Host "Excellent, VMware installed in $VMWAREpath"
write-host "Excellent, all requirements done, starting labbuildr"
write-output "starting labbuildr powershell"
start-process  $pshome\powershell.exe -ArgumentList " -noexit -command $pwd\..\profile.ps1"  -WorkingDirectory "$pwd\..\"