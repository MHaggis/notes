# Install Exchange on Attack Range

The following assumes you have deployed an Attack Range.

Install Exchange on the DC, or a domain joined server.

Before installing, validate disk space is larger than 30Gb. 

If using AWS, expand the EBS volume attached to server. On the server, open Storage services and expand the volume.


## Install

source: https://raw.githubusercontent.com/clong/DetectionLab/3ac2b21ccc4ab3434d4362b9bff7e59ce644eeed/Vagrant/scripts/install-exchange.ps1

New version: https://github.com/clong/DetectionLab/blob/master/Vagrant/scripts/install-exchange.ps1

Because this is not being install within Detectionlab, we will need to modify the end of the script to D: and not e: 


```
If (Test-Path "D:\Setup.exe") {
    Start-Process cmd.exe -ArgumentList "/k", "d:\setup.exe", "/PrepareSchema", "/IAcceptExchangeServerLicenseTerms" -Credential $credential -Wait
    Start-Process cmd.exe -ArgumentList "/k", "d:\setup.exe", "/PrepareAD", "/OrganizationName:`"Attack Range`"", "/IAcceptExchangeServerLicenseTerms" -Credential $credential -Wait
    Start-Process cmd.exe -ArgumentList "/k", "d:\setup.exe", "/Mode:Install", "/Role:Mailbox", "/IAcceptExchangeServerLicenseTerms" -Credential $credential -Wait
}
Else {
    Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Something went wrong downloading or mounting the ISO..." }
```

Also change any hardcoded username/passwords.