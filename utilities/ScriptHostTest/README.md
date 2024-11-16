# ScriptHostTest.ps1


## 🚀 Overview

**ScriptHostTest.ps1** is a powerful PowerShell script designed to test file creation and execution permissions across various Windows directories. It helps defenders and security professionals validate AppLocker and Windows Defender Application Control (WDAC) policies by attempting to create and execute different types of scripts in specified user and system paths. This tool ensures that security boundaries and access controls are effectively enforced within your environment.

## 🔒 Features

- **✅ Validate AppLocker & WDAC Policies**: Ensure that your script execution policies are correctly configured.
- **📝 Multiple File Types**: Supports `.ps1`, `.bat`, `.cmd`, `.vbs`, `.js`, `.jse`, `.hta`, and more.
- **📊 Detailed Logging**: Track successes, failures, and generate comprehensive reports.
- **⚙️ Interactive Mode**: Customize paths and file types to fit your unique environment.
- **🧹 Automatic Cleanup**: Ensures all test files are removed post-execution for a tidy workspace.
- **🔍 Identify Policy Gaps**: Spot vulnerabilities and strengthen your defenses with ease.
- **📂 Configuration Support**: Easily define custom paths and file types via a JSON configuration file.

## 🛠 Installation

1. **Download the Script:**
   
   Clone the repository or download the `ScriptHostTest.ps1` script directly.

   ```powershell
   git clone https://github.com/your-repo/ScriptHostTest.git
   ```

2. **Navigate to the Script Directory:**

   ```powershell
   cd path\to\utilities\ScriptHostTest
   ```

3. **Ensure Execution Policy Allows Script Execution:**

   You might need to set the execution policy to allow running scripts.

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 📁 Configuration

**ScriptHostTest.ps1** can be customized using a JSON configuration file. By default, it looks for `ScriptHostTestConfig.json` in the script's directory. You can specify a different path using the `-ConfigPath` parameter.

### 📝 Example Configuration (`ScriptHostTestConfig.json`)

```json
{
    "UserPaths": [
        "C:\\Users\\%USERNAME%\\Downloads",
        "C:\\Users\\%USERNAME%\\Documents"
    ],
    "SystemPaths": [
        "C:\\Windows\\Tasks",
        "C:\\Windows\\tracing",
        "C:\\Windows\\registration\\crmlog",
        "C:\\Windows\\System32\\Tasks",
        "C:\\Windows\\System32\\spool\\drivers\\color"
    ],
    "FileTypes": [
        { "Ext": ".ps1", "Content": "$psContent" },
        { "Ext": ".bat", "Content": "$batContent" },
        { "Ext": ".cmd", "Content": "$batContent" },
        { "Ext": ".vbs", "Content": "$vbsContent" },
        { "Ext": ".js", "Content": "$jsContent" },
        { "Ext": ".jse", "Content": "$jsContent", "Executor": "cscript.exe" },
        { "Ext": ".hta", "Content": "$hta", "Executor": "mshta.exe" }
    ]
}
```

### 📌 Notes:

- **Environment Variables**: Use `%USERNAME%` to dynamically insert the current user's name.
- **Custom File Types**: Define additional script types and their respective executors as needed.

## 📋 Usage

### 🔧 Parameters

- `-VerboseLogging`: Enables verbose logging of script execution.
- `-ConfigPath <Path>`: Specifies the path to the configuration file in JSON format.
- `-Interactive`: Launches the script in interactive mode, allowing user selection of paths and file types.
- `-Force`: Runs the script without interactive prompts, using all specified configurations.

### 💻 Running the Script

#### 1. **Basic Execution**

Run the script with default settings:

```powershell
.\ScriptHostTest.ps1
```

#### 2. **Verbose Logging**

Enable detailed logging:

```powershell
.\ScriptHostTest.ps1 -VerboseLogging
```

#### 3. **Custom Configuration File**

Specify a custom configuration file:

```powershell
.\ScriptHostTest.ps1 -ConfigPath "C:\Configs\CustomConfig.json"
```

#### 4. **Interactive Mode**

Choose specific paths and file types interactively:

```powershell
.\ScriptHostTest.ps1 -Interactive
```

#### 5. **Force Execution Without Prompts**

Run the script without any interactive prompts:

```powershell
.\ScriptHostTest.ps1 -Force
```

### 📂 Example Commands

- **Run with Verbose Logging and Custom Config:**

  ```powershell
  .\ScriptHostTest.ps1 -VerboseLogging -ConfigPath "C:\Configs\ScriptHostTestConfig.json"
  ```

- **Run in Interactive Mode:**

  ```powershell
  .\ScriptHostTest.ps1 -Interactive
  ```

- **Run with All Parameters:**

  ```powershell
  .\ScriptHostTest.ps1 -VerboseLogging -ConfigPath "C:\Configs\ScriptHostTestConfig.json" -Interactive -Force
  ```


## 📈 Reporting

After execution, the script logs detailed information and generates a summary report indicating:

- **Total Tests Run**
- **Successful Tests**
- **Failed Tests**
- **Success Rate**

The summary is both displayed on the console and written to `ScriptHostTest.log`.

## 🧹 Cleanup

The script ensures that all created test files are removed after execution. In case of interruptions, a trap block captures the event and performs cleanup to maintain a clean environment.

## 🛡️ Security Considerations

- **Execution Policy**: Ensure that the script aligns with your organization's PowerShell execution policies.
- **Administrator Privileges**: Testing system paths might require administrative privileges.
- **Script Content**: The scripts created for testing are benign and meant solely for validation purposes.

## 🤝 Contributing

Contributions are welcome! 


## 🌟 Example Usage Scenarios

### 1. **Validating Execution Policies**

Ensure that your AppLocker and WDAC policies are correctly preventing unauthorized script executions.

```powershell
.\ScriptHostTest.ps1 -VerboseLogging -ConfigPath "C:\Configs\ScriptHostTestConfig.json" -Force
```

### 2. **Custom Script Types**

Add and test custom scripting languages or encrypted script types to validate their handling by security policies.

```json
{
    "CustomFileTypes": [
        {
            "Ext": ".py",
            "Content": "print(\"Python script executed successfully\")",
            "Executor": "python.exe"
        }
    ]
}
```


💡 **Tip**: Always review and understand the scripts you're executing in your environment. Ensure that `ScriptHostTest.ps1` is run in a controlled manner to avoid unintended side effects. 