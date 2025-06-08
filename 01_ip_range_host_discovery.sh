#!/bin/bash

# Enhanced with error handling and progress reporting
set -euo pipefail

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (required for /etc/hosts modification)" >&2
    exit 1
fi

# Validate arguments and set defaults
# If only 2 arguments are provided, assume they are start_ip and end_ip, with default prefix.
if [ $# -lt 2 ]; then
    echo "Usage: $0 [<network_prefix>] <start_ip> <end_ip>" >&2
    echo "Example: $0 10.1.1. 1 100" >&2
    echo "Example (using default prefix 10.1.1.): $0 1 100" >&2
    exit 1
fi

# Determine prefix, start, and end based on number of arguments
if [ $# -eq 3 ]; then
    prefix="$1"
    start="$2"
    end="$3"
elif [ $# -eq 2 ]; then
    prefix="10.1.1." # Default network prefix
    start="$1"
    end="$2"
fi

timestamp=$(date +%Y%m%d_%H%M%S)

# Backup original file with error checking
backup_file="/etc/hosts.backup_$timestamp"
if ! cp /etc/hosts "$backup_file"; then
    echo "Failed to create backup! Exiting." >&2
    exit 1
fi
echo "Created backup: $backup_file"

# Function to update server hosts file with progress reporting
update_server_hosts() {
    echo "Starting server hosts file update..."
    
    # Read the current /etc/hosts content BEFORE any modifications.
    # This acts as the "source of truth" for what was previously in the file.
    local original_hosts_content
    original_hosts_content=$(cat /etc/hosts)

    # Create temporary file safely
    tmp_file=$(mktemp /tmp/hosts_tmp.XXXXXX)
    # Ensure temporary file is removed on script exit
    trap 'rm -f "$tmp_file"' EXIT
    
    # Write standard header to the temporary file.
    # These are fundamental entries and should always be present at the top.
    echo -e "127.0.0.1\tlocalhost" > "$tmp_file"
    echo -e "127.0.1.1\tcluster" >> "$tmp_file"
    
    # Use an associative array to quickly check if an IP is within the current processing range.
    # This prevents duplication when we append existing entries later.
    declare -A current_range_ips
    
    # Process all IPs in current range (start to end) with progress counter.
    total_nodes=$((end - start + 1))
    current_node=0
    
    for i in $(seq "$start" "$end"); do
        current_node=$((current_node + 1))
        ip="${prefix}${i}"
        hostname="nodo$(printf "%02d" "$i")" # Ensure two-digit formatting
        entry="${ip}\t${hostname}"
        
        printf "\rProcessing node %02d/%d..." "$current_node" "$total_nodes"
        
        # Mark this IP as part of the current processing range.
        current_range_ips["$ip"]=1 
        
        # Test connection with timeout.
        if timeout 1 ping -c 1 "$ip" &>/dev/null; then
            echo -e "$entry" >> "$tmp_file"
            echo "Discovered active node: $entry" # Print discovery message on a new line.
        else
            # If offline, add as commented. If an active entry for this IP was
            # previously present but is now offline, this will override it.
            echo -e "#${entry}" >> "$tmp_file"
        fi
    done
    
    echo -e "\nAppending remaining configuration from original /etc/hosts..."
    
    # Iterate through the original /etc/hosts content line by line.
    # This loop ensures that any lines not explicitly managed by this script (like custom entries)
    # or node entries outside the current processing range are preserved.
    # Changed from pipe `| while` to `while read ... <<< "$original_hosts_content"` to avoid subshell
    # and allow `current_range_ips` to be accessible.
    while IFS= read -r line; do
        # Skip lines that are standard localhost, cluster, or common IPv6 blocks,
        # as these are handled separately by the script's fixed headers/footers.
        if echo "$line" | grep -qE "^127\.0\.0\.1|^127\.0\.1\.1|^::1|^fe00::0|^ff00::0|^ff02::1|^ff02::2"; then
            continue
        fi

        # Attempt to extract an IP address from the current line if it looks like a node entry.
        local extracted_ip=""
        if echo "$line" | grep -qE "^${prefix}"; then
            # Extract IP from an active entry (e.g., "10.1.1.5 nodo05")
            extracted_ip=$(echo "$line" | awk '{print $1}')
        elif echo "$line" | grep -qE "^#${prefix}"; then
            # Extract IP from a commented entry (e.g., "#10.1.1.5 nodo05")
            extracted_ip=$(echo "$line" | sed -E "s/^#(${prefix}[0-9]+).*$/\1/")
        fi

        # If an IP was extracted AND it's part of the *current* range being processed, skip it.
        # This prevents duplication for IPs that were already handled by the loop above.
        # Modified condition to safely check if the array key exists to prevent "unbound variable" error.
        if [[ -n "$extracted_ip" && ${current_range_ips["$extracted_ip"]+set} == "set" ]]; then
            continue
        fi

        # If the line doesn't fall into any of the above categories, append it to the new file.
        # This preserves custom entries or node entries outside the current processing range.
        echo "$line" >> "$tmp_file"
    done <<< "$original_hosts_content" # Here string to feed content into the while loop in current shell
    
    # Add standard IPv6 block cleanly and only once at the end of the file.
    cat <<EOF >> "$tmp_file"

# Standard IPv6 Configuration
::1\tip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    # Set correct permissions on the temporary file BEFORE moving it.
    # This ensures /etc/hosts retains read permissions for normal users.
    chmod 644 "$tmp_file"

    # Verify that the temporary hosts file is not empty before replacing the actual /etc/hosts.
    if [ -s "$tmp_file" ]; then
        if ! mv "$tmp_file" /etc/hosts; then
            echo "Failed to update /etc/hosts! Restoring backup..." >&2
            cp "$backup_file" /etc/hosts
            exit 1
        fi
    else
        echo "Error: Generated empty hosts file! Aborting." >&2
        exit 1
    fi
    
    echo "Server hosts file updated successfully"
}

# Main execution block with error trapping and logging.
{
    echo "Starting IP discovery and server hosts file configuration at $(date)"
    echo "===================================="
    
    # Update the server's hosts file.
    update_server_hosts
    
    echo -e "\nOperation completed at $(date)"
    echo "===================================="
    echo "Summary:"
    echo "- Server hosts file updated with active and discovered node entries within the specified range."
    echo "- Original configuration backed up to $backup_file"
    echo "Note: This script now only modifies the local server's /etc/hosts file."
} | tee -a "/var/log/cluster_config_$timestamp.log" # Log all output to a timestamped file.

exit 0
