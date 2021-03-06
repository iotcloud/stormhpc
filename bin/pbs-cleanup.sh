#!/bin/bash

function print_usage {
    echo "Usage: -n NODES -h"
    echo "       -n: Number of nodes requested for the Storm installation"
    echo "       -h: Print help"
}

# initialize arguments
NODES=""

# parse arguments
args=`getopt n:h $*`
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

        -h) shift;
	    print_usage
	    exit 0
    esac
done

if [ "$NODES" != "" ]; then
    echo "Number of Storm nodes specified by user: $NODES"
else 
    echo "Required parameter not set - number of nodes (-n)"
    print_usage
    exit 1
fi

# get the number of nodes from PBS
if [ -e $PBS_NODEFILE ]; then
    pbsNodes=`awk 'END { print NR }' $PBS_NODEFILE`
    echo "Received $pbsNodes nodes from PBS"

    if [ "$NODES" != "$pbsNodes" ]; then
	echo "Number of nodes received from PBS not the same as number of nodes requested by user"
	exit 1
    fi
else 
    echo "PBS_NODEFILE is unavailable"
    exit 1
fi

# clean up working directories for N-node Hadoop cluster
for ((i=1; i<=$NODES; i++))
do
    node=`awk 'NR=='"$i"'{print;exit}' $PBS_NODEFILE`
    echo "Clean up node: $node"
    cmd="rm -rf $STORM_DATA_DIR $STORM_LOG_DIR $ZK_DATA_DIR"
    echo $cmd
    ssh $node $cmd 
done
