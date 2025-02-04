# SQL Server Security Testing Toolkit (SQLSSTT) 🛡️

SQLSSTT is a comprehensive PowerShell-based toolkit designed for SQL Server security testing and validation. Perfect for blue teams, security researchers, and system administrators who need to validate SQL Server security configurations.

```ascii
 ____   ___  _     ____ ____ _____ _____ 
/ ___| / _ \| |   / ___/ ___|_   _|_   _|
\___ \| | | | |   \___ \___ \ | |   | |  
 ___) | |_| | |___ ___) |__) || |   | |  
|____/ \__\_\_____|____/____/ |_|   |_|  
                                             
     SQL Server Security Testing Toolkit
```

## 🚀 Features

- **Automated SQL Server Installation**
  - Zero-touch SQL Server deployment
  - Secure default configurations
  - Comprehensive logging
  - PowerShell module integration

- **Security Testing Capabilities**
  - xp_cmdshell testing and validation
  - Authentication pattern testing
  - Data exfiltration simulation
  - System enumeration checks
  - URL injection testing
  - Output redirection testing

- **Dual Testing Methods**
  - Invoke-Sqlcmd PowerShell cmdlet
  - Native sqlcmd.exe utility

## 📋 Prerequisites

- Windows PowerShell 5.1 or later
- Administrative privileges
- 6GB+ free disk space
- Internet connectivity (for installer download)
- SQL Server PowerShell Module (optional)
- SQL Server Command Line Utilities (optional)

## 🛠️ Quick Start

1. **Install SQL Server**
```powershell
.\install-SQL.ps1
```

2. **Run Security Tests**
```powershell
.\SQLSSTT.ps1 -Server "localhost" -Database "master" -Username "sa" -Password "ComplexPass123!"
```

3. **Verify Installation**
```powershell
.\sql-tester.ps1
```

## 📊 Test Categories

- Basic Connectivity
- Authentication Patterns
- System Enumeration
- Configuration Tests
- Data Exfiltration Patterns
- Output Format Tests
- URL Input Tests
- xp_cmdshell Tests

## ⚙️ Configuration

Default settings can be modified in each script:

```powershell
$config = @{
    Server = "localhost"
    Database = "master"
    Username = "sa"
    Password = "ComplexPass123!"
    UseBothMethods = $true
}
```

## 🔍 Example Usage

```powershell
# Basic test with defaults
.\SQLSSTT.ps1

# Test remote SQL Server
.\SQLSSTT.ps1 -Server "sql.contoso.com" -Username "pentester" -Password "SecurePass123!"

# Test specific database
.\SQLSSTT.ps1 -Server "dbserver" -Database "target_db" -UseBothMethods:$false
```

## 📝 Logging

- Installation logs: `C:\SQL2022\InstallLogs\install.log`
- Test results: Console output with color-coded status
- Detailed error messages and stack traces

## ⚠️ Security Notes

- This toolkit is for authorized testing only
- Default credentials should be changed post-installation
- Some tests may trigger security monitoring systems
- Always test in controlled environments first

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bugs and feature requests.

---
Created with 💙 by The Haag
