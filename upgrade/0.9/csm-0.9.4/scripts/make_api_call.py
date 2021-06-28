# Copyright (C) 2021 Hewlett Packard Enterprise Development LP

import json
import os
import requests
from requests.auth import HTTPBasicAuth
import sys
import warnings

# Read in username, password, vendor, method, url, and payload from environment variables
# Payload may not be set, but that's okay -- we only look at it if the method
# is post or patch, in which case it needs to be set
user=os.environ['USERNAME']
pw=os.environ['IPMI_PASSWORD']
vendor=os.environ['VENDOR']
try:
    payload=os.environ['payload']
except KeyError:
    payload = "null"
url=os.environ['url']
method=os.environ['method']

# Determine the requests module function we will be calling.
# Even though the script currently only makes get, patch, and post calls, no reason
# not to include delete and put, in case they are needed in the future
if method.lower() == "delete":
    rfunc = requests.delete
elif method.lower() == "get":
    rfunc = requests.get
elif method.lower() == "patch":
    rfunc = requests.patch
elif method.lower() == "post":
    rfunc = requests.post
elif method.lower() == "put":
    rfunc = requests.put
else:
    raise AssertionError("Invalid method specified: %s" % method)

# Build up initial argument list for request call
kwargs = {
    "url": url,
    "auth": HTTPBasicAuth(user, pw),
    "verify": False,
    "allow_redirects": True }

if payload != "null":
    # Convert to JSON and add to argument list
    kwargs["json"] = json.loads(payload)

# Build up our headers
if method in { "patch", "post" }:
    headers = dict()
    headers["Content-Type"] = "application/json"
    headers["Accept"] = "application/json"

    # We use the same vendor check that is used in the set-bmc-ntp-dns.sh script to determine
    # whether or not this is Gigabyte
    if -1 < vendor.find("GIGA") < vendor.find("BYTE"):
        # Adding this header based on this comment in the shell script:
        # GIGABYTE seems to need If-Match headers.  For now, just accept * all since we don't 
        # know yet what they are looking for
        headers["If-Match"] = "*"

    # Add the headers to our request argument list
    kwargs["headers"] = headers

# Make the request
with warnings.catch_warnings():
    warnings.simplefilter('ignore', category=requests.packages.urllib3.exceptions.InsecureRequestWarning)
    resp = rfunc(**kwargs)

# Just as with the curl command this script is replacing, we do not validate the status
# code. However, to aid in debugging, we do print a warning if the status code is not in the
# 200s. We print it to stderr since this script is typically piped to jq
if not 200 <= resp.status_code <= 299:
    print("WARNING: %s request to %s returned status code %d" % (method, url, resp.status_code), file=sys.stderr)

# Print the response body and exit
print(resp.text)