#!/bin/bash

function print_usage {
    echo "Usage: -n NODES -p -d BASE_DIR -c STORMCFGDIR -h"
    echo "       -n: Number of nodes requested for the Storm installation"
    echo "       -c: The directory to generate storm configs in"
    echo "       -h: Print help"
}

# initialize arguments
NODES=""
BASE_DIR=""
STORMCFGDIR=""

# parse arguments
args=`getopt n:d:c:h $*`
if test $? != 0
then
    print_usage
    exit 1
fi
set -- $args
for i
do
    case "$i" in
        -n) shift;
	    NODES=$1
            shift;;

        -c) shift;
	    STORMCFGDIR=$1
            shift;;

        -z) shift;
	    ZOOCFGDIR=$1
            shift;;

        -h) shift;
	    print_usage
	    exit 0
    esac
done


#STORMCFGDIR="/home/supun/dev/projects/stormforhpc/storm/conf"

echo $ZOOCFGDIR
echo $PBS_NODEFILE
echo $STORMCFGDIR

if [ "$NODES" != "" ]; then
    echo "Number of Storm nodes requested: $NODES"
else 
    echo "Required parameter not set - number of nodes (-n)"
    print_usage
    exit 1
fi


if [ "$STORMCFGDIR" != "" ]; then
    echo "Generation Storm configuration in directory: $STORMCFGDIR"
else
    echo "Location of Storm configuration directory not specified"
    print_usage
    exit 1
fi

# get the number of nodes from PBS
if [ -e $PBS_NODEFILE ]; then
    PBS_NODES=`awk 'END { print NR }' $PBS_NODEFILE`
    echo "Received $PBS_NODES nodes from PBS"
    if [ "$NODES" != "$PBS_NODES" ]; then
	echo "Number of nodes received from PBS not the same as number of nodes requested by user"
	exit 1
    fi
else 
    echo "PBS_NODEFILE is unavailable"
    exit 1
fi

# create the config, data, and log directories
rm -rf $STORMCFGDIR
mkdir -p $STORMCFGDIR
mkdir -p $ZOOCFGDIR

# pick the master node as the first node in the PBS_NODEFILE
MASTER_NODE=`awk 'NR==1{print;exit}' $PBS_NODEFILE`
echo "Master is: $MASTER_NODE"

for ((i=1; i<=$NODES; i++))
do
    node=`awk 'NR=='"$i"'{print;exit}' $PBS_NODEFILE`
    echo "Configuring node: $node"

    STORM_CFG_DIR_NODE=$STORMCFGDIR/$i

    STORM_LOCAL_DIR="//N/u/skamburu/storm/local-dir/$i"
    echo $STORM_LOCAL_DIR
    STORM_LOG_DIR="/N/u/skamburu/storm/logs/$i"
    echo $STORM_LOG_DIR

    cmd="rm -rf $STORM_CFG_DIR_NODE; mkdir -p $STORM_CFG_DIR_NODE"
    echo $cmd
    rm -rf $STORM_CFG_DIR_NODE; mkdir -p $STORM_CFG_DIR_NODE

    # first copy over all default storm configs
    echo "cp $STORM_HOME/conf/* $STORM_CFG_DIR_NODE"
    cp $STORM_HOME/conf/* $STORM_CFG_DIR_NODE/

    # update the storm configs
    sed 's:NIMBUS_HOST:'"$MASTER_NODE"':g' $STORMHPC_HOME/etc/storm.yaml > $STORM_CFG_DIR_NODE/storm.yaml
    sed -i 's:STORM_LOCAL_DIR:'"$STORM_LOCAL_DIR"':g' $STORM_CFG_DIR_NODE/storm.yaml
    sed -i 's:STORM_LOG_DIR:'"$STORM_LOG_DIR"':g' $STORM_CFG_DIR_NODE/storm.yaml

    cmd="rm -rf $STORM_LOG_DIR; mkdir -p $STORM_LOG_DIR"
    echo $cmd
    rm -rf $STORM_LOG_DIR; mkdir -p $STORM_LOG_DIR

    cmd="rm -rf $STORM_LOCAL_DIR; mkdir -p $STORM_LOCAL_DIR"
    echo $cmd
    ssh $node $cmd
    rm -rf $STORM_LOCAL_DIR; mkdir -p $STORM_LOCAL_DIR
    if [ $i -eq 1 ]; then
	    ssh $node "sh -c 'export STORM_CONF_DIR=$STORM_CFG_DIR_NODE; nohup $STORM_HOME/bin/storm nimbus --config storm.yaml > /dev/null 2>&1 &'"
	    ssh $node "sh -c 'export STORM_CONF_DIR=$STORM_CFG_DIR_NODE; nohup $STORM_HOME/bin/storm ui --config storm.yaml > /dev/null 2>&1 &'"
	else
	    ssh $node "sh -c 'export STORM_CONF_DIR=$STORM_CFG_DIR_NODE; nohup $STORM_HOME/bin/storm supervisor --config storm.yaml > /dev/null 2>&1 &'"
    fi
done
