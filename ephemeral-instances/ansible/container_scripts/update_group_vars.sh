#/bin/bash

ansible_base_dir="/etc/ansible"
environment_intern="$ansible_base_dir/environments/intern/"
group_vars_file="$environment_intern/group_vars/all/all.yml"

cat >> $group_vars_file <<EOF

# EL RPM repositories
setup_el_repo_internal: true
setup_el_repo_stable: true
setup_el_repo_testing: true
EOF

grep setup_el_repo $group_vars_file
[ $? -eq 0 ] || exit 1

exit 0


