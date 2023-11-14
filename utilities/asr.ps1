  # This script is designed to manage individual Attack Surface Reduction (ASR) rules in a Windows environment.
  # It provides a list of ASR rules with their corresponding GUIDs and allows the user to enable or disable 
  # specific rules based on their needs. The script also allows the user to set the mode of the rule to either 
  # Block, Audit, or Warn. This provides flexibility in managing the security posture of the system.
  # The script is interactive and prompts the user for inputs.
  # Author: @M_haggis
  # Additional credits to https://techcommunity.microsoft.com/t5/microsoft-defender-for-endpoint/demystifying-attack-surface-reduction-rules-part-3/ba-p/1360968 and https://github.com/anthonws/MDATP_PoSh_Scripts/blob/master/ASR/ASR_Analyzer_v2.2.ps1

# Define ASR rules with their corresponding GUIDs
$asrRules = @{
    "Block abuse of exploited vulnerable signed drivers" = "56a863a9-875e-4185-98a7-b882c64b5ce5";
    "Block Adobe Reader from creating child processes" = "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c";
    "Block all Office applications from creating child processes" = "D4F940AB-401B-4EFC-AADC-AD5F3C50688A";
    "Block credential stealing from the Windows local security authority subsystem (lsass.exe)" = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2";
    "Block executable content from email client and webmail" = "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550";
    "Block executable files from running unless they meet a prevalence, age, or trusted list criterion" = "01443614-cd74-433a-b99e-2ecdc07bfc25";
    "Block execution of potentially obfuscated scripts" = "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC";
    "Block JavaScript or VBScript from launching downloaded executable content" = "D3E037E1-3EB8-44C8-A917-57927947596D";
    "Block Office applications from creating executable content" = "3B576869-A4EC-4529-8536-B80A7769E899";
    "Block Office applications from injecting code into other processes" = "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84";
    "Block Office communication applications from creating child processes" = "26190899-1602-49e8-8b27-eb1d0a1ce869";
    "Block persistence through WMI event subscription" = "e6db77e5-3df2-4cf1-b95a-636979351e5b";
    "Block process creations originating from PSExec and WMI commands" = "d1e49aac-8f56-4280-b9ba-993a6d77406c";
    "Block untrusted and unsigned processes that run from USB" = "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4";
    "Block Webshell creation for Servers" = "a8f5898e-1dc8-49a9-9878-85004b8a61e6";
    "Block Win32 API calls from Office macros" = "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B";
    "Use advanced protection against ransomware" = "c1db55ab-c21a-4637-bb3f-a12568109d35";
} 

function Enable-ASRRule {
    $asrRulesArray = $asrRules.Keys
    $i = 1
    foreach ($ruleName in $asrRulesArray) {
        Write-Host "${i}: $ruleName"
        $i++
    }
    $selectedRuleNumber = Read-Host "Enter the number of the ASR rule you want to enable"
    if ($selectedRuleNumber -le 0 -or $selectedRuleNumber -gt $asrRulesArray.Count) {
        Write-Host "Invalid rule number. Please try again."
        return
    }
    $selectedRuleName = $asrRulesArray[$selectedRuleNumber - 1]
    $selectedRuleId = $asrRules[$selectedRuleName]

    $mode = Read-Host "Enter the mode (Block, Audit, Warn)"
    switch ($mode) {
        "Block" { $action = "Enabled" }
        "Audit" { $action = "AuditMode" }
        "Warn"  { $action = "Warn" }
        default {
            Write-Host "Invalid mode. Please enter Block, Audit, or Warn."
            return
        }
    }

    Set-MpPreference -AttackSurfaceReductionRules_Ids $selectedRuleId -AttackSurfaceReductionRules_Actions $action
    Write-Host "ASR rule '$selectedRuleName' has been set to $mode mode."
}

