#/bin/bash

ssh_config_file="$HOME/.ssh/config

echo "HOST *" >> $ssh_config_file
echo "    StrictHostKeyChecking no" >> $ssh_config_file
echo "    UserKnownHostsFile /dev/null" >> $ssh_config_file
