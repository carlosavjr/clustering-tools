#!/bin/bash

# Enhanced with error handling and progress reporting
set -euo pipefail # Exit immediately if a command exits with a non-zero status,
                  # exit if an undeclared variable is used, and propagate pipe errors.

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (required for /etc/hosts and /etc/exports modification)" >&2
    exit 1
fi

# Validate arguments and set defaults
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

# --- Variables and Flags for NFS Export Configuration ---
# Define the base NFS export path. This should be your shared directory.
NFS_EXPORT_PATH="/home"
# Flag to track if any NFS export lines were added/modified
NFS_EXPORTS_CHANGED=0

# Backup original /etc/hosts file with error checking
backup_hosts_file="/etc/hosts.backup_$timestamp"
if ! cp /etc/hosts "$backup_hosts_file"; then
    echo "Failed to create /etc/hosts backup! Exiting." >&2
    exit 1
fi
echo "Created hosts backup: $backup_hosts_file"

# Backup original /etc/exports file with error checking
backup_exports_file="/etc/exports.backup_$timestamp"
if ! cp /etc/exports "$backup_exports_file"; then
    echo "Failed to create /etc/exports backup! Exiting." >&2
    exit 1
fi
echo "Created exports backup: $backup_exports_file"

# Function to update /etc/exports for a single IP
# Arguments: $1 = IP address to add to exports
update_nfs_export_entry() {
    local ip_address="$1"
    # Construct the full export line for the specific IP
    local export_line="${NFS_EXPORT_PATH} ${ip_address}(rw,sync,no_root_squash,no_subtree_check)"

    echo "  Checking /etc/exports for: ${export_line}"

    # Check if the line already exists in /etc/exports
    if ! grep -qF "${export_line}" /etc/exports; then
        echo "  Line not found for ${ip_address}. Adding to /etc/exports..."
        echo "${export_line}" | sudo tee -a /etc/exports > /dev/null
        if [ $? -eq 0 ]; then
            echo "  Successfully added line for ${ip_address} to /etc/exports."
            NFS_EXPORTS_CHANGED=1 # Set flag as a change was made
        else
            echo "  ERROR: Failed to add line for ${ip_address} to /etc/exports." >&2
        fi
    else
        echo "  Line for ${ip_address} already exists in /etc/exports. Skipping."
    fi
}


# Function to update server hosts file with progress reporting
update_server_hosts() {
    echo "Starting server hosts file update and NFS exports configuration..."

    # Read the current /etc/hosts content BEFORE any modifications.
    local original_hosts_content
    original_hosts_content=$(cat /etc/hosts)

    # Create temporary file safely
    tmp_hosts_file=$(mktemp /tmp/hosts_tmp.XXXXXX)
    # Ensure temporary file is removed on script exit
    trap 'rm -f "$tmp_hosts_file"' EXIT

    # Write standard header to the temporary file.
    echo -e "127.0.0.1\tlocalhost" > "$tmp_hosts_file"
    echo -e "127.0.1.1\tcluster" >> "$tmp_hosts_file"

    # Use an associative array to quickly check if an IP is within the current processing range.
    declare -A current_range_ips

    # Process all IPs in current range (start to end) with progress counter.
    total_nodes=$((end - start + 1))
    current_node=0

    for i in $(seq "$start" "$end"); do
        current_node=$((current_node + 1))
        ip="${prefix}${i}"
        hostname="nodo$(printf "%02d" "$i")" # Ensure two-digit formatting
        entry="${ip}\t${hostname}"

        printf "\rProcessing node %02d/%d: %-15s" "$current_node" "$total_nodes" "$ip" # Updated progress message

        # Mark this IP as part of the current processing range.
        current_range_ips["$ip"]=1

        # Test connection with timeout.
        if timeout 1 ping -c 1 "$ip" &>/dev/null; then
            echo -e "$entry" >> "$tmp_hosts_file"
            echo "  Discovered active node: $entry" # Print discovery message on a new line.
            
            # --- CALL NFS EXPORT UPDATE FUNCTION FOR THIS ACTIVE IP ---
            update_nfs_export_entry "$ip"
            # -----------------------------------------------------------
        else
            # If offline, add as commented.
            echo -e "#${entry}" >> "$tmp_hosts_file"
            echo "  Node offline: $entry" # Print offline message on a new line.
        fi
    done

    echo -e "\nAppending remaining configuration from original /etc/hosts..."

    while IFS= read -r line; do
        if echo "$line" | grep -qE "^127\.0\.0\.1|^127\.0\.1\.1|^::1|^fe00::0|^ff00::0|^ff02::1|^ff02::2"; then
            continue
        fi

        local extracted_ip=""
        if echo "$line" | grep -qE "^${prefix}"; then
            extracted_ip=$(echo "$line" | awk '{print $1}')
        elif echo "$line" | grep -qE "^#${prefix}"; then
            extracted_ip=$(echo "$line" | sed -E "s/^#(${prefix}[0-9\.]+).*$/\1/") # Adjusted regex for IP extraction
        fi

        if [[ -n "$extracted_ip" && ${current_range_ips["$extracted_ip"]+set} == "set" ]]; then
            continue
        fi

        echo "$line" >> "$tmp_hosts_file"
    done <<< "$original_hosts_content"

    # Add standard IPv6 block cleanly and only once at the end of the file.
    cat <<EOF >> "$tmp_hosts_file"

# Standard IPv6 Configuration
::1\tip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    # Set correct permissions on the temporary file BEFORE moving it.
    chmod 644 "$tmp_hosts_file"

    if [ -s "$tmp_hosts_file" ]; then
        if ! mv "$tmp_hosts_file" /etc/hosts; then
            echo "Failed to update /etc/hosts! Restoring backup..." >&2
            cp "$backup_hosts_file" /etc/hosts
            exit 1
        fi
    else
        echo "Error: Generated empty hosts file! Aborting." >&2
        exit 1
    fi

    echo "Server hosts file updated successfully."
}

# Main execution block with error trapping and logging.
{
    echo "Starting IP discovery and server hosts file configuration at $(date)"
    echo "===================================="

    # Update the server's hosts file and implicitly configure NFS exports
    update_server_hosts

    # --- NFS Service Reload and Restart (Conditional) ---
    if [ "$NFS_EXPORTS_CHANGED" -eq 1 ]; then
        echo -e "\nChanges detected in /etc/exports. Reloading NFS exports and restarting nfs-kernel-server..."
        sudo exportfs -a
        if [ $? -ne 0 ]; then
            echo "Warning: exportfs -a command failed." >&2
        fi
        sudo systemctl restart nfs-kernel-server
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to restart nfs-kernel-server. Please check logs." >&2
            exit 1
        else
            echo "nfs-kernel-server restarted successfully."
        fi
    else
        echo -e "\nNo changes detected in /etc/exports. NFS service not restarted."
    fi
    # ----------------------------------------------------

    echo -e "\nOperation completed at $(date)"
    echo "===================================="
    echo "Summary:"
    echo "- Server hosts file updated with active and discovered node entries within the specified range."
    echo "- Original /etc/hosts backed up to $backup_hosts_file"
    echo "- Original /etc/exports backed up to $backup_exports_file"
    echo "Note: This script now also configures /etc/exports for active discovered nodes."
} | tee -a "/var/log/cluster_config_$timestamp.log" # Log all output to a timestamped file.

exit 0