function Disable-ASRRule {
    $i = 1
    $asrRulesArray = @($asrRules.Keys)
    foreach ($ruleName in $asrRulesArray) {
        Write-Host "${i}: $ruleName"
        $i++
    }
    $selectedRuleNumber = Read-Host "Enter the number of the ASR rule you want to disable"
    $selectedRuleName = $asrRulesArray[$selectedRuleNumber - 1]
    $selectedRuleId = $asrRules[$selectedRuleName]

    if (-not $selectedRuleId) {
        Write-Host "Invalid rule number. Please try again."
        return
    }

    Set-MpPreference -AttackSurfaceReductionRules_Ids $selectedRuleId -AttackSurfaceReductionRules_Actions Disabled
    Write-Host "ASR rule '$selectedRuleName' has been disabled."
}

function EnableAllASRRules {
    $mode = Read-Host "Enter the mode for all rules (Block, Audit, Warn)"
    switch ($mode) {
        "Block" { $action = "Enabled" }
        "Audit" { $action = "AuditMode" }
        "Warn"  { $action = "Warn" }
        default {
            Write-Host "Invalid mode. Please enter Block, Audit, or Warn."
            return
        }
    }

    $ruleIds = $asrRules.Values
    Set-MpPreference -AttackSurfaceReductionRules_Ids $ruleIds -AttackSurfaceReductionRules_Actions ($ruleIds | ForEach-Object { $action })
    Write-Host "All ASR rules have been set to $mode mode."
}


function DisableAllASRRules {
    $ruleIds = $asrRules.Values
    Set-MpPreference -AttackSurfaceReductionRules_Ids $ruleIds -AttackSurfaceReductionRules_Actions ($ruleIds | ForEach-Object { 'Disabled' })
    Write-Host "All ASR rules have been disabled."
}

