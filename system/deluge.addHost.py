#!/usr/bin/env python
#
# Deluge hostlist id generator
#
#   deluge.addHost.py
#
#

import hashlib
import sys
import time

hashlib.sha1(str(time.time())).hexdigest()
