#/bin/bash

playbook_script=$1
[ -z "$playbook_script" ] && exit 1
shift 1

if [ -z "$VAULT_PASSWORD_B64" ]; then
   cred_id=$1
   shift 1

   cred_file="$HOME/.ansible-playbook-cred-$cred_id"
   if [ ! -e "$cred_file" ]; then
       echo "VAULT_PASSWORD_B64 is not defined"
       exit 1
   else
        source $cred_file
   fi
fi

playbook_args="$@"

if [ -z "$GIT_USER" ]; then
   echo "GIT_USER is not defined"
   exit 1
fi

if [ -z "$GIT_TOKEN" ]; then
   echo "GIT_TOKEN is not defined"
   exit 1
fi

if [ -z "$VAULT_PASSWORD_B64" ]; then
   echo "VAULT_PASSWORD_B64 is not defined"
   exit 1
fi

ansbile_base_dir="/opt/ansible"
ansbile_bin_dir="$ansbile_base_dir/bin"
ansbile_container_scripts_dir="$ansbile_base_dir/container_scripts"
ansible_image=repo.sup-logistik.de/docker-private-releases/supcis-ansible-container:202503-x86
container_vol="-v $ansbile_container_scripts_dir:/scripts:z,ro"
container_env="--env GIT_USER --env GIT_TOKEN --env VAULT_PASSWORD_B64"

podman run --rm --user ansible -t $container_vol $container_env $ansible_image bash /scripts/$playbook_script $playbook_args

exit 0