### REFERENCE: https://github.com/anthonws/MDATP_PoSh_Scripts/blob/master/ASR/ASR_Analyzer_v2.2.ps1
### https://techcommunity.microsoft.com/t5/microsoft-defender-for-endpoint/demystifying-attack-surface-reduction-rules-part-3/ba-p/1360968
function CheckASR {
    $RulesIds = Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids
    $RulesActions = Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Actions
    $RulesExclusions = Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionOnlyExclusions

    $RulesIdsArray = @()
    $RulesIdsArray += $RulesIds

    $counter = 0
    $TotalNotConfigured = 0
    $TotalAudit = 0
    $TotalBlock = 0
    $TotalWarn = 0

    ForEach ($i in $RulesActions){
        If ($RulesActions[$counter] -eq 0){$TotalNotConfigured++}
        ElseIf ($RulesActions[$counter] -eq 1){$TotalBlock++}
        ElseIf ($RulesActions[$counter] -eq 2){$TotalAudit++}
        ElseIf ($RulesActions[$counter] -eq 6){$TotalWarn++}
        $counter++
    }

    Write-Host 
    Write-Host ====================================== ASR Summary ======================================

    Write-Host "=> There's"($RulesIds).Count"rules configured"
    Write-Host "=>"$TotalNotConfigured "in Disabled Mode **" $TotalAudit "in Audit Mode **" $TotalBlock "in Block Mode **" $TotalWarn "in Warn Mode"

    Write-Host 
    Write-Host ====================================== ASR Rules ======================================

    $counter = 0

    ForEach ($j in $RulesIds){
        ## Convert GUID into Rule Name
        If ($RulesIdsArray[$counter] -eq "56a863a9-875e-4185-98a7-b882c64b5ce5"){$RuleName = "Block abuse of exploited vulnerable signed drivers"}
        ElseIf ($RulesIdsArray[$counter] -eq "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c"){$RuleName = "Block Adobe Reader from creating child processes"}
        ElseIf ($RulesIdsArray[$counter] -eq "D4F940AB-401B-4EFC-AADC-AD5F3C50688A"){$RuleName = "Block all Office applications from creating child processes"}
        ElseIf ($RulesIdsArray[$counter] -eq "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2"){$RuleName = "Block credential stealing from the Windows local security authority subsystem (lsass.exe)"}
        ElseIf ($RulesIdsArray[$counter] -eq "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550"){$RuleName = "Block executable content from email client and webmail"}
        ElseIf ($RulesIdsArray[$counter] -eq "01443614-cd74-433a-b99e-2ecdc07bfc25"){$RuleName = "Block executable files from running unless they meet a prevalence, age, or trusted list criteria"}
        ElseIf ($RulesIdsArray[$counter] -eq "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC"){$RuleName = "Block execution of potentially obfuscated scripts"}
        ElseIf ($RulesIdsArray[$counter] -eq "D3E037E1-3EB8-44C8-A917-57927947596D"){$RuleName = "Block JavaScript or VBScript from launching downloaded executable content"}
        ElseIf ($RulesIdsArray[$counter] -eq "3B576869-A4EC-4529-8536-B80A7769E899"){$RuleName = "Block Office applications from creating executable content"}
        ElseIf ($RulesIdsArray[$counter] -eq "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84"){$RuleName = "Block Office applications from injecting code into other processes"}
        ElseIf ($RulesIdsArray[$counter] -eq "26190899-1602-49e8-8b27-eb1d0a1ce869"){$RuleName = "Block Office communication applications from creating child processes"}
        ElseIf ($RulesIdsArray[$counter] -eq "e6db77e5-3df2-4cf1-b95a-636979351e5b"){$RuleName = "Block persistence through WMI event subscription"}
        ElseIf ($RulesIdsArray[$counter] -eq "d1e49aac-8f56-4280-b9ba-993a6d77406c"){$RuleName = "Block process creations originating from PSExec and WMI commands"}
        ElseIf ($RulesIdsArray[$counter] -eq "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4"){$RuleName = "Block untrusted and unsigned processes that run from USB"}
        ElseIf ($RulesIdsArray[$counter] -eq "a8f5898e-1dc8-49a9-9878-85004b8a61e6"){$RuleName = "Block Webshell creation for Servers"}
        ElseIf ($RulesIdsArray[$counter] -eq "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B"){$RuleName = "Block Win32 API calls from Office macro"}
        ElseIf ($RulesIdsArray[$counter] -eq "c1db55ab-c21a-4637-bb3f-a12568109d35"){$RuleName = "Use advanced protection against ransomware"}
        Else   {$RuleName = "UNKNOWN ASR rule name"}
        ## Check the Action type
        If ($RulesActions[$counter] -eq 0){$RuleAction = "Disabled"}
        ElseIf ($RulesActions[$counter] -eq 1){$RuleAction = "Block"}
        ElseIf ($RulesActions[$counter] -eq 2){$RuleAction = "Audit"}
        ElseIf ($RulesActions[$counter] -eq 6){$RuleAction = "Warn"}
        ## Output Rule Id, Name and Action
        Write-Host "=>" $RulesIdsArray[$counter] " **" $RuleName "**" "Action:"$RuleAction
        $counter++
    }

    Write-Host 
    Write-Host ====================================== ASR Exclusions ======================================

    $counter = 0

    ## Output ASR exclusions
    ForEach ($f in $RulesExclusions){
        Write-Host "=>" $RulesExclusions[$counter]
        $counter++
    }
}


Write-Output @"
_________________________________________              _____    ___________________ 
/   _____/\__    ___/\______   \__    ___/             /  _  \  /   _____/\______   \
\_____  \   |    |    |       _/ |    |      ______   /  /_\  \ \_____  \  |       _/
/        \  |    |    |    |   \ |    |     /_____/  /    |    \/        \ |    |   \
/_______  /  |____|    |____|_  / |____|              \____|__  /_______  / |____|_  /
       \/                    \/                              \/        \/         \/ 
"@

  # Main script
  while ($true) {
    Write-Host "`nSelect an option:"
    Write-Host "1: Enable an ASR rule"
    Write-Host "2: Disable an ASR rule"
    Write-Host "3: Enable all ASR rules"
    Write-Host "4: Disable all ASR rules"
    Write-Host "5: Check ASR"
    Write-Host "6: Exit"
    $option = Read-Host "Enter your choice"

    switch ($option) {
        "1" { Enable-ASRRule }
        "2" { Disable-ASRRule }
        "3" { EnableAllASRRules }
        "4" { DisableAllASRRules }
        "5" { CheckASR }
        "6" { exit }
        default { Write-Host "Invalid option. Please try again." }
    }
}
