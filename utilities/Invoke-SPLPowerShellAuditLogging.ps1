function Invoke-SPLPowerShellAuditLogging {
        <#
        .SYNOPSIS
        
        A simple script to assist with enabling PowerShell Script Block, Module and Transcript logging.
                
        .DESCRIPTION

        The following functions are meant to make it easy to enable PowerShell Logging and Splunk it. 

        This particular method is not meant to be something deployed across an enterprise, which is why we have GPOs. This is meant to help with "testing" out PowerShell logging to determine proof of value in such a rich dataset.

        .PARAMETER Method
        
        Specifies the method of Logging you would like to enable.

        ScriptBlockLogging
        ModuleLogging
        TranscriptLogging

        EnableAllLogging
        DisableAllLogging

        ProcessCreateWithCmdline

        .PARAMETER InputsFilePath
        Specifies the path you would like the App to be installed at.
        Default is C:\Program Files\SplunkUniversalForwarder\etc\apps

        .PARAMETER TransactionLogPath
        Specifies the path you would like Transaction logs to be stored.
        Default is C:\pstransactions\
        
        .EXAMPLE
       
        Invoke-SPLPowerShellAuditLogging -method ScriptBlockLogging
       
        Enable only ScriptBlockLogging

        .EXAMPLE
        
        Invoke-SPLPowerShellAuditLogging -method EnableAllLogging

        Enable all logging

        .EXAMPLE        
        
        Invoke-SPLPowerShellAuditLogging -method DisableAllLogging

        Disable all logging and delete the transcript log directory.

        .EXAMPLE
        
        Invoke-SPLPowerShellAuditLogging -method EnableAllLogging -TransactionLogPath C:\Temp\ 

        Enable all logging and place Transport logs in a specified path.

        .LINK
        Code originated from: https://raw.githubusercontent.com/timip/splunk/master/powershell_logging.ps1
        Reference: https://hurricanelabs.com/splunk-tutorials/how-to-use-powershell-transcription-logs-in-splunk/


        .NOTES
        
        #>
                param (
                [Parameter(Mandatory)]
                [String]
                [ValidateSet('ScriptBlockLogging','ModuleLogging','TranscriptLogging','EnableAllLogging','DisableAllLogging','ProcessCreateWithCmdline','CreateInputs')]
                $method,
        
                [Parameter()]
                [String]
                $InputsFilePath = 'C:\Program Files\SplunkUniversalForwarder\etc\apps',

                [Parameter()]
                [String]
                $TransactionLogPath = "C:\pstransactions\"

                )
        
                $ascii = @"
                __
                .-.__      \ .-.  ___  __|_|
            '--.-.-(   \/\;;\_\.-._______.-.
                (-)___     \ \ .-\ \;;\(   \       \ \
                 Y    '---._\_((Q)) \;;\\ .-\     __(_)
                 I           __'-' / .--.((Q))---'    \,
                 I     ___.-:    \|  |   \'-'_          \
                 A  .-'      \ .-.\   \   \ \ '--.__     '\
                 |  |____.----((Q))\   \__|--\_      \     '
                    ( )        '-'  \_  :  \-' '--.___\
                     Y                \  \  \       \(_)
                     I                 \  \  \         \,
                     I                  \  \  \          \
                     A                   \  \  \          '\
                     |              snd   \  \__|           '
                                           \_:.  \
                                             \ \  \
                                              \ \  \
                                               \_\_|


"@

        $ascii

        function Invoke-SPLScriptBlockLogging {

                Write-Host "Enabling PowerShell Script Block Logging"   

                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
                $Name = "EnableScriptBlockLogging"
                $value = "1"
                
                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
                $Name = "EnableScriptBlockInvocationLogging"
                $value = "1"
                
                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                }
                
        }
        
        function Invoke-SPLModuleLogging {
                
                Write-Host "Enabling PowerShell Module Logging"

                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
                $Name = "EnableModuleLogging"
                $value = "1"
                
                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames"
                $Name = "*"
                $value = "*"
                
                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -Force | Out-Null
                }
        
        }
        
        function Invoke-SPLTranscriptLogging {

                Write-Host "Enabling PowerShell Transcript Logging"

                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\Transcription"
                $Name = "EnableInvocationHeader"
                $value = "1"
                
                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\Transcription"
                $Name = "EnableTranscripting"
                $value = "1"
                
                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\Transcription"
                $Name = "OutputDirectory"
                
                $value = $TransactionLogPath
                
                IF (!(Test-Path $TransactionLogPath)) {
                        New-Item -Path $TransactionLogPath  -ItemType Directory -Force | Out-Null
                } ELSE {
                        Write-Host "Unable to create directory $TransactionLogPath"
                }

                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -Force | Out-Null
                }
        
        }

        function Invoke-SPLProcessCreationIncludeCmdLine {

                Write-Host "Enabling Process Creation Include CmdLine"

                auditpol /set /category:"detailed tracking" /subcategory:"Process Creation" /success:enable | Out-Null
                
                $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
                $Name = "ProcessCreationIncludeCmdLine_Enabled"
                $value = "1"
                
                IF (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                } ELSE {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                }
        
        }

        function Invoke-SPLPSLogging {
                Write-Host "Invoking all PowerShell Logging Methods" -ForegroundColor Green
                Invoke-SPLScriptBlockLogging
                Invoke-SPLModuleLogging
                Invoke-SPLTranscriptLogging
                Invoke-SPLProcessCreationIncludeCmdLine
                Write-Host "All Logging is Enabled. May the force be with you." -ForegroundColor Green
        }
        
        function Invoke-SPLInputs {

                $InputsConf=@"
[WinEventLog://Microsoft-Windows-PowerShell/Operational]
source = XmlWinEventLog:Microsoft-Windows-PowerShell/Operational
renderXml = 0
disabled = false
index = win   

[monitor://$TransactionLogPath]
sourcetype = powershell:transcript
disabled = false
multiline_event_extra_waittime = true
time_before_close = 300
index = win
"@

                $InputsConfFile = "$InputsFilePath\SPLAuditLogging\local\inputs.conf"

                IF (!(Test-Path $InputsConfFile)) {
                        new-item -Path $InputsFilePath\SPLAuditLogging\local\ -itemtype directory -Force
                        new-item -Path $InputsConfFile -ItemType File -Force
                        Add-Content -Path $InputsConfFile -Value $InputsConf -Force -WarningAction Ignore
                        Write-Host "Restarting SplunkForwarder" -ForegroundColor Green
                        Restart-Service SplunkForwarder -Force
                        Write-Host "$InputsConfFile has been created and SplunkForwarder restarted." -ForegroundColor Green
                } ELSE {
                        Write-Host "The $InputsConfFile is already created." -ForegroundColor Red
                }

        }

        function Invoke-SPLDisableAllLogging {

                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
                $Name = "EnableScriptBlockLogging"
                
                IF (Test-Path $registryPath) {
                        Remove-ItemProperty -Path $registryPath -Name $name -Force -WarningAction Ignore
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
                $Name = "EnableScriptBlockInvocationLogging"
                
                IF (Test-Path $registryPath) {
                        Remove-ItemProperty -Path $registryPath -Name $name -Force
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
                $Name = "EnableModuleLogging"
                
                IF (Test-Path $registryPath) {
                        Remove-ItemProperty -Path $registryPath -Name $name -Force
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames"
                $Name = "*"
                
                IF (Test-Path $registryPath) {
                        Remove-ItemProperty -Path $registryPath -Name $name -Force
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                }

                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\Transcription"
                $Name = "EnableInvocationHeader"
                
                IF (Test-Path $registryPath) {
                        Remove-ItemProperty -Path $registryPath -Name $name -Force
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\Transcription"
                $Name = "EnableTranscripting"
                
                IF (Test-Path $registryPath) {
                        Remove-ItemProperty -Path $registryPath -Name $name -Force
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                }
                
                $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\Transcription"
                $Name = "OutputDirectory"
                
                IF (Test-Path $registryPath) {
                        Remove-ItemProperty -Path $registryPath -Name $name  -Force
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                }
                

                $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
                $Name = "ProcessCreationIncludeCmdLine_Enabled"
                
                IF (Test-Path $registryPath) {
                        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
                } ELSE {
                        Write-Host "Unable to remove $registryPath and key $Name"
                        }
                
                
        
                IF (Test-Path $TransactionLogPath) {
                        Remove-Item -Path $TransactionLogPath -Recurse -Force -WarningAction Ignore
                } ELSE {
                        Write-Host "Unable to remove $TransactionLogPath"
                }
                
        }

                switch ($method) {
                'ScriptBlockLogging' { Invoke-SPLScriptBlockLogging }
                'ModuleLogging' { Invoke-SPlModuleLogging }
                'TranscriptLogging' { Invoke-SPLTranscriptLogging }
                'EnableAllLogging' { Invoke-SPLPSLogging }
                'DisableAllLogging' { Invoke-SPLDisableAllLogging }
                'ProcessCreateWithCmdline' { Invoke-SPLProcessCreationIncludeCmdLine }
                'CreateInputs' { Invoke-SPLInputs }
                }
        
                
        }

         
