#!/bin/bash

# --- Configuration ---
SLURM_CONF_PATH="slurm.config/slurm.conf" # Adjust this path if needed
ORIGINAL_CONF_BACKUP="slurm.config/slurm.conf.bak"
LIST_SPECS_TEMP=~/slurm_temp_list_specs
NODE_LINES_TEMP=~/slurm_temp_node_lines
PART_LINE_TEMP=~/slurm_temp_part_line

# --- Script Arguments and Usage ---

echo "########################################"
echo "  SLURM CONFIGURATION AUTOMATION (3-in-1)"
echo "########################################"

if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./full_slurm_config_update.sh 0X Y (X,Y intervalo de 01 até N inteiro de 2 dígitos)'
 exit 1
fi

NODE_START=$1
NODE_END=$2
echo "Intervalo de nodos selecionado: $NODE_START até $NODE_END"
echo ""

# --- 1. COLLECT SPECS (Replaces g_slurmCspec.sh) ---

echo "--- 1/3: Collecting node specifications via SSH ---"

rm -f $LIST_SPECS_TEMP # Clean previous run's temp file
MAX_NODE_NUM=0
COLLECTED_NODES_COUNT=0

for i in $(eval echo {$NODE_START..$NODE_END})
do
if ping -c 1 nodo$i > /dev/null
then 
  echo "  ✅ Spec found for nodo$i"
  # Execute slurmd -C on the remote node and append to the local temporary file
  ssh nodo$i "slurmd -C" >> $LIST_SPECS_TEMP
  
  # Update max node number found
  NODE_NUM=$(echo $i | grep -oP '\d+')
  if (( 10#$NODE_NUM > MAX_NODE_NUM )); then MAX_NODE_NUM=$((10#$NODE_NUM)); fi
  COLLECTED_NODES_COUNT=$((COLLECTED_NODES_COUNT + 1))
else
  echo "  ❌ Host: nodo$i is down (Skipping)"
fi
done

if [[ $COLLECTED_NODES_COUNT -eq 0 ]]; then
    echo "Error: No nodes responded. Exiting."
    rm -f $LIST_SPECS_TEMP
    exit 1
fi

echo ""

# --- 2. GENERATE CONFIG LINES (Replaces generate_slurm_conf.sh) ---

echo "--- 2/3: Generating new configuration lines ---"

rm -f $NODE_LINES_TEMP $PART_LINE_TEMP # Clean temp files
NODE_CONFIG_LINES=""

# Loop through list_specs to extract node info
while IFS= read -r LINE; do
    if [[ "$LINE" =~ ^NodeName= ]]; then
        # Extract the core config (excluding RealMemory=) and append State=UNKNOWN
        CORE_CONFIG=$(echo "$LINE" | grep -oP 'NodeName=\w+ CPUs=\d+ Boards=\d+ SocketsPerBoard=\d+ CoresPerSocket=\d+ ThreadsPerCore=\d+')
        if [[ -n "$CORE_CONFIG" ]]; then
            NODE_CONFIG_LINES+="$CORE_CONFIG State=UNKNOWN"$'\n'
        fi
    fi
done < "$LIST_SPECS_TEMP"

# Save Node Configuration Lines
echo -n "$NODE_CONFIG_LINES" > "$NODE_LINES_TEMP"
echo "  ✅ Node lines generated in $NODE_LINES_TEMP"

# Generate Partition Line
FORMATTED_MIN="01" # Always start partition at 01
FORMATTED_MAX=$(printf "%02d" $MAX_NODE_NUM)
PARTITION_RANGE="Nodes=nodo[$FORMATTED_MIN-$FORMATTED_MAX]"
PARTITION_LINE="PartitionName=geral $PARTITION_RANGE Default=YES MaxTime=INFINITE State=UP"

# Save Partition Configuration Line
echo "$PARTITION_LINE" > "$PART_LINE_TEMP"
echo "  ✅ Partition line generated in $PART_LINE_TEMP (Range: $PARTITION_RANGE)"

echo ""

# --- 3. UPDATE SLURM.CONF (Replaces update_slurm_conf.sh) ---

echo "--- 3/3: Updating $SLURM_CONF_PATH ---"

if [[ ! -f "$SLURM_CONF_PATH" ]]; then
    echo "Error: Slurm configuration file not found at $SLURM_CONF_PATH. Exiting."
    rm -f $LIST_SPECS_TEMP $NODE_LINES_TEMP $PART_LINE_TEMP
    exit 1
fi

# 3a. Create Backup
cp "$SLURM_CONF_PATH" "$ORIGINAL_CONF_BACKUP"
echo "  - Backup created at $ORIGINAL_CONF_BACKUP"

# 3b. Read the replacement content
NODE_REPLACEMENT=$(cat "$NODE_LINES_TEMP")
PARTITION_REPLACEMENT=$(cat "$PART_LINE_TEMP")
START_MARKER="^# COMPUTE NODES"
END_MARKER="^#filas"

# 3c. Perform the Node Block Replacement using awk
echo "  - Replacing old Compute Node definitions..."
awk -v start="$START_MARKER" -v end="$END_MARKER" -v replacement="$NODE_REPLACEMENT" '
    $0 ~ start {
        print $0; 
        print ""; 
        print "#NodeName=nodo01 State=UNKNOWN"; # Keep original comment
        print replacement;
        in_block=1; next;
    }
    $0 ~ end && in_block {
        in_block=0; print ""; print $0; # Exit block and print the next marker
        next;
    }
    !in_block { print } # Print lines outside the block
' "$SLURM_CONF_PATH" > "$SLURM_CONF_PATH.tmp" && mv "$SLURM_CONF_PATH.tmp" "$SLURM_CONF_PATH"


# 3d. Perform the Partition Line Replacement using sed
echo "  - Replacing old Partition line..."
# Use sed to replace the line starting with 'PartitionName=geral'
sed -i.bak2 "/^PartitionName=geral/c\\
$PARTITION_REPLACEMENT
" "$SLURM_CONF_PATH"
rm -f "$SLURM_CONF_PATH.bak2"

# 3e. Cleanup temporary files
rm -f $LIST_SPECS_TEMP $NODE_LINES_TEMP $PART_LINE_TEMP

echo ""
echo "✅ Configuration Update Complete!"
echo "   - $SLURM_CONF_PATH has been updated."
echo "   - Partition 'geral' is now set to $PARTITION_RANGE."
