#/bin/bash

if [ -z "$GH_WF_TOKEN" ]; then
   cred_id=$1
   shift 1

   cred_file="/tmp/automation/.terraform-cred-$cred_id"
   if [ ! -e "$cred_file" ]; then
       echo "create-instance: $cred_file not found"
       echo "create-instance: GH_WF_TOKEN is not defined"
       exit 1
   else
        source $cred_file
   fi
fi

command_args="$@"
base_dir="/opt/automation"
bin_dir="$base_dir/bin"
config_file="$base_dir/config/ephemeral-instances.json"
export GH_WF_URL="https://api.github.com/repos/Element-Logic/automation-terraform-aws-internal/dispatches"
export GH_WF_TOKEN

$bin_dir/instance-mgmt.py add --file $config_file $command_args

exit 0
