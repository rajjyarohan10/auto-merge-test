#!/bin/bash

: <<'COMMENT'
    Author: Rajjya Rohan Paudyal, Runway Engineers
    Story: (S-386445) Implementation - Auto merge of branch from release to master, develop
    Description: 
        This script is being called from the excell release tool
COMMENT

# Check for the correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <base_branch> <release_branch>"
    exit 1
fi

# # Configuration Git with a specific user name and email
# git config user.name "rajjyarohan10"
# git config user.email "rajjyarohan@gmail.com"

# Assigning command-line arguments to variables
BASE_BRANCH=$1
RELEASE_BRANCH=$2

# Function to send notification to admin
send_notification() {
    echo "Notification to admin: $1"
}

# # Ensuring we're in the repository directory (GitHub Actions runner starts in the root of the repository)
# cd "$(dirname "$0")/../../" || exit

# Stash any uncommitted changes
echo ">>> Stashing any uncommitted changes ..."
git stash push -m "Auto-stash by auto_merge.sh"

# Checkout the release branch and update
echo ">>> Checking out the release branch: $RELEASE_BRANCH ..."
git fetch origin
git checkout "$RELEASE_BRANCH" || exit
git pull origin "$RELEASE_BRANCH" || send_notification "Failed to pull release branch: $RELEASE_BRANCH"

# Check for .config file changes
echo ">>> Checking for .config file changes ..."
CONFIG_CHANGES=$(git diff --name-only "origin/$BASE_BRANCH...$RELEASE_BRANCH" | grep '.sfdx-json$')
if [ ! -z "$CONFIG_CHANGES" ]; then
    send_notification "Aborted merge due to .config file changes between $BASE_BRANCH and $RELEASE_BRANCH."
    git stash pop # Optional: pop the stash if you want to restore the changes after detecting config changes
    exit 0
fi

# .config folder
# any thing except "force app main default"


# Attempt to merge the release branch into the base branch
echo ">>> Attempting merge into the base branch: $BASE_BRANCH ..."
git checkout "$BASE_BRANCH" || exit
git pull origin "$BASE_BRANCH" || send_notification "Failed to pull base branch: $BASE_BRANCH"
MERGE_RESULT=$(git merge --no-ff --strategy-option=ours "$RELEASE_BRANCH" 2>&1)
if [ $? -eq 0 ]; then
    echo "Successfully merged $RELEASE_BRANCH into $BASE_BRANCH."
    git push origin "$BASE_BRANCH"
else
    echo "$MERGE_RESULT"
    if [[ $MERGE_RESULT == *"Automatic merge failed"* ]]; then
        send_notification "Merge conflict detected when merging $RELEASE_BRANCH into $BASE_BRANCH. Merge aborted."
    fi
    git merge --abort
fi

# Pop the stash to restore uncommitted changes
echo ">>> Restoring uncommitted changes ..."
git stash pop || echo "No stash entries found."

exit 0
