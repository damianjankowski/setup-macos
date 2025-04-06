#!/bin/bash

if [ -f ".env" ]; then
  echo "Loading .env variables..."
  set -o allexport
  source .env
  set +o allexport
else
  echo ".env file not found. Exiting."
  exit 1
fi

# Credentials
personal_name="$PERSONAL_NAME"
personal_email="$PERSONAL_EMAIL"
work_name="$WORK_NAME"
work_email="$WORK_EMAIL"

# Directories
main_gitconfig="$HOME/.gitconfig"
personal_gitconfig="$HOME/.gitconfig-personal"
work_gitconfig="$HOME/.gitconfig-work"

# Create main gitconfig
echo "Creating ~/.gitconfig"
cat > "$main_gitconfig" <<EOF
[user]
    name = $work_name
    email = $work_email

[credential]
    helper = osxkeychain

[includeIf "gitdir:~/src/"]
    path = $personal_gitconfig

[includeIf "gitdir:~/repo/"]
    path = $work_gitconfig
EOF

# Create personal gitconfig
echo "Creating ~/.gitconfig-personal"
cat > "$personal_gitconfig" <<EOF
[user]
    name = $personal_name
    email = $personal_email

[credential]
    helper = osxkeychain
EOF

# Create work gitconfig
echo "Creating ~/.gitconfig-work"
cat > "$work_gitconfig" <<EOF
[user]
    name = $work_name
    email = $work_email

[credential]
    helper = osxkeychain
EOF

echo -e "\nGit identity"
echo "Work repos → ~/repo/  (uses $work_email)"
echo "Personal repos → ~/src/  (uses $personal_email)"
