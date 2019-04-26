#!/usr/bin/expect
spawn read -s -r -p "Password: " PASSWORD
expect "Password: "
send "shj190810"
echo $PASSWORD
