# Splunk Python SDK

I will admit I am not a developer. I have seen, read, and shouldersurfed multiple languages, but I have never focused enough to intently learn said languages. In this particular task, my research flow is as such: research, design and the end product. During my research phase I will work to understand what is available on the internet related to this task, what else have others done, issues and errors. The important part of research is understanding what others have done, and for me, understanding how the code works. The next phase is taking the objective of the task and breaking it into chunks. In this case, I need to learn how to query Splunk with the Python SDK and have an output (print). During this phase I begin to write barebones code to achieve my goal. It may not have comments yet, it may not have the exact output I expect or required, but the bare minimum is complete. Post Design and testing, my final objective is to ensure this actually works effectively, my code is commented accordingly.

My final output: [splunk_search.py](https://github.com/MHaggis/notes/blob/master/Splunk-Python-SDK/splunk_search.py)

Table of Contents
- [Splunk Python SDK](#splunk-python-sdk)
  - [Research](#research)
    - [Understand the basics of the Splunk SDK for Python](#understand-the-basics-of-the-splunk-sdk-for-python)
  - [Design](#design)
    - [service.jobs.create - Blocking Search](#servicejobscreate---blocking-search)
    - [service.jobs.oneshot - synchronous search](#servicejobsoneshot---synchronous-search)
  - [Final Thoughts](#final-thoughts)



## Research

### Understand the basics of the Splunk SDK for Python

Splunk Docs have an excellent step by step along with example scripts in the [SDK Repo](https://github.com/splunk/splunk-sdk-python/tree/master/examples).

Parts I've found that I'll be using:

- How to Connect via [Python SDK](https://dev.splunk.com/enterprise/docs/devtools/python/sdk-python/howtousesplunkpython/howtoconnectpython)

My base query to identify failed login attempts to a Splunk Search Head:

```
index=_internal  sourcetype=splunkd component=UiAuth |  table _time user clientip
```
How I got to this query:

I know that auth events and default errors and what not are stored in `_internal` (more details from Splunk on [What it logs about itself](https://docs.splunk.com/Documentation/Splunk/8.0.6/Troubleshooting/WhatSplunklogsaboutitself)). With that, I generated a failed login attempt with a username other than `Admin` - I used `Jack` - and then simply queried for:

`index=_internal jack`

From there, I identified the sourcetype (splunkd) and component (UiAuth). Once I got the events I needed to see, I finished my query by generated a table of time, user and clientip.


 - Identified [last_login.py](https://github.com/tccontre/python-splunk-sdk_example/blob/master/last_login.py) on github via querying for [splunk sdk python](https://github.com/search?q=splunk+sdk+python) examples on github. 

- Identified a resource [Splunk Search - SDK ](https://github.com/nikhil-rupanawar/splunk_search/blob/master/search.py) on github that provides the basics of how to perform a query

## Design

build a python script that:
- searches splunk indexes for failed login attempts in the last week to the splunk search head. 
- prints out the username, time and IP address of the users

My base test is to just connect:

Borrowed from [How to Connect - Python SDK](https://dev.splunk.com/enterprise/docs/devtools/python/sdk-python/howtousesplunkpython/howtoconnectpython).

The example provided is written for python 2.7. I went ahead and [converted](https://docs.python.org/3/library/2to3.html) it to Python3 by running `2to3-2.7 -w sdkconnect.py`. This is a basic auth script, therefore a quick conversion was no big deal.

```
# Import SDK client module
import splunklib.client as client

# Where to connect
HOST = "localhost"
PORT = 8089
USERNAME = "admin"
PASSWORD = "changeme"

# Create a Service instance and log in
service = client.connect(
    host=HOST,
    port=PORT,
    username=USERNAME,
    password=PASSWORD)

# Print installed apps to the console to verify login
for app in service.apps:
    print(app.name)
```
and now all the currently installed Apps are displayed:

```
...
alert_logevent
alert_webhook
appsbrowser
base64
botsv3_data_set
CiscoNVM
Code42ForSplunk
DA-ESS-ContentUpdate
decrypt
force_directed_viz
introspection_generator_addon
jellyfisher
...
```

I believe I have the connection part complete. Now I want to understand how to perform a query. In this case, because of the research I did previously, I sort of know what the final output will look like. I'm going to take a look at it now to see what it looks like in comparison. 

As of right now, I have do not have a class defined, functions created or error checking in place. All things that should come out after this design phase, if I was really good at Python (eek).

I am going to now focus on getting my query added to this and go from there. This is the part where I am getting stuck. I took a step back, re-read parts of [this](https://docs.splunk.com/DocumentationStatic/PythonSDK/1.6.13/client.html) and comparing to my [example](https://github.com/tccontre/python-splunk-sdk_example/blob/master/last_login.py), I think I'm going to start over with what I had.

I decided that, in a long round about way, that I probably need to go back to the basics and not focus on the final product so much. I took a step back and began to follow the [guide - How to run searches python](https://dev.splunk.com/enterprise/docs/devtools/python/sdk-python/howtousesplunkpython/howtorunsearchespython). After I got the basics down, my [initial script creates a normal search](https://dev.splunk.com/enterprise/docs/devtools/python/sdk-python/howtousesplunkpython/howtorunsearchespython#To-create-a-normal-search-poll-for-completion-and-display-results) (a job), it polls for the completion of said job, and then displays results. I know from reading other example scripts, there is a way to make this query faster using `service.jobs.oneshot` as outlined [here](https://dev.splunk.com/enterprise/docs/devtools/python/sdk-python/howtousesplunkpython/howtorunsearchespython#To-create-a-basic-one-shot-search-and-display-results). 

### [service.jobs.create - Blocking Search](https://dev.splunk.com/enterprise/docs/devtools/python/sdk-python/howtousesplunkpython/howtorunsearchespython#To-create-a-normal-search-poll-for-completion-and-display-results)

```
import sys
from time import sleep
import splunklib.results as results
import splunklib.client as client


service = client.connect(username="admin",
                         password="changeme",
                         # change this to ip address of machine where the splunk monitoring instance is located (remote splunk instance)
                         host="localhost",
                         port=8089
                         )


searchquery_normal = "search index=_internal  sourcetype=splunkd component=UiAuth |  table _time user clientip"
kwargs_normalsearch = {"earliest_time": "-7d", "latest_time": "now"}
job = service.jobs.create(searchquery_normal, **kwargs_normalsearch)

# A normal search returns the job's SID right away, so we need to poll for completion
while True:
    while not job.is_ready():
        pass
    stats = {"isDone": job["isDone"],
             "doneProgress": float(job["doneProgress"])*100,
             "scanCount": int(job["scanCount"]),
             "eventCount": int(job["eventCount"]),
             "resultCount": int(job["resultCount"])}

    status = ("\r%(doneProgress)03.1f%%   %(scanCount)d scanned   "
              "%(eventCount)d matched   %(resultCount)d results") % stats

    sys.stdout.write(status)
    sys.stdout.flush()
    if stats["isDone"] == "1":
        sys.stdout.write("\n\nDone!\n\n")
        break
    sleep(2)

# Get the results and display them
for result in results.ResultsReader(job.results()):
    print(result)

job.cancel()
sys.stdout.write('\n')

```

Output:

```
root@ubuntu:/opt/splunk-sdk-python# python3 search_logins.py 
100.0%   15 scanned   2 matched   2 results

Done!

OrderedDict([('_time', '2020-10-13T16:02:30.428+00:00'), ('user', 'jack'), ('clientip', '52.1.210.251')])
OrderedDict([('_time', '2020-10-08T12:41:06.177+00:00'), ('user', 'admin'), ('clientip', '174.27.198.9')])
```

I feel I have a solid plan right now. I have completed:
- [x] Log into Splunk with Python
- [x] Query Splunk and get results
- [x] prints out the username, time and IP address of the users


### service.jobs.oneshot - synchronous search

Following the above, I want to now make this faster and not require a job by use `service.jobs.oneshot`. Per the guide, this is "The simplest way to get data out of Splunk Enterprise is with a one-shot search". 

At this point I'm starting to feel comfortable with what I am doing. First try, I got this to run and produce output:

```
import sys
from time import sleep
import splunklib.results as results
import splunklib.client as client


service = client.connect(username="admin",
                         password="changeme",
                         # change this to ip address of machine where the splunk monitoring instance is located (remote splunk instance)
                         host="localhost",
                         port=8089
                         )

# Run a one-shot search and display the results using the results reader

# Set the parameters for the search:
# - Search everything in a 24-hour time range starting June 19, 12:00pm
# - Display the first 10 results
kwargs_oneshot = {"earliest_time": "-7d", "latest_time": "now"}
searchquery_oneshot = "search index=_internal  sourcetype=splunkd component=UiAuth |  table _time user clientip"

oneshotsearch_results = service.jobs.oneshot(searchquery_oneshot, **kwargs_oneshot)

# Get the results and display them using the ResultsReader
reader = results.ResultsReader(oneshotsearch_results)
for item in reader:
    print(item)
```

Output:

```
root@ubuntu:/opt/splunk-sdk-python# python3 oneshot.py 
OrderedDict([('_time', '2020-10-13T16:02:30.428+00:00'), ('user', 'jack'), ('clientip', '52.1.210.251')])
OrderedDict([('_time', '2020-10-08T12:41:06.177+00:00'), ('user', 'admin'), ('clientip', '174.27.198.9')])
```
Now, per the last item on the guide, manipulating the data with the `ResultsReader`. 

last one:

```
import sys
from time import sleep
import splunklib.results as results
import splunklib.client as client


service = client.connect(username="admin",
                         password="changeme",
                         # change this to ip address of machine where the splunk monitoring instance is located (remote splunk instance)
                         host="localhost",
                         port=8089
                         )

# Run a one-shot search and display the results using the results reader

# Set the parameters for the search:
# - Search everything in a 24-hour time range starting June 19, 12:00pm
# - Display the first 10 results
kwargs_oneshot = {"earliest_time": "-7d", "latest_time": "now"}
searchquery_oneshot = "search index=_internal  sourcetype=splunkd component=UiAuth |  table _time user clientip"

oneshotsearch_results = service.jobs.oneshot(searchquery_oneshot, **kwargs_oneshot)

reader = results.ResultsReader(oneshotsearch_results)
for result in reader:
    if isinstance(result, dict):
        print "Result: %s" % result
    elif isinstance(result, results.Message):
        # Diagnostic messages may be returned in the results
        print "Message: %s" % result

# Print whether results are a preview from a running search
print "is_preview = %s " % reader.is_preview
```

Output:

```
root@ubuntu:/opt/splunk-sdk-python# python3 results.py
Result: OrderedDict([('_time', '2020-10-13T16:02:30.428+00:00'), ('user', 'jack'), ('clientip', '52.1.210.251')])
Result: OrderedDict([('_time', '2020-10-08T12:41:06.177+00:00'), ('user', 'admin'), ('clientip', '174.27.198.9')])
is_preview = False 
```

I believe it is now time to get the formatting correct. 

Looking at the [example-last_login.py](https://github.com/tccontre/python-splunk-sdk_example/blob/master/last_login.py) I don't believe this example is using the `ResultsReader` at all. It's only taking the xml output and using `xml.etree.ElementTree`. Which I guess makes sense, but because I have no experienece with this, I'm going to try my best to get the output I want. 

After googling for a few minutes, I believe the reason to use `xml.etree.ElementTree` is because `ResultsReader` doesn't have much other than dumping the data(?). I will now figure out how to use `xml.etree.ElementTree` based on the example referenced here and [Python docs](https://docs.python.org/2/library/xml.etree.elementtree.html).

I spent quite a bit of time attempting to resolve this with `xml.etree.ElementTree` and I am struggling. In the end of it all, I assume if I was using a python ise it may make more sense, but I just don't have the full skills to poke at the data like that just yet. I went on a google chase looking for ways to parse xml. That's when I realized that the [splunklib.results](https://docs.splunk.com/DocumentationStatic/PythonSDK/1.6.13/results.html#) module can dump to json. I tried to figure that out and came across this [result](https://stackoverflow.com/questions/62312428/python-json-data-from-splunk) but that appeared to be a whole _another_ way of solving our task. 

I ended up finding a _new_ way (to me) to parse the xml. While viewing this [response](https://stackoverflow.com/a/62334885) it highlighted the use of [Python Pandas](https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.html) and that instantly made me curious. I imported the module and install it via pip3 (`pip3 install pandas`) and my result:


```
import sys
import splunklib.results as results
import splunklib.client as client
import pandas as pd


service = client.connect(username="admin",
                         password="changeme",
                         # change this to ip address of machine where the splunk monitoring instance is located (remote splunk instance)
                         host="localhost",
                         port=8089
                         )

# Run a one-shot search and display the results using the results reader

# Set the parameters for the search:
# - Search everything in a 30 day time range
kwargs_oneshot = {"earliest_time": "-30d", "latest_time": "now"}
searchquery_oneshot = "search index=_internal  sourcetype=splunkd component=UiAuth |  table _time user clientip"

oneshotsearch_results = service.jobs.oneshot(searchquery_oneshot, **kwargs_oneshot)

# Get the results and display them using the ResultsReader
#reader = results.ResultsReader(oneshotsearch_results)
#for item in reader:
#    print(item)

reader = results.ResultsReader(oneshotsearch_results)

df = pd.DataFrame(reader)
print(df)
```

Output:

```
                           _time   user       clientip
0  2020-10-13T16:02:30.428+00:00   jack   52.1.210.251
1  2020-10-08T12:41:06.177+00:00  admin   174.27.198.9
2  2020-10-02T20:58:47.728+00:00  admin  75.174.160.17
```

and with that - we can also add at the end of our script to output to CSV for further data manipulation:

`df.to_csv('results.csv')` 

## Final Thoughts

The following is a list of things I'd like to better understand to generate a great working script:

- Functions within Python. Understanding how to use multiple functions in a single script to solve my problem.
- Input arguments. I believe this script could go next level by having custom "search" queries added on the fly similar to [example search](https://github.com/splunk/splunk-sdk-python/blob/master/examples/search.py)
- File with multiple queries. Take file on disk, grab each line and query each in Splunk.
- Time range. Define time picker as an argument.
- XML parsing. I would like to better understand the data from Splunk in XML and how to better parse it in Python.


Overall, I believe in the time I put into this, going from never using the Splunk Python SDK to generating a script was a success. I learned quite a bit about some Python basics with Python, found some great resources, and was able to use the example SDK scripts. 

A [blog by Josh Liburdi](https://medium.com/@jshlbrd/hunting-for-powershell-using-heatmaps-69b70151fa5d) I read a long time ago uses Pandas heat maps to identify behaviors across endpoints using Powershell. Pandas is something I am aware of and new to, but I find it very fascinating from an analysis perspective. 
