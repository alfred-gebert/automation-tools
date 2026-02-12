#/bin/bash

ansible_base_dir="/etc/ansible"
github_owner_url="https://github.com/Element-Logic"
# git_branch="feature/ess-deployment"

# Setup HTTPS access for all Git repositories
environments_github_url="$github_owner_url/automation-ansible-inventory.git"
( cd $ansible_base_dir/environments && git remote set-url origin $environments_github_url )

playbooks_github_url="$github_owner_url/automation-ansible-playbooks.git"
( cd $ansible_base_dir/playbooks && git remote set-url origin $playbooks_github_url )

roles_github_url="$github_owner_url/automation-ansible-roles.git"
( cd $ansible_base_dir/roles && git remote set-url origin $roles_github_url )

# Setup Git credentials
mkdir $HOME/bin
git_pass_script=$HOME/bin/git_token
echo "echo $GIT_TOKEN" > $git_pass_script
chmod +x $git_pass_script
export GIT_ASKPASS="$git_pass_script"
git config --global credential.https://github.com.username $GIT_USER

# Updating all Ansible repositories
for dir in environments playbooks roles; do
    git_dir="$ansible_base_dir/$dir"
    echo "Git repository: $git_dir"
    
    # if [ ! -z "$git_branch" ]; then
    #     echo "Switching to branch $git_branch ..."
    #     ( cd $git_dir && sudo -u ansible -- git switch $git_branch )
    # fi
    
    echo "Pulling latest commits ..."
    ( cd $git_dir && git pull )
    ( cd $git_dir && git status )
done
