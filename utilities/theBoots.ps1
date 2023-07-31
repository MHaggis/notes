Clear-Host
Write-Host @"
 TTTTT H   H EEEEE      BBBBB  OOOO  OOOO TTTTT SSSSS
   T   H   H E          B   BB O   OO   O   T   S
   T   HHHHH EEEE       BBBBB  O   OO   O   T   SSSSS
   T   H   H E          B   BB O   OO   O   T       S
   T   H   H EEEEE      BBBBB  OOOO  OOOO   T   SSSSS
"@

function Show-Menu {
    Write-Host "1. Set BootExecute value to `"`"autocheck autoche *`"`""
    Write-Host "2. Revert BootExecute value to its default `"`"autocheck autochk *`"`""
    Write-Host "3. Display the current BootExecute value"
    Write-Host "4. Set BootExecute value to a custom value"
    Write-Host "5. Exit"
}

$exit = $false

while (-not $exit) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-5)"
    
    switch ($choice) {
        "1" {
            reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v BootExecute /t REG_MULTI_SZ /d "autocheck autoche *" /f
            Write-Host "BootExecute value updated to `"`"autocheck autoche *`"`""
        }
        "2" {
            reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v BootExecute /t REG_MULTI_SZ /d "autocheck autochk *" /f
            Write-Host "BootExecute value reverted to its default `"`"autocheck autochk *`"`""
        }
        "3" {
            $value = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "BootExecute").BootExecute
            Write-Host "Current BootExecute value: `"$value`""
        }
        "4" {
            $custom_value = Read-Host "Enter the custom value for BootExecute"
            reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v BootExecute /t REG_MULTI_SZ /d "$custom_value" /f
            Write-Host "BootExecute value updated to `"`"$custom_value`"`""
        }
        "5" { $exit = $true }
        default {
            Write-Host "Invalid choice. Please enter a number between 1 and 5."
        }
    }
    Write-Host ""
}
