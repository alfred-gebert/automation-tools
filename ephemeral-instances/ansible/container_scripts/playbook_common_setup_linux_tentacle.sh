#/bin/bash

target_host_name=$1
[ -z "$target_host_name" ] && exit 1

curl --version || exit 1
python3 --version || exit 1

ls -la /scripts/

bash /scripts/update-git-repositories.sh

exit 0


short_hostname="${target_host_name%%.*}"
echo "Hostname: $target_host_name"
echo "Short Hostname: $short_hostname"

ansible_base_dir="/etc/ansible"

# Add Octopus Tentacle settings for the 'Ansible.Machine.Name'
environment_intern="$ansible_base_dir/environments/intern/"
host_vars_dir="$environment_intern/host_vars/$short_hostname"
mkdir -p $host_vars_dir || exit 1

host_vars_file="$host_vars_dir/main_$short_hostname.yml"
cat > $host_vars_file <<EOF
---
install_alloy_stage: "dev"
sot_tentacle_instance: "ess-auto-qa"
sot_environment_name: ""

...
# code: language=yaml
EOF

chown -R ansible:ansible $host_vars_dir
ls -l $host_vars_file
cat $host_vars_file


host_group_file="$environment_intern/sup_intern.yml"
cat > $host_group_file <<EOF
---
# temporaery inventory file

cloud:
  hosts:
    $short_hostname:
      ansible_host: $target_host_name

esswcs_linux:
  hosts:
    $short_hostname:
EOF

chown ansible:ansible $host_group_file
ls -l $host_group_file
cat $host_group_file

playbook_script="/tmp/$$_playbook-run.sh"
playbooks="$ansible_base_dir/playbooks"

echo "cd $playbooks || exit 1" > $playbook_script
chmod 750 $playbook_script
chgrp ansible $playbook_script
echo "export VAULT_PASSWORD=$(echo $vault_password_b64 | /usr/bin/base64 -d)" >> $playbook_script
echo "pwd" >> $playbook_script
echo "ansible-playbook common/setup_linux_tentacle.yml -l $short_hostname -i $environment_intern || exit 1" >> $playbook_script

cat $playbook_script

