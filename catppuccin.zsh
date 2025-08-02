# vim:ft=zsh ts=2 sw=2 sts=2
#
# Bright Catppuccin ZSH Theme
# A vibrant, modern prompt using Catppuccin's brightest colors
#
# Features:
# - Multi-line design with clean separation
# - Bright, vibrant colors from Catppuccin palette
# - Git status with detailed branch information
# - Python virtual environment support
# - Execution time for long-running commands
# - Smart path truncation
# - Custom prompt character that changes based on last command status

# Catppuccin Mocha Bright Color Palette
typeset -A CATPPUCCIN
CATPPUCCIN[rosewater]="251"  # #f5e0dc
CATPPUCCIN[flamingo]="210"   # #f2cdcd  
CATPPUCCIN[pink]="212"       # #f5c2e7
CATPPUCCIN[mauve]="183"      # #cba6f7
CATPPUCCIN[red]="210"        # #f38ba8
CATPPUCCIN[maroon]="174"     # #eba0ac
CATPPUCCIN[peach]="216"      # #fab387
CATPPUCCIN[yellow]="221"     # #f9e2af
CATPPUCCIN[green]="156"      # #a6e3a1
CATPPUCCIN[teal]="123"       # #94e2d5
CATPPUCCIN[sky]="117"        # #89dceb
CATPPUCCIN[sapphire]="116"   # #74c7ec
CATPPUCCIN[blue]="111"       # #89b4fa
CATPPUCCIN[lavender]="183"   # #b4befe
CATPPUCCIN[text]="255"       # #cdd6f4
CATPPUCCIN[subtext1]="251"   # #bac2de
CATPPUCCIN[subtext0]="248"   # #a6adc8
CATPPUCCIN[overlay2]="245"   # #9399b2
CATPPUCCIN[surface2]="242"   # #585b70
CATPPUCCIN[surface1]="239"   # #45475a
CATPPUCCIN[surface0]="237"   # #313244
CATPPUCCIN[base]="235"       # #1e1e2e
CATPPUCCIN[mantle]="234"     # #181825
CATPPUCCIN[crust]="232"      # #11111b

# Theme Configuration
CATPPUCCIN_PROMPT_SHOW_TIME=${CATPPUCCIN_PROMPT_SHOW_TIME:-true}
CATPPUCCIN_PROMPT_SHOW_USER=${CATPPUCCIN_PROMPT_SHOW_USER:-false}
CATPPUCCIN_PROMPT_SHOW_HOST=${CATPPUCCIN_PROMPT_SHOW_HOST:-false}
CATPPUCCIN_PROMPT_TIME_FORMAT=${CATPPUCCIN_PROMPT_TIME_FORMAT:-"%H:%M"}
CATPPUCCIN_PROMPT_PATH_LENGTH=${CATPPUCCIN_PROMPT_PATH_LENGTH:-3}

# Enable command execution time tracking
zmodload zsh/datetime

# Hook to capture command start time
preexec() {
    CATPPUCCIN_CMD_START_TIME=$EPOCHSECONDS
}

# Function to get command execution time
catppuccin_cmd_exec_time() {
    if [[ -n $CATPPUCCIN_CMD_START_TIME ]]; then
        local duration=$((EPOCHSECONDS - CATPPUCCIN_CMD_START_TIME))
        unset CATPPUCCIN_CMD_START_TIME
        
        if (( duration > 2 )); then
            if (( duration < 60 )); then
                echo "%F{${CATPPUCCIN[peach]}}󱦟 ${duration}s%f"
            elif (( duration < 3600 )); then
                local minutes=$((duration / 60))
                local seconds=$((duration % 60))
                echo "%F{${CATPPUCCIN[peach]}}󱦟 ${minutes}m ${seconds}s%f"
            else
                local hours=$((duration / 3600))
                local minutes=$(((duration % 3600) / 60))
                echo "%F{${CATPPUCCIN[peach]}}󱦟 ${hours}h ${minutes}m%f"
            fi
        fi
    fi
}

# Function to get current time
catppuccin_time() {
    if [[ $CATPPUCCIN_PROMPT_SHOW_TIME == "true" ]]; then
        echo "%F{${CATPPUCCIN[sky]}}󰥔 $(date +"$CATPPUCCIN_PROMPT_TIME_FORMAT")%f"
    fi
}

