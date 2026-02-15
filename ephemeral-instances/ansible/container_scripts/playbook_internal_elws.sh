#/bin/bash

target_host_name=$1
[ -z "$target_host_name" ] && exit 1

/scripts/update-git-repositories.sh || exit 1
/scripts/update_ssh_config.sh || exit 1
/scripts/update_loginmanagement_config.sh || exit 1

short_hostname="${target_host_name%%.*}"
echo "Hostname: $target_host_name"
echo "Short Hostname: $short_hostname"

ansible_base_dir="/etc/ansible"
playbooks_dir="$ansible_base_dir/playbooks"

# Add host-related environment settings for $short_hostname
environment_intern="$ansible_base_dir/environments/intern/"
host_vars_dir="$environment_intern/host_vars/$short_hostname"
mkdir -p $host_vars_dir || exit 1

host_vars_file="$host_vars_dir/main_$short_hostname.yml"
cat > $host_vars_file <<EOF
---
install_alloy_stage: "dev"
sot_tentacle_instance: "ess-automated-qa"
sot_environment_name: "sys-test-auto"

...
# code: language=yaml
EOF

chown -R ansible:ansible $host_vars_dir
# ls -l $host_vars_file
# cat $host_vars_file


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
# ls -l $host_group_file
# cat $host_group_file

cd $playbooks_dir || exit 1
ls -la internal/elws/

export VAULT_PASSWORD="$(echo $VAULT_PASSWORD_B64 | /usr/bin/base64 -d)"
ansible-playbook internal/elws/01_os_configuration_elws_linux.yml -l $short_hostname -i $environment_intern || exit 1
