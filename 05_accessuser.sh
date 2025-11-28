#!/bin/bash
echo ""
echo "########################################"
echo "ACESSAR NODOS GTCMC "
echo "########################################"


echo ''
echo 'Instalar sem senha:'
echo ''
echo ""

if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./05_accessuser.sh 0X Y (X,Y intervalo de 02 até N inteiro de 2 dígitos)'
 exit 1
fi

# Define your single password file
# This file should contain 10 lines, with each line being the password for user01, user02, ..., user10 in order.
PASSWORD_FILE="pwd/passwords.txt"

# Check if the password file exists
if [[ ! -f "$PASSWORD_FILE" ]]; then
    echo "Error: Password file '$PASSWORD_FILE' not found."
    exit 1
fi

# Read passwords into an array, one password per line
# The first line (index 0) should be for user01, the second (index 1) for user02, and so on.
mapfile -t PASSWORDS < "$PASSWORD_FILE"

# Loop for users from 0 to 9 (total of 10 users: user01 to user10)
for j in {0..29}
do
    # Format the user number with leading zero if less than 10
    # For j=0, user_num will be 01. For j=9, user_num will be 10.
    printf -v user_num "%02d" $((j+1))

    # Get the password for the current user (j) from the array
    current_password="${PASSWORDS[$j]}"

    # Check if a password was successfully retrieved for the current user index
    if [[ -z "$current_password" ]]; then
        echo "Warning: No password found for user$user_num at array index $j in $PASSWORD_FILE. Skipping this user."
        continue
    fi

    echo "Processing user$user_num"

    # Set SSHPASS for the OUTER sshpass command (connecting to 'cluster')
    # This export happens on the LOCAL machine.
    export SSHPASS="$current_password"

    # The entire block within single quotes is executed on the 'cluster' machine.
    # We need to ensure SSHPASS is set *within* that remote shell for ssh-copy-id.
    # The trick is to inject the $current_password variable (local) into the remote string,
    # by carefully breaking out of single quotes, inserting the variable, then re-entering single quotes.
    sshpass -e ssh -t user"$user_num"@cluster '
        # Set SSHPASS variable on the remote host for the nested sshpass calls.
        # This is where the magic happens: the value of $current_password (from the local script)
        # is injected into this string executed on the remote 'cluster' machine.
        export SSHPASS="'"$current_password"'";

        echo "Creating SSH keypair...";
        echo "";

        hostname;

        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa <<< y;

        # The remote script needs to know the current user number (n)
        # and the range for target nodes ($1 and $2 are passed from the local script context).
        n="'"$user_num"'"

        echo "Installation interval selected: '$1' to '$2'";

        for i in `eval echo {'"$1"'..'"$2"'}`
        do
            if ping -c 1 nodo$i > /dev/null;
            then
                echo "Echo ssh-copy-id Nodo $i cpu:";
                echo "user$n";
                echo "$i";

                IP_OCTET=$((10#$i))
                IP_ADDRESS="10.1.1.$IP_OCTET"

                ssh-keygen -R "nodo$i"
                ssh-keygen -R "$IP_ADDRESS"

                # This sshpass -e will now successfully find the SSHPASS variable set above
                sshpass -e ssh-copy-id -o StrictHostKeychecking=no user$n@nodo$i;

                echo "";
            else
                echo "Host : nodo$i is down at $(date)";
                echo "";
            fi
        done
        # Good practice: unset SSHPASS on the remote host after use
        unset SSHPASS
    '
    # Unset SSHPASS locally after the ssh command to avoid it lingering in the environment
    unset SSHPASS

done

echo "END CLUSTER INSTALL."
