#/bin/bash

ansible_base_dir="/etc/ansible"
loginmanagement_defaults_file="$ansible_base_dir/roles/loginmanagement/defaults/main.yml"

ls -la $loginmanagement_defaults_file
cat $loginmanagement_defaults_file
grep loginmanagement_ldap_uri $loginmanagement_defaults_file

sed -i 's|^\(loginmanagement_ldap_uri:[[:space:]]*"\)[^"]*\(".*\)$|\1ldap://host.containers.internal:8389\2|' $loginmanagement_defaults_file
[ $? -eq 0 ] || exit 1

grep loginmanagement_ldap_uri $loginmanagement_defaults_file

exit 0
