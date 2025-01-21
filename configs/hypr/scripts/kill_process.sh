#!/usr/bin/env bash

# Function to kill a process using fzf for selection
kill_process() {
    # Check if fzf is installed
    if ! command -v fzf &> /dev/null; then
        echo "Error: 'fzf' is not installed. Please install it to use this script."
        return 1
    fi

    # Get the list of processes (PID, command) and filter using fzf
    local selected_process
    selected_process=$(ps -eo pid,comm --no-headers | fzf --height 20% --preview 'echo {}' --prompt="Select a process to kill: ")

    # Exit if no process is selected
    if [[ -z "$selected_process" ]]; then
        echo "No process selected. Exiting."
        return 1
    fi

    # Extract the PID from the selected process
    local pid
    pid=$(echo "$selected_process" | awk '{print $1}')

    # Confirm before killing the process
    echo "Selected process:"
    echo "$selected_process"
    read -r -p "Are you sure you want to kill this process? (Y/n): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Attempt to kill the process
        if kill -9 "$pid" 2>/dev/null; then
            echo "Process $pid killed successfully."
        else
            echo "Failed to kill process $pid. You might need additional permissions."
        fi
    else
        echo "Process not killed."
    fi
}

# Main script execution
kill_process
