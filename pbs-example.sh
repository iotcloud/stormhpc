#!/bin/bash

#PBS -q batch
#PBS -N storm_job
###PBS -l nodes=2:ppn=4
#PBS -l select=2:ncpus=8
#PBS -o s.out
#PBS -e s.err
#PBS -A baru-tro
#PBS -V

### Run the stormhpc environment script to set the appropriate variables
#
# Note: ensure that the variables are set correctly in bin/setenv.sh
. /N/u/skamburu/software/stormhpc/bin/setenv.sh

#### Set this to the directory where Storm configs should be generated
# Don't change the name of this variable (STORM_CONF_DIR) as it is
# required by Storm - all config files will be picked up from here
#
# Make sure that this is accessible to all nodes
export STORM_CONF_DIR="/N/u/skamburu/software/stormhpc/storm/conf"
export ZOOCFGDIR="/N/u/skamburu/software/stormhpc/zkconf"

#### Set up the configuration
# Make sure number of nodes is the same as what you have requested from PBS
# usage: $STORM_HPC_HOME/bin/pbs-configure.sh -h
echo "Set up the configurations for stormhpc"
# this is the non-persistent mode
$STORMHPC_HOME/bin/pbs-configure.sh -n 2 -c $STORM_CONF_DIR
echo

sleep 30

#### Submit your jobs here
$STORM_HOME/bin/storm jar $STORM_HOME/examples/storm-starter/storm-starter-topologies-0.9.2-incubating.jar storm.starter.WordCountTopology

while true;
do
    sleep 10
done

#### Clean up the working directories after job completion
echo "Clean up"
$STORMHPC_HOME/bin/pbs-cleanup.sh -n 2
echo
