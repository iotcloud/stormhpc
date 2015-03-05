#!/bin/bash

#PBS -q batch
#PBS -N storm_job
###PBS -l nodes=2:ppn=4
#PBS -l select=6:ncpus=12
#PBS -o s.out
#PBS -e s.err
#PBS -A baru-tro
#PBS -V

### Run the stormhpc environment script to set the appropriate variables
#
# Note: ensure that the variables are set correctly in bin/setenv.sh
. /N/u/skamburu/projects/stormhpc/bin/setenv.sh
#. /home/supun/dev/projects/stormforhpc/bin/setenv.sh

#### Set this to the directory where Storm configs should be generated
# Don't change the name of this variable (STORM_CONF_DIR) as it is
# required by Storm - all config files will be picked up from here
#
# Make sure that this is accessible to all nodes
export STORM_CONF_DIR="/N/u/skamburu/projects/stormhpc/storm/conf"
export ZOOCFGDIR="/N/u/skamburu/projects/stormhpc/zkconf"
#export STORM_CONF_DIR="/home/supun/dev/projects/stormforhpc/storm/conf"
#export ZOOCFGDIR="/home/supun/dev/projects/stormforhpc/zk/conf"
#### Set up the configuration
# Make sure number of nodes is the same as what you have requested from PBS
# usage: $STORM_HPC_HOME/bin/pbs-configure.sh -h
echo "Set up the configurations for stormhpc"
# this is the non-persistent mode

#export PBS_NODEFILE="/home/supun/dev/projects/stormforhpc/pbsnodes"

$STORMHPC_HOME/bin/pbs-configure.sh -n 6 -c $STORM_CONF_DIR

sleep 10

#### Submit your jobs here
$STORM_HOME/bin/storm jar ~/projects/iotrobots/slam/streaming/target/iotrobots-slam-streaming-1.0-SNAPSHOT-jar-with-dependencies.jar cgl.iotrobots.slam.streaming.SLAMTopology -name slam_processor -ds_mode 0 -p 20 -pt 60 -i > /dev/null 2>&1 &


while true;
do
    sleep 10
done

#### Clean up the working directories after job completion
echo "Clean up"
$STORMHPC_HOME/bin/pbs-cleanup.sh -n 2
echo
