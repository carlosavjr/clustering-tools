#!/bin/bash
echo ""
echo "########################################"
echo "ACESSAR NODOS GTCMC "
echo "########################################"


echo ''
echo 'Install :'
echo ''
echo ""


if [[ -z "$1" || -z "$2" ]] ; then
 echo 'uso: ./d_nfsreload.sh 0X Y'
 echo 'exemplo: ./d_nfsreload.sh 02 17'
 exit 1
fi

echo "Intervalo de instalacao selecionado"
echo "$1 até $2" # Quote variables for robustness

echo ''
echo 'Update nfs:'
echo ''
echo ""

# Define the NFS mount line you want to add
NFS_MOUNT_LINE="10.1.1.1:/home /home nfs auto,noatime,nolock,bg,intr,tcp,actimeo=1800 0 0"

for i in `eval echo {$1..$2}`
do
if ping -c 1 nodo$i > /dev/null
then
  echo "Processing Nodo $i:"
  echo ''

  ssh -t nodo$i "
    ./admin_mode.sh # Execute your admin mode script first

    # Check if the NFS mount line already exists in /etc/fstab
    if ! grep -qF \"$NFS_MOUNT_LINE\" /etc/fstab; then
      echo \"NFS mount line not found in /etc/fstab on \$(hostname). Adding it...\"
      echo \"$NFS_MOUNT_LINE\" | sudo tee -a /etc/fstab > /dev/null
      echo \"Line added successfully. Trying to mount...\"
      sudo mount -a # Attempt to mount all entries in fstab
      if [ \$? -eq 0 ]; then
        echo \"NFS mounts updated and mounted successfully on \$(hostname).\"
      else
        echo \"Warning: mount -a failed after adding line on \$(hostname). Check mount status manually.\" >&2
      fi
    else
      echo \"NFS mount line already exists in /etc/fstab on \$(hostname). Skipping addition.\"
      sudo mount -a # Still run mount -a to ensure all fstab entries are mounted
      if [ \$? -eq 0 ]; then
        echo \"NFS mounts refreshed successfully on \$(hostname).\"
      else
        echo \"Warning: mount -a failed on \$(hostname). Check mount status manually.\" >&2
      fi
    fi
  "

  echo ''
else
  # 100% failed
  echo "Host : nodo$i is down at $(date "+%H:%M:%S %d/%m")"
  echo ''
fi
done

echo "END CLUSTER INSTALL."
