#/bin/bash

ansible_base_dir="/etc/ansible"

# Setup HTTPS access for all Git repositories
github_owner_url="https://github.com/Element-Logic"
[ -z "$GITHUB_OWNER" ] || github_owner_url="https://github.com/$GITHUB_OWNER"

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
    
    # Check if we have an alternate branch
    if [ ! -z "$GIT_BRANCH" ]; then
        remote_branch="origin/$GIT_BRANCH"
        echo "Checking for branch $remote_branch"
        ( cd $git_dir && git fetch origin "$GIT_BRANCH" )
        if [ $? -eq 0 ]; then
            echo "Switching to branch $remote_branch ..."
            ( cd $git_dir && git checkout --track $remote_branch )
            [ $? -eq 0 ] || exit 1
        fi
    fi
    
    echo "Pulling latest commits ..."
    ( cd $git_dir && git pull --stat 2>&1 | grep -E 'files? changed' | head -n 1 ) || exit 1
    ( cd $git_dir && git status )
done
