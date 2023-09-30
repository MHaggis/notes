# NTLM Challenge Mimic Script - Fancy NTLM Relay

This PowerShell script simulates an NTLM challenge-response interaction but doesn't perform genuine authentication.

UPDATE: This script ended up being from Nishang - https://github.com/samratashok/nishang

How It Works:

- Listening for NTLM Headers: The script sets up an HTTP listener on localhost:8080. When a request with an Authorization NTLM header arrives, it logs the NTLM message.

- Static NTLM Challenge: Instead of generating a dynamic challenge, the script always responds with a pre-defined NTLM Type 2 challenge, regardless of the NTLM message type received.

- Logging: All received NTLM messages are logged to C:\temp\ntlm.txt for observation.

- Note: This script is designed for educational and observation purposes, capturing NTLM messages in transit. It doesn't validate or complete genuine NTLM authentication.

References:
- https://cert.gov.ua/article/5702579
- https://www.virustotal.com/gui/file/52951f2d92e3d547bad86e33c1b0a8622ac391c614efa3c5d167d8a825937179
- https://gist.github.com/MHaggis/52b090dbb9c2b91d9cdd8c54f2256f74
- https://github.com/Kevin-Robertson/Inveigh/tree/master
- https://www.virustotal.com/gui/file/5c08c1c1b7e089b172e30b9ad452bab7ce64ee48201f603fc96fd9c6e24db1dc

## Details

### NTLM Authentication Overview:

- NTLM Negotiation (Type 1 message):
  - The client sends an NTLM negotiation message to the server, indicating its capabilities and requesting the server to set up an authentication challenge.

- NTLM Challenge (Type 2 message):
  - In response to the negotiation message, the server sends back a challenge message. This message contains various pieces of information, including a randomly generated challenge string.

- NTLM Authentication (Type 3 message):
  - The client responds to the challenge with an authentication message. This message includes credentials (like username and domain) and a response to the server's challenge, which is generated using the user's password's hash.

### What fancyntlmrelay.ps1 Does:

When a client sends an HTTP request to your server, the script checks if the request has an Authorization header with an NTLM message.

If it finds an NTLM message (Type 1 or Type 3), it logs the message to a file.

Regardless of the actual content or type of the NTLM message received, the script then responds with a hard-coded NTLM Type 2 challenge message ($NTLMType2). This is not a real challenge, just a static value.

If the client continues the authentication process by sending a Type 3 message in response to the fake challenge, the script will again log the message to a file and send the same Type 2 message back.

### What Happens with a Real NTLM Client:

If a genuine client (like a web browser or an HTTP client configured for NTLM authentication) sends a Type 1 NTLM negotiation message to your script:

The script logs the Type 1 message to a file.

The script responds with the static Type 2 challenge message.

A genuine client will then respond with a Type 3 message, using the challenge provided and the user's hashed credentials.

The script will log this Type 3 message and then again send back the static Type 2 challenge.

Depending on the client's configuration and behavior, it might retry the authentication a few times (given that it keeps getting a challenge) or might eventually give up.

Key Takeaway:
fancyntlmrelay doesn't validate NTLM messages or complete a genuine NTLM authentication handshake. Instead, it logs NTLM messages it receives and always responds with a static Type 2 challenge. It's useful for capturing or observing NTLM messages but not for actual authentication.


## Start the fancyntlmrelay

`./fancyntlmrelay.ps1`

## Initiate request

```
$headers = @{
    'Authorization' = 'NTLM SOMENTLMMESSAGE'
}

Invoke-WebRequest -Uri "http://localhost:8080/" -Headers $headers
```

## Shutdown the listener

```
Invoke-WebRequest -Uri "http://localhost:8080/exit"
```
