function Out-SPLSecurityContentMacro {


    param (
    [Parameter(Mandatory)]
    [String]
    [ValidateSet('CreateMacro')]
    $method,

    [Parameter()]
    [String]
    $OriginalFileName = "PowerShell.Exe",

    [Parameter()]
    [String]
    $ProcessName = "powershell.exe",

    
    [Parameter()]
    [String]
    $Name = "powershell",

        
    [Parameter()]
    [String]
    $MacrosPath = "/Users/mhaag/Research/malware/GitHub/security_content/macros/process_$Name.yml"

    )


function Invoke-OutNewMacro {

    $macro=@"
definition: (Processes.process_name=$ProcessName OR Processes.original_file_name=$OriginalFileName)
description: Matches the process with its original file name, data for this macro came from https://strontic.github.io/
name: process_$Name
"@

    IF (!(Test-Path $MacrosPath)) {
            new-item -Path $MacrosPath -itemtype File -Force
            Add-Content -Path $MacrosPath -Value $macro -Force -WarningAction Ignore
            Write-Host "New Macro written for process_$Name" -ForegroundColor Green
    } ELSE {
            Write-Host "The $MacrosPath is already created." -ForegroundColor Red
    }

}


switch ($method) {
'CreateMacro' { Invoke-OutNewMacro }
    }


}