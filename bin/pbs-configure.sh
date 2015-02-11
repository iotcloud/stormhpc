#!/bin/bash

function print_usage {
    echo "Usage: -n NODES -p -d BASE_DIR -c CONFIG_DIR -z) ZOOCFGDIR -h"
    echo "       -n: Number of nodes requested for the Storm installation"
    echo "       -c: The directory to generate storm configs in"
    echo "       -h: Print help"
}

# initialize arguments
NODES=""
PERSIST="false"
BASE_DIR=""
CONFIG_DIR=""

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
	    CONFIG_DIR=$1
            shift;;

        -z) shift;
	    ZOOCFGDIR=$1
            shift;;

        -h) shift;
	    print_usage
	    exit 0
    esac
done

#echo $NODES
#echo $PBS_NODEFILE
#cat  $PBS_NODEFILE
if [ "$NODES" != "" ]; then
    echo "Number of Storm nodes requested: $NODES"
else 
    echo "Required parameter not set - number of nodes (-n)"
    print_usage
    exit 1
fi

if [ "ZOOCFGDIR" != "" ]; then
    echo "Generation ZK configuration in directory: $ZOOCFGDIR"
else 
    echo "Location of ZK configuration directory not specified"
    print_usage
    exit 1
fi

if [ "$CONFIG_DIR" != "" ]; then
    echo "Generation Storm configuration in directory: $CONFIG_DIR"
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
rm -rf $CONFIG_DIR
mkdir -p $CONFIG_DIR
mkdir -p $ZOOCFGDIR

# first copy over all default Hadoop configs
cp $STORM_HOME/conf/* $CONFIG_DIR/
cp $ZK_HOME/conf/* $ZOOCFGDIR/

# pick the master node as the first node in the PBS_NODEFILE
MASTER_NODE=`awk 'NR==1{print;exit}' $PBS_NODEFILE`
echo "Master is: $MASTER_NODE"

# update the hdfs and mapred configs
sed 's:NIMBUS_HOST:'"$MASTER_NODE"':g' $STORMHPC_HOME/etc/storm.yaml > $CONFIG_DIR/storm.yaml
sed -i 's:STORM_LOCAL_DIR:'"$STORM_LOCAL_DIR"':g' $CONFIG_DIR/storm.yaml
sed -i 's:ZK_HOST:'"$MASTER_NODE"':g' $CONFIG_DIR/storm.yaml
sed 's:ZK_DATA_DIR'"$ZK_DATA_DIR"':g' $STORMHPC_HOME/etc/zoo.cfg > $ZOOCFGDIR/zoo.cfg

# create or link HADOOP_{DATA,LOG}_DIR on all slaves
for ((i=1; i<=$NODES; i++))
do
    node=`awk 'NR=='"$i"'{print;exit}' $PBS_NODEFILE`
    echo "Configuring node: $node"
    cmd="rm -rf $STORM_LOG_DIR; mkdir -p $STORM_LOG_DIR"
    echo $cmd
    ssh $node $cmd 

	cmd="rm -rf $STORM_LOCAL_DIR; mkdir -p $STORM_LOCAL_DIR"
	echo $cmd
	ssh $node $cmd

	cmd="rm -rf $ZK_DATA_DIR; mkdir -p $ZK_DATA_DIR"
	echo $cmd
	ssh $node $cmd

    if [ $i -eq 1 ]; then
        cmd="nohup $STORM_HOME/bin/storm nimbus &"
	    echo $cmd
	    ssh $node $cmd

	    cmd="$ZK_HOME/bin/zkServer.sh start"
	    echo $cmd
	    ssh $node $cmd
	else
	    cmd="nohup $STORM_HOME/bin/storm supervisor &"
	    echo $cmd
	    ssh $node $cmd
    fi
done
