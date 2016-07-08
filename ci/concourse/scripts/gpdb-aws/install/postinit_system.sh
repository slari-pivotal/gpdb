#!/bin/bash

echo "Saving MASTER_DATA_DIRECTORY"
echo $MASTER_DIRECTORY
sudo sh -E -c 'echo "export MASTER_DATA_DIRECTORY=${MASTER_DIRECTORY}/gpseg-1" >> ~gpadmin/.bashrc'
sudo sh -E -c 'echo "export MASTER_DATA_DIRECTORY=${MASTER_DIRECTORY}/gpseg-1" >> ~root/.bashrc'

echo "Adding ETL hosts to pg_hba.conf"
for IP in $INTERNAL_ETL_IPS; do
  sudo sh -E -c 'echo -e "host\tall\tgpadmin\t${IP}/32\ttrust" >> "${MASTER_DIRECTORY}/gpseg-1/pg_hba.conf"'
done

if [[ $(hostname) == "smdw" ]]; then
  exit
fi

# echo "Setting GUCS for ${SEGMENTS} segments"
#
# su - gpadmin -c "gpconfig -c optimizer -v on"
#
# CORES=$(cat /proc/cpuinfo | grep -c processor)
# CORES_PER_SEGMENT=$(bc <<< "scale=2; ${CORES}/$SEGMENTS")
# su - gpadmin -c "gpconfig -c gp_resqueue_priority_cpucores_per_segment -v ${CORES_PER_SEGMENT} -m ${CORES}"
#
# RAM=$(free -g | grep Mem | xargs | cut -f2 -d' ')
# if [[ $RAM -ge 128 ]]; then
#   AV_RAM=$(( $RAM - 32 ))
# else
#   AV_RAM=$(( $RAM - 16 ))
# fi
# RAM_PER_SEGMENT=$(( $AV_RAM / $SEGMENTS ))
# RAM_PER_SEGMENT_KB=$(( $RAM_PER_SEGMENT * 1024 * 1024 ))
#
# su - gpadmin -c "gpconfig -c gp_vmem_protect_limit -v ${RAM_PER_SEGMENT_KB}"
# su - gpadmin -c "gpconfig -c max_statement_mem -v ${RAM_PER_SEGMENT}GB"

# echo "Reloading database"
# su - gpadmin -c "gpstop -a -r"
