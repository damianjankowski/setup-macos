basic_git_config() {
	parse_env
	PERSONAL_NAME=$(get_env_value "PERSONAL_NAME")
	PERSONAL_EMAIL=$(get_env_value "PERSONAL_EMAIL")
	
	log_info "Retrieved PERSONAL_NAME: '$PERSONAL_NAME'"
	log_info "Retrieved PERSONAL_EMAIL: '$PERSONAL_EMAIL'"
	
    cat > ~/.gitconfig << EOF
[user]
    name = ${PERSONAL_NAME}
    email = ${PERSONAL_EMAIL}

[credential]
    helper = osxkeychain

[init]
    defaultBranch = main

[pull]
    rebase = false

[push]
    default = simple

[core]
    autocrlf = input
    editor = nvim
    pager = delta

[interactive]
    diffFilter = delta --color-only

[include]
    path = ~/.config/delta/catppuccin.gitconfig

[delta]
    navigate = true
    side-by-side = true
    # dark = true 
    features = catppuccin-mocha

[color]
    ui = auto

# [includeIf "gitdir:~/src/"]
#     path = $HOME/.gitconfig-personal

# [includeIf "gitdir:~/work/"]
#     path = $HOME/.gitconfig-work

[gpg]
    format = ssh

[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign

[commit]
    gpgsign = false
EOF
}

work_git_config() {
	parse_env
	WORK_NAME=$(get_env_value "WORK_NAME")
	WORK_EMAIL=$(get_env_value "WORK_EMAIL")
	
	log_info "Retrieved WORK_NAME: '$WORK_NAME'"
	log_info "Retrieved WORK_EMAIL: '$WORK_EMAIL'"
    
    cat > ~/.gitconfig << EOF
[user]
    name = ${WORK_NAME}
    email = ${WORK_EMAIL}

[credential]
    helper = osxkeychain

[init]
    defaultBranch = main

[pull]
    rebase = false

[push]
    default = simple

[core]
    autocrlf = input
    editor = nvim
    pager = delta

[interactive]
    diffFilter = delta --color-only

[include]
    path = ~/.config/delta/catppuccin.gitconfig

[delta]
    navigate = true
    side-by-side = true
    # dark = true 
    features = catppuccin-mocha

[color]
    ui = auto

[includeIf "gitdir:~/src/"]
    path = $HOME/.gitconfig-personal

[includeIf "gitdir:~/work/"]
    path = $HOME/.gitconfig-work

[gpg]
    format = ssh

[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign

[commit]
    gpgsign = false
EOF


	cat > ~/.gitconfig-work << EOF
[user]
    name = ${WORK_NAME}
    email = ${WORK_EMAIL}

[credential]
    helper = osxkeychain
EOF



	cat > ~/.gitconfig-personal << EOF
[user]
	name = ${PERSONAL_NAME}
	email = ${PERSONAL_EMAIL}

[credential]
	helper = osxkeychain
EOF
}

_remove_git_backup() {
	ask_for_confirmation "Are you sure you want to remove the git backup files?"
	if [[ $? -ne 0 ]]; then
		log_info "Git backup files not removed"
		return 0
	fi

    if [ -f ~/.gitconfig.backup ]; then
        log_info "Removing existing .gitconfig.backup"
        rm ~/.gitconfig.backup
    fi

	if [ -f ~/.gitconfig-personal.backup ]; then
        log_info "Removing existing .gitconfig-personal.backup"
        rm ~/.gitconfig-personal.backup
    fi

	if [ -f ~/.gitconfig-work.backup ]; then
        log_info "Removing existing .gitconfig-work.backup"
        rm ~/.gitconfig-work.backup
    fi
}

setup_personal_git_config() {
    log_info "Setting up personal git configuration..."
    
    if [ -f ~/.gitconfig ]; then
        log_info "Backing up existing .gitconfig to .gitconfig.backup"
        cp ~/.gitconfig ~/.gitconfig.backup
    fi
    
    basic_git_config
    log_info "Personal git configuration has been set up successfully!"
}

setup_work_git_config() {
    log_info "Setting up work git configuration..."
    
    if [ -f ~/.gitconfig ]; then
        log_info "Backing up existing .gitconfig to .gitconfig.backup"
        cp ~/.gitconfig ~/.gitconfig.backup
    fi

	if [ -f ~/.gitconfig-work ]; then
        log_info "Backing up existing .gitconfig-work to .gitconfig-work.backup"
        cp ~/.gitconfig-work ~/.gitconfig-work.backup
    fi

	if [ -f ~/.gitconfig-personal ]; then
		log_info "Backing up existing .gitconfig-personal to .gitconfig-personal.backup"
		cp ~/.gitconfig-personal ~/.gitconfig-personal.backup
	fi
    
    work_git_config
    log_info "Work git configuration has been set up successfully!"
}

setup_git_identity() {
	log_info "Setting up git identity..."

	check_if_file_exists "../.env"
}

configure_git_to_use_delta() {
	log_info "Configuring git to use delta..."

	local gitconfig=$(get_expanded_config "GITCONFIG_PATH")
	local delta_dir=$(get_expanded_config "DELTA_CONFIG_DIR")
	local theme_path=$(get_expanded_config "DELTA_THEME_PATH")
	
    
    if [[ -f "$gitconfig" ]]; then
        log_info "Backing up existing .gitconfig to .gitconfig.backup"
        cp "$gitconfig" "$gitconfig.backup"
    fi
    
    if [[ -f "$gitconfig" ]]; then
        sed -i.bak '/catppuccin.gitconfig/d' "$gitconfig"
    fi

    if grep -q "^\[include\]" "$gitconfig"; then
        local temp_file=$(mktemp)
        awk -v path="$theme_path" '
            /^\[include\]/ { 
                print $0; 
                print "    path = " path; 
                next; 
            }
            { print $0 }
        ' "$gitconfig" > "$temp_file"
        mv "$temp_file" "$gitconfig"
    else
        printf "\n[include]\n    path = %s\n" "$theme_path" >> "$gitconfig"
    fi
    
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.features catppuccin-mocha
    git config --global delta.side-by-side true
    git config --global delta.navigate true

	log_info "Catppuccin delta configured!"	
}


show_git_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         Git Tools         │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "1) Setup personal git config"
	echo "2) Setup work git config"
	echo "3) Configure git to use delta"
	echo "4) Remove git backup files"
    echo "0) Back"
    echo ""
}

handle_git_menu() {
    while true; do
        show_git_menu
        read -p "Choice [0-4]: " choice
        
        case $choice in
            1)
                setup_personal_git_config
                wait_for_user
                ;;
            2)
                setup_work_git_config
                wait_for_user
                ;;
			3)
				configure_git_to_use_delta
				wait_for_user
				;;
			4)
				_remove_git_backup
				wait_for_user
				;;
            0)
                return
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 1
                ;;
        esac
    done
}

git_tools() {
    handle_git_menu
}