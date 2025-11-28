echo "########################################"
echo "Instalar Openmpi nos NODOS GTCMC "
echo "########################################"

echo ''
echo 'Starting clock synchronization:'
echo ''

# Get the current date and time from the server in a format suitable for 'date -s'
# Using the format "YYYY-MM-DD HH:MM:SS" is safer for date -s
SERVER_TIME=$(date +"%Y-%m-%d %H:%M:%S")

echo "Server Time: $SERVER_TIME"
echo ""

for i in {01..03}
do
    NODE="nodo$i"

    if ping -c 1 "$NODE" > /dev/null
    then
        echo "Synchronizing clock on $NODE..."

        # Use SSH to execute the 'sudo date -s' command on the node.
        # The '$SERVER_TIME' is expanded on the local server before SSH runs.
        # **NOTE:** This requires the user to have passwordless sudo permission
        # or passwordless SSH access set up.
        ssh -t "$NODE" "./admin_mode.sh; sudo date -s \"$SERVER_TIME\""

        # Verification step: Read the clock back from the node
        echo "Node $i new clock (Verification): $(ssh "$NODE" "date +\"%Y-%m-%d 
%H:%M:%S\"")"
        echo ''
    else
        # 100% failed
        echo "Host: $NODE is DOWN at $(date)"
        echo ''
    fi
done

echo "END CLUSTER INSTALL."
