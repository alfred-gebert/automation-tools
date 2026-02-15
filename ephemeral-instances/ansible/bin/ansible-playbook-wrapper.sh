#/bin/bash

playbook_script=$1
[ -z "$playbook_script" ] && exit 1
shift 1

if [ -z "$VAULT_PASSWORD_B64" ]; then
   cred_id=$1
   shift 1

   cred_file="/tmp/automation/.ansible-cred-$cred_id"
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

base_dir="/opt/automation"
cntr_scripts_dir="$base_dir/container_scripts"
# cntr_image=repo.sup-logistik.de/docker-private-releases/supcis-ansible-container:202503-x86
cntr_image=localhost/automation-ansible:latest
cntr_vol="-v $cntr_scripts_dir:/scripts:ro"
cntr_env="--env GIT_USER --env GIT_TOKEN --env GIT_BRANCH --env VAULT_PASSWORD_B64"
cntr_opts="--rm -t --security-opt label=disable --user ansible"
cntr_cmd="/scripts/$playbook_script"

podman run $cntr_opts $cntr_vol $cntr_env $cntr_image bash $cntr_cmd $playbook_args

exit 0
