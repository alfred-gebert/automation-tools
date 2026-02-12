#/bin/bash

ansible_base_dir="/etc/ansible"
# git_branch="feature/ess-deployment"

git_credentials="env --username=$GIT_USER --password=$GIT_TOKEN"
sudo -u ansible -- git config credential.helper "$git_credentials"

# Updating all Ansible repositories
for dir in environments playbooks roles; do
    git_dir="$ansible_base_dir/$dir"
    echo "Git repository: $git_dir"
    
    # if [ ! -z "$git_branch" ]; then
    #     echo "Switching to branch $git_branch ..."
    #     ( cd $git_dir && sudo -u ansible -- git switch $git_branch )
    # fi
    
    # echo "Pulling latest commits ..."
    # ( cd $git_dir && sudo -u ansible -- git pull )
    
    ( cd $git_dir && sudo -u ansible -- git status )
done
