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

# Assigning command-line arguments to variables
BASE_BRANCH=$1
RELEASE_BRANCH=$2

# Function to send notification to admin
send_notification() {
    echo "Notification to admin: $1"
    # Need to add actual notification logic here
    # Send a message to Teams or email
}

# # Set Git configuration for commits made by this script
# git config user.name ""
# git config user.email ""

# Ensure we're in the repository directory
# cd "${GITHUB_WORKSPACE}" || {
#     send_notification "Failed to change to GitHub workspace. Aborting."
#     exit 1
# }

# Fetch all branch history
git fetch --all

# Checkout the release branch and update
echo ">>> Checking out the release branch: $RELEASE_BRANCH ..."
git checkout "$RELEASE_BRANCH" || {
    send_notification "Failed to checkout release branch: $RELEASE_BRANCH. Aborting."
    exit 1
}

git pull origin "$RELEASE_BRANCH" || {
    send_notification "Failed to pull release branch: $RELEASE_BRANCH. Aborting."
    exit 1
}

# Check for .config file changes
echo ">>> Checking for .config file changes ..."
CONFIG_CHANGES=$(git diff --name-only "origin/$BASE_BRANCH...$RELEASE_BRANCH" | grep '.config$')
if [ ! -z "$CONFIG_CHANGES" ]; then
    send_notification "Aborted merge due to .config file changes between $BASE_BRANCH and $RELEASE_BRANCH."
    exit 0
fi

# Attempt to merge the release branch into the base branch
echo ">>> Attempting merge into the base branch: $BASE_BRANCH ..."
git checkout "$BASE_BRANCH" || {
    send_notification "Failed to checkout base branch: $BASE_BRANCH. Aborting."
    exit 1
}

git pull origin "$BASE_BRANCH" || {
    send_notification "Failed to pull base branch: $BASE_BRANCH. Aborting."
    exit 1
}

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
    exit 0
fi
