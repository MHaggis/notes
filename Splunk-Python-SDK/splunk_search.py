"""
Basic script to connect to Splunk via Python SDK and perform a query with Pandas output.
More details here: https://github.com/MHaggis/notes/blob/master/Splunk-Python-SDK/
"""

# Built-in/Generic Imports
import sys

# Libs
import splunklib.results as results
import splunklib.client as client
import pandas as pd

__author__ = 'mhaggis'


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

oneshotsearch_results = service.jobs.oneshot(searchquery_oneshot, **kwargs_oneshot) # Our results

# Another way to output the data using splunklib.results
# Get the results and display them using the ResultsReader
#reader = results.ResultsReader(oneshotsearch_results)
#for item in reader:
#    print(item)

reader = results.ResultsReader(oneshotsearch_results)
# Convert results to Pandas DataFrame
df = pd.DataFrame(reader)
print(df) # Print sweet output
df.to_csv('results.csv') # output results to a csv for further manipulation
