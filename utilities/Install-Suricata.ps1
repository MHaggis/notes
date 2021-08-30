# Two step:
# 1.) Install the suricata TA to $splunkUF/etc/apps on a Windows System, not Linux box.
# 1.a) Modify the inputs to index=network
# 1.b) Ensure the monitor path is windows specific to the eve.json file for Suricata
# 2.) Run this script from disk, or copy and paste into PowerShell/PowerShell_ISE. Run.
# 2.a) The script will prompt you to double click the installation of npcap.exe in c:\temp. 

$exepath = "c:\temp"
$suricataPath = 'C:\Program Files\Suricata'

If (-not (Test-Path $exepath\suricata.msi)) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Downloading Suricata to" $exepath
  Invoke-WebRequest -Uri https://www.openinfosecfoundation.org/download/windows/Suricata-6.0.1-2-64bit.msi -OutFile $exepath\Suricata.msi
} else {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Suricata is already downloaded."
}

If (-not (Test-Path $exepath\npcap.exe)) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Downloading Npcap to" $exepath
  Invoke-WebRequest -Uri https://nmap.org/npcap/dist/npcap-1.20.exe -OutFile $exepath\npcap.exe
} else {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) npcap is already downloaded."
}


If (-not (Test-Path 'C:\Program Files\suricata')) {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Installing Suricata" 
  msiexec /i $exepath\Suricata.msi /l*v $exepath\suricataInstallLog.txt /qn
} else {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Suricata is already installed."
}

#If (-not (Test-Path 'C:\Program Files\npcap\NPFInstall.exe')) {
#  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Installing npcap" 
#  Stop-Service SplunkForwarder -force
#  c:\temp\npcap.exe
#  Start-Service SplunkForwarder
#} else {
#  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) npcap is already installed."
#}

If (-not (Test-Path 'C:\Program Files\npcap\NPFInstall.exe')) {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date))  Install NPCap:" 
  Stop-Service SplunkForwarder -force
  Invoke-Item c:\temp
  Read-Host -Prompt "SplunkForwarder is stopped. Manually install npcap from $exepath. Press any key to continue"
  Start-Service SplunkForwarder
} else {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) NPCap is already installed."
}


copy-item $suricataPath\suricata.yaml -Destination $suricataPath\suricata.yaml.bak
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Downloading custom yaml"
Invoke-WebRequest -Uri https://gist.githubusercontent.com/MHaggis/777bf3578c26e69cadb57c62ffcbe66d/raw/dd5fe35752c5fa617800ea8e988cc5b3493a9daf/suricata.yaml -OutFile $suricataPath\suricata.yaml


Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Starting Suricata"
Set-Location $suricataPath
.\suricata.exe -c suricata.yaml -i 10.0.1.14 