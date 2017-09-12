#!/usr/bin/expect -f
set timeout -1
spawn apt-get -y upgrade
match_max 100000
expect -nocase "*A new version*of configuration file*is available, but the version*installed currently*has*been locally modified*What do you want to do about modified configuration file*keep the local version currently installed*"
send -- "\r"
expect eof