# Function to get user@host info
catppuccin_user_host() {
    local user_color="${CATPPUCCIN[green]}"
    local host_color="${CATPPUCCIN[blue]}"
    
    # Change colors if root or SSH
    if [[ $EUID -eq 0 ]]; then
        user_color="${CATPPUCCIN[red]}"
    fi
    
    if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
        host_color="${CATPPUCCIN[pink]}"
    fi
    
    local result=""
    if [[ $CATPPUCCIN_PROMPT_SHOW_USER == "true" ]]; then
        result+="%F{${user_color}}%n%f"
    fi
    
    if [[ $CATPPUCCIN_PROMPT_SHOW_HOST == "true" ]]; then
        if [[ -n $result ]]; then
            result+="%F{${CATPPUCCIN[subtext0]}}@%f"
        fi
        result+="%F{${host_color}}%m%f"
    fi
    
    if [[ -n $result ]]; then
        echo "$result"
    fi
}

# Function to get truncated path
catppuccin_path() {
    local path_segments=()
    local current_path="${PWD/#$HOME/~}"
    
    # Split path into segments
    IFS='/' read -A path_segments <<< "$current_path"
    
    local result=""
    local segments_count=${#path_segments[@]}
    
    if (( segments_count <= CATPPUCCIN_PROMPT_PATH_LENGTH )); then
        result="$current_path"
    else
        # Show first segment, ellipsis, and last few segments
        result="${path_segments[1]}"
        if (( segments_count > CATPPUCCIN_PROMPT_PATH_LENGTH + 1 )); then
            result+="%F{${CATPPUCCIN[overlay2]}}/%f%F{${CATPPUCCIN[subtext0]}}…%f"
        fi
        
        local start_idx=$((segments_count - CATPPUCCIN_PROMPT_PATH_LENGTH + 1))
        for (( i = start_idx; i <= segments_count; i++ )); do
            if [[ -n ${path_segments[i]} ]]; then
                result+="%F{${CATPPUCCIN[overlay2]}}/%f${path_segments[i]}"
            fi
        done
    fi
    
    echo "%F{${CATPPUCCIN[mauve]}}󰉋 %f%F{${CATPPUCCIN[text]}}$result%f"
}

# Function to get Git information
catppuccin_git_info() {
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        return
    fi
    
    local branch_name=""
    local git_status_info=""
    local branch_color="${CATPPUCCIN[green]}"
    
    # Get branch name
    branch_name=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -z $branch_name ]]; then
        # Detached HEAD
        branch_name="󰓁 $(git rev-parse --short HEAD 2>/dev/null)"
        branch_color="${CATPPUCCIN[yellow]}"
    fi
    
    # Get repository status
    local staged_count=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    local modified_count=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    local untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    
    # Get ahead/behind info
    local ahead_behind=""
    local upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [[ -n $upstream ]]; then
        local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
        local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
        
        if (( ahead > 0 && behind > 0 )); then
            ahead_behind=" %F{${CATPPUCCIN[red]}}󰹺 $ahead%f%F{${CATPPUCCIN[blue]}}󰁅 $behind%f"
            branch_color="${CATPPUCCIN[red]}"
        elif (( ahead > 0 )); then
            ahead_behind=" %F{${CATPPUCCIN[green]}}󰁝 $ahead%f"
        elif (( behind > 0 )); then
            ahead_behind=" %F{${CATPPUCCIN[blue]}}󰁅 $behind%f"
            branch_color="${CATPPUCCIN[yellow]}"
        fi
    fi
    
    # Build status info
    local status_parts=()
    if (( staged_count > 0 )); then
        status_parts+="%F{${CATPPUCCIN[green]}}󰐗 $staged_count%f"
        branch_color="${CATPPUCCIN[yellow]}"
    fi
    if (( modified_count > 0 )); then
        status_parts+="%F{${CATPPUCCIN[yellow]}}󰏫 $modified_count%f"
        branch_color="${CATPPUCCIN[yellow]}"
    fi
    if (( untracked_count > 0 )); then
        status_parts+="%F{${CATPPUCCIN[red]}}󰋗 $untracked_count%f"
        branch_color="${CATPPUCCIN[red]}"
    fi
    
    if (( ${#status_parts[@]} > 0 )); then
        git_status_info=" ${(j: :)status_parts}"
    fi
    
    echo "%F{${CATPPUCCIN[red]}}󰊢 %f%F{${branch_color}}$branch_name%f$ahead_behind$git_status_info"
}

# Function to get Python virtual environment info
catppuccin_venv_info() {
    if [[ -n $VIRTUAL_ENV ]]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        echo "%F{${CATPPUCCIN[pink]}}󰌠 %f%F{${CATPPUCCIN[text]}}$venv_name%f"
    elif [[ -n $CONDA_DEFAULT_ENV ]]; then
        echo "%F{${CATPPUCCIN[pink]}}󰌠 %f%F{${CATPPUCCIN[text]}}$CONDA_DEFAULT_ENV%f"
    fi
}

# Function to get background jobs info
catppuccin_jobs_info() {
    local job_count=$(jobs | wc -l | tr -d ' ')
    if (( job_count > 0 )); then
        echo "%F{${CATPPUCCIN[lavender]}}󰜎 %f%F{${CATPPUCCIN[text]}}$job_count%f"
    fi
}

# Function to get the prompt character based on last command status
catppuccin_prompt_char() {
    if [[ $? -eq 0 ]]; then
        echo "%F{${CATPPUCCIN[green]}}❯%f"
    else
        echo "%F{${CATPPUCCIN[red]}}❯%f"
    fi
}

# Function to build the first line of the prompt
catppuccin_build_top_line() {
    local components=()
    
    # Add execution time if available
    local exec_time=$(catppuccin_cmd_exec_time)
    [[ -n $exec_time ]] && components+=("$exec_time")
    
    # Add background jobs
    local jobs_info=$(catppuccin_jobs_info)
    [[ -n $jobs_info ]] && components+=("$jobs_info")
    
    # Join components with separator
    if (( ${#components[@]} > 0 )); then
        local separator="%F{${CATPPUCCIN[surface2]}} • %f"
        echo "${(j:$separator:)components}"
    fi
}

# Function to build the second line of the prompt
catppuccin_build_middle_line() {
    local components=()
    
    # Add current path
    local path_info=$(catppuccin_path)
    [[ -n $path_info ]] && components+=("$path_info")
    
    # Add time if enabled
    local time_info=$(catppuccin_time)
    [[ -n $time_info ]] && components+=("$time_info")
    
    # Add virtual environment
    local venv_info=$(catppuccin_venv_info)
    [[ -n $venv_info ]] && components+=("$venv_info")
    
    # Add git info
    local git_info=$(catppuccin_git_info)
    [[ -n $git_info ]] && components+=("$git_info")
    
    # Join components with separator
    if (( ${#components[@]} > 0 )); then
        local result="${components[1]}"
        for (( i=2; i<=${#components[@]}; i++ )); do
            result+="%F{${CATPPUCCIN[surface2]}} | %f${components[i]}"
        done
        echo "$result"
    fi
}

# Main prompt function - CURVED LINES REMOVED
catppuccin_build_prompt() {
    local top_line=$(catppuccin_build_top_line)
    local middle_line=$(catppuccin_build_middle_line)
    local prompt_char=$(catppuccin_prompt_char)
    
    # Build the complete prompt
    local result="\n"
    
    if [[ -n $top_line ]]; then
        result+="$top_line"$'\n'
    fi
    
    if [[ -n $middle_line ]]; then
        if [[ -n $top_line ]]; then
            result+="$middle_line"$'\n'
        else
            result+="$middle_line"$'\n'
        fi
    fi
    
    result+="$prompt_char "
    
    echo "$result"
}

# Right-side prompt (optional)
catppuccin_rprompt() {
    # You can add additional info here like exit code, etc.
    if [[ $? -ne 0 ]]; then
        echo "%F{${CATPPUCCIN[red]}}✗ $?%f"
    fi
}

# Set the prompts
setopt PROMPT_SUBST
PROMPT='$(catppuccin_build_prompt)'
RPROMPT='$(catppuccin_rprompt)'

# Enable additional prompt features
setopt AUTO_CD
setopt CORRECT
setopt HIST_VERIFY
