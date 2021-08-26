function Invoke-CertUtil {
  <#
 
 .EXAMPLE
     Invoke-CertUtil
     Executes CertUtil.exe using the defaults to download a remote file.
 
 .EXAMPLE
     Invoke-CertUtil -EncodeSwitchName decode -FileToDecode C:\certutil\encoded.txt -OutputDecodedFilePath C:\temp\calc.exe
     Utilizes CertUtil to decode base64 file to .exe
 
 .EXAMPLE
     Invoke-CertUtil -EncodehexSwitchName encodehex -FileToEncodehex c:\windows\system32\calc.exe -EncodedhexOutputFilePath C:\certutil\encodedhex.txt
 
 .EXAMPLE
     Invoke-CertUtil -FileToDecode C:\certutil\encode_clop.txt -EncodeSwitchName decode -OutputDecodedFilePath C:\certutil\orig.exe
 
 .EXAMPLE
     Invoke-CertUtil -EncodehexSwitchName decodehex -FileToDecodehex C:\certutil\encodedhex_clop.txt -OutputDecodedhexFilePath C:\certutil\clop_decode.exe
  #>
 
     [CmdletBinding(DefaultParameterSetName = 'CertUtilUri')]
     param (
         [Parameter(Mandatory, ParameterSetName = 'Encode')]
         [Parameter(Mandatory, ParameterSetName = 'Decode')]
         [String]
         [ValidateSet('encode', 'decode')]
         $EncodeSwitchName = 'encode',
 
         [Parameter(Mandatory, ParameterSetName = 'EncodeHex')]
         [Parameter(Mandatory, ParameterSetName = 'DecodeHex')] 
         [String]
         [ValidateSet('encodehex', 'decodehex')]
         $EncodehexSwitchName = 'encodehex',
 
         [Parameter(ParameterSetName = 'CertUtilUri')]
         [String]
         [ValidateNotNullOrEmpty()]
         $CertUtilUri = "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/LICENSE.txt",
 
         [Parameter(ParameterSetName = 'CertUtilUri')]
         [Parameter(ParameterSetName = 'Encode')]
         [Parameter(ParameterSetName = 'Decode')]
         [Parameter(ParameterSetName = 'EncodeHex')]
         [Parameter(ParameterSetName = 'DecodeHex')]
         [String]
         [ValidateNotNullOrEmpty()]
         $CertUtilFilePath = "$Env:windir\System32\certutil.exe",
 
         [Parameter(ParameterSetName = 'CertUtilUri')]
         [String]
         [ValidateSet('urlcache', 'verifyctl')]
         $method = 'urlcache',
 
         [Parameter(ParameterSetName = 'CertUtilUri')]
         [Parameter(ParameterSetName = 'Encode')]
         [Parameter(ParameterSetName = 'Decode')]
         [Parameter(ParameterSetName = 'EncodeHex')]
         [Parameter(ParameterSetName = 'DecodeHex')]
         [String]
         [ValidateSet('Hyphen', 'EnDash', 'EmDash', 'HorizontalBar', 'ForwardSlash', 'SmallLetteru')]
         $CommandLineSwitchType = 'Hyphen',
 
         [Parameter(ParameterSetName = 'CertUtilUri')]
         [string]
         $OutputFilePath,
 
         [Parameter(ParameterSetName = 'Decode')]
         [string]
         $OutputDecodedFilePath = "c:\temp\calc.exe",
 
         [Parameter(ParameterSetName = 'DecodeHex')]
         [string]
         $OutputDecodedhexFilePath = "c:\temp\calc.exe",
 
         [Parameter(Mandatory, ParameterSetName = 'Encode')]
         [String]
         [ValidateNotNullOrEmpty()]
         $FileToEncode = "c:\windows\system32\calc.exe",
 
         [Parameter(Mandatory, ParameterSetName = 'EncodeHex')]
         [String]
         [ValidateNotNullOrEmpty()]
         $FileToEncodehex = "c:\windows\system32\calc.exe",
 
         [Parameter(ParameterSetName = 'Encode')]
         [String]
         [ValidateNotNullOrEmpty()]
         $EncodedOutputFilePath = "C:\temp\test.txt",
 
         [Parameter(ParameterSetName = 'EncodeHex')]
         [String]
         [ValidateNotNullOrEmpty()]
         $EncodedhexOutputFilePath = "C:\temp\test.txt",
 
         [Parameter(Mandatory, ParameterSetName = 'Decode')]
         [String]
         [ValidateNotNullOrEmpty()]
         $FileToDecode,
 
         [Parameter(Mandatory, ParameterSetName = 'DecodeHex')]
         [String]
         [ValidateNotNullOrEmpty()]
         $FileToDecodehex
 
         )
 
     switch($CommandLineSwitchType) {
         'Hyphen'        { $SwitchChar = [Char] '-' }
         'EnDash'        { $SwitchChar = [Char] 0x2013 }
         'EmDash'        { $SwitchChar = [Char] 0x2014 }
         'HorizontalBar' { $SwitchChar = [Char] 0x2015 }
         'ForwardSlash'  { $SwitchChar = [Char] '/' }
         'SmallLetteru'  { $SwitchChar = [char] 0x00FB }
     }
 
 
 if ($PSCmdlet.ParameterSetName -eq 'CertUtilUri') { 
        
     $CertUtilCommandLine = "`"$CertUtilFilePath`" $SwitchChar$method -split -f $CertUtilUri $OutputFilePath"  
      $ProcStartResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $CertUtilCommandLine }  
        return
          
         }
 
 if ($PSCmdlet.ParameterSetName -eq 'Encode') {      
   
     $CertUtilCommandLine = "`"$CertUtilFilePath`" $SwitchChar$EncodeSwitchName $FileToEncode $EncodedOutputFilePath"  
      $ProcStartResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $CertUtilCommandLine }  
        return
          
         }
 
 if ($PSCmdlet.ParameterSetName -eq 'Decode') {        
 
     $CertUtilCommandLine = "`"$CertUtilFilePath`" $SwitchChar$EncodeSwitchName $FileToDecode $OutputDecodedFilePath"  
      $ProcStartResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $CertUtilCommandLine }  
        return
          
         }
 
 if ($PSCmdlet.ParameterSetName -eq 'EncodeHex') {      
   
     $CertUtilCommandLine = "`"$CertUtilFilePath`" $SwitchChar$EncodehexSwitchName $FileToEncodehex $EncodedhexOutputFilePath"  
      $ProcStartResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $CertUtilCommandLine }  
        return
          
         }
 
 if ($PSCmdlet.ParameterSetName -eq 'DecodeHex') {        
 
     $CertUtilCommandLine = "`"$CertUtilFilePath`" $SwitchChar$EncodehexSwitchName $FileToDecodehex $OutputDecodedhexFilePath"  
      $ProcStartResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $CertUtilCommandLine }  
        return
          
         }
 
 if ($PSCmdlet.ParameterSetName -eq 'AddCertificate') {    
 
     $cert = New-SelfSignedCertificate -DnsName atomicredteam.com -CertStoreLocation cert:\LocalMachine\My
     Export-Certificate -Type CERT -Cert  Cert:\LocalMachine\My\$($cert.Thumbprint) -FilePath #{pfx_path}
     Get-ChildItem Cert:\LocalMachine\My\$($cert.Thumbprint) | Remove-Item    
 
     $CertUtilCommandLine = "`"$CertUtilFilePath`" $SwitchChar$EncodehexSwitchName $FileToDecodehex $OutputDecodedhexFilePath"  
      $ProcStartResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $CertUtilCommandLine }  
        return
          
         }
 
 }
 
  
  
 