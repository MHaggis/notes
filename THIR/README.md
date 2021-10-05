# Mining The Shadows with ZoidbergStrike: A Scanner for Cobalt Strike - SANS Threat Hunting Summit


## Cobalt Strike Notes and Resources

- Pipes: https://gist.github.com/MHaggis/a725aed9800bca40904822b8c89ed269
- Spawnto: https://gist.github.com/MHaggis/dc1f1c2ebbe884bb27065479321b06b8 
- Compile_Time: https://gist.github.com/MHaggis/d81454df71b3ffc58145a8bb3ca9623e
- DNS Idle: https://gist.github.com/MHaggis/e848699e8481fae48eae4524cf0085e1
- Latest profile list: https://gist.github.com/MHaggis/921a4a47de1adab7eec938b4597f0be3
- Prior profile list: https://gist.github.com/MHaggis/6c600e524045a6d49c35291a21e10752

## Attack Data
- https://github.com/splunk/attack_data/blob/master/datasets/attack_techniques/T1055/cobalt_strike/cobalt_strike.yml
- https://github.com/splunk/attack_data/blob/master/datasets/attack_techniques/T1572/cobalt_strike/cobalt_strike.yml 

## Resources
- [@MichalKoczwara](https://twitter.com/MichalKoczwara)
- [Cobalt Strike Indicators | IronNet Threat Research](https://github.com/IronNetCybersecurity/IronNetTR/tree/main/cobalt_strike)
- [Awesome CobaltStrike Defence | Michael Koczwara](https://github.com/MichaelKoczwara/Awesome-CobaltStrike-Defence)
- [Pointer - Hunting and mapping Cobalt Strike](https://github.com/shabarkin/pointer)
- [Conti Leaks usage](https://twitter.com/M_haggis/status/1424780941059235851?s=20)
- [Keynote: Cobalt Strike Threat Hunting | Chad Tilbury](https://www.youtube.com/watch?v=borfuQGrB8g)
- https://github.com/shabarkin/pointer
- [Cobalt Strike Profiles | Zsec](https://blog.zsec.uk/cobalt-strike-profiles/)
- [Malleable C2 Help | Cobalt Strike](https://cobaltstrike.com/help-malleable-c2)
- [Guide to Named Pipes and Hunting for Cobalt Strike Pipes | svch0st](https://svch0st.medium.com/guide-to-named-pipes-and-hunting-for-cobalt-strike-pipes-dc46b2c5f575)
- [Cobalt Strike Defenders Guide | The DFIR Report](https://thedfirreport.com/2021/08/29/cobalt-strike-a-defenders-guide/)
- [Learn pipe fitting for all of your offense projects | Cobalt Strike](https://blog.cobaltstrike.com/2021/02/09/learn-pipe-fitting-for-all-of-your-offense-projects/)
- [Malleable C2 | ThreatExpress](https://github.com/threatexpress/malleable-c2)
- [Detecting Cobalt Strike Default Modules via Named Pipe Analysis | F-Secure](https://labs.f-secure.com/blog/detecting-cobalt-strike-default-modules-via-named-pipe-analysis/)
- https://twitter.com/cyb3rops/status/1417434947779022863
- [Knock, Knock, Neo. - Active C2 Discovery Using Protocol Emulation | @cci_forensics Takahiro Haruyama](https://jsac.jpcert.or.jp/archive/2021/pdf/JSAC2021_201_haruyama_jp.pdf)



## System32 Baselining 
- [System32 Binaries | Red Canary](https://redcanary.com/blog/system32-binaries)



```
 $system32 = Get-ChildItem -Path C:\windows\System32\ -Include '*.exe' -Recurse -ErrorAction SilentlyContinue |

 % {

             [PSCustomObject] @{
                 file_name = $_.name
                 file_path = $_.FullName
                 InternalName = $_.VersionInfo.InternalName
                 fileDescription = $_.VersionInfo.FileDescription
             }
 }

 $system32 | Export-Csv -Path ~\Desktop\data.csv
 ```
 
 
 
  To see the objects, I just ran: 
 $system32 | format-list
 
 example output

 ```
 ...
file_name       : UsoClient.exe
file_path       : C:\windows\System32\UsoClient.exe
InternalName    : UsoClient
fileDescription : UsoClient
Product         :
...
```

## Git Search


```
from github import Github

ACCESS_TOKEN = 'TOKEN HERE'

g = Github(ACCESS_TOKEN)

def search_github(keyword):
    rate_limit = g.get_rate_limit()
    rate = rate_limit.search
    if rate.remaining == 0:
        print(f'You have 0/{rate.limit} API calls remaining. Reset time: {rate.reset}')
        return
    else:
        print(f'You have {rate.remaining}/{rate.limit} API calls remaining')

    query = f'"{keyword}" in:file'
    result = g.search_code(query, order='desc')

    max_size = 100
    print(f'Found {result.totalCount} file(s)')
    if result.totalCount > max_size:
        result = result[:max_size]

    for file in result:
        print(f'{file.download_url}')


if __name__ == '__main__':
    keyword = input('Enter keyword[spawnto_x86, spawnto_x64, pipename, dns_idle]: ')
    search_github(keyword)
```

I use PowerShell to download the the files:

```
gc results.txt | % {iwr $_ -outf $(split-path $_ -leaf)}
```

Simple grep



```
$csprofiles=~\Desktop\profiles\*.profile
 Get-ChildItem -Path $csprofiles -Recurse | Select-String -Pattern 'set uri' -CaseSensitive | sort |  Get-Unique
```