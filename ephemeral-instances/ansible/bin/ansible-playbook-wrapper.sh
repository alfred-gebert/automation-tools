#/bin/bash

playbook_script=$1
[ -z "$playbook_script" ] && exit 1
shift 1

playbook_args="$@"

if [ -z "$GIT_USER" ]; then
   echo "GIT_USER is not defined"
   exit 1
fi

if [ -z "$GIT_TOKEN" ]; then
   echo "GIT_TOKEN is not defined"
   exit 1
fi

# if [ -z VAULT_PASSWORD ]; then

ansbile_base_dir="/opt/ansible"
ansbile_bin_dir="$ansbile_base_dir/bin"
ansbile_container_scripts_dir="$ansbile_base_dir/container_scripts"
ansible_image=repo.sup-logistik.de/docker-private-releases/supcis-ansible-container:202503-x86
container_vol="-v $ansbile_container_scripts_dir:/scripts:z,ro"
container_env="--env GIT_USER --env GIT_TOKEN"

podman run --rm -t $container_vol $container_env $ansible_image bash /scripts/$playbook_script $playbook_args

# podman create --name $container_name $ansible_image || exit 1
# podman start --volume $ansbile_container_scripts_dir:/scripts $container_name || exit 1
# podman exec -i $container_name bash -c /scripts/update-git-repositories.sh
# podman stop $container_name || exit 1
# podman rm $container_name || exit 1

exit 0
