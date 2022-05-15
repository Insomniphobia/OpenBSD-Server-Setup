#!/bin/bash

#Please channge the following variables to match your own details
remote_machine_root_password="Enter Password here"
doas_user=fooname
server_ip=192.168.1.1
public_key=$(cat ~/.ssh/id_ecdsa.pub)

#Packages needed for script to work
which sshpass > /dev/null 2>&1

#sshpass_installed?
if [ $? != 0 ]; then echo "sshpass is not installed. Please install and this script again"; exit 1; fi

#Install needed packages
sshpass -p $remote_machine_root_password ssh -t root@$server_ip 'pkg_add python ansible-core'

#Add a user with doas permissions to remote server
sshpass -p $remote_machine_root_password ssh -t root@$server_ip 'useradd -g wheel -s /bin/sh -d /home/'$doas_user' -m '$doas_user' '
sshpass -p $remote_machine_root_password ssh -t root@$server_ip 'touch /etc/doas.conf && echo permit nopass :wheel > /etc/doas.conf'

#Enable SSH
sshpass -p $remote_machine_root_password ssh -t root@$server_ip 'sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication yes|"  /etc/ssh/sshd_config'
sshpass -p $remote_machine_root_password ssh -t root@$server_ip 'echo '$public_key' >> /home/'$doas_user'/.ssh/authorized_keys'
sshpass -p $remote_machine_root_password ssh -t root@$server_ip 'rcctl restart sshd'


#Test SSH
ssh -t $doas_user@$server_ip 'exit'
last_log=$(ssh -t $doas_user@$server_ip 'tail -n 1 /var/log/authlog')
if [[ $last_log == *"Accepted publickey for 0 "$doas_user* ]]; then echo "User is unable to log in via ssh. Abort the script as proceeding further will lock you out of the remote machine"; exit 1; fi
if [ $? != 0 ]; then echo "Public key not found. Please either generate your public key or ensure that the variable public_key_name is not misspelled"; exit 1; fi

#Hardening
ssh -t $doas_user@$server_ip 'doas sed -i "s|#PasswordAuthentication yes|PasswordAuthentication no|"  /etc/ssh/sshd_config' 


